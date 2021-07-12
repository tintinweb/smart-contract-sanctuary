/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @title UnifiedLiquidityPool Interface
 */
interface IUnifiedLiquidityPool {
    /**
     * @dev External function for start staking. Only owner can call this function.
     * @param _initialStake Amount of GBTS token
     */
    function startStaking(uint256 _initialStake) external;

    /**
     * @dev External function for staking. This function can be called by any users.
     * @param _amount Amount of GBTS token
     */
    function stake(uint256 _amount) external;

    /**
     * @dev External function for exit staking. Users can withdraw their funds.
     * @param _amount Amount of sGBTS token
     */
    function exitStake(uint256 _amount) external;

    /**
     * @dev External function for sending prize to winner. This is called by only approved games.
     * @param _prizeAmount Amount of GBTS token
     */
    function sendPrize(address _winner, uint256 _prizeAmount) external;

    /**
     * @dev External function for approving games. This is called by only owner.
     * @param _gameAddr Address of game
     */
    function approveGame(address _gameAddr, bool _approved) external;

    /**
     * @dev External function for burning sGBTS token. Only called by owner.
     * @param _amount Amount of sGBTS
     */
    function burnULPsGbts(uint256 _amount) external;

    /**
     * @dev External function to check to see if the distributor has any sGBTS then distribute called by only approvedGames.
     *      Only distributes to one provider at a time. Only if the ULP has more then 50 million GBTS.
     */
    function distribute() external;

    /**
     * @dev External function for getting vrf number and reqeust randomness. This function can be called by only apporved games.
     */
    function getRandomNumber() external returns (uint256);

    /**
     * @dev External function for getting new vrf number(Game number). This function can be called by only apporved games.
     * @param _oldRandom Previous random number
     */
    function getNewRandomNumber(uint256 _oldRandom) external returns (uint256);

    /**
     * @dev Public function for returning verified random number. This function can be called by only approved games.
     */
    function getVerifiedRandomNumber() external view returns (uint256);
}

/**
 * @title Aggregator contract Interface
 */
interface IAggregator {
    /**
     * @dev External function for getting latest price of chainlink oracle.
     */
    function latestAnswer() external view returns (int256);

