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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libs/TransactionLibrary.sol";

contract Transaction is Context, Initializable, ERC1155Holder {
    using TransactionLibrary for TransactionLibrary.TransactionStorage;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    enum AssetType {
        ERC20,
        ERC721,
        ERC1155
    }

    struct AssetInfo {
        AssetType assetType;
        uint256 amount;
        bool active;
    }

    struct NFT {
        address nftAddress;
        uint256 id;
    }

    TransactionLibrary.TransactionStorage public transactionStorage;

    mapping(address => mapping(address => AssetInfo)) useTokens;
    address[] public tokens;

    mapping(address => mapping(address => mapping(uint256 => AssetInfo))) useNfts;
    NFT[] public nfts;

    function initialize(address _initiator, address _taker) external initializer {
        require(_initiator != address(0), "Invalid address");
        require(_taker != address(0), "Invalid address");
        require(_initiator != _taker, "Taker and initiator canot be use same address");
        transactionStorage.initiator = _initiator;
        transactionStorage.taker = _taker;
    }

    /* ========== MODIFIERS =============== */

    modifier onlyInitiatorOrTaker() {
        require(
            _msgSender() == transactionStorage.initiator || _msgSender() == transactionStorage.taker,
            "Only initiator or taker can call this function"
        );
        _;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function transferNft(
        address nft,
        AssetType assetType,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        if (assetType == AssetType.ERC721) {
            IERC721(nft).safeTransferFrom(from, to, id);
        } else {
            IERC1155(nft).safeTransferFrom(from, to, id, amount, "0x0");
        }
    }

    function distribution() internal {
        // Distribution ERC20 token
        address _talker = transactionStorage.taker;
        address _initiator = transactionStorage.initiator;
        for (uint256 i; i < tokens.length; i++) {
            address _token = tokens[i];
            uint256 takerAmount = useTokens[_talker][_token].amount;
            if (takerAmount > 0) {
                useTokens[_talker][_token].amount = 0;
                IERC20(_token).safeTransfer(_initiator, takerAmount);
            }
            uint256 initiatorAmount = useTokens[_initiator][_token].amount;
            if (initiatorAmount > 0) {
                useTokens[_initiator][_token].amount = 0;
                IERC20(_token).safeTransfer(_talker, initiatorAmount);
            }
        }
        // Distribution ERC721 and ERC1155 token
        for (uint256 i; i < nfts.length; i++) {
            address _nft = nfts[i].nftAddress;
            uint256 _id = nfts[i].id;
            uint256 takerAmount = useNfts[_talker][_nft][_id].amount;
            if (takerAmount > 0) {
                useNfts[_talker][_nft][_id].amount = 0;
                transferNft(_nft, useNfts[_talker][_nft][_id].assetType, address(this), _initiator, _id, takerAmount);
            }
            uint256 initiatorAmount = useNfts[_initiator][_nft][_id].amount;
            if (initiatorAmount > 0) {
                useNfts[_initiator][_nft][_id].amount = 0;
                transferNft(
                    _nft,
                    useNfts[_initiator][_nft][_id].assetType,
                    address(this),
                    _talker,
                    _id,
                    initiatorAmount
                );
            }
        }
        emit Distribution();
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function deposit(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        address[] calldata _nfts,
        uint256[] calldata _nftIds,
        uint256[] calldata _nftAmounts,
        AssetType[] calldata _assetTypes
    ) external onlyInitiatorOrTaker {
        require(transactionStorage.isCanDepositAndWithdraw(), "User transaction status is not open");
        require(
            _tokens.length == _amounts.length &&
                _nfts.length == _nftIds.length &&
                _nfts.length == _assetTypes.length &&
                _nfts.length == _nftAmounts.length,
            "!length"
        );
        // Deposit ERC20 token
        for (uint256 i; i < _tokens.length; i++) {
            address _token = _tokens[i];
            uint256 _amount = _amounts[i];
            require(_token != address(0), "Invalid address");
            require(_amounts[i] > 0, "Cannot deposit zero amount");
            if (useTokens[_msgSender()][_token].active) {
                useTokens[_msgSender()][_token].amount += _amount;
            } else {
                tokens.push(_token);
                useTokens[_msgSender()][_token] = AssetInfo(AssetType.ERC20, _amount, true);
            }
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
            emit Deposit(_msgSender(), _token, _amount);
        }
        // Deposit ERC721 and ERC1155 token
        for (uint256 i; i < _nfts.length; i++) {
            address _nft = _nfts[i];
            uint256 _id = _nftIds[i];
            uint256 _amount = _nftAmounts[i];
            AssetType _type = _assetTypes[i];
            require(_nft != address(0), "Invalid address");
            if (useNfts[_msgSender()][_nft][_id].active) {
                useNfts[_msgSender()][_nft][_id].amount += _amount;
            } else {
                nfts.push(NFT(_nft, _id));
                useNfts[_msgSender()][_nft][_id] = AssetInfo(_type, _amount, true);
            }
            transferNft(_nft, _type, _msgSender(), address(this), _id, _amount);
            emit DepositNFT(_msgSender(), _nft, _id, _type, _amount);
        }
    }

    function withdraw(
        address[] calldata _tokens,
        uint256[] calldata _amounts,
        address[] calldata _nfts,
        uint256[] calldata _nftIds,
        uint256[] calldata _nftAmounts,
        AssetType[] calldata _assetTypes
    ) external onlyInitiatorOrTaker {
        require(transactionStorage.isCanDepositAndWithdraw(), "User transaction status is not open");
        require(
            _tokens.length == _amounts.length &&
                _nfts.length == _nftIds.length &&
                _nfts.length == _assetTypes.length &&
                _nfts.length == _nftAmounts.length,
            "!length"
        );
        // Withdraw ERC20 token
        for (uint256 i; i < _tokens.length; i++) {
            address _token = _tokens[i];
            uint256 _amount = _amounts[i];
            require(_token != address(0), "Invalid address");
            require(useTokens[_msgSender()][_token].active, "Token not exits");
            uint256 maxWithdrawAmount = _amount <= useTokens[_msgSender()][_token].amount
                ? _amount
                : useTokens[_msgSender()][_token].amount;
            require(maxWithdrawAmount > 0, "Insufficient balance");
            useTokens[_msgSender()][_token].amount -= maxWithdrawAmount;
            IERC20(_token).safeTransfer(_msgSender(), maxWithdrawAmount);
            emit Withdraw(_msgSender(), _token, maxWithdrawAmount);
        }
        // Withdraw ERC721 and ERC1155 token
        for (uint256 i; i < _nfts.length; i++) {
            address _nft = _nfts[i];
            uint256 _id = _nftIds[i];
            uint256 _amount = _nftAmounts[i];
            AssetType _type = _assetTypes[i];
            require(_nft != address(0), "Invalid address");
            require(useNfts[_msgSender()][_nft][_id].active, "NFT not exits");
            uint256 maxWithdrawAmount = _amount <= useNfts[_msgSender()][_nft][_id].amount
                ? _amount
                : useNfts[_msgSender()][_nft][_id].amount;
            require(maxWithdrawAmount > 0, "Insufficient balance");
            useNfts[_msgSender()][_nft][_id].amount -= maxWithdrawAmount;
            transferNft(_nft, _type, address(this), _msgSender(), _id, maxWithdrawAmount);
            emit WithdrawNFT(_msgSender(), _nft, _id, _type, maxWithdrawAmount);
        }
    }

    function exit() external onlyInitiatorOrTaker {
        require(transactionStorage.isCanExitTransaction(), "!rejected");
        // Exit ERC20 token
        for (uint256 i; i < tokens.length; i++) {
            address _token = tokens[i];
            uint256 amount = useTokens[_msgSender()][_token].amount;
            if (amount > 0) {
                useTokens[_msgSender()][_token].amount = 0;
                IERC20(_token).safeTransfer(_msgSender(), amount);
            }
        }
        // Exit ERC721 and ERC1155 token
        for (uint256 i; i < nfts.length; i++) {
            address _nft = nfts[i].nftAddress;
            uint256 _id = nfts[i].id;
            uint256 amount = useNfts[_msgSender()][_nft][_id].amount;
            if (amount > 0) {
                useNfts[_msgSender()][_nft][_id].amount = 0;
                transferNft(_nft, useNfts[_msgSender()][_nft][_id].assetType, address(this), _msgSender(), _id, amount);
            }
        }
        transactionStorage.updateSenderStatusIsOpen();
        emit Exit(_msgSender());
    }

    function lock() external onlyInitiatorOrTaker {
        return transactionStorage.lock();
    }

    function unlock() external onlyInitiatorOrTaker {
        return transactionStorage.unlock();
    }

    function confirm() external onlyInitiatorOrTaker {
        transactionStorage.confirm();
        if (transactionStorage.isCanDistribution()) {
            distribution();
        }
    }

    function reject() external onlyInitiatorOrTaker {
        return transactionStorage.reject();
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getInitiator() external view returns (address) {
        return transactionStorage.initiator;
    }

    function getTaker() external view returns (address) {
        return transactionStorage.taker;
    }

    function getInitiatorStatus() external view returns (uint256) {
        return uint256(transactionStorage.initiatorStatus);
    }

    function getTakerStatus() external view returns (uint256) {
        return uint256(transactionStorage.takerStatus);
    }

    /* =============== EVENTS ==================== */

    event Deposit(address indexed user, address token, uint256 amount);
    event Withdraw(address indexed user, address token, uint256 amount);
    event DepositNFT(address indexed user, address token, uint256 id, AssetType assetType, uint256 amount);
    event WithdrawNFT(address indexed user, address token, uint256 id, AssetType assetType, uint256 amount);
    event Exit(address indexed user);
    event Distribution();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITransaction.sol";
import "./Transaction.sol";

contract TransactionFactory is Ownable {
    address[] public transactions;
    mapping(address => address[]) public initiatorTransactions;
    mapping(address => address[]) public takerTransactions;

    /* ========== PUBLIC FUNCTIONS ========== */

    function createTransaction(address _taker) external returns (address transaction) {
        require(_taker != address(0), "Invalid address");
        require(_msgSender() != _taker, "Taker and initiator canot be use same address");
        bytes memory bytecode = type(Transaction).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));
        assembly {
            transaction := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(transaction)) {
                revert(0, 0)
            }
        }
        ITransaction(transaction).initialize(_msgSender(), _taker);
        transactions.push(transaction);
        initiatorTransactions[_msgSender()].push(transaction);
        takerTransactions[_taker].push(transaction);
        emit CreateTransaction(_msgSender(), transaction);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getInitiatorTransactionsPagination(
        address _user,
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory, uint256) {
        uint256 length = size;
        if (length > initiatorTransactions[_user].length - cursor) {
            length = initiatorTransactions[_user].length - cursor;
        }
        address[] memory values = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = initiatorTransactions[_user][cursor + i];
        }
        return (values, cursor + length);
    }

    function getTalkerTransactionsPagination(
        address _user,
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory, uint256) {
        uint256 length = size;
        if (length > takerTransactions[_user].length - cursor) {
            length = takerTransactions[_user].length - cursor;
        }
        address[] memory values = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = takerTransactions[_user][cursor + i];
        }
        return (values, cursor + length);
    }

    /* =============== EVENTS ==================== */

    event CreateTransaction(address indexed user, address transaction);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface ITransaction {
    function initialize(address _initiator, address _taker) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

library TransactionLibrary {
    enum UserStatus {
        OPEN,
        LOCKED,
        CONFIRMED,
        REJECTED
    }

    struct TransactionStorage {
        address initiator;
        address taker;
        UserStatus initiatorStatus;
        UserStatus takerStatus;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function getSenderStatus(TransactionStorage storage self) internal view returns (UserStatus) {
        if (msg.sender == self.initiator) {
            return self.initiatorStatus;
        } else {
            return self.takerStatus;
        }
    }

    function isCanDepositAndWithdraw(TransactionStorage storage self) internal view returns (bool) {
        return getSenderStatus(self) == UserStatus.OPEN;
    }

    function isCanExitTransaction(TransactionStorage storage self) internal view returns (bool) {
        UserStatus _status;
        if (msg.sender == self.initiator) {
            _status = self.takerStatus;
        } else {
            _status = self.initiatorStatus;
        }
        return _status == UserStatus.REJECTED;
    }

    function isCanDistribution(TransactionStorage storage self) internal view returns (bool) {
        return (self.initiatorStatus == UserStatus.CONFIRMED && self.takerStatus == UserStatus.CONFIRMED);
    }

    function updateSenderStatusIsOpen(TransactionStorage storage self) internal {
        if (msg.sender == self.initiator) {
            self.initiatorStatus = UserStatus.OPEN;
        } else {
            self.takerStatus = UserStatus.OPEN;
        }
    }

    function lock(TransactionStorage storage self) internal {
        if (msg.sender == self.initiator) {
            require(self.initiatorStatus == UserStatus.OPEN, "Initiator transaction status required open");
            self.initiatorStatus = UserStatus.LOCKED;
        } else {
            require(self.takerStatus == UserStatus.OPEN, "Taker transaction status required open");
            self.takerStatus = UserStatus.LOCKED;
        }
        emit Lock(msg.sender);
    }

    function unlock(TransactionStorage storage self) internal {
        if (msg.sender == self.initiator) {
            require(
                self.initiatorStatus == UserStatus.LOCKED ||
                    (self.initiatorStatus == UserStatus.CONFIRMED && self.takerStatus == UserStatus.OPEN),
                "Transaction status not allowed"
            );
            self.initiatorStatus = UserStatus.OPEN;
            if (self.takerStatus != UserStatus.OPEN && self.takerStatus != UserStatus.REJECTED) {
                self.takerStatus = UserStatus.OPEN;
            }
        } else {
            require(
                self.takerStatus == UserStatus.LOCKED ||
                    (self.takerStatus == UserStatus.CONFIRMED && self.initiatorStatus == UserStatus.OPEN),
                "Transaction status not allowed"
            );
            self.takerStatus = UserStatus.OPEN;
            if (self.initiatorStatus != UserStatus.OPEN && self.initiatorStatus != UserStatus.REJECTED) {
                self.initiatorStatus = UserStatus.OPEN;
            }
        }
        emit Unlock(msg.sender);
    }

    function confirm(TransactionStorage storage self) internal {
        if (msg.sender == self.initiator) {
            require(self.initiatorStatus == UserStatus.LOCKED, "Initiator transaction status must not be locked");
            self.initiatorStatus = UserStatus.CONFIRMED;
        } else {
            require(self.takerStatus == UserStatus.LOCKED, "Taker transaction status must not be locked");
            self.takerStatus = UserStatus.CONFIRMED;
        }
        emit Confirm(msg.sender);
    }

    function reject(TransactionStorage storage self) internal {
        if (msg.sender == self.initiator) {
            require(self.initiatorStatus == UserStatus.LOCKED, "Initiator transaction status must not be locked");
            self.initiatorStatus = UserStatus.REJECTED;
        } else {
            require(self.takerStatus == UserStatus.LOCKED, "Taker transaction status must not be locked");
            self.takerStatus = UserStatus.REJECTED;
        }
        emit Reject(msg.sender);
    }

    /* =============== EVENTS ==================== */

    event Lock(address indexed user);
    event Unlock(address indexed user);
    event Confirm(address indexed user);
    event Reject(address indexed user);
}