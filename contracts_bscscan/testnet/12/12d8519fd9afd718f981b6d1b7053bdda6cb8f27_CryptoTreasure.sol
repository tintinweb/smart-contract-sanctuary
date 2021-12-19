/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: contracts/Bytes.sol


pragma solidity ^0.8.0;

/**
 * @title Bytes util library.
 * @notice Collection of utility functions to manipulate bytes
 */
library Bytes {
    /**
     * @dev Extract uint256 in a bytes from an index
     *
     * @param _bts bytes to extact the integer from
     * @param _from extraction starting from this index
     * @return uint256 integer extracted
     */
    function _bytesToUint256(bytes memory _bts, uint256 _from)
        internal
        pure
        returns (uint256)
    {
        require(_bts.length >= _from + 32, "e0");

        uint256 convertedUint256;
        uint256 startByte = _from + 32; //first 32 bytes denote the array length

        assembly {
            convertedUint256 := mload(add(_bts, startByte))
        }

        return convertedUint256;
    }

    /**
     * @dev Extract uint8 in a bytes from an index
     *
     * @param _bts bytes to extact the integer from
     * @param _from extraction starting from this index
     * @return uint8 integer extracted
     */
    function _bytesToUint8(bytes memory _bts, uint256 _from)
        internal
        pure
        returns (uint8)
    {
        require(_bts.length >= _from + 1, "e0");

        uint8 convertedUint8;
        uint256 startByte = _from + 1;

        assembly {
            convertedUint8 := mload(add(_bts, startByte))
        }

        return convertedUint8;
    }

    /**
     * @dev Extract address in a bytes from an index
     *
     * @param _bts bytes to extact the address from
     * @param _from extraction starting from this index
     * @return address extracted
     */
    function _bytesToAddress(bytes memory _bts, uint256 _from)
        internal
        pure
        returns (address)
    {
        require(_bts.length >= _from + 20, "e0");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bts, 0x20), _from)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

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

// File: contracts/IBox.sol


pragma solidity ^0.8.0;

/**
 * @title Box events and storage
 * @notice Collection of events and storage to handle boxes
 */
interface IBox is IERC165, IERC721Receiver, IERC1155Receiver {
    // ERC721 token information {address and token ids} used for function parameters
    struct ERC721TokenInfos {
        address addr;
        uint256[] ids;
    }
    // ERC20 token information {address and amount} used for function parameters
    struct ERC20TokenInfos {
        address addr;
        uint256 amount;
    }
    // ERC1155 token information {address, token ids and token amounts} used for function parameters
    struct ERC1155TokenInfos {
        address addr;
        uint256[] ids;
        uint256[] amounts;
    }

    event Store(
        uint256 indexed boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s
    );

    event Withdraw(
        uint256 indexed boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s,
        address to
    );

