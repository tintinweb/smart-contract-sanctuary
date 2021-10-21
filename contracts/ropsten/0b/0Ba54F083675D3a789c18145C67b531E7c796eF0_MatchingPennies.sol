// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.9;

contract MatchingPennies {
    struct Game {
        uint8 choiceA;
        uint8 choiceB;
        bytes32 commitmentA;
        bytes32 commitmentB;
        bytes32 randomA;
        bytes32 randomB;
        address payable playerA;
        address payable playerB;
    }
    event WinnerAnounce(
        address winner,
        address playerA,
        address playerB,
        bytes32 commitmentA,
        bytes32 commitmentB,
        uint8 choiceA,
        uint8 choiceB,
        bytes32 randomA,
        bytes32 randomB
    );
    uint256 public constant betAmount = 1 ether;
    uint256 public constant timeOut = 10 minutes;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 public lastUpdate;
    uint256 private _status;
    Game public game;

    // mapping (address => uint256) public balance;

    constructor() {
        _status = _NOT_ENTERED;
        lastUpdate = block.timestamp;
    }

    function isMatching() private view returns (bool) {
        return (game.playerA == address(0) || game.playerB == address(0));
    }

    function isCommitting() private view returns (bool) {
        return (game.playerA != address(0) &&
            game.playerB != address(0) &&
            (game.commitmentA == 0 || game.commitmentB == 0));
    }

    function isRevealing() private view returns (bool) {
        return (game.playerA != address(0) &&
            game.playerB != address(0) &&
            game.commitmentA != 0 &&
            game.commitmentB != 0 &&
            (game.choiceA == 0 || game.choiceB == 0));
    }

    function isCalculating() private view returns (bool) {
        return (game.playerA != address(0) &&
            game.playerB != address(0) &&
            game.commitmentA != 0 &&
            game.commitmentB != 0 &&
            game.choiceA != 0 &&
            game.choiceB != 0);
    }

    modifier equalToBetAmount() {
        require(msg.value == betAmount);
        _;
    }
    modifier registered() {
        require(
            msg.sender == game.playerA || msg.sender == game.playerB,
            "You haven't registered for the game!"
        );
        _;
    }
    modifier unregistered() {
        require(
            msg.sender != game.playerA && msg.sender != game.playerB,
            "You have already registered for the game!"
        );
        _;
    }
    modifier matching() {
        require(isMatching(), "Game is not matching!");
        _;
    }
    modifier committing() {
        require(isCommitting(), "Game is not committing!");
        _;
    }
    modifier revealing() {
        require(isRevealing(), "Game is not revealing!");
        _;
    }
    modifier calculating() {
        require(isCalculating(), "Game is not calculating!");
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
        if (game.playerA == address(0)) {
            game.playerA = payable(msg.sender);
            lastUpdate = block.timestamp;
            return "Registered as player A";
        } else if (game.playerB == address(0)) {
            game.playerB = payable(msg.sender);
            lastUpdate = block.timestamp;
            return "Registered as player B";
        } else {
            revert("Game has started! Register for the next game!");
        }
    }

    function commit(bytes32 commitment) external committing registered {
        if (msg.sender == game.playerA) {
            require(
                game.commitmentA == 0,
                "You have already made a commitment!"
            );
            game.commitmentA = commitment;
        } else if (msg.sender == game.playerB) {
            require(
                game.commitmentB == 0,
                "You have already made a commitment!"
            );
            game.commitmentB = commitment;
        }
        lastUpdate = block.timestamp;
    }

    function reveal(uint8 choice, bytes32 random)
        external
        revealing
        registered
    {
        require(choice == 1 || choice == 2, "You have made a invalid choice!");
        if (msg.sender == game.playerA) {
            require(game.choiceA == 0, "You have already revealed a choice!");
            require(
                game.commitmentA == keccak256(abi.encodePacked(choice, random)),
                "Your revealing didn't match your commitment!"
            );
            game.choiceA = choice;
            game.randomA = random;
        } else if (msg.sender == game.playerB) {
            require(game.choiceB == 0, "You have already revealed a choice!");
            require(
                game.commitmentB == keccak256(abi.encodePacked(choice, random)),
                "Your revealing didn't match your commitment!"
            );
            game.choiceB = choice;
            game.randomB = random;
        }
        lastUpdate = block.timestamp;
        if (game.choiceA != 0 && game.choiceB != 0) {
            calculate();
        }
    }

    function calculate() private {
        address payable winner;
        if (game.choiceA == game.choiceB) {
            winner = game.playerA;
        } else {
            winner = game.playerB;
        }
        emit WinnerAnounce(
            winner,
            game.playerA,
            game.playerB,
            game.commitmentA,
            game.commitmentB,
            game.choiceA,
            game.choiceB,
            game.randomA,
            game.randomB
        );
        reset();
        winner.transfer(2 ether);
    }

    function timeOutCheck() public view returns (bool) {
        return block.timestamp < (lastUpdate + timeOut);
    }

    function timeOutReset() public nonReentrant {
        address payable refundAddress;
        uint256 refundAmount;
        require(block.timestamp < (lastUpdate + timeOut), "Didn't time out!");
        if (isMatching()) {
            //game is in matching phase
            //Only player A has registored for the game, so refund the player A money.
            refundAddress = game.playerA;
            refundAmount = 1 ether;
            reset();
        } else if (isCommitting()) {
            //game is in committing phase
            if (game.commitmentA == 0 && game.commitmentB == 0) {
                //If both player haven't made a commitment within the timeout period then the contract won't refund their money.
                reset();
            } else if (game.commitmentA != 0 && game.commitmentB == 0) {
                //If a player make a commitment but the other player don't within the timeout period, then this player become the winner and take the reward.
                refundAddress = game.playerA;
                refundAmount = 2 ether;
            } else if (game.commitmentA == 0 && game.commitmentB != 0) {
                refundAddress = game.playerB;
                refundAmount = 2 ether;
            }
            emit WinnerAnounce(
                refundAddress,
                game.playerA,
                game.playerB,
                game.commitmentA,
                game.commitmentB,
                game.choiceA,
                game.choiceB,
                game.randomA,
                game.randomB
            );
            reset();
        } else if (isRevealing()) {
            //game is in revealing phase
            if (game.choiceA == 0 && game.choiceB == 0) {
                //If both player haven't revealed within the timeout period then the contract won't refund their money.
                reset();
            } else if (game.choiceA != 0 && game.choiceB == 0) {
                //If a player reveal but the other player don't within the timeout period, then this player become the winner and take the reward.
                refundAddress = game.playerA;
                refundAmount = 2 ether;
            } else if (game.choiceA == 0 && game.choiceB != 0) {
                refundAddress = game.playerB;
                refundAmount = 2 ether;
            }
            emit WinnerAnounce(
                refundAddress,
                game.playerA,
                game.playerB,
                game.commitmentA,
                game.commitmentB,
                game.choiceA,
                game.choiceB,
                game.randomA,
                game.randomB
            );
            reset();
        }
        // if the refundAddress isn't empty, transfer the refund or reward to it.
        if (refundAddress != address(0)) {
            refundAddress.transfer(refundAmount);
        }
    }

    function reset() private {
        game.playerA = payable(address(0));
        game.playerB = payable(address(0));
        game.commitmentA = 0;
        game.commitmentB = 0;
        game.choiceA = 0;
        game.choiceB = 0;
        game.randomA = 0;
        game.randomB = 0;
    }

    function getGameStatus() public view returns (string memory) {
        if (isMatching()) {
            return "Matching";
        } else if (isCommitting()) {
            return "Committing";
        } else if (isRevealing()) {
            return "Revealing";
        } else {
            return "Calculating";
        }
    }
}