pragma solidity ^0.4.24;

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
pragma solidity ^0.4.24;

interface EtherHiLoRandomNumberRequester {

    function incomingRandomNumber(address player, uint8 randomNumber) external;

    function incomingRandomNumberError(address player) external;

}

interface EtherHiLoRandomNumberGenerator {

    function generateRandomNumber(address player, uint8 max) external returns (bool);

}

/// @title EtherHiLo
/// @dev the contract than handles the EtherHiLo app
contract EtherHiLo is Ownable, EtherHiLoRandomNumberRequester {

    uint8 constant NUM_DICE_SIDES = 13;

    uint public minBet;
    uint public maxBetThresholdPct;
    bool public gameRunning;
    uint public balanceInPlay;

    EtherHiLoRandomNumberGenerator private random;
    mapping(address => Game) private gamesInProgress;

    event GameFinished(address indexed player, uint indexed playerGameNumber, uint bet, uint8 firstRoll, uint8 finalRoll, uint winnings, uint payout);
    event GameError(address indexed player, uint indexed playerGameNumber);

    enum BetDirection {
        None,
        Low,
        High
    }

    enum GameState {
        None,
        WaitingForFirstCard,
        WaitingForDirection,
        WaitingForFinalCard,
        Finished
    }

    // the game object
    struct Game {
        address player;
        GameState state;
        uint id;
        BetDirection direction;
        uint bet;
        uint8 firstRoll;
        uint8 finalRoll;
        uint winnings;
    }

    // the constructor
    constructor() public {
        setMinBet(100 finney);
        setGameRunning(true);
        setMaxBetThresholdPct(75);
    }

    /// Default function
    function() external payable {

    }


    /// =======================
    /// EXTERNAL GAME RELATED FUNCTIONS

    // begins a game
    function beginGame() public payable {
        address player = msg.sender;
        uint bet = msg.value;

        require(player != address(0));
        require(gamesInProgress[player].state == GameState.None || gamesInProgress[player].state == GameState.Finished);
        require(gameRunning);
        require(bet >= minBet && bet <= getMaxBet());

        Game memory game = Game({
                id:         uint(keccak256(block.number, player, bet)),
                player:     player,
                state:      GameState.WaitingForFirstCard,
                bet:        bet,
                firstRoll:  0,
                finalRoll:  0,
                winnings:   0,
                direction:  BetDirection.None
            });

        if (!random.generateRandomNumber(player, NUM_DICE_SIDES)) {
            player.transfer(msg.value);
            return;
        }

        balanceInPlay = balanceInPlay + game.bet;
        gamesInProgress[player] = game;
    }

    // finishes a game that is in progress
    function finishGame(BetDirection direction) public {
        address player = msg.sender;

        require(player != address(0));
        require(gamesInProgress[player].state != GameState.None && gamesInProgress[player].state != GameState.Finished);

        if (!random.generateRandomNumber(player, NUM_DICE_SIDES)) {
            return;
        }

        Game storage game = gamesInProgress[player];
        game.direction = direction;
        game.state = GameState.WaitingForFinalCard;
        gamesInProgress[player] = game;
    }

    // returns current game state
    function getGameState(address player) public view returns
            (GameState, uint, BetDirection, uint, uint8, uint8, uint) {
        return (
            gamesInProgress[player].state,
            gamesInProgress[player].id,
            gamesInProgress[player].direction,
            gamesInProgress[player].bet,
            gamesInProgress[player].firstRoll,
            gamesInProgress[player].finalRoll,
            gamesInProgress[player].winnings
        );
    }

    // Returns the minimum bet
    function getMinBet() public view returns (uint) {
        return minBet;
    }

    // Returns the maximum bet
    function getMaxBet() public view returns (uint) {
        return SafeMath.div(SafeMath.div(SafeMath.mul(this.balance - balanceInPlay, maxBetThresholdPct), 100), 12);
    }

    // calculates winnings for the given bet and percent
    function calculateWinnings(uint bet, uint percent) public pure returns (uint) {
        return SafeMath.div(SafeMath.mul(bet, percent), 100);
    }

    // Returns the win percent when going low on the given number
    function getLowWinPercent(uint number) public pure returns (uint) {
        require(number >= 2 && number <= NUM_DICE_SIDES);
        if (number == 2) {
            return 1200;
        } else if (number == 3) {
            return 500;
        } else if (number == 4) {
            return 300;
        } else if (number == 5) {
            return 300;
        } else if (number == 6) {
            return 200;
        } else if (number == 7) {
            return 180;
        } else if (number == 8) {
            return 150;
        } else if (number == 9) {
            return 140;
        } else if (number == 10) {
            return 130;
        } else if (number == 11) {
            return 120;
        } else if (number == 12) {
            return 110;
        } else if (number == 13) {
            return 100;
        }
    }

    // Returns the win percent when going high on the given number
    function getHighWinPercent(uint number) public pure returns (uint) {
        require(number >= 1 && number < NUM_DICE_SIDES);
        if (number == 1) {
            return 100;
        } else if (number == 2) {
            return 110;
        } else if (number == 3) {
            return 120;
        } else if (number == 4) {
            return 130;
        } else if (number == 5) {
            return 140;
        } else if (number == 6) {
            return 150;
        } else if (number == 7) {
            return 180;
        } else if (number == 8) {
            return 200;
        } else if (number == 9) {
            return 300;
        } else if (number == 10) {
            return 300;
        } else if (number == 11) {
            return 500;
        } else if (number == 12) {
            return 1200;
        }
    }


    /// =======================
    /// RANDOM NUMBER CALLBACKS

    function incomingRandomNumberError(address player) public {
        require(msg.sender == address(random));

        Game storage game = gamesInProgress[player];
        if (game.bet > 0) {
            game.player.transfer(game.bet);
        }

        delete gamesInProgress[player];
        GameError(player, game.id);
    }

    function incomingRandomNumber(address player, uint8 randomNumber) public {
        require(msg.sender == address(random));

        Game storage game = gamesInProgress[player];

        if (game.firstRoll == 0) {

            game.firstRoll = randomNumber;
            game.state = GameState.WaitingForDirection;
            gamesInProgress[player] = game;

            return;
        }

        uint8 finalRoll = randomNumber;
        uint winnings = 0;

        if (game.direction == BetDirection.High && finalRoll > game.firstRoll) {
            winnings = calculateWinnings(game.bet, getHighWinPercent(game.firstRoll));
        } else if (game.direction == BetDirection.Low && finalRoll < game.firstRoll) {
            winnings = calculateWinnings(game.bet, getLowWinPercent(game.firstRoll));
        }

        // this should never happen according to the odds,
        // and the fact that we don&#39;t allow people to bet
        // so large that they can take the whole pot in one
        // fell swoop - however, a number of people could
        // theoretically all win simultaneously and cause
        // this scenario.  This will try to at a minimum
        // send them back what they bet and then since it
        // is recorded on the blockchain we can verify that
        // the winnings sent don&#39;t match what they should be
        // and we can manually send the rest to the player.
        uint transferAmount = winnings;
        if (transferAmount > this.balance) {
            if (game.bet < this.balance) {
                transferAmount = game.bet;
            } else {
                transferAmount = SafeMath.div(SafeMath.mul(this.balance, 90), 100);
            }
        }

        balanceInPlay = balanceInPlay - game.bet;

        if (transferAmount > 0) {
            game.player.transfer(transferAmount);
        }

        game.finalRoll = finalRoll;
        game.winnings = winnings;
        game.state = GameState.Finished;
        gamesInProgress[player] = game;

        GameFinished(player, game.id, game.bet, game.firstRoll, finalRoll, winnings, transferAmount);
    }


    /// OWNER / MANAGEMENT RELATED FUNCTIONS

    // fail safe for balance transfer
    function transferBalance(address to, uint amount) public onlyOwner {
        to.transfer(amount);
    }

    // cleans up a player abandoned game, but only if it&#39;s
    // greater than 24 hours old.
    function cleanupAbandonedGame(address player) public onlyOwner {
        require(player != address(0));

        Game storage game = gamesInProgress[player];
        require(game.player != address(0));

        game.player.transfer(game.bet);
        delete gamesInProgress[game.player];
    }

    function setRandomAddress(address _address) public onlyOwner {
        random = EtherHiLoRandomNumberGenerator(_address);
    }

    // set the minimum bet
    function setMinBet(uint bet) public onlyOwner {
        minBet = bet;
    }

    // set whether or not the game is running
    function setGameRunning(bool v) public onlyOwner {
        gameRunning = v;
    }

    // set the max bet threshold percent
    function setMaxBetThresholdPct(uint v) public onlyOwner {
        maxBetThresholdPct = v;
    }

    // Transfers the current balance to the recepient and terminates the contract.
    function destroyAndSend(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }

}