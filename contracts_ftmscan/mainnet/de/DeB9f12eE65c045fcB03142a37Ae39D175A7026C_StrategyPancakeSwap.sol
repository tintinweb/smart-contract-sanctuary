/**
 *Submitted for verification at FtmScan.com on 2021-12-04
*/

// SPDX-License-Identifier: MIXED

// File @violinio/defi-interfaces/contracts/[email protected]
// License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPancakeSwapMC {
    function BONUS_MULTIPLIER() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function devaddr() external view returns (address);

    function emergencyWithdraw(uint256 _pid) external;

    function enterStaking(uint256 _amount) external;

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);

    function leaveStaking(uint256 _amount) external;

    function massUpdatePools() external;

    function migrate(uint256 _pid) external;

    function migrator() external view returns (address);

    function owner() external view returns (address);

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accCakePerShare
        );

    function poolLength() external view returns (uint256);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function startBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// File @openzeppelin/contracts/token/ERC20/[email protected]
// License-Identifier: MIT

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

// File @openzeppelin/contracts/utils/[email protected]
// License-Identifier: MIT

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

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]
// License-Identifier: MIT

pragma solidity ^0.8.0;


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

// File @openzeppelin/contracts/utils/introspection/[email protected]
// License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File @openzeppelin/contracts/token/ERC1155/[email protected]
// License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File contracts/interfaces/IStrategy.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;

interface IStrategy {
  /**
     * @notice Gets the token this strategy compounds.
     * @dev This token might have a transfer-tax.
     * @dev Invariant: This variable may never change.
     */
    function underlyingToken() external view returns (IERC20);

    /**
     * @notice Gets the total amount of tokens either idle in this strategy or staked in an underlying strategy.
     */
    function totalUnderlying() external view returns (uint256 totalUnderlying);
    /**
     * @notice Gets the total amount of tokens either idle in this strategy or staked in an underlying strategy and only the tokens actually staked.
     */
    function totalUnderlyingAndStaked() external view returns (uint256 totalUnderlying, uint256 totalUnderlyingStaked);

    /**
     * @notice The panic function unstakes all staked funds from the strategy and leaves them idle in the strategy for withdrawal
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function panic() external;

    /**
     * @notice Executes a harvest on the underlying vaultchef.
     * @dev Authority: This function must only be callable by the vaultchef.
     */
    function harvest() external;
    /**
     * @notice Deposits `amount` amount of underlying tokens in the underlying strategy
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Withdraws `amount` amount of underlying tokens to `to`.
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function withdraw(address to, uint256 amount) external;

    /**
     * @notice Withdraws `amount` amount of `token` to `to`.
     * @notice This function is used to withdraw non-staking and non-native tokens accidentally sent to the strategy.
     * @notice It will also be used to withdraw tokens airdropped to the strategies.
     * @notice The underlying token can never be withdrawn through this method because VaultChef prevents it.
     * @dev Requirement: This function should in no way allow withdrawal of staking tokens
     * @dev Requirement: This function should in no way allow for the decline in shares or share value (this is also checked in the VaultChef);
     * @dev Validation is already done in the VaultChef that the staking token cannot be withdrawn.
     * @dev Authority: This function must only be callable by the VaultChef.
     */
    function inCaseTokensGetStuck(
        IERC20 token,
        uint256 amount,
        address to
    ) external;
}

// File contracts/interfaces/IVaultChefCore.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;



/**
 * @notice The VaultChef is a vault management contract that manages vaults, their strategies and the share positions of investors in these vaults.
 * @notice Positions are not hardcoded into the contract like traditional staking contracts, instead they are managed as ERC-1155 receipt tokens.
 * @notice This receipt-token mechanism is supposed to simplify zapping and other derivative protocols.
 * @dev The VaultChef contract has the following design principles.
 * @dev 1. Simplicity of Strategies: Strategies should be as simple as possible.
 * @dev 2. Control of Governance: Governance should never be able to steal underlying funds.
 * @dev 3. Auditability: It should be easy for third-party reviewers to assess the safety of the VaultChef.
 */
