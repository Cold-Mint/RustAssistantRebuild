# 铁锈助手Rebuild

### 跨平台运行与Steam创意工坊

1. 支持多端运行（Windows，Android，Linux）。
2. 支持读取和编辑来自Steam创意工坊的模组。

### 支持多行文本

1. 对以三个英文引号开头的文本格式做了兼容处理。现在可以妥善的处理多行文本与多行注解。

### 安全的文件名

1. 对非英文的文件名进行安全的转换，以便您的模组能够在多平台运行，避免出现编码兼容性问题。

### 本地化

重新生成翻译文件：

flutter gen-l10n

### 安卓构建

从 app 中引用密钥库

创建一个名为 [project]/android/key.properties 的文件，它包含了密钥库位置的定义。在替换内容时请去除 < > 括号：

storePassword=<password-from-previous-step>
keyPassword=<password-from-previous-step>
keyAlias=upload
storeFile=<keystore-file-location>

storeFile 密钥路径在 macOS 上类似于 /Users/<user name>/upload-keystore.jks，在 Windows 上类似于 C:\\Users\\<user name>\\upload-keystore.jks。
提示

keystore.jks 的 Windows 路径必须使用双反斜杠：\\。

