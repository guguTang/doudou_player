const lanUploadPageHtml = r'''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>豆豆播放器 · 局域网上传</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #121212;
      --card: #1e1e1e;
      --border: #333;
      --text: #f5f5f5;
      --muted: #aaa;
      --accent: #b388ff;
      --accent-strong: #7c4dff;
      --danger: #ff8a80;
      --success: #69f0ae;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: radial-gradient(circle at top, #1f1633, var(--bg) 45%);
      color: var(--text);
      padding: 24px 16px 40px;
    }
    .container {
      max-width: 720px;
      margin: 0 auto;
    }
    h1 {
      margin: 0 0 8px;
      font-size: 1.6rem;
    }
    p { color: var(--muted); line-height: 1.5; }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 20px;
      margin-top: 20px;
    }
    label {
      display: block;
      margin-bottom: 8px;
      font-size: 0.95rem;
    }
    input[type="password"], input[type="text"] {
      width: 100%;
      padding: 12px 14px;
      border-radius: 10px;
      border: 1px solid var(--border);
      background: #111;
      color: var(--text);
      font-size: 1rem;
      letter-spacing: 0.2em;
    }
    .dropzone {
      margin-top: 16px;
      border: 2px dashed #555;
      border-radius: 16px;
      padding: 36px 20px;
      text-align: center;
      transition: border-color 0.2s, background 0.2s;
      cursor: pointer;
    }
    .dropzone.dragover {
      border-color: var(--accent);
      background: rgba(179, 136, 255, 0.08);
    }
    .dropzone strong { display: block; margin-bottom: 8px; }
    .file-list {
      margin-top: 16px;
      display: grid;
      gap: 8px;
    }
    .file-item {
      display: flex;
      justify-content: space-between;
      gap: 12px;
      padding: 10px 12px;
      border-radius: 10px;
      background: #181818;
      font-size: 0.92rem;
      word-break: break-all;
    }
    button {
      margin-top: 16px;
      width: 100%;
      border: none;
      border-radius: 12px;
      padding: 14px 18px;
      font-size: 1rem;
      font-weight: 600;
      color: white;
      background: linear-gradient(135deg, var(--accent), var(--accent-strong));
      cursor: pointer;
    }
    button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
    .progress {
      margin-top: 16px;
      height: 8px;
      border-radius: 999px;
      background: #2a2a2a;
      overflow: hidden;
      display: none;
    }
    .progress.visible { display: block; }
    .progress > div {
      height: 100%;
      width: 0%;
      background: linear-gradient(90deg, var(--accent), var(--success));
      transition: width 0.2s;
    }
    .status {
      margin-top: 16px;
      padding: 12px 14px;
      border-radius: 12px;
      background: #181818;
      white-space: pre-wrap;
      display: none;
    }
    .status.visible { display: block; }
    .status.error { color: var(--danger); }
    .status.success { color: var(--success); }
  </style>
</head>
<body>
  <div class="container">
    <h1>豆豆播放器 · 局域网上传</h1>
    <p>将视频或字幕文件上传到运行豆豆播放器的设备。请确保设备与电脑处于同一 Wi-Fi。</p>

    <div class="card">
      <label for="token">上传 PIN（在应用设置页查看）</label>
      <input id="token" type="password" inputmode="numeric" maxlength="6" placeholder="6 位数字 PIN" autocomplete="one-time-code">

      <div id="dropzone" class="dropzone">
        <strong>拖拽文件到此处</strong>
        <span>或点击选择视频 / 字幕文件</span>
      </div>
      <input id="fileInput" type="file" multiple hidden>

      <div id="fileList" class="file-list"></div>

      <div id="progress" class="progress"><div></div></div>
      <button id="uploadBtn" type="button" disabled>开始上传</button>
      <div id="status" class="status"></div>
    </div>
  </div>

  <script>
    const tokenInput = document.getElementById('token');
    const dropzone = document.getElementById('dropzone');
    const fileInput = document.getElementById('fileInput');
    const fileList = document.getElementById('fileList');
    const uploadBtn = document.getElementById('uploadBtn');
    const progress = document.getElementById('progress');
    const progressBar = progress.firstElementChild;
    const status = document.getElementById('status');
    let selectedFiles = [];

    const savedToken = localStorage.getItem('doudou_upload_token');
    if (savedToken) tokenInput.value = savedToken;

    function renderFiles() {
      fileList.innerHTML = '';
      selectedFiles.forEach((file, index) => {
        const item = document.createElement('div');
        item.className = 'file-item';
        item.innerHTML = '<span>' + file.name + '</span><span>' + formatSize(file.size) + '</span>';
        fileList.appendChild(item);
      });
      uploadBtn.disabled = selectedFiles.length === 0;
    }

    function formatSize(bytes) {
      if (bytes < 1024) return bytes + ' B';
      if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
      if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
      return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
    }

    function setStatus(message, type) {
      status.textContent = message;
      status.className = 'status visible ' + (type || '');
    }

    function addFiles(files) {
      const merged = [...selectedFiles];
      for (const file of files) {
        if (!merged.some((item) => item.name === file.name && item.size === file.size)) {
          merged.push(file);
        }
      }
      selectedFiles = merged;
      renderFiles();
    }

    dropzone.addEventListener('click', () => fileInput.click());
    fileInput.addEventListener('change', () => {
      addFiles([...fileInput.files]);
      fileInput.value = '';
    });

    ['dragenter', 'dragover'].forEach((eventName) => {
      dropzone.addEventListener(eventName, (event) => {
        event.preventDefault();
        dropzone.classList.add('dragover');
      });
    });
    ['dragleave', 'drop'].forEach((eventName) => {
      dropzone.addEventListener(eventName, (event) => {
        event.preventDefault();
        dropzone.classList.remove('dragover');
      });
    });
    dropzone.addEventListener('drop', (event) => {
      addFiles([...event.dataTransfer.files]);
    });

    uploadBtn.addEventListener('click', async () => {
      const token = tokenInput.value.trim();
      if (!/^\d{6}$/.test(token)) {
        setStatus('请输入 6 位数字 PIN。', 'error');
        return;
      }
      if (selectedFiles.length === 0) {
        setStatus('请先选择文件。', 'error');
        return;
      }

      localStorage.setItem('doudou_upload_token', token);
      const formData = new FormData();
      selectedFiles.forEach((file) => formData.append('files', file, file.name));

      uploadBtn.disabled = true;
      progress.classList.add('visible');
      progressBar.style.width = '0%';
      setStatus('正在上传...', '');

      try {
        const result = await uploadWithProgress(formData, token);
        const summary = [
          '上传完成',
          '新增视频: ' + (result.videosAdded || 0),
          '关联字幕: ' + (result.subtitlesAttached || 0),
          '跳过: ' + (result.skipped || 0),
        ];
        if (result.errors && result.errors.length > 0) {
          summary.push('', '提示:', ...result.errors);
        }
        setStatus(summary.join('\n'), 'success');
        selectedFiles = [];
        renderFiles();
      } catch (error) {
        setStatus(error.message || '上传失败', 'error');
      } finally {
        uploadBtn.disabled = selectedFiles.length === 0;
        progress.classList.remove('visible');
        progressBar.style.width = '0%';
      }
    });

    function uploadWithProgress(formData, token) {
      return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open('POST', '/api/upload?token=' + encodeURIComponent(token));
        xhr.setRequestHeader('X-Upload-Token', token);
        xhr.upload.addEventListener('progress', (event) => {
          if (!event.lengthComputable) return;
          const percent = Math.round((event.loaded / event.total) * 100);
          progressBar.style.width = percent + '%';
        });
        xhr.addEventListener('load', () => {
          let payload = {};
          try {
            payload = JSON.parse(xhr.responseText || '{}');
          } catch (_) {}
          if (xhr.status >= 200 && xhr.status < 300) {
            resolve(payload);
            return;
          }
          reject(new Error(payload.error || ('上传失败 (' + xhr.status + ')') ));
        });
        xhr.addEventListener('error', () => reject(new Error('网络错误')));
        xhr.send(formData);
      });
    }
  </script>
</body>
</html>
''';
