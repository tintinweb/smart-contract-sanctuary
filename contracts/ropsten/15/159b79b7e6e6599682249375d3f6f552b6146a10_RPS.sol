/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract RPS {
    // 해당 컨트랙트가 송금을 진행하기 위해 생성자 함수에 payable 키워드 사용 -> 송금이 가능하다는 것을 명시
    constructor () payable {}

    // 플레이어는 가위/바위/보 값을 낼 수 있음. 이를 제외하고는 없음 -> 가위/바위/보 외의 값을 낼 경우 예외 발생하도록 하기
    // 각각 0, 1, 2
    enum Hand {
        rock, paper, scissors
    }

    // 플레이어의 상태 -> 승/패/비김/대기중
    enum PlayerStatus {
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }

    // 게임 상태 -> 방 만듦, 참여자가 참가해 결과가 나옴, 베팅을 분배함, 게임 중간에 에러가 발생함
    enum GameStatus {
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }
    // 게임에서는 각 플레이어의 주소와 베팅 금액을 알고 있어야 함
    struct Player {
        address payable addr; // 주소
        uint256 playerBetAmount; // 베팅 금액
        Hand hand; // 플레이어가 낸 가위/바위/보 값
        PlayerStatus playerStatus; // 플레이어의 현 상태
    }

    // 각 게임은 >>방<< 에서 진행되는데, 이 방은 모두 같은 형식을 가지고 있음.
    struct Game {
        Player originator; // 방장 정보
        Player taker; // 참여자 정보
        uint256 betAmount; // 총 베팅 금액
        GameStatus gameStatus; // 게임의 현 상태
    }

    // mappint: storage 데이터 영역에서 키-값 구조로 데이터를 저장할 때 사용하는 참조형.
    // mapping({키 형식} => {값 형식}) {변수명} 형태로 선언
    mapping(uint => Game) rooms; // rooms[0], rooms[1] 형식으로 접근할 수 있으며, 각 요소는 Game 구조체 형식입니다.
    uint roomLen = 0;

    // 가위/바위/보 말고 다른 값을 지정했는지 검사하는 함수 제어자
    modifier isValidHand (Hand _hand) {
        // require : 설정한 조건이 참인지 확인하고, 조건이 거짓이면 에러를 리턴
        require((_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors));
        _;
    }

    // createRoom: 게임을 생성함.
    // 게임을 생성한 방장은 자신이 낼 가위/바위/보 값을 인자로 보내고, 베팅 금액은 msg.value로 설정함.
    // msg? 솔리디티에 정의된 글로벌 변수. msg.value는 함수를 사용할 때 입력받지만, 함수 내에서는 파라미터로 설정할 필요가 없음.
    // 게임을 만들고 나면 해당 게임의 방 번호 반환
    function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum){
        // payable? 베팅 금액을 설정하기 때문

        // 일단 Game 구조체의 instance 만들어야 함
        rooms[roomLen] = Game({
            betAmount: msg.value, // 베팅 금액
            gameStatus: GameStatus.STATUS_NOT_STARTED, // 아직 시작 안함
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender), // 해당 msg 보낸 사람
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value // 베팅 금액
            }),
            taker: Player({ // player 구조체 형태로 초기화. 그냥 기본값 setting임.
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            }) 
        });

        roomNum = roomLen; // 리턴됨. 새롭게 만들어진 게임의 방 번호는 roomLen이 된다.
        roomLen = roomLen + 1; // 다음 방을 위해 하나 더해줌.
    }

    // joinRoom : 기존에 만들어진 방에 참가.
    // 참가자는 참가할 방 번호와 자신이 낼 가위/바위/보 값을 인자로 보내고, 베팅 금액은 msg.value로 설정.
    function joinRoom (uint roomNum, Hand _hand) public payable isValidHand(_hand) {
        // 입력받은 방에 해당하는 Game 인스턴스 중 taker 설정
        rooms[roomNum].taker = Player({
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });

        // 참여자가 들어오면서 전체 게임 방의 베팅 금액도 달라졌으므로, 이것도 변경해줌
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum); // 게임 결과 업데이트 함수 호출
    }

    // compareHands : 게임 결과 업데이트 + 참여자들의 상태 업데이트
    // joinRoom 함수가 끝나는 시점에서, 방장과 참가자가 모두 가위바위보 값을 냈기 때문에
    // 게임의 승패를 확인 가능. 
    function compareHands(uint roomNum) private {
        // 방장과 참가자의 가위바위보 값은 enum값. 그러니 정수형으로 바꿔준다.
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        if (taker == originator){ // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        }
        else if ((taker +1) % 3 == originator) { // 방장이 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((originator + 1)%3 == taker){  // 참가자가 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {  // 그 외의 상황에는 게임 상태를 에러로 업데이트한다
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    modifier isPlayer(uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }

    // payout : 방 번호를 인자로 받아, 게임 결과에 따라 베팅 금액을 송금하고, 게임을 종료함.
    // 컨트랙트에 있는 금액을 송금하기 위해서는 솔리디티에 내장되어 있는 transfer 함수를 사용함.
    // ADDRESS.transfer(value) : ADRESS로 value만큼 송금.
    // 여기서 중요한 것은 payout 함수를 실행하는 주체가 방장 또는 참가자 여야 한다는 것.
    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
        if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
            rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
        } else {
            if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
            } else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; // 게임이 종료되었으므로 게임 상태 변경
    }
}