interface IVaultChefCore is IERC1155 {
    /// @notice A vault is a strategy users can stake underlying tokens in to receive a share of the vault value.
    struct Vault {
        /// @notice The token this strategy will compound.
        IERC20 underlyingToken;
        /// @notice The timestamp of the last harvest, set to zero while no harvests have happened.
        uint96 lastHarvestTimestamp;
        /// @notice The strategy contract.
        IStrategy strategy;
        /// @notice The performance fee portion of the harvests that is sent to the feeAddress, denominated by 10,000.
        uint16 performanceFeeBP;
        /// @notice Whether deposits are currently paused.
        bool paused;
        /// @notice Whether the vault has panicked which means the funds are pulled from the strategy and it is paused forever.
        bool panicked;
    }

    /**
     * @notice Deposit `underlyingAmount` amount of underlying tokens into the vault and receive `sharesReceived` proportional to the actually staked amount.
     * @notice Deposits mint `sharesReceived` receipt tokens as ERC-1155 tokens to msg.sender with the tokenId equal to the vaultId.
     * @notice The tokens are transferred from `msg.sender` which requires approval if pulled is set to false, otherwise `msg.sender` needs to implement IPullDepositor.
     * @param vaultId The id of the vault.
     * @param underlyingAmount The intended amount of tokens to deposit (this might not equal the actual deposited amount due to tx/stake fees or the pull mechanism).
     * @param pulled Uses a pull-based deposit hook if set to true, otherwise traditional safeTransferFrom. The pull-based mechanism allows the depositor to send tokens using a hook.
     * @param minSharesReceived The minimum amount of shares that must be received, or the transaction reverts.
     * @dev This pull-based methodology is extremely valuable for zapping transfer-tax tokens more economically.
     * @dev `msg.sender` must be a smart contract implementing the `IPullDepositor` interface.
     * @return sharesReceived The number of shares minted to the msg.sender.
     */
    function depositUnderlying(
        uint256 vaultId,
        uint256 underlyingAmount,
        bool pulled,
        uint256 minSharesReceived
    ) external returns (uint256 sharesReceived);

    /**
     * @notice Withdraws `shares` from the vault into underlying tokens to the `msg.sender`.
     * @notice Burns `shares` receipt tokens from the `msg.sender`.
     * @param vaultId The id of the vault.
     * @param shares The amount of shares to burn, underlying tokens will be sent to msg.sender proportionally.
     * @param minUnderlyingReceived The minimum amount of underlying tokens that must be received, or the transaction reverts.
     */
    function withdrawShares(
        uint256 vaultId,
        uint256 shares,
        uint256 minUnderlyingReceived
    ) external returns (uint256 underlyingReceived);

    /**
     * @notice Withdraws `shares` from the vault into underlying tokens to the `to` address.
     * @notice To prevent phishing, we require msg.sender to be a contract as this is intended for more economical zapping of transfer-tax token withdrawals.
     * @notice Burns `shares` receipt tokens from the `msg.sender`.
     * @param vaultId The id of the vault.
     * @param shares The amount of shares to burn, underlying tokens will be sent to msg.sender proportionally.
     * @param minUnderlyingReceived The minimum amount of underlying tokens that must be received, or the transaction reverts.
     */
    function withdrawSharesTo(
        uint256 vaultId,
        uint256 shares,
        uint256 minUnderlyingReceived,
        address to
    ) external returns (uint256 underlyingReceived);

    /**
     * @notice Total amount of shares in circulation for a given vaultId.
     * @param vaultId The id of the vault.
     * @return The total number of shares currently in circulation.
     */
    function totalSupply(uint256 vaultId) external view returns (uint256);

