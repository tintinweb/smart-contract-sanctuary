//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RPSGame {
    enum GameStage {
        Open,
        BetsDeposited,
        MovesSubmitted,
        MoveRevealed,
        Completed
    }

    enum Move {
        None,
        Rock,
        Paper,
        Scissors
    }
    Player public playerA;
    Player public playerB;
    uint256 public betAmount;
    GameStage public gameStage;

    struct Player {
        Move move;
        bytes32 hashedMove;
        uint256 balance;
        address addr;
        bool submitted;
        bool revealed;
    }

    constructor(uint256 _betAmount, address _opponent) payable {
        require(msg.sender != _opponent, "You cannot play against yourself");
        betAmount = _betAmount;
        playerA.addr = msg.sender;
        playerB.addr = _opponent;
    }

    event GameStageChanged(GameStage gameStage);
    event ResetGame();
    event Winner(address indexed _winner);
    event Draw();
    event GameComplete();
    event Incentivized(
        address indexed _winner,
        uint256 betAmount,
        uint256 balance
    );

    modifier isPlayer() {
        require(
            msg.sender == playerA.addr || msg.sender == playerB.addr,
            "RPSGame: Not a valid player"
        );
        _;
    }

    function depositBet() external payable isPlayer {
        require(
            msg.value >= betAmount,
            "RPSGame: Balance not enough, Send more fund"
        );

        msg.sender == playerA.addr
            ? playerA.balance += msg.value
            : playerB.balance += msg.value;

        if (playerA.balance >= betAmount && playerB.balance >= betAmount) {
            gameStage = GameStage.BetsDeposited;
            emit GameStageChanged(GameStage.BetsDeposited);
        }
    }

    function submitMove(bytes32 _hashedMove) external isPlayer {
        require(
            gameStage == GameStage.BetsDeposited,
            "RPSGame: game not under progress"
        );
        Player storage player = playerA.addr == msg.sender ? playerA : playerB;

        require(
            !player.submitted,
            "RPSGame: you have already submitted the move"
        );
        player.hashedMove = _hashedMove;
        player.submitted = true;
        if (playerA.submitted && playerB.submitted) {
            gameStage = GameStage.MovesSubmitted;
            emit GameStageChanged(GameStage.MovesSubmitted);
        }
    }

    function revealMove(uint8 _move, bytes32 _salt) external isPlayer {
        require(
            gameStage == GameStage.MovesSubmitted,
            "RPSGame: both players have not submitted move yet."
        );
        // TODO: Should check the reveal time limit
        Player storage currentPlayer = msg.sender == playerA.addr
            ? playerA
            : playerB;
        bytes32 revealedHash = keccak256(abi.encodePacked(_move, _salt));
        // Already revealed
        require(!currentPlayer.revealed, "You have already revealed your move");
        // revealed data not true
        require(
            revealedHash == currentPlayer.hashedMove,
            "RPSGame: Either your salt or move is not same as your submitted hashed move"
        );
        currentPlayer.move = Move(_move);
        currentPlayer.revealed = true;
        if (playerA.revealed && playerB.revealed) {
            pickWinner();
        }
    }

    function pickWinner() private {
        require(
            playerA.submitted && playerB.submitted,
            "RPSGame: Players have not submitted their move"
        );
        address _winner = getWinner();
        if (_winner != address(0)) {
            emit Winner(_winner);
            incentivize(_winner);
        } else {
            emit Draw();
        }
        gameStage = GameStage.Completed;
        emit GameStageChanged(GameStage.Completed);

        resetGame();
    }

    function incentivize(address _winner) internal {
        // Update contract balances of winners and loosers
        if (_winner == playerA.addr) {
            playerA.balance += betAmount;
            playerB.balance -= betAmount;
            emit Incentivized(playerA.addr, betAmount, playerA.balance);
        } else {
            playerB.balance += betAmount;
            playerA.balance -= betAmount;
            emit Incentivized(playerB.addr, betAmount, playerB.balance);
        }
    }

    modifier notUnderProgress() {
        require(
            gameStage != GameStage.MovesSubmitted &&
                gameStage != GameStage.BetsDeposited,
            "RPSGame: Game under progress"
        );
        _;
    }

    function withdrawFund() external isPlayer notUnderProgress {
        Player storage player = msg.sender == playerA.addr ? playerA : playerB;
        require(
            player.balance > 0,
            "RPSGame: You don't have anything to withdraw!"
        );
        payable(player.addr).transfer(player.balance);
    }

    function getWinner() internal view returns (address) {
        if (playerA.move == playerB.move) return address(0);
        if (
            (playerA.move == Move.Rock && playerB.move == Move.Scissors) ||
            (playerA.move == Move.Paper && playerB.move == Move.Rock) ||
            (playerA.move == Move.Scissors && playerB.move == Move.Paper)
        ) {
            return playerA.addr;
        }
        return playerB.addr;
    }

    function resetGame() internal {
        playerA.move = Move.None;
        playerA.submitted = false;
        playerB.move = Move.None;
        playerB.submitted = false;
        gameStage = GameStage.Open;
        emit GameStageChanged(GameStage.Open);
        emit ResetGame();
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 50
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}