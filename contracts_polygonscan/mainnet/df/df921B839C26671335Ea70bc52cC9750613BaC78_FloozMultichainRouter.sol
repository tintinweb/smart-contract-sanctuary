pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IWETH.sol";

contract FeeReceiver is Pausable, Ownable {
    using SafeMath for uint256;

    event BuybackRateUpdated(uint256 newBuybackRate);
    event RevenueReceiverUpdated(address newRevenueReceiver);
    event RouterWhitelistUpdated(address router, bool status);
    event BuybackExecuted(uint256 amountBuyback, uint256 amountRevenue);

    address internal constant ZERO_ADDRESS = address(0);
    uint256 public constant FEE_DENOMINATOR = 10000;
    IPancakeRouter02 public pancakeRouter;
    address payable public revenueReceiver;
    uint256 public buybackRate;
    address public SYA;
    address public WETH;

    mapping(address => bool) public routerWhitelist;

    constructor(
        IPancakeRouter02 _pancakeRouterV2,
        address _SYA,
        address _WETH,
        address payable _revenueReceiver,
        uint256 _buybackRate
    ) public {
        pancakeRouter = _pancakeRouterV2;
        SYA = _SYA;
        WETH = _WETH;
        revenueReceiver = _revenueReceiver;
        buybackRate = _buybackRate;
        routerWhitelist[address(pancakeRouter)] = true;
    }

    /// @dev executes the buyback, buys SYA on pancake & sends revenue to the revenueReceiver by the defined rate.
    function executeBuyback() external whenNotPaused {
        require(address(this).balance > 0, "FeeReceiver: No balance for buyback");
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = SYA;

        uint256 balance = address(this).balance;
        uint256 amountBuyback = balance.mul(buybackRate).div(FEE_DENOMINATOR);
        uint256 amountRevenue = balance.sub(amountBuyback);

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountBuyback}(
            0,
            path,
            ZERO_ADDRESS,
            block.timestamp
        );
        TransferHelper.safeTransferETH(revenueReceiver, amountRevenue);
        emit BuybackExecuted(amountBuyback, amountRevenue);
    }

    /// @dev converts collected tokens from fees to ETH for executing buybacks
    function convertToETH(
        address _router,
        IERC20 _token,
        bool _fee
    ) public whenNotPaused {
        require(routerWhitelist[_router], "FeeReceiver: Router not whitelisted");
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = WETH;

        uint256 balance = _token.balanceOf(address(this));
        TransferHelper.safeApprove(address(_token), address(pancakeRouter), balance);
        if (_fee) {
            IPancakeRouter02(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                balance,
                0,
                path,
                address(this),
                block.timestamp
            );
        } else {
            IPancakeRouter02(_router).swapExactTokensForETH(balance, 0, path, address(this), block.timestamp);
        }
    }

    /// @dev converts WETH to ETH
    function unwrapWETH() public whenNotPaused {
        uint256 balance = IWETH(WETH).balanceOf(address(this));
        require(balance > 0, "FeeReceiver: Nothing to unwrap");
        IWETH(WETH).withdraw(balance);
    }

    /// @dev lets the owner update update the router whitelist
    function updateRouterWhiteliste(address _router, bool _status) external onlyOwner {
        routerWhitelist[_router] = _status;
        emit RouterWhitelistUpdated(_router, _status);
    }

    /// @dev lets the owner update the buyback rate
    function updateBuybackRate(uint256 _newBuybackRate) external onlyOwner {
        buybackRate = _newBuybackRate;
        emit BuybackRateUpdated(_newBuybackRate);
    }

    /// @dev lets the owner update the revenue receiver address
    function updateRevenueReceiver(address payable _newRevenueReceiver) external onlyOwner {
        revenueReceiver = _newRevenueReceiver;
        emit RevenueReceiverUpdated(_newRevenueReceiver);
    }

    /// @dev lets the owner withdraw ETH from the contract
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    /// @dev lets the owner withdraw any ERC20 Token from the contract
    function withdrawERC20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @dev allows to receive ETH on this contract
    receive() external payable {}

    /// @dev lets the owner pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev lets the owner unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

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
    constructor () internal {
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

pragma solidity =0.6.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

pragma solidity >=0.6.2;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address _spender, uint256 _amount) external returns (bool);

    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

pragma solidity =0.6.6;

import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/PancakeLibrary.sol";
import "./interfaces/IReferralRegistry.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IZerox.sol";

