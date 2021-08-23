pragma solidity 0.8.3;

// SPDX-License-Identifier: MIT



import "./GamesCore.sol";

contract CoinFlip is GamesCore {
    constructor() {
        croupier = msg.sender;
        profitTaker = msg.sender;

        edge = 5;
        minEtherBet = 0.1 ether;
        maxEtherBet = 10 ether;
    }

    /**
        * @notice Add new game
        * @param _seed: Uniqual value for each game
    */
    function play(uint256 _choice, bytes32 _seed) public payable betInRange uniqueSeed(_seed) {
        require(_choice == 0 || _choice == 1, 'Choice should be 0 or 1');

        uint256 possiblePrize = msg.value * (200 - edge) / 100;
        require(
            possiblePrize < address(this).balance,
            'Insufficent funds on contract to cover the bet'
        );

        Game storage game = games[_seed];

        totalGamesCount++;

        game.id = totalGamesCount;
        game.player = payable(msg.sender);
        game.bet = msg.value;
        game.state = GameState.PENDING;

        game.choice = _choice;

        houseProfitEther += int256(game.bet);
        listGames.push(_seed);

        emit GameCreated(
            game.player,
            game.bet,
            game.choice,
            _seed,
            true
        );
    }

    /**
        * @notice Confirm the game, with seed
        * @param _seed: Uniqual value for each game
    */
    function confirm(
        bytes32 _seed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public override onlyCroupier {
        Game storage game = games[_seed];

        require(game.state == GameState.PENDING, 'Game already played');

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _seed));

        require(ecrecover(prefixedHash, _v, _r, _s) == croupier, 'Invalid signature');

        game.result = uint256(_s) % 2;
        
        if (game.choice == game.result) {
            game.prize = game.bet * (200 - edge) / 100;
            game.state = GameState.WON;
            
            houseProfitEther -= int256(game.prize);
            
            game.player.transfer(game.prize);
        } else {
            game.prize = 0;
            game.state = GameState.LOST;
        }

        emit GamePlayed(
            game.player,
            game.id,
            (200 - edge),
            game.bet,
            game.prize,
            game.choice,
            game.result,
            _seed,
            true,
            game.state
        );
    }
}

pragma solidity 0.8.3;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract GamesCore is Ownable {
    struct Game {
        uint256 id;
        address payable player;
        uint256 bet;
        uint256 prize;
        uint256 choice;
        uint256 result;
        bool over;
        GameState state;
    }

    enum GameState {
        PENDING,
        WON,
        LOST
    }

    /// Number of all games
    uint256 public totalGamesCount;
    /// Minimal amount for bet
    uint256 public minEtherBet;
    /// Maximal amount for bet
    uint256 public maxEtherBet;

    /// Profit from bets
    int256 public houseProfitEther;

    /// Croupier
    address public croupier;
    /// Person how will receive houseProfitEther
    address public profitTaker;
    /// Fee factor
    uint8 public edge;

    /// Info of each game
    mapping(bytes32 => Game) public games;

    /// Games seeds
    bytes32[] public listGames;

    event GameCreated(
        address indexed player,
        uint256 bet,
        uint256 choice,
        bytes32 seed,
        bool over
    );

    event GamePlayed(
        address indexed player,
        uint256 round,
        uint256 multiplier,
        uint256 bet,
        uint256 prize,
        uint256 choice,
        uint256 result,
        bytes32 indexed seed,
        bool over,
        GameState state
    );

    // Modifier for functions that can only be ran by the croupier
    modifier onlyCroupier() {
        require(
            msg.sender == croupier,
            "Only the croupier can run this function."
        );
        _;
    }

    // Modifier for functions that can only be ran by the profit taker
    modifier onlyProfitTaker() {
        require(
            msg.sender == profitTaker,
            "Only the profit taker can run this function."
        );
        _;
    }

    // Check that the rate is between min and max bet
    modifier betInRange() {
        require(
            minEtherBet <= msg.value && msg.value <= maxEtherBet,
            "Incorrect amount to bet"
        );
        _;
    }

    /// Check that sedd is unique
    modifier uniqueSeed(bytes32 _seed) {
        require(games[_seed].id == 0, "Seed already used");
        _;
    }

    /**
     * @notice Confirm the game, with seed
     * @param _seed: Uniqual value for each game
     */
    function confirm(
        bytes32 _seed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public virtual;

    /**
     * @notice Set new minEtherBet and maxEtherBet
     * @param _min: New minEtherBet
     * @param _max: New maxEtherBet
     */
    function setBetRange(uint256 _min, uint256 _max) public onlyOwner {
        minEtherBet = _min;
        maxEtherBet = _max;
    }

    /**
     * @notice Set new croupier
     * @param _addr: New croupier
     */
    function setCroupier(address _addr) public onlyOwner {
        croupier = _addr;
    }

    /**
     * @notice Set new profitTaker
     * @param _profitTaker: New profitTaker
     */
    function setProfitTaker(address _profitTaker) public onlyOwner {
        profitTaker = _profitTaker;
    }

    /**
        * @notice Set new edge    
        * @param _e: New edge
    */
    function setEdge(uint8 _e) public onlyOwner {
        edge = _e;
    }

    /**
     * @notice sends houseProfitEther to profitTaker
     */
    function takeProfit() public onlyProfitTaker {
        if (houseProfitEther > 0) {
            payable(profitTaker).transfer(uint256(houseProfitEther));
            houseProfitEther = 0;
        }
    }

    /**
     * @notice sends contract's excessive balance to owner
     */
    function withdraw() public onlyOwner {
        if (houseProfitEther > 0) {
            payable(owner()).transfer(
                address(this).balance - uint256(houseProfitEther)
            );
            return;
        }

        payable(owner()).transfer(address(this).balance);
    }

    // Fallback function
    fallback() external payable {}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}