// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

import './StratManager.sol';
import '../Interfaces/IPancakeRouter02.sol';
import '../Interfaces/IBoardroom.sol';
import '../util/Statistics.sol';
import '../Interfaces/IBoardroomStats.sol';

contract ChargeLPBoardroomStrategy is StratManager {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Tokens used
    address public wrapped;
    address public dollar;
    address public share;
    address public want;
    address public busd;

    // Fee structure
    uint256 public WITHDRAWAL_MAX = 100000;
    uint256 public WITHDRAW_FEE = 0; //0%  (amount *withdrawalFee/WITHDRAWAL_MAX
    uint256 public MAX_FEE = 1000;
    uint256 public CALL_FEE = 1000; //100% of Platform fee  (CALL_FEE/MAX_FEE * Platform fee = 1%)
    uint256 public STRATEGIST_FEE = 0; //0% of Platform fee  (STRATEGIST_FEE/MAX_FEE * Platform fee = 0%)
    uint256 public FEE_BATCH = 0; //0% of Platform fee  (FEE_BATCH/MAX_FEE * Platform fee = 0%)
    uint256 public PLATFORM_FEE = 10; //1% Platform fee (PLATFORM_FEE / MAX_FEE).  To cover gas cost.

    // Third party contracts
    address boardroom;
    IBoardroomStats boardroomStats;

    // Controllers
    bool public locked;
    bool initiateTimelock = false;

    // Charge addresses
    address public harvester;

    // Routes
    address[] shareToWrappedRoute; // keep this wrapped
    address[] dollarToStableRoute;
    address[] shareToDollarRoute;
    address[] customPath;

    // Controllers
    uint256 depositTime;
    uint256 withdrawTime;
    uint256 withdrawEpoch = 7200; // 2 hours
    uint256 epoch = 172800; // 48 hours

    event StratHarvest(address indexed harvester);

    constructor(
        address harvester_,
        address boardroom_,
        address share_,
        address dollar_,
        address dollarLp_,
        address wrapped_,
        address strategist_,
        address unirouter_,
        address feeRecipient_,
        address busd_,
        IBoardroomStats boardroomStats_
    ) StratManager(strategist_, unirouter_, feeRecipient_) {
        strategist = msg.sender;
        whitelist[msg.sender] = true;
        whitelist[harvester] = true;
        want = dollarLp_;
        harvester = harvester_;
        boardroom = boardroom_;
        share = share_;
        want = share_;
        dollar = dollar_;
        wrapped = wrapped_;
        busd = busd_;
        shareToWrappedRoute = [share, busd, wrapped];
        shareToDollarRoute = [share, busd, dollar];
        dollarToStableRoute = [dollar, busd];
        boardroomStats = boardroomStats_;

        _giveAllowances();
        startUnlockWindow();
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        if (initiateTimelock) {
            IBoardroom(boardroom).claimReward();
            addLiquidity();
            uint256 wantBal = IERC20(want).balanceOf(address(this));
            IBoardroom(boardroom).stake(wantBal);
            depositTime = block.timestamp;
            initiateTimelock = false;
        }
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == vault, '!vault');
        require(!locked, 'Withdrawals locked');

        uint256 wantBal = IERC20(want).balanceOf(address(this));

        if (wantBal > _amount) {
            wantBal = _amount;
        }

        if (tx.origin == owner() || paused()) {
            IERC20(want).safeTransfer(vault, wantBal);
        } else {
            uint256 withdrawalFeeAmount = wantBal.mul(WITHDRAW_FEE).div(
                WITHDRAWAL_MAX
            );
            IERC20(want).safeTransfer(vault, wantBal.sub(withdrawalFeeAmount));
        }
    }

    function userActivateTimelock() external {
        checkEpoch();
        deposit();
    }

    // compounds earnings and charges performance fee
    function harvest() external whenNotPaused onlyWhitelisted {
        chargeFees();
        addLiquidity();
        checkEpoch();
        deposit();

        emit StratHarvest(msg.sender);
    }

    // checks to ensure that the correct time has elapsed and withdrawals are possible
    function checkEpoch() internal returns (bool) {
        if (
            IBoardroom(boardroom).canWithdraw(address(this)) &&
            block.timestamp > depositTime.add(epoch) &&
            locked
        ) {
            startUnlockWindow();
        } else if (!locked) {
            lockStart();
        }
    }

    function startUnlockWindow() internal {
        // withdraw all share from the boardroom
        if (IBoardroom(boardroom).balanceOf(address(this)) > 0) {
            IBoardroom(boardroom).withdraw(
                IBoardroom(boardroom).balanceOf(address(this))
            );
        }
        addLiquidity();
        // initiate the withdrawal window
        withdrawTime = block.timestamp;
        // unlock controller
        locked = false;
    }

    function lockStart() internal {
        if (block.timestamp > withdrawTime.add(withdrawEpoch) && !locked) {
            // start timelock
            locked = true;
            initiateTimelock = true;
        }
    }

    // performance fees
    function chargeFees() internal {
        uint256 toWrapped = IERC20(share)
        .balanceOf(address(this))
        .mul(PLATFORM_FEE)
        .div(MAX_FEE);
        if (toWrapped > 0) {
            IPancakeRouter02(unirouter)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                toWrapped,
                0,
                shareToWrappedRoute,
                address(this),
                block.timestamp
            );
        }

        uint256 wrappedBal = IERC20(wrapped).balanceOf(address(this));

        uint256 callFeeAmount = wrappedBal.mul(CALL_FEE).div(MAX_FEE);
        IERC20(wrapped).safeTransfer(msg.sender, callFeeAmount);

        uint256 chargeFeeAmount = wrappedBal.mul(FEE_BATCH).div(MAX_FEE);
        IERC20(wrapped).safeTransfer(chargeFeeRecipient, chargeFeeAmount);

        uint256 strategistFee = wrappedBal.mul(STRATEGIST_FEE).div(MAX_FEE);
        IERC20(wrapped).safeTransfer(strategist, strategistFee);
    }

    // Adds liquidity to AMM and gets more LP tokens.
    function addLiquidity() internal {
        uint256 shareBal = IERC20(share).balanceOf(address(this));
        if (shareBal > 0) {
            IPancakeRouter02(unirouter).swapExactTokensForTokens(
                shareBal,
                0,
                shareToDollarRoute,
                address(this),
                block.timestamp
            );
        }

        uint256 dollarBalance = IERC20(dollar).balanceOf(address(this));
        if (dollarBalance > 0) {
            uint256 dollarHalf = dollarBalance.div(2);
            IPancakeRouter02(unirouter)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                dollarHalf,
                0,
                dollarToStableRoute,
                address(this),
                block.timestamp
            );


            uint256 busdBal = IERC20(busd).balanceOf(address(this));
            uint256 dollarBal = IERC20(dollar).balanceOf(address(this));
            IPancakeRouter02(unirouter).addLiquidity(
                busd,
                dollar,
                busdBal,
                dollarBal,
                1,
                1,
                address(this),
                block.timestamp
            );
        }
    }

    // calculate the total underlaying 'want' held by the strat.
    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    // it calculates how much 'want' this contract holds.
    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    // it calculates how much 'want' the strategy has working in the farm.
    function balanceOfPool() public view returns (uint256) {
        uint256 _amount = IBoardroom(boardroom).balanceOf(address(this));
        return _amount;
    }

    function unlockWindowRemaining() public view returns (uint256) {
        uint256 timeLeft = (withdrawTime + withdrawEpoch) - block.timestamp;
        if (timeLeft > withdrawEpoch) {
            timeLeft = 0;
        }
        return timeLeft;
    }

    function lockWindowRemaining() public view returns (uint256) {
        uint256 timeLeft = (depositTime + epoch) - block.timestamp;
        if (timeLeft > epoch) {
            timeLeft = 0;
        }
        return timeLeft;
    }

    // called as part of strat migration. Sends all the available funds back to the vault.
    function retireStrat() external {
        require(!locked);
        require(msg.sender == vault, '!vault');
        uint256 wantBal = IERC20(want).balanceOf(address(this));
        IERC20(want).transfer(vault, wantBal);
    }

    // pauses deposits and withdraws all funds from third party systems.
    function panic() public {
        require(msg.sender == strategist, '!auth');
        pause();
        IBoardroom(boardroom).withdraw(balanceOfPool());
    }

    function pause() public {
        require(msg.sender == strategist, '!auth');
        _pause();
        _removeAllowances();
    }

    function unpause() external {
        require(msg.sender == strategist, '!auth');
        _unpause();
        _giveAllowances();
        deposit();
    }

    function _giveAllowances() internal {
        IERC20(want).safeApprove(boardroom, type(uint256).max);
        IERC20(dollar).safeApprove(unirouter, type(uint256).max);
        IERC20(share).safeApprove(unirouter, type(uint256).max);
        IERC20(busd).safeApprove(unirouter, type(uint256).max);
    }

    function _removeAllowances() internal {
        IERC20(want).safeApprove(boardroom, 0);
        IERC20(dollar).safeApprove(unirouter, 0);
        IERC20(share).safeApprove(unirouter, 0);
        IERC20(busd).safeApprove(unirouter, 0);

    }

    // This function exists incase tokens that do not match the want of this strategy accrue.  For example: an amount of
    // tokens sent to this address in the form of an airdrop of a different token type.  This will allow us to convert
    // this token to the want-token of the strategy, allowing the amount to be paid out to stakers in the matching vault.
    function makeCustomTxn(
        address _fromToken,
        address _toToken,
        address _unirouter,
        uint256 _amount
    ) external {
        require(msg.sender == strategist, '!auth for custom txn');

        approveTxnIfNeeded(_fromToken, _unirouter, _amount);

        customPath = [_fromToken, _toToken];

        IPancakeRouter02(_unirouter).swapExactTokensForTokens(
            _amount,
            0,
            customPath,
            address(this),
            block.timestamp.add(600)
        );
    }

    function approveTxnIfNeeded(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _spender) < _amount) {
            IERC20(_token).safeApprove(_spender, uint256(0));
            IERC20(_token).safeApprove(_spender, type(uint256).max);
        }
    }

    function setFees(
        uint256 newCallFee,
        uint256 newStratFee,
        uint256 newWithdrawFee,
        uint256 newFeeBatchAmount
    ) external {
        require(msg.sender == strategist, '!auth');
        require(newWithdrawFee < 5000, 'withdrawal fee too high');
        CALL_FEE = newCallFee;
        STRATEGIST_FEE = newStratFee;
        WITHDRAW_FEE = newWithdrawFee;
        FEE_BATCH = newFeeBatchAmount;
    }

    /*
     * @notice View function to see APR on frontend.
	 * @return APR for strategy
	 */
    function APR() external view returns (uint256) {
        return IBoardroomStats(boardroomStats).APR(IBoardroom02(boardroom));
    }

    /*
     * @notice View function to see TVL on frontend.
	 * @return TVL for strategy
	 */
    function TVL() public view returns (uint256) {
        uint256 depositAmount = IBoardroom(boardroom).balanceOf(address(this));
        return
        depositAmount
        .mul(
            IBoardroomStats(boardroomStats).stakedTokenPrice(
                IBoardroom02(boardroom)
            )
        )
        .div(1e18);
    }

    function stakedTokenPrice() external view returns (uint256) {
        return
        IBoardroomStats(boardroomStats).stakedTokenPrice(
            IBoardroom02(boardroom)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../Interfaces/IPancakeRouter02.sol';
import './PriceCalculator.sol';

abstract contract Statistics is PriceCalculator {
	function APR() external view virtual returns (uint256);

	function TVL() external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../Interfaces/IPancakeRouter02.sol';

abstract contract PriceCalculator {
	function _getTokenPrice(
		IPancakeRouter02 router,
		address[] memory tokenToStable
	) internal view virtual returns (uint256) {
		//special case where token is stable
		if (tokenToStable.length == 1) {
			return 1e18;
		}

		uint256[] memory amounts = router.getAmountsOut(1e9, tokenToStable);
		return amounts[amounts.length - 1] * 1e9;
	}

	function _getLPTokenPrice(
		IPancakeRouter02 router,
		address[] memory token0ToStable,
		address[] memory token1ToStable,
		IERC20 lpToken
	) internal view virtual returns (uint256) {
		uint256 token0InPool = IERC20(token0ToStable[0]).balanceOf(
			address(lpToken)
		);
		uint256 token1InPool = IERC20(token1ToStable[0]).balanceOf(
			address(lpToken)
		);

		uint256 totalPriceOfPool = token0InPool *
			(_getTokenPrice(router, token0ToStable)) +
			token1InPool *
			(_getTokenPrice(router, token1ToStable));

		return totalPriceOfPool / (lpToken.totalSupply());
	}
}

pragma solidity 0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract StratManager is Ownable, Pausable {
	address public strategist;
	address public unirouter;
	address public vault;
	address public chargeFeeRecipient;
	mapping(address => bool) public whitelist;

	constructor(
		address strategist_,
		address unirouter_,
		address chargeFeeRecipient_
	) public {
		strategist = strategist_;
		unirouter = unirouter_;
		chargeFeeRecipient = chargeFeeRecipient_;
	}

	function addOrRemoveFromWhitelist(address add, bool isAdd) public {
		require(msg.sender == strategist, '!auth');
		whitelist[add] = isAdd;
	}

	modifier onlyWhitelisted() {
		require(whitelist[msg.sender] == true, 'You are not whitelisted');
		_;
	}

	function setStrategist(address _strategist) external {
		require(msg.sender == strategist, '!strategist');
		strategist = _strategist;
	}

	function setUnirouter(address _unirouter) external onlyOwner {
		unirouter = _unirouter;
	}

	function setVault(address _vault) external onlyOwner {
		vault = _vault;
	}

	/**
	 * @dev Function to synchronize balances before new user deposit.
	 * Can be overridden in the strategy.
	 */
	function beforeDeposit() external virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import './IPancakeRouter01.sol';

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

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

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

pragma solidity 0.8.4;

import './IBoardroom02.sol';

interface IBoardroomStats {
	function APR(IBoardroom02 _boardroom) external view returns (uint256);

	function TVL(IBoardroom02 _boardroom) external view returns (uint256);

	function stakedTokenPrice(IBoardroom02 _boardroom)
		external
		view
		returns (uint256);
}

pragma solidity 0.8.4;

import './IBoardroom.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IBoardroom02 is IBoardroom {
	struct BoardSnapshot {
		uint256 time;
		uint256 cashRewardReceived;
		uint256 cashRewardPerShare;
		uint256 shareRewardReceived;
		uint256 shareRewardPerShare;
	}

	function wantToken() external view returns (IERC20);

	function cash() external view returns (IERC20);

	function share() external view returns (IERC20);

	function totalSupply() external view returns (uint256);

	function latestSnapshotIndex() external view returns (uint256);

	function boardHistory(uint256 _index)
		external
		view
		returns (BoardSnapshot memory);
}

pragma solidity 0.8.4;

interface IBoardroom {
	function balanceOf(address _director) external view returns (uint256);

	function earned(address _director) external view returns (uint256, uint256);

	function canWithdraw(address _director) external view returns (bool);

	function canClaimReward(address _director) external view returns (bool);

	function setOperator(address _operator) external;

	function setLockUp(
		uint256 _withdrawLockupEpochs,
		uint256 _rewardLockupEpochs
	) external;

	function stake(uint256 _amount) external;

	function withdraw(uint256 _amount) external;

	function exit() external;

	function claimReward() external;

	function allocateSeigniorage(uint256 _cashReward, uint256 _shareReward)
		external;

	function governanceRecoverUnsupported(
		address _token,
		uint256 _amount,
		address _to
	) external;

	function APR() external pure returns (uint256);
}