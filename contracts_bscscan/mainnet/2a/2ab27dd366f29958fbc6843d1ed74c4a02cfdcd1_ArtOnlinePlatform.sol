/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

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



contract Initializable {
  bool inited = false;

  modifier initializer() {
    require(!inited, "already inited");
    _;
    inited = true;
  }
}



contract EIP712Base is Initializable {
  struct EIP712Domain {
      string name;
      string version;
      address verifyingContract;
      bytes32 salt;
  }

  string constant public ERC712_VERSION = "1";

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
    bytes(
      "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
    )
  );
  bytes32 internal domainSeperator;

  // supposed to be called once while initializing.
  // one of the contractsa that inherits this contract follows proxy pattern
  // so it is not possible to do this in a constructor
  function _initializeEIP712(string memory name) internal initializer {
    _setDomainSeperator(name);
  }

  function _setDomainSeperator(string memory name) internal {
    domainSeperator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(ERC712_VERSION)),
        address(this),
        bytes32(getChainId())
      )
    );
  }

  function getDomainSeperator() public view returns (bytes32) {
      return domainSeperator;
  }

  function getChainId() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * Accept message hash and returns hash message in EIP712 compatible form
   * So that it can be used to recover signer from signature signed using EIP712 formatted data
   * https://eips.ethereum.org/EIPS/eip-712
   * "\\x19" makes the encoding deterministic
   * "\\x01" is the version byte to make it compatible to EIP-191
   */
  function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
  return
    keccak256(
      abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
    );
  }
}




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





