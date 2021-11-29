/**
 *Submitted for verification at FtmScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIXED

// File @openzeppelin/contracts/token/ERC20/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File @openzeppelin/contracts/utils/introspection/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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

// File @openzeppelin/contracts/token/ERC1155/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File @openzeppelin/contracts/token/ERC1155/extensions/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File @openzeppelin/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File @openzeppelin/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File @openzeppelin/contracts/utils/introspection/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File contracts/dependencies/ERC1155.sol
// License-Identifier: MIT
// Derived from openzeppeling ERC1155 without acceptance hooks on mints

pragma solidity ^0.8.0;






/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(from != address(0), "ERC1155: transfer from the zero address");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(from != address(0), "ERC1155: transfer from the zero address");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value. [ DISABLED ]
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);
        // DISABLED:
        // _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);
        // DISABLED:
        //_doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File contracts/dependencies/ERC1155Supply.sol
// License-Identifier: MIT
// Copy of ERC1155Supply using ./ERC1155 which omits the reentrancy hook on mints.
pragma solidity ^0.8.4;

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}

// File contracts/dependencies/Ownable.sol
// License-Identifier: MIT

// Derived from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/1b27c13096d6e4389d62e7b0766a1db53fbb3f1b/contracts/access/Ownable.sol
// Adds pending owner

pragma solidity ^0.8.0;

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
    address public pendingOwner;

    event PendingOwnershipTransferred(address indexed previousPendingOwner, address indexed newPendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to the pendingOwner.
     * Can only be called by the pendingOwner.
     */
    function transferOwnership() public virtual {
        require(_msgSender() == pendingOwner, "Ownable: caller is not the pendingOwner");
        require(pendingOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(pendingOwner);
    }

    /**
     * @dev Sets the pendingOwner, ownership is only transferred when they call transferOwnership.
     * Can only be called by the current owner.
     */
    function setPendingOwner(address newPendingOwner) external onlyOwner {
        address oldPendingOwner = pendingOwner;
        pendingOwner = newPendingOwner;

        emit PendingOwnershipTransferred(oldPendingOwner, pendingOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
    function vaultInfo(uint256 vaultId) external returns (Vault memory);

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

// File contracts/interfaces/IPullDepositor.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPullDepositor {
    /**
     * @notice Called by a contract requesting tokens, with the aim of the PullDepositor implementing contract to send these tokens.
     * @dev This interface allows for an alternative flow compared to the traditional transferFrom flow.
     * @dev This flow is especially useful when in combination with a zapping contract.
     */
    function pullTokens(
        IERC20 token,
        uint256 amount,
        address to
    ) external;
}

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// File @openzeppelin/contracts/security/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File contracts/vaultchef/VaultChefCore.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;









/**
 * @title VaultChefCore
 * @notice A vault management contract that manages vaults, their strategies and the share positions of investors in these vaults.
 * @notice Documentation is present in the IVaultChefCore interface.
 */
contract VaultChefCore is
    ERC1155Supply,
    IVaultChefCore,
    Ownable,
    ReentrancyGuard
{
    using Address for address;
    using SafeERC20 for IERC20;

    /// @notice The list of all registered vaults.
    Vault[] internal vaults;

    /// @notice The maximum performance fee settable. This is the % of the harvests that are minted to the owner.
    uint256 private constant MAX_PERFORMANCE_FEE_BP = 1000;

    /// @notice The set of contracts that allow for pull-based deposits. Unnecessary but trims down privileges further.
    mapping(address => bool) public canDoPullDeposits;

    event VaultAdded(
        uint256 indexed vaultId,
        IStrategy indexed strategy,
        uint256 performanceFeeBP
    );
    event VaultPerformanceFeeSet(
        uint256 indexed vaultId,
        uint256 performanceFeeBP
    );
    event VaultPaused(uint256 indexed vaultId, bool paused);
    event VaultPanicked(uint256 indexed vaultId);
    event VaultHarvest(uint256 indexed vaultId, uint256 underlyingIncrease);
    event VaultInCaseTokenStuck(
        uint256 indexed vaultId,
        IERC20 indexed token,
        address indexed to,
        uint256 amount
    );
    event URIUpdated(string oldURI, string newURI);
    event InCaseTokenStuck(
        IERC20 indexed token,
        address indexed to,
        uint256 amount
    );

    event Deposit(
        uint256 indexed vaultId,
        address indexed user,
        uint256 sharesAmount,
        uint256 underlyingAmountReceived
    );
    event Withdraw(
        uint256 indexed vaultId,
        address indexed user,
        address indexed receiver,
        uint256 sharesAmount,
        uint256 underlyingAmountReceived
    );

    event PullDepositorSet(address indexed depositor, bool indexed allowPulls);

    constructor() ERC1155("https://violin.finance/api/vaults/{id}.json") {}

    modifier validVault(uint256 vaultId) {
        require(vaultId < vaults.length, "!no vault");
        _;
    }

    //** USER FUNCTIONS *//

    function depositUnderlying(
        uint256 vaultId,
        uint256 underlyingAmount,
        bool pulled,
        uint256 minSharesReceived
    )
        public
        virtual
        override
        validVault(vaultId)
        nonReentrant
        returns (uint256 sharesReceived)
    {
        _harvest(vaultId);
        Vault memory vault = vaults[vaultId];
        require(!vault.paused, "!paused");

        // Variables for shares calculation.
        uint256 totalSharesBefore = totalSupply(vaultId);
        (uint256 underlyingBefore, uint256 stakedBefore) = vault
            .strategy
            .totalUnderlyingAndStaked();

        // Transfer in the funds from the msg.sender to the strategy contract.
        underlyingAmount = _transferInFunds(
            vault.underlyingToken,
            address(vault.strategy),
            underlyingAmount,
            pulled
        );

        // Make the strategy stake the received funds.
        vault.strategy.deposit(underlyingAmount);

        (uint256 underlyingAfter, uint256 stakedAfter) = vault
            .strategy
            .totalUnderlyingAndStaked();
        underlyingAmount = stakedAfter - stakedBefore;

        // Mint shares according to the actually received underlyingAmount, based on the share value before deposit.
        uint256 shares = totalSharesBefore != 0 && underlyingBefore != 0
            ? (underlyingAmount * totalSharesBefore) / underlyingBefore
            : underlyingAmount;
        _mint(msg.sender, vaultId, shares, ""); // Reentrancy hook has been removed from our ERC-1155 implementation (only modification).

        // Gas optimized non-decreasing share value requirement (see nonDecreasingShareValue). Marked as assert as we could not find any way to fail this.
        assert(
            underlyingAfter * totalSharesBefore >=
                underlyingBefore * totalSupply(vaultId) ||
                totalSharesBefore == 0
        );
        // We require the total underlying in the vault to be within reasonable bounds to prevent mulDiv overflow on withdrawal (1e34^2 is still 9 magnitudes smaller than type(uint256).max).
        // Using https://github.com/Uniswap/v3-core/blob/2ac90dd32184f4c5378b19a08bce79492ea23d37/contracts/libraries/FullMath.sol would be a better alternative but goes against our simplicity principle.
        require(underlyingAfter <= 1e34, "!unsafe");
        require(shares >= minSharesReceived, "!min not received");
        require(shares > 0, "!zero shares");
        emit Deposit(vaultId, msg.sender, shares, underlyingAmount);
        return shares;
    }

    function withdrawShares(
        uint256 vaultId,
        uint256 shares,
        uint256 minReceived
    )
        public
        virtual
        override
        validVault(vaultId)
        nonDecreasingShareValue(vaultId)
        nonReentrant
        returns (uint256 underlyingReceived)
    {
        return _withdrawSharesTo(vaultId, shares, minReceived, msg.sender);
    }

    function withdrawSharesTo(
        uint256 vaultId,
        uint256 shares,
        uint256 minReceived,
        address to
    )
        public
        virtual
        override
        validVault(vaultId)
        nonDecreasingShareValue(vaultId)
        nonReentrant
        returns (uint256 underlyingReceived)
    {
        // Withdrawing to another wallet should only be done by zapping contracts thus we can add a phishing measure.
        require(address(msg.sender).isContract(), "!to phishing");
        return _withdrawSharesTo(vaultId, shares, minReceived, to);
    }

    /// @notice isValidVault is implicit through nonDecreasingShareValue (gas optimization).
    function _withdrawSharesTo(
        uint256 vaultId,
        uint256 shares,
        uint256 minReceived,
        address to
    ) internal returns (uint256 underlyingReceived) {
        require(
            balanceOf(msg.sender, vaultId) >= shares,
            "!insufficient shares"
        );
        require(shares > 0, "!zero shares");
        Vault memory vault = vaults[vaultId];

        uint256 withdrawAmount = (shares * vault.strategy.totalUnderlying()) /
            totalSupply(vaultId);
        _burn(msg.sender, vaultId, shares);

        uint256 balanceBefore = vault.underlyingToken.balanceOf(to);
        vault.strategy.withdraw(to, withdrawAmount);
        withdrawAmount = vault.underlyingToken.balanceOf(to) - balanceBefore;

        require(withdrawAmount >= minReceived, "!min not received");
        emit Withdraw(vaultId, msg.sender, to, shares, withdrawAmount);
        return withdrawAmount;
    }

    /// @notice Transfers in tokens from the `msg.sender` to `to`. Returns the actual receivedAmount that can be both lower and higher.
    /// @param pulled Whether to use a pulled-based mechanism.
    /// @dev Requires reentrancy-guard and no way for the staked funds to be sent back into the strategy within the before-after.
    function _transferInFunds(
        IERC20 token,
        address to,
        uint256 underlyingAmount,
        bool pulled
    ) internal returns (uint256 receivedAmount) {
        uint256 beforeBal = token.balanceOf(to);
        if (!pulled) {
            token.safeTransferFrom(msg.sender, to, underlyingAmount);
        } else {
            require(canDoPullDeposits[msg.sender], "!whitelist");
            IPullDepositor(msg.sender).pullTokens(token, underlyingAmount, to);
        }
        return token.balanceOf(to) - beforeBal;
    }

    //** GOVERNANCE FUNCTIONS *//

    /// @dev nonDecreasingUnderlyingValue(vaultId) omitted since it is implicitly defined.
    function harvest(uint256 vaultId)
        public
        virtual
        override
        validVault(vaultId)
        nonReentrant
        returns (uint256 underlyingIncrease)
    {
        require(!vaults[vaultId].paused, "!paused");
        return _harvest(vaultId);
    }

    /// @dev Gas optimization: Implicit nonDecreasingShareValue due to no supply change within _harvest (reentrancyGuards guarantee this).
    /// @dev Gas optimization: Implicit nonDecreasingUnderlyingValue check due to before-after underflow.
    function _harvest(uint256 vaultId)
        internal
        returns (uint256 underlyingIncrease)
    {
        Vault storage vault = vaults[vaultId];
        IStrategy strategy = vault.strategy;

        uint256 underlyingBefore = strategy.totalUnderlying();
        strategy.harvest();
        uint256 underlyingAfter = strategy.totalUnderlying();
        underlyingIncrease = underlyingAfter - underlyingBefore;

        vault.lastHarvestTimestamp = uint96(block.timestamp);

        // The performance fee is minted to the owner in shares to reduce governance risk, strategy complexity and gas fees.
        address feeRecipient = owner();
        if (underlyingIncrease > 0 && feeRecipient != address(0)) {
            uint256 performanceFeeShares = (underlyingIncrease *
                totalSupply(vaultId) *
                vault.performanceFeeBP) /
                underlyingAfter /
                10000;
            _mint(feeRecipient, vaultId, performanceFeeShares, "");
        }

        emit VaultHarvest(vaultId, underlyingIncrease);
        return underlyingIncrease;
    }

    function addVault(IStrategy strategy, uint16 performanceFeeBP)
        public
        virtual
        override
        onlyOwner
        nonReentrant
    {
        require(performanceFeeBP <= MAX_PERFORMANCE_FEE_BP, "!valid");
        vaults.push(
            Vault({
                underlyingToken: strategy.underlyingToken(),
                strategy: strategy,
                paused: false,
                panicked: false,
                lastHarvestTimestamp: 0,
                performanceFeeBP: performanceFeeBP
            })
        );
        emit VaultAdded(vaults.length - 1, strategy, performanceFeeBP);
    }

    function setVault(uint256 vaultId, uint16 performanceFeeBP)
        external
        virtual
        override
        onlyOwner
        validVault(vaultId)
        nonReentrant
    {
        require(performanceFeeBP <= MAX_PERFORMANCE_FEE_BP, "!valid");
        Vault storage vault = vaults[vaultId];
        vault.performanceFeeBP = performanceFeeBP;

        emit VaultPerformanceFeeSet(vaultId, performanceFeeBP);
    }

    function setPullDepositor(address pullDepositor, bool isAllowed)
        external
        override
        onlyOwner
        nonReentrant
    {
        require(canDoPullDeposits[pullDepositor] != isAllowed, "!set");
        canDoPullDeposits[pullDepositor] = isAllowed;
        emit PullDepositorSet(pullDepositor, isAllowed);
    }

    function panicVault(uint256 vaultId)
        external
        override
        onlyOwner
        validVault(vaultId)
        nonReentrant
    {
        Vault storage vault = vaults[vaultId];
        require(!vault.panicked, "!panicked");
        if (!vault.paused) _pauseVault(vaultId, true);
        vault.panicked = true;

        vault.strategy.panic();

        emit VaultPanicked(vaultId);
    }

    function pauseVault(uint256 vaultId, bool paused)
        external
        override
        onlyOwner
        validVault(vaultId)
        nonReentrant
    {
        _pauseVault(vaultId, paused);
    }

    /// @notice Marks the vault as paused which means no deposits or harvests can occur anymore.
    function _pauseVault(uint256 vaultId, bool paused) internal virtual {
        Vault storage vault = vaults[vaultId];
        require(!vault.panicked, "!panicked");
        require(paused != vault.paused, "!set");
        vault.paused = paused;
        emit VaultPaused(vaultId, paused);
    }

    /// @notice No staked tokens are ever sent to the VaultChef, only to the strategies.
    function inCaseTokensGetStuck(IERC20 token, address to)
        external
        override
        onlyOwner
        nonReentrant
    {
        require(to != address(0), "!zero");
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(to, amount);
        emit InCaseTokenStuck(token, to, amount);
    }

    /// @notice Although the strategy could contain underlying tokens, this function reverts if governance tries to withdraw these.
    function inCaseVaultTokensGetStuck(
        uint256 vaultId,
        IERC20 token,
        address to,
        uint256 amount
    )
        external
        override
        onlyOwner
        validVault(vaultId)
        nonReentrant
        nonDecreasingUnderlyingValue(vaultId)
    {
        require(to != address(0), "!zero");
        Vault storage vault = vaults[vaultId];
        require(token != vault.underlyingToken, "!underlying");

        vault.strategy.inCaseTokensGetStuck(token, amount, to);
        emit VaultInCaseTokenStuck(vaultId, token, to, amount);
    }

    //** VIEW FUNCTIONS *//

    /// @notice Returns whether a vault exists at the provided vault id `vaultId`.
    function isValidVault(uint256 vaultId)
        external
        view
        override
        returns (bool)
    {
        return vaultId < vaults.length;
    }

    /// @notice Returns information about the vault for the frontend to use.
    function vaultInfo(uint256 vaultId)
        public
        view
        override
        validVault(vaultId)
        returns (Vault memory)
    {
        return vaults[vaultId];
    }

    //** MODIFIERS **//

    /// @dev The nonDecreasingShareValue modifier requires the vault's share value to be nondecreasing over the operation.
    modifier nonDecreasingShareValue(uint256 vaultId) {
        uint256 supply = totalSupply(vaultId);
        IStrategy strategy = vaults[vaultId].strategy;
        uint256 underlyingBefore = strategy.totalUnderlying();
        _;
        if (supply == 0) return;
        uint256 underlyingAfter = strategy.totalUnderlying();
        uint256 newSupply = totalSupply(vaultId);
        // This is a rewrite of shareValueAfter >= shareValueBefore which also passes if newSupply is zero. ShareValue is defined as totalUnderlying/totalShares.
        require(
            underlyingAfter * supply >= underlyingBefore * newSupply,
            "!unsafe"
        );
    }

    /// @dev the nonDecreasingVaultValue modifier requires the vault's total underlying tokens to not decrease over the operation.
    modifier nonDecreasingUnderlyingValue(uint256 vaultId) {
        Vault memory vault = vaults[vaultId];
        uint256 balanceBefore = vault.strategy.totalUnderlying();
        _;
        uint256 balanceAfter = vault.strategy.totalUnderlying();
        require(balanceAfter >= balanceBefore, "!unsafe");
    }

    //** REQUIRED OVERRIDES *//
    /// @dev Due to multiple inheritance, we require to overwrite the totalSupply method.
    function totalSupply(uint256 id)
        public
        view
        override(ERC1155Supply, IVaultChefCore)
        returns (uint256)
    {
        return super.totalSupply(id);
    }
}

// File contracts/vaultchef/VaultChef.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;




/**
 * @notice The VaultChef is the wrapper of the core `VaultChefCore` logic that contains all non-essential functionality.
 * @notice It is isolated from the core functionality because all this functionality has no impact on the core functionality.
 * @notice This separation should enable third party reviewers to more easily assess the core component of the vaultchef.
 
 * @dev One of the main extensions is the added compatibility of the SushiSwap MasterChef interface, this is done to be compatible with third-party tools:
 * @dev Allocpoints have been made binary to indicate whether a vault is paused or not (1 alloc point means active, 0 means paused).
 * @dev Reward related variables are set to zero (lastRewardBlock, accTokenPerShare).
 * @dev Events are emitted on the lower level for more compatibility with third-party tools.
 * @dev EmergencyWithdraw event has been omitted intentionally since it is functionally identical to a normal withdrawal.
 * @dev There is no concept of receipt tokens on the compatibility layer, all amounts represent underlying tokens.
 *
 * @dev ERC-1155 transfers have been wrapped with nonReentrant to reduce the exploit freedom. Furthermore receipt tokens cannot be sent to the VaultChef as it does not implement the receipt interface.
 * 
 * @dev Furthermore the VaultChef implements IERC20Metadata for etherscan compatibility as it currently uses this metadata to identify ERC-1155 collection metadata.
 *
 * @dev Finally safeguards are added to the addVault function to only allow a strategy to be listed once.
 *
 * @dev For third-party reviewers: The security of this extension can be validated since no internal state is modified on the parent contract.
 */
contract VaultChef is VaultChefCore, IVaultChefWrapper {
    // ERC-20 metadata for etherscan compatibility.
    string private _name = "Violin Vault Receipt";
    string private _symbol = "vVault";
    uint8 private _decimals = 18;

    /// @notice how many vaults are not paused.
    uint256 private activeVaults;

    uint256 private immutable _startBlock;

    /// @notice mapping that returns true if the strategy is set as a vault.
    mapping(IStrategy => bool) public override strategyExists;
    /// @notice Utility mapping for UI to figure out the vault id of a strategy.
    mapping(IStrategy => uint256) public override strategyVaultId;

    event ChangeMetadata(string newName, string newSymbol, uint256 newDecimals);

    constructor(address _owner) {
        _startBlock = block.number;
        _transferOwnership(_owner);
    }

    //** MASTERCHEF COMPATIBILITY **/

    /// @notice Deposits `underlyingAmount` of underlying tokens in the vault at `vaultId`.
    /// @dev This function is identical to depositUnderlying, duplication has been permitted to match the masterchef interface.
    /// @dev Event emitted on lower level.
    function deposit(uint256 vaultId, uint256 underlyingAmount)
        public
        virtual
        override
    {
        depositUnderlying(vaultId, underlyingAmount, false, 0);
    }

    /// @notice withdraws `amount` of underlying tokens from the vault at `vaultId` to `msg.sender`.
    /// @dev Event emitted on lower level.
    function withdraw(uint256 vaultId, uint256 underlyingAmount)
        public
        virtual
        override
        validVault(vaultId)
    {
        uint256 underlyingBefore = vaults[vaultId].strategy.totalUnderlying();
        require(underlyingBefore != 0, "!empty");
        uint256 shares = (totalSupply(vaultId) * underlyingAmount) /
            underlyingBefore;
        withdrawShares(vaultId, shares, 0);
    }

    /// @notice withdraws the complete position of `msg.sender` to `msg.sender`.
    function emergencyWithdraw(uint256 vaultId)
        public
        virtual
        override
        validVault(vaultId)
    {
        uint256 shares = balanceOf(msg.sender, vaultId);
        withdrawShares(vaultId, shares, 0);
    }

    /// @notice poolInfo returns the vault information in a format compatible with the masterchef poolInfo.
    /// @dev allocPoint is either 0 or 1. Zero means paused while one means active.
    /// @dev _lastRewardBlock and _accTokenPerShare are zero since there is no concept of rewards in the VaultChef.
    function poolInfo(uint256 vaultId)
        external
        view
        override
        validVault(vaultId)
        returns (
            IERC20 _lpToken,
            uint256 _allocPoint,
            uint256 _lastRewardBlock,
            uint256 _accTokenPerShare
        )
    {
        uint256 allocPoints = vaults[vaultId].paused ? 0 : 1;
        return (vaults[vaultId].underlyingToken, allocPoints, 0, 0);
    }

    /// @notice Returns the total amount of underlying tokens a vault has under management.
    function totalUnderlying(uint256 vaultId)
        external
        view
        override
        validVault(vaultId)
        returns (uint256)
    {
        return vaults[vaultId].strategy.totalUnderlying();
    }

    /// @notice Since there is no concept of allocPoints we return the number of active vaults as allocPoints (each active vault has allocPoint 1) for MasterChef compatibility.
    function totalAllocPoint() external view override returns (uint256) {
        return activeVaults;
    }

    /// @notice Returns the number of vaults.
    function poolLength() external view override returns (uint256) {
        return vaults.length;
    }

    /// @notice the startBlock function indicates when rewards start in a masterchef, since there is no notion of rewards, it returns zero.
    /// @dev This function is kept for compatibility with third-party tools.
    function startBlock() external view override returns (uint256) {
        return _startBlock;
    }

    /// @notice userInfo returns the user their stake information about a specific vault in a format compatible with the masterchef userInfo.
    /// @dev amount represents the amount of underlying tokens.
    /// @dev _rewardDebt are zero since there is no concept of rewards in the VaultChef.
    function userInfo(uint256 vaultId, address user)
        external
        view
        override
        validVault(vaultId)
        returns (uint256 _amount, uint256 _rewardDebt)
    {
        uint256 supply = totalSupply((vaultId));
        uint256 underlyingAmount = supply == 0
            ? 0
            : (vaults[vaultId].strategy.totalUnderlying() *
                balanceOf(user, vaultId)) / supply;
        return (underlyingAmount, 0);
    }

    /** Active vault accounting for allocpoints **/

    /// @dev Add accounting for the allocPoints and also locking if the strategy already exists.
    function addVault(IStrategy strategy, uint16 performanceFeeBP)
        public
        override
    {
        require(!strategyExists[strategy], "!exists");
        strategyExists[strategy] = true;
        strategyVaultId[strategy] = vaults.length;
        activeVaults += 1;
        super.addVault(strategy, performanceFeeBP);
    }

    /// @dev _pauseVault is overridden to add accounting for the allocPoints
    /// @dev It should be noted that the first requirement is only present for auditability since it is redundant in the parent contract.
    function _pauseVault(uint256 vaultId, bool paused) internal override {
        require(paused != vaults[vaultId].paused, "!set");
        if (paused) {
            activeVaults -= 1;
        } else {
            activeVaults += 1;
        }
        super._pauseVault(vaultId, paused);
    }

    /** GOVERNANCE FUNCTIONS **/

    /// @notice ERC-20 metadata can be updated for potential rebrands, it is included for etherscan compatibility.
    function changeMetadata(
        string memory newName,
        string memory newSymbol,
        uint8 newDecimals
    ) external override onlyOwner {
        _name = newName;
        _symbol = newSymbol;
        _decimals = newDecimals;

        emit ChangeMetadata(newName, newSymbol, newDecimals);
    }

    /// @notice Override the ERC-1155 token api metadata URI, this is needed since we want to change it to include the chain slug.
    function setURI(string memory newURI) external override onlyOwner {
        string memory oldURI = uri(0);
        _setURI(newURI);

        emit URIUpdated(oldURI, newURI);
    }

    /** ERC-20 METADATA COMPATIBILITY **/

    /// @notice The name of the token collection.
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @notice The shorthand symbol of the token collection.
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @notice The amount of decimals of individual tokens.
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /** ERC-1155 nonReentrant modification to reduce risks **/

    /// @notice override safeTransferFrom with nonReentrant modifier to safeguard system properties.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override nonReentrant {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /// @notice override safeBatchTransferFrom with nonReentrant modifier to safeguard system properties.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override nonReentrant {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

// File contracts/vaultchef/WhitelistedVaultChef.sol
// License-Identifier: MIT

pragma solidity ^0.8.6;

contract WhitelistedVaultChef is VaultChef {
    mapping(address => bool) public whitelisted;
    address[] public whitelist;

    event UserWhitelisted(address indexed user);

    constructor(address _owner) VaultChef(_owner) {
        // Required for minting and burning
        _addToWhitelist(address(this));
        _addToWhitelist(address(0));
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "!not whitelisted");
        _;
    }
    function addToWhitelist(address user) public onlyOwner {
        _addToWhitelist(user);
    }


    function addMultipleToWhitelist(address[] calldata users) external onlyOwner {
        for(uint256 i = 0; i < users.length; i++) {
            _addToWhitelist(users[i]);
        }
    }


    function _addToWhitelist(address user) internal {
        require(!whitelisted[user], "!already whitelisted");
        whitelisted[user] = true;
        whitelist.push(user);

        emit UserWhitelisted(user);
    }
    function depositUnderlying(
        uint256 vaultId,
        uint256 underlyingAmount,
        bool pulled,
        uint256 minSharesReceived
    ) public override onlyWhitelisted returns (uint256 sharesReceived) {
        return super.depositUnderlying(vaultId, underlyingAmount, pulled, minSharesReceived);
    }

    function withdrawShares(
        uint256 vaultId,
        uint256 shares,
        uint256 minUnderlyingReceived
    ) public override onlyWhitelisted returns (uint256 underlyingReceived) {
        return super.withdrawShares(vaultId, shares, minUnderlyingReceived);
    }

    function withdrawSharesTo(
        uint256 vaultId,
        uint256 shares,
        uint256 minUnderlyingReceived,
        address to
    ) public override onlyWhitelisted returns (uint256 underlyingReceived) {
        require(whitelisted[to], "!to not whitelisted");
        return super.withdrawSharesTo(vaultId, shares, minUnderlyingReceived, to);
    }

    function harvest(uint256 vaultId) public override onlyWhitelisted returns (uint256 underlyingIncrease) {
        return super.harvest(vaultId);
    }

    function deposit(uint256 _pid, uint256 _amount) public override onlyWhitelisted {
        super.deposit(_pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public override onlyWhitelisted {
        super.withdraw(_pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public override onlyWhitelisted {
        super.emergencyWithdraw(_pid);
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override onlyWhitelisted {
        require(whitelisted[from], "!from not whitelisted");
        require(whitelisted[to], "!to not whitelisted");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function whitelistLength() external view returns (uint256) {
        return whitelist.length;
    }
}