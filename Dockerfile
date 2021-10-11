# 设置基础镜像
FROM nginx

# 将 dist 文件夹中的内容复制到 /home/web
COPY ./dist /home/web