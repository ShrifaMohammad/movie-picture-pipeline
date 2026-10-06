# دليل تسليم المشروع (Movie Picture Pipeline)

## الملفات المضافة
```
.github/workflows/frontend-ci.yaml   -> Frontend Continuous Integration
.github/workflows/backend-ci.yaml    -> Backend Continuous Integration
.github/workflows/frontend-cd.yaml   -> Frontend Continuous Deployment
.github/workflows/backend-cd.yaml    -> Backend Continuous Deployment
.gitignore / .gitattributes
```
تعديل مهم: ملفات المشروع كانت بنهايات أسطر Windows (CRLF) مما كان يجعل `npm run lint` يفشل (37 خطأ prettier).
تم تحويلها إلى LF وإضافة `.gitattributes` لمنع تكرار المشكلة.

## 1) رفع المشروع إلى GitHub
```bash
# أنشئ repo عام فارغ على GitHub ثم:
cd <مجلد المشروع>
git init -b main
git add .
git commit -m "Add CI/CD pipelines"
git remote add origin https://github.com/<USER>/<REPO>.git
git push -u origin main
```

## 2) إنشاء بيئة AWS (Terraform)
```bash
cd setup/terraform
terraform init
terraform apply          # اكتب yes
terraform output         # احفظ frontend_ecr / backend_ecr
```
ثم أنشئ Access Key للمستخدم `github-action-user` (IAM > Users > Security credentials)
ثم شغّل:
```bash
aws eks update-kubeconfig --name cluster --region us-east-1
cd ../ && ./init.sh
```

## 3) إعدادات GitHub (Settings > Secrets and variables > Actions)
Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Variables (بعد نشر الـ backend، انظر الخطوة 4):
- `BACKEND_URL` = `http://<backend-load-balancer-hostname>` (بدون / في النهاية)

## 4) ترتيب التشغيل
1. شغّل **Backend Continuous Deployment** (Actions > Run workflow).
2. جلب رابط الـ backend: `kubectl get svc backend` (عمود EXTERNAL-IP)
   وتأكد: `curl http://<EXTERNAL-IP>/movies`
3. ضع الرابط في المتغير `BACKEND_URL`.
4. شغّل **Frontend Continuous Deployment**.
5. افتح `kubectl get svc frontend` -> الرابط في المتصفح، يجب أن تظهر قائمة الأفلام.

## 5) اختبار الـ CI (مطلوب للتسليم)
```bash
git checkout -b test-ci
# عدّل أي ملف داخل starter/frontend و starter/backend
git commit -am "test ci" && git push -u origin test-ci
# افتح Pull Request نحو main -> يجب أن تعمل workflows الـ CI بنجاح
```
أو شغّلها يدوياً عبر Run workflow.

## 6) ما يُسلَّم
- رابط الـ repo
- screenshot لواجهة الـ frontend تعرض الأفلام
- screenshot لـ `http://<backend-lb>/movies`
- screenshots لنجاح الـ 4 workflows

## 7) الحذف بعد التسليم
```bash
kubectl delete svc frontend backend
cd setup/terraform && terraform destroy
```
