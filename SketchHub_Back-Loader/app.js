const express = require('express');
const loader = require('./loader/loader');
const bodyParser = require('body-parser');
const http = require('http');
const WebSocket = require('ws');

async function startServer() {
    const app = express();
    const server = http.createServer(app);
    const wss = new WebSocket.Server({ server });

    app.use(bodyParser.json());
    app.use(express.urlencoded({ extended: false }));
    await loader(app);

    // 클라이언트 연결 시 실행되는 이벤트 처리
    wss.on('connection', (ws) => {
        console.log('새로운 클라이언트가 연결되었습니다.');

        // 클라이언트로부터 수신한 스케치 데이터를 다른 클라이언트에게 브로드캐스트
        ws.on('message', (message) => {
            const data = JSON.parse(message); // 버퍼 값을 JavaScript 객체로 파싱
            const x = data.x;
            const y = data.y;

            console.log('x:', x, 'y:', y); // 수정: 콘솔 로그에 출력

            wss.clients.forEach((client) => {
                if (client !== ws && client.readyState === WebSocket.OPEN) {
                    client.send(message); // 수정: 원본 메시지 그대로 전송
                }
            });
        });

        // 클라이언트 연결 해제 시 실행되는 이벤트 처리
        ws.on('close', () => {
            console.log('클라이언트가 연결을 해제했습니다.');
        });
    });

    server.listen(app.get('port'), () => {
        console.log(app.get('port'), 'port waiting...');
    });
}

startServer();