    /**
     * @notice Calls harvest on the underlying strategy to compound pending rewards to underlying tokens.
     * @notice The performance fee is minted to the owner as shares, it can never be greater than 5% of the underlyingIncrease.
     * @return underlyingIncrease The amount of underlying tokens generated.
     * @dev Can only be called by owner.
     */
    function harvest(uint256 vaultId)
        external
        returns (uint256 underlyingIncrease);

    /**
     * @notice Adds a new vault to the vaultchef.
     * @param strategy The strategy contract that manages the allocation of the funds for this vault, also defines the underlying token
     * @param performanceFeeBP The percentage of the harvest rewards that are given to the governance, denominated by 10,000 and maximum 5%.
     * @dev Can only be called by owner.
     */
    function addVault(IStrategy strategy, uint16 performanceFeeBP) external;

    /**
     * @notice Updates the performanceFee of the vault.
     * @param vaultId The id of the vault.
     * @param performanceFeeBP The percentage of the harvest rewards that are given to the governance, denominated by 10,000 and maximum 5%.
     * @dev Can only be called by owner.
     */
    function setVault(uint256 vaultId, uint16 performanceFeeBP) external;
    /**
     * @notice Allows the `pullDepositor` to create pull-based deposits (useful for zapping contract).
     * @notice Having a whitelist is not necessary for this functionality as it is safe but upon defensive code recommendations one was added in.
     * @dev Can only be called by owner.
     */
    function setPullDepositor(address pullDepositor, bool isAllowed) external;
    
    /**
     * @notice Withdraws funds from the underlying staking contract to the strategy and irreversibly pauses the vault.
     * @param vaultId The id of the vault.
     * @dev Can only be called by owner.
     */
    function panicVault(uint256 vaultId) external;

    /**
     * @notice Returns true if there is a vault associated with the `vaultId`.
     * @param vaultId The id of the vault.
     */
    function isValidVault(uint256 vaultId) external returns (bool);

    /**
     * @notice Returns the Vault information of the vault at `vaultId`, returns if non-existent.
     * @param vaultId The id of the vault.
     */
    function vaultInfo(uint256 vaultId) external returns (IERC20 underlyingToken, uint96 lastHarvestTimestamp, IStrategy strategy, uint16 performanceFeeBP, bool paused, bool panicked);

    /**
     * @notice Pauses the vault which means deposits and harvests are no longer permitted, reverts if already set to the desired value.
     * @param vaultId The id of the vault.
     * @param paused True to pause, false to unpause.
     * @dev Can only be called by owner.
     */
    function pauseVault(uint256 vaultId, bool paused) external;

    /**
     * @notice Transfers tokens from the VaultChef to the `to` address.
     * @notice Cannot be abused by governance since the protocol never ever transfers tokens to the VaultChef. Any tokens stored there are accidentally sent there.
     * @param token The token to withdraw from the VaultChef.
     * @param to The address to send the token to.
     * @dev Can only be called by owner.
     */
    function inCaseTokensGetStuck(IERC20 token, address to) external;

    /**
     * @notice Transfers tokens from the underlying strategy to the `to` address.
     * @notice Cannot be abused by governance since VaultChef prevents token to be equal to the underlying token.
     * @param token The token to withdraw from the strategy.
     * @param to The address to send the token to.
     * @param amount The amount of tokens to withdraw.
     * @dev Can only be called by owner.
     */
    function inCaseVaultTokensGetStuck(
        uint256 vaultId,
        IERC20 token,
        address to,
        uint256 amount
    ) external;
}

// File contracts/interfaces/IMasterChef.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;

/// @dev The VaultChef implements the masterchef interface for compatibility with third-party tools.
interface IMasterChef {
    /// @dev An active vault has a dummy allocPoint of 1 while an inactive one has an allocPoint of zero.
    /// @dev This is done for better compatibility with third-party tools.
    function poolInfo(uint256 pid)
        external
        view
        returns (
            IERC20 lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare
        );

