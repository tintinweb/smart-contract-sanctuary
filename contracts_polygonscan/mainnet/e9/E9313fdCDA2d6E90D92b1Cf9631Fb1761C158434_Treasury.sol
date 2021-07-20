pragma solidity 0.5.17;

import "../standards/SafeMath.sol";
import "../standards/IERC20.sol";
import "../standards/Address.sol";
import "../standards/SafeERC20.sol";

import "../interfaces/IConverter.sol";
import "../interfaces/ILiquidityMiningRewards.sol";
import "../interfaces/IRewardStaker.sol";

// A simple treasury that takes erc20 tokens and ETH
contract Treasury {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;
    mapping (address => bool) public isManager;
    address public converter;

    address public omt;
    address public wbnb;
    address public busd;
    address public omtBNBPancakeLP;
    address public omtBUSDPancakeLP;

    address public omtRewardStaker;
    address public liquidityMiningReward;

    uint256 public totalOMTBuyback;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _converter, address _omt, address _wbnb, address _busd, address _omtBNBPancakeLP, address _omtBUSDPancakeLP, address _omtRewardStaker, address _liquidityMiningReward) public {
        governance = msg.sender;
        converter = _converter;
        omt = _omt;
        wbnb = _wbnb;
        busd = _busd;
        omtBNBPancakeLP = _omtBNBPancakeLP;
        omtBUSDPancakeLP = _omtBUSDPancakeLP;
        omtRewardStaker = _omtRewardStaker;
        liquidityMiningReward = _liquidityMiningReward;
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance, "!governance");
        _;
    }

    modifier onlyManager() {
        require(isManager[msg.sender] == true, "!manager");
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function holdings(address _token)
        public
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function() external payable {}

    function takeOut(
        address _token,
        address _destination,
        uint256 _amount
    )
        public
        onlyGov
    {
        require(_amount <= holdings(_token), "!insufficient");
        IERC20(_token).safeTransfer(_destination, _amount);
    }

    function takeOutETH(
        address payable _destination,
        uint256 _amount
    )
        public
        payable
        onlyGov
    {
        _destination.transfer(_amount);
    }

    // swap any token to any token
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn) public onlyManager {
        IERC20(_tokenIn).safeApprove(converter, 0);
        IERC20(_tokenIn).safeApprove(converter, _amountIn);
        uint256 amountOut = IConverter(converter).swap(_tokenIn, _tokenOut, _amountIn);

        if (_tokenOut == omt) {
            totalOMTBuyback = totalOMTBuyback.add(amountOut);
        }
        emit Swapped(_tokenIn, _tokenOut, _amountIn, amountOut);
    }

    // add liquidity for any token pair
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    )
        public
        onlyManager
    {
        IERC20(_tokenA).safeApprove(converter, 0);
        IERC20(_tokenA).safeApprove(converter, _amountA);
        IERC20(_tokenB).safeApprove(converter, 0);
        IERC20(_tokenB).safeApprove(converter, _amountB);
        uint256 lpAmount = IConverter(converter).addLiquidity(_tokenA, _tokenB, _amountA, _amountB);
        emit AddedLiquidity(_tokenA, _tokenB, _amountA, _amountB, lpAmount);
    }

    // get underlyings to LP
    function removeLiquidity(address _tokenA, address _tokenB, address _lpPair, uint _liquidity) public onlyManager {
        IERC20(_lpPair).safeApprove(converter, 0);
        IERC20(_lpPair).safeApprove(converter, _liquidity);
        (uint256 amountA, uint256 amountB) = IConverter(converter).removeLiquidity(_tokenA, _tokenB, _lpPair, _liquidity);
        emit RemovedLiquidity(_tokenA, _tokenB, amountA, amountB, _liquidity);
    }

    // swap any token into half omt, half wbnb, and add liquidity
    function addLiquidityToOMTBNBPair(address _token, uint256 _amount) public onlyManager {
        IERC20(_token).safeApprove(converter, 0);
        IERC20(_token).safeApprove(converter, _amount);
        uint half = _amount.div(2);
        uint omtAmount = IConverter(converter).swap(_token, omt, half);
        uint wbnbAmount = IConverter(converter).swap(_token, wbnb, half);
        IERC20(omt).safeApprove(converter, 0);
        IERC20(omt).safeApprove(converter, omtAmount);
        IERC20(wbnb).safeApprove(converter, 0);
        IERC20(wbnb).safeApprove(converter, wbnbAmount);
        uint256 lpAmount = IConverter(converter).addLiquidity(omt, wbnb, omtAmount, wbnbAmount);

        totalOMTBuyback = totalOMTBuyback.add(omtAmount);
        emit AddedLiquidity(omt, wbnb, omtAmount, wbnbAmount, lpAmount);
    }

    // swap any token into half omt, half busd, and add liquidity
    function addLiquidityToOMTBUSDPair(address _token, uint256 _amount) public onlyManager {
        IERC20(_token).safeApprove(converter, 0);
        IERC20(_token).safeApprove(converter, _amount);
        uint half = _amount.div(2);
        uint omtAmount = IConverter(converter).swap(_token, omt, half);
        uint busdAmount = IConverter(converter).swap(_token, busd, half);
        IERC20(omt).safeApprove(converter, 0);
        IERC20(omt).safeApprove(converter, omtAmount);
        IERC20(busd).safeApprove(converter, 0);
        IERC20(busd).safeApprove(converter, busdAmount);
        uint256 lpAmount = IConverter(converter).addLiquidity(omt, busd, omtAmount, busdAmount);

        totalOMTBuyback = totalOMTBuyback.add(omtAmount);
        emit AddedLiquidity(omt, busd, omtAmount, busdAmount, lpAmount);
    }

    function depositOMTBNBLP(uint256 _amount) public onlyManager {
        IERC20(omtBNBPancakeLP).safeApprove(liquidityMiningReward, 0);
        IERC20(omtBNBPancakeLP).safeApprove(liquidityMiningReward, _amount);
        ILiquidityMiningRewards(liquidityMiningReward).deposit(omtBNBPancakeLP, _amount);
    }

    function withdrawOMTBNBLP(uint256 _amount) public onlyManager {
        ILiquidityMiningRewards(liquidityMiningReward).withdraw(omtBNBPancakeLP, _amount);
    }

    function depositOMTBUSDLP(uint256 _amount) public onlyManager {
        IERC20(omtBUSDPancakeLP).safeApprove(liquidityMiningReward, 0);
        IERC20(omtBUSDPancakeLP).safeApprove(liquidityMiningReward, _amount);
        ILiquidityMiningRewards(liquidityMiningReward).deposit(omtBUSDPancakeLP, _amount);
    }

    function withdrawOMTBUSDLP(uint256 _amount) public onlyManager {
        ILiquidityMiningRewards(liquidityMiningReward).withdraw(omtBUSDPancakeLP, _amount);
    }

    function claimLPReward() public onlyManager {
        ILiquidityMiningRewards(liquidityMiningReward).claimAll();
    }

    function unstakeRewards() public onlyManager {
        uint _shares = IRewardStaker(omtRewardStaker).shares(address(this));
        IRewardStaker(omtRewardStaker).leave(_shares);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function setGov(address _governance)
        public
        onlyGov
    {
        governance = _governance;
    }

    function addManager(address _manager)
        public
        onlyGov
    {
        isManager[_manager] = true;
        emit AddManager(_manager);
    }

    function removeManager(address _manager)
        public
        onlyGov
    {
        isManager[_manager] = false;
        emit RemoveManager(_manager);
    }

    function setConverter(address _converter)
        public
        onlyGov
    {
        converter = _converter;
    }

    function setOMTRewardStaker(address _omtRewardStaker)
        public
        onlyGov
    {
        omtRewardStaker = _omtRewardStaker;
    }

    function setLiquidityMiningReward(address _liquidityMiningReward)
        public
        onlyGov
    {
        liquidityMiningReward = _liquidityMiningReward;
    }

    /* ========== EVENTS ========== */
    event Swapped(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event AddedLiquidity(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 lpAmount);
    event RemovedLiquidity(address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 lpAmount);
    event AddManager(address indexed manager);
    event RemoveManager(address indexed manager);
}

pragma solidity 0.5.17;

interface IConverter {
  function swap(address _tokenIn, address _tokenOut, uint _amountIn) external returns (uint amountOut_);
  function addLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB) external returns (uint lpAmount_);
  function removeLiquidity(address _tokenA, address _tokenB, address _lpPair, uint _liquidity) external returns (uint amountA_, uint amountB_);
}

pragma solidity 0.5.17;

interface ILiquidityMiningRewards {
    function deposit(address _token, uint256 _amount) external;
    function withdraw(address _token, uint256 _amount) external;
    function claimAll() external;
}

pragma solidity 0.5.17;

interface IRewardStaker {
    function enter(uint256 _amount, address _user) external;
    function leave(uint256 _share) external;
    function shares(address) external view returns (uint);
}

pragma solidity 0.5.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity 0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity 0.5.17;

import { IERC20 } from "./IERC20.sol";
import { SafeMath } from "./SafeMath.sol";
import { Address } from "./Address.sol";
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.5.17;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}