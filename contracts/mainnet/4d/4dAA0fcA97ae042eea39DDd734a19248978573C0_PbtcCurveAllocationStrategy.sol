pragma solidity 0.6.6;

import "../interfaces/IAllocationStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../modules/UniswapModule.sol";
import "../interfaces/ICurveGaugeV2.sol";
import "../interfaces/ICurveDepositPBTC.sol";
import "../interfaces/ICurveMinter.sol";

/**
    @title pBTC allocation strategy
    @author Overall Finance
    @notice Used for allocating oToken funds pBtc sBtc Curve Pool
*/
contract PbtcCurveAllocationStrategy is IAllocationStrategy, UniswapModule, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IERC20 public underlying;
    IERC20 public PNT;
    IERC20 public CRV;
    IERC20 public pBTCsbtcCRV;
    ICurveDepositPBTC public depositPbtc;
    ICurveGaugeV2 public pBTCsbtcCRVGauge;
    ICurveMinter public curveMinter;
    address public uniswapRouter;
    uint256 private constant SLIPPAGE_BASE_UNIT = 10**18;
    uint256 public allowedSlippage = 1500000000000000000;
    bool initialised;

    /**
        @notice Constructor
        @param _underlying Address of the underlying token
        @param _pntAddress Address of the PNT token
        @param _crvAddress Address of the CRV token
        @param _depositPbtc Address of the Curve pool deposit contract
        @param _pBTCsbtcCRV Address of the Curve contract
        @param _pBTCsbtcCRVGauge Address of the Curve contract
        @param _uniswapRouter Address of the UniswapV2Router
    */
    constructor(address _underlying, address _pntAddress, address _crvAddress, address _depositPbtc, address _pBTCsbtcCRV, address _pBTCsbtcCRVGauge, address _curveMinter, address _uniswapRouter) public {
        underlying = IERC20(_underlying);
        PNT = IERC20(_pntAddress);
        CRV = IERC20(_crvAddress);
        depositPbtc = ICurveDepositPBTC(_depositPbtc);
        pBTCsbtcCRV = IERC20(_pBTCsbtcCRV);
        pBTCsbtcCRVGauge = ICurveGaugeV2(_pBTCsbtcCRVGauge);
        curveMinter = ICurveMinter(_curveMinter);
        uniswapRouter = _uniswapRouter;
    }

    /**
        @notice Set maximum approves for used protocols
    */
    function setMaxApprovals() external {
        require(!initialised, "Already initialised");
        initialised = true;
        PNT.safeApprove(uniswapRouter, uint256(-1));
        CRV.safeApprove(uniswapRouter, uint256(-1));
        underlying.safeApprove(address(depositPbtc), uint256(-1));
        pBTCsbtcCRV.safeApprove(address(depositPbtc), uint256(-1));
        pBTCsbtcCRV.safeApprove(address(pBTCsbtcCRVGauge), uint256(-1));
    }

    /**
        @notice Get the amount of underlying in the BTC strategy
        @return Balance denominated in the underlying asset
    */
    function balanceOfUnderlying() external override returns (uint256) {
        uint256 curveGaugeBalance = pBTCsbtcCRVGauge.balanceOf(address(this));
        uint256 balance = _balanceOfUnderlying(curveGaugeBalance);
        return balance;
    }

    /**
        @notice Get the amount of underlying in the BTC strategy, while not modifying state
        @return Balance denominated in the underlying asset
    */
    function balanceOfUnderlyingView() public view override returns(uint256) {
        uint256 curveGaugeBalance = pBTCsbtcCRVGauge.balanceOf(address(this));
        uint256 balance = _balanceOfUnderlying(curveGaugeBalance);
        return balance;
    }

    /**
        @notice Get the amount of underlying in the BTC strategy, while not modifying state
        @return Balance denominated in the underlying asset
    */
    function _balanceOfUnderlying(uint256 curveGaugeAmount) internal view returns(uint256) {
        if (curveGaugeAmount == 0)
            return 0;
        uint256 balance = depositPbtc.calc_withdraw_one_coin(curveGaugeAmount, 0);
        return balance;
    }

    /**
        @notice Deposit the underlying token in the protocol
        @param _investAmount Amount of underlying tokens to hold
    */
    function investUnderlying(uint256 _investAmount) external override onlyOwner returns (uint256) {
        uint256 balanceBeforeInvestment = pBTCsbtcCRVGauge.balanceOf(address(this));
        uint256 maxAllowedMinAmount = _investAmount - ((_investAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pBTCsbtcCRVAmount = depositPbtc.add_liquidity([_investAmount, 0, 0, 0], maxAllowedMinAmount);
        pBTCsbtcCRVGauge.deposit(pBTCsbtcCRVAmount, address(this));
        uint256 poolTokensAcquired = pBTCsbtcCRVGauge.balanceOf(address(this)).sub(balanceBeforeInvestment);
        uint256 investAmount = _balanceOfUnderlying(poolTokensAcquired);
        return investAmount;
    }

    /**
        @notice Redeeem the underlying asset from the protocol
        @param _redeemAmount Amount of oTokens to redeem
        @param _receiver Address of a receiver
    */
    function redeemUnderlying(uint256 _redeemAmount, address _receiver) external override onlyOwner returns(uint256) {
        uint256 redeemAmountGauge = depositPbtc.calc_token_amount([_redeemAmount, 0, 0, 0], false);
        pBTCsbtcCRVGauge.withdraw(redeemAmountGauge);

        uint256 pBTCsbtcCRVAmount = pBTCsbtcCRV.balanceOf(address(this));
        uint256 maxAllowedMinAmount = pBTCsbtcCRVAmount - ((pBTCsbtcCRVAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pbtcAmount = depositPbtc.remove_liquidity_one_coin(pBTCsbtcCRVAmount, 0, maxAllowedMinAmount);

        underlying.safeTransfer(_receiver, pbtcAmount);
        return pbtcAmount;
    }

    /**
        @notice Redeem the entire balance from the underlying protocol
    */
    function redeemAll() external override onlyOwner {
        uint256 balance = pBTCsbtcCRVGauge.balanceOf(address(this));
        pBTCsbtcCRVGauge.withdraw(balance);

        uint256 pBTCsbtcCRVAmount = pBTCsbtcCRV.balanceOf(address(this));
        uint256 maxAllowedMinAmount = pBTCsbtcCRVAmount - ((pBTCsbtcCRVAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
        uint256 pbtcAmount = depositPbtc.remove_liquidity_one_coin(pBTCsbtcCRVAmount, 0, maxAllowedMinAmount);

        underlying.safeTransfer(msg.sender, pbtcAmount);
    }

    /**
        @notice Claim and reinvest yield from protocols
        @param _amountOutMinCRV Minimal amount for a swap of CRV
        @param _amountOutMinPNT Minimal amount for a swap of PNT
        @param _deadline Deadline for a swap
    */
    function farmYield(uint256 _amountOutMinCRV, uint256 _amountOutMinPNT, uint256 _deadline) public {
        curveMinter.mint(address(pBTCsbtcCRVGauge));
        uint256 crvBalance = CRV.balanceOf(address(this));
        uint256[] memory swappedAmounts;
        uint256 farmedAmount;
        if (crvBalance > 0) {
            swappedAmounts = swapTokensThroughETH(address(CRV), address(underlying), crvBalance, _amountOutMinCRV, _deadline, uniswapRouter);
            farmedAmount = swappedAmounts[2];
        }
        pBTCsbtcCRVGauge.claim_rewards(address(this));
        uint256 pntBalance = PNT.balanceOf(address(this));
        if (pntBalance > 0) {
            swappedAmounts = swapTokensThroughETH(address(PNT), address(underlying), pntBalance, _amountOutMinPNT, _deadline, uniswapRouter);
            farmedAmount = farmedAmount.add(swappedAmounts[2]);
        }

        if (farmedAmount > 0) {
            uint256 maxAllowedMinAmount = farmedAmount - ((farmedAmount * allowedSlippage) / (SLIPPAGE_BASE_UNIT * 100));
            uint256 pBTCsbtcCRVAmount = depositPbtc.add_liquidity([farmedAmount, 0, 0, 0], maxAllowedMinAmount);
            pBTCsbtcCRVGauge.deposit(pBTCsbtcCRVAmount, address(this));
        }
    }
}

pragma solidity 0.6.6;

interface IAllocationStrategy {
    function balanceOfUnderlying() external returns (uint256);
    function balanceOfUnderlyingView() external view returns(uint256);
    function investUnderlying(uint256 _investAmount) external returns (uint256);
    function redeemUnderlying(uint256 _redeemAmount, address _receiver) external returns (uint256);
    function redeemAll() external;
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

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IUniswapV2Router.sol";

contract UniswapModule {
    using SafeERC20 for IERC20;
    function getAmountsOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _uniswapRouter) internal view returns (uint256 amountsOut) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        uint256[] memory amountsOutArr = uniswapRouter.getAmountsOut(_amountIn, path);
        return amountsOutArr[1];
    }

    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline,
        address _uniswapRouter) internal returns (uint256[] memory) {
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        amounts = uniswapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            _deadline
        );
        return amounts;
    }

    function swapExactETHForTokens(
        address _tokenOut,
        uint256 _amountOutMin,
        uint256 _deadline,
        address _uniswapRouter) internal returns (uint256[] memory) {
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        path[0] = uniswapRouter.WETH();
        path[1] = _tokenOut;
        amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(
            _amountOutMin,
            path,
            address(this),
            _deadline
        );
        return amounts;
    }

    function swapExactTokensForETH(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline,
        address _uniswapRouter) internal returns (uint256[] memory) {
        uint256[] memory amounts;
        address[] memory path = new address[](2);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        path[0] = _tokenIn;
        path[1] = uniswapRouter.WETH();
        amounts = uniswapRouter.swapExactTokensForETH(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            _deadline
        );
        return amounts;
    }

    function swapTokensThroughETH(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _deadline,
        address _uniswapRouter) internal returns (uint256[] memory) {
        uint256[] memory amounts;
        address[] memory path = new address[](3);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        path[0] = _tokenIn;
        path[1] = uniswapRouter.WETH();
        path[2] = _tokenOut;
        amounts = uniswapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            _deadline
        );
        return amounts;
    }

    function getAmountOut(uint _amountIn, uint _reserveIn, uint _reserveOut, address _uniswapRouter) internal returns (uint amountOut) {
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        return uniswapRouter.getAmountOut(_amountIn, _reserveIn, _reserveOut);
    }

    function getAmountIn(uint _amountOut, uint _reserveIn, uint _reserveOut, address _uniswapRouter) internal returns (uint amountIn) {
        IUniswapV2Router uniswapRouter = IUniswapV2Router(_uniswapRouter);
        return uniswapRouter.getAmountIn(_amountOut, _reserveIn, _reserveOut);
    }
}

pragma solidity 0.6.6;

interface ICurveGaugeV2 {
    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function balanceOf(address _addr) external view returns (uint256);

    function approve(address _addr, uint256 _amount) external returns (bool);

    function crv_token() external returns (address);

    function claim_rewards(address _addr) external;

    function claimable_reward(address _addr, address _token) external view returns (uint256);

    function claimable_tokens(address addr) external returns (uint256);

    function allowance(address _owner, address _spender) external returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function transfer(address _to, uint256 _amount) external returns (bool);
}

pragma solidity 0.6.6;

interface ICurveDepositPBTC {
    function add_liquidity(uint256[4] calldata call_data_amounts, uint256 min_mint_amount) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function token() external returns (address);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool is_deposit) external view returns (uint256);
}

pragma solidity 0.6.6;

interface ICurveMinter {
    function mint(address gauge_addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

pragma solidity 0.6.6;

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
}

