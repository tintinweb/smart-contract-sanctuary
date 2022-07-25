// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./TokenSaleDistributorStorage.sol";
import "./TokenSaleDistributorProxy.sol";
import "./ReentrancyGuard.sol";

contract TokenSaleDistributor is ReentrancyGuard, TokenSaleDistributorStorage {
    using SafeERC20 for IERC20;

    event Claimed(address indexed recipient, uint amount);

    /** The token address was set by the administrator. */
    event AdminSetToken(address tokenAddress);

    /** The administratory withdrew tokens. */
    event AdminWithdrewTokens(address tokenAddress, uint amount);

    /********************************************************
     *                                                      *
     *                   PUBLIC FUNCTIONS                   *
     *                                                      *
     ********************************************************/

    /**
     * @notice Claim the tokens that have already vested
     */
    function claim() external nonReentrant {
        uint claimed;

        uint length = allocations[msg.sender].length;
        for (uint i; i < length; ++i) {
            claimed += _claim(allocations[msg.sender][i]);
        }

        if (claimed > 0) {
            emit Claimed(msg.sender, claimed);
        }
    }

    /**
     * @notice Get the total number of allocations for `recipient`
     */
    function totalAllocations(address recipient) external view returns (uint) {
        return allocations[recipient].length;
    }

    /**
     * @notice Get all allocations for `recipient`
     */
    function getUserAllocations(address recipient) external view returns (Allocation[] memory) {
        return allocations[recipient];
    }

    /**
     * @notice Get the total amount of tokens allocated for `recipient`
     */
    function totalAllocated(address recipient) external view returns (uint) {
        uint total;

        uint length = allocations[recipient].length;
        for (uint i; i < length; ++i) {
            total += allocations[recipient][i].amount;
        }

        return total;
    }

    /**
     * @notice Get the total amount of vested tokens for `recipient` so far
     */
    function totalVested(address recipient) external view returns (uint) {
        uint tokensVested;

        uint length = allocations[recipient].length;
        for (uint i; i < length; ++i) {
            tokensVested += _vested(allocations[recipient][i]);
        }

        return tokensVested;
    }

    /**
     * @notice Get the total amount of claimed tokens by `recipient`
     */
    function totalClaimed(address recipient) external view returns (uint) {
        uint total;

        uint length = allocations[recipient].length;
        for (uint i; i < length; ++i) {
            total += allocations[recipient][i].claimed;
        }

        return total;
    }

    /**
     * @notice Get the total amount of claimable tokens by `recipient`
     */
    function totalClaimable(address recipient) external view returns (uint) {
        uint total;

        uint length = allocations[recipient].length;
        for (uint i; i < length; ++i) {
            total += _claimable(allocations[recipient][i]);
        }

        return total;
    }

    /**
     * @notice Get the total amount of expired tokens for `recipient`
     */
    function totalExpired(address recipient) external view returns (uint) {
        uint total;

        uint length = allocations[recipient].length;
        for (uint i; i < length; ++i) {
            Allocation memory allocation = allocations[recipient][i];

            if (_isExpired(allocation)) {
                total += allocation.amount - allocation.claimed;
            }
        }

        return total;
    }


    /********************************************************
     *                                                      *
     *               ADMIN-ONLY FUNCTIONS                   *
     *                                                      *
     ********************************************************/

    /**
     * @notice Set the amount of purchased tokens per user.
     * @param recipients Token recipients
     * @param isLinear Allocation types
     * @param epochs Vesting epochs
     * @param vestingDurations Vesting period lengths
     * @param cliffs Vesting cliffs, if any
     * @param cliffPercentages Vesting cliff unlock percentages, if any
     * @param amounts Purchased token amounts
     * @param gracePeriods Claiming grace periods, if any
     */
    function setAllocations(
        address[] memory recipients,
        bool[] memory isLinear,
        uint[] memory epochs,
        uint[] memory vestingDurations,
        uint[] memory cliffs,
        uint[] memory cliffPercentages,
        uint[] memory amounts,
        uint[] memory gracePeriods
    )
        external
        adminOnly
    {
        require(recipients.length == epochs.length);
        require(recipients.length == isLinear.length);
        require(recipients.length == vestingDurations.length);
        require(recipients.length == cliffs.length);
        require(recipients.length == cliffPercentages.length);
        require(recipients.length == amounts.length);
        require(recipients.length == gracePeriods.length);

        uint length = recipients.length;
        for (uint i; i < length; ++i) {
            require(cliffPercentages[i] <= 1e18);

            allocations[recipients[i]].push(
                Allocation(
                    isLinear[i],
                    epochs[i],
                    vestingDurations[i],
                    cliffs[i],
                    cliffPercentages[i],
                    amounts[i],
                    0,
                    gracePeriods[i]
                )
            );
        }
    }

    /**g
     * @notice Reset all data for the given addresses.
     * @param recipients Addresses whose data to reset
     */
    function resetAllocationsByUser(address[] memory recipients) external adminOnly {
        uint length = recipients.length;
        for (uint i; i < length; ++i) {
            delete allocations[recipients[i]];
        }
    }

    /**
     * @notice Withdraw deposited tokens from the contract.
     * @param amount Amount to withdraw from the contract balance
     */
    function withdraw(uint amount) external adminOnly {
        if (amount > 0) {
            IERC20(tokenAddress).safeTransfer(admin, amount);
        }
        emit AdminWithdrewTokens(tokenAddress, amount);
    }

    /**
     * @notice Set the vested token address
     * @param newTokenAddress ERC-20 token address
     */
    function setTokenAddress(address newTokenAddress) external adminOnly {
        require(tokenAddress == address(0), "Address already set");
        tokenAddress = newTokenAddress;

        emit AdminSetToken(newTokenAddress);
    }

    /**
     * @notice Accept this contract as the implementation for a proxy.
     * @param proxy TokenSaleDistributorProxy
     */
    function becomeImplementation(TokenSaleDistributorProxy proxy) external {
        require(msg.sender == proxy.admin(), "Only proxy admin can change the implementation");
        proxy.acceptPendingImplementation();
    }

    /**
     * @notice Withdraw tokens from the contract.
     * @param token The token address to withdraw
     * @param amount The amount of tokens to withdraw
     */
    function withdraw(address token, uint amount) external adminOnly {
        if (amount > 0) {
            IERC20(token).safeTransfer(admin , amount); 
        }
        emit AdminWithdrewTokens(tokenAddress, amount);
    }

    /********************************************************
     *                                                      *
     *                  INTERNAL FUNCTIONS                  *
     *                                                      *
     ********************************************************/

    /**
     * @notice Calculate the amount of vested tokens at the time of calling
     * @return Amount of vested tokens
     */
    function _vested(Allocation memory allocation) internal view returns (uint) {
        if (block.timestamp < allocation.epoch + allocation.cliff) {
            return 0;
        }

        uint initialAmount = allocation.amount * allocation.cliffPercentage / 1e18;
        uint postCliffAmount = allocation.amount - initialAmount;
        uint elapsed = block.timestamp - allocation.epoch - allocation.cliff;

        if (allocation.isLinear) {
            if (elapsed >= allocation.vestingDuration) {
                return allocation.amount;
            }

            return initialAmount + (postCliffAmount * elapsed / allocation.vestingDuration);
        }

        uint elapsedPeriods = elapsed / monthlyVestingInterval;
        if (elapsedPeriods >= allocation.vestingDuration) {
            return allocation.amount;
        }

        uint monthlyVestedAmount = postCliffAmount / allocation.vestingDuration;

        return initialAmount + (monthlyVestedAmount * elapsedPeriods);
    }

    /**
     * @notice Check if the allocation has expired and is no longer claimable
     */
    function _isExpired(Allocation memory allocation) internal view returns (bool) {
        if (allocation.gracePeriod == 0) {
            return false;
        }

        if (allocation.isLinear) {
            return allocation.epoch
                + allocation.cliff
                + allocation.vestingDuration
                 +allocation.gracePeriod < block.timestamp;
        }

        return allocation.epoch
            + allocation.cliff
            + (allocation.vestingDuration * monthlyVestingInterval)
            + allocation.gracePeriod < block.timestamp;
    }

    /**
     * @notice Get the amount of claimable tokens for `allocation`
     */
    function _claimable(Allocation memory allocation) internal view returns (uint) {
        if (_isExpired(allocation)) {
            return 0;
        }

        return _vested(allocation) - allocation.claimed;
    }

    /**
     * @notice Claim all vested tokens from the allocation
     * @return The amount of claimed tokens
     */
    function _claim(Allocation storage allocation) internal returns (uint) {
        uint claimable = _claimable(allocation);
        if (claimable == 0) {
            return 0;
        }

        allocation.claimed += claimable;
        IERC20(tokenAddress).safeTransfer(msg.sender, claimable);

        return claimable;
    }

    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./Address.sol";

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

pragma solidity 0.8.10;

import "./TokenSaleDistributorProxyStorage.sol";

contract TokenSaleDistributorStorage is TokenSaleDistributorProxyStorage {
    address public tokenAddress;

    // 60 * 60 * 24 * 365 / 12 seconds
    uint public constant monthlyVestingInterval = 2628000;

    mapping(address => Allocation[]) public allocations;

    struct Allocation {
        // True for linear vesting, false for monthly
        bool isLinear;

        // Vesting start timestamp
        uint epoch;

        // Linear: The amount of seconds after the cliff before all tokens are vested
        // Monthly: The number of monthly claims before all tokens are vested
        uint vestingDuration;

        // Seconds after epoch when tokens start vesting
        uint cliff;

        // Percentage of tokens that become vested immediately after the cliff. 100 % = 1e18.
        uint cliffPercentage;

        // Total amount of allocated tokens
        uint amount;

        // Amount of claimed tokens from this allocation
        uint claimed;

        // The duration during which the tokens have to be claimed after all tokens are vested.
        // If not claimed, the tokens are returned to the treasury. 0 for disabled.
        uint gracePeriod;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./ReentrancyGuard.sol";
import "./TokenSaleDistributorProxyStorage.sol";

contract TokenSaleDistributorProxy is ReentrancyGuard, TokenSaleDistributorProxyStorage {
    /** The admin was changed  */
    event AdminChanged(address newAdmin);

    /** The implementation was changed */
    event ImplChanged(address newImpl);

    constructor() public {
        admin = msg.sender;
    }

    /**
     * Request a new admin to be set for the contract.
     *
     * @param newAdmin New admin address
     */
    function setPendingAdmin(address newAdmin) public adminOnly {
        require(newAdmin != address(0), "Cannot set to zero address");
        pendingAdmin = newAdmin;
    }

    /**
     * Accept admin transfer from the current admin to the new.
     */
    function acceptPendingAdmin() public {
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "Caller must be the pending admin");

        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit AdminChanged(admin);
    }

    /**
     * Request a new implementation to be set for the contract.
     *
     * @param newImplementation New contract implementation contract address
     */
    function setPendingImplementation(address newImplementation) public adminOnly {
        require(newImplementation != address(0), "Cannot set to zero address");
        pendingImplementation = newImplementation;
    }

    /**
     * Accept pending implementation change
     */
    function acceptPendingImplementation() public {
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "Only the pending implementation contract can call this");

        implementation = pendingImplementation;
        pendingImplementation = address(0);

        emit ImplChanged(implementation);
    }

    fallback() payable external {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            let size := returndatasize()
            returndatacopy(free_mem_ptr, 0, size)

            switch success
            case 0 { revert(free_mem_ptr, size) }
            default { return(free_mem_ptr, size) }
        }
    }

    /********************************************************
     *                                                      *
     *                      MODIFIERS                       *
     *                                                      *
     ********************************************************/

    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
contract ReentrancyGuard {
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

    constructor() public {
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
pragma solidity 0.8.10;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

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

pragma solidity 0.8.10;

contract TokenSaleDistributorProxyStorage {
    // Current contract admin address
    address public admin;

    // Requested new admin for the contract
    address public pendingAdmin;

    // Current contract implementation address
    address public implementation;

    // Requested new contract implementation address
    address public pendingImplementation;
}