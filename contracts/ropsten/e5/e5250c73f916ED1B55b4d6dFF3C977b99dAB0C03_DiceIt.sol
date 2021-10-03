/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DiceIt {
    enum Stage {
        Reg,
        Run,
        Done
    }
    enum CurrentPlayer {
        Owner,
        Challenger
    }

    struct Game {
        uint256 id;
        address owner;
        address challenger;
        Stage stage;
        uint256 maxScore;
        uint256 maxTurn;
        CurrentPlayer currentPlayer;
        Player ownerPlayer;
        Player challengerPlayer;
        address winner;
        uint256 bet;
    }

    struct Player {
        uint256 turn;
        uint256 score;
        bool stop;
    }

    uint256 currentGameIndex = 0;
    mapping(uint256 => Game) public games;

    function createGame(
        address _challenger,
        uint256 _maxScore,
        uint256 _maxTurn
    ) public payable returns (uint256 index) {
        require(msg.value > 0);

        games[currentGameIndex] = Game(
            currentGameIndex,
            msg.sender,
            _challenger,
            Stage.Reg,
            _maxScore,
            _maxTurn,
            CurrentPlayer.Challenger,
            Player(0, 0, false),
            Player(0, 0, false),
            address(0),
            msg.value
        );

        currentGameIndex++;
        return currentGameIndex - 1;
    }

    modifier isStage(uint256 gameId, Stage stage) {
        require(games[gameId].stage == stage);
        _;
    }

    function challengerBet(uint256 gameId) public payable isStage(gameId, Stage.Reg) {
        Game storage game = games[gameId];
        require(msg.value == game.bet);

        game.stage = Stage.Run;
    }


    modifier isPlayerTurn(uint256 gameId, address player) {
        Game memory game = games[gameId];
        uint256 playerIndex;
        if (player == game.owner) {
            require(
                CurrentPlayer.Owner == game.currentPlayer &&
                    !game.ownerPlayer.stop
            );
        } else if (player == game.challenger) {
            require(
                CurrentPlayer.Challenger == game.currentPlayer &&
                    !game.challengerPlayer.stop
            );
        } else {
            revert();
        }
        _;
    }

    function playTurn(uint256 gameId, bool draw)
        public
        payable
        isStage(gameId, Stage.Run)
        isPlayerTurn(gameId, msg.sender)
    {
        uint256 randomInt = random();
        Game storage game = games[gameId];
        if (msg.sender == game.owner) {
            if (draw) game.ownerPlayer.score += randomInt;
            game.ownerPlayer.turn++;

            if (
                !draw ||
                game.ownerPlayer.score > game.maxScore ||
                game.ownerPlayer.turn >= game.maxTurn
            ) game.ownerPlayer.stop = true;
            if (!game.challengerPlayer.stop)
                game.currentPlayer = CurrentPlayer.Challenger;
        } else if (msg.sender == game.challenger) {
            if (draw) game.challengerPlayer.score += randomInt;
            game.challengerPlayer.turn++;

            if (
                !draw ||
                game.challengerPlayer.score > game.maxScore ||
                game.challengerPlayer.turn >= game.maxTurn
            ) game.challengerPlayer.stop = true;
            if (!game.ownerPlayer.stop)
                game.currentPlayer = CurrentPlayer.Owner;
        }

        if (game.ownerPlayer.stop && game.challengerPlayer.stop) {
            game.stage = Stage.Done;
            game.winner = revealWinner(gameId);

            if (game.winner == address(0)) {
              payable(game.owner).transfer(game.bet);
              payable(game.challenger).transfer(game.bet);
            } else {
              payable(msg.sender).transfer(game.bet * 2);
            }
        }
    }

    function random() private view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        uint256(6)
                    )
                )
            ) % 6) + 1;
    }

    function revealWinner(uint256 gameId)
        public
        view
        isStage(gameId, Stage.Done)
        returns (address winner)
    {
        Game memory game = games[gameId];

        if (
            (game.ownerPlayer.score <= game.maxScore && game.challengerPlayer.score > game.maxScore) ||
            (game.ownerPlayer.score <= game.maxScore && game.ownerPlayer.score > game.challengerPlayer.score)
        ) {
            return game.owner;
        } else if (
            (game.challengerPlayer.score <= game.maxScore && game.ownerPlayer.score > game.maxScore) ||
            (game.challengerPlayer.score <= game.maxScore && game.ownerPlayer.score < game.challengerPlayer.score)
        ) {
            return game.challenger;
        } else {
            return address(0);
        }
    }

      modifier isWinner(uint256 gameId, address player) {
        Game memory game = games[gameId];
        require(game.winner == player);
        _;
    }

    function claimReward(uint256 gameId)
      public
      payable
      isStage(gameId, Stage.Done)
      isWinner(gameId, msg.sender) {
        Game memory game = games[gameId];
        payable(msg.sender).transfer(game.bet * 2);
      }

    function fetchOwnedGames() public view returns (Game[] memory _ownGames) {
        uint256 totalGameCount = currentGameIndex;
        uint256 gameCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalGameCount; i++) {
            if (games[i].owner == msg.sender) {
                gameCount += 1;
            }
        }

        Game[] memory ownGames = new Game[](gameCount);
        for (uint256 i = 0; i < totalGameCount; i++) {
            if (games[i].owner == msg.sender) {
                uint256 currentId = i;
                Game storage currentItem = games[currentId];
                ownGames[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return ownGames;
    }

    function fetchParticipatingGames()
        public
        view
        returns (Game[] memory _participatingGames)
    {
        uint256 totalGameCount = currentGameIndex;
        uint256 gameCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalGameCount; i++) {
            if (games[i].challenger == msg.sender) {
                gameCount += 1;
            }
        }

        Game[] memory participatingGames = new Game[](gameCount);
        for (uint256 i = 0; i < totalGameCount; i++) {
            if (games[i].challenger == msg.sender) {
                uint256 currentId = i;
                Game storage currentItem = games[currentId];
                participatingGames[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return participatingGames;
    }

    function fetchMyGames() public view returns (Game[] memory _myGames) {
        uint256 totalGameCount = currentGameIndex;
        uint256 gameCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalGameCount; i++) {
            if (
                games[i].owner == msg.sender ||
                games[i].challenger == msg.sender
            ) {
                gameCount += 1;
            }
        }

        Game[] memory myGames = new Game[](gameCount);
        for (uint256 i = 0; i < totalGameCount; i++) {
            if (
                games[i].owner == msg.sender ||
                games[i].challenger == msg.sender
            ) {
                uint256 currentId = i;
                Game storage currentItem = games[currentId];
                myGames[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return myGames;
    }
}