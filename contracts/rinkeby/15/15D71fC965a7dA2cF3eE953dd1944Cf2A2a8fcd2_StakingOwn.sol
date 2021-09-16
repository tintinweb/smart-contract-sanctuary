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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBTCMT is IERC20 {

    event FarmStatusChanged (address indexed farm, bool isFarmNow);

    event TransferLocked (address indexed from, address indexed to, uint256 amount);

    event ApprovalLocked (address indexed owner, address indexed spender, uint256 amount);

    function balanceOfSum (address account) external view returns (uint256);

    function transferFarm (address to, uint256 amountLocked, uint256 amountUnlocked, uint256[] calldata farmIndexes) external returns (uint256[] memory);

    function transferFromFarm (address from, uint256 amountLocked, uint256 amountUnlocked) external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IBTCMT.sol";

contract StakingOwn is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IBTCMT public stoken;
    IERC20 public rewardToken;
    uint256 public farmStartedTime;
    uint256 public miniStakePeriodInSeconds;
    uint256 public nowTotalMined;
    uint256 public allTimeTotalMined;
    uint256 public nowTotalStakers;
    uint256 public allTimeTotalStakers;
    uint256 public totalRewardInPool;
    uint256 public totalWithdrawed;

    uint256 private _yesterdayShairs;
    uint256 private _todayShairs;

    mapping(address => StakeRecord) public userStakes;
    mapping(uint256 => DepositRecord) public rewardDeposits;
    mapping(uint256 => bool) private _changerVarsShairs;
    mapping(uint256 => bool) private _rewardDepositIndexies;
    mapping(address => bool) private _isUserStaker;
    mapping(address => mapping(uint256 => uint256)) public _stakesDays;
    mapping(address => mapping(uint256 => Unstake)) public _unstakesDays;

    struct StakeRecord {
        uint256 day;
        uint256 totalAmount;
        uint256 lockedAmount;
        uint256 unlockedAmount;
        uint256 previousAmount;
        uint256 reservedReward;
        uint256[] array;
        uint256 claimedDay;
    }

    struct DepositRecord {
        uint256 amountOfReward;
        uint256 amountOfShairsNow;
    }

    struct Unstake {
        uint256 amount;
        bool before;
    }

    modifier onlyWhenOpen {
        require(block.timestamp >= farmStartedTime, "Contract is not open yet");
        _;
    }

    event StakeTokenIncome(
        address who,
        uint256 day,
        uint256 amountLocked,
        uint256 amountUnlocked,
        uint256 totalAmount
    );
    event StakeTokenOutcome(
        address who,
        uint256 day,
        uint256 amountLocked,
        uint256 amountUnlocked,
        uint256 totalAmount
    );
    event RewardDeposit(
        address who,
        uint256 day,
        uint256 amount,
        uint256 totalRewardOnContract
    );
    event RewardWithdrawn(
        address who,
        uint256 day,
        uint256 amount,
        uint256 totalRewardOnContract
    );

    constructor(
        IBTCMT _SToken,
        IERC20 _rewardToken,
        uint256 miniStakePeriod,
        uint256 startTime
    ) {
        stoken = _SToken;
        rewardToken = _rewardToken;
        require(miniStakePeriod > 0, "mining period should >0");
        miniStakePeriodInSeconds = miniStakePeriod;
        farmStartedTime = startTime;
        _yesterdayShairs = 0;
        _todayShairs = 0;
    }

    function rewardTokenDonation(uint256 amount)
        external
        onlyOwner
        onlyWhenOpen
        nonReentrant
    {
        address sender = _msgSender();
        uint256 today = _currentDay();
        require(amount > 0, "Amount should be more then zero");
        require(
            !_rewardDepositIndexies[today],
            "Deposit has already done today"
        );
        _updateShairsVars();
        rewardToken.safeTransferFrom(sender, address(this), amount);
        totalRewardInPool = totalRewardInPool + amount;
        _rewardDepositIndexies[today] = true;
        DepositRecord memory currentDeposit =
            DepositRecord(amount, _yesterdayShairs);
        rewardDeposits[today] = currentDeposit;
        emit RewardDeposit(sender, today, amount, totalRewardInPool);
    }

    function withdrawRewardAll() external onlyWhenOpen nonReentrant {
        address sender = _msgSender();
        _withdrawReward(sender, 0);
    }

    function withdrawRewardPartially(uint256 amount)
        external
        onlyWhenOpen
        nonReentrant
    {
        address sender = _msgSender();
        _withdrawReward(sender, amount);
    }

    function stakeStart(uint256 amountUnlocked, uint256 amountLocked)
        external
        onlyWhenOpen
        nonReentrant
    {
        address sender = _msgSender();
        uint256 today = _currentDay();
        uint256 amount = amountUnlocked + amountLocked;
        require(amount > 0, "Amount should be more then zero");
        require(
            amount <= stoken.balanceOfSum(sender),
            "You have not enough tokens for staking"
        );
        uint256[] memory arr;
        arr = stoken.transferFromFarm(sender, amountLocked, amountUnlocked);
        if (_isUserStaker[sender]) {
            uint256 day = _reserveReward(sender);
            if (day == today) {
                userStakes[sender].previousAmount = 0;
            } else {
                userStakes[sender].previousAmount =
                    userStakes[sender].previousAmount +
                    userStakes[sender].totalAmount;
            }
            userStakes[sender].totalAmount =
                userStakes[sender].totalAmount +
                amount;
            userStakes[sender].unlockedAmount =
                userStakes[sender].unlockedAmount +
                amountUnlocked;
            userStakes[sender].lockedAmount =
                userStakes[sender].lockedAmount +
                amountLocked;
            for (uint256 i = 0; i < arr.length; i++) {
                userStakes[sender].array.push(arr[i]);
            }
        } else {
            StakeRecord memory stake =
                StakeRecord(
                    today,
                    amount,
                    amountLocked,
                    amountUnlocked,
                    0,
                    0,
                    arr,
                    today
                );
            userStakes[sender] = stake;
            _isUserStaker[sender] = true;
            nowTotalStakers++;
            allTimeTotalStakers++;
        }
        _updateShairsVars();
        _stakesDays[sender][today] = _stakesDays[sender][today] + amount;
        _todayShairs = _todayShairs + amount;
        nowTotalMined = nowTotalMined + amount;
        allTimeTotalMined = allTimeTotalMined + amount;

        emit StakeTokenIncome(
            sender,
            today,
            amountLocked,
            amountUnlocked,
            amount
        );
    }

    function stakeEndPartially(uint256 lockedAmount, uint256 unlockedAmount)
        external
        onlyWhenOpen
        nonReentrant
    {
        address sender = _msgSender();
        _updateShairsVars();
        require(_isUserStaker[sender], "You have no any stakes");
        uint256 today = _currentDay();
        uint256[] memory returnArray = userStakes[sender].array;
        uint256 locked = userStakes[sender].lockedAmount;
        uint256 unlocked = userStakes[sender].unlockedAmount;
        uint256 total = userStakes[sender].totalAmount;
        uint256 totalAmount = lockedAmount + unlockedAmount;
        require(totalAmount != 0, "Total amount couldn't be zero");
        uint256 sharesToday = _stakesDays[sender][today];
        require(lockedAmount <= locked, "Not enough locked tokens");
        require(unlockedAmount <= unlocked, "Not enough unlocked tokens");
        if (userStakes[sender].day < today) {
            _reserveReward(sender);
        }
        returnArray = stoken.transferFarm(
            sender,
            lockedAmount,
            unlockedAmount,
            returnArray
        );
        nowTotalMined = nowTotalMined - totalAmount;
        if (totalAmount == (locked + unlocked)) {
            --nowTotalStakers;
            _isUserStaker[sender] = false;
            delete userStakes[sender];
        } else {
            userStakes[sender].totalAmount = total - totalAmount;
            userStakes[sender].lockedAmount = locked - lockedAmount;
            userStakes[sender].unlockedAmount = unlocked - unlockedAmount;
            userStakes[sender].array = returnArray;
            userStakes[sender].previousAmount = 0;
        }
        if (sharesToday != 0) {
            if (sharesToday >= totalAmount) {
                _todayShairs = _todayShairs - totalAmount;
            } else {
                _todayShairs = _todayShairs - sharesToday;
                _yesterdayShairs =
                    _yesterdayShairs -
                    (totalAmount - sharesToday);
            }
        } else {
            _yesterdayShairs = _yesterdayShairs - totalAmount;
        }
        _unstakesDays[sender][today].amount += totalAmount;
        if (_rewardDepositIndexies[today]) {
            _unstakesDays[sender][today].before = false;
        }
        emit StakeTokenOutcome(
            sender,
            today,
            lockedAmount,
            unlockedAmount,
            totalAmount
        );
    }

    function stakeEnd() external onlyWhenOpen nonReentrant {
        address sender = _msgSender();
        _updateShairsVars();
        require(_isUserStaker[sender], "You have no any stakes");
        uint256 today = _currentDay();
        uint256[] memory returnArray = userStakes[sender].array;
        uint256 locked = userStakes[sender].lockedAmount;
        uint256 unlocked = userStakes[sender].unlockedAmount;
        uint256 total = locked + unlocked;
        uint256 sharesToday = _stakesDays[sender][today];
        if (userStakes[sender].day < today) {
            _withdrawReward(sender, 0);
        }
        stoken.transferFarm(sender, locked, unlocked, returnArray);
        nowTotalMined = nowTotalMined - total;
        --nowTotalStakers;
        _isUserStaker[sender] = false;
        delete userStakes[sender];
        if (sharesToday != 0) {
            _todayShairs = _todayShairs - sharesToday;
        }
        _yesterdayShairs = _yesterdayShairs - (total - sharesToday);
        emit StakeTokenOutcome(sender, today, locked, unlocked, total);
    }

    function currentDay() external view onlyWhenOpen returns (uint256) {
        return _currentDay();
    }

    function getCurrentUserReward(address user)
        external
        view
        onlyWhenOpen
        returns (uint256)
    {
        uint256 amount = userStakes[user].reservedReward;
        (uint256 outputAmount, ) = _calculationReward(user);
        return amount + outputAmount;
    }

    function getTodayReward() external view returns(uint256){
        uint256 today = _currentDay();
        DepositRecord memory rew = rewardDeposits[today];
        return rew.amountOfReward;
    }

    function calculationRewardTable(
        address user,
        uint256 startDay,
        uint256 endDay
    ) external view onlyWhenOpen returns (uint256[] memory arr) {
        require(user != address(0), "Got zero address");
        require(userStakes[user].day <= startDay, "Wrong start day");
        require(endDay <= _currentDay(), "Wrong end day");
        if (!_isUserStaker[user]) {
            arr = new uint256[](0);
            return arr;
        }

        arr = new uint256[](endDay - startDay + 1);
        uint256 lengthArr = 0;
        uint256 amount = 0;
        uint256 currentDayDeposit = 0;
        uint256 currentDayShares = 0;
        uint256 totalStaked = _stakesDays[user][startDay];
        if (startDay == userStakes[user].day) {
            arr[0] = 0;
            lengthArr = 1;
            ++startDay;
        }
        for (uint256 i = startDay; i <= endDay; i++) {
            if (
                _unstakesDays[user][i].amount != 0 &&
                !_unstakesDays[user][i].before
            ) {
                totalStaked -= _unstakesDays[user][i].amount;
            }
            if (_rewardDepositIndexies[i]) {
                currentDayDeposit = rewardDeposits[i].amountOfReward;
                currentDayShares = rewardDeposits[i].amountOfShairsNow;
                amount = (totalStaked * currentDayDeposit) / currentDayShares;
                arr[lengthArr] = amount;
            } else {
                arr[lengthArr] = 0;
            }
            if (_stakesDays[user][i] != 0) {
                totalStaked += _stakesDays[user][i];
            }
            if (
                _unstakesDays[user][i].amount != 0 &&
                _unstakesDays[user][i].before
            ) {
                totalStaked -= _unstakesDays[user][i].amount;
            }
            lengthArr++;
        }
        return arr;
    }

    function _calculationReward(address user)
        private
        view
        returns (uint256, uint256)
    {
        require(user != address(0), "Got zero address");
        if (!_isUserStaker[user]) {
            return (0, 0);
        } else {
            uint256 additional;
            uint256 amount;
            uint256 currentDayDeposit;
            uint256 currentDayShares;
            uint256 startDay = userStakes[user].claimedDay + 1;
            uint256 today = _currentDay();
            if (startDay > today)
                return (0, today);
            uint256 endDay = ((today - startDay) < (5555 * miniStakePeriodInSeconds)) ? today : (startDay + (5555 * miniStakePeriodInSeconds));
            //uint256 endDay = _currentDay();
            uint256 prevAmount = userStakes[user].previousAmount;
            uint256 totalStaked = userStakes[user].totalAmount;
            if (prevAmount != 0 && _rewardDepositIndexies[startDay]) {
                currentDayDeposit = rewardDeposits[startDay].amountOfReward;
                currentDayShares = rewardDeposits[startDay].amountOfShairsNow;
                additional =
                    (prevAmount * currentDayDeposit) /
                    currentDayShares;
                amount = amount + additional;
                for (uint256 ii = startDay + 1; ii <= endDay; ii++) {
                    if (_rewardDepositIndexies[ii]) {
                        currentDayDeposit = rewardDeposits[ii].amountOfReward;
                        currentDayShares = rewardDeposits[ii].amountOfShairsNow;
                        additional =
                            (totalStaked * currentDayDeposit) /
                            currentDayShares;
                        amount = amount + additional;
                    } else {
                        continue;
                    }
                }
            } else {
                for (uint256 ii = startDay; ii <= endDay; ii++) {
                    if (_rewardDepositIndexies[ii]) {
                        currentDayDeposit = rewardDeposits[ii].amountOfReward;
                        currentDayShares = rewardDeposits[ii].amountOfShairsNow;
                        additional =
                            (totalStaked * currentDayDeposit) /
                            currentDayShares;
                        amount = amount + additional;
                    } else {
                        continue;
                    }
                }
            }
            uint256 day;
            if (_rewardDepositIndexies[endDay]) {
                day = endDay;
            } else {
                day = endDay - 1;
            }
            return (amount, day);
        }
    }

    function _reserveReward(address user) private returns (uint256) {
        require(user != address(0), "Got zero address");
        require(_isUserStaker[user], "You have no any stakes");
        (uint256 amount, uint256 claimedDay) = _calculationReward(user);
        if (userStakes[user].previousAmount != 0) {
            userStakes[user].previousAmount = 0;
        }
        if (amount != 0) {
            userStakes[user].reservedReward += amount;
        }
        userStakes[user].claimedDay = claimedDay;
        return claimedDay;
    }

    function _withdrawReward(address user, uint256 inputAmount) private {
        require(user != address(0), "Got zero address");
        require(_isUserStaker[user], "You have no any stakes");
        _reserveReward(user);
        uint256 resRew = userStakes[user].reservedReward;
        if (inputAmount != 0) {
            require(
                inputAmount <= resRew,
                "You have not earned so much tokens"
            );
            resRew = inputAmount;
        }
        if(resRew > 0){
            rewardToken.safeTransfer(user, resRew);
        }
        userStakes[user].reservedReward -= resRew;
        totalRewardInPool -= resRew;
        totalWithdrawed += resRew;
        emit RewardWithdrawn(user, _currentDay(), resRew, totalRewardInPool);
    }

    function _currentDay() private view returns (uint256) {
        return (block.timestamp - farmStartedTime) / miniStakePeriodInSeconds;
    }

    function _updateShairsVars() private {
        uint256 today = _currentDay();
        if (!_changerVarsShairs[today]) {
            _changerVarsShairs[today] = true;
            _yesterdayShairs = _yesterdayShairs + _todayShairs;
            _todayShairs = 0;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}