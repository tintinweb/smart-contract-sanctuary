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

// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/PancakeLibrary.sol";
import "./interfaces/IReferralRegistry.sol";
import "./interfaces/IReferrals.sol";
import "./interfaces/IWETH.sol";

contract FloozRouter is Ownable, Pausable {
    using SafeMath for uint256;
    event SwapFeeUpdated(uint16 swapFee);
    event ReferralRewardRateUpdated(uint16 referralRewardRate);
    event ReferralsActivatedUpdated(bool activated);
    event FeeReceiverUpdated(address feeReceiver);
    event BalanceThresholdUpdated(uint256 balanceThreshold);
    event ReferralAnchorCreated(address indexed user, address indexed referee);
    event ReferralRegistryUpdated(address referralRegistry);
    event CustomReferralRewardRateUpdated(address indexed account, uint16 referralRate);
    event ReferralRewardPaid(address from, address indexed to, address tokenOut, address tokenReward, uint256 amount);

    uint256 public constant FEE_DENOMINATOR = 10000;
    address public immutable WETH;
    IReferralRegistry public referralRegistry;
    bytes internal pancakeInitCodeV1;
    bytes internal pancakeInitCodeV2;
    address public pancakeFactoryV1;
    address public pancakeFactoryV2;
    IERC20 public saveYourAssetsToken;
    uint256 public balanceThreshold;
    address public feeReceiver;
    uint16 public swapFee;
    uint16 public referralRewardRate;
    bool public referralsActivated;

    // stores individual referral rates
    mapping(address => uint16) public customReferralRewardRate;

    // stores the address that refered this user
    mapping(address => address) public referralAnchor;

    modifier isValidFactory(address factory) {
        require(factory == pancakeFactoryV1 || factory == pancakeFactoryV2, "FloozRouter: invalid factory");
        _;
    }

    modifier isValidReferee(address referee) {
        require(msg.sender != referee, "FloozRouter: self referral");
        _;
    }

    constructor(
        address _WETH,
        uint16 _swapFee,
        uint16 _referralRewardRate,
        address _feeReceiver,
        uint256 _balanceThreshold,
        IERC20 _saveYourAssetsToken,
        address _pancakeFactoryV1,
        address _pancakeFactoryV2,
        bytes memory _pancakeInitCodeV1,
        bytes memory _pancakeInitCodeV2,
        IReferralRegistry _referralRegistry
    ) public {
        WETH = _WETH;
        swapFee = _swapFee;
        referralRewardRate = _referralRewardRate;
        feeReceiver = _feeReceiver;
        saveYourAssetsToken = _saveYourAssetsToken;
        balanceThreshold = _balanceThreshold;
        pancakeFactoryV1 = _pancakeFactoryV1;
        pancakeFactoryV2 = _pancakeFactoryV2;
        pancakeInitCodeV1 = _pancakeInitCodeV1;
        pancakeInitCodeV2 = _pancakeInitCodeV2;
        referralsActivated = true;
        referralRegistry = _referralRegistry;
    }

    receive() external payable {}

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        address factory,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? _pairFor(factory, output, path[i + 2]) : _to;
            IPancakePair(_pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactETHForTokens(
        address factory,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external payable whenNotPaused isValidFactory(factory) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(msg.value, referee);
        amounts = _getAmountsOut(factory, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: swapAmount}();
        assert(IWETH(WETH).transfer(_pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(factory, amounts, path, msg.sender);

        if (feeAmount > 0) {
            _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
        }
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address factory,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = PancakeLibrary.sortTokens(input, output);
            IPancakePair pair = IPancakePair(_pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = _getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? _pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFactory(factory) isValidReferee(referee) {
        require(path[path.length - 1] == WETH, "FloozRouter: BNB has to be the last path item");
        referee = _getReferee(referee);
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(factory, path[0], path[1]), amountIn);
        _swapSupportingFeeOnTransferTokens(factory, path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "FloozRouter: slippage setting to low");
        IWETH(WETH).withdraw(amountOut);
        (uint256 amountWithdraw, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amountOut, referee);
        TransferHelper.safeTransferETH(msg.sender, amountWithdraw);

        if (feeAmount > 0) _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    function swapExactTokensForTokens(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFactory(factory) isValidReferee(referee) returns (uint256[] memory amounts) {
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amountIn, referee);
        amounts = _getAmountsOut(factory, swapAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(factory, amounts, path, msg.sender);

        if (feeAmount > 0) _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    function swapExactTokensForETH(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFactory(factory) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        amounts = _getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(factory, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        (uint256 amountOut, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amounts[amounts.length - 1], referee);
        TransferHelper.safeTransferETH(msg.sender, amountOut);

        if (feeAmount > 0) _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    function swapETHForExactTokens(
        address factory,
        uint256 amountOut,
        address[] calldata path,
        address referee
    ) external payable whenNotPaused isValidFactory(factory) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        amounts = _getAmountsIn(factory, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amounts[0], referee);
        require(amounts[0].add(feeAmount).add(referralReward) <= msg.value, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(_pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(factory, amounts, path, msg.sender);

        if (feeAmount > 0) _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);

        // refund dust eth, if any
        if (msg.value > amounts[0].add(feeAmount).add(referralReward))
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0].add(feeAmount).add(referralReward));
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address factory,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFactory(factory) isValidReferee(referee) {
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amountIn, referee);
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(factory, path[0], path[1]), swapAmount);
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(factory, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );

        if (feeAmount > 0) _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    function swapTokensForExactTokens(
        address factory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFactory(factory) isValidReferee(referee) returns (uint256[] memory amounts) {
        referee = _getReferee(referee);
        amounts = _getAmountsIn(factory, amountOut, path);
        (, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amounts[0], referee);
        require(amounts[0].add(feeAmount).add(referralReward) <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(factory, amounts, path, msg.sender);

        if (feeAmount > 0) _withdrawFeesAndRewards(path[0], path[path.length - 1], referee, feeAmount, referralReward);
    }

    function swapTokensForExactETH(
        address factory,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address referee
    ) external whenNotPaused isValidFactory(factory) isValidReferee(referee) returns (uint256[] memory amounts) {
        require(path[path.length - 1] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        amounts = _getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "FloozRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(factory, amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(amounts[amounts.length - 1], referee);

        TransferHelper.safeTransferETH(msg.sender, swapAmount);
        if (feeAmount > 0) _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address factory,
        uint256 amountOutMin,
        address[] calldata path,
        address referee
    ) external payable whenNotPaused isValidFactory(factory) isValidReferee(referee) {
        require(path[0] == WETH, "FloozRouter: INVALID_PATH");
        referee = _getReferee(referee);
        (uint256 swapAmount, uint256 feeAmount, uint256 referralReward) = _calculateFeesAndRewards(msg.value, referee);
        IWETH(WETH).deposit{value: swapAmount}();
        assert(IWETH(WETH).transfer(_pairFor(factory, path[0], path[1]), swapAmount));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(msg.sender);
        _swapSupportingFeeOnTransferTokens(factory, path, msg.sender);
        require(
            IERC20(path[path.length - 1]).balanceOf(msg.sender).sub(balanceBefore) >= amountOutMin,
            "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        if (feeAmount > 0) _withdrawFeesAndRewards(address(0), path[path.length - 1], referee, feeAmount, referralReward);
    }

    function _getReferee(address referee) internal returns (address) {
        address sender = msg.sender;
        if (!referralRegistry.hasUserReferee(sender)) {
            referralRegistry.createReferralAnchor(sender, referee);
        }
        return referralRegistry.getUserReferee(sender);
    }

    function _calculateFeesAndRewards(uint256 amount, address referee)
        internal
        view
        returns (
            uint256 swapAmount,
            uint256 feeAmount,
            uint256 referralReward
        )
    {
        if (userAboveBalanceThreshold(msg.sender)) {
            referralReward = 0;
            feeAmount = 0;
            swapAmount = amount;
        } else {
            uint256 fees = amount.mul(swapFee).div(FEE_DENOMINATOR);
            swapAmount = amount.sub(fees);
            if (referee != address(0) && referralsActivated) {
                uint16 referralRate = customReferralRewardRate[referee] > 0 ? customReferralRewardRate[referee] : referralRewardRate;
                referralReward = fees.mul(referralRate).div(FEE_DENOMINATOR);
                feeAmount = amount.sub(swapAmount).sub(referralReward);
            } else {
                referralReward = 0;
                feeAmount = fees;
            }
        }
    }

    function userAboveBalanceThreshold(address _account) public view returns (bool) {
        return saveYourAssetsToken.balanceOf(_account) >= balanceThreshold;
    }

    function getUserFee(address user) public view returns (uint256) {
        saveYourAssetsToken.balanceOf(user) >= balanceThreshold ? 0 : swapFee;
    }

    function updateSwapFee(uint16 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
        emit SwapFeeUpdated(newSwapFee);
    }

    function updateReferralRewardRate(uint16 newReferralRewardRate) external onlyOwner {
        referralRewardRate = newReferralRewardRate;
        emit ReferralRewardRateUpdated(newReferralRewardRate);
    }

    function updateFeeReceiver(address newFeeReceiver) external onlyOwner {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(newFeeReceiver);
    }

    function updateBalanceThreshold(uint256 newBalanceThreshold) external onlyOwner {
        balanceThreshold = newBalanceThreshold;
        emit BalanceThresholdUpdated(balanceThreshold);
    }

    function updateReferralsActivated(bool newReferralsActivated) external onlyOwner {
        referralsActivated = newReferralsActivated;
        emit ReferralsActivatedUpdated(newReferralsActivated);
    }

    function updateReferralRegistry(address newReferralRegistry) external onlyOwner {
        referralRegistry = IReferralRegistry(newReferralRegistry);
        emit ReferralRegistryUpdated(newReferralRegistry);
    }

    function updateCustomReferralRewardRate(address account, uint16 referralRate) external onlyOwner returns (uint256) {
        require(referralRate <= FEE_DENOMINATOR, "FloozRouter: INVALID_RATE");
        customReferralRewardRate[account] = referralRate;
        emit CustomReferralRewardRateUpdated(account, referralRate);
    }

    function getUserReferee(address user) external view returns (address) {
        return referralRegistry.getUserReferee(user);
    }

    function hasUserReferee(address user) external view returns (bool) {
        return referralRegistry.hasUserReferee(user);
    }

    /**
     * @dev Withdraw BNB that somehow ended up in the contract.
     */
    function withdrawBnb(address payable to, uint256 amount) external onlyOwner {
        to.transfer(amount);
    }

    /**
     * @dev Withdraw any erc20 compliant tokens that
     * somehow ended up in the contract.
     */
    function withdrawErc20Token(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

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

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountOut) {
        require(amountIn > 0, "FloozRouter: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul((9975 - getUserFee(msg.sender)));
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view returns (uint256 amountIn) {
        require(amountOut > 0, "FloozRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "FloozRouter: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(10000);
        uint256 denominator = reserveOut.sub(amountOut).mul(9975 - getUserFee(msg.sender));
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function _getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "FloozRouter: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = _getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
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

    // fetches and sorts the reserves for a pair
    function _getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = PancakeLibrary.sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = PancakeLibrary.sortTokens(tokenA, tokenB);
        bytes memory initcode = factory == pancakeFactoryV1 ? pancakeInitCodeV1 : pancakeInitCodeV2;
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        initcode // init code hash
                    )
                )
            )
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

pragma solidity =0.6.6;

interface IReferralRegistry {
    function getUserReferee(address _user) external view returns (address);

    function hasUserReferee(address _user) external view returns (bool);

    function createReferralAnchor(address _user, address _referee) external;
}

pragma solidity =0.6.6;

//SPDX-License-Identifier: Unlicense

interface IReferrals {
    function registerReferral(
        address _referee,
        address _token,
        uint256 _amount
    ) external payable;
}

pragma solidity >=0.5.0;

//SPDX-License-Identifier: Unlicense

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address _spender, uint256 _amount) external returns (bool);

    function balanceOf(address _account) external view returns (uint256);
}

pragma solidity >=0.5.0;
//SPDX-License-Identifier: Unlicense
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
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
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

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PancakeLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(998);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PancakeLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "PancakeLibrary: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(998);
        amountIn = (numerator / denominator).add(1);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-newer
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

