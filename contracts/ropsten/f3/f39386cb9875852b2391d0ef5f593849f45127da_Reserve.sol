/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/math/SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/interfaces/IDO.sol

interface IDO is IERC20 {
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/interfaces/IHolder.sol

interface IHolder {
    function withdrawROC(uint256 _amount) external;
}

// File: contracts/interfaces/ILayerManager.sol

interface ILayerManager {
    function getAmountPerLayer(uint256 _soldAmount) external pure returns(uint256);
    function getPriceIncrementPerLayer(uint256 _soldAmount) external pure returns(uint256);
}

// File: contracts/interfaces/IROC.sol

interface IROC is IERC20 {
    function delegate(address delegatee) external;
}

// File: contracts/interfaces/IRoUSD.sol

interface IRoUSD is IERC20 {
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router01.sol

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

// File: contracts/uniswapv2/interfaces/IUniswapV2Router02.sol

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

// File: contracts/uniswapv2/interfaces/IUniswapV2Pair.sol

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

// File: contracts/Reserve.sol

// This contract is owned by Timelock.
contract Reserve is Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public router;
    IUniswapV2Pair public roUSDDOPair;

    IROC public rocToken;
    IDO public doToken;
    IRoUSD public roUSDToken;

    struct HolderInfo {
        IHolder holder;
        uint256 share;  // a number from 1 (0.01%) to 10000 (100%)
    }

    HolderInfo[] public holderInfoArray;
    uint256 constant HOLDER_SHARE_BASE = 10000;

    uint256 public earlyPrice = 5e16;  // 0.05
    uint256 public price;  // Unset, 1e17 means 0.1
    uint256 public sold;  // amount of sold ROC
    uint256 public soldInPreviousLayers;
    uint256 public cost;  // amound of received roUSD

    ILayerManager public layerManager;

    uint256 public reserveRatio = 800000;  // 0.8

    uint256 public inflationThreshold = 1030000;  // 1.03
    uint256 public deflationThreshold = 970000;  // 0.97

    uint256 public inflationTarget = 1010000;  // 1.01
    uint256 public deflationTarget = 990000;  // 0.99

    // ind means inflation and deflation
    uint256 public indIncentive = 1000;  // 0.1%
    uint256 public indIncentiveLimit = 100e18;  // 100 DO
    uint256 public indStep = 3000;  // 0.3%
    uint256 public indWindow = 1 hours;
    uint256 public indGap = 1 minutes;

    uint256 public inflationUntil = 0;
    uint256 public deflationUntil = 0;
    uint256 public inflationLast = 0;
    uint256 public deflationLast = 0;

    uint256 constant RATIO_BASE = 1e6;
    uint256 constant PRICE_BASE = 1e18;  // 1 roUSD

    struct Loan {
        uint128 createdAt;
        uint128 updatedAt;
        uint256 rocAmount;
        uint256 doAmount;
    }

    mapping(address => Loan[]) public loanMap;

    constructor(IROC _roc, IDO _do, IRoUSD _roUSD) public {
        rocToken = _roc;
        doToken = _do;
        roUSDToken = _roUSD;
    }

    // Call this function in the beginning.
    function setInitialSoldAndCost(uint256 _sold, uint256 _cost) external onlyOwner {
        require(sold == 0 && cost == 0, "Can only set once");
        sold = _sold;
        soldInPreviousLayers = _sold;
        cost = _cost;
    }

    function setEarlyPrice(uint256 _earlyPrice) external onlyOwner {
        require(price == 0, "Price should not be set");
        earlyPrice = _earlyPrice;
    }

    // Please only call this function after 1 year.
    function setInitialPrice(uint256 _price) external onlyOwner {
        require(price == 0, "Can only set once");
        require(_price >= earlyPrice, "Must be larger than early price");
        price = _price;
    }