interface IArteon {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




contract ArtOnlinePlatformStorage is AccessControl {
  address internal _artOnline;

  bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
  bytes32 public constant COMMUNITY_ROLE = keccak256("COMMUNITY_ROLE");

  uint256 internal _blockTime = 60;
  string internal _uri;
  uint internal unlocked = 1;

  struct Listing {
    uint256 price;
    uint256 listed;
  }
  string[] public tokens;
  uint256[] public listings;

  mapping(uint256 => uint256) internal _totalMiners;
  mapping(uint256 => uint256[]) public _auctions;
  mapping(uint256 => uint256) internal _maxReward;
  mapping(uint256 => mapping(address => uint256)) internal _balances;
  mapping(address => mapping(address => bool)) internal _operatorApprovals;
  // _miners[id][address] = balance
  mapping(uint256 => mapping(address => uint256)) internal _miners;

  mapping(uint256 => mapping(uint256 => uint256)) internal _mining;
  mapping(uint256 => mapping(uint256 => address)) internal _owners;
  mapping(uint256 => mapping(address => uint256)) internal _rewards;
  mapping(uint256 => mapping(address => uint256)) internal _startTime;
  mapping(uint256 => uint256) internal _totalSupply;
  mapping(uint256 => uint256) internal _halvings;
  mapping(uint256 => uint256) internal _nextHalving;
  mapping(address => uint256) internal _blacklist;

  mapping(uint256 => Listing) public lists;
  mapping(uint256 => mapping(uint256 => Listing)) public auctions;
  mapping(string => uint256) tokenIds;
  mapping(string => uint256) tokenDecimals;
  mapping(uint256 => uint256) internal _cap;

  event AddToken(string name, uint256 decimals, uint256 id);
  event AddPool(string name, uint256 id);
  event List(uint256 id, uint256 tokenId, uint256 price);
  event Delist(uint256 id, uint256 tokenId);
  event Sold(uint256 id, uint256 tokenId, address owner, uint256 price);
  event Activate(address indexed account, uint256 id, uint256 tokenId);
  event Deactivate(address indexed account, uint256 id, uint256 tokenId);
  event Reward(address account, uint256 id, uint256 reward);
}















contract ArtOnlinePlatform is Context, ERC165, EIP712Base, IERC1155, IERC1155MetadataURI, Pausable, ArtOnlinePlatformStorage {
  using Address for address;

  modifier isListed(uint256 id, uint256 tokenId) {
    if (tokenId == 0) {
      require(lists[id].listed == 1, 'NOT_LISTED');
    } else {
      require(auctions[id][tokenId].listed == 1, 'NOT_AUCTIONED');
    }
    _;
  }

  modifier isWhiteListed(address account) {
    require(_blacklist[account] == 0, 'BLACKLISTED');
    _;
  }

  modifier lock() {
    require(unlocked == 1, 'LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  constructor(string memory uri_) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MINT_ROLE, _msgSender());
    _setupRole(COMMUNITY_ROLE, _msgSender());
    _uri = uri_;
    _initializeEIP712('Arteon Platform');
  }

  function setArtOnline(address artonline_) external onlyRole(DEFAULT_ADMIN_ROLE) lock {
    _artOnline = artonline_;
  }

  function artOnline() external view virtual returns (address) {
    return _artOnline;
  }

  function cap(uint256 id) external view virtual returns (uint256) {
    return _cap[id];
  }

  function mining(uint256 id, uint256 tokenId) external view virtual returns (uint256) {
    return _mining[id][tokenId];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function uri(uint256) public view virtual override returns (string memory) {
    return _uri;
  }

  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0), "balance query for the zero address");
    return _balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
  public
  view
  virtual
  override
  returns (uint256[] memory) {
    require(accounts.length == ids.length, "accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
        batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_msgSender() != operator, "setting approval status for self");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  function safeTransferFrom(
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes memory data
  ) public virtual override isWhiteListed(from) isWhiteListed(to) {
    require(
        from == _msgSender() || isApprovedForAll(from, _msgSender()),
        "caller is not owner nor approved"
    );
    _safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) public virtual override isWhiteListed(from) isWhiteListed(to) {
    require(
        from == _msgSender() || isApprovedForAll(from, _msgSender()),
        "transfer caller is not owner nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _safeTransferFrom(
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes memory data
  ) internal virtual {
    require(to != address(0), "transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
    _removeBalance(from, id, amount, 0);
    _addBalance(to, id, amount, 0);

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function _safeBatchTransferFrom(
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) internal virtual {
    require(ids.length == amounts.length, "ids and amounts length mismatch");
    require(to != address(0), "transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      _removeBalance(from, ids[i], amounts[i], 0);
      _addBalance(to, ids[i], amounts[i], 0);
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function totalSupply(uint256 id) public view returns (uint256) {
    return _totalSupply[id];
  }

  function addToken(string memory name, uint256 decimals, uint256 cap_) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
    require(tokenIds[name] == 0, 'token exists');
    tokens.push(name);
    uint256 id = tokens.length - 1;
    _cap[id] = cap_;
    tokenIds[name] = id;
    tokenDecimals[name] = decimals;
    emit AddToken(name, decimals, id);
  }

  function addPool(uint256 id, uint256 maxReward, uint256 halving) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _maxReward[id] = maxReward;
    _halvings[id] = halving;
    unchecked {
      _nextHalving[id] = block.number + halving;
    }
    emit AddPool(tokens[id], id);
  }

  function mint(address to, uint256 id, uint256 amount) public whenNotPaused virtual onlyRole(MINT_ROLE) {
    _mint(to, id, amount, "");
  }

  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public whenNotPaused virtual onlyRole(MINT_ROLE) {
    _mintBatch(to, ids, amounts, "");
  }

  function burn(address from, uint256 id, uint256 amount) public virtual whenNotPaused onlyRole(MINT_ROLE) {
    _burn(from, id, amount, "");
  }

  function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) public whenNotPaused virtual onlyRole(MINT_ROLE) {
    _burnBatch(from, ids, amounts, "");
  }

  function _beforeMint(address to, uint256 id, uint256 amount) internal virtual {
    require(_cap[id] >= amount, 'exceeds token cap');
    require(_owners[id][amount] == address(0), 'already exists');
    require(to != address(0), "mint to the zero address");
  }

  function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    require(to != address(0), "mint to the zero address");
    require(ids.length == amounts.length, "ids and amounts length mismatch");
    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _beforeMint(to, ids[i], amounts[i]);
      _addBalance(to, ids[i], amounts[i], 1);
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);
    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    _beforeMint(to, id, amount);
    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

    _addBalance(to, id, amount, 1);
    emit TransferSingle(operator, address(0), to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  function _addBalance(address to, uint256 id, uint256 amount, uint256 mints) internal {
    _balances[id][to] += 1;
    if (mints == 1) {
      _totalSupply[id] += 1;
    }
    _owners[id][amount] = to;
  }

  function _removeBalance(address from, uint256 id, uint256 amount, uint256 burns) internal {
    require(_owners[id][amount] == from, "not an owner");

    if (burns == 1) {
      unchecked {
        _totalSupply[id] -= 1;
      }
    }
    unchecked {
      _balances[id][from] -= 1;
    }
    _owners[id][amount] = address(0);
  }

  function _beforeTokenTransfer(
      address operator,
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
    ) internal virtual {
      for (uint256 i = 0; i < ids.length; i++) {
        if (from != address(0)) {
          uint256 id = ids[i];
          uint256 amount = amounts[i];
          require(_mining[id][amount] == 0, "DEACTIVATE_FIRST");
          require(_owners[id][amount] == from, 'not an owner');
        }
      }
    }

    function _burn(address from, uint256 id, uint256 amount, bytes memory data) internal virtual {
      require(from != address(0), "burn from the zero address");

      address operator = _msgSender();

      _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");
      _removeBalance(from, id, amount, 1);

      emit TransferSingle(operator, from, address(0), id, amount);
    }
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
      require(from != address(0), "burn from the zero address");
      require(ids.length == amounts.length, "ids and amounts length mismatch");

      address operator = _msgSender();

      _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

      for (uint256 i = 0; i < ids.length; i++) {
        _removeBalance(from, ids[i], amounts[i], 1);
      }
      emit TransferBatch(operator, from, address(0), ids, amounts);
    }

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
                revert("ERC1155Receiver rejected tokens");
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155Receiver rejected tokens");
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("transfer to non ERC1155Receiver implementer");
        }
      }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
      uint256[] memory array = new uint256[](1);
      array[0] = element;

      return array;
    }