    function userInfo(uint256 pid, address user)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function startBlock() external view returns (uint256);

    function poolLength() external view returns (uint256);

    /// @dev Returns the total number of active vaults.
    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// File contracts/interfaces/IERC20Metadata.sol
// License-Identifier: MIT
// Based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/1b27c13096d6e4389d62e7b0766a1db53fbb3f1b/contracts/token/ERC20/extensions/IERC20Metadata.sol

pragma solidity ^0.8.6;
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File contracts/interfaces/IVaultChefWrapper.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;



interface IVaultChefWrapper is IMasterChef, IERC20Metadata{
     /**
     * @notice Interface function to fetch the total underlying tokens inside a vault.
     * @notice Calls the totalUnderlying function on the vault strategy.
     * @param vaultId The id of the vault.
     */
    function totalUnderlying(uint256 vaultId) external view returns (uint256);

     /**
     * @notice Changes the ERC-20 metadata for etherscan listing.
     * @param newName The new ERC-20-like token name.
     * @param newSymbol The new ERC-20-like token symbol.
     * @param newDecimals The new ERC-20-like token decimals.
     */
    function changeMetadata(
        string memory newName,
        string memory newSymbol,
        uint8 newDecimals
    ) external;

     /**
     * @notice Sets the ERC-1155 metadata URI.
     * @param newURI The new ERC-1155 metadata URI.
     */
    function setURI(string memory newURI) external;

    /// @notice mapping that returns true if the strategy is set as a vault.
    function strategyExists(IStrategy strategy) external view returns(bool);


    /// @notice Utility mapping for UI to figure out the vault id of a strategy.
    function strategyVaultId(IStrategy strategy) external view returns(uint256);

}

// File contracts/interfaces/IVaultChef.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;


/// @notice Interface for derivative protocols.
interface IVaultChef is IVaultChefWrapper, IVaultChefCore {
    function owner() external view returns (address);
}

// File contracts/interfaces/IZapHandler.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;

/// @notice The IZap interface allows contracts to swap a token for another token without having to directly interact with verbose AMMs directly.
/// @notice It furthermore allows to zap to and from an LP pair within a single transaction.
interface IZapHandler {
    struct Factory {
        /// @dev The address of the factory.
        address factory;
        /// @dev The fee nominator of the AMM, usually set to 997 for a 0.3% fee.
        uint32 amountsOutNominator;
        /// @dev The fee denominator of the AMM, usually set to 1000.
        uint32 amountsOutDenominator;
    }

    function setFactory(
        address factory,
        uint32 amountsOutNominator,
        uint32 amountsOutDenominator
    ) external;

    function setRoute(
        IERC20 from,
        IERC20 to,
        address[] memory inputRoute
    ) external;
    function factories(address factoryAddress) external view returns (Factory memory);

    function routeLength(IERC20 token0, IERC20 token1) external view returns (uint256);

    function owner() external view returns (address);
}

// File contracts/interfaces/IZap.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;


/// @notice The IZap interface allows contracts to swap a token for another token without having to directly interact with verbose AMMs directly.
/// @notice It furthermore allows to zap to and from an LP pair within a single transaction.
interface IZap {
    /**
    * @notice Swap `amount` of `fromToken` to `toToken` and send them to the `recipient`.
    * @notice The `fromToken` and `toToken` arguments can be AMM pairs.
    * @notice Reverts if the `recipient` received less tokens than `minReceived`.
    * @notice Requires approval.
    * @param fromToken The token to take from `msg.sender` and exchange for `toToken`.
    * @param toToken The token that will be bought and sent to the `recipient`.
    * @param recipient The destination address to receive the `toToken`.
    * @param amount The amount that the zapper should take from the `msg.sender` and swap.
    * @param minReceived The minimum amount of `toToken` the `recipient` should receive. Otherwise the transaction reverts.
    */
    function swapERC20(IERC20 fromToken, IERC20 toToken, address recipient, uint256 amount, uint256 minReceived) external returns (uint256 received);


