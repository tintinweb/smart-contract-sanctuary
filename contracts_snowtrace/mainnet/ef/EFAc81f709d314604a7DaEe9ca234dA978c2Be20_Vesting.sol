/**
 *Submitted for verification at snowtrace.io on 2021-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

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


// File contracts/Vesting/Vesting.sol

/**
 *  @title Vesting contract
 ***********************************
 *  @notice Makes tokens available to claim for addresses according to specified distribution rules.
 *
 *  Vesting rules are defined within user groups. Users are added to a group with vesting amount that is to be
 *  distributed according to group rules.
 *  Contract has to have balance prior to make groups possible to be set. Groups have to be set before users are
 *  possible to be set.
 *
 *  The vesting process can be paused and unpaused any time.
 *  The vesting process can be closed permanently and all remaining tokens can be withdrawn from the contract.
 */
contract Vesting is Ownable, Pausable {

    using SafeERC20 for IERC20;


    /**************************************
     *  PROPERTIES, DATA STRUCTS, EVENTS  *
     **************************************/

    bool public vestingStarted;             // true when the vesting procedure has started
    uint public vestingStartTimestamp;      // the starting timestamp of vesting schedule
    bool public vestingScheduledForClosing; // true when the admin schedules vesting for closing
    uint public vestingCloseTimestamp;      // the time when vesting is closed and no more claims can be made
    uint public vestingCloseOffset;         // offset in seconds when the admin is allowed to close vesting after last group vesting ends
    uint public vestingCloseMargin;         // adds additional offset in s after closeVesting() how long users will still be able to claim tokens
    IERC20 public vestingToken;             // the address of an ERC20 token used for vesting

    // holds user groups configuration and data
    GroupData[] public groupsConfiguration;
    // holds user vesting data
    mapping (address => UserData) public userConfiguration;

    struct UserData {
        uint groupId;                    // Id of group
        uint vestAmount;                 // The total number of tokens that are vested
        uint withdrawnAmount;            // The current amount of already withdrawn tokens
    }

    struct GroupData {
        string name;                     // Name of group
        uint distributionAmount;         // The amount of tokens that can be distributed within this group
        uint vestedAmount;               // The actual number of tokens currently assigned for distribution
        uint distributionStartOffset;    // The offset of distribution start from vesting start timestamp
        uint distributionLength;         // The total length in ms of distribution.
        uint initialRelease;             // The mantissa of the tokens to be distributed when vesting begins
    }

    event VestingStarted();
    event VestingScheduledForClosing(uint closeTimestamp);
    event UserDataSet(address user, uint groupId, uint vestAmount);
    event GroupDataSet(
        uint groupId,
        string groupName,
        uint maxDistributionAmount,
        uint distributionOffset,
        uint distributionLength,
        uint initialRelease
    );
    event TokensClaimed(address user, uint groupId, uint amount);
    event TokensReclaimed(address initiator, address receiver, uint amount);




    /**
     *  @param vestingTokenAddress - the address of the token used for distribution
     *  @param closeOffset        - offset in seconds when the contract can be closed after all groups vesting ends
     *  @param closeMargin        - additional offset after vesting is scheduled for closing
     */
    constructor(address vestingTokenAddress, uint closeOffset, uint closeMargin) {
        require(vestingTokenAddress != address(0), "Vesting token address invalid!");
        vestingToken = IERC20(vestingTokenAddress);
        vestingStarted = false;
        vestingScheduledForClosing = false;
        vestingCloseOffset = closeOffset;
        vestingCloseMargin = closeMargin;
    }





    /********************
     *  CONTRACT LOGIC  *
     ********************/

    /**
     *  @notice claims all available tokens
     */
    function claimAll() external afterVestingStarted beforeVestingClosed whenNotPaused {
        claim(checkClaim(msg.sender));
    }

    /**
     *  @notice transfers the specified amount of tokens to the claimer. Reverts when the amount exceeds available.
     *  @param amount - the amount of tokens to be claimed
     */
    function claim(uint amount) public afterVestingStarted beforeVestingClosed whenNotPaused {
        require(checkClaim(msg.sender) >= amount, "Claim amount too high!");

        userConfiguration[msg.sender].withdrawnAmount = userConfiguration[msg.sender].withdrawnAmount + amount;
        vestingToken.transfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, userConfiguration[msg.sender].groupId, amount);
    }

    /**
     *  @notice checks how many tokens can be claimed by the given account address
     *  @param account - the wallet address to be checked
     *  @return the amount of tokens that can be claimed
     */
    function checkClaim(address account) public view returns (uint) {
        UserData storage userData = userConfiguration[account];
        GroupData storage groupData = groupsConfiguration[userData.groupId];

        uint initialReleaseShare;
        // if vesting started check the initial release amount
        if (vestingStarted && vestingStartTimestamp <= block.timestamp) {
            initialReleaseShare = groupData.initialRelease * userData.vestAmount / 1e18;
        }

        // return only the initial release share when vesting for group has not started yet
        if (block.timestamp <= (vestingStartTimestamp + groupData.distributionStartOffset)) {
            return initialReleaseShare - userData.withdrawnAmount;
        }

        // return all available amount of unclaimed tokens if the vesting ended
        if ((block.timestamp - (vestingStartTimestamp + groupData.distributionStartOffset)) >= groupData.distributionLength ) {
            return userData.vestAmount - userData.withdrawnAmount;
        }

        // or calculate the amount of tokens when vesting is in progress
        return
            initialReleaseShare +
            (
                (block.timestamp - (vestingStartTimestamp + groupData.distributionStartOffset))
                * 1e18
                / groupData.distributionLength
                * (userData.vestAmount - initialReleaseShare)
                / 1e18
            )
            - userData.withdrawnAmount;
    }




    /******************************
     *  ADMINISTRATIVE FUNCTIONS  *
     ******************************/

    /**
     *  @notice sets the group settings for token distribution. Can only be set before vesting started.
     *  @param groupName                  - the semantic name of group
     *  @param distributionAmount      - the total amount of tokens that can be distributed to this group users
     *  @param distributionStartOffset    - the offset in seconds between contracts starting timestamp and group distribution
     *  @param distributionLength         - the time in seconds
     *  @return                           - the id of newly added group
     */
    function _setGroup(
        string memory groupName,
        uint distributionAmount,
        uint distributionStartOffset,
        uint distributionLength,
        uint initialRelease
    ) external onlyOwner beforeVestingStarted returns(uint) {
        require(distributionAmount > 0, "Invalid Distribution Amount!");
        require(distributionLength > 0, "Invalid Distribution Lenght!");
        require(initialRelease <= 1e18, "Invalid Initial Release!");

        uint sumDistributionAmount = 0;
        for (uint i; i < groupsConfiguration.length; i++) {
            sumDistributionAmount += groupsConfiguration[i].distributionAmount;
        }
        require(distributionAmount + sumDistributionAmount <= vestingToken.balanceOf(address(this)), "Distribution amount too big!");

        GroupData memory groupData;
        groupData.name = groupName;
        groupData.distributionAmount = distributionAmount;
        groupData.distributionStartOffset = distributionStartOffset;
        groupData.distributionLength = distributionLength;
        groupData.initialRelease = initialRelease;

        groupsConfiguration.push(groupData);
        uint groupId = groupsConfiguration.length - 1;
        emit GroupDataSet(groupId, groupName, distributionAmount, distributionStartOffset, distributionLength, initialRelease);

        return groupId;
    }

    /**
     *  @notice configures the vesting for specified user. Can only be set before vesting started.
     *  @param account    - the address for which we are configuring vesting
     *  @param groupId    - the ID of the group which the user should belong to
     *  @param vestAmount - the amount of tokens to be distributed
     */
    function _setUser(address account, uint groupId, uint vestAmount) public onlyOwner beforeVestingStarted {
        require(account != address(0), "Wrong wallet address specified!");
        require(groupId < groupsConfiguration.length, "Invalid groupId!");
        require(
            vestAmount <= groupsConfiguration[groupId].distributionAmount - groupsConfiguration[groupId].vestedAmount,
            "Vesting amount too high!"
        );

        // recalculate grups vested amount if updating user
        if (userConfiguration[account].vestAmount > 0) {
            groupsConfiguration[userConfiguration[account].groupId].vestedAmount -= userConfiguration[account].vestAmount;
        }

        UserData memory userData;
        userData.groupId = groupId;
        userData.vestAmount = vestAmount;
        userConfiguration[account] = userData;

        groupsConfiguration[groupId].vestedAmount += vestAmount;

        emit UserDataSet(account, groupId, vestAmount);
    }

    /**
     *  @notice provides a convenient interface for adding users in bulk. See _setUser() for additional info.
     *  @param accounts    - array of accounts
     *  @param groupIds    - array of groupIds
     *  @param vestAmounts - array of vesting amounts
     */
    function _setUserBulk(address[] memory accounts, uint[] memory groupIds, uint[] memory vestAmounts) external onlyOwner beforeVestingStarted {
        require(accounts.length == groupIds.length && groupIds.length == vestAmounts.length, "Invalid array lengths!");
        for (uint i = 0; i < accounts.length; i++) {
            _setUser(accounts[i], groupIds[i], vestAmounts[i]);
        }
    }

    /**
     *  @notice Starts the vesting schedule.
     *  Since we cannot modify any vesting rules after vesting starts, we return the unallocated token amount to the
     *  provided wallet address.
     *  @param timestamp    - the vesting starting time. if timestamp = 0 the vesting starts this block
     *  @param returnWallet - the wallet address for returning unallocated funds
     */
    function _startVesting(uint timestamp, address returnWallet) external onlyOwner beforeVestingStarted {
        require(timestamp == 0 || timestamp > block.timestamp, "Invalid vesting start!");
        require(vestingToken.balanceOf(address(this)) > 0, "Vesting Contract has no balance!");
        require(groupsConfiguration.length > 0, "No groups configured!");
        require(returnWallet != address(0), "Return wallet not specified!");

        vestingStarted = true;

        if (timestamp == 0) {
            vestingStartTimestamp = block.timestamp;
        } else {
            vestingStartTimestamp = timestamp;
        }

        uint vestedTotalAmount = 0;
        for (uint i; i < groupsConfiguration.length; i++) {
            vestedTotalAmount += groupsConfiguration[i].vestedAmount;
        }
        uint difference = vestingToken.balanceOf(address(this)) - vestedTotalAmount;
        if (difference > 0) {
            vestingToken.transfer(returnWallet, difference);
        }

        emit VestingStarted();
    }

    /**
     *  @notice Pauses the ability to claim tokens from vesting contract
     */
    function _pauseVesting() external onlyOwner afterVestingStarted whenNotPaused {
        _pause();
    }

    /**
     *  @notice Resumes the ability to claim tokens from vesting contract
     */
    function _unpauseVesting() external onlyOwner afterVestingStarted whenPaused {
        _unpause();
    }

    /**
     *  @notice checks if a defined time has passed since ending of all groups vesting and schedules the vesting for closing
     *  If no time is specified in vestingCloseMargin the vesting is closed immediately
     */
    function _closeVesting() external onlyOwner afterVestingStarted beforeVestingClosed {
        uint groupVestingEndTimestamp = _lastGroupDistributionFinishTimestamp();
        require(groupVestingEndTimestamp + vestingCloseOffset < block.timestamp, "Cannot close vesting!");
        vestingScheduledForClosing = true;
        vestingCloseTimestamp = block.timestamp + vestingCloseMargin;
        emit VestingScheduledForClosing(vestingCloseTimestamp);
    }


    /**
     *  @notice calculates the ending timestamp of last group's distribution schedule
     *  @return the last schedule end timestamp
     */
    function _lastGroupDistributionFinishTimestamp() internal view returns (uint) {
        uint groupVestingEndTimestamp;
        for (uint i; i < groupsConfiguration.length; i++) {
            uint closeTimestamp =
            vestingStartTimestamp
            + groupsConfiguration[i].distributionStartOffset
            + groupsConfiguration[i].distributionLength;
            if (closeTimestamp > groupVestingEndTimestamp) {
                groupVestingEndTimestamp = closeTimestamp;
            }
        }
        return groupVestingEndTimestamp;
    }

    /**
     *  @notice reclaims the unclaimed token balance from this contract to admin address
     *  Executable only when vesting is closed.
     *  @param receiver - the address to which the contract balance is sent
     */
    function _reclaim(address receiver) public onlyOwner afterVestingClosed {
        uint contractBalance = vestingToken.balanceOf(address(this));
        vestingToken.transfer(receiver, contractBalance);
        emit TokensReclaimed(msg.sender, receiver, contractBalance);
    }




    /***************
     *  MODIFIERS  *
     ***************/

    modifier afterVestingStarted {
        require(vestingStarted, "Vesting has not started!");
        _;
    }
    modifier beforeVestingStarted {
        require(!vestingStarted, "Vesting has already started!");
        _;
    }
    modifier beforeVestingClosed {
        require(
            vestingCloseTimestamp == 0
            || vestingCloseTimestamp > block.timestamp,
            "Vesting has been closed!"
        );
        _;
    }
    modifier afterVestingClosed {
        require(
            vestingCloseTimestamp != 0
            && vestingCloseTimestamp <= block.timestamp,
            "Vesting has not been closed!"
        );
        _;
    }
}