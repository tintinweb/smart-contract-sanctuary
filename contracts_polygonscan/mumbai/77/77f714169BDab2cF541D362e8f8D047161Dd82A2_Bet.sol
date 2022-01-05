/**
 *Submitted for verification at polygonscan.com on 2022-01-04
*/

// SPDX-License-Identifier: None
pragma solidity >=0.8.9;

contract Bet {

    //jedi bet status
    uint256 constant STATUS_WIN = 1;
    uint256 constant STATUS_LOSE = 2;
    uint256 constant STATUS_TIE = 3;
    uint256 constant STATUS_PENDING = 4;

    //game status
    uint256 constant STATUS_NOT_STARTED = 1;
    uint256 constant STATUS_STARTED = 2;
    uint256 constant STATUS_COMPLETE = 3;

    //general status
    uint256 constant STATUS_ERROR = 4;

    //the 'better' structure
    struct JediBet {
        uint256 guess;
        address addr;
        uint256 status;
    }

    //the 'game' structure
    struct Game {
        uint256 betAmount;
        uint256 outcome;
        uint256 status;
        JediBet originator;
        JediBet taker;
    }

    //the game
    Game game;

    //fallback function
    fallback() external payable {}
    receive() external payable {}

    function createBet(uint256 _guess) public payable {
        game = Game(
            msg.value,
            0,
            STATUS_STARTED,
            JediBet(_guess, msg.sender, STATUS_PENDING),
            JediBet(0, address(0), STATUS_NOT_STARTED)
        );
        game.originator = JediBet(_guess, msg.sender, STATUS_PENDING);
    }

    function takeBet(uint256 _guess) public payable {
        //requires the taker to make the same bet amount
        require(msg.value == game.betAmount);
        game.taker = JediBet(_guess, msg.sender, STATUS_PENDING);
        generateBetOutcome();
    }

    // function payout() public payable {
    //     checkPermissions(msg.sender);

    //     if (
    //         game.originator.status == STATUS_TIE &&
    //         game.taker.status == STATUS_TIE
    //     ) {
    //         payable(game.originator.addr).transfer(game.betAmount);
    //         payable(game.taker.addr).transfer(game.betAmount);
    //     } else {
    //         if (game.originator.status == STATUS_WIN) {
    //             payable(game.originator.addr).transfer(game.betAmount * 2);
    //         } else if (game.taker.status == STATUS_WIN) {
    //             payable(game.taker.addr).transfer(game.betAmount * 2);
    //         } else {
    //             payable(game.originator.addr).transfer(game.betAmount);
    //             payable(game.taker.addr).transfer(game.betAmount);
    //         }
    //     }
    // }

    function payout() public {
        checkPermissions(msg.sender);
        if (
            game.originator.status == STATUS_TIE &&
            game.taker.status == STATUS_TIE
        ) {
            sendReward(game.originator.addr, game.betAmount);
            sendReward(game.taker.addr, game.betAmount);
        } else {
            if (game.originator.status == STATUS_WIN) {
                sendReward(game.originator.addr, game.betAmount * 2);
            } else if (game.taker.status == STATUS_WIN) {
                sendReward(game.taker.addr, game.betAmount * 2);
            } else {
                sendReward(game.originator.addr, game.betAmount);
                sendReward(game.taker.addr, game.betAmount);
            }
        }
    }

    function sendReward(address wallet, uint256 amount) internal {
        payable(wallet).transfer(amount);
    }

    function checkPermissions(address sender) private view {
        //only the originator or taker can call this function
        require(sender == game.originator.addr || sender == game.taker.addr);
    }

    function getBetAmount() public view returns (uint256) {
        checkPermissions(msg.sender);
        return game.betAmount;
    }

    function getOriginatorGuess() public view returns (uint256) {
        checkPermissions(msg.sender);
        return game.originator.guess;
    }

    function getTakerGuess() public view returns (uint256) {
        checkPermissions(msg.sender);
        return game.taker.guess;
    }

    function getPot() public view returns (uint256) {
        checkPermissions(msg.sender);
        return address(this).balance;
    }

    function generateBetOutcome() private {
        //todo - not a great way to generate a random number but ok for now
        game.outcome = (uint256(blockhash(block.number - 1)) % 10) + 1;
        game.status = STATUS_COMPLETE;

        if (game.originator.guess == game.taker.guess) {
            game.originator.status = STATUS_TIE;
            game.taker.status = STATUS_TIE;
        } else if (
            game.originator.guess > game.outcome &&
            game.taker.guess > game.outcome
        ) {
            game.originator.status = STATUS_TIE;
            game.taker.status = STATUS_TIE;
        } else {
            if (
                (game.outcome - game.originator.guess) <
                (game.outcome - game.taker.guess)
            ) {
                game.originator.status = STATUS_WIN;
                game.taker.status = STATUS_LOSE;
            } else if (
                (game.outcome - game.taker.guess) <
                (game.outcome - game.originator.guess)
            ) {
                game.originator.status = STATUS_LOSE;
                game.taker.status = STATUS_WIN;
            } else {
                game.originator.status = STATUS_ERROR;
                game.taker.status = STATUS_ERROR;
                game.status = STATUS_ERROR;
            }
        }
    }

    //returns - [<description>, 'originator', <originator status>, 'taker', <taker status>]
    function getBetOutcome()
        public
        view
        returns (
            string memory description,
            string memory originatorKey,
            uint256 originatorStatus,
            string memory takerKey,
            uint256 takerStatus
        )
    {
        if (
            game.originator.status == STATUS_TIE ||
            game.taker.status == STATUS_TIE
        ) {
            description = "Both bets were the same or were over the number, the pot will be split";
        } else {
            if (game.originator.status == STATUS_WIN) {
                description = "Bet originator guess was closer to the number and will receive the pot";
            } else if (game.taker.status == STATUS_WIN) {
                description = "Bet taker guess was closer to the number and will receive the pot";
            } else {
                description = "Unknown Bet Outcome";
            }
        }
        originatorKey = "originator";
        originatorStatus = game.originator.status;
        takerKey = "taker";
        takerStatus = game.taker.status;
    }

    function ResolveBet() public {
        
    }
}