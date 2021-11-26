/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS{
    constructor () payable {}


enum Hand { 
    rock, paper, scissors //플레이어가 낼 수 있는 가위바위보를 열거형으로 지정
}

enum PlayerStatus {
    STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING //플레이어 상태를 열거형으로 지정
}

enum GameStatus{
    STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR //게임상태를 열거형으로 지정
}

struct Player{ //플레이어가 가질수 있는 정보들
        address payable addr; //payable을 통해 addr이라는 변수명을 가진 주소선언
        uint256 playerBetAmount; //플레이어(방장,참가자)가 베팅할 양
        Hand hand; //hand라는 변수명을 가진 Hand 열거타입
        PlayerStatus playerStatus; //playerStatus라는 변수명을 가진 PlayerStatus 열거타입
}


struct Game { //Game의 구조
    Player originator; //originator이라는 변수명을 가진 Player 구조체
    Player taker; //taker라는 변수명을 가진 Player 구조체
    uint256 betAmount; //betAmount라는 현재 Game안에서 방장과 참가자의 베팅한 양 합계
    GameStatus gamestatus; //gamestatus라는 변수명을가진 GameStatus 열거타입
}

mapping(uint => Game) rooms; //Game구조를 가진 rooms들을 여러개 만들어낸다.
uint roomLen = 0; //rooms길이 즉 번호는 0부터 시작한다. 방번호

modifier isValidHand (Hand _hand){
    require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
    // _hand가 가위바위보 중에서 만 들어도록 검사하여 이상없을시 pass한다.
    _; //이후 isValidHand가 선언된 함수가 작동된다.
}

function createRoom (Hand _hand) public payable isValidHand( _hand) returns (uint roomNum){
    //방장이 방만들때 자기가 낼 _hand를 인자로 보내며 방번호를 리턴한다.
rooms[roomLen] = Game({ //Game구조체로 방이 만들어지며 Game 구조에 맞게 아래 데이터가 작성된다.
    betAmount: msg.value, // 총 베팅양은 현재 참가자가 없으므로 방장의 msg.value로 채워진다.
    gamestatus: GameStatus.STATUS_NOT_STARTED, 
    originator: Player({
        hand: _hand,
        addr: payable(msg.sender), //현재sender 즉 방장의 주소
        playerStatus : PlayerStatus.STATUS_PENDING,
        playerBetAmount : msg.value
    }),
    taker: Player({
        hand: Hand.rock,
        addr: payable(msg.sender), //현재sender 즉 방장의 주소지만 joinRoom 함수로 참가자가 입장시 참가자의 sender주소로 바뀌게된다.
        playerStatus: PlayerStatus.STATUS_PENDING,
        playerBetAmount: 0 
    })
});
roomNum = roomLen; //방번호를 리턴하기 위한
roomLen = roomLen+1; //방생성후 방번호를 올린다.
}

function joinRoom(uint roomNum, Hand _hand) public payable isValidHand ( _hand){
    //참가자는 방번호와 자기가 낼 _hand를 인자로 보낸다.
    rooms[roomNum].taker = Player({ //참가자의 Player 구조체에 맞게 데이터를 보낸다.
        hand: _hand, 
        addr: payable(msg.sender), //현재참가자 즉 sender의 주소
        playerStatus: PlayerStatus.STATUS_PENDING,
        playerBetAmount: msg.value //현재참자가의 보낸 베팅양 = > 위 createRoom 에서 taker의 playerBetAmount가 0 에서 이 msg.value로 바뀐다.
   });
   rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value; //현재 방장의 베팅양을 전체 betAmount에 저장했으니 거기에 참가자의 베팅양도 합친다.
   compareHands(roomNum); // hand를 비교하는 함수를 실행하여 결과를 도출한다.
}
 
function compareHands(uint roomNum) private{
 uint8 originator = uint8(rooms[roomNum].originator.hand); 
 //HAND의 열거에서 가위 바위 보는 enum이라는 열거를 통해 순서에 따라 0~숫자가 매겨지므로 그 숫자를 정수형uint8로 변환한다.
  uint8 taker = uint8(rooms[roomNum].taker.hand);

   rooms[roomNum].gamestatus = GameStatus.STATUS_STARTED; //게임상태를 시작으로 바꾸어준다.

   if(originator==taker){ //변환한 숫자가 같으면 비긴다.
       rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
       rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
   }
   else if((taker + 1) % 3 == originator){ //숫자계산을 통해 승자를 가려낸다.
       rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
       rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
   }
   else if((originator + 1) % 3 == taker){
       rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
       rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
   }
   else{ //이외에 처리는 게임상태가 error가 된다.
       rooms[roomNum].gamestatus = GameStatus.STATUS_ERROR;
   }

}

modifier isPlayer (uint roomNum, address sender){
    require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
    //payout 함수로 승자에 따라 베팅총양을 출금할때 이 payout을 실행할 사람이 방장또는 참가자 여야한다.
    _; //require 이상없을시 payout 함수 실행
}

function payout(uint roomNum) public payable isPlayer (roomNum, msg.sender){
    if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE){
        //방장과 참가자 모두가 비겼을시
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        //각자의 주소로 다시 자신이 베팅한 돈을 돌려준다.
    }
    else {
        if(rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN){
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
        //이겼을시 이긴 사람의 주소로 총 베팅금액이 모여있는 betAmount가 전송된다.
        }
        else if(rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN)
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
    
    else {
    // 그밖에 에러사항이나 예외시 각자의 베팅 금액을 각자 주소로 되돌려준다.
        rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
        rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
    }
    }
    rooms[roomNum].gamestatus = GameStatus.STATUS_COMPLETE;
    //방의 게임상태를 완료로 바꾼다.
}

}