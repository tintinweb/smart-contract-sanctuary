// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.9;

contract MatchingPennies {
    uint256 public constant betAmount = 1 ether;
    uint256 public constant timeOut = 10 minutes;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 public lastUpdate;
    uint256 private _status;
    // mapping (address => uint256) public balance;
    enum Outcomes {
        None,
        PlayerA,
        PlayerB
    }
    struct Game {
        address payable playerA;
        address payable playerB;
        bytes32 encryptedChoicePlayerA;
        bytes32 encryptedChoicePlayerB;
        uint8 choicePlayerA;
        uint8 choicePlayerB;
        Outcomes outcome;
    }
    event WinnerAnounce(address winner);
    Game public lastGame;
    Game public gameOngoing;

    constructor() {
        _status = _NOT_ENTERED;
        lastUpdate = block.timestamp;
    }

    modifier equalToBetAmount() {
        require(msg.value == betAmount);
        _;
    }
    modifier registered() {
        require(
            msg.sender == gameOngoing.playerA ||
                msg.sender == gameOngoing.playerB,
            "You haven't registered for the game!"
        );
        _;
    }
    modifier unregistered() {
        require(
            msg.sender != gameOngoing.playerA &&
                msg.sender != gameOngoing.playerB,
            "You have already registered for the game!"
        );
        _;
    }
    modifier matching() {
        require(
            gameOngoing.playerA == address(0) ||
                gameOngoing.playerB == address(0),
            "Game is not matching!"
        );
        _;
    }
    modifier committing() {
        require(
            gameOngoing.playerA != address(0) &&
                gameOngoing.playerB != address(0) &&
                (gameOngoing.encryptedChoicePlayerA == 0 ||
                    gameOngoing.encryptedChoicePlayerB == 0),
            "Game is not committing!"
        );
        _;
    }
    modifier revealing() {
        require(
            gameOngoing.playerA != address(0) &&
                gameOngoing.playerB != address(0) &&
                gameOngoing.encryptedChoicePlayerA != 0 &&
                gameOngoing.encryptedChoicePlayerB != 0 &&
                (gameOngoing.choicePlayerA == 0 ||
                    gameOngoing.choicePlayerB == 0),
            "Game is not revealing!"
        );
        _;
    }
    modifier calculating() {
        require(
            gameOngoing.playerA != address(0) &&
                gameOngoing.playerB != address(0) &&
                gameOngoing.encryptedChoicePlayerA != 0 &&
                gameOngoing.encryptedChoicePlayerB != 0 &&
                gameOngoing.choicePlayerA != 0 &&
                gameOngoing.choicePlayerB != 0,
            "Game is not calculating!"
        );
        _;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function registor()
        external
        payable
        equalToBetAmount
        unregistered
        matching
        returns (string memory)
    {
        if (gameOngoing.playerA == address(0)) {
            gameOngoing.playerA = payable(msg.sender);
            lastUpdate = block.timestamp;
            return "Registered as player A";
        } else if (gameOngoing.playerB == address(0)) {
            gameOngoing.playerB = payable(msg.sender);
            lastUpdate = block.timestamp;
            return "Registered as player B";
        } else {
            revert("Game has started! Register for the next game!");
        }
    }

    function commit(bytes32 encryptedChoice) external committing registered {
        if (msg.sender == gameOngoing.playerA) {
            require(
                gameOngoing.encryptedChoicePlayerA == 0,
                "You have already made a choice!"
            );
            gameOngoing.encryptedChoicePlayerA = encryptedChoice;
        } else if (msg.sender == gameOngoing.playerB) {
            require(
                gameOngoing.encryptedChoicePlayerB == 0,
                "You have already made a choice!"
            );
            gameOngoing.encryptedChoicePlayerB = encryptedChoice;
        }
        lastUpdate = block.timestamp;
    }

    function reveal(uint8 playerChoice, bytes32 randomNumber)
        external
        revealing
        registered
    {
        require(
            playerChoice == 1 || playerChoice == 2,
            "You have made a invalid choice!"
        );
        if (msg.sender == gameOngoing.playerA) {
            require(
                gameOngoing.choicePlayerA == 0,
                "You have already revealed a choice!"
            );
            require(
                gameOngoing.encryptedChoicePlayerA ==
                    keccak256(abi.encodePacked(playerChoice, randomNumber)),
                "Your revealing didn't match your choice!"
            );
            gameOngoing.choicePlayerA = playerChoice;
        } else if (msg.sender == gameOngoing.playerB) {
            require(
                gameOngoing.choicePlayerB == 0,
                "You have already revealed a choice!"
            );
            require(
                gameOngoing.encryptedChoicePlayerB ==
                    keccak256(abi.encodePacked(playerChoice, randomNumber)),
                "Your revealing didn't match your choice!"
            );
            gameOngoing.choicePlayerB = playerChoice;
        }
        lastUpdate = block.timestamp;
        if (gameOngoing.choicePlayerA != 0 && gameOngoing.choicePlayerB != 0) {
            calculate();
        }
    }

    function calculate() private {
        address payable winner;
        if (gameOngoing.choicePlayerA == gameOngoing.choicePlayerB) {
            gameOngoing.outcome = Outcomes.PlayerA;
            winner = gameOngoing.playerA;
        } else {
            gameOngoing.outcome = Outcomes.PlayerB;
            winner = gameOngoing.playerB;
        }
        //lastGame = gameOngoing;
        reset();

        winner.transfer(2 ether);
        emit WinnerAnounce(winner);

        // balance[winner] += 2 ether;
    }

    // function withdraw() external{
    //     uint256 money = balance[msg.sender];
    //     balance[msg.sender] = 0;
    //     payable(msg.sender).transfer(money);
    // }

    // function timeOutCheck() public nonReentrant {
    //     address payable refundAddress;
    //     uint256 refundAmount;
    //     if (gameOngoing.gameStatus == GameStatus.Matching) {
    //         if (matchingDeadline != 0 && matchingDeadline < block.timestamp) {
    //             refundAddress = gameOngoing.playerA;
    //             refundAmount = 1 ether;
    //             reset();
    //         }
    //     } else if (gameOngoing.gameStatus == GameStatus.Playing) {
    //         if (playingDeadline != 0 && playingDeadline < block.timestamp) {
    //             if (
    //                 gameOngoing.encryptedChoicePlayerA == 0 &&
    //                 gameOngoing.encryptedChoicePlayerB == 0
    //             ) {
    //                 reset();
    //             } else if (
    //                 gameOngoing.encryptedChoicePlayerA != 0 &&
    //                 gameOngoing.encryptedChoicePlayerB == 0
    //             ) {
    //                 refundAddress = gameOngoing.playerA;
    //                 refundAmount = 2 ether;
    //                 gameOngoing.outcome = Outcomes.PlayerA;
    //             } else if (
    //                 gameOngoing.encryptedChoicePlayerA == 0 &&
    //                 gameOngoing.encryptedChoicePlayerB != 0
    //             ) {
    //                 refundAddress = gameOngoing.playerB;
    //                 refundAmount = 2 ether;
    //                 gameOngoing.outcome = Outcomes.PlayerB;
    //             }
    //             gameHistory.push(gameOngoing);
    //             reset();
    //         }
    //     } else if (gameOngoing.gameStatus == GameStatus.Revealing) {
    //         if (revealingDeadline != 0 && revealingDeadline < block.timestamp) {
    //             if (
    //                 gameOngoing.choicePlayerA == Choice.None &&
    //                 gameOngoing.choicePlayerB == Choice.None
    //             ) {
    //                 reset();
    //             } else if (
    //                 gameOngoing.choicePlayerA != Choice.None &&
    //                 gameOngoing.choicePlayerB == Choice.None
    //             ) {
    //                 refundAddress = gameOngoing.playerA;
    //                 refundAmount = 2 ether;
    //                 gameOngoing.outcome = Outcomes.PlayerA;
    //             } else if (
    //                 gameOngoing.choicePlayerA == Choice.None &&
    //                 gameOngoing.choicePlayerB != Choice.None
    //             ) {
    //                 refundAddress = gameOngoing.playerB;
    //                 refundAmount = 2 ether;
    //                 gameOngoing.outcome = Outcomes.PlayerB;
    //             }
    //             gameHistory.push(gameOngoing);
    //             reset();
    //         }
    //     }
    //     if (refundAddress != address(0)) {
    //         refundAddress.transfer(refundAmount);
    //     }
    // }

    function reset() private {
        gameOngoing.playerA = payable(address(0));
        gameOngoing.playerB = payable(address(0));
        gameOngoing.encryptedChoicePlayerA = 0;
        gameOngoing.encryptedChoicePlayerB = 0;
        gameOngoing.choicePlayerA = 0;
        gameOngoing.choicePlayerB = 0;
    }

    function getOngoingGameStatus() public view returns (string memory) {
        if (
            gameOngoing.playerA == address(0) ||
            gameOngoing.playerB == address(0)
        ) {
            return "Matching";
        } else if (
            gameOngoing.playerA != address(0) &&
            gameOngoing.playerB != address(0) &&
            (gameOngoing.encryptedChoicePlayerA == 0 ||
                gameOngoing.encryptedChoicePlayerB == 0)
        ) {
            return "Committing";
        } else if (
            gameOngoing.playerA != address(0) &&
            gameOngoing.playerB != address(0) &&
            gameOngoing.encryptedChoicePlayerA != 0 &&
            gameOngoing.encryptedChoicePlayerB != 0 &&
            (gameOngoing.choicePlayerA == 0 || gameOngoing.choicePlayerB == 0)
        ) {
            return "Revealing";
        } else {
            return "Calculating";
        }
    }

    // function getLastGameInformation()
    //     public
    //     view
    //     returns (
    //         address,
    //         address,
    //         Outcomes
    //     )
    // {
    //     Game memory game = gameHistory[gameHistory.length - 1];
    //     return (game.playerA, game.playerB, game.outcome);
    // }
}