    function setHolderInfoArray(IHolder[] calldata _holders, uint256[] calldata _shares) external onlyOwner {
        require(_holders.length == _shares.length);

        delete holderInfoArray;
        for (uint256 i = 0; i < _holders.length; ++i) {
            HolderInfo memory info;
            info.holder = _holders[i];
            info.share = _shares[i];
            holderInfoArray.push(info);
        }
    }

    function setLayerManager(ILayerManager _layerManager) external onlyOwner {
        layerManager = _layerManager;
    }

    function setRouter(IUniswapV2Router02 _router) external onlyOwner {
        router = _router;
    }

    function setRoUSDDOPair(IUniswapV2Pair _roUSDDOPair) external onlyOwner {
        roUSDDOPair = _roUSDDOPair;
    }

    function setReserveRatio(uint256 _reserveRatio) external onlyOwner {
        reserveRatio = _reserveRatio;
    }

    function setInflationThreshold(uint256 _inflationThreshold) external onlyOwner {
        inflationThreshold = _inflationThreshold;
    }

    function setDeflationThreshold(uint256 _deflationThreshold) external onlyOwner {
        deflationThreshold = _deflationThreshold;
    }

    function setInflationTarget(uint256 _inflationTarget) external onlyOwner {
        inflationTarget = _inflationTarget;
    }

    function setDeflationTarget(uint256 _deflationTarget) external onlyOwner {
        deflationTarget = _deflationTarget;
    }

    function setIndIncentive(uint256 _indIncentive) external onlyOwner {
        indIncentive = _indIncentive;
    }

    function setIndIncentiveLimit(uint256 _indIncentiveLimit) external onlyOwner {
        indIncentiveLimit = _indIncentiveLimit;
    }

    function setIndStep(uint256 _indStep) external onlyOwner {
        indStep = _indStep;
    }

    function setIndWindow(uint256 _indWindow) external onlyOwner {
        indWindow = _indWindow;
    }

    function setIndGap(uint256 _indGap) external onlyOwner {
        indGap = _indGap;
    }

    function _checkReserveRatio() private view {
        uint256 doSupply = doToken.totalSupply();
        uint256 roUSDBalance = roUSDToken.balanceOf(address(this));

        require(doSupply.mul(reserveRatio) <= roUSDBalance.mul(RATIO_BASE),
                "Reserve: NOT_ENOUGH_ROUSD");
    }

    function getReserves() private view returns (uint256 reserveDo, uint256 reserveRoUSD) {
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1,) = roUSDDOPair.getReserves();
        if (roUSDDOPair.token0() == address(doToken)) {
            reserveDo = uint256(reserve0);
            reserveRoUSD = uint256(reserve1);
        } else {
            reserveDo = uint256(reserve1);
            reserveRoUSD = uint256(reserve0);
        }
    }

    function canInflate() public view returns(bool) {
        (uint256 reserveDo, uint256 reserveRoUSD) = getReserves();
        return reserveRoUSD.mul(RATIO_BASE) > reserveDo.mul(inflationThreshold) ||
            reserveRoUSD.mul(RATIO_BASE) > reserveDo.mul(inflationTarget) && now < inflationUntil;
    }

    function canDeflate() public view returns(bool) {
        (uint256 reserveDo, uint256 reserveRoUSD) = getReserves();
        return reserveRoUSD.mul(RATIO_BASE) < reserveDo.mul(deflationThreshold) ||
            reserveRoUSD.mul(RATIO_BASE) < reserveDo.mul(deflationTarget) && now < deflationUntil;
    }

    function isInTargetPrice() public view returns(bool) {
        (uint256 reserveDo, uint256 reserveRoUSD) = getReserves();
        return reserveRoUSD.mul(RATIO_BASE) <= reserveDo.mul(inflationTarget) &&
            reserveRoUSD.mul(RATIO_BASE) >= reserveDo.mul(deflationTarget);
    }