    function _rewardPerGPU(uint256 id) internal view returns (uint256) {
      if (_totalSupply[id] == 0) {
        return 0;
      }
      return _maxReward[id] / _totalSupply[id];
    }

    function getHalvings(uint256 id) public view returns (uint256) {
      return _halvings[id];
    }

    function getNextHalving(uint256 id) public view returns (uint256) {
      return _nextHalving[id];
    }

    function rewards(address account, uint256 id) public view returns (uint256) {
      return _rewards[id][account];
    }

    function rewardPerGPU(uint256 id) public view returns (uint256) {
      return _rewardPerGPU(id);
    }

    function getMaxReward(uint256 id) public view returns (uint256) {
      return _maxReward[id];
    }

    function earned(uint256 id) public returns (uint256) {
      return _calculateReward(id);
    }

    function miners(uint256 id) public view virtual returns (uint256) {
      return _totalMiners[id];
    }

    function activateGPU(uint256 id, uint256 tokenId) public whenNotPaused isWhiteListed(msg.sender) {
      address account = msg.sender;
      require(ownerOf(id, tokenId) == account, 'NOT_OWNER');
      if (_miners[id][account] > 0) {
        getReward(id);
      }
      _activateGPU(account, id, tokenId);
      emit Activate(account, id, tokenId);
    }

    function deactivateGPU(uint256 id, uint256 tokenId) public whenNotPaused isWhiteListed(msg.sender) {
      address account = msg.sender;
      require(ownerOf(id, tokenId) == account, 'NOT_OWNER');
      getReward(id);
      _deactivateGPU(account, id, tokenId);
      emit Deactivate(account, id, tokenId);
    }

    function getReward(uint256 id) public whenNotPaused isWhiteListed(msg.sender) {
      address sender = msg.sender;
      uint256 reward = _calculateReward(id);
      if (reward > 0) {
        IArteon(_artOnline).mint(sender, reward);
        _rewards[id][sender] = 0;
        _startTime[id][sender] = block.timestamp;
        emit Reward(sender, id, reward);
      }
    }

    function _calculateReward(uint256 id) internal returns (uint256) {
      address account = msg.sender;
      uint256 startTime = _startTime[id][account];
      if (block.timestamp > startTime + _blockTime) {
        unchecked {
          uint256 remainder = block.timestamp - startTime;
          uint256 reward = _rewardPerGPU(id) * _miners[id][account];
          _rewards[id][account] = _rewards[id][account] + (reward * remainder);
        }
        _startTime[id][account] = block.timestamp;
      }
      return _rewards[id][account];
    }

    function _activateGPU(address account, uint256 id, uint256 tokenId) internal {
      require(tokenId > 0, "Activate at least one");
      unchecked {
        _startTime[id][account] = block.timestamp;
        _miners[id][account] += 1;
      }
      _mining[id][tokenId] = 1;
      _totalMiners[id] += 1;
      _checkHalving(id);
      _rewardPerGPU(id);
    }

    function _deactivateGPU(address account, uint256 id, uint256 tokenId) internal {
      unchecked {
        _miners[id][account] -= 1;
        _totalMiners[id] -= 1;
      }
      if (_miners[id][account] == 0) {
        _mining[id][tokenId] = 0;
        delete _startTime[id][account];
      } else {
        _startTime[id][account] = block.timestamp;
      }
      _checkHalving(id);
      _rewardPerGPU(id);
    }

    function _checkHalving(uint256 id) internal {
      uint256 blockHeight = block.number;
      if (blockHeight > _nextHalving[id]) {
        unchecked {
          _nextHalving[id] += _halvings[id];
          _maxReward[id] = _maxReward[id] / 2;
        }
      }
    }

    function ownerOf(uint256 id, uint256 tokenId) public view virtual returns (address) {
      address owner = _owners[id][tokenId];
      require(owner != address(0), "NONEXISTENT_TOKEN");
      return owner;
    }

    function tokensLength() external view returns (uint256) {
      return tokens.length;
    }

    function listingLength() external view returns (uint256) {
      return listings.length;
    }

    function AuctionLength(uint256 id) external view returns (uint256) {
      return _auctions[id].length;
    }

    function list(uint256 id, uint256 tokenId, uint256 price) external whenNotPaused isWhiteListed(msg.sender) lock {
      if (tokenId == 0) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'NOT_AN_ADMIN');
        require(lists[id].listed == 0, 'LISTING_EXISTS');
        listings.push(id);
        lists[id].price = price;
        lists[id].listed = 1;

        emit List(id, tokenId, price);
      } else {
        require(auctions[id][tokenId].listed == 0, 'LISTING_EXISTS');
        require(ownerOf(id, tokenId) == msg.sender, 'NOT_AN_OWNER');

        _auctions[id].push(tokenId);
        auctions[id][tokenId].price = price;
        auctions[id][tokenId].listed = 1;

        emit List(id, tokenId, price);
      }
    }

    function forceDelist(uint256 id, uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
      __removeAuction(id, tokenId);
    }

    function delist(uint256 id, uint256 tokenId) external whenNotPaused {
      _removeAuction(id, tokenId, msg.sender);
    }

    function _removeAuction(uint256 id, uint256 tokenId, address owner) internal {
      require(ownerOf(id, tokenId) == owner, 'NOT_AN_OWNER');
      __removeAuction(id, tokenId);
    }

    function __removeAuction(uint256 id, uint256 tokenId) internal {
      auctions[id][tokenId].listed = 0;
      emit Delist(id, tokenId);
    }

    function _mintAsset(address to, uint256 id) internal returns (uint256) {
      uint256 tokenId = _totalSupply[id] + 1;
      _mint(to, id, tokenId, "");
      return tokenId;
    }

    function buy(uint256 id, uint256 tokenId) external whenNotPaused isListed(id, tokenId) isWhiteListed(msg.sender) {
      address owner;
      uint256 price;
      if (tokenId == uint256(0)) {
        owner = address(this);
        price = lists[id].price;
      } else {
        owner = ownerOf(id, tokenId);
        price = auctions[id][tokenId].price;
      }
      address account = msg.sender;
      require(owner != account, 'SELLER_OWN');
      require(IERC20(_artOnline).balanceOf(account) >= price, 'NOT_ENOUGH_TOKENS');

      if (owner == address(this)) {
        IArteon(_artOnline).burn(account, price);
        tokenId = _mintAsset(account, id);
      } else {
        SafeERC20.safeTransferFrom(IERC20(_artOnline), account, owner, price);
        _safeTransferFrom(owner, account, id, tokenId, '');
        _removeAuction(id, tokenId, msg.sender);
      }
      emit Sold(id, tokenId, account, price);
    }

    function setPrice(uint256 id, uint256 tokenId, uint256 price) external whenNotPaused isListed(id, tokenId) {
      if (tokenId == 0) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) == true, 'NOT_AN_ADMIN');
        lists[id].price = price;
      } else {
        require(ownerOf(id, tokenId) == msg.sender, 'NOT_AN_OWNER');
        auctions[id][tokenId].price = price;
      }
    }

    function getPrice(uint256 id, uint256 tokenId) public view isListed(id, tokenId) returns (uint256) {
      if (tokenId == 0) {
        return lists[id].price;
      }
      return auctions[id][tokenId].price;
    }

    function pause() external virtual whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
      super._pause();
    }

    function unpause() external virtual whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
      super._unpause();
    }

    function blacklist(address account) external onlyRole(COMMUNITY_ROLE) isWhiteListed(account) {
      _blacklist[account] = 1;
    }
}