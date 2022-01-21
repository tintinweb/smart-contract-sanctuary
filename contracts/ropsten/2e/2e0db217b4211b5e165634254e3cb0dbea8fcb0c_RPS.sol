/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    constructor() payable {}

    enum Hand {
        rock,
        paper,
        scissors
    }

    //플레이어 상태
    enum PlayerStatus {
        STATUS_WIN,
        STATUS_LOSE,
        STATUS_TIE,
        STATUS_PENDING
    }
    // 게임의 상태
    enum GameStatus {
        STATUS_NOT_STARTED,
        STATUS_STARTED,
        STATUS_COMPLETE,
        STATUS_ERROR
    }

    struct Player {
        address payable addr;
        uint256 playerBetAmount;
        Hand hand;
        PlayerStatus playerStatus; // 사용자의 현 상태
    }
    struct Game {
        Player originator; // 방장 정보
        Player taker; // 참여자 정보
        uint256 betAmount; // 총 베팅 금액
        GameStatus gameStatus; // 게임의 현 상태
    }

    mapping(uint256 => Game) rooms; // rooms[0], rooms[1] 형식으로 접근할 수 있으며, 각 요소는 Game 구조체 형식입니다.
    uint256 roomLen = 0; // rooms의 키 값입니다. 방이 생성될 때마다 1씩 올라갑니다.

    modifier isValidHand(Hand _hand) {
        require(
            (_hand == Hand.rock) || (_hand == Hand.paper) || (_hand == Hand.scissors)
        );
        _;
    }

    modifier isPlayer (uint roomNum, address sender) {
        require(sender == rooms[roomNum].originator.addr || sender == rooms[roomNum].taker.addr);
        _;
    }


    function createRoom(Hand _hand)
        public
        payable
        isValidHand(_hand)
        returns (uint256 roomNum)
    {
        rooms[roomLen] = Game({
            betAmount: msg.value,
            gameStatus: GameStatus.STATUS_NOT_STARTED,
            originator: Player({
                hand: _hand,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: msg.value
            }),
            taker: Player({
                hand: Hand.rock,
                addr: payable(msg.sender),
                playerStatus: PlayerStatus.STATUS_PENDING,
                playerBetAmount: 0
            })
        });
        roomNum = roomLen; // roomNum은 리턴된다.
        roomLen = roomLen + 1; // 다음 방 번호를 설정
    }

    function joinRoom(uint256 roomNum, Hand _hand)
        public
        payable
        isValidHand(_hand)
    {
        rooms[roomNum].taker = Player({
            hand: _hand,
            addr: payable(msg.sender),
            playerStatus: PlayerStatus.STATUS_PENDING,
            playerBetAmount: msg.value
        });
        rooms[roomNum].betAmount = rooms[roomNum].betAmount + msg.value;
        compareHands(roomNum); // 게임 결과 업데이트 함수 호출
    }

    function compareHands(uint256 roomNum) private {
        uint8 originator = uint8(rooms[roomNum].originator.hand);
        uint8 taker = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].gameStatus = GameStatus.STATUS_STARTED;
        if (taker == originator) {
            // 비긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_TIE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_TIE;
        } else if ((taker + 1) % 3 == originator) {
            // 방장이 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_WIN;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_LOSE;
        } else if ((originator + 1) % 3 == taker) {
            // 참가자가 이긴 경우
            rooms[roomNum].originator.playerStatus = PlayerStatus.STATUS_LOSE;
            rooms[roomNum].taker.playerStatus = PlayerStatus.STATUS_WIN;
        } else {
            // 그 외의 상황에는 게임 상태를 에러로 업데이트한다
            rooms[roomNum].gameStatus = GameStatus.STATUS_ERROR;
        }
    }

    function payout(uint256 roomNum) public payable isPlayer(roomNum, msg.sender) {
        if (
            rooms[roomNum].originator.playerStatus == PlayerStatus.STATUS_TIE &&
            rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_TIE
        ) {
            rooms[roomNum].originator.addr.transfer(
                rooms[roomNum].originator.playerBetAmount
            );
            rooms[roomNum].taker.addr.transfer(
                rooms[roomNum].taker.playerBetAmount
            );
        } else {
            if (
                rooms[roomNum].originator.playerStatus ==
                PlayerStatus.STATUS_WIN
            ) {
                rooms[roomNum].originator.addr.transfer(
                    rooms[roomNum].betAmount
                );
            } else if (
                rooms[roomNum].taker.playerStatus == PlayerStatus.STATUS_WIN
            ) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(
                    rooms[roomNum].originator.playerBetAmount
                );
                rooms[roomNum].taker.addr.transfer(
                    rooms[roomNum].taker.playerBetAmount
                );
            }
        }
        rooms[roomNum].gameStatus = GameStatus.STATUS_COMPLETE; // 게임이 종료되었으므로 게임 상태 변경
    }
}