    /**
     * @dev External function for getting latest round data of chainlink oracle.
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * @title DiceRoll Contract
 */
contract DiceRoll is Ownable, ReentrancyGuard {
    IUnifiedLiquidityPool public ULP;
    IERC20 public GBTS;
    IAggregator public LinkUSDT;
    IAggregator public GBTSUSDT;

    uint256 constant RTP = 98;
    uint256 constant gameId = 1;

    uint256 public betGBTS;
    uint256 public paidGBTS;

    bool public isLocked;

    uint256 public vrfCost = 10000; // 0.0001 Link

    struct BetInfo {
        uint256 number;
        uint256 amount;
        uint256 multiplier;
        uint256 gameRandomNumber;
    }

    mapping(address => BetInfo) private betInfos;

    /// @notice Event emitted only on construction.
    event DiceRollDeployed();

    /// @notice Event emitted when player start the betting.
    event BetStarted(address indexed player, uint256 number, uint256 amount);

    /// @notice Event emitted when player finish the betting.
    event BetFinished(address indexed player, bool won);

    /// @notice Event emitted when game number generated.
    event VerifiedGameNumber(uint256 vrf, uint256 gameNumber, uint256 gameId);

    modifier unLocked() {
        require(isLocked == false, "DiceRoll: Game is locked");
        _;
    }

    /**
     * @dev Constructor function
     * @param _ULP Interface of ULP
     * @param _GBTS Interface of GBTS
     * @param _GBTSUSDT Interface of GBTS Token USDT Aggregator
     * @param _LinkUSDT Interface of Link Token USDT Aggregator "0xd9FFdb71EbE7496cC440152d43986Aae0AB76665" Address of LINK/USD Price Contract
     */
    constructor(
        IUnifiedLiquidityPool _ULP,
        IERC20 _GBTS,
        IAggregator _GBTSUSDT,
        IAggregator _LinkUSDT
    ) {
        ULP = _ULP;
        GBTS = _GBTS;
        GBTSUSDT = _GBTSUSDT;
        LinkUSDT = _LinkUSDT;

        emit DiceRollDeployed();
    }

    /**
     * @dev External function for start betting. This function can be called by players.
     * @param _number Number of player set
     * @param _amount Amount of player betted.
     */
    function bet(uint256 _number, uint256 _amount) external unLocked {
        require(betInfos[msg.sender].number == 0, "DiceRoll: Already betted");
        require(1 <= _number && _number <= 50, "DiceRoll: Number out of range");
        require(
            GBTS.balanceOf(msg.sender) >= _amount,
            "DiceRoll: Caller has not enough balance"
        );

        uint256 multiplier = (RTP * 1000) / _number;
        uint256 winnings = (_amount * multiplier) / 1000;

        require(
            checkBetAmount(winnings, _amount),
            "DiceRoll: Bet amount is out of range"
        );

        require(
            GBTS.transferFrom(msg.sender, address(ULP), _amount),
            "DiceRoll: GBTS transfer failed"
        );

        betInfos[msg.sender].number = _number;
        betInfos[msg.sender].amount = _amount;
        betInfos[msg.sender].multiplier = multiplier;
        betInfos[msg.sender].gameRandomNumber = ULP.getRandomNumber();
        betGBTS += _amount;

        emit BetStarted(msg.sender, _number, _amount);
    }

    /**
     * @dev External function for calculate betting win or lose.
     */
    function play() external nonReentrant unLocked {
        require(
            betInfos[msg.sender].number != 0,
            "DiceRoll: Cannot play without betting"
        );

        uint256 newRandomNumber = ULP.getNewRandomNumber(
            betInfos[msg.sender].gameRandomNumber
        );

        uint256 gameNumber = uint256(
            keccak256(abi.encode(newRandomNumber, address(msg.sender), gameId))
        ) % 100;

        emit VerifiedGameNumber(newRandomNumber, gameNumber, gameId);

        BetInfo storage betInfo = betInfos[msg.sender];

        if (gameNumber < betInfo.number) {
            ULP.sendPrize(
                msg.sender,
                (betInfo.amount * betInfo.multiplier) / 1000
            );

            paidGBTS += (betInfo.amount * betInfo.multiplier) / 1000;
            betInfos[msg.sender].number = 0;

            emit BetFinished(msg.sender, true);
        } else {
            betInfos[msg.sender].number = 0;

            emit BetFinished(msg.sender, false);
        }
    }

    /**
     * @dev Public function for returns min bet amount with current Link and GBTS token price.
     */
    function minBetAmount() public view returns (uint256) {
        int256 GBTSPrice;
        int256 LinkPrice;

        (, GBTSPrice, , , ) = GBTSUSDT.latestRoundData();
        (, LinkPrice, , , ) = LinkUSDT.latestRoundData();

        return (uint256(LinkPrice) * 53) / (uint256(GBTSPrice) * vrfCost);
    }

    /**
     * @dev Internal function to check current bet amount is enough to bet.
     * @param _winnings Amount of GBTS if user wins.
     * @param _betAmount Bet Amount
     */
    function checkBetAmount(uint256 _winnings, uint256 _betAmount)
        internal
        view
        returns (bool)
    {
        return (GBTS.balanceOf(address(ULP)) / 100 >= _winnings &&
            _betAmount >= minBetAmount());
    }

    /**
     * @dev External function for lock the game. This function is called by owner only.
     */
    function lock() external unLocked onlyOwner {
        _lock();
    }

    /**
     * @dev Private function for lock the game.
     */
    function _lock() private {
        isLocked = true;
    }

    /**
     * @dev External function for unlock the game. This function is called by owner only.
     */
    function unLock() external onlyOwner {
        require(isLocked == true);

        isLocked = false;
    }
}