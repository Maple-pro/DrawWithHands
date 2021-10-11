# Draw with hands

> A website where you can draw with your hands.
> 
> It is a simple application of MediaPip.

## Usage guide
网站：[http://maples31.com:3000/](http://maples31.com:3000/)

Press `ctrl` to draw!

## Build Setup

``` bash
# install dependencies
npm install

# serve with hot reload at localhost:8080
npm run dev

# build for production with minification
npm run build

# build for production and view the bundle analyzer report
npm run build --report

# docker 部署
docker build -t drawwithhands .

docker run -p 3000:8080 -d --name drawwithhands drawwithhands

docker exec -it [container ID] /bin/bash

find / -name nginx.conf

# 配置nginx
server {
    listen 8080;
    server_name localhost;
    root /home/web;
}

nginx -s reload
```

For a detailed explanation on how things work, check out the [guide](http://vuejs-templates.github.io/webpack/) and [docs for vue-loader](http://vuejs.github.io/vue-loader).

## Problem
### Cannot read property 'getUserMedia' of undefined
1. 在浏览器中输入 [chrome://flags/#unsafely-treat-insecure-origin-as-secure](chrome://flags/#unsafely-treat-insecure-origin-as-secure)
2. 定位到的“Insecure origins treated as secure”区域的文本框中输入需要使用HTTP协议访问的IP地址，如果有多个IP地址使用逗号（,）分隔。
![示例图片](https://maples31-blog.oss-cn-beijing.aliyuncs.com/img/image-20211011191647046.png)
3. 将右侧 Disabled 改为 Enabled
4. 点击下方的 Relaunch
5. 再次访问
