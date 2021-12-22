// SPDX-License-Identifier: Unlicensed

pragma solidity =0.8.4;

import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {EnumerableSet} from "EnumerableSet.sol";
import "IReinvestor.sol";
import "IPremiumDistributor.sol";

library Errors {
  string public constant ZERO_GROW_K_PERIOD = 'ZERO_GROW_K_PERIOD';
  string public constant NOT_DEPOSIT_OWNER = 'NOT_DEPOSIT_OWNER';
  string public constant DEPOSIT_IS_LOCKED = 'DEPOSIT_IS_LOCKED';
  string public constant INSUFFICIENT_DEPOSIT = 'INSUFFICIENT_DEPOSIT';
  string public constant ZERO_TOTAL_RATING = 'ZERO_TOTAL_RATING';
  string public constant ZERO_ADDRESS = 'ZERO_ADDRESS';
  string public constant SMALL_END_K = 'SMALL_END_K';
  string public constant ZERO_DEPOSIT_AMOUNT = 'ZERO_DEPOSIT_AMOUNT';
  string public constant NOT_FOUND = 'NOT_FOUND';
  string public constant WRONG_INDEX = 'WRONG_INDEX';
  string public constant DATA_INCONSISTENCY = 'DATA_INCONSISTENCY';
  string public constant INSUFFICIENT_SWAP = 'INSUFFICIENT_SWAP';
  string public constant REINVESTOR_NOT_SET = 'REINVESTOR_NOT_SET';
  string public constant PREMIUM_DISTRIBUTOR_NOT_SET = 'PREMIUM_DISTRIBUTOR_NOT_SET';
}


/**
 * @title RankedStaking
 * @notice DOES NOT SUPPORT deflation and inflation tokens.
 * @dev Distribute premium among stakers.
 * @dev The stakers who freeze deposit longer gets higher coefficient.
 */