    /**
    * @notice Swap `amount` of `fromToken` to `toToken` and send them to the `msg.sender`.
    * @notice The `fromToken` and `toToken` arguments can be AMM pairs.
    * @notice Requires approval.
    * @param fromToken The token to take from `msg.sender` and exchange for `toToken`.
    * @param toToken The token that will be bought and sent to the `msg.sender`.
    * @param amount The amount that the zapper should take from the `msg.sender` and swap.
    */
    function swapERC20Fast(IERC20 fromToken, IERC20 toToken, uint256 amount) external;

    function implementation() external view returns (IZapHandler);
}

// File contracts/strategies/BaseStrategy.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;



/**
 * @notice The BaseStrategy implements reusable logic for all Violin strategies that earn some single asset "rewardToken".
 * @dev It exposes a very simple interface which the actual strategies can implement.
 * @dev The zapper contract does not have excessive privileges and withdrawals should always be possible even if it reverts.
 */
abstract contract BaseStrategy is IStrategy {
    using SafeERC20 for IERC20;
    /// @dev Set to true once _initializeBase is called by the implementation.
    bool initialized;

    /// @dev The vaultchef contract this strategy is managed by.
    IVaultChef public vaultchef;
    /// @dev The zapper contract to swap earned for underlying tokens.
    IZap public zap;
    /// @dev The token that is actually staked into the underlying protocol.
    IERC20 public override underlyingToken;
    /// @dev The token the underlying protocol gives as a reward.
    IERC20 public rewardToken;

    modifier onlyVaultchef() {
        require(msg.sender == address(vaultchef), "!vaultchef");
        _;
    }

    modifier initializer() {
        require(!initialized, "!already initialized");
        _;
        // We unsure that the implementation has called _initializeBase during the external initialize function.
        require(initialized, "!not initialized");
    }

    /// @notice Initializes the base strategy variables, should be called together with contract deployment by a contract factory.
    function _initializeBase(
        IVaultChef _vaultchef,
        IZap _zap,
        IERC20 _underlyingToken,
        IERC20 _rewardToken
    ) internal {
        assert(!initialized); // No implementation should call _initializeBase without using the initialize modifier, hence we can assert.
        initialized = true;
        vaultchef = _vaultchef;
        zap = _zap;
        underlyingToken = _underlyingToken;
        rewardToken = _rewardToken;
    }

    /// @notice Deposits `amount` amount of underlying tokens in the underlying strategy.
    /// @dev Authority: This function must only be callable by the VaultChef.
    function deposit(uint256 amount) external override onlyVaultchef {
        _deposit(amount);
    }

    /// @notice Withdraws `amount` amount of underlying tokens to `to`.
    /// @dev Authority: This function must only be callable by the VaultChef.
    function withdraw(address to, uint256 amount)
        external
        override
        onlyVaultchef
    {
        uint256 idleUnderlying = underlyingToken.balanceOf(address(this));
        if (idleUnderlying < amount) {
            _withdraw(amount - idleUnderlying);
        }
        uint256 toWithdraw = underlyingToken.balanceOf(address(this));
        if (amount < toWithdraw) {
            toWithdraw = amount;
        }
        underlyingToken.safeTransfer(to, toWithdraw);
    }

    /// @notice Withdraws all funds from the underlying staking contract into the strategy.
    /// @dev This should ideally always work (eg. emergencyWithdraw instead of a normal withdraw on masterchefs).
    function panic() external override onlyVaultchef {
        _panic();
    }

    /// @notice Harvests the reward token from the underlying protocol, converts it to underlying tokens and deposits it again.
    /// @dev The whole rewardToken balance will be converted to underlying tokens, this might include tokens send to the contract by accident.
    /// @dev There is no way to exploit this, even when reward and earned tokens are identical since the vaultchef does not allow harvesting after a panic occurs.
    function harvest() external override onlyVaultchef {
        _harvest();

        if (rewardToken != underlyingToken) {
            uint256 rewardBalance = rewardToken.balanceOf(address(this));
            if (rewardBalance > 0) {
                rewardToken.approve(address(zap), rewardBalance);
                zap.swapERC20Fast(rewardToken, underlyingToken, rewardBalance);
            }
        }
        uint256 toDeposit = underlyingToken.balanceOf(address(this));
        if (toDeposit > 0) {
            _deposit(toDeposit);
        }
    }

    /// @notice Withdraws stuck ERC-20 tokens inside the strategy contract, cannot be staking or underlying.
    function inCaseTokensGetStuck(
        IERC20 token,
        uint256 amount,
        address to
    ) external override onlyVaultchef {
        require(
            token != underlyingToken && token != rewardToken,
            "invalid token"
        );
        require(!isTokenProhibited(token), "token prohibited");
        token.safeTransfer(to, amount);
    }

    function isTokenProhibited(IERC20) internal virtual returns(bool) {
        return false;
    }

    /// @notice Gets the total amount of tokens either idle in this strategy or staked in an underlying strategy.
    function totalUnderlying() external view override returns (uint256) {
        return underlyingToken.balanceOf(address(this)) + _totalStaked();
    }

    /// @notice Gets the total amount of tokens either idle in this strategy or staked in an underlying strategy and only the tokens actually staked.
    function totalUnderlyingAndStaked()
        external
        view
        override
        returns (uint256 _totalUnderlying, uint256 _totalUnderlyingStaked)
    {
        uint256 totalStaked = _totalStaked();
        return (
            underlyingToken.balanceOf(address(this)) + totalStaked,
            totalStaked
        );
    }

    ///** INTERFACE FOR IMPLEMENTATIONS **/

    /// @notice Should withdraw all staked funds to the strategy.
    function _panic() internal virtual;

    /// @notice Should harvest all earned rewardTokens to the strategy.
    function _harvest() internal virtual;

    /// @notice Should deposit `amount` from the strategy into the staking contract.
    function _deposit(uint256 amount) internal virtual;

    /// @notice Should withdraw `amount` from the staking contract, it is okay if there is a transfer tax and less is actually received.
    function _withdraw(uint256 amount) internal virtual;

    /// @notice Should withdraw `amount` from the staking contract, it is okay if there is a transfer tax and less is actually received.
    function _totalStaked() internal view virtual returns (uint256);
}

// File contracts/strategies/StrategyPancakeSwap.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;


contract StrategyPancakeSwap is BaseStrategy {
    IPancakeSwapMC public masterchef;
    uint256 public pid;

    address deployer;

    constructor() {
        deployer = msg.sender;
    }

    function initialize(
        IVaultChef _vaultchef,
        IZap _zap,
        IERC20 _underlyingToken,
        IERC20 _rewardToken,
        IPancakeSwapMC _masterchef,
        uint256 _pid
    ) external initializer {
        require(msg.sender == deployer);
        _initializeBase(_vaultchef, _zap, _underlyingToken, _rewardToken);

        masterchef = _masterchef;
        pid = _pid;
    }

    function _panic() internal override {
        masterchef.emergencyWithdraw(pid);
    }

    function _harvest() internal override {
        masterchef.deposit(pid, 0);
    }

    function _deposit(uint256 amount) internal override {
        underlyingToken.approve(address(masterchef), amount);
        masterchef.deposit(pid, amount);
    }

    function _withdraw(uint256 amount) internal override {
        masterchef.withdraw(pid, amount);
    }

    function _totalStaked() internal view override returns (uint256) {
        (uint256 amount, ) = masterchef.userInfo(pid, address(this));
        return amount;
    }
}