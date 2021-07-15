// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction. While these are generally available
 * via msg.sender, they should not be accessed in such a direct
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
}

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

/**
 * @title Base contract for vesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme.
 */
abstract contract Erc20MultiVesting is Context, Ownable {
    using SafeERC20 for IERC20;

    event TokensReleased(address beneficiary, uint256 amount);
    event TokensAllocated(address beneficiary, uint256 amount);
    event TokensRevoked(address beneficiary, uint256 amount);

    uint256 internal _totalSupply;
    // Total allocated amount, should be less or equal than totalSupply
    uint256 internal _totalAllocatedSupply;

    uint256 private _totalRevokedClaim;

    uint256 private _tgeTime;
    uint256 private _cliffDuration;
    uint256 private _intervalDuration;

    uint256 private _tgePercent;
    uint256 private _intervalPercent;

    IERC20 private _token;

    /**
     * @dev When beneficiary added to vesting - contract allocate requested amount of tokens
     * that allocation stored to _allocated. When beneficiary call release method - contract send real tokens
     * to beneficiary that release stored to _released. Owner can revoke vesting for beneficiary - contract revoke
     * unvested tokens that revoke stored to _revoked (all vested tokens before revoke is available for beneficiary)
     */
    mapping(address => uint256) private _allocated;
    mapping(address => uint256) private _released;
    mapping(address => uint256) private _revoked;

    /**
     * @dev All beneficiaries participated in vesting
     */
    address[] private _beneficiaries;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, by start TGE time, wait cliff duration and interval releases. By then all
     * of the balance will have vested.
     * @param token_ address of the token which should be vested
     * @param totalSupply_ total tokens amount for current vesting contract
     * @param tgeTime_ UNIX timestamp at which vesting period will start (should be in future)
     * @param cliffDuration_ lockup period in seconds after tgeTime
     * @param intervalDuration_ duration in seconds of each release after cliffDuration
     * @param tgePercent_ percent of allocated tokens that vest for tgeTime
     * @param intervalPercent_ percent of allocated tokens that vest for each interval
     */
    constructor (
        address token_,
        uint256 totalSupply_,
        uint256 tgeTime_,
        uint256 cliffDuration_,
        uint256 intervalDuration_,
        uint256 tgePercent_,
        uint256 intervalPercent_
    ) {
        require(token_ != address(0), "Erc20MultiVesting: Token is the zero address!");
        require(totalSupply_ > 0, "Erc20MultiVesting: TotalSupply is 0!");
        require(intervalDuration_ > 0, "Erc20MultiVesting: Interval duration is 0!");
        require(tgePercent_ <= 100, "Erc20MultiVesting: TGE percent bigger than 100!");
        require(intervalPercent_ <= 100, "Erc20MultiVesting: Interval percent bigger than 100!");

        _token = IERC20(token_);
        _totalSupply = totalSupply_;
        _tgeTime = tgeTime_;
        _cliffDuration = cliffDuration_;
        _intervalDuration = intervalDuration_;
        _tgePercent = tgePercent_;
        _intervalPercent = intervalPercent_;
    }

    /*
     *  Getters
     */

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalAllocatedSupply() public view returns (uint256) {
        return _totalAllocatedSupply;
    }

    function totalRevokedClaim() public view returns (uint256) {
        return _totalRevokedClaim;
    }

    function tgeTime() public view returns (uint256) {
        return _tgeTime;
    }

    function cliffDuration() public view returns (uint256) {
        return _cliffDuration;
    }

    function intervalDuration() public view returns (uint256) {
        return _intervalDuration;
    }

    function tgePercent() public view returns (uint256) {
        return _tgePercent;
    }

    function intervalPercent() public view returns (uint256) {
        return _intervalPercent;
    }

    /**
     * @notice Allocated tokens is total amount of tokens for beneficiary
     * which will be sent in the vesting process
     * @param beneficiary address of beneficiary participated in vesting
     * @return total allocated tokens for beneficiary
     */
    function allocated(address beneficiary) public view returns (uint256) {
        return _allocated[beneficiary];
    }

    /**
     * @notice Released tokens is total amount of tokens really sent to
     * beneficiary
     * @param beneficiary address of beneficiary participated in vesting
     * @return total released tokens for beneficiary
     */
    function released(address beneficiary) public view returns (uint256) {
        return _released[beneficiary];
    }

    /**
     * @notice Revoked tokens is total amount of tokens revoked from beneficiary,
     * already vested tokens still available for beneficiary
     * @param beneficiary address of beneficiary participated in vesting
     * @return total revoked tokens for beneficiary
     */
    function revoked(address beneficiary) public view returns (uint256) {
        return _revoked[beneficiary];
    }

    /**
     * @notice Vested tokens is total amount of tokens unlocked for beneficiary,
     * not considering how much he has already taken
     * @param beneficiary address of beneficiary participated in vesting
     * @return total vested tokens for beneficiary
     */
    function vested(address beneficiary) public view returns (uint256) {
        return _vestedFor(beneficiary);
    }

    /**
     * @notice Available to release tokens is total amount of tokens which
     * beneficiary can take with release() method invoke
     * @param beneficiary address of beneficiary participated in vesting
     * @return total available to release tokens for beneficiary
     */
    function availableToRelease(address beneficiary) public view returns (uint256) {
        return _releasableAmount(beneficiary);
    }

    /**
     * @notice Help method to take tokens from the balance,
     * the amount of which is higher than total supply contract.
     * It can be used for situations when more token has come to the contract than total supply
     * This method cannot take total supply, so the beneficiaries are safe
     *
     * Only owner can invoke this method
     *
     * @param account receiver unused token address
     */
    function takeUnused(address account) public onlyOwner {
        require(account != address(0), "takeUnused: Account is the zero address!");

        uint256 currentBalance = _token.balanceOf(address(this));
        require(currentBalance > _totalSupply, "takeUnused: No unused tokens");

        uint256 unused = currentBalance - _totalSupply;
        _token.safeTransfer(account, unused);
    }

    /**
     * @notice Help method to take tokens from the balance,
     * the amount of which is higher than total supply contract.
     * It can be used for situations when more token has come to the contract than total supply
     * This method cannot take total supply, so the beneficiaries are safe
     *
     * Only owner can invoke this method
     *
     * @param account receiver unused token address
     */
    function takeRevoked(address account) public onlyOwner {
        require(account != address(0), "takeRevoked: Account is the zero address!");

        uint256 totalVestedForNow = _calculateVestedAmount(_totalSupply, 0);

        // Calculate vested amount for unallocated tokens as default value.
        // On next steps will fill vested amounts for all beneficiaries
        uint256 reallyVestedForNow = _calculateVestedAmount(_totalSupply - _totalAllocatedSupply, 0);
        for (uint i = 0; i < _beneficiaries.length; i++) {
            reallyVestedForNow += _vestedFor(_beneficiaries[i]);
        }

        require(totalVestedForNow > reallyVestedForNow, "takeRevoked: No revoked tokens");

        uint256 revokedForNow = totalVestedForNow - reallyVestedForNow;
        require(revokedForNow > _totalRevokedClaim, "takeRevoked: All revoked tokens are claimed");

        uint256 revokedForClaim = revokedForNow - _totalRevokedClaim;
        _totalRevokedClaim += revokedForClaim;

        _token.safeTransfer(account, revokedForClaim);
    }

    /**
     * @notice Transfer available tokens to method invoker account,
     * the account should be beneficiary with vesting allocation
     * Only beneficiary should invoke this method to release tokens
     */
    function release() public {
        _release(_msgSender());
    }

    /**
     * @notice Transfer available tokens to beneficiary, beneficiary should have
     * vesting allocation
     * @param beneficiary address for release tokens
     */
    function releaseFor(address beneficiary) public {
        _release(beneficiary);
    }

    /**
     * @notice Transfer available tokens to beneficiary
     * @param beneficiary address for sent token
     */
    function _release(address beneficiary) private {
        uint256 unreleased = _releasableAmount(beneficiary);
        require(unreleased > 0, "release: No tokens are due!");

        _released[beneficiary] += unreleased;
        _token.safeTransfer(beneficiary, unreleased);

        emit TokensReleased(beneficiary, unreleased);
    }

    /**
     * @param beneficiary address of beneficiary participated in vesting
     * @return total available to release tokens for beneficiary
     */
    function _releasableAmount(address beneficiary) private view returns (uint256) {
        return _vestedFor(beneficiary) - _released[beneficiary];
    }

    /**
     * @dev this is main vesting calculation
     * vested amount is total amount of available tokens (not considering released tokens)
     * vesting focuses on the current block timestamp and calculates from it
     * revoked tokens are also participates in calculation
     */
    function _vestedFor(address beneficiary) private view returns (uint256) {
        uint256 beneficiaryTotal = _allocated[beneficiary];
        require(beneficiaryTotal > 0, "release: Beneficiary does not have allocation");

        return _calculateVestedAmount(beneficiaryTotal, _revoked[beneficiary]);
    }

    function _calculateVestedAmount(uint256 totalAmount, uint256 revokedAmount) private view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime < _tgeTime) {
            return 0;
        }

        uint256 availableAmount = totalAmount - revokedAmount;
        uint256 tgeAmount = _percent(totalAmount, _tgePercent);
        uint256 intervalAmount = _percent(totalAmount, _intervalPercent);

        uint256 timeLeftAfterTge = currentTime - _tgeTime;
        if (timeLeftAfterTge < _cliffDuration) {
            return _min(availableAmount, tgeAmount);
        }

        uint256 timeLeftAfterCliff = currentTime - (_tgeTime + _cliffDuration);
        uint256 intervalReleasesCount = timeLeftAfterCliff / _intervalDuration;
        uint256 intervalTotalAmount = intervalAmount + intervalReleasesCount * intervalAmount;

        return _min(availableAmount, tgeAmount + intervalTotalAmount);
    }

    /**
     * @dev allocate amount of tokens for beneficiary
     * vesting of tokens is subject to the general rules of the contract
     * one beneficiary can participate only once
     * token allocation increase totalAllocatedSupply, which cannot be bigger than totalSupply
     * @param beneficiary address of beneficiary for token vesting
     * @param amount total amount of tokens for vesting
     */
    function _allocate(address beneficiary, uint256 amount) internal {
        require(_allocated[beneficiary] == 0, "allocate: Beneficiary has been already allocated");
        require(beneficiary != address(0), "allocate: Beneficiary is the zero address!");
        require(amount > 0, "allocate: amount is 0!");

        _totalAllocatedSupply += amount;
        require(_totalAllocatedSupply <= _totalSupply, "allocate: total supply exceeded");

        _allocated[beneficiary] = amount;
        _beneficiaries.push(beneficiary);

        emit TokensAllocated(beneficiary, amount);
    }

    /**
     * @dev revoke unvested tokens for beneficiary
     * token revokation not decrease totalAllocatedSupply
     * revoked tokens can't be allocated for another beneficiary
     * only contract owner can claim revoked tokens
     * one beneficiary can be revoked only once
     * @param beneficiary address of beneficiary for revoke
     */
    function _revoke(address beneficiary) internal {
        require(beneficiary != address(0), "revoke: Beneficiary is the zero address!");
        require(_revoked[beneficiary] == 0, "revoke: Beneficiary has been already revoked");

        uint256 allocated_ = _allocated[beneficiary];
        require(allocated_ > 0, "revoke: Beneficiary has not allocation");

        uint256 vested_ = _vestedFor(beneficiary);

        uint256 revoked_ = allocated_ - vested_;
        require(revoked_ > 0, "revoke: Nothing to revoke");

        _revoked[beneficiary] = revoked_;

        emit TokensRevoked(beneficiary, revoked_);
    }

    /**
     * @dev simple math min
     * @param a left operand
     * @param b right operand
     * @return math minimum of operand left and right
     */
    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev math percent calculation
     * since integer arithmetic is used, the result value is always rounded down
     * @param total percentage subject
     * @param percent_ percent value
     * @return absolute value as result of subject percentage
     */
    function _percent(uint256 total, uint256 percent_) private pure returns (uint256) {
        return total * percent_ / 100;
    }
}