contract RankedStaking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    event DepositPut (
        address indexed user,
        uint40 lockFor,
        uint256 indexed id,
        uint256 amount
    );

    event DepositWithdrawn (
        address indexed user,
        uint256 indexed id,
        uint256 amount,
        uint256 rest
    );

    event SharePremium(
        address indexed user,
        uint256 amount,
        uint256 premiumPerRatingPoint,
        uint256 totalRating
    );

    event PremiumPaid(
        address indexed user,
        uint256 amount
    );

    event ReinvestorSet(address indexed newAddress);

    event PremiumDistributorSet(address indexed newAddress);

    struct Deposit {
        address user;
        uint40 depositAt;
        uint40 lockFor;
        uint256 amount;
    }

    struct UserAccount {
        uint256 claimedAmount;
        uint256 rating;
        uint256 totalDepositAmount;
    }

    address immutable public stakingToken;
    address immutable public premiumToken;
    IReinvestor public reinvestor;
    IPremiumDistributor public premiumDistributor;
    uint256 internal nextDepositId;
    uint256 public totalRating;
    uint256 public premiumPerRatingPoint;
    uint256 public constant PREMIUM_PER_RATING_POINT_BASE = 10 ** 18;
    uint256 public constant RATE_POINT_BASE = 10 ** 18;
    mapping (uint256 => Deposit) public deposits;
    mapping (address => UserAccount) public accounts;
    mapping (address => EnumerableSet.UintSet) internal userDepositIds;

    uint256 public constant K_BASE = 10 ** 18;
    uint256 constant public START_K = K_BASE;
    uint256 immutable public END_K;
    uint40 immutable public START_K_PERIOD;
    uint40 immutable public GROW_K_PERIOD;


    //    K
    //  ^                        K = END_K, after T >= depositAt + START_K_PERIOD + GROW_K_PERIOD
    //  |                ---------
    //  |               /
    //  |              /
    //  |             /
    //  |            /   K = START_K + (END_K - START_K) * (T - depositAt - START_K_PERIOD) / GROW_K_PERIOD, after T > depositAt + START_K_PERIOD
    //  |           /
    //  |   -------/
    //  |
    //  |    ^
    //  |    K = START_K, T <= depositAt + START_K_PERIOD
    //  |
    //  |-----------------------------------> Time
    function calculateK(uint256 lockFor) public view returns (uint256) {
        if (lockFor <= START_K_PERIOD) {
            return START_K;
        } else if (lockFor < START_K_PERIOD + GROW_K_PERIOD) {
            return START_K + (END_K - START_K) * (lockFor - START_K_PERIOD) / GROW_K_PERIOD;
        } else {
            return END_K;
        }
    }

    function getUserDepositIds(address user) view external returns (uint256[] memory) {
        uint256[] memory depositIds = new uint256[](userDepositIds[user].length());
        for(uint256 i = 0; i < userDepositIds[user].length(); ++i) {
            depositIds[i] = userDepositIds[user].at(i);
        }
        return depositIds;
    }

    function getUserDepositIdAtIndex(address user, uint256 index) view external returns (uint256) {
        return userDepositIds[user].at(index);
    }

    function getUserDepositsLength(address user) view external returns (uint256) {
        return userDepositIds[user].length();
    }

    /**
     * @dev Create a RankedStaking.
     * @param _endK the end value of K
     * @param _startKPeriod the period length when K=START_K
     * @param _growKPeriod the period length when K is growing from START_K to END_K
     * @param _premiumToken the address of token to pay premium
     * @param _stakingToken the address of token to stake
     */
    constructor(
        uint256 _endK,
        uint40 _startKPeriod,
        uint40 _growKPeriod,
        address _premiumToken,
        address _stakingToken
    ) {
        require(_growKPeriod > 0, Errors.ZERO_GROW_K_PERIOD);
        require(_endK >= START_K, Errors.SMALL_END_K);
        require(_premiumToken != address(0), Errors.ZERO_ADDRESS);
        require(_stakingToken != address(0), Errors.ZERO_ADDRESS);
        END_K = _endK;
        START_K_PERIOD = _startKPeriod;
        GROW_K_PERIOD = _growKPeriod;
        premiumToken = _premiumToken;
        stakingToken = _stakingToken;
    }

    function sharePremium(uint256 amount) external {
        require(totalRating > 0, Errors.ZERO_TOTAL_RATING);
        premiumPerRatingPoint += amount * PREMIUM_PER_RATING_POINT_BASE / totalRating;
        emit SharePremium(msg.sender, amount, premiumPerRatingPoint, totalRating);
        IERC20(premiumToken).safeTransferFrom(msg.sender, address(this), amount);
    }

    function distributePremiumAndClaim() external {
        require(address(premiumDistributor) != address(0), Errors.PREMIUM_DISTRIBUTOR_NOT_SET);
        premiumDistributor.distributePremium();
        accounts[msg.sender].claimedAmount = _claimPremium();
    }

    function claimPremium() external {
        accounts[msg.sender].claimedAmount = _claimPremium();
    }

    function _claimPremium() private returns(uint256) {
        UserAccount storage account = accounts[msg.sender];
        uint256 total = account.rating * premiumPerRatingPoint / PREMIUM_PER_RATING_POINT_BASE;
        uint256 _claimedAmount = account.claimedAmount;
        if (total <= _claimedAmount) {
            return _claimedAmount;
        }
        uint256 rest = total - _claimedAmount;
        emit PremiumPaid(msg.sender, rest);
        IERC20(premiumToken).safeTransfer(msg.sender, rest);
        return total;
    }

    function premiumOf(address user) external view returns (uint256){
        UserAccount memory account = accounts[user];
        uint256 total = account.rating * premiumPerRatingPoint / PREMIUM_PER_RATING_POINT_BASE;
        if (total <= account.claimedAmount) {
            return 0;
        }
        uint256 rest = total - account.claimedAmount;
        return rest;
    }

    function putDeposit(uint256 amount, uint40 lockFor) external returns(uint256) {
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        return deposit(msg.sender, amount, lockFor);
    }

    function deposit(address beneficiary, uint256 amount, uint40 lockFor) private returns(uint256) {
        require(amount > 0, Errors.ZERO_DEPOSIT_AMOUNT);
        _claimPremium();
        uint256 depositId = nextDepositId++;
        deposits[depositId] = Deposit({
            user: beneficiary,
            depositAt: uint40(block.timestamp),
            amount: amount,
            lockFor: lockFor
        });
        uint256 deltaRating = amount * calculateK(lockFor) / K_BASE;
        UserAccount storage account = accounts[beneficiary];
        uint256 _rating = account.rating;
        account.claimedAmount = (_rating + deltaRating) * premiumPerRatingPoint / PREMIUM_PER_RATING_POINT_BASE;
        account.rating = _rating + deltaRating;
        account.totalDepositAmount += amount;
        require(userDepositIds[beneficiary].add(depositId), Errors.DATA_INCONSISTENCY);
        totalRating += deltaRating;
        emit DepositPut(beneficiary, lockFor, depositId, amount);
        return depositId;
    }

    function reinvest(uint40 lockFor, uint256 minimalSwapRateScaled) external nonReentrant {
        require(address(reinvestor) != address(0), Errors.REINVESTOR_NOT_SET);
        UserAccount storage account = accounts[msg.sender];
        uint256 total = account.rating * premiumPerRatingPoint / PREMIUM_PER_RATING_POINT_BASE;
        uint256 _claimedAmount = account.claimedAmount;
        if (total <= _claimedAmount) {
            return;
        }
        uint256 rest = total - _claimedAmount;
        account.claimedAmount = total;
        emit PremiumPaid(msg.sender, rest);
        IERC20(premiumToken).approve(address(reinvestor), rest);
        uint256 reinvestAmount = reinvestor.reinvest(rest, minimalSwapRateScaled);
        require(reinvestAmount >= rest * minimalSwapRateScaled / RATE_POINT_BASE, Errors.INSUFFICIENT_SWAP);

        IERC20(stakingToken).safeTransferFrom(address(reinvestor), address(this), reinvestAmount);
        deposit(msg.sender, reinvestAmount, lockFor);
    }

    function withdrawDeposit(uint256 depositId, uint256 amount) external {
        _claimPremium();
        Deposit storage deposit = deposits[depositId];
        if (deposit.amount < amount) {
            revert(Errors.INSUFFICIENT_DEPOSIT);
        }
        // deposit.amount >= amount
        require(deposit.user == msg.sender, Errors.NOT_DEPOSIT_OWNER);
        require(block.timestamp >= deposit.depositAt + deposit.lockFor, Errors.DEPOSIT_IS_LOCKED);
        require(userDepositIds[msg.sender].contains(depositId), Errors.DATA_INCONSISTENCY);
        uint256 deltaRating = amount * calculateK(deposit.lockFor) / K_BASE;
        UserAccount storage account = accounts[msg.sender];
        account.totalDepositAmount -= amount;
        uint256 _rating = account.rating;
        account.claimedAmount = (_rating - deltaRating) * premiumPerRatingPoint / PREMIUM_PER_RATING_POINT_BASE;
        account.rating = (_rating - deltaRating);
        totalRating -= deltaRating;
        if (deposit.amount > amount) {
            deposit.amount -= amount;
            emit DepositWithdrawn(msg.sender, depositId, amount, deposit.amount);
        } else {  // deposit.amount == amount, because of require condition (take care!)
            delete deposits[depositId];  // free up storage slot
            require(userDepositIds[msg.sender].remove(depositId), Errors.DATA_INCONSISTENCY);
            emit DepositWithdrawn(msg.sender, depositId, amount, 0);
        }
        IERC20(stakingToken).safeTransfer(msg.sender, amount);
    }

    function setReinvestor(address newAddress) external onlyOwner {
        reinvestor = IReinvestor(newAddress);
        emit ReinvestorSet(newAddress);
    }

    function setPremiumDistributor(address newAddress) external onlyOwner {
        premiumDistributor = IPremiumDistributor(newAddress);
        emit PremiumDistributorSet(newAddress);
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

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

pragma solidity ^0.8.0;

import "Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface IReinvestor {

    function reinvest(uint256 amount, uint256 minimalSwapRateScaled) external returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.4;

interface IPremiumDistributor {

    function distributePremium() external;

}