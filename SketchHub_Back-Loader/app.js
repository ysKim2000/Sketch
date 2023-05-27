const express = require('express');
const loader = require('./loader/loader');
const bodyParser = require('body-parser');
const http = require('http');
const socketIO = require('socket.io');

async function startServer(){
    const app = express();
    const server = http.createServer(app);
    const io = socketIO(server);

    app.use(bodyParser.json());
    app.use(express.urlencoded( {extended : false } ));
    await loader(app);

    // 클라이언트 연결 시 실행되는 이벤트 처리
    io.on('connection', (socket) => {
        console.log('새로운 클라이언트가 연결되었습니다.');

        // 클라이언트로부터 수신한 스케치 데이터를 다른 클라이언트에게 브로드캐스트
        socket.on('sketchData', (data) => {
            console.log('스케치 데이터를 수신했습니다:', data);
            io.emit('sketchData', data);
        });

        // 클라이언트 연결 해제 시 실행되는 이벤트 처리
        socket.on('disconnect', () => {
            console.log('클라이언트가 연결을 해제했습니다.');
        });
    });

    app.listen(app.get('port'), () => {
        console.log(app.get('port'), 'port waiting...');
    });   
}

startServer()

