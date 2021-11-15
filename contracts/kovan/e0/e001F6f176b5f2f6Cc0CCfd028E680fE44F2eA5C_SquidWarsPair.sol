pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./UniSwapCommon.sol";
import "./SquidWarsLib.sol";

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function mint(address account) external;

    function balanceOf(address owner) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

interface ISquidWarsRandomCallback {
    function callback(bytes32 requestId, uint256 roudom)
        external
        returns (bool);
}

interface ISquidWarsUtils {
    function getRandomResult(bytes32 requestId) external returns (uint256);

    function getRandomNumber(address callback)
        external
        returns (bytes32 requestId);
}

contract SquidWarsPair is
    Ownable,
    Pausable,
    ReentrancyGuard,
    ISquidWarsRandomCallback
{
    event PlayEvent(address indexed account, uint256 indexed tikects);

    event GameBeginEvent(
        uint256 indexed curEndpoint_,
        uint256 indexed finishtime_
    );

    event GetRewardEvent(
        address indexed account,
        uint256 indexed tikects,
        uint256 indexed amount
    );

    event Passage(address indexed account, uint256 endpoint, uint256 blocktime);

    ///
    /// Game Rules
    ///

    uint256 public numOfTikects;

    uint256 public numOfAccounts;

    bool private firstGetReward;

    address public _referee;

    mapping(bytes32 => bool) private _orders;

    //User Info
    mapping(address => UsersInfo) private _usersInfo;

    //Total number of levels
    uint256 public constant endpoint = 1;

    //Ending time
    uint256 public finishtime;

    uint256 public prefinishtime;

    //The current level
    uint256 public curEndpoint;

    struct GameLevels {
        uint16 rate;
        uint32 duration;
        uint32 lowerBound;
        uint32 upperBound;
        uint64 numOfAccounts;
    }

    mapping(uint256 => GameLevels) public _gameLevels;

    ISquidWarsUtils public immutable _util;

    IERC20 public constant _squidWarsPreSales =
        IERC20(0x80A0fb1dBF9cda00a4886cE3Ba1E5C0c9c78B35e);

    address public constant deadAddress =
        0x000000000000000000000000000000000000dEaD;

    ///
    /// Tipping
    ///

    //10% of the prize money goes to the next round of
    uint256 public constant _bonusFee = 100;

    //Operating Fee
    uint256 public constant _tipFee = 100;

    uint256 public tip;

    uint256 public bonus;

    ///
    /// Markets
    ///

    IUniswapV2Factory public immutable _uniswapfactory;
    IUniswapV2Router02 public immutable _uniswaprouter;

    //struct for mixed payments
    struct AggregateOrders {
        address erc20;
        uint256 amount;
        address[] path;
    }

    //selling price
    mapping(uint256 => AggregateOrders[]) private _grantSalesPrices;

    mapping(uint256 => bool) private _pausedPayment;

    constructor(address util_, address uniswaprouter_) {
        _util = ISquidWarsUtils(util_);
        _uniswaprouter = IUniswapV2Router02(uniswaprouter_);
        _uniswapfactory = IUniswapV2Factory(
            IUniswapV2Router02(uniswaprouter_).factory()
        );
    }

    ///
    /// Game Rules
    ///

    /** Participating Games.
     *  Requires that the current game has not started, or is in the first level
     */
    function play(uint256 tickets, uint256 payId)
        public
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        require(curEndpoint <= 1, "game has started");
        uint256 blocktime_ = block.timestamp;
        if (curEndpoint == 0) {
            //If the game has not started then, start the game
            curEndpoint = 1;
            clear(1);
        }
        //Support advance ticketing
        UsersInfo storage usersInfo = _usersInfo[msg.sender];
        require(tickets > 0);
        buyTikects(tickets, payId);

        require(usersInfo.blocktime <= prefinishtime, "wait next round");

        usersInfo.endpoint = 1;
        usersInfo.blocktime = uint64(blocktime_);
        usersInfo.num = 0;
        usersInfo.tickets = toUint128(tickets * 10**18);

        emit PlayEvent(msg.sender, tickets);
        return true;
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    /** Mark users as candidates */
    function next(bytes memory signature) public whenNotPaused returns (bool) {
        UsersInfo storage userInfo = _usersInfo[msg.sender];
        require(curEndpoint == userInfo.endpoint, "revert for endpoint");
        require(userInfo.blocktime > prefinishtime, "game is over");
        require(userInfo.num == 0, "num error");
        bytes32 hash = SquidWarsLib.hashToVerify(msg.sender, userInfo);
        require(!_orders[hash], "signature hash expired");
        require(
            SquidWarsLib.verify(_referee, hash, signature),
            "Signature not valid."
        );
        userInfo.num = uint32(++numOfAccounts);
        _orders[hash] = true;
        if (finishtime < block.timestamp && curEndpoint <= endpoint) {
            //End the current level
            _nextSession();
        }
        return true;
    }

    /** Whether to win */
    function hasNext() public returns (bool) {
        UsersInfo storage userInfo = _usersInfo[msg.sender];
        GameLevels memory level = _gameLevels[userInfo.endpoint];
        require(userInfo.endpoint == curEndpoint - 1, "Waiting for God's Hand");
        require(userInfo.blocktime > prefinishtime, "time error");
        require(
            (userInfo.num >= level.lowerBound &&
                userInfo.num < level.upperBound) ||
                (userInfo.num + level.numOfAccounts >= level.lowerBound &&
                    userInfo.num + level.numOfAccounts < level.upperBound)
        );
        emit Passage(msg.sender, userInfo.endpoint, userInfo.blocktime);
        if (++userInfo.endpoint > endpoint) {
            numOfTikects += userInfo.tickets;
        }
        userInfo.num = 0;
        return true;
    }

    /**
     * Requests randomness
     */
    function _nextSession() internal {
        if (!paused()) {
            _pause();
        }
        _util.getRandomNumber(address(this));
    }

    /** Proactively open the next level when the level is already over */
    function nextSession() public {
        require(block.timestamp > finishtime && numOfAccounts > 0);
        _nextSession();
    }

    /** Clean up game rules data */
    function clear(uint256 curEndpoint_) private {
        GameLevels storage nlevel = _gameLevels[curEndpoint_];
        finishtime = block.timestamp + nlevel.duration;
        nlevel.lowerBound = 0;
        nlevel.upperBound = 0;
        nlevel.numOfAccounts = 0;
        numOfAccounts = 0;
        emit GameBeginEvent(curEndpoint_, finishtime);
    }

    /** get users info */
    function getUsersInfo(address account)
        public
        view
        returns (UsersInfo memory)
    {
        return _usersInfo[account];
    }

    /** chainlink random number callback interface */
    function callback(bytes32 requestId, uint256 randomness)
        external
        override
        returns (bool)
    {
        require(msg.sender == address(_util) || true);
        //Calculate the probability of passing this level
        GameLevels storage level = _gameLevels[curEndpoint];
        uint256 num = (numOfAccounts * level.rate) / 1000;
        level.lowerBound = uint32(randomness % numOfAccounts) + 1;
        level.upperBound = level.lowerBound + uint32(num == 0 ? 1 : num);
        level.numOfAccounts = uint64(numOfAccounts);

        //Try to open the next level
        curEndpoint++;
        clear(curEndpoint);

        if (paused()) {
            _unpause();
        }
        return true;
    }

    ///
    /// Market
    ///

    modifier canPayment(uint256 payId) {
        require(!_pausedPayment[payId], "No payment available");
        _;
    }

    //buy tikect
    function buyTikects(uint256 tickets, uint256 payId)
        internal
        canPayment(payId)
    {
        (address[] memory tokens_, uint256[] memory amount_) = grantSalesPrices(
            payId
        );
        for (uint256 index = 0; index < tokens_.length; index++) {
            IERC20(tokens_[index]).transferFrom(
                msg.sender,
                address(this),
                amount_[index] * tickets
            );
        }
    }

    //Get the sale price
    function grantSalesPrices(uint256 payId)
        public
        view
        returns (address[] memory tokens_, uint256[] memory amount_)
    {
        //gamefi amount
        AggregateOrders[] memory aggregateOrders = _grantSalesPrices[payId];
        tokens_ = new address[](aggregateOrders.length);
        amount_ = new uint256[](aggregateOrders.length);
        for (uint256 index = 0; index < aggregateOrders.length; index++) {
            tokens_[index] = aggregateOrders[index].erc20;
            amount_[index] = aggregateOrders[index].path.length == 0
                ? aggregateOrders[index].amount
                : _uniswaprouter.getAmountsIn(
                    aggregateOrders[index].amount,
                    aggregateOrders[index].path
                )[0];
        }
    }

    //Update sale price
    function setGrantSalesPrices(
        uint256 payId,
        AggregateOrders[] memory aggregateOrders_
    ) public onlyOwner {
        delete _grantSalesPrices[payId];
        AggregateOrders[] storage _aggregateOrders = _grantSalesPrices[payId];
        for (uint256 index = 0; index < aggregateOrders_.length; index++) {
            if (_aggregateOrders.length <= index)
                _aggregateOrders.push(aggregateOrders_[index]);
            else _aggregateOrders[index] = aggregateOrders_[index];
        }
    }

    //Deactivate the assigned payment
    function pausePayment(uint256 payId) public onlyOwner {
        _pausedPayment[payId] = true;
    }

    //Enable the specified payment
    function unpausePayment(uint256 payId) public onlyOwner {
        _pausedPayment[payId] = false;
    }

    ///
    /// reward pool
    ///

    // Get rewards based on weighting
    function getReward(address[] calldata tokens_) public nonReentrant {
        UsersInfo memory usersInfo = _usersInfo[msg.sender];
        require(usersInfo.endpoint > endpoint);
        uint256 numOfTikects_ = numOfTikects;
        if (!firstGetReward) {
            tip += (numOfTikects_ * _tipFee) / 1000;
            bonus += (numOfTikects_ * _bonusFee) / 1000;
            firstGetReward = true;
            numOfTikects_ = numOfTikects_ + tip + bonus;
        }
        (uint256 fee_, uint256 rtikects_) = SquidWarsLib.getWithdrawFee(
            usersInfo.tickets,
            finishtime
        );
        tip += fee_;
        _calculateEarnings(tokens_, rtikects_, numOfTikects_);

        emit GetRewardEvent(msg.sender, usersInfo.tickets, numOfTikects_);
        delete _usersInfo[msg.sender];

        numOfTikects_ -= rtikects_;

        if (numOfTikects_ == bonus) {
            _reset();
            return;
        }
        numOfTikects = numOfTikects_;
    }

    //Calculate the number of specific bonuses
    function _calculateEarnings(
        address[] calldata tokens_,
        uint256 rtikects_,
        uint256 numOfTikects_
    ) internal {
        require(numOfTikects_ != 0, "numOfTikects gt zero");
        for (uint256 i = 0; i < tokens_.length; i++) {
            IERC20 erc20 = IERC20(tokens_[i]);
            uint256 reward_ = (erc20.balanceOf(address(this)) *
                rtikects_) / numOfTikects_;
            erc20.transfer(msg.sender, reward_);
        }
    }

    ///
    /// Manager
    ///

    /** After 30 days, the administrator can forcibly terminate the game */
    function reset() public onlyOwner whenPaused {
        require(block.timestamp - finishtime > 86400 * 30);
        _reset();
    }

    function _reset() internal {
        numOfTikects = 0;
        curEndpoint = 0;
        prefinishtime = finishtime;
        bonus = 0;
        firstGetReward = false;
    }

    /** Set rules for each level */
    function setGameLevels(
        uint256 i,
        uint16 rate,
        uint32 duration_
    ) external onlyOwner {
        require(rate != 0 && duration_ != 0, "Invalid level");
        GameLevels storage level = _gameLevels[i];
        level.rate = rate;
        level.duration = duration_;
    }

    /** Hiring referees */
    function setReferee(address referee_) public onlyOwner {
        _referee = referee_;
    }

    /** Withdrawal fees */
    function withdrawTip(address[] calldata tokens_) public onlyOwner {
        require(firstGetReward, "wait game over");
        uint256 numOfTikects_ = numOfAccounts;
        _calculateEarnings(tokens_, tip, numOfTikects_);
        numOfTikects_ -= tip;
        tip = 0;
        if (numOfTikects_ == bonus) {
            _reset();
            return;
        }
        numOfAccounts = numOfTikects_;
    }

    function burnPreTikects() public {
        _squidWarsPreSales.transfer(
            deadAddress,
            _squidWarsPreSales.balanceOf(address(this))
        );
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    constructor() {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity 0.8.0;
// SPDX-License-Identifier: Unlicensed

//用户数据结构
struct UsersInfo {
    uint32 endpoint;
    uint32 num;
    uint64 blocktime;
    uint128 tickets;
}

library SquidWarsLib {
    
    function getFee(uint256 amount,uint _bonusFee,uint _tipFee)
        public
        pure
        returns (
            uint256 fee_,
            uint256 tip_,
            uint256 amount_
        )
    {
        fee_ = (amount * _bonusFee) / 1000;
        tip_ = (amount * _tipFee) / 1000;
        amount_ = amount - (fee_ + tip_);
    }

    function getWithdrawFee(uint256 amount,uint finishtime)
        public
        view
        returns (uint256 fee_, uint256 amount_)
    {
        uint256 r = (block.timestamp - finishtime) / 86400;
        if (r > 25) {
            r = 25;
        }
        amount_ = (amount * (r + 75)) / 100;
        fee_ = amount - amount_;
    }

    function hashUsersInfo(
        address tokenId,UsersInfo memory info
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    tokenId,
                    info.endpoint,
                    info.num,
                    info.blocktime,
                    info.tickets,
                    address(this)
                )
            );
    }

    function hashToSign(address tokenId, uint32 endpoint_, uint32 num, uint64 blocktime, uint128 tickets ) public view returns (bytes32) {
        UsersInfo memory info = UsersInfo(endpoint_, num, blocktime, tickets);
        return hashUsersInfo(tokenId,info);
    }

    function hashToVerify(address tokenId,
        UsersInfo memory info
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hashUsersInfo(tokenId,info)
                )
            );
    }

    function verify(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) public pure returns (bool) {
        require(signer != address(0));
        require(signature.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28);

        return signer == ecrecover(hash, v, r, s);
    }
}