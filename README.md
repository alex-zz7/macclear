# 卸净

原生 macOS 应用。把应用和它留下的偏好设置、缓存、容器、登录项、收据一起移到废纸篓。

系统自带的卸载通常只带走 `.app`。卸净按 Bundle ID 查找残留文件；只按名称对上的项目会标成「可能相关」，默认不勾选。系统应用不会删除。只要有一条路径不在允许的目录里，这次操作会整批取消。

## 打开

用 Xcode 打开 `XieJing.xcodeproj`，运行方案 **XieJing**。需要 Xcode 26 和 macOS 15。

第一次使用时，在系统设置里给卸净打开「完全磁盘访问权限」。删除「应用程序」文件夹里的软件时，还需要允许「应用管理」。

## 生成工程

安装 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 后：

```sh
xcodegen generate
```