    function inflate(uint256 _deadline) external {
        require(canInflate(),
                "Reserve: not ready to inflate");

        if (now >= inflationUntil) {
            inflationUntil = now + indWindow;
        }

        require(now >= inflationLast + indGap, "Reserve: wait for the gap");
        inflationLast = now;

        (uint256 reserveDo, uint256 reserveRoUSD) = getReserves();

        // Mint the amount of do to swap (with some math).
        uint256 amountOfDoToInflate = reserveDo.mul(indStep).div(RATIO_BASE);
        doToken.mint(address(this), amountOfDoToInflate);

        uint256 incentive = amountOfDoToInflate.mul(indIncentive).div(RATIO_BASE);
        incentive = incentive > indIncentiveLimit ? indIncentiveLimit : incentive;

        // Mint some extra do as incentive.
        doToken.mint(msg.sender, incentive);

        address[] memory path = new address[](2);
        path[0] = address(doToken);
        path[1] = address(roUSDToken);

        // Now swap.
        doToken.approve(address(router), amountOfDoToInflate);
        router.swapExactTokensForTokens(
            amountOfDoToInflate,
            0,
            path,
            address(this),
            _deadline);

        // Make sure the ratio is still good.
        _checkReserveRatio();
    }

    function deflate(uint256 _deadline) external {
        require(canDeflate(),
                "Reserve: not ready to deflate");

        if (now >= deflationUntil) {
            deflationUntil = now + indWindow;
        }

        require(now >= deflationLast + indGap, "Reserve: wait for the gap");
        deflationLast = now;

        (uint256 reserveDo, uint256 reserveRoUSD) = getReserves();

        uint256 balanceOfRoUSD = roUSDToken.balanceOf(address(this));

        // Calculate the amount of roUSD to swap (with some math).
        uint256 amountRoUSDToSwap = reserveRoUSD.mul(indStep).div(RATIO_BASE);

        // amountRoUSDToSwap should be smaller than or equal to balance.
        amountRoUSDToSwap = amountRoUSDToSwap <= balanceOfRoUSD ?
            amountRoUSDToSwap : balanceOfRoUSD;

        address[] memory path = new address[](2);
        path[0] = address(roUSDToken);
        path[1] = address(doToken);

        // Now swap.
        roUSDToken.approve(address(router), amountRoUSDToSwap);
        uint256[] memory amounts;
        amounts = router.swapExactTokensForTokens(
           amountRoUSDToSwap,
           0,
           path,
           address(this),
           _deadline);

        // Now send out incentive and burn the rest.
        uint256 incentive = amounts[amounts.length - 1].mul(indIncentive).div(RATIO_BASE);
        incentive = incentive > indIncentiveLimit ? indIncentiveLimit : incentive;

        doToken.transfer(msg.sender, incentive);
        doToken.burn(amounts[amounts.length - 1].sub(incentive));

        // Make sure the ratio is still good.
        _checkReserveRatio();
    }

    function withdrawRoUSD(uint256 _amount) external onlyOwner {
        roUSDToken.transfer(msg.sender, _amount);

        // Make sure the ratio is still good.
        _checkReserveRatio();
    }

    function purchaseExactAmountOfROCWithRoUSD(
        uint256 _amountOfROC,
        uint256 _maxAmountOfRoUSD,
        uint256 _deadline
    ) external returns (uint256) {
        require(now < _deadline, "Reserve: deadline");

        uint256 amountOfRoUSD;
        (amountOfRoUSD, price, sold, soldInPreviousLayers) = estimateRoUSDAmountFromROC(_amountOfROC);
        cost = cost.add(amountOfRoUSD);

        require(amountOfRoUSD <= _maxAmountOfRoUSD, "Reserve: EXCESSIVE_AMOUNT");

        uint256 i;

        // 50% of the ROC should be from holders.
        for (i = 0; i < holderInfoArray.length; ++i) {
            uint256 amountFromHolder = _amountOfROC.div(2).mul(holderInfoArray[i].share).div(HOLDER_SHARE_BASE);
            rocToken.transferFrom(address(holderInfoArray[i].holder), address(this), amountFromHolder);
        }

        rocToken.transfer(msg.sender, _amountOfROC);
        roUSDToken.transferFrom(msg.sender, address(this), amountOfRoUSD);

        // 50% roUSD goes to holders.
        for (i = 0; i < holderInfoArray.length; ++i) {
            uint256 amountToHolder = amountOfRoUSD.div(2).mul(holderInfoArray[i].share).div(HOLDER_SHARE_BASE);
            roUSDToken.transfer(address(holderInfoArray[i].holder), amountToHolder);
        }

        return amountOfRoUSD;
    }

