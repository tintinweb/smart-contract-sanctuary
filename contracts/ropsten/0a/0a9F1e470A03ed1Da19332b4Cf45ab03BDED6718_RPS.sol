/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RPS {
    constructor() payable {}

    enum Hand {
        rock,
        paper,
        scissors,
        none
    }

    enum PlayerStatus {
        WIN,
        LOSE,
        TIE,
        PENDING
    }

    enum GameStatus {
        NOT_STARTED,
        STARTED,
        COMPLETE,
        ERROR
    }

    struct Player {
        address payable addr;
        uint256 betAmount;
        Hand hand;
        bytes32 encHand;
        PlayerStatus status;
    }

    struct Game {
        Player originator;
        Player taker;
        uint256 betAmount;
        GameStatus status;
    }

    mapping(uint256 => Game) rooms;
    uint256 roomLen = 0;

    modifier isValidHand(Hand _hand) {
        require(
            (_hand == Hand.rock) ||
                (_hand == Hand.paper) ||
                (_hand == Hand.scissors)
        );
        _;
    }

    event CreateRoomLog(
        address addr,
        uint256 betAmount,
        uint8 hand,
        uint8 status,
        uint256 roomNum
    );

    function createRoom(Hand _hand, string memory password)
        public
        payable
        isValidHand(_hand)
        returns (uint256 roomNum)
    {
        rooms[roomLen] = Game({
            originator: Player({
                addr: payable(msg.sender),
                betAmount: msg.value,
                hand: Hand.none,
                encHand: sha256(abi.encodePacked(_hand, password)),
                status: PlayerStatus.PENDING
            }),
            taker: Player({
                addr: payable(msg.sender),
                betAmount: 0,
                hand: Hand.none,
                encHand: sha256(abi.encodePacked(_hand, password)),
                status: PlayerStatus.PENDING
            }),
            betAmount: msg.value,
            status: GameStatus.NOT_STARTED
        });
        roomNum = roomLen;
        roomLen = roomLen + 1;
        emit CreateRoomLog(
            payable(msg.sender),
            msg.value,
            uint8(_hand),
            uint8(PlayerStatus.PENDING),
            roomNum
        );

        return roomNum;
    }

    event JoinRoomLog(
        uint256 roomNum,
        uint8 hand,
        uint8 status,
        uint256 betAmount
    );

    function joinRoom(
        uint256 roomNum,
        Hand _hand,
        string memory password
    ) public payable isValidHand(_hand) {
        rooms[roomNum].taker = Player({
            addr: payable(msg.sender),
            betAmount: msg.value,
            hand: Hand.none,
            encHand: sha256(abi.encodePacked(_hand, password)),
            status: PlayerStatus.PENDING
        });

        rooms[roomNum].betAmount =
            rooms[roomNum].originator.betAmount +
            msg.value;

        emit JoinRoomLog(
            roomNum,
            uint8(_hand),
            uint8(rooms[roomNum].taker.status),
            uint256(rooms[roomNum].betAmount)
        );
    }

    function revealOriginator(
        uint256 roomNum,
        Hand _hand,
        string memory password
    ) public {
        if (
            sha256(abi.encodePacked(_hand, password)) ==
            rooms[roomNum].originator.encHand
        ) {
            rooms[roomNum].originator.hand = _hand;
        }

        if (
            rooms[roomNum].originator.hand != Hand.none &&
            rooms[roomNum].taker.hand != Hand.none
        ) {
            compareHands(roomNum);
        }
    }

    function revealTaker(
        uint256 roomNum,
        Hand _hand,
        string memory password
    ) public {
        if (
            sha256(abi.encodePacked(_hand, password)) ==
            rooms[roomNum].taker.encHand
        ) {
            rooms[roomNum].taker.hand = _hand;
        }
        if (
            rooms[roomNum].originator.hand != Hand.none &&
            rooms[roomNum].taker.hand != Hand.none
        ) {
            compareHands(roomNum);
        }
    }

    event CompareHandsLog(
        uint256 roomNum,
        uint8 originatorHand,
        uint8 takerHand,
        uint8 roomStatus
    );

    function compareHands(uint256 roomNum) private {
        uint8 originatorHand = uint8(rooms[roomNum].originator.hand);
        uint8 takerHand = uint8(rooms[roomNum].taker.hand);

        rooms[roomNum].status = GameStatus.STARTED;

        if (originatorHand == takerHand) {
            rooms[roomNum].originator.status = PlayerStatus.TIE;
            rooms[roomNum].taker.status = PlayerStatus.TIE;
        } else if ((takerHand + 1) % 3 == originatorHand) {
            // 방장 승리
            rooms[roomNum].originator.status = PlayerStatus.WIN;
            rooms[roomNum].taker.status = PlayerStatus.LOSE;
        } else if ((originatorHand + 1) % 3 == takerHand) {
            // 참가자 승리
            rooms[roomNum].originator.status = PlayerStatus.LOSE;
            rooms[roomNum].taker.status = PlayerStatus.WIN;
        } else {
            rooms[roomNum].status = GameStatus.ERROR;
        }

        emit CompareHandsLog(
            roomNum,
            originatorHand,
            takerHand,
            uint8(rooms[roomNum].status)
        );

        payout(roomNum);
    }

    modifier isPlayer(uint256 roomNum, address sender) {
        require(
            sender == rooms[roomNum].originator.addr ||
                sender == rooms[roomNum].taker.addr
        );
        _;
    }

    event PayOutLog(string log);

    function payout(uint256 roomNum) public payable {
        if (
            rooms[roomNum].originator.status == PlayerStatus.TIE &&
            rooms[roomNum].taker.status == PlayerStatus.TIE
        ) {
            rooms[roomNum].originator.addr.transfer(
                rooms[roomNum].originator.betAmount
            );
            rooms[roomNum].taker.addr.transfer(rooms[roomNum].taker.betAmount);
        } else {
            if (rooms[roomNum].originator.status == PlayerStatus.WIN) {
                rooms[roomNum].originator.addr.transfer(
                    rooms[roomNum].betAmount
                );
            } else if (rooms[roomNum].taker.status == PlayerStatus.WIN) {
                rooms[roomNum].taker.addr.transfer(rooms[roomNum].betAmount);
            } else {
                rooms[roomNum].originator.addr.transfer(
                    rooms[roomNum].originator.betAmount
                );
                rooms[roomNum].taker.addr.transfer(
                    rooms[roomNum].taker.betAmount
                );
            }
        }
        emit PayOutLog("Paid");
        rooms[roomNum].status = GameStatus.COMPLETE; // 게임이 종료되었으므로 게임 상태 변경
    }
}