/**
 *Submitted for verification at Etherscan.io on 2021-12-12
*/

// 라이센스 설정
//SPDX-License-Identifier: MIT
// 솔리디티 컴파일러 설정 : 0.8.7 이상의 컴파일 허용
pragma solidity ^0.8.7;

// 솔리디티 스마크 컨트랙트 작성(RPS game)
contract RPS {
    // 생성자 함수 : constructor : 생성자 함수 선언시, 컨트랙트 생성시 생성자 함수가 실행되며 컨트랙트의 상태를 초기화함.
    constructor () payable {}

    enum Hand { rock, paper, scissors } // rock:0, paper:1, scissors:2

    // 함수 변경자 : modifier : 함수 정의 부분의 modifier를 사용해, 함수 실행 전 요구 조건을 만족하는지 확인.
    modifier isValidHand (Hand _hand) {
    	// 에러 핸들링 : require( 조건, 에러메시지 ) : 조건이 맞다면 통과하지만 틀리면 에러를 발생시킵니다.
    	require((_hand  == Hand.rock) || (_hand  == Hand.paper) || (_hand == Hand.scissors), "InValidHand!!");
        _; // 함수 실행
        //... // (있다면, )함수 끝난 후 실행 (지금은 없음)
    }

    // Player의 상태(이김, 짐, 비김, 대기)
    enum PlayerStatus{ STATUS_WIN, STATUS_LOSE, STATUS_TIE, STATUS_PENDING }

    // Game의 상태 (게임시작안함=대기중, 게임시작=게임중, 게임완료=게임끝, 게임오류=오류발생)
    enum GameStatus { STATUS_NOT_STARTED, STATUS_STARTED, STATUS_COMPLETE, STATUS_ERROR }

    // 구조체 player
    struct Player {
    	// (송금불가_0.8버전 이상)주소 : address : 0x로 시작하고 최대 40자리의 16진수로 구성되는 문자열, 크기는 20바이트
        // 송금 가능한 주소 : address payable : 이더 송금을 위해 transfer()와 send() 함수가 내장되어 있음.
    	address payable addr; // Player의 지갑 주소
    	uint256 playerBetAmount; // 게임의 베팅금액(256비트)
    	Hand hand; // Player의 손모양(0,1,2 중 하나, 이외의 값인 경우 에러 발생)
    	PlayerStatus playerStatus; // Player의 상태
    }

    // 구조체 Game
    struct Game {
    	Player originator; // 방장 Player의 정보(지갑 주소, 베팅 금액, 손 모양, 상태)
    	Player taker; // 참여자 Player의 정보(지갑 주소, 베팅 금액, 손 모양, 상태)
    	uint256 betAmount; // 총 베팅 금액(방장 베팅금액 + 참여자 베팅금액 - 각종 수수료?)
    	GameStatus gameStatus; // Game의 상태(이김, 짐, 비김, 대기)
    }

    // 매핑 : mapping : 스토리지 데이터 영역에 '키-값' 구조의 데이터를 저장함.
    // uint라는 키의 형식, Game이라는 값의 형식, rooms는 변수
    // rooms[uint형식의 키값] = Game형식의 값
    mapping(uint => Game) rooms;

    // 방장이 생성한 방의 개수를 저장(createRoom 함수 실행시 1씩 증가할 예정)
    uint roomLen = 0;

    // 함수명 : createRoom : 방장이 방을 만들때 사용함.
    // 입력값 : (Hand _hand) : 방장이 제시하는 손모양
    // 함수 접근 수준 : public : 컨트랙트 내부, 외부 컨트랙트, 클라이언트 코드에서 호출 가능.
    // payable : 선언하면 함수에서 이더를 받을 수 있음.
    // isValidHand(_hand) : 방장이 제시한 손모양이 유요한 값인지 확인.
    // returns (uint roomNum) : uint roomNum 형식을 반환함.
    function createRoom (Hand _hand) public payable isValidHand (_hand) returns (uint roomNum) {
    	// 첫번째 생성된 방인 경우, rooms[0] = Game 구조체가 대입됩니다.
    	rooms[roomLen] = Game({
        	// 방장의 배팅 금액을 넣습니다.
            // 글로벌 변수 : msg : 컨트랙트를 시작한 트랜잭션 콜이나 메시지 콜에 대한 정보를 가짐.
            // 방장의 트랜잭션 메시지 정보 = msg, msg.value : 메시지와 함꼐 보낸 이더 금액, uint 형식.
    		betAmount: msg.value,
            // 방을 만들었을 때는 아직 시작하지 않은 상태.
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            // 방장에 대한 정보 입력
            originator: Player({
            	// 방장이 제시한 손모양(함수의 입력 값)
    			hand: _hand,
                // 방장의 지갑 주소
                // msg.sender : 호출을 수행하고 있는 메시지 발신자의 주소
                // address payable로 바꾸기 위해, payable(msg.sender)
                addr: payable(msg.sender),
                // 방을 만들고 아직 참여자가 없기 때문에, 방장의 상태는 대기로 설정.
    			playerStatus: PlayerStatus.STATUS_PENDING,
                // 방장이 배팅한 금액
    			playerBetAmount: msg.value
    		}),
            // 참여자에 대한 정보 입력
    		taker: Player({
            	// 아직 참여자가 없기 때문에, 참여자가 제시한 손모양을 임시로 rock이라는 손목양을 할당함.
    			hand: Hand.rock,
                // 아직 참여자가 없기 때문에, 참여자가 지갑주소를 임시로 방장의 주소를 할당함.
    			addr: payable(msg.sender),
                // 아직 참여자가 없기 때문에, 참여자의 상태를 임시로 대기 상태를 할당함.
    			playerStatus: PlayerStatus.STATUS_PENDING,
                // 아직 참여자가 없기 때문에, 참여자의 배팅 금액을 임시로 0을 할당함.
    			playerBetAmount: 0
    		})
    	});
        // roomNum은 리턴하는 변수.
        // 생성한 방에 대한 인덱스로 roomLen을 대입, 0부터 시작
    	roomNum = roomLen;
        // 다음 생성될 방의 인덱스를 위해 값을 1 올림.
    	roomLen = roomLen+1;
    }

    // 함수명 : joinRoom : 방장이 만든 방에 참여하기.
    // 입력값 : (uint roomNum, Hand _hand)
    // roomNum은 createRoom의 리턴 값을 찾아 넣어야 함
    // _hand은 참여자가 제시하는 손모양
    // 나머지 createRoom의 설명과 동일
    function joinRoom(uint roomNum, Hand _hand) public payable isValidHand( _hand) {
    	// 참여한 roomNum에 해당하는 방의 taker(참여자)의 Player 정보를 설정함
    	rooms[roomNum].taker = Player({
        	// 참여자가 제시한 손모양(함수의 입력 값)
    		hand: _hand,
            // 참여자의 지갑 주소
            // msg.sender : 호출을 수행하고 있는 메시지 발신자의 주소
            // address payable로 바꾸기
    		addr: payable(msg.sender),
            // 게임을 아직 시작하지 않았기 때문에, 참여자의 상태를 대기로 설정.
    		playerStatus: PlayerStatus.STATUS_PENDING,
            // 참여자가 배팅한 금액
    		playerBetAmount: msg.value
    	});
        // 전역변수 rooms(위에 작성함)에 접근하기
        // createRoom 함수에서 기존 방장의 베팅금액에 참여자의 베팅금액 더하기
    	rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;

    	// 방장이 만든 방에 참여자가 게임에 참여한 상태에서 게임 시작을 위해, compareHands 함수 호출
    	compareHands(roomNum); // 게임 결과 업데이트 함수 호출
    }

    // 함수명 : compareHands : 게임의 시작, 방장의 손모양과 참여자의 손모양을 비교
    // 입력값 : (uint roomNum) : 게임의 인덱스, 게임의 인덱스만 알면 rooms를 통해 정보를 확인 가능
    // 함수 접근 수준 : private : 컨트랙트 멤버만 호출할 수 있음. 외부에서 게임을 방해하면 안됨.
    function compareHands(uint roomNum) private {
    	// originator에 방장의 손모양을 대입
    	uint8 originator = uint8(rooms[roomNum].originator.hand);
        // taker에 참여자의 손모양을 대입
    	uint8 taker = uint8(rooms[roomNum].taker.hand);

        // 방의 게임상태를 게임 시작상태로 변경
        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        // 손모양이 같은 경우 게임이 비김
    	if (taker == originator){
        	// 방장의 player 상태를 TIE로
    		rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
    		// 참여자의 player 상태를 TIE로
    		rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;    
    	}
        // 방장이 이긴 경우
    	else if ((taker +1) % 3 == originator) {
        	// 방장의 player 상태를 WIN으로
    		rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
        	// 참여자의 player 상태를 LOSE로
    		rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
    	}
        // 참여자가 이긴 경우
    	else if ((originator + 1)%3 == taker){
        	// 방장의 player 상태를 LOSE로
    		rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
        	// 참여자의 player 상태를 WIN으로
    		rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
    	}
        // 그 외의 상황에 대해서
        else {
        	// 게임 상태를 ERROR로 처리
    		rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
    	}  
    }

    // 게임 결과에 따라 베팅 금액을 송금하기 전, 방장과 참여자의 지갑 주로를 확인함.
    // 입력값 : (uint roomNum, address sender)
    // roomNum : 게임의 방 인덱스, sender : 현재 호출을 수행하는 메시지 발신자
    // payout 함수를 호출하는 사람이 방장인 경우 sender는 방장의 지갑 주소
    // payout 함수를 호출하는 사람이 참여자인 경우 sender는 참여자의 지갑 주소
    modifier isPlayer (uint roomNum, address sender) {
    	// 주소는 방장 또는 참여자의 주소라야만 오류가 나지 않음, 엉뚱한 사람이 payout을 요구하면 오류 발생.
    	require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr, "InValidPlayer In this Game!!");
    	_;
    }
    
    // 함수명 : payout : 게임 결과에 따라 베팅 금액을 송금하고 게임을 종료함.
    // 입력값 : (uint roomNum) : roomNum 인덱스에 따라 게임 방 정보에 접근가능.
    // isPlayer(roomNum, msg.sender) : payout 함수 실행한 사람이 방장과 참여자인지 검사.
    function payout(uint roomNum) public payable isPlayer(roomNum, msg.sender) {
    	// 방장과 참여자의 상태가 모두 TIE라면
    	if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE && rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE) {
    		// 방장의 지갑에 본인이 베팅한 이더만큼을 전송함, 비겼으니까
    		// transfer() : 이더를 계정에 전송하는 함수
    		rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
    		// 참여자의 지갑에 본인이 베팅한 이더만큼을 전송함, 비겼으니까
    		rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
    	}
        else {
    		// 방장이 이겼다면
        	if (rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_WIN) {
    			// 방장의 지갑에 게임의 총 베팅금액을 전송함.
    			rooms[roomNum].originator.addr.transfer(rooms[roomNum].betAmount);
    		}
    		// 참여자가 이겼다면
            else if (rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN) {
    			// 참여자의 지갑에 게임의 총 베팅금액을 전송함.
    			rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
    		}
    		// 그 외 경우라면
            else {
    			// 방장의 지갑에 본인이 배팅한 금액을 전송
    			rooms[roomNum].originator.addr.transfer(rooms[roomNum].originator.playerBetAmount);
    			// 참여자의 지갑에 본인이 배팅한 금액을 전송
    			rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.playerBetAmount);
    		}
    	}
        // 게임의 상태를 완료로 바꿈
    	rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE;
    }
}