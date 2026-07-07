# mac安装jdk
brew install openjdk@17
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# sdk command安装
brew install --cask android-commandlinetools

# 创建sdk的文件夹
mkdir -p ~/Library/Android/sdk

# sdk组件安装
sdkmanager \
  "platforms;android-36" \
  "build-tools;36.0.0"
  
sdkmanager \
  "platform-tools" \
  "platforms;android-35" \
  "build-tools;35.0.0"

# flutter配置android sdk路径
flutter config --android-sdk ~/Library/Android/sdk