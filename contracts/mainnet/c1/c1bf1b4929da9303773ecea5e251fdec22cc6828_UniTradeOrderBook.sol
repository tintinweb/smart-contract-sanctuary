// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/GSN/Context.sol

// pragma solidity ^0.6.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// pragma solidity ^0.6.0;

// import "@openzeppelin/contracts/GSN/Context.sol";
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


// Dependency file: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// pragma solidity ^0.6.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

// pragma solidity >=0.5.0;

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


// Dependency file: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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


// Dependency file: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

// pragma solidity >=0.6.2;

// import '/Users/train/Documents/Work/Decent/unitrade/unitrade/node_modules/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol';

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


// Dependency file: @uniswap/lib/contracts/libraries/TransferHelper.sol

// pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/UniTradeIncinerator.sol

// pragma solidity ^0.6.6;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract UniTradeIncinerator {
    using SafeMath for uint256;

    uint256 constant UINT256_MAX = ~uint256(0);
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable unitrade;
    uint256 lastIncinerated;

    event UniTradeToBurn(uint256 etherIn);
    event UniTradeBurned(uint256 etherIn, uint256 tokensBurned);

    constructor(IUniswapV2Router02 _uniswapV2Router, address _unitrade) public {
        uniswapV2Router = _uniswapV2Router;
        unitrade = _unitrade;
        lastIncinerated = block.timestamp;
    }

    function burn() external payable returns (bool) {
        require(msg.value > 0, "Nothing to burn");

        emit UniTradeToBurn(msg.value);

        if (block.timestamp < lastIncinerated + 1 days) {
            return true;
        }

        lastIncinerated = block.timestamp;

        address[] memory _tokenPair = new address[](2);
        _tokenPair[0] = uniswapV2Router.WETH();
        _tokenPair[1] = unitrade;

        uint256[] memory _swapResult = uniswapV2Router.swapExactETHForTokens{
            value: address(this).balance
        }(
            0, // take any
            _tokenPair,
            address(this),
            UINT256_MAX
        );

        emit UniTradeBurned(_swapResult[0], _swapResult[1]);

        return true;
    }
}


// Dependency file: contracts/IUniTradeStaker.sol

// pragma solidity ^0.6.6;

interface IUniTradeStaker
{
    function deposit() external payable;
}


// Root file: contracts/UniTradeOrderBook.sol

pragma solidity ^0.6.6;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
// import "contracts/UniTradeIncinerator.sol";
// import "contracts/IUniTradeStaker.sol";