/**
 * @title Custom contract for vesting
 * @notice Custom contract for vesting, contains all parameters as constructor args
 * additionally contains allocate and revoke methods controlled by flags
 *
 * This is final vesting contract for deploy
 */
contract CustomErc20MultiVesting is Erc20MultiVesting {

    /**
     * Helper struct for pass allocations to constructor
     */
    struct allocation {
        address beneficiary;
        uint256 amount;
    }

    bool private _allowRevoke;
    bool private _allowAllocate;

    /**
     * @notice Creates a vesting contract based on Erc20MultiVesting
     * additionally has control args
     * constructor contains safety checks
     * for revokable vesting we should allow allocate, otherwise tokens can be lost
     * for non allocable vesting we should allocate total amount in constructor,
     * otherwise tokens can be lost
     * @param allowRevoke_ allow to revoke tokens from beneficiary
     * @param allowAllocate_ allow allocate tokens to new beneficiary
     * @param allocations_ array of beneficiary allocations
     */
    constructor (
        address token_,
        uint256 totalSupply_,
        uint256 tgeTime_,
        uint256 cliffDuration_,
        uint256 intervalDuration_,
        uint256 tgePercent_,
        uint256 intervalPercent_,
        bool allowRevoke_,
        bool allowAllocate_,
        allocation[] memory allocations_
    ) Erc20MultiVesting(
        token_,
        totalSupply_,
        tgeTime_,
        cliffDuration_,
        intervalDuration_,
        tgePercent_,
        intervalPercent_
    ) {
        _allowAllocate = allowAllocate_;
        _allowRevoke = allowRevoke_;

        for (uint i = 0; i < allocations_.length; i++) {
            _allocate(allocations_[i].beneficiary, allocations_[i].amount);
        }

        if (!_allowAllocate) {
            require(_totalSupply == _totalAllocatedSupply,
                "non allocable vesting should allocated total supply");
        }
    }

    /*
     *  Getters
     */

    function allowRevoke() public view returns (bool) {
        return _allowRevoke;
    }

    function allowAllocate() public view returns (bool) {
        return _allowAllocate;
    }

    /**
     * @notice allocate amount of tokens for beneficiary
     * @dev proxy with restriction for _allocate method
     * @param beneficiary address of beneficiary for token vesting
     * @param amount total amount of tokens for vesting
     */
    function allocate(address beneficiary, uint256 amount) public onlyOwner {
        require(_allowAllocate, "contract does not allow to allocate");
        _allocate(beneficiary, amount);
    }

    /**
     * @notice revoke unvested tokens for beneficiary
     * @dev proxy with restriction for _revoke method
     * @param beneficiary address of beneficiary for revoke
     */
    function revoke(address beneficiary) public onlyOwner {
        require(_allowRevoke, "contract does not allow to revoke");
        _revoke(beneficiary);
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}