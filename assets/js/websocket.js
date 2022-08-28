function WebSocket(url, protocols) {
    this._id = WebSocket._currId++;
    this._eventCb = {}
    this.url = url;
    this.protocols = typeof protocols === 'string' ? [protocols] : protocols;
    this.send = (data) => sendMessage('ws:send', JSON.stringify([this._id, data]));
    this.close = (code, reason) => {
        sendMessage('ws:close', JSON.stringify({id: this._id, code, reason}));
        delete WebSocket._ids[this._id];
    };
    this.addEventListener = (e, cb) => {
        this._eventCb[e] = (this._eventCb[e] || []).concat(cb);
    };
    sendMessage('ws:construct', JSON.stringify([this._id, this.url, this.protocol]));
    WebSocket._ids[this._id] = this;
    return this;
}

WebSocket._currId = 0;
WebSocket._ids = {};
WebSocket._dispatchEvent = (id, eName, data) => {
    if (!WebSocket._ids[id]) return;
    let ws = WebSocket._ids[id];
    if (ws["on"+eName]) 
        ws["on"+eName].apply(ws, data);
    (ws._eventCb[eName]||[])
        .forEach(cb => cb(data));
};

