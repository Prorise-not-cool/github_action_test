// vulnerable.js

function getQueryParam(name) {
    // Source: 直接获取 URL 参数，属于不可信输入
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(name);
}

function renderWelcome() {
    const user = getQueryParam('user');
    // Sink: 直接将未清洗的用户输入赋值给 innerHTML
    // 攻击者可构造 ?user=<img src=x onerror=alert(1)> 触发 XSS
    document.getElementById('welcome-msg').innerHTML = "Welcome " + user;
}