contract UniTradeOrderBook is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 constant UINT256_MAX = ~uint256(0);
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Factory public immutable uniswapV2Factory;
    UniTradeIncinerator public immutable incinerator;
    IUniTradeStaker public staker;
    uint16 public feeMul;
    uint16 public feeDiv;
    uint16 public splitMul;
    uint16 public splitDiv;

    enum OrderType {TokensForTokens, EthForTokens, TokensForEth}
    enum OrderState {Placed, Cancelled, Executed}

    struct Order {
        OrderType orderType;
        address payable maker;
        address tokenIn;
        address tokenOut;
        uint256 amountInOffered;
        uint256 amountOutExpected;
        uint256 executorFee;
        uint256 totalEthDeposited;
        uint256 activeOrderIndex;
        OrderState orderState;
        bool deflationary;
    }

    uint256 private orderNumber;
    uint256[] private activeOrders;
    mapping(uint256 => Order) private orders;
    mapping(address => uint256[]) private ordersForAddress;

    event OrderPlaced(
        uint256 indexed orderId,
        OrderType orderType,
        address payable indexed maker,
        address tokenIn,
        address tokenOut,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee,
        uint256 totalEthDeposited
    );
    event OrderUpdated(
        uint256 indexed orderId,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    );
    event OrderCancelled(uint256 indexed orderId);
    event OrderExecuted(
        uint256 indexed orderId,
        address indexed executor,
        uint256[] amounts,
        uint256 unitradeFee
    );
    event StakerUpdated(address newStaker);

    modifier exists(uint256 orderId) {
        require(orders[orderId].maker != address(0), "Order not found");
        _;
    }

    constructor(
        IUniswapV2Router02 _uniswapV2Router,
        UniTradeIncinerator _incinerator,
        IUniTradeStaker _staker,
        uint16 _feeMul,
        uint16 _feeDiv,
        uint16 _splitMul,
        uint16 _splitDiv
    ) public {
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        incinerator = _incinerator;
        staker = _staker;
        feeMul = _feeMul;
        feeDiv = _feeDiv;
        splitMul = _splitMul;
        splitDiv = _splitDiv;
    }

    function placeOrder(
        OrderType orderType,
        address tokenIn,
        address tokenOut,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external payable nonReentrant returns (uint256) {
        require(amountInOffered > 0, "Invalid offered amount");
        require(amountOutExpected > 0, "Invalid expected amount");
        require(executorFee > 0, "Invalid executor fee");

        address _wethAddress = uniswapV2Router.WETH();
        bool deflationary = false;

        if (orderType != OrderType.EthForTokens) {
            require(
                msg.value == executorFee,
                "Transaction value must match executor fee"
            );
            if (orderType == OrderType.TokensForEth) {
                require(tokenOut == _wethAddress, "Token out must be WETH");
            } else {
                getPair(tokenIn, _wethAddress);
            }
            uint256 beforeBalance = IERC20(tokenIn).balanceOf(address(this));
            // transfer tokenIn funds in necessary for order execution
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                amountInOffered
            );
            uint256 afterBalance = IERC20(tokenIn).balanceOf(address(this));
            if (afterBalance.sub(beforeBalance) != amountInOffered) {
                amountInOffered = afterBalance.sub(beforeBalance);
                deflationary = true;
            }
            require(amountInOffered > 0, "Invalid final offered amount");
        } else {
            require(tokenIn == _wethAddress, "Token in must be WETH");
            require(
                msg.value == amountInOffered.add(executorFee),
                "Transaction value must match offer and fee"
            );
        }

        // get canonical uniswap pair address
        address _pairAddress = getPair(tokenIn, tokenOut);

        (uint256 _orderId, Order memory _order) = registerOrder(
            orderType,
            msg.sender,
            tokenIn,
            tokenOut,
            _pairAddress,
            amountInOffered,
            amountOutExpected,
            executorFee,
            msg.value,
            deflationary
        );

        emit OrderPlaced(
            _orderId,
            _order.orderType,
            _order.maker,
            _order.tokenIn,
            _order.tokenOut,
            _order.amountInOffered,
            _order.amountOutExpected,
            _order.executorFee,
            _order.totalEthDeposited
        );

        return _orderId;
    }

    function updateOrder(
        uint256 orderId,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee
    ) external payable exists(orderId) nonReentrant returns (bool) {
        Order memory _updatingOrder = orders[orderId];
        require(msg.sender == _updatingOrder.maker, "Permission denied");
        require(
            _updatingOrder.orderState == OrderState.Placed,
            "Cannot update order"
        );
        require(amountInOffered > 0, "Invalid offered amount");
        require(amountOutExpected > 0, "Invalid expected amount");
        require(executorFee > 0, "Invalid executor fee");

        if (_updatingOrder.orderType == OrderType.EthForTokens) {
            uint256 newTotal = amountInOffered.add(executorFee);
            if (newTotal > _updatingOrder.totalEthDeposited) {
                require(
                    msg.value == newTotal.sub(_updatingOrder.totalEthDeposited),
                    "Additional deposit must match"
                );
            } else if (newTotal < _updatingOrder.totalEthDeposited) {
                TransferHelper.safeTransferETH(
                    _updatingOrder.maker,
                    _updatingOrder.totalEthDeposited.sub(newTotal)
                );
            }
            _updatingOrder.totalEthDeposited = newTotal;
        } else {
            if (executorFee > _updatingOrder.executorFee) {
                require(
                    msg.value == executorFee.sub(_updatingOrder.executorFee),
                    "Additional fee must match"
                );
            } else if (executorFee < _updatingOrder.executorFee) {
                TransferHelper.safeTransferETH(
                    _updatingOrder.maker,
                    _updatingOrder.executorFee.sub(executorFee)
                );
            }
            _updatingOrder.totalEthDeposited = executorFee;
            if (amountInOffered > _updatingOrder.amountInOffered) {
                uint256 beforeBalance = IERC20(_updatingOrder.tokenIn)
                    .balanceOf(address(this));
                TransferHelper.safeTransferFrom(
                    _updatingOrder.tokenIn,
                    msg.sender,
                    address(this),
                    amountInOffered.sub(_updatingOrder.amountInOffered)
                );
                uint256 afterBalance = IERC20(_updatingOrder.tokenIn).balanceOf(
                    address(this)
                );
                amountInOffered = _updatingOrder.amountInOffered.add(
                    afterBalance.sub(beforeBalance)
                );
            } else if (amountInOffered < _updatingOrder.amountInOffered) {
                TransferHelper.safeTransfer(
                    _updatingOrder.tokenIn,
                    _updatingOrder.maker,
                    _updatingOrder.amountInOffered.sub(amountInOffered)
                );
            }
        }

        // update order record
        _updatingOrder.amountInOffered = amountInOffered;
        _updatingOrder.amountOutExpected = amountOutExpected;
        _updatingOrder.executorFee = executorFee;
        orders[orderId] = _updatingOrder;

        emit OrderUpdated(
            orderId,
            amountInOffered,
            amountOutExpected,
            executorFee
        );

        return true;
    }

    function cancelOrder(uint256 orderId)
        external
        exists(orderId)
        nonReentrant
        returns (bool)
    {
        Order memory _cancellingOrder = orders[orderId];
        require(msg.sender == _cancellingOrder.maker, "Permission denied");
        require(
            _cancellingOrder.orderState == OrderState.Placed,
            "Cannot cancel order"
        );

        proceedOrder(orderId, OrderState.Cancelled);

        // Revert token allocation, funds, and fees
        if (_cancellingOrder.orderType != OrderType.EthForTokens) {
            TransferHelper.safeTransfer(
                _cancellingOrder.tokenIn,
                _cancellingOrder.maker,
                _cancellingOrder.amountInOffered
            );
        }

        TransferHelper.safeTransferETH(
            _cancellingOrder.maker,
            _cancellingOrder.totalEthDeposited
        );

        emit OrderCancelled(orderId);
        return true;
    }

    function executeOrder(uint256 orderId)
        external
        exists(orderId)
        nonReentrant
        returns (uint256[] memory amounts)
    {
        Order memory _executingOrder = orders[orderId];
        require(
            _executingOrder.orderState == OrderState.Placed,
            "Cannot execute order"
        );

        proceedOrder(orderId, OrderState.Executed);

        address[] memory _addressPair = createPair(
            _executingOrder.tokenIn,
            _executingOrder.tokenOut
        );
        uint256 unitradeFee = 0;

        if (_executingOrder.orderType == OrderType.TokensForTokens) {
            TransferHelper.safeApprove(
                _executingOrder.tokenIn,
                address(uniswapV2Router),
                _executingOrder.amountInOffered
            );
            uint256 _tokenFee = _executingOrder.amountInOffered.mul(feeMul).div(
                feeDiv
            );
            if (_executingOrder.deflationary) {
                uint256 beforeBalance = IERC20(_executingOrder.tokenOut)
                    .balanceOf(_executingOrder.maker);
                uniswapV2Router
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _executingOrder.amountInOffered.sub(_tokenFee),
                    _executingOrder.amountOutExpected,
                    _addressPair,
                    _executingOrder.maker,
                    UINT256_MAX
                );
                uint256 afterBalance = IERC20(_executingOrder.tokenOut)
                    .balanceOf(_executingOrder.maker);
                amounts = new uint256[](2);
                amounts[0] = _executingOrder.amountInOffered.sub(_tokenFee);
                amounts[1] = afterBalance.sub(beforeBalance);
            } else {
                amounts = uniswapV2Router.swapExactTokensForTokens(
                    _executingOrder.amountInOffered.sub(_tokenFee),
                    _executingOrder.amountOutExpected,
                    _addressPair,
                    _executingOrder.maker,
                    UINT256_MAX
                );
            }

            if (_tokenFee > 0) {
                // Convert x% of tokens to ETH as fee
                address[] memory _wethPair = createPair(
                    _executingOrder.tokenIn,
                    uniswapV2Router.WETH()
                );
                if (_executingOrder.deflationary) {
                    uint256 beforeBalance = IERC20(uniswapV2Router.WETH())
                        .balanceOf(address(this));
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                        _tokenFee,
                        0, //take any
                        _wethPair,
                        address(this),
                        UINT256_MAX
                    );
                    uint256 afterBalance = IERC20(uniswapV2Router.WETH())
                        .balanceOf(address(this));
                    unitradeFee = afterBalance.sub(beforeBalance);
                } else {
                    uint256[] memory _ethSwapResult = uniswapV2Router
                        .swapExactTokensForETH(
                        _tokenFee,
                        0, //take any
                        _wethPair,
                        address(this),
                        UINT256_MAX
                    );
                    unitradeFee = _ethSwapResult[1];
                }
            }
        } else if (_executingOrder.orderType == OrderType.TokensForEth) {
            TransferHelper.safeApprove(
                _executingOrder.tokenIn,
                address(uniswapV2Router),
                _executingOrder.amountInOffered
            );
            if (_executingOrder.deflationary) {
                uint256 beforeBalance = address(this).balance;
                uniswapV2Router
                    .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _executingOrder.amountInOffered,
                    _executingOrder.amountOutExpected,
                    _addressPair,
                    address(this),
                    UINT256_MAX
                );
                uint256 afterBalance = address(this).balance;
                amounts = new uint256[](2);
                amounts[0] = _executingOrder.amountInOffered;
                amounts[1] = afterBalance.sub(beforeBalance);
            } else {
                amounts = uniswapV2Router.swapExactTokensForETH(
                    _executingOrder.amountInOffered,
                    _executingOrder.amountOutExpected,
                    _addressPair,
                    address(this),
                    UINT256_MAX
                );
            }

            unitradeFee = amounts[1].mul(feeMul).div(feeDiv);
            if (amounts[1].sub(unitradeFee) > 0) {
                // Transfer to maker after post swap fee split
                TransferHelper.safeTransferETH(
                    _executingOrder.maker,
                    amounts[1].sub(unitradeFee)
                );
            }
        } else if (_executingOrder.orderType == OrderType.EthForTokens) {
            // Subtract fee from initial swap
            uint256 amountEthOffered = _executingOrder.totalEthDeposited.sub(
                _executingOrder.executorFee
            );
            unitradeFee = amountEthOffered.mul(feeMul).div(feeDiv);

            uint256 beforeBalance = IERC20(_executingOrder.tokenOut).balanceOf(
                _executingOrder.maker
            );
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: amountEthOffered.sub(unitradeFee)
            }(
                _executingOrder.amountOutExpected,
                _addressPair,
                _executingOrder.maker,
                UINT256_MAX
            );
            uint256 afterBalance = IERC20(_executingOrder.tokenOut).balanceOf(
                _executingOrder.maker
            );
            amounts = new uint256[](2);
            amounts[0] = amountEthOffered.sub(unitradeFee);
            amounts[1] = afterBalance.sub(beforeBalance);
        }

        // Transfer fee to incinerator/staker
        if (unitradeFee > 0) {
            uint256 burnAmount = unitradeFee.mul(splitMul).div(splitDiv);
            if (burnAmount > 0) {
                incinerator.burn{value: burnAmount}(); //no require
            }
            staker.deposit{value: unitradeFee.sub(burnAmount)}(); //no require
        }

        // transfer fee to executor
        TransferHelper.safeTransferETH(msg.sender, _executingOrder.executorFee);

        emit OrderExecuted(orderId, msg.sender, amounts, unitradeFee);
    }

    function registerOrder(
        OrderType orderType,
        address payable maker,
        address tokenIn,
        address tokenOut,
        address pairAddress,
        uint256 amountInOffered,
        uint256 amountOutExpected,
        uint256 executorFee,
        uint256 totalEthDeposited,
        bool deflationary
    ) internal returns (uint256 orderId, Order memory) {
        uint256 _orderId = orderNumber;
        orderNumber++;

        // create order entries
        Order memory _order = Order({
            orderType: orderType,
            maker: maker,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountInOffered: amountInOffered,
            amountOutExpected: amountOutExpected,
            executorFee: executorFee,
            totalEthDeposited: totalEthDeposited,
            activeOrderIndex: activeOrders.length,
            orderState: OrderState.Placed,
            deflationary: deflationary
        });

        activeOrders.push(_orderId);
        orders[_orderId] = _order;
        ordersForAddress[maker].push(_orderId);
        ordersForAddress[pairAddress].push(_orderId);

        return (_orderId, _order);
    }

    function proceedOrder(uint256 orderId, OrderState nextState)
        internal
        returns (bool)
    {
        Order memory _proceedingOrder = orders[orderId];
        require(
            _proceedingOrder.orderState == OrderState.Placed,
            "Cannot proceed order"
        );

        if (activeOrders.length > 1) {
            uint256 _availableIndex = _proceedingOrder.activeOrderIndex;
            uint256 _lastOrderId = activeOrders[activeOrders.length - 1];
            Order memory _lastOrder = orders[_lastOrderId];
            _lastOrder.activeOrderIndex = _availableIndex;
            orders[_lastOrderId] = _lastOrder;
            activeOrders[_availableIndex] = _lastOrderId;
        }

        activeOrders.pop();
        _proceedingOrder.orderState = nextState;
        _proceedingOrder.activeOrderIndex = UINT256_MAX; // indicate that it's not active
        orders[orderId] = _proceedingOrder;

        return true;
    }

    function getPair(address tokenA, address tokenB)
        internal
        view
        returns (address)
    {
        address _pairAddress = uniswapV2Factory.getPair(tokenA, tokenB);
        require(_pairAddress != address(0), "Unavailable pair address");
        return _pairAddress;
    }

    function getOrder(uint256 orderId)
        external
        view
        exists(orderId)
        returns (
            OrderType orderType,
            address payable maker,
            address tokenIn,
            address tokenOut,
            uint256 amountInOffered,
            uint256 amountOutExpected,
            uint256 executorFee,
            uint256 totalEthDeposited,
            OrderState orderState,
            bool deflationary
        )
    {
        Order memory _order = orders[orderId];
        return (
            _order.orderType,
            _order.maker,
            _order.tokenIn,
            _order.tokenOut,
            _order.amountInOffered,
            _order.amountOutExpected,
            _order.executorFee,
            _order.totalEthDeposited,
            _order.orderState,
            _order.deflationary
        );
    }

    function updateStaker(IUniTradeStaker newStaker) external onlyOwner {
        staker = newStaker;
        emit StakerUpdated(address(newStaker));
    }

    function updateFee(uint16 _feeMul, uint16 _feeDiv) external onlyOwner {
        require(_feeMul < _feeDiv, "!fee");
        feeMul = _feeMul;
        feeDiv = _feeDiv;
    }

    function updateSplit(uint16 _splitMul, uint16 _splitDiv)
        external
        onlyOwner
    {
        require(_splitMul < _splitDiv, "!split");
        splitMul = _splitMul;
        splitDiv = _splitDiv;
    }

    function createPair(address tokenA, address tokenB)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory _addressPair = new address[](2);
        _addressPair[0] = tokenA;
        _addressPair[1] = tokenB;
        return _addressPair;
    }

    function getActiveOrdersLength() external view returns (uint256) {
        return activeOrders.length;
    }

    function getActiveOrderId(uint256 index) external view returns (uint256) {
        return activeOrders[index];
    }

    function getOrdersForAddressLength(address _address)
        external
        view
        returns (uint256)
    {
        return ordersForAddress[_address].length;
    }

    function getOrderIdForAddress(address _address, uint256 index)
        external
        view
        returns (uint256)
    {
        return ordersForAddress[_address][index];
    }

    receive() external payable {} // to receive ETH from Uniswap
}