contract FloozRouter is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using LibBytesV06 for bytes;

    event SwapFeeUpdated(uint16 swapFee);
    event ReferralRegistryUpdated(address referralRegistry);
    event ReferralRewardRateUpdated(uint16 referralRewardRate);
    event ReferralsActivatedUpdated(bool activated);
    event FeeReceiverUpdated(address payable feeReceiver);
    event BalanceThresholdUpdated(uint256 balanceThreshold);
    event CustomReferralRewardRateUpdated(address indexed account, uint16 referralRate);
    event ReferralRewardPaid(address from, address indexed to, address tokenOut, address tokenReward, uint256 amount);
    event ForkUpdated(address factory);

    // Denominator of fee
    uint256 public constant FEE_DENOMINATOR = 10000;

    // Numerator of fee
    uint16 public swapFee;

    // address of WETH
    address public immutable WETH;

    // address of zeroEx proxy contract to forward swaps
    address payable public immutable zeroEx;

    // address of 1inch contract to forward swaps
    address payable public immutable oneInch;

    // address of referral registry that stores referral anchors
    IReferralRegistry public referralRegistry;

    // address of SYA token
    IERC20 public saveYourAssetsToken;

    // balance threshold of SYA tokens which actives feeless swapping
    uint256 public balanceThreshold;

    // address that receives protocol fees
    address payable public feeReceiver;

    // percentage of fees that will be paid as rewards
    uint16 public referralRewardRate;

    // stores if the referral system is turned on or off
    bool public referralsActivated;

    // stores individual referral rates
    mapping(address => uint16) public customReferralRewardRate;

    // stores uniswap forks status, index is the factory address
    mapping(address => bool) public forkActivated;

    // stores uniswap forks initCodes, index is the factory address
    mapping(address => bytes) public forkInitCode;

    /// @dev construct this contract
    /// @param _WETH address of WETH.
    /// @param _swapFee nominator for swapFee. Denominator = 10000
    /// @param _referralRewardRate percentage of swapFee that are paid out as rewards
    /// @param _feeReceiver address that receives protocol fees
    /// @param _balanceThreshold balance threshold of SYA tokens which actives feeless swapping
    /// @param _saveYourAssetsToken address of SYA token
    /// @param _referralRegistry address of referral registry that stores referral anchors
    /// @param _zeroEx address of zeroX proxy contract to forward swaps
    /// @param _oneInch address of 1inch contract to forward swaps
    constructor(
        address _WETH,
        uint16 _swapFee,
        uint16 _referralRewardRate,
        address payable _feeReceiver,
        uint256 _balanceThreshold,
        IERC20 _saveYourAssetsToken,
        IReferralRegistry _referralRegistry,
        address payable _zeroEx,
        address payable _oneInch
    ) public {
        WETH = _WETH;
        swapFee = _swapFee;
        referralRewardRate = _referralRewardRate;
        feeReceiver = _feeReceiver;
        saveYourAssetsToken = _saveYourAssetsToken;
        balanceThreshold = _balanceThreshold;
        referralRegistry = _referralRegistry;
        zeroEx = _zeroEx;
        oneInch = _oneInch;
        referralsActivated = true;
    }

    /// @dev execute swap directly on Uniswap/Pancake & simular forks
    /// @param fork fork used to execute swap
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    /// @return amounts
    function swapExactETHForTokens(
        address fork,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external payable whenNotPaused isValidFork(fork) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            msg.value,
            referee,
            false
        );
        amounts = _getAmountsOut(fork, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(_pairFor(fork, path[0], path[1]), amounts[0]));
        _swap(fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountIn amount of tokensIn
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address fork,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFork(fork) isValidReferee(referee) {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(fork, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(fork, path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountOut);
        (uint256 amountWithdraw, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            amountOut,
            referee,
            false
        );
        require(amountWithdraw >= amountOutMin, "FloozRouter: LOW_SLIPPAGE");
        TransferHelper.safeTransferETH(msg.sender, amountWithdraw);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    /// @return amounts
    function swapExactTokensForTokens(
        address fork,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFork(fork) isValidReferee(referee) returns (uint256[] memory amounts) {
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            amountIn,
            referee,
            false
        );
        amounts = _getAmountsOut(fork, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(fork, path[0], path[1]), swapAmount);
        _swap(fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    /// @return amounts
    function swapExactTokensForETH(
        address fork,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFork(fork) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        amounts = _getAmountsOut(fork, amountIn, path);
        (uint256 amountWithdraw, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            amounts[amounts.length - 1],
            referee,
            false
        );
        require(amountWithdraw >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(fork, path[0], path[1]), amounts[0]);
        _swap(fork, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(msg.sender, amountWithdraw);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountOut expected amount of tokens out
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    /// @return amounts
    function swapETHForExactTokens(
        address fork,
        uint256 amountOut,
        address[] calldata path,
        address referee
    ) external payable whenNotPaused isValidFork(fork) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        amounts = _getAmountsIn(fork, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amounts[0], referee, true);
        require(amounts[0].add(feeAmount).add(referralReward) <= msg.value, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(_pairFor(fork, path[0], path[1]), amounts[0]));
        _swap(fork, amounts, path, msg.sender);

        // refund dust eth, if any
        if (msg.value > amounts[0].add(feeAmount).add(referralReward))
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0].add(feeAmount).add(referralReward));

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address fork,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFork(fork) isValidReferee(referee) {
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            amountIn,
            referee,
            false
        );
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(fork, path[0], path[1]), swapAmount);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(fork, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountOut expected tokens to receive
    /// @param amountInMax maximum tokens to send
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    /// @return amounts
    function swapTokensForExactTokens(
        address fork,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFork(fork) isValidReferee(referee) returns (uint256[] memory amounts) {
        referee = _getReferee(referee);
        amounts = _getAmountsIn(fork, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amounts[0], referee, true);

        require(amounts[0].add(feeAmount).add(referralReward) <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(fork, path[0], path[1]), amounts[0]);
        _swap(fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountOut expected tokens to receive
    /// @param amountInMax maximum tokens to send
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    /// @return amounts
    function swapTokensForExactETH(
        address fork,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFork(fork) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);

        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amountOut, referee, true);

        amounts = _getAmountsIn(fork, amountOut.add(feeAmount).add(referralReward), path);
        require(amounts[0].add(feeAmount).add(referralReward) <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(fork, path[0], path[1]), amounts[0]);
        _swap(fork, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        TransferHelper.safeTransferETH(msg.sender, amountOut);
        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param fork fork used to execute swap
    /// @param amountOutMin minimum expected tokens to receive
    /// @param path Sell path.
    /// @param referee address of referee for msg.sender, 0x adress if none
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address fork,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external payable whenNotPaused isValidFork(fork) isValidReferee(referee) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            msg.value,
            referee,
            false
        );
        IWETH(WETH).deposit{value: swapAmount}();
        assert(IWETH(WETH).transfer(_pairFor(fork, path[0], path[1]), swapAmount));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(fork, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev returns the referee for a given address, if new, registers referee
    /// @param referee the address of the referee for msg.sender
    /// @return referee address from referral registry
    function _getReferee(address referee) internal returns (address) {
        address sender = msg.sender;
        if (!referralRegistry.hasUserReferee(sender) && referee != address(0)) {
            referralRegistry.createReferralAnchor(sender, referee);
        }
        return referralRegistry.getUserReferee(sender);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        address fork,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? _pairFor(fork, output, path[i + 2]) : _to;
            IPancakePair(_pairFor(fork, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address fork,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(_pairFor(fork, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = _getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? _pairFor(fork, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @dev Executes a swap on 0x API
    /// @param data calldata expected by data field on 0x API (https://0x.org/docs/api#response-1)
    /// @param tokenOut the address of currency to sell – 0x address for ETH
    /// @param tokenIn the address of currency to buy – 0x address for ETH
    /// @param referee address of referee for msg.sender, 0x adress if none
    function executeZeroExSwap(
        bytes calldata data,
        address tokenOut,
        address tokenIn,
        address referee
    ) external payable nonReentrant whenNotPaused isValidReferee(referee) {
        referee = _getReferee(referee);
        bytes4 selector = data.readBytes4(0);
        address impl = IZerox(zeroEx).getFunctionImplementation(selector);
        require(impl != address(0), "FloozRouter: NO_IMPLEMENTATION");

        bool isAboveThreshold = userAboveBalanceThreshold(msg.sender);
        // skip fees & rewards for god mode users
        if (isAboveThreshold) {
            (bool success, ) = impl.delegatecall(data);
            require(success, "FloozRouter: REVERTED");
        } else {
            // if ETH in execute trade as router & distribute funds & fees
            if (msg.value > 0) {
                (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    msg.value,
                    referee,
                    false
                );
                (bool success, ) = impl.call{value: swapAmount}(data);
                require(success, "FloozRouter: REVERTED");
                TransferHelper.safeTransfer(tokenIn, msg.sender, IERC20(tokenIn).balanceOf(address(this)));
                _withdrawFeesAndRewards(address(0), tokenIn, referee, feeAmount, referralReward);
            } else {
                uint256 balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);
                (bool success, ) = impl.delegatecall(data);
                require(success, "FloozRouter: REVERTED");
                uint256 balanceAfter = IERC20(tokenOut).balanceOf(msg.sender);
                require(balanceBefore > balanceAfter, "INVALID_TOKEN");
                (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    balanceBefore.sub(balanceAfter),
                    referee,
                    true
                );
                _withdrawFeesAndRewards(tokenOut, tokenIn, referee, feeAmount, referralReward);
            }
        }
    }

    /// @dev calculates swap, fee & reward amounts
    /// @param amount total amount of tokens
    /// @param referee the address of the referee for msg.sender
    function _calculateFeesAndRewards(
        uint256 amount,
        address referee,
        bool additiveFee
    )
        internal
        view
        returns (
            uint256 swapAmount,
            uint256 feeAmount,
            uint256 referralReward
        )
    {
        // no fees for users above threshold
        if (userAboveBalanceThreshold(msg.sender)) {
            swapAmount = amount;
        } else {
            if (additiveFee) {
                swapAmount = amount;
                feeAmount = swapAmount.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR.sub(swapFee)).sub(amount);
            } else {
                feeAmount = amount.mul(swapFee).div(FEE_DENOMINATOR);
                swapAmount = amount.sub(feeAmount);
            }

            // calculate referral rates, if referee is not 0x
            if (referee != address(0) && referralsActivated) {
                uint16 referralRate = customReferralRewardRate[referee] > 0
                    ? customReferralRewardRate[referee]
                    : referralRewardRate;
                referralReward = feeAmount.mul(referralRate).div(FEE_DENOMINATOR);
                feeAmount = feeAmount.sub(referralReward);
            } else {
                referralReward = 0;
            }
        }
    }

    /// @dev lets the admin update an Uniswap style fork
    function updateFork(
        address _factory,
        bytes calldata _initCode,
        bool _activated
    ) external onlyOwner {
        forkActivated[_factory] = _activated;
        forkInitCode[_factory] = _initCode;
        emit ForkUpdated(_factory);
    }

    /// @dev returns if a users is above the SYA threshold and can swap without fees
    function userAboveBalanceThreshold(address _account) public view returns (bool) {
        return saveYourAssetsToken.balanceOf(_account) >= balanceThreshold;
    }

    /// @dev returns the fee nominator for a given user
    function getUserFee(address user) public view returns (uint256) {
        saveYourAssetsToken.balanceOf(user) >= balanceThreshold ? 0 : swapFee;
    }

    /// @dev lets the admin update the swapFee nominator
    function updateSwapFee(uint16 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
        emit SwapFeeUpdated(newSwapFee);
    }

    /// @dev lets the admin update the referral reward rate
    function updateReferralRewardRate(uint16 newReferralRewardRate) external onlyOwner {
        require(newReferralRewardRate <= FEE_DENOMINATOR, "FloozRouter: INVALID_RATE");
        referralRewardRate = newReferralRewardRate;
        emit ReferralRewardRateUpdated(newReferralRewardRate);
    }

    /// @dev lets the admin update which address receives the protocol fees
    function updateFeeReceiver(address payable newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(newFeeReceiver);
    }

    /// @dev lets the admin update the SYA balance threshold, which activates feeless trading for users
    function updateBalanceThreshold(uint256 newBalanceThreshold) external onlyOwner {
        balanceThreshold = newBalanceThreshold;
        emit BalanceThresholdUpdated(balanceThreshold);
    }

    /// @dev lets the admin update the status of the referral system
    function updateReferralsActivated(bool newReferralsActivated) external onlyOwner {
        referralsActivated = newReferralsActivated;
        emit ReferralsActivatedUpdated(newReferralsActivated);
    }

    /// @dev lets the admin set a new referral registry
    function updateReferralRegistry(address newReferralRegistry) external onlyOwner {
        referralRegistry = IReferralRegistry(newReferralRegistry);
        emit ReferralRegistryUpdated(newReferralRegistry);
    }

    /// @dev lets the admin set a custom referral rate
    function updateCustomReferralRewardRate(address account, uint16 referralRate) external onlyOwner returns (uint256) {
        require(referralRate <= FEE_DENOMINATOR, "FloozRouter: INVALID_RATE");
        customReferralRewardRate[account] = referralRate;
        emit CustomReferralRewardRateUpdated(account, referralRate);
    }

    /// @dev returns the referee for a given user – 0x address if none
    function getUserReferee(address user) external view returns (address) {
        return referralRegistry.getUserReferee(user);
    }

    /// @dev returns if the given user has been referred or not
    function hasUserReferee(address user) external view returns (bool) {
        return referralRegistry.hasUserReferee(user);
    }

    /// @dev lets the admin withdraw ETH from the contract.
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(to, amount);
    }

    /// @dev lets the admin withdraw ERC20s from the contract.
    function withdrawERC20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev distributes fees & referral rewards to users
    function _withdrawFeesAndRewards(
        address tokenReward,
        address tokenOut,
        address referee,
        uint256 feeAmount,
        uint256 referralReward
    ) internal {
        if (tokenReward == address(0)) {
            TransferHelper.safeTransferETH(feeReceiver, feeAmount);
            if (referralReward > 0) {
                TransferHelper.safeTransferETH(referee, referralReward);
                emit ReferralRewardPaid(msg.sender, referee, tokenOut, tokenReward, referralReward);
            }
        } else {
            TransferHelper.safeTransferFrom(tokenReward, msg.sender, feeReceiver, feeAmount);
            if (referralReward > 0) {
                TransferHelper.safeTransferFrom(tokenReward, msg.sender, referee, referralReward);
                emit ReferralRewardPaid(msg.sender, referee, tokenOut, tokenReward, referralReward);
            }
        }
    }

    /// @dev given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "FloozRouter: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul((9980));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /// @dev given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9980);
        amountIn = (numerator / denominator).add(1);
    }

    /// @dev performs chained getAmountOut calculations on any number of pairs
    function _getAmountsOut(
        address fork,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "FloozRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(fork, path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev performs chained getAmountIn calculations on any number of pairs
    function _getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "FloozRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = _getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev fetches and sorts the reserves for a pair
    function _getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @dev calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = PancakeLibrary.sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        forkInitCode[factory] // init code hash
                    )
                )
            )
        );
    }

    /// @dev lets the admin pause this contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev lets the admin unpause this contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev allows to receive ETH on the contract
    receive() external payable {}

    modifier isValidFork(address factory) {
        require(forkActivated[factory], "FloozRouter: INVALID_FACTORY");
        _;
    }

    modifier isValidReferee(address referee) {
        require(msg.sender != referee, "FloozRouter: SELF_REFERRAL");
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibBytesRichErrorsV06.sol";
import "./errors/LibRichErrorsV06.sol";


library LibBytesV06 {

    using LibBytesV06 for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    ///      When `from == 0`, the original array will match the slice.
    ///      In other cases its state will be corrupted.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                from,
                to
            ));
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                to,
                b.length
            ));
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        if (b.length == 0) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                b.length,
                0
            ));
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                b.length,
                index + 20 // 20 is length of address
            ));
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                b.length,
                index + 32
            ));
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        if (b.length < index + 4) {
            LibRichErrorsV06.rrevert(LibBytesRichErrorsV06.InvalidByteOperationError(
                LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                b.length,
                index + 4
            ));
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length)
        internal
        pure
    {
        assembly {
            mstore(b, length)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity =0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

library PancakeLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "PancakeLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "PancakeLibrary: ZERO_ADDRESS");
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "PancakeLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }
}

pragma solidity >=0.5.0;

interface IReferralRegistry {
    function getUserReferee(address _user) external view returns (address);

    function hasUserReferee(address _user) external view returns (bool);

    function createReferralAnchor(address _user, address _referee) external;
}

pragma solidity ^0.6.5;

interface IZerox {
    function getFunctionImplementation(bytes4 selector) external returns (address payable);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibBytesRichErrorsV06 {

    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR =
        0x28006595;

    // solhint-disable func-name-mixedcase
    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_BYTE_OPERATION_ERROR_SELECTOR,
            errorCode,
            offset,
            required
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;


library LibRichErrorsV06 {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/PancakeLibrary.sol";
import "./interfaces/IReferralRegistry.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IZerox.sol";

contract FloozMultichainRouter is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    event SwapFeeUpdated(uint16 swapFee);
    event ReferralRegistryUpdated(address referralRegistry);
    event ReferralRewardRateUpdated(uint16 referralRewardRate);
    event ReferralsActivatedUpdated(bool activated);
    event FeeReceiverUpdated(address payable feeReceiver);
    event CustomReferralRewardRateUpdated(address indexed account, uint16 referralRate);
    event ReferralRewardPaid(address from, address indexed to, address tokenOut, address tokenReward, uint256 amount);
    event ForkCreated(address factory);
    event ForkUpdated(address factory);

    struct SwapData {
        address fork;
        address referee;
        bool fee;
    }

    struct ExternalSwapData {
        bytes data;
        address fromToken;
        address toToken;
        uint256 amountFrom;
        address referee;
        uint256 minOut;
        bool fee;
    }

    // Denominator of fee
    uint256 public constant FEE_DENOMINATOR = 10000;

    // Numerator of fee
    uint16 public swapFee;

    // address of WETH
    address public immutable WETH;

    // address of zeroEx proxy contract to forward swaps
    address payable public immutable zeroEx;

    // address of 1inch contract to forward swaps
    address payable public immutable oneInch;

    // address of referral registry that stores referral anchors
    IReferralRegistry public referralRegistry;

    // address that receives protocol fees
    address payable public feeReceiver;

    // percentage of fees that will be paid as rewards
    uint16 public referralRewardRate;

    // stores if the referral system is turned on or off
    bool public referralsActivated;

    // stores individual referral rates
    mapping(address => uint16) public customReferralRewardRate;

    // stores uniswap forks status, index is the factory address
    mapping(address => bool) public forkActivated;

    // stores uniswap forks initCodes, index is the factory address
    mapping(address => bytes) public forkInitCode;

    /// @dev construct this contract
    /// @param _WETH address of WETH.
    /// @param _swapFee nominator for swapFee. Denominator = 10000
    /// @param _referralRewardRate percentage of swapFee that are paid out as rewards
    /// @param _feeReceiver address that receives protocol fees
    /// @param _referralRegistry address of referral registry that stores referral anchors
    /// @param _zeroEx address of zeroX proxy contract to forward swaps
    constructor(
        address _WETH,
        uint16 _swapFee,
        uint16 _referralRewardRate,
        address payable _feeReceiver,
        IReferralRegistry _referralRegistry,
        address payable _zeroEx,
        address payable _oneInch
    ) public {
        WETH = _WETH;
        swapFee = _swapFee;
        referralRewardRate = _referralRewardRate;
        feeReceiver = _feeReceiver;
        referralRegistry = _referralRegistry;
        zeroEx = _zeroEx;
        oneInch = _oneInch;
        referralsActivated = true;
    }

    /// @dev execute swap directly on Uniswap/Pancake & simular forks
    /// @param swapData stores the swapData information
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @return amounts
    function swapExactETHForTokens(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            msg.value,
            referee,
            false
        );
        amounts = _getAmountsOut(swapData.fork, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(_pairFor(swapData.fork, path[0], path[1]), amounts[0]));
        _swap(swapData.fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount of tokensIn
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external whenNotPaused isValidFork(swapData.fork) isValidReferee(swapData.referee) {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(swapData.fork, path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountOut);
        (uint256 amountWithdraw, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountOut,
            referee,
            false
        );
        require(amountWithdraw >= amountOutMin, "FloozRouter: LOW_SLIPPAGE");
        TransferHelper.safeTransferETH(msg.sender, amountWithdraw);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @return amounts
    function swapExactTokensForTokens(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountIn,
            referee,
            false
        );
        amounts = _getAmountsOut(swapData.fork, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), swapAmount);
        _swap(swapData.fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    /// @return amounts
    function swapExactTokensForETH(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        amounts = _getAmountsOut(swapData.fork, amountIn, path);
        (uint256 amountWithdraw, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amounts[amounts.length - 1],
            referee,
            false
        );
        require(amountWithdraw >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amounts[0]);
        _swap(swapData.fork, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(msg.sender, amountWithdraw);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOut expected amount of tokens out
    /// @param path Sell path.
    /// @return amounts
    function swapETHForExactTokens(
        SwapData calldata swapData,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        amounts = _getAmountsIn(swapData.fork, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amounts[0],
            referee,
            true
        );
        require(amounts[0].add(feeAmount).add(referralReward) <= msg.value, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");

        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(_pairFor(swapData.fork, path[0], path[1]), amounts[0]));
        _swap(swapData.fork, amounts, path, msg.sender);

        // refund dust eth, if any
        if (msg.value > amounts[0].add(feeAmount).add(referralReward))
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0].add(feeAmount).add(referralReward));

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountIn amount if tokens In
    /// @param amountOutMin minimum tokens to receive
    /// @param path Sell path.
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        SwapData calldata swapData,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    ) external whenNotPaused isValidFork(swapData.fork) isValidReferee(swapData.referee) {
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountIn,
            referee,
            false
        );
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), swapAmount);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(swapData.fork, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOut expected tokens to receive
    /// @param amountInMax maximum tokens to send
    /// @param path Sell path.
    /// @return amounts
    function swapTokensForExactTokens(
        SwapData calldata swapData,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        address referee = _getReferee(swapData.referee);
        amounts = _getAmountsIn(swapData.fork, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amounts[0],
            referee,
            true
        );

        require(amounts[0].add(feeAmount).add(referralReward) <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amounts[0]);
        _swap(swapData.fork, amounts, path, msg.sender);

        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOut expected tokens to receive
    /// @param amountInMax maximum tokens to send
    /// @param path Sell path.
    /// @return amounts
    function swapTokensForExactETH(
        SwapData calldata swapData,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path
    )
        external
        whenNotPaused
        isValidFork(swapData.fork)
        isValidReferee(swapData.referee)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);

        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            amountOut,
            referee,
            true
        );

        amounts = _getAmountsIn(swapData.fork, amountOut.add(feeAmount).add(referralReward), path);
        require(amounts[0].add(feeAmount).add(referralReward) <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(swapData.fork, path[0], path[1]), amounts[0]);
        _swap(swapData.fork, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        TransferHelper.safeTransferETH(msg.sender, amountOut);
        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev execute swap directly on Uniswap/Pancake/...
    /// @param swapData stores the swapData information
    /// @param amountOutMin minimum expected tokens to receive
    /// @param path Sell path.
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address[] calldata path
    ) external payable whenNotPaused isValidFork(swapData.fork) isValidReferee(swapData.referee) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        address referee = _getReferee(swapData.referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
            swapData.fee,
            msg.value,
            referee,
            false
        );
        IWETH(WETH).deposit{value: swapAmount}();
        assert(IWETH(WETH).transfer(_pairFor(swapData.fork, path[0], path[1]), swapAmount));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(swapData.fork, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        if (feeAmount.add(referralReward) > 0)
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    /// @dev returns the referee for a given address, if new, registers referee
    /// @param referee the address of the referee for msg.sender
    /// @return referee address from referral registry
    function _getReferee(address referee) internal returns (address) {
        address sender = msg.sender;
        if (!referralRegistry.hasUserReferee(sender) && referee != address(0)) {
            referralRegistry.createReferralAnchor(sender, referee);
        }
        return referralRegistry.getUserReferee(sender);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        address fork,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? _pairFor(fork, output, path[i + 2]) : _to;
            IPancakePair(_pairFor(fork, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address fork,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(_pairFor(fork, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = _getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? _pairFor(fork, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @dev Executes a swap on 1inch
    /// @param swapData encoded swap data
    function executeOneInchSwap(ExternalSwapData calldata swapData)
        external
        payable
        nonReentrant
        whenNotPaused
        isValidReferee(swapData.referee)
    {
        address referee = _getReferee(swapData.referee);
        uint256 balanceBefore;
        if (swapData.toToken == address(0)) {
            balanceBefore = msg.sender.balance;
        } else {
            balanceBefore = IERC20(swapData.toToken).balanceOf(msg.sender);
        }
        if (!swapData.fee) {
            // execute without fees
            if (swapData.fromToken != address(0)) {
                IERC20(swapData.fromToken).transferFrom(msg.sender, address(this), swapData.amountFrom);
                IERC20(swapData.fromToken).approve(oneInch, swapData.amountFrom);
            }
            // executes trade and sends toToken to defined recipient
            (bool success, ) = address(oneInch).call{value: msg.value}(swapData.data);
            require(success, "FloozRouter: REVERTED");
        } else {
            // Swap from ETH
            if (msg.value > 0 && swapData.fromToken == address(0)) {
                (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    swapData.fee,
                    msg.value,
                    referee,
                    false
                );
                (bool success, ) = address(oneInch).call{value: swapAmount}(swapData.data);
                require(success, "FloozRouter: REVERTED");
                _withdrawFeesAndRewards(address(0), swapData.toToken, referee, feeAmount, referralReward);
                // Swap from token
            } else {
                (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    swapData.fee,
                    swapData.amountFrom,
                    referee,
                    false
                );
                IERC20(swapData.fromToken).transferFrom(msg.sender, address(this), swapAmount);
                IERC20(swapData.fromToken).approve(oneInch, swapAmount);
                (bool success, ) = address(oneInch).call(swapData.data);
                require(success, "FloozRouter: REVERTED");
                _withdrawFeesAndRewards(swapData.fromToken, swapData.toToken, referee, feeAmount, referralReward);
            }
            uint256 balanceAfter;
            if (swapData.toToken == address(0)) {
                balanceAfter = msg.sender.balance;
            } else {
                balanceAfter = IERC20(swapData.toToken).balanceOf(msg.sender);
            }
            require(balanceAfter.sub(balanceBefore) >= swapData.minOut, "FloozRouter: INSUFFICIENT_OUTPUT");
        }
    }

    /// @dev Executes a swap on 0x
    /// @param swapData encoded swap data
    function executeZeroExSwap(ExternalSwapData calldata swapData)
        external
        payable
        nonReentrant
        whenNotPaused
        isValidReferee(swapData.referee)
    {
        address referee = _getReferee(swapData.referee);
        uint256 balanceBefore;
        if (swapData.toToken == address(0)) {
            balanceBefore = msg.sender.balance;
        } else {
            balanceBefore = IERC20(swapData.toToken).balanceOf(msg.sender);
        }
        if (!swapData.fee) {
            if (msg.value > 0 && swapData.fromToken == address(0)) {
                (bool success, ) = zeroEx.call{value: msg.value}(swapData.data);
                require(success, "FloozRouter: REVERTED");
                TransferHelper.safeTransfer(
                    swapData.toToken,
                    msg.sender,
                    IERC20(swapData.toToken).balanceOf(address(this))
                );
            } else {
                IERC20(swapData.fromToken).transferFrom(msg.sender, address(this), swapData.amountFrom);
                IERC20(swapData.fromToken).approve(zeroEx, swapData.amountFrom);
                (bool success, ) = zeroEx.call(swapData.data);
                require(success, "FloozRouter: REVERTED");
                if (swapData.toToken == address(0)) {
                    TransferHelper.safeTransferETH(msg.sender, address(this).balance);
                } else {
                    TransferHelper.safeTransfer(
                        swapData.toToken,
                        msg.sender,
                        IERC20(swapData.toToken).balanceOf(address(this))
                    );
                }
            }
        } else {
            // Swap from ETH
            if (msg.value > 0 && swapData.fromToken == address(0)) {
                (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    swapData.fee,
                    msg.value,
                    referee,
                    false
                );
                (bool success, ) = zeroEx.call{value: swapAmount}(swapData.data);
                require(success, "FloozRouter: REVERTED");
                TransferHelper.safeTransfer(
                    swapData.toToken,
                    msg.sender,
                    IERC20(swapData.toToken).balanceOf(address(this))
                );
                _withdrawFeesAndRewards(address(0), swapData.toToken, referee, feeAmount, referralReward);
                // Swap from Token
            } else {
                (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(
                    swapData.fee,
                    swapData.amountFrom,
                    referee,
                    false
                );
                IERC20(swapData.fromToken).transferFrom(msg.sender, address(this), swapAmount);
                IERC20(swapData.fromToken).approve(zeroEx, swapAmount);
                (bool success, ) = zeroEx.call(swapData.data);
                require(success, "FloozRouter: REVERTED");
                if (swapData.toToken == address(0)) {
                    TransferHelper.safeTransferETH(msg.sender, address(this).balance);
                } else {
                    TransferHelper.safeTransfer(
                        swapData.toToken,
                        msg.sender,
                        IERC20(swapData.toToken).balanceOf(address(this))
                    );
                }
                _withdrawFeesAndRewards(swapData.fromToken, swapData.toToken, referee, feeAmount, referralReward);
            }
        }
        uint256 balanceAfter;
        if (swapData.toToken == address(0)) {
            balanceAfter = msg.sender.balance;
        } else {
            balanceAfter = IERC20(swapData.toToken).balanceOf(msg.sender);
        }
        require(balanceAfter.sub(balanceBefore) >= swapData.minOut, "FloozRouter: INSUFFICIENT_OUTPUT");
    }

    /// @dev calculates swap, fee & reward amounts
    /// @param fee boolean if fee will be applied or not
    /// @param amount total amount of tokens
    /// @param referee the address of the referee for msg.sender
    function _calculateFeesAndRewards(
        bool fee,
        uint256 amount,
        address referee,
        bool additiveFee
    )
        internal
        view
        returns (
            uint256 swapAmount,
            uint256 feeAmount,
            uint256 referralReward
        )
    {
        uint16 swapFee = swapFee;
        // no fees for users above threshold
        if (!fee) {
            swapAmount = amount;
        } else {
            if (additiveFee) {
                swapAmount = amount;
                feeAmount = swapAmount.mul(FEE_DENOMINATOR).div(FEE_DENOMINATOR.sub(swapFee)).sub(amount);
            } else {
                feeAmount = amount.mul(swapFee).div(FEE_DENOMINATOR);
                swapAmount = amount.sub(feeAmount);
            }

            // calculate referral rates, if referee is not 0x
            if (referee != address(0) && referralsActivated) {
                uint16 referralRate = customReferralRewardRate[referee] > 0
                    ? customReferralRewardRate[referee]
                    : referralRewardRate;
                referralReward = feeAmount.mul(referralRate).div(FEE_DENOMINATOR);
                feeAmount = feeAmount.sub(referralReward);
            } else {
                referralReward = 0;
            }
        }
    }

    /// @dev lets the admin register an Uniswap style fork
    function registerFork(address _factory, bytes calldata _initCode) external onlyOwner {
        require(!forkActivated[_factory], "FloozRouter: ACTIVE_FORK");
        forkActivated[_factory] = true;
        forkInitCode[_factory] = _initCode;
        emit ForkCreated(_factory);
    }

    /// @dev lets the admin update an Uniswap style fork
    function updateFork(
        address _factory,
        bytes calldata _initCode,
        bool _activated
    ) external onlyOwner {
        forkActivated[_factory] = _activated;
        forkInitCode[_factory] = _initCode;
        emit ForkUpdated(_factory);
    }

    /// @dev lets the admin update the swapFee nominator
    function updateSwapFee(uint16 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
        emit SwapFeeUpdated(newSwapFee);
    }

    /// @dev lets the admin update the referral reward rate
    function updateReferralRewardRate(uint16 newReferralRewardRate) external onlyOwner {
        require(newReferralRewardRate <= FEE_DENOMINATOR, "FloozRouter: INVALID_RATE");
        referralRewardRate = newReferralRewardRate;
        emit ReferralRewardRateUpdated(newReferralRewardRate);
    }

    /// @dev lets the admin update which address receives the protocol fees
    function updateFeeReceiver(address payable newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(newFeeReceiver);
    }

    /// @dev lets the admin update the status of the referral system
    function updateReferralsActivated(bool newReferralsActivated) external onlyOwner {
        referralsActivated = newReferralsActivated;
        emit ReferralsActivatedUpdated(newReferralsActivated);
    }

    /// @dev lets the admin set a new referral registry
    function updateReferralRegistry(address newReferralRegistry) external onlyOwner {
        referralRegistry = IReferralRegistry(newReferralRegistry);
        emit ReferralRegistryUpdated(newReferralRegistry);
    }

    /// @dev lets the admin set a custom referral rate
    function updateCustomReferralRewardRate(address account, uint16 referralRate) external onlyOwner returns (uint256) {
        require(referralRate <= FEE_DENOMINATOR, "FloozRouter: INVALID_RATE");
        customReferralRewardRate[account] = referralRate;
        emit CustomReferralRewardRateUpdated(account, referralRate);
    }

    /// @dev returns the referee for a given user - 0x address if none
    function getUserReferee(address user) external view returns (address) {
        return referralRegistry.getUserReferee(user);
    }

    /// @dev returns if the given user has been referred or not
    function hasUserReferee(address user) external view returns (bool) {
        return referralRegistry.hasUserReferee(user);
    }

    /// @dev lets the admin withdraw ETH from the contract.
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(to, amount);
    }

    /// @dev lets the admin withdraw ERC20s from the contract.
    function withdrawERC20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }

    /// @dev distributes fees & referral rewards to users
    function _withdrawFeesAndRewards(
        address tokenReward,
        address tokenOut,
        address referee,
        uint256 feeAmount,
        uint256 referralReward
    ) internal {
        if (tokenReward == address(0)) {
            TransferHelper.safeTransferETH(feeReceiver, feeAmount);
            if (referralReward > 0) {
                TransferHelper.safeTransferETH(referee, referralReward);
                emit ReferralRewardPaid(msg.sender, referee, tokenOut, tokenReward, referralReward);
            }
        } else {
            TransferHelper.safeTransferFrom(tokenReward, msg.sender, feeReceiver, feeAmount);
            if (referralReward > 0) {
                TransferHelper.safeTransferFrom(tokenReward, msg.sender, referee, referralReward);
                emit ReferralRewardPaid(msg.sender, referee, tokenOut, tokenReward, referralReward);
            }
        }
    }

    /// @dev given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "FloozRouter: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul((9970));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /// @dev given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9970);
        amountIn = (numerator / denominator).add(1);
    }

    /// @dev performs chained getAmountOut calculations on any number of pairs
    function _getAmountsOut(
        address fork,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "FloozRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(fork, path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev performs chained getAmountIn calculations on any number of pairs
    function _getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "FloozRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = _getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev fetches and sorts the reserves for a pair
    function _getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @dev calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = PancakeLibrary.sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        forkInitCode[factory] // init code hash
                    )
                )
            )
        );
    }

    /// @dev lets the admin pause this contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev lets the admin unpause this contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev allows to receive ETH on the contract
    receive() external payable {}

    modifier isValidFork(address factory) {
        require(forkActivated[factory], "FloozRouter: INVALID_FACTORY");
        _;
    }

    modifier isValidReferee(address referee) {
        require(msg.sender != referee, "FloozRouter: SELF_REFERRAL");
        _;
    }
}

pragma solidity =0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IWETH.sol";

contract FeeReceiverMultichain is Ownable {
    address public WETH;

    constructor(address _WETH) public {
        WETH = _WETH;
    }

    /// @dev converts WETH to ETH
    function unwrapWETH() public {
        uint256 balance = IWETH(WETH).balanceOf(address(this));
        require(balance > 0, "FeeReceiver: Nothing to unwrap");
        IWETH(WETH).withdraw(balance);
    }

    /// @dev lets the owner withdraw ETH from the contract
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    /// @dev lets the owner withdraw any ERC20 Token from the contract
    function withdrawERC20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /// @dev allows to receive ETH on this contract
    receive() external payable {}
}

pragma solidity =0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReferralRegistry is Ownable {
    event ReferralAnchorCreated(address indexed user, address indexed referee);
    event ReferralAnchorUpdated(address indexed user, address indexed referee);
    event AnchorManagerUpdated(address account, bool isManager);

    // stores addresses which are allowed to create new anchors
    mapping(address => bool) public isAnchorManager;

    // stores the address that referred a given user
    mapping(address => address) public referralAnchor;

    /// @dev create a new referral anchor on the registry
    /// @param _user address of the user
    /// @param _referee address wich referred the user
    function createReferralAnchor(address _user, address _referee) external onlyAnchorManager {
        require(referralAnchor[_user] == address(0), "ReferralRegistry: ANCHOR_EXISTS");
        referralAnchor[_user] = _referee;
        emit ReferralAnchorCreated(_user, _referee);
    }

    /// @dev allows admin to overwrite anchor
    /// @param _user address of the user
    /// @param _referee address wich referred the user
    function updateReferralAnchor(address _user, address _referee) external onlyOwner {
        referralAnchor[_user] = _referee;
        emit ReferralAnchorUpdated(_user, _referee);
    }

    /// @dev allows admin to grant/remove anchor priviliges
    /// @param _anchorManager address of the anchor manager
    /// @param _isManager add or remove privileges
    function updateAnchorManager(address _anchorManager, bool _isManager) external onlyOwner {
        isAnchorManager[_anchorManager] = _isManager;
        emit AnchorManagerUpdated(_anchorManager, _isManager);
    }

    function getUserReferee(address _user) external view returns (address) {
        return referralAnchor[_user];
    }

    function hasUserReferee(address _user) external view returns (bool) {
        return referralAnchor[_user] != address(0);
    }

    modifier onlyAnchorManager() {
        require(isAnchorManager[msg.sender], "ReferralRegistry: FORBIDDEN");
        _;
    }
}