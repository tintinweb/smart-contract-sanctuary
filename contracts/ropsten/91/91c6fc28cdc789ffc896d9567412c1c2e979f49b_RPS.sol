/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

//SPDX-License-Identifier: MIT // 01_라이센스 설정
pragma solidity ^0.8.7; // 02_컴파일러 설정

contract RPS { // 03_컨트랙트 이름 RPS
    
    constructor () payable {} // 04_컨트랙트 생성시 생성자 함수 실행되며 컨트랙트 상태 초기화
    
    /*
    event GameCreated(address originator, uint256 originator_bet);
    event GameJoined(address originator, address taker, uint256 originator_bet, uint256 taker_bet);
    event OriginatorWin(address originator, address taker, uint256 betAmount);
    event TakerWin(address originator, address taker, uint256 betAmount);
   */
   
    enum Hand { // 08_플레이어가 낸 값, 가위/바위/보 값에 대한 enum
        rock, paper, scissors
    }
    
    enum PlayerStatus{ // 10_플레이어의 상태
        STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING
    }
    
    enum GameStatus { // 18_게임의 상태
        STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR
    }
    
    // player structure
    struct Player { // 05_플레이어 구조체(주소와베팅 금액)
        address payable addr; // 06_주소
        uint256 playerBetAmount; // 07_베팅금액
        Hand hand; // 09_플레이어가 낸 가위/바위/보 값
        PlayerStatus playerStatus; // 11_사용자의 현 상태
    }
    
    struct Game { // 12_컨트랙트에는 게임을 진행하는 여러 방이 있고, 아래와 같은 형식을 가짐
        Player originator; // 13_방장 정보
        Player taker; // 14_참여자 정보
        uint256 betAmount; // 15_총 베팅 금액
        GameStatus gameStatus; // 19_게임의 현 상태
    }
    
    
    mapping(uint => Game) rooms; // 16_rooms[0], rooms[1] 형식으로 접근할 수 있으며, 각 요소는 Game 구조체 형식입니다.
    // mapping 스토리지 데이터 영역에서 키-값 구조로 데이터를 저장, mapping({키 형식}=>{값 형식}) {변수명}
    uint roomLen = 0; // 17_rooms의 키 값입니다. 방이 생성될 때마다 1씩 올라갑니다.
    
    modifier isValidHand (Hand _hand) {
        // 31_가위,바위,보 값 이외의 값이 지정될 경우, 함수 선언에 modifier를 추가하여 함수에 변경자를 적용할 수 있습니다.
        require((_hand  == Hand.rock) || (_hand  == Hand.paper) || (_hand == Hand.scissors),
        "InValidHand!!");
        _;
    }
    
    // 20_createRoom은 게임을 생성합니다. 게임을 생성한 방장은 자신이 낼 가위,바위,보 값을 인자로 보내고,
    // 베팅 금액은 msg.value로 설정합니다.
    // 글로벌 변수 msg-gasleft(),data,sender,gas,value
    // 32_createRoom이 실행되기 전에 방장이 낸 가위,바위,보 값이 올바른 값인지 확인 (isValidHand(_hand) 추가)
    // 이를 위해 isValidHand라는 함수 제어자를 만들어, createRoom 실행 시 확인하도록 합니다.
    function createRoom (Hand _hand) public payable isValidHand(_hand) returns (uint roomNum) {
        // 22_베팅금액을 설정하기 때문에 payable 키워드를 사용합니다. , 변수 roomNum의 값을 반환합니다.
        rooms[roomLen] = Game({ // 23_게임을 만들기 위해서는 rooms에 새로운 Game 구조체의 인스턴스를 할당해야 합니다.
            betAmount: msg.value, // 24_아직 방장만 있기 때문에 방장의 베팅 금액을 넣습니다.
            gameStatus: GameStatus.STATUS_NOT_STARTED, // 25_아직 시작하지 않은 상태이기 때문에 ~NOT_STARTED
            originator: Player({ // 26_Player 구조체의 인스턴스를 만들어, 방장의 정보를 넣어줍니다.
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value // 21_메시지와 함께 보낸 이더 금액. uint 형식
            }),
            taker: Player({ // 27_Player 구조체 형식의 데이터로 초기화되어야 하기 때문에
                hand: Hand.rock, // 29_Hand.rock으로 할당해둡니다.
                addr: payable(msg.sender), // 28_addr에는 방장의 주소를
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen; // 29_roomNum은 리턴된다. ,새롭게 만들어진 게임의 방 번호는 roomLen이 됩니다.
        roomLen = roomLen+1; // 30_다음 방 번호를 설정, 다음에 만들어질 게임을 위해 roomLen의 값을 1 올려줍니다.
        
        
       // Emit gameCreated(msg.sender, msg.value);
    }
    
    // 33_기존에 만들어진 방에 참가합니다.
    // 참가자는 참가할 방 번호와 자신이 낼 가위바위보 값을 인자로 보내고, 베팅 금액은 msg.value로 설정
    // 가위,바위,보 값을 내기 때문에 마찬가지로 isValidHand 함수 제어자를 사용합니다.
    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand( _hand) {
       // Emit gameJoined(game.originator.addr, msg.sender, game.betAmount, msg.value);
        
        rooms[roomNum].taker = Player({ // 34_입력받은 방의 Game 구조체 인스턴스의 taker를 설정합니다.
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        // 35_참가자가 참여하면서 게임의 베팅 금액이 추가되었기 때문에, Game 인스턴스의 betAmount 역시 변경해줍니다.
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        // 36_게임 결과 업데이트, joinRoom 함수가 끝나는 시점에서, 승패를 확인할 수 있습니다.
        // 게임의 결과에 따라 게임의 상태와 참여자들의 상태를 업데이트하는 함수 compareHands()를 작성함.
        compareHands(roomNum); // 게임 결과 업데이트 함수 호출
    }
    
    // 37_게임을 본격적으로 비교하기 때문에, 게임의 상태를 GameStatus.STATUS_STARTED로 변경
    function compareHands(uint roomNum) private{
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);
        
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        
        if (taker == originator){ // 38_비긴 경우 draw
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
            
        }
        else if ((taker +1) % 3 == originator) { // 39_방장이 이긴 경우, originator wins
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        }
        else if ((originator + 1)%3 == taker){ // 40_참가자가 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else { // 41_그 외의 상황에는 게임 상태를 에러로 업데이트한다
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }  
    }

    // 45_isPlayer는 방 번호와 함수를 호출한 사용자이 주소를 받습니다.
    // 그리고 사용자의 주소가 방장 또는 참가자의 주소와 일치하는 지 확인합니다.
    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr,
        "InValidPlayer In this Game!!");
        _;
    }

    // 42_payout 함수는 방 번호를 인자로 받아, 게임 결과에 따라 베팅 금액을 송금하고, 게임을 종료합니다.
    // 컨트랙트에 있는 금액을 송금하기 위해서는 솔리디티에 내장되어 있는 transfer 함수를 사용합니다.
    // ADDRESS.transfer(value) // ADDRESS로 value 만큼 송금합니다.
    // 43_가위바위보 컨트랙트에서는 비긴 경우에는 자신의 베팅 금액을 돌려받고, 이긴 경우에는 전체 베팅 금액을 돌려받습니다.
    // 44_한 가지 중요한 것을 payout 함수를 실행하는 주체는 방장 또는 참가자여야 한다는 점입니다.
    // 참가자는 중간에 자신이 낸 값을 변경할 수 도 있기 때문입니다.
    // 따라서 payout을 실행하기 전 해당 함수를 실행하는 주체가 방장 또는 참가자인지 확인하는 함수 제어자 isPlayer를 만들어야 합니다.
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
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
}