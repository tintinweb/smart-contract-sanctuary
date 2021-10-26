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

pragma solidity =0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Claimer is Ownable {
    using SafeERC20 for IERC20;

    // Prevents stupid mistakes in provided timestamps
    uint256 private constant UNLOCK_TIME_THRESHOLD = 1618877169;
    string public id;

    struct Claim {
        uint256 unlockTime; // unix time
        uint256 percent; // three decimals: 1.783% = 1783
    }

    Claim[] public claims;

    bool public isPaused = false;
    uint256 public totalTokens;
    mapping(address => uint256) public allocation;
    mapping(address => uint256) public claimedTotal;
    mapping(address => mapping(uint256 => uint256)) public userClaimedPerClaim;
    // Marks the indexes of claims already claimed by all participants, usually when it was airdropped
    uint256[] public alreadyDistributedClaims;
    uint256 private manuallyClaimedTotal;

    IERC20 public token;

    event Claimed(
        address indexed account,
        uint256 amount,
        uint256 percent,
        uint256 claimIdx
    );
    event DuplicateAllocationSkipped(
        address indexed account,
        uint256 failedAllocation,
        uint256 existingAllocation
    );
    event ClaimReleased(uint256 percent, uint256 newTime, uint256 claimIdx);
    event ClaimTimeChanged(uint256 percent, uint256 newTime, uint256 claimIdx);
    event ClaimingPaused(bool status);

    constructor(
        string memory _id,
        address _token,
        uint256[] memory times,
        uint256[] memory percents
    ) {
        token = IERC20(_token);
        id = _id;

        uint256 totalPercent;
        for (uint256 i = 0; i < times.length; i++) {
            require(percents[i] > 0, "Claimer: 0% is not allowed");
            claims.push(Claim(times[i], percents[i]));
            totalPercent += percents[i];
        }
        require(
            totalPercent == 100000,
            "Claimer: Sum of all claimed must be 100%"
        );
    }

    function setToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function setAlreadyDistributedClaims(uint256[] calldata claimedIdx)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < claimedIdx.length; i++) {
            require(claimedIdx[i] < claims.length, "Claimer: Index out of bounds");
        }
        alreadyDistributedClaims = claimedIdx;
    }

    function getTotalRemainingAmount() external view returns (uint256) {
        return totalTokens - getTotalClaimed();
    }

    function getTotalClaimed() internal view returns (uint256) {
        return manuallyClaimedTotal + getAlreadyDistributedAmount(totalTokens);
    }

    function getClaims(address account)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            uint256[] memory
        )
    {
        uint256 len = claims.length;
        uint256[] memory times = new uint256[](len);
        uint256[] memory percents = new uint256[](len);
        uint256[] memory amount = new uint256[](len);
        bool[] memory _isClaimable = new bool[](len);
        uint256[] memory claimedAmount = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            times[i] = claims[i].unlockTime;
            percents[i] = claims[i].percent;
            amount[i] = getClaimAmount(allocation[account], i);
            _isClaimable[i] = isClaimable(account, i);
            claimedAmount[i] = getAccountClaimed(account, i);
        }

        return (times, percents, amount, _isClaimable, claimedAmount);
    }

    function getTotalAccountClaimable(address account)
        external
        view
        returns (uint256)
    {
        uint256 totalClaimable;
        for (uint256 i = 0; i < claims.length; i++) {
            if (isClaimable(account, i)) {
                totalClaimable += getClaimAmount(allocation[account], i);
            }
        }

        return totalClaimable;
    }

    function getTotalAccountClaimed(address account)
        internal
        view
        returns (uint256)
    {
        return
            claimedTotal[account] +
            getAlreadyDistributedAmount(allocation[account]);
    }

    function getAccountClaimed(address account, uint256 claimIdx)
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < alreadyDistributedClaims.length; i++) {
            if (alreadyDistributedClaims[i] == claimIdx) {
                return
                    getClaimAmount(
                        allocation[account],
                        alreadyDistributedClaims[i]
                    );
            }
        }

        return userClaimedPerClaim[account][claimIdx];
    }

    function getAlreadyDistributedAmount(uint256 total)
        internal
        view
        returns (uint256)
    {
        uint256 amount;

        for (uint256 i = 0; i < alreadyDistributedClaims.length; i++) {
            amount += getClaimAmount(total, alreadyDistributedClaims[i]);
        }

        return amount;
    }

    function claim(address account, uint256 idx) external {
        require(idx < claims.length, "Claimer: Index out of bounds");
        require(
            allocation[account] > 0,
            "Claimer: Account doesn't have allocation"
        );
        require(!isPaused, "Claimer: Claiming paused");

        uint256 claimAmount = claimInternal(account, idx);
        emit Claimed(account, claimAmount, claims[idx].percent, idx);
    }

    function claimAll(address account) external {
        require(
            allocation[account] > 0,
            "Claimer: Account doesn't have allocation"
        );
        require(!isPaused, "Claimer: Claiming paused");

        for (uint256 idx = 0; idx < claims.length; idx++) {
            if (isClaimable(account, idx)) {
                claimInternal(account, idx);
            }
        }
    }

    function claimInternal(address account, uint256 idx)
        internal
        returns (uint256)
    {
        require(
            isClaimable(account, idx),
            "Claimer: Not claimable or already claimed"
        );

        uint256 claimAmount = getClaimAmount(allocation[account], idx);
        require(claimAmount > 0, "Claimer: Amount is zero");

        manuallyClaimedTotal += claimAmount;
        claimedTotal[account] += claimAmount;
        userClaimedPerClaim[account][idx] = claimAmount;

        token.safeTransfer(account, claimAmount);

        return claimAmount;
    }

    function setClaimTime(uint256 claimIdx, uint256 newUnlockTime)
        external
        onlyOwner
    {
        require(claimIdx < claims.length, "Claimer: Index out of bounds");
        Claim storage _claim = claims[claimIdx];

        _claim.unlockTime = newUnlockTime;
        emit ClaimTimeChanged(_claim.percent, _claim.unlockTime, claimIdx);
    }

    function releaseClaim(uint256 claimIdx) external onlyOwner {
        require(claimIdx < claims.length, "Claimer: Index out of bounds");
        Claim storage _claim = claims[claimIdx];

        require(
            _claim.unlockTime > block.timestamp,
            "Claimer: Claim already released"
        );
        _claim.unlockTime = block.timestamp;
        emit ClaimReleased(_claim.percent, _claim.unlockTime, claimIdx);
    }

    function isClaimable(address account, uint256 claimIdx)
        internal
        view
        returns (bool)
    {
        // The claim is already claimed by the user
        if (isClaimed(account, claimIdx)) {
            return false;
        }

        uint256 unlockTime = claims[claimIdx].unlockTime;
        // A claim without a specified time is TBC and cannot be claimed
        if (unlockTime == 0 || unlockTime < UNLOCK_TIME_THRESHOLD) {
            return false;
        }

        return unlockTime < block.timestamp;
    }

    function isClaimed(address account, uint256 claimIdx)
        internal
        view
        returns (bool)
    {
        return
            userClaimedPerClaim[account][claimIdx] > 0 ||
            isAlreadyDistributed(claimIdx);
    }

    function isAlreadyDistributed(uint256 claimIdx)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < alreadyDistributedClaims.length; i++) {
            if (alreadyDistributedClaims[i] == claimIdx) {
                return true;
            }
        }

        return false;
    }

    function getClaimAmount(uint256 total, uint256 claimIdx)
        internal
        view
        returns (uint256)
    {
        return (total * claims[claimIdx].percent) / 100000;
    }

    function pauseClaiming(bool status) external onlyOwner {
        isPaused = status;
        emit ClaimingPaused(status);
    }

    function setAllocation(address account, uint256 newTotal)
        external
        onlyOwner
    {
        if (newTotal > allocation[account]) {
            totalTokens += newTotal - allocation[account];
        } else {
            totalTokens -= allocation[account] - newTotal;
        }
        allocation[account] = newTotal;
    }

    function batchAddAllocation(
        address[] calldata addresses,
        uint256[] calldata allocations
    ) external onlyOwner {
        require(
            addresses.length == allocations.length,
            "Claimer: Arguments length mismatch"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            address account = addresses[i];
            uint256 alloc = allocations[i];

            // Skip already added users
            if (allocation[account] > 0) {
                emit DuplicateAllocationSkipped(
                    account,
                    alloc,
                    allocation[account]
                );
                continue;
            }

            allocation[account] = alloc;
            totalTokens += alloc;
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        token.transfer(owner(), token.balanceOf(address(this)));
    }

    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(owner(), amount);
    }
}