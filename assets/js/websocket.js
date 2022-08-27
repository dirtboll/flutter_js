function WebSocket(url, protocols) {
    this._id = WebSocket.currId++;
    this._eventCb = {}
    this.url = url;
    this.protocols = typeof protocols === 'string' ? [protocols] : protocols;
    this.send = (data) => sendMessage('ws:send', JSON.stringify([this._id, data]));
    this.close = (code, reason) => sendMessage('ws:close', JSON.stringify([this._id, code, reason]));
    this.addEventListener = (e, cb) => {
        this._eventCb[e] = (this._eventCb[e] || []).concat(cb);
    };
    sendMessage('ws:construct', JSON.stringify([this._id, this.url, this.protocol]));
    WebSocket.ids[this._id] = this;
    return this;
}

WebSocket.currId = 0;
WebSocket.ids = {};
WebSocket._dispatchEvent = (id, eName, data) => {
    if (!WebSocket.ids[id]) return;
    let ws = WebSocket.ids[id];
    if (ws["on"+eName]) ws["on"+eName](data);
    (ws._eventCb[eName]||[]).forEach(cb => cb(data));
};

