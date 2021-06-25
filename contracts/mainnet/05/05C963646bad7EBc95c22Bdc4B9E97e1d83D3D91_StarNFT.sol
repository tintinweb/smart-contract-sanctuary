/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: Apache License, Version 2.0

pragma solidity 0.7.6;



// Part: Address

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

// Part: ERC165Checker

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, _INTERFACE_ID_ERC165) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // success determines whether the staticcall succeeded and result determines
        // whether the contract at account indicates support of _interfaceId
        (bool success, bool result) = _callERC165SupportsInterface(account, interfaceId);

        return (success && result);
    }

    /**
     * @notice Calls the function with selector 0x01ffc9a7 (ERC165) and suppresses throw
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return success true if the STATICCALL succeeded, false otherwise
     * @return result true if the STATICCALL succeeded and the contract at account
     * indicates support of the interface with identifier interfaceId, false otherwise
     */
    function _callERC165SupportsInterface(address account, bytes4 interfaceId)
        private
        view
        returns (bool, bool)
    {
        bytes memory encodedParams = abi.encodeWithSelector(_INTERFACE_ID_ERC165, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return (false, false);
        return (success, abi.decode(result, (bool)));
    }
}

// Part: IERC165

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

// Part: IERC20

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

// Part: SafeMath

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// Part: ERC165

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// Part: IERC1155

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// Part: IERC1155Receiver

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// Part: IStarUpdateListener

interface IStarUpdateListener is IERC165 {
    function onQuasarUpdated(uint256 id, uint256 oldAmount, uint256 newAmount) external;
    function onPowahUpdated(uint256 id, uint256 oldPowah, uint256 newPowah) external;
}

// Part: IERC1155MetadataURI

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

// Part: IStarNFT

/**
 * @title IStarNFT
 * @author Galaxy Protocol
 *
 * Interface for operating with StarNFTs.
 */
interface IStarNFT is IERC1155 {
    /* ============ Events =============== */
    event PowahUpdated(uint256 indexed id, uint256 indexed oldPoints, uint256 indexed newPoints);

    /* ============ Functions ============ */

    function isOwnerOf(address, uint256) external view returns (bool);
    function starInfo(uint256) external view returns (uint128 powah, uint128 mintBlock, address originator);
    function quasarInfo(uint256) external view returns (uint128 mintBlock, IERC20 stakeToken, uint256 amount, uint256 campaignID);
    function superInfo(uint256) external view returns (uint128 mintBlock, IERC20[] memory stakeToken, uint256[] memory amount, uint256 campaignID);

    // mint
    function mint(address account, uint256 powah) external returns (uint256);
    function mintBatch(address account, uint256 amount, uint256[] calldata powahArr) external returns (uint256[] memory);
    function burn(address account, uint256 id) external;
    function burnBatch(address account, uint256[] calldata ids) external;

    // asset-backing mint
    function mintQuasar(address account, uint256 powah, uint256 cid, IERC20 stakeToken, uint256 amount) external returns (uint256);
    function burnQuasar(address account, uint256 id) external;

    // asset-backing forge
    function mintSuper(address account, uint256 powah, uint256 campaignID, IERC20[] calldata stakeTokens, uint256[] calldata amounts) external returns (uint256);
    function burnSuper(address account, uint256 id) external;
    // update
    function updatePowah(address owner, uint256 id, uint256 powah) external;
}

// File: StarNFT.sol

/**
 * based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol
 */