    event TransferBetweenBoxes(
        uint256 indexed srcBoxId,
        uint256 indexed destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] erc20s,
        ERC721TokenInfos[] erc721s,
        ERC1155TokenInfos[] erc1155s
    );

    event Destroyed(uint256 indexed boxId);

    function store(
        uint256 boxId,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external payable;

    function withdraw(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s,
        address payable to
    ) external;

    function transferBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external;

    function destroy(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20ToWithdraw,
        ERC721TokenInfos[] calldata erc721ToWithdraw,
        ERC1155TokenInfos[] calldata erc1155ToWithdraw,
        address payable to
    ) external;

    function EthBalanceOf(uint256 _boxId) external view returns (uint256);

    function erc20BalanceOf(uint256 _boxId, address _tokenAddress)
        external
        view
        returns (uint256);

    function erc721BalanceOf(
        uint256 _boxId,
        address _tokenAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function erc1155BalanceOf(
        uint256 _boxId,
        address _tokenAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override returns (bytes4);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override returns (bytes4);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// File: contracts/BoxStorage.sol


pragma solidity ^0.8.0;



/**
 * @title Box storage
 * @notice Collection storage to handle boxes
 */
abstract contract BoxStorage is ERC165 {
    // ERC20: Mapping from hash(boxId, tokenAddress) to balance
    // ERC721: Mapping from hash(boxId, tokenAddress, tokenId) to 1 (owned) / 0 (not owned)
    // ER1155: Mapping from hash(boxId, tokenAddress, tokenId) to balance
    mapping(bytes32 => uint256) public _indexedTokens;

    // ETH: Mapping from boxId to balance
    mapping(uint256 => uint256) public _indexedEth;

    // Mapping of destroyed boxes
    mapping(uint256 => bool) public destroyedBoxes;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IBox).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// File: contracts/BoxProxy.sol


pragma solidity ^0.8.0;







/**
 * @title Box with public functions to store, withdraw, transferBetweenBoxes and destroy
 * @notice This contract delegateCall the contract BoxBase
 */
abstract contract BoxProxy is IBox, BoxStorage, ReentrancyGuard {
    /// contract boxBase to delegateCall
    address public boxBase;

    /**
     * @dev Constructor
     * @param _boxBaseAddress boxBase address
     */
    constructor(address _boxBaseAddress) {
        boxBase = _boxBaseAddress;
    }

    /**
     * @dev Store tokens to a box
     * @notice allowance for the tokens must be done to this contract
     * @notice _beforeStore(boxId) is called before actually storing
     *
     * @param boxId id of the box
     * @param erc20s list of erc20 to store
     * @param erc721s list of erc721 to store
     * @param erc1155s list of erc1155 to store
     */
    function store(
        uint256 boxId,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external payable override nonReentrant {
        _beforeStore(boxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "store(uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[])",
                boxId,
                erc20s,
                erc721s,
                erc1155s
            )
        );
        require(status, "e23");
    }

    /**
     * @dev Withdraw tokens from a box to an address
     * @notice _beforeWithdraw(boxId) is called before actually withdrawing
     *
     * @param boxId id of the box
     * @param ethAmount amount of eth to withdraw
     * @param erc20s list of erc20 to withdraw
     * @param erc721s list of erc721 to withdraw
     * @param erc1155s list of erc1155 to withdraw
     * @param to address of reception
     */
    function withdraw(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s,
        address payable to
    ) external override nonReentrant {
        _beforeWithdraw(boxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "withdraw(uint256,uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[],address)",
                boxId,
                ethAmount,
                erc20s,
                erc721s,
                erc1155s,
                to
            )
        );
        require(status, "e23");
    }

    /**
     * @dev Transfer tokens from a box to another
     * @notice _beforeStore(destBoxId) and _beforeWithdraw(srcBoxId) are called before actually transfering
     *
     * @param srcBoxId source box
     * @param destBoxId destination box
     * @param ethAmount amount of eth to transfer
     * @param erc20s list of erc20 to transfer
     * @param erc721s list of erc721 to transfer
     * @param erc1155s list of erc1155 to transfer
     */
    function transferBetweenBoxes(
        uint256 srcBoxId,
        uint256 destBoxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20s,
        ERC721TokenInfos[] calldata erc721s,
        ERC1155TokenInfos[] calldata erc1155s
    ) external override nonReentrant {
        _beforeWithdraw(srcBoxId);
        _beforeStore(destBoxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "transferBetweenBoxes(uint256,uint256,uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[])",
                srcBoxId,
                destBoxId,
                ethAmount,
                erc20s,
                erc721s,
                erc1155s
            )
        );
        require(status, "e23");
    }

    /**
     * @dev Destroy a box
     * @notice _beforeDestroy(boxId) is called before actually destroying
     *
     * @param boxId id of the box
     * @param ethAmount amount of eth to withdraw
     * @param erc20ToWithdraw list of erc20 to withdraw
     * @param erc721ToWithdraw list of erc721 to withdraw
     * @param erc1155ToWithdraw list of erc1155 to withdraw
     * @param to address of reception
     */
    function destroy(
        uint256 boxId,
        uint256 ethAmount,
        ERC20TokenInfos[] calldata erc20ToWithdraw,
        ERC721TokenInfos[] calldata erc721ToWithdraw,
        ERC1155TokenInfos[] calldata erc1155ToWithdraw,
        address payable to
    ) external override nonReentrant {
        _beforeDestroy(boxId);

        (bool status, ) = boxBase.delegatecall(
            abi.encodeWithSignature(
                "destroy(uint256,uint256,(address,uint256)[],(address,uint256[])[],(address,uint256[],uint256[])[],address)",
                boxId,
                ethAmount,
                erc20ToWithdraw,
                erc721ToWithdraw,
                erc1155ToWithdraw,
                to
            )
        );
        require(status, "e23");

        _afterDestroy(boxId);
    }

    /**
     * @dev Get the balance of ethers in a box
     *
     * @param boxId id of the box
     *
     * @return balance
     */
    function EthBalanceOf(uint256 boxId)
        public
        view
        override
        returns (uint256 balance)
    {
        return _indexedEth[boxId];
    }

    /**
     * @dev Get the balance of an erc20 token in a box
     *
     * @param boxId id of the box
     * @param tokenAddress erc20 token address
     *
     * @return balance
     */
    function erc20BalanceOf(uint256 boxId, address tokenAddress)
        public
        view
        override
        returns (uint256 balance)
    {
        bytes32 index = keccak256(abi.encodePacked(boxId, tokenAddress));
        return _indexedTokens[index];
    }

    /**
     * @dev Get the balance of an erc1155 token in a box
     *
     * @param boxId id of the box
     * @param tokenAddress erc1155 token address
     * @param tokenId token id
     *
     * @return balance
     */
    function erc1155BalanceOf(
        uint256 boxId,
        address tokenAddress,
        uint256 tokenId
    ) public view override returns (uint256 balance) {
        bytes32 index = keccak256(
            abi.encodePacked(boxId, tokenAddress, tokenId)
        );
        return _indexedTokens[index];
    }

    /**
     * @dev Check if an ERC721 token is in a box
     *
     * @param boxId id of the box
     * @param tokenAddress erc1155 token address
     * @param tokenId token id
     *
     * @return present 1 if present, 0 otherwise
     */
    function erc721BalanceOf(
        uint256 boxId,
        address tokenAddress,
        uint256 tokenId
    ) public view override returns (uint256 present) {
        bytes32 index = keccak256(
            abi.encodePacked(boxId, tokenAddress, tokenId)
        );
        return _indexedTokens[index];
    }

    /**
     * @dev Handles the receipt of ERC1155 token types
     * @notice will always revert
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert();
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types
     * @notice Authorized only if the transfer is operated by this contract
     */
    function onERC1155BatchReceived(
        address operator,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public view override returns (bytes4) {
        require(operator == address(this), "e2");

        // reception accepted
        return 0xbc197c81;
    }

    /**
     * @dev Handles the receipt of a multiple ERC721 token types
     * @notice Authorized only if the transfer is operated by this contract
     */
    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) public view override returns (bytes4) {
        require(operator == address(this), "e2");

        // reception accepted
        return 0x150b7a02;
    }

    /**
     * @dev Throw if box is destroyed
     *
     * @param boxId id of the box
     */
    function onlyNotBrokenBox(uint256 boxId) internal view {
        require(!destroyedBoxes[boxId], "e3");
    }

    /**
     * @dev executed before a withdraw
     *
     * @param boxId id of the box
     */
    function _beforeWithdraw(uint256 boxId) internal virtual {}

    /**
     * @dev executed before a store
     * @notice forbid store if crypto treasure has been destroyed
     *
     * @param boxId id of the box
     */
    function _beforeStore(uint256 boxId) internal virtual {
        onlyNotBrokenBox(boxId);
    }

    /**
     * @dev executed before a destroy
     * @notice forbid destroy if crypto treasure has been destroyed
     *
     * @param boxId id of the box
     */
    function _beforeDestroy(uint256 boxId) internal virtual {
        onlyNotBrokenBox(boxId);
    }

    /**
     * @dev executed after a destroy
     *
     * @param boxId id of the box
     */
    function _afterDestroy(uint256 boxId) internal virtual {}
}

// File: contracts/BoxWithTimeLock.sol


pragma solidity ^0.8.0;


/**
 * @title Box with a time lock
 * @notice A locked box cannot be withdrawn, stored and destroyed
 */
abstract contract BoxWithTimeLock is BoxProxy {
    /// Mapping from boxId to unlock timestamp
    mapping(uint256 => uint256) public _unlockTimestamp;

    event BoxLocked(uint256 indexed boxId, uint256 unlockTimestamp);

    /**
     * @dev Constructor
     * @param _baseBoxAddress boxBase address
     */
    constructor(address _baseBoxAddress) BoxProxy(_baseBoxAddress) {}

    /**
     * @dev lock a box until a timestamp
     *
     * @param boxId id of the box
     * @param timestamp unlock timestamp
     */
    function _lockBox(uint256 boxId, uint256 timestamp) internal virtual {
        _unlockTimestamp[boxId] = timestamp;
        emit BoxLocked(boxId, timestamp);
    }

    /**
     * @dev executed before a withdraw
     * @notice forbid withdraw if box is locked
     *
     * @param boxId id of the box
     */
    function _beforeWithdraw(uint256 boxId) internal virtual override {
        onlyNotLockedBox(boxId);
    }

    /**
     * @dev executed before a store
     * @notice forbid store if box is locked
     * @notice forbid store if crypto treasure has been destroyed (from BoxExternal)
     *
     * @param boxId id of the box
     */
    function _beforeStore(uint256 boxId) internal virtual override {
        super._beforeStore(boxId);
        onlyNotLockedBox(boxId);
    }

    /**
     * @dev executed before a destroy
     * @notice forbid destroy if box is locked
     * @notice forbid destroy if crypto treasure has been destroyed (from BoxExternal)
     *
     * @param boxId id of the box
     */
    function _beforeDestroy(uint256 boxId) internal virtual override {
        super._beforeDestroy(boxId);
        onlyNotLockedBox(boxId);
    }

    /**
     * @dev Throw if box is locked
     *
     * @param boxId id of the box
     */
    function onlyNotLockedBox(uint256 boxId) internal view {
        require(_unlockTimestamp[boxId] <= block.timestamp, "e8");
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Token 
    string public baseExtension = ".json";
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/ERC721Typed.sol


pragma solidity ^0.8.0;



/**
 * @title typed ERC721
 * @notice every token has a type with optional data
 */
abstract contract ERC721Typed is ERC721 {
    // Structure to defined a type
    struct Type {
        // First id for this token type
        uint256 from;
        // Last id for this token type
        uint256 to;
        bytes data;
        uint256 nextToMint;
    }

    // Mapping types information
    mapping(uint256 => Type) public _types;

    // Mapping token id => type id
    mapping(uint256 => uint256) public _tokenTypes;

    event NewType(uint256 id, uint256 from, uint256 to, bytes data);

    /**
     * @dev Constructor
     * @param name_ erc721 token name
     * @param symbol_ erc721 token symbol
     */
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
    {}

    /**
     * @dev Mint an ERC721 typed token from its id
     * @notice throw if type does not exist
     * @notice throw if tokenId is not in the range of the type (between from and to)
     *
     * @param to address of reception
     * @param tokenId id of the token
     * @param data array bytes containing the type id (in first 32 bytes)
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual override {
        uint256 typeId = Bytes._bytesToUint256(data, 0);
        require(typeId != 0, "e9");

        Type memory requestedType = _types[typeId];
        require(requestedType.to != 0, "e10");
        require(tokenId >= requestedType.from, "e11");
        require(tokenId <= requestedType.to, "e12");
        _tokenTypes[tokenId] = typeId;

        super._safeMint(to, tokenId, data);
    }

    /**
     * @dev Mint an ERC721 typed token from a type id
     * @notice throw if type does not exist
     * @notice throw if all the tokens are already minted for this type
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data extra information
     *
     * @return minted token id
     */
    function _safeMintByType(
        address to,
        uint256 typeId,
        bytes memory data
    ) internal virtual returns (uint256) {
        Type memory requestedType = _types[typeId];
        require(requestedType.to != 0, "e10");

        uint256 tokenId = requestedType.nextToMint;
        // skip the token already minted
        while (_exists(tokenId)) {
            tokenId++;
            // Revert if all tokens have been minted for the allocated type range
            require(tokenId <= requestedType.to, "e18");
        }

        _tokenTypes[tokenId] = typeId;

        // mint the token
        super._safeMint(to, tokenId, data);

        // increment the next to mint
        requestedType.nextToMint = tokenId + 1;

        return tokenId;
    }

    /**
     * @dev Mint a batch of ERC721 typed token from a type id
     * @notice throw if type does not exist
     * @notice throw if there is not enough tokens to minted for this type
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data extra information
     *
     * @return minted tokens id
     */
    function _safeBatchMintByType(
        address[] calldata to,
        uint256 typeId,
        bytes memory data
    ) internal virtual returns (uint256[] memory) {
        Type memory requestedType = _types[typeId];
        require(requestedType.to != 0, "e10");

        uint256[] memory tokensMinted = new uint256[](to.length);
        uint256 tokenId = requestedType.nextToMint;
        for (uint256 j = 0; j < to.length; j++) {
            // skip the token already minted
            while (_exists(tokenId)) {
                tokenId++;
                // Revert if all tokens have been minted for the allocated type range
                require(tokenId <= requestedType.to, "e18");
            }

            // mint the token
            super._safeMint(to[j], tokenId, data);
            tokensMinted[j] = tokenId;

            _tokenTypes[tokenId] = typeId;

            // increment the next to mint
            requestedType.nextToMint = tokenId + 1;
        }

        return tokensMinted;
    }

    /**
     * @dev Add one type with a range of token id
     * @notice throw if type id already exist
     * @notice throw if to is lower than from
     *
     * @param id new id type
     * @param from first id for this type
     * @param to last id for this type
     * @param data extra information
     */
    function _addType(
        uint256 id,
        uint256 from,
        uint256 to,
        bytes calldata data
    ) internal virtual {
        require(_types[id].to == 0, "e13");
        require(from < to, "e14");
        _types[id] = Type(from, to, data, from);
        emit NewType(id, from, to, data);
    }

    /**
     * @dev Add list of types
     * @notice throw if a type id already exist
     * @notice throw if a to is lower than a from
     *
     * @param ids new ids type
     * @param from first ids for this type
     * @param to last ids for this type
     * @param data extra information
     */
    function _addTypes(
        uint256[] calldata ids,
        uint256[] calldata from,
        uint256[] calldata to,
        bytes[] calldata data
    ) internal virtual {
        for (uint256 i = 0; i < ids.length; i++) {
            _addType(ids[i], from[i], to[i], data[i]);
        }
    }
}

// File: contracts/ERC721TypedMintByLockingERC20.sol


pragma solidity ^0.8.0;




/**
 * @title Types ERC721 with an erc20 token lock to mint a token.
 * @notice Every type required a specific amount of a specific erc20 to be lock to mint tokens
 * @notice To unlock the erc20 tokens lock after a mint is to call the internal function _unlockMint()
 */
contract ERC721TypedMintByLockingERC20 is ERC721Typed {
    struct ERC20ToLock {
        address addr;
        uint256 amount;
    }

    // Mapping typeId => erc20 address to lock
    mapping(uint256 => ERC20ToLock) public _erc20ToLock;

    /**
     * @dev Constructor
     * @param name_ erc721 token name
     * @param symbol_ erc721 token symbol
     */
    constructor(string memory name_, string memory symbol_)
        ERC721Typed(name_, symbol_)
    {}

    /**
     * @dev Mint an ERC721 typed token from its id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     *
     * @param to address of reception
     * @param tokenId id of the token
     * @param data array bytes containing the type id (in first 32 bytes)
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual override {
        super._safeMint(to, tokenId, data);

        ERC20ToLock memory etl = _erc20ToLock[_tokenTypes[tokenId]];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // Safely transfer the tokens to this very contract to lock them
            SafeERC20.safeTransferFrom(erc20, _msgSender(), address(this), etl.amount);
        }
    }

    /**
     * @dev Mint an ERC721 typed token from a type id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data extra information
     *
     * @return minted token id
     */
    function _safeMintByType(
        address to,
        uint256 typeId,
        bytes memory data
    ) internal virtual override returns (uint256) {
        // min the token
        uint256 tokenId = super._safeMintByType(to, typeId, data);

        ERC20ToLock memory etl = _erc20ToLock[typeId];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // Safely transfer the tokens to this very contract to lock them
            SafeERC20.safeTransferFrom(erc20, _msgSender(), address(this), etl.amount);
        }

        // return the token id
        return tokenId;
    }

    /**
     * @dev Mint a batch of ERC721 typed token from a type id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data extra information
     *
     * @return minted tokens id
     */
    function _safeBatchMintByType(
        address[] calldata to,
        uint256 typeId,
        bytes memory data
    ) internal override returns (uint256[] memory) {
        // mint the tokens
        uint256[] memory tokensMinted = super._safeBatchMintByType(
            to,
            typeId,
            data
        );

        ERC20ToLock memory etl = _erc20ToLock[typeId];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // Safely transfer the tokens to this very contract to lock them
            SafeERC20.safeTransferFrom(erc20, _msgSender(), address(this), etl.amount * to.length);
        }

        return tokensMinted;
    }

    /**
     * @dev Add one type with a range of token id
     *
     * @param id new id type
     * @param from first id for this type
     * @param to last id for this type
     * @param data array bytes containing:
     *                  - the erc20 addres to lock (in first 20 bytes)
     *                  - the amount to lock (in following 32 bytes)
     */
    function _addType(
        uint256 id,
        uint256 from,
        uint256 to,
        bytes calldata data
    ) internal virtual override {
        _erc20ToLock[id] = ERC20ToLock(
            Bytes._bytesToAddress(data, 0),
            Bytes._bytesToUint256(data, 20)
        );
        super._addType(id, from, to, data);
    }

    /**
     * @dev Release the erc20 locked for a token to the token owner
     *
     * @param tokenId id of the token
     */
    function _unlockMint(uint256 tokenId) internal virtual {
        ERC20ToLock memory etl = _erc20ToLock[_tokenTypes[tokenId]];
        if (etl.amount != 0) {
            IERC20 erc20 = IERC20(etl.addr);
            // Safely transfer the tokens from this very contract to the owner of the treasure
            SafeERC20.safeTransfer(erc20, ownerOf(tokenId), etl.amount);
        }
    }
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;





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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/CryptoTreasure.sol


pragma solidity ^0.8.0;




/**
 * @title CryptoTreasure is a typed ERC721 token able to store other tokens (ETH, ERC20, ERC721 & ERC1155)
 * @notice The types define the erc20 token (and the amount) to lock to mint a crypto treasure
 * @notice The locked erc20 tokens can be release by "destroying" the crypto treasure
 * @notice A destroyed crypto treasure allows to withdraw stored tokens but forbids the storing.
 * @notice The types define the timestamp from when it is allowed for non admin to mint a crypto treasure
 * @notice The types define a number of crypto treasure reserved for the admins
 */
contract CryptoTreasure is
    BoxWithTimeLock,
    ERC721TypedMintByLockingERC20,
    AccessControl
{
    string private baseURI =
        "ipfs://QmYGDWZyAFCXuXusLx2TjLfVcjXUjwJzHZ1ZwEHUdd9nhB/";

    // Mapping from box id to restriction
    mapping(uint256 => bool) public _storeRestrictedToOwnerAndApproval;

    // Mapping from type id to blocked destruction duration
    mapping(uint256 => uint256) public _lockedDestructionDuration;

    // Mapping from type id to minting start timestamp
    mapping(uint256 => uint256) public _mintStartTimestamp;

    // Mapping from type id to last id not reserved to admin
    mapping(uint256 => uint256) public _lastIdNotReserved;

    // Mapping from box id to destroy unlock timestamp
    mapping(uint256 => uint256) public _lockedDestructionEnd;

    /**
     * @dev Constructor
     * @notice add msg.sender as DEFAULT_ADMIN_ROLE
     * @param _baseBoxAddress boxBase address
     */
    constructor(address _baseBoxAddress)
        ERC721TypedMintByLockingERC20("CryptoTreasures", "CTR")
        BoxWithTimeLock(_baseBoxAddress)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Mint crypto treasure  from its id
     * @notice This will transferFrom() erc20 token to lock to the contract
     * @notice Allowance of the erc20 to lock must be done before
     * @notice Throw if the minting start is not yet passed
     * @notice Throw if the crypto treasure is reserved to an admin
     *
     * @param to address of reception
     * @param boxId id of the box
     * @param data array bytes containing:
     *                      - the type id (in first 32 bytes)
     *                      - the storing restriction (in following 8 bytes) - 1 only owner can store, 0 everyone can store
     */
    function safeMint(
        address to,
        uint256 boxId,
        bytes memory data
    ) external nonReentrant {
        super._safeMint(to, boxId, data);

        uint256 typeId = _tokenTypes[boxId];
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                boxId <= _lastIdNotReserved[typeId],
            "e22"
        );
        require(_mintStartTimestamp[typeId] <= block.timestamp, "e19");

        _storeRestrictedToOwnerAndApproval[boxId] =
            Bytes._bytesToUint8(data, 32) == 1;

        uint256 destroyLockDuration = _lockedDestructionDuration[typeId];
        if (destroyLockDuration != 0) {
            _lockedDestructionEnd[boxId] =
                block.timestamp +
                destroyLockDuration;
        }
    }

    /**
     * @dev Mint a crypto treasure from a type id
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     * @notice Throw if the minting start is not yet passed
     * @notice Throw if there is no more crypto treasure available for this type
     *
     * @param to address of reception
     * @param typeId id of the type
     * @param data array bytes containing the storing restriction (in first 8 bytes) - 1 only owner can store, 0 everyone can store
     *
     * @return minted crypto treasure id
     */
    function safeMintByType(
        address to,
        uint256 typeId,
        bytes memory data
    ) external nonReentrant returns (uint256) {
        require(_mintStartTimestamp[typeId] <= block.timestamp, "e19");

        // mint the token
        uint256 tokenId = _safeMintByType(to, typeId, data);
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                tokenId <= _lastIdNotReserved[typeId],
            "e22"
        );

        _storeRestrictedToOwnerAndApproval[tokenId] =
            Bytes._bytesToUint8(data, 0) == 1;

        uint256 destroyLockDuration = _lockedDestructionDuration[typeId];
        if (destroyLockDuration != 0) {
            _lockedDestructionEnd[tokenId] =
                block.timestamp +
                destroyLockDuration;
        }

        // return the token id
        return tokenId;
    }

    /**
     * @dev Mint a batch of crypto treasures from a type id
     * @notice only admins cal execute this function
     * @notice This will transferFrom() tokens to the contract
     * @notice Allowance of the erc20 to lock must be done before
     * @notice Minting can be done before the minting start for everyone
     * @notice Throw if there is no more crypto treasure available for this type
     *
     * @param to addresses of reception
     * @param typeId id of the type
     * @param data array bytes containing the storing restriction (in first 8 bytes) - 1 only owner can store, 0 everyone can store
     *
     * @return tokensMinted minted crypto treasure id list
     */
    function safeBatchMintByType(
        address[] calldata to,
        uint256 typeId,
        bytes memory data
    )
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256[] memory tokensMinted)
    {
        // mint the tokens
        tokensMinted = super._safeBatchMintByType(to, typeId, data);

        uint256 destroyLockDuration = _lockedDestructionDuration[typeId];

        // define the restriction mode
        for (uint256 j = 0; j < to.length; j++) {
            _storeRestrictedToOwnerAndApproval[tokensMinted[j]] =
                Bytes._bytesToUint8(data, 0) == 1;
            if (destroyLockDuration != 0) {
                _lockedDestructionEnd[tokensMinted[j]] =
                    block.timestamp +
                    destroyLockDuration;
            }
        }
    }

    /**
     * @dev lock a crypto treasure until a timestamp
     * @notice Only owner or approved can execute this
     * @notice Throw if the crypto treasure is already locked
     *
     * @param boxId id of the box
     * @param unlockTimestamp unlock timestamp
     */
    function lockBox(uint256 boxId, uint256 unlockTimestamp) external {
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
        onlyNotLockedBox(boxId);
        _lockBox(boxId, unlockTimestamp);
    }

    /**
     * @dev Set the restriction mode of the storing
     * @notice Only owner or approved can execute this
     * @notice Throw if the crypto treasure is already locked
     *
     * @param boxId id of the box
     * @param restriction true: only owner can store, false: everyone can store
     */
    function setStoreRestrictionToOwnerAndApproval(
        uint256 boxId,
        bool restriction
    ) external {
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
        onlyNotLockedBox(boxId);

        _storeRestrictedToOwnerAndApproval[boxId] = restriction;
    }

    /**
     * @dev Add one type with a range of token id
     * @notice Only admin can execute this function
     * @notice Throw if the number reserved is bigger than the range
     *
     * @param id new id type
     * @param from first id for this type
     * @param to last id for this type
     * @param data array bytes containing:
     *                  - the erc20 addres to lock (in first 20 bytes)
     *                  - the amount to lock (in following 32 bytes)
     *                  - the duration before destroy() is allowed after minting (in following 32 bytes)
     *                  - the duration before mint() is allowed for everyone (in following 32 bytes)
     *                  - the number of tokens reserved to admins (in following 32 bytes)
     */
    function addType(
        uint256 id,
        uint256 from,
        uint256 to,
        bytes calldata data
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _addType(id, from, to, data);
        _lockedDestructionDuration[id] = Bytes._bytesToUint256(data, 52);
        _mintStartTimestamp[id] =
            block.timestamp +
            Bytes._bytesToUint256(data, 84);
        uint256 numberToReserved = Bytes._bytesToUint256(data, 116);

        require(numberToReserved <= to - from + 1, "e21");
        _lastIdNotReserved[id] = to - numberToReserved;
    }

    /**
     * @dev Add a list of types
     * @notice Only admin can execute this function
     *
     * @param ids new ids
     * @param from first id for each type
     * @param to last id for each type
     * @param data array bytes containing: see addType()
     */
    function addTypes(
        uint256[] calldata ids,
        uint256[] calldata from,
        uint256[] calldata to,
        bytes[] calldata data
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < ids.length; i++) {
            addType(ids[i], from[i], to[i], data[i]);
        }
    }

    /**
     * @dev Updates the base URI
     * @notice Only admin can execute this function
     *
     * @param _newBaseURI new base URI
     */
    function updateBaseURI(string calldata _newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Executed before a withdraw
     * @notice Throw if box is locked (from BoxWithTimeLock)
     * @notice Throw if not owner or approved
     *
     * @param boxId id of the box
     */
    function _beforeWithdraw(uint256 boxId) internal override {
        super._beforeWithdraw(boxId);
        // Useless as the balance will be computed in the withdraw
        // require(_exists(boxId), "e15");
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
    }

    /**
     * @dev Executed before a store
     * @notice Throw if box is locked (from BoxWithTimeLock)
     * @notice Throw if crypto treasure does not exist
     * @notice Throw if not approved AND if store restriction is true
     * @notice Throw if crypto treasure has been destroyed (from BoxExternal)
     *
     * @param boxId id of the box
     */
    function _beforeStore(uint256 boxId) internal override {
        super._beforeStore(boxId);
        require(_exists(boxId), "e15");
        require(
            !_storeRestrictedToOwnerAndApproval[boxId] ||
                _isApprovedOrOwner(_msgSender(), boxId),
            "e7"
        );
    }

    /**
     * @dev Executed before a destroy
     * @notice Throw if box is locked (from BoxWithTimeLock)
     * @notice Throw if not approved
     * @notice Throw if crypto treasure has been destroyed (from BoxExternal)
     * @notice Throw if before destroy allowed timestamp
     *
     * @param boxId id of the box
     */
    function _beforeDestroy(uint256 boxId) internal override {
        super._beforeDestroy(boxId);
        require(_isApprovedOrOwner(_msgSender(), boxId), "e4");
        require(_isDestructionUnlocked(boxId), "e17");
    }

    /**
     * @dev Executed after a destroy
     * @notice Release the erc20 locked to the owner
     *
     * @param boxId id of the box
     */
    function _afterDestroy(uint256 boxId) internal override {
        _unlockMint(boxId);
    }

    /**
     * @dev Check if the crypto treasure passed the destroy lock
     *
     * @param boxId id of the box
     * @return true if the crypto treasure passed the destroy lock, false otherwise
     */
    function _isDestructionUnlocked(uint256 boxId)
        internal
        view
        returns (bool)
    {
        return _lockedDestructionEnd[boxId] <= block.timestamp;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Base URI for computing {tokenURI}
     * @return string baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}