    function purchaseROCWithExactAmountOfRoUSD(
        uint256 _amountOfRoUSD,
        uint256 _minAmountOfROC,
        uint256 _deadline
    ) external returns (uint256) {
        require(now < _deadline, "Reserve: deadline");

        uint256 amountOfROC;
        (amountOfROC, price, sold, soldInPreviousLayers) = estimateROCAmountFromRoUSD(_amountOfRoUSD);
        cost = cost.add(_amountOfRoUSD);

        require(amountOfROC >= _minAmountOfROC, "Reserve: INCESSIVE_AMOUNT");

        uint256 i;

        // 50% of the ROC should be from holders.
        for (i = 0; i < holderInfoArray.length; ++i) {
            uint256 amountFromHolder = amountOfROC.div(2).mul(holderInfoArray[i].share).div(HOLDER_SHARE_BASE);
            rocToken.transferFrom(address(holderInfoArray[i].holder), address(this), amountFromHolder);
        }

        rocToken.transfer(msg.sender, amountOfROC);
        roUSDToken.transferFrom(msg.sender, address(this), _amountOfRoUSD);

        // 50% roUSD goes to holders.
        for (i = 0; i < holderInfoArray.length; ++i) {
            uint256 amountToHolder = _amountOfRoUSD.div(2).mul(holderInfoArray[i].share).div(HOLDER_SHARE_BASE);
            roUSDToken.transfer(address(holderInfoArray[i].holder), amountToHolder);
        }

        return amountOfROC;
    }

    function estimateRoUSDAmountFromROC(
        uint256 _amountOfROC
    ) public view returns(uint256, uint256, uint256, uint256) {
        require(price > 0, "price must be initialized");

        uint256 mPrice = price;
        uint256 mSold = sold;
        uint256 mSoldInPreviousLayers = soldInPreviousLayers;

        uint256 amountOfRoUSD = 0;
        uint256 remainingInLayer = layerManager.getAmountPerLayer(mSold).add(soldInPreviousLayers).sub(mSold);

        while (_amountOfROC > 0) {
            if (_amountOfROC < remainingInLayer) {
                amountOfRoUSD = amountOfRoUSD.add(_amountOfROC.mul(mPrice).div(PRICE_BASE));
                mSold = mSold.add(_amountOfROC);
                _amountOfROC = 0;
            } else {
                amountOfRoUSD = amountOfRoUSD.add(remainingInLayer.mul(mPrice).div(PRICE_BASE));
                _amountOfROC = _amountOfROC.sub(remainingInLayer);
                mPrice = mPrice.add(layerManager.getPriceIncrementPerLayer(mSold));

                // Updates mSold and mSoldInPreviousLayers.
                mSoldInPreviousLayers = mSoldInPreviousLayers.add(layerManager.getAmountPerLayer(mSold));
                mSold = mSold.add(remainingInLayer);

                // Move to a new layer.
                remainingInLayer = layerManager.getAmountPerLayer(mSold);
            }
        }

        return (amountOfRoUSD, mPrice, mSold, mSoldInPreviousLayers);
    }

    function estimateROCAmountFromRoUSD(
        uint256 _amountOfRoUSD
    ) public view returns(uint256, uint256, uint256, uint256) {
        require(price > 0, "price must be initialized");

        uint256 mPrice = price;
        uint256 mSold = sold;
        uint256 mSoldInPreviousLayers = soldInPreviousLayers;

        uint256 amountOfROC = 0;
        uint256 remainingInLayer = layerManager.getAmountPerLayer(mSold).add(soldInPreviousLayers).sub(mSold);

        while (_amountOfRoUSD > 0) {
            uint256 amountEstimate = _amountOfRoUSD.mul(PRICE_BASE).div(mPrice);

            if (amountEstimate < remainingInLayer) {
                amountOfROC = amountOfROC.add(amountEstimate);
                mSold = mSold.add(amountEstimate);
                _amountOfRoUSD = 0;
            } else {
                amountOfROC = amountOfROC.add(remainingInLayer);
                _amountOfRoUSD = _amountOfRoUSD.sub(remainingInLayer.mul(mPrice).div(PRICE_BASE));
                mPrice = mPrice.add(layerManager.getPriceIncrementPerLayer(mSold));

                // Updates mSold and mSoldInPreviousLayers.
                mSoldInPreviousLayers = mSoldInPreviousLayers.add(layerManager.getAmountPerLayer(mSold));
                mSold = mSold.add(remainingInLayer);

                // Move to a new layer.
                remainingInLayer = layerManager.getAmountPerLayer(mSold);
            }
        }

        return (amountOfROC, mPrice, mSold, mSoldInPreviousLayers);
    }

    function getAveragePriceOfROC() public view returns(uint256) {
        if (price == 0) {
            return earlyPrice;
        } else {
            return cost.mul(PRICE_BASE).div(sold);
        }
    }

    function mintExactAmountOfDO(
        uint256 _amountOfDo,
        uint256 _maxAmountOfROC,
        uint256 _deadline
    ) external returns(uint256) {
        require(now < _deadline, "Reserve: deadline");

        uint256 averagePriceOfROC = getAveragePriceOfROC();
        uint256 amountOfROC = _amountOfDo.mul(2).mul(PRICE_BASE).div(averagePriceOfROC);  // 2 times over-collateralized

        require(amountOfROC <= _maxAmountOfROC, "Reserve: EXCESSIVE_AMOUNT");

        rocToken.transferFrom(msg.sender, address(this), amountOfROC);
        doToken.mint(msg.sender, _amountOfDo);

        Loan memory loan;
        loan.createdAt = uint128(now);
        loan.updatedAt = uint128(now);
        loan.rocAmount = amountOfROC;
        loan.doAmount = _amountOfDo;
        loanMap[msg.sender].push(loan);

        _checkReserveRatio();

        return amountOfROC;
    }

    function mintDOWithExactAmountOfROC(
        uint256 _amountOfROC,
        uint256 _minAmountOfDo,
        uint256 _deadline
    ) external returns(uint256) {
        require(now < _deadline, "Reserve: deadline");

        uint256 averagePriceOfROC = getAveragePriceOfROC();
        uint256 amountOfDo = _amountOfROC.mul(averagePriceOfROC).div(PRICE_BASE).div(2);  // 2 times over-collateralized

        require(amountOfDo >= _minAmountOfDo, "Reserve: INCESSIVE_AMOUNT");

        rocToken.transferFrom(msg.sender, address(this), _amountOfROC);
        doToken.mint(msg.sender, amountOfDo);

        Loan memory loan;
        loan.createdAt = uint128(now);
        loan.updatedAt = uint128(now);
        loan.rocAmount = _amountOfROC;
        loan.doAmount = amountOfDo;
        loanMap[msg.sender].push(loan);

        _checkReserveRatio();

        return amountOfDo;
    }

    function redeemROC(uint256 _index) external {
        Loan storage loan = loanMap[msg.sender][_index];
        loan.updatedAt = uint128(now);

        rocToken.transfer(msg.sender, loan.rocAmount);
        loan.rocAmount = 0;

        doToken.burnFrom(msg.sender, loan.doAmount);
        loan.doAmount = 0;
    }
}