contract StarNFT is ERC165, IERC1155, IERC1155MetadataURI, IStarNFT {
    using SafeMath for uint256;
    using Address for address;
    using ERC165Checker for address;

    /* ============ Events ============ */
    event GalaxyCommunityTransferred(address indexed previousGalaxyCommunity, address indexed newGalaxyCommunity);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BurnQuasar(uint256 indexed id);
    event BurnSuper(uint256 indexed id);
    /* ============ Modifiers ============ */
    /**
     * Only owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Must be owner");
        _;
    }
    /**
     * Only galaxy community.
     */
    modifier onlyGalaxyCommunity() {
        require(msg.sender == _galaxyCommunityAddress, "must be galaxy community");
        _;
    }
    /**
     * Only minter.
     */
    modifier onlyMinter() {
        require(_minters[msg.sender], "must be minter");
        _;
    }
    /**
     * Only operator.
     */
    modifier onlyOperator() {
        require(_operators[msg.sender], "must be operator");
        _;
    }
    /* ============ Enums ================ */
    /* ============ Structs ============ */
    struct NFTInfo {
        uint128 mintBlock;
        uint128 powah;
        address originator;
    }

    struct Quasar {
        IERC20 stakeToken;
        uint256 amount;
        uint256 campaignID;
    }

    struct Super {
        // assetToken => amount
        IERC20[] backingTokens;
        uint256[] backingAmounts;
        uint256 campaignID;
    }
    /* ============ State Variables ============ */

    // Indicates that the contract has been initialized.
    bool private _initialized;

    // Used as the URI for all token types by ID substitution, e.g. https://galaxy.eco/{address}/{id}.json
    string private _baseURI;

    // Contract owner
    address private _owner;

    // Galaxy community address
    address private _galaxyCommunityAddress;

    // Mint and burn star
    mapping(address => bool) private _minters;

    // Update star info
    mapping(address => bool) private _operators;

    // Total star count, including burnt nft
    uint256 private _starCount;
    // Mapping from token ID to account
    mapping(uint256 => address) private _starBelongTo;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // {id} => {star}
    mapping(uint256 => NFTInfo) private _stars;
    // {id} => {quasar}
    mapping(uint256 => Quasar) private _quasars;
    // {id} => {super}
    mapping(uint256 => Super) private _supers;

    /* ============ Constructor ============ */
    //    constructor () public {}
    /**
     * for proxy, use initialize instead.
     * set 'owner', 'galaxy community' and register 1155, metadata interface.
     */
    function initialize(address owner, address _galaxyCommunity) external {
        require(!_initialized, "Contract already initialized");
        require(owner != address(0), "Owner must not be null address");
        require(_galaxyCommunity != address(0), "galaxyCommunity must not be null address");
        _owner = owner;
        _galaxyCommunityAddress = _galaxyCommunity;

        _initialized = true;
    }

    /* ============ External Functions ============ */
    /**
     * See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external override {
        require(msg.sender != operator, "Setting approval status for self");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external override {
        require(to != address(0), "Transfer to must not be null address");
        require(amount == 1, "Invalid amount");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "Transfer caller is neither owner nor approved"
        );
        require(isOwnerOf(from, id), "Not the owner");

        _starBelongTo[id] = to;

        emit TransferSingle(msg.sender, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    /**
     * See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external override {
        require(to != address(0), "Batch transfer to must not be null address");
        require(ids.length == amounts.length, "Array(ids, amounts) length mismatch");
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "Transfer caller is neither owner nor approved");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(isOwnerOf(from, id), "Not the owner");
            _starBelongTo[id] = to;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function mint(address account, uint256 powah) external onlyMinter override returns (uint256) {
        return _mint(account, powah);
    }

    function mintBatch(address account, uint256 amount, uint256[] calldata powahArr) external onlyMinter override returns (uint256[] memory) {
        require(account != address(0), "Must not mint to null address");
        require(powahArr.length == amount, "Array(powah) length mismatch param(amount)");
        return _mintBatch(account, amount, powahArr);
    }

    function burn(address account, uint256 id) external onlyMinter override {
        require(isOwnerOf(account, id), "Not the owner");
        _burn(account, id);
    }

    function burnBatch(address account, uint256[] calldata ids) external onlyMinter override {
        for (uint i = 0; i < ids.length; i++) {
            require(isOwnerOf(account, ids[i]), "Not the owner");
        }
        _burnBatch(account, ids);
    }

    function mintQuasar(address account, uint256 powah, uint256 campaignID, IERC20 stakeToken, uint256 erc20Amount) external onlyMinter override returns (uint256) {
        return _mintQuasar(account, powah, campaignID, stakeToken, erc20Amount);
    }

    function burnQuasar(address account, uint256 id) external onlyMinter override {
        require(isOwnerOf(account, id), "Not the owner");
        _burnQuasar(id);
    }

    function mintSuper(address account, uint256 powah, uint256 campaignID, IERC20[] calldata stakeTokens, uint256[] calldata amounts) external onlyMinter override returns (uint256) {
        return _mintSuper(account, powah, campaignID, stakeTokens, amounts);
    }

    function burnSuper(address account, uint256 id) external onlyMinter override {
        require(isOwnerOf(account, id), "Must be owner of this Super NFT");
        _burnSuper(id);
    }

    /**
      * PRIVILEGED MODULE FUNCTION. Update nft powah.
      */
    function updatePowah(address owner, uint256 id, uint256 powah) external onlyOperator override {
        require(isOwnerOf(owner, id), "Must be owner");

        emit PowahUpdated(id, _stars[id].powah, powah);
        _doSafePowahUpdatedAcceptanceCheck(owner, id, _stars[id].powah, powah);

        _stars[id].powah = uint128(powah);
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Sets a new baseURI for all token types.
     */
    function setURI(string memory newURI) external onlyGalaxyCommunity {
        _baseURI = newURI;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Transfer community ownership.
     */
    function transferGalaxyCommunity(address newGalaxyCommunity) external onlyGalaxyCommunity {
        require(newGalaxyCommunity != address(0), "NewGalaxyCommunity must not be null address");
        _galaxyCommunityAddress = newGalaxyCommunity;
        emit GalaxyCommunityTransferred(_galaxyCommunityAddress, newGalaxyCommunity);
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Transfer ownership.
     */
    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner must not be null address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Add a new minter.
     */
    function addMinter(address minter) external onlyOwner {
        require(minter != address(0), "Minter must not be null address");
        require(!_minters[minter], "Minter already added");
        _minters[minter] = true;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Remove a old minter.
     */
    function removeMinter(address minter) external onlyOwner {
        require(_minters[minter], "Minter does not exist");
        delete _minters[minter];
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Add a new operator.
     */
    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "Operator must not be null address");
        require(!_operators[operator], "Operator already added");
        _operators[operator] = true;
    }

    /**
     * PRIVILEGED MODULE FUNCTION. Remove an old operator.
     */
    function removeOperator(address operator) external onlyOwner {
        require(_operators[operator], "Operator does not exist");
        delete _operators[operator];
    }

    /* ============ External Getter Functions ============ */
    /**
     * Is contract initialized.
     */
    function initialized() external view returns (bool) {
        return _initialized;
    }

    /**
     * Star nft contract owner.
     */
    function starNFTOwner() external view returns (address) {
        return _owner;
    }

    /**
     * Galaxy community address.
     */
    function galaxyCommunity() external view returns (address) {
        return _galaxyCommunityAddress;
    }

    /**
     * Is minter.
     */
    function isMinter(address minter) external view returns (bool) {
        return _minters[minter];
    }

    /**
     * Is operator.
     */
    function isOperator(address operator) external view returns (bool) {
        return _operators[operator];
    }

    /**
     * See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * Base URI for all token types by ID substitution.
     */
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /**
     * Total star nft count, including burnt nft.
     */
    function starNFTCount() external view returns (uint256) {
        return _starCount;
    }

    /**
     * See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 id) external view override returns (string memory) {
        require(id <= _starCount, "Star nft does not exist");
        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_baseURI).length == 0) {
            return "";
        } else {
            // bytes memory b = new bytes(32);
            // assembly { mstore(add(b, 32), id) }
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, uint2str(id), ".json"));
        }
    }

    /**
     * Is the nft owner.
     * Requirements:
     * - `account` must not be zero address.
     */
    function isOwnerOf(address account, uint256 id) public view override returns (bool) {
        if (account == address(0)) {
            return false;
        } else {
            return _starBelongTo[id] == account;
        }
    }

    /**
     * Get star info.
     */
    function starInfo(uint256 id) external view override returns (uint128 powah, uint128 mintBlock, address originator) {
        powah = _stars[id].powah;
        mintBlock = _stars[id].mintBlock;
        originator = _stars[id].originator;
    }

    /**
     * Get quasar info.
     */
    function quasarInfo(uint256 id) external view override returns (uint128 mintBlock, IERC20 stakeToken, uint256 amount, uint256 campaignID) {
        mintBlock = _stars[id].mintBlock;
        stakeToken = _quasars[id].stakeToken;
        amount = _quasars[id].amount;
        campaignID = _quasars[id].campaignID;
    }
    /**
     * Get super info
     */
    function superInfo(uint256 id) external view override returns (uint128 mintBlock, IERC20[] memory stakeToken, uint256[] memory amount, uint256 campaignID){
        mintBlock = _stars[id].mintBlock;
        campaignID = _supers[id].campaignID;
        stakeToken = _supers[id].backingTokens;
        amount = _supers[id].backingAmounts;
    }

    /**
     * See {IERC1155-balanceOf}.
     * Requirements:
     * - `account` must not be zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        if (isOwnerOf(account, id)) {
            return 1;
        }
        return 0;
    }

    /**
     * See {IERC1155-balanceOfBatch}.
     * Requirements:
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view override returns (uint256[] memory){
        require(accounts.length == ids.length, "Array(accounts, ids) length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /* ============ Internal Functions ============ */
    /* ============ Private Functions ============ */
    /**
     * Create star with `powah`, and assign it to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     * - `account` must not be zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 powah) private returns (uint256) {
        require(account != address(0), "Must not mint to null address");
        _starCount++;
        uint256 sID = _starCount;
        _starBelongTo[sID] = account;
        _stars[sID] = NFTInfo({
        powah : uint128(powah),
        mintBlock : uint128(block.number),
        originator : account
        });

        emit TransferSingle(msg.sender, address(0), account, sID, 1);

        _doSafeTransferAcceptanceCheck(msg.sender, address(0), account, sID, 1, "");

        return sID;
    }

    /**
     * Create quasar with `powah`, and assign it to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     * - `account` must not be zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mintQuasar(address account, uint256 powah, uint256 campaignID, IERC20 stakeToken, uint256 amount) private returns (uint256) {
        uint256 sID = _mint(account, powah);
        _quasars[sID] = Quasar({
        stakeToken : stakeToken,
        amount : amount,
        campaignID : campaignID
        });
        return sID;
    }

    /**
     * Create super with `powah`, and assign it to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     * - `account` must not be zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mintSuper(address account, uint256 powah, uint256 campaignID, IERC20[] calldata stakeTokens, uint256[] calldata amounts) private returns (uint256){
        require(stakeTokens.length > 0, "Array(stakeTokens) must not be empty");
        // Don't use validate arrays because empty arrays are valid
        require(stakeTokens.length == amounts.length, "Array(stakeTokens, amounts) length mismatch");

        uint256 sID = _mint(account, powah);
        _supers[sID].campaignID = campaignID;
        _supers[sID].backingTokens = stakeTokens;
        _supers[sID].backingAmounts = amounts;

        return sID;
    }

    /**
     * Mint `amount` star nft to `to`
     *
     * Requirements:
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256 amount, uint256[] calldata powahArr) private returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](amount);
        uint256[] memory amounts = new uint256[](amount);
        for (uint i = 0; i < ids.length; i++) {
            _starCount++;
            _starBelongTo[_starCount] = to;
            _stars[_starCount] = NFTInfo({
            powah : uint128(powahArr[i]),
            mintBlock : uint128(block.number),
            originator : to
            });
            ids[i] = _starCount;
            amounts[i] = 1;
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), to, ids, amounts, "");

        return ids;
    }

    /**
     * Burn `id` nft from `account`.
     */
    function _burn(address account, uint256 id) private {
        delete _starBelongTo[id];
        delete _quasars[id];
        delete _supers[id];
        delete _stars[id];

        emit TransferSingle(msg.sender, account, address(0), id, 1);
    }

    /**
     * Delete quasar.
     */
    function _burnQuasar(uint256 id) private {
        delete _quasars[id];

        emit BurnQuasar(id);
    }

    /**
     * Delete super.
     */
    function _burnSuper(uint256 id) private {
        delete _supers[id].backingTokens;
        delete _supers[id].backingAmounts;
        delete _supers[id];

        emit BurnSuper(id);
    }

    /**
     * xref:ROOT:erc1155.doc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids) private {
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            delete _starBelongTo[ids[i]];
            delete _quasars[ids[i]];
            delete _supers[ids[i]];
            delete _stars[ids[i]];
            amounts[i] = 1;
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
    private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
    )
    private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeQuasarUpdatedAcceptanceCheck(
        address owner,
        uint256 id,
        uint256 oldAmount,
        uint256 newAmount
    )
    private
    {
        if (owner.isContract() && owner.supportsERC165()) {
            if (
                IERC165(owner).supportsInterface(
                    IStarUpdateListener(0).onQuasarUpdated.selector
                )
            ) {
                IStarUpdateListener(owner).onQuasarUpdated(id, oldAmount, newAmount);
            }
        }
    }

    function _doSafePowahUpdatedAcceptanceCheck(
        address owner,
        uint256 id,
        uint256 oldPowah,
        uint256 newPowah
    )
    private
    {
        if (owner.isContract() && owner.supportsERC165()) {
            if (
                IERC165(owner).supportsInterface(
                    IStarUpdateListener(0).onPowahUpdated.selector
                )
            ) {
                IStarUpdateListener(owner).onPowahUpdated(id, oldPowah, newPowah);
            }
        }
    }

    /* ============ Util Functions ============ */
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bStr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bStr[k] = b1;
            _i /= 10;
        }
        return string(bStr);
    }
}