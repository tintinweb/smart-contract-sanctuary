// File: node_modules\@openzeppelin\contracts\introspection\IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.2;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
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

// File: @openzeppelin\contracts\token\ERC1155\IERC1155Receiver.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


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

// File: contracts\standalone\IERC1155Views.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title IERC1155Views - An optional utility interface to improve the ERC-1155 Standard.
 * @dev This interface introduces some additional capabilities for ERC-1155 Tokens.
 */
interface IERC1155Views {

    /**
     * @dev Returns the total supply of the given token id
     * @param objectId the id of the token whose availability you want to know 
     */
    function totalSupply(uint256 objectId) external view returns (uint256);

    /**
     * @dev Returns the name of the given token id
     * @param objectId the id of the token whose name you want to know 
     */
    function name(uint256 objectId) external view returns (string memory);

    /**
     * @dev Returns the symbol of the given token id
     * @param objectId the id of the token whose symbol you want to know 
     */
    function symbol(uint256 objectId) external view returns (string memory);

    /**
     * @dev Returns the decimals of the given token id
     * @param objectId the id of the token whose decimals you want to know 
     */
    function decimals(uint256 objectId) external view returns (uint256);

    /**
     * @dev Returns the uri of the given token id
     * @param objectId the id of the token whose uri you want to know 
     */
    function uri(uint256 objectId) external view returns (string memory);
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

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

// File: contracts\standalone\IERC20NFTWrapper.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


interface IERC20NFTWrapper is IERC20 {
    function init(uint256 objectId) external;

    function mainWrapper() external view returns (address);

    function objectId() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function mint(address owner, uint256 amount) external;

    function burn(address owner, uint256 amount) external;
}

// File: contracts\standalone\IERC1155Data.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

interface IERC1155Data {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// File: contracts\standalone\ISuperSaiyanToken.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;






interface ISuperSaiyanToken is IERC1155, IERC1155Receiver, IERC1155Views, IERC1155Data {
    function init(
        address model,
        address source,
        string calldata name,
        string calldata symbol
    ) external;

    function fromDecimals(uint256 objectId, uint256 amount)
        external
        view
        returns (uint256);

    function toDecimals(uint256 objectId, uint256 amount)
        external
        view
        returns (uint256);

    function getMintData(uint256 objectId)
        external
        view
        returns (
            string memory,
            string memory,
            uint256
        );

    function getModel() external view returns (address);

    function source() external view returns (address);

    function asERC20(uint256 objectId) external view returns (IERC20NFTWrapper);

    function emitTransferSingleEvent(address sender, address from, address to, uint256 objectId, uint256 amount) external;

    function mint(uint256 amount, string calldata partialUri)
        external
        returns (uint256, address);

    function burn(
        uint256 objectId,
        uint256 amount,
        bytes calldata data
    ) external;

    function burnBatch(
        uint256[] calldata objectIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    event Mint(uint256 objectId, address tokenAddress);
}

// File: contracts\standalone\voting\IDFOSuperSaiyanToken.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


interface IDFOSuperSaiyanToken is ISuperSaiyanToken {

    function doubleProxy() external view returns(address);
    function setDoubleProxy(address newDoubleProxy) external;
    function setUri(uint256 objectId, string calldata uri) external;

    event UriChanged(uint256 indexed objectId, string oldUri, string newUri);
}

interface IDoubleProxy {
    function proxy() external view returns(address);
}

interface IMVDProxy {
    function getToken() external view returns(address);
    function getStateHolderAddress() external view returns(address);
    function getMVDWalletAddress() external view returns(address);
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDFunctionalityProposalManagerAddress() external view returns(address);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
}

interface IStateHolder {
    function setUint256(string calldata name, uint256 value) external returns(uint256);
    function getUint256(string calldata name) external view returns(uint256);
    function getBool(string calldata varName) external view returns (bool);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

// File: @openzeppelin\contracts\GSN\Context.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\math\SafeMath.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin\contracts\utils\Address.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin\contracts\introspection\ERC165.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
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
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
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

// File: contracts\standalone\SuperSaiyanToken.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;








/**
 * @title SuperSaiyanToken - An improved ERC1155 token with ERC20 trading capabilities.
 * @dev In the SuperSaiyanToken standard, there is no a centralized storage where to save every objectId info.
 * In fact every NFT data is saved in a specific ERC20 token that can also work as a standalone one, and let transfer parts of an atomic object.
 * The ERC20 represents a unique Token Id, and its supply represents the entire supply of that Token Id.
 * You can instantiate a SuperSaiyanToken as a brand-new one, or as a wrapper for pre-existent classic ERC1155 NFT.
 * In the first case, you can introduce some particular permissions to mint new tokens.
 * In the second case, you need to send your NFTs to the Wrapped SuperSaiyanToken (using the classic safeTransferFrom or safeBatchTransferFrom methods)
 * and it will create a brand new ERC20 Token or mint new supply (in the case some tokens with the same id were transfered before yours).
 */
contract SuperSaiyanToken is ISuperSaiyanToken, Context, ERC165 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 internal constant _INTERFACEobjectId_ERC1155 = 0xd9b67a26;

    address private _source;

    string internal _name;
    string internal _symbol;

    mapping(uint256 => string) internal _objectUris;

    bool private _supportsName;
    bool private _supportsSymbol;
    bool private _supportsDecimals;

    mapping(uint256 => address) internal _dest;
    mapping(address => bool) internal _isMine;

    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    address internal _model;

    /**
     * @dev Constructor
     * When you create a SuperSaiyanToken, you can specify if you want to create a brand new one, passing the classic data like name, symbol, amd URI,
     * or wrap a pre-existent ERC1155 NFT, passing its contract address.
     * You can use just one of the two modes at the same time.
     * In both cases, a ERC20 token address is mandatory. It will be used as a model to be cloned for every minted NFT.
     * @param model the address of the ERC20 pre-deployed model. I will not be used in the procedure, but just cloned as a brand-new one every time a new NFT is minted.
     * @param source the address of the ERC1155 NFT to be wrapped. If you want to create a brand new NFT, this value must be address(0).
     * @param name the name of the brand new SuperSaiyanToken to be created. If you are wrapping a pre-existing ERC1155 NFT, this must be blank.
     * @param symbol the symbol of the brand new SuperSaiyanToken to be created. If you are wrapping a pre-existing ERC1155 NFT, this must be blank.
     */
    constructor(
        address model,
        address source,
        string memory name,
        string memory symbol
    ) public {
        if(model != address(0)) {
            init(model, source, name, symbol);
        }
    }

    /**
     * @dev Utility method which contains the logic of the constructor.
     * This is a useful trick to instantiate a contract when it is cloned.
     */
    function init(
        address model,
        address source,
        string memory name,
        string memory symbol
    ) public virtual override {
        require(
            _model == address(0),
            "Init already called!"
        );

        require(
            model != address(0),
            "Model should be a valid ethereum address"
        );
        _model = model;

        _source = source;

        require(
            _source != address(0) || keccak256(bytes(name)) != keccak256(""),
            "At least a source contract or a name must be set"
        );
        require(
            _source != address(0) || keccak256(bytes(symbol)) != keccak256(""),
            "At least a source contract or a symbol must be set"
        );

        _registerInterface(this.onERC1155Received.selector);
        _registerInterface(this.onERC1155BatchReceived.selector);
        bool safeBatchTransferFrom = _checkAndInsertSelector(
            this.safeBatchTransferFrom.selector
        );
        bool cumulativeInterface = _checkAndInsertSelector(
            _INTERFACEobjectId_ERC1155
        );
        require(
            _source == address(0) ||
                safeBatchTransferFrom ||
                cumulativeInterface,
            "Looks like you're not wrapping a correct ERC1155 Token"
        );
        _checkAndInsertSelector(this.balanceOf.selector);
        _checkAndInsertSelector(this.balanceOfBatch.selector);
        _checkAndInsertSelector(this.setApprovalForAll.selector);
        _checkAndInsertSelector(this.isApprovedForAll.selector);
        _checkAndInsertSelector(this.safeTransferFrom.selector);
        _checkAndInsertSelector(this.uri.selector);
        _checkAndInsertSelector(this.totalSupply.selector);
        _supportsName = _checkAndInsertSelector(0x00ad800c); //name(uint256)
        _supportsSymbol = _checkAndInsertSelector(0x4e41a1fb); //symbol(uint256)
        _supportsDecimals = _checkAndInsertSelector(this.decimals.selector);
        _supportsDecimals = _source == address(0) ? false : _supportsDecimals;
        _setAndCheckNameAndSymbol(name, symbol);
    }

    /**
     * @dev Mint
     * If the SuperSaiyanToken does not wrap a pre-existent NFT, this call is used to mint new NFTs, according to the permission rules provided by the Token creator.
     * @param amount The amount of tokens to be created. It must be greater than 1 unity.
     * @param objectUri The Uri to locate this new token's metadata.
     */
    function mint(uint256 amount, string memory objectUri)
        public
        virtual
        override
        returns (uint256 objectId, address tokenAddress)
    {
        require(_source == address(0), "Cannot mint unexisting tokens");
        require(
            keccak256(bytes(objectUri)) != keccak256(""),
            "Uri cannot be empty"
        );
        (objectId, tokenAddress) = _mint(msg.sender, 0, amount, true);
        _objectUris[objectId] = objectUri;
    }

    /**
     * @dev Burn
     * You can choose to burn your NFTs.
     * In case this Token wraps a pre-existent ERC1155 NFT, you will receive the wrapped NFTs.
     */
    function burn(
        uint256 objectId,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        asERC20(objectId).burn(msg.sender, toDecimals(objectId, amount));
        if (_source != address(0)) {
            IERC1155(_source).safeTransferFrom(
                address(this),
                msg.sender,
                objectId,
                amount,
                data
            );
        }
    }

    /**
     * @dev Burn Batch
     * Same as burn, but for multiple NFTs at the same time
     */
    function burnBatch(
        uint256[] memory objectIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        for (uint256 i = 0; i < objectIds.length; i++) {
            asERC20(objectIds[i]).burn(
                msg.sender,
                toDecimals(objectIds[i], amounts[i])
            );
        }
        if (_source != address(0)) {
            IERC1155(_source).safeBatchTransferFrom(
                address(this),
                msg.sender,
                objectIds,
                amounts,
                data
            );
        }
    }

    /**
     * @dev classic ERC-1155 onERC1155Received hook.
     * This method can be called only by the wrapped classic ERC1155 NFT, if it exists.
     * Call this method means that someone transfer original NFTs to receive wrapped ones.
     * So this method will provide brand new NFTs
     */
    function onERC1155Received(
        address,
        address owner,
        uint256 objectId,
        uint256 amount,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(msg.sender == _source, "Unauthorized action!");
        _mint(owner, objectId, amount, false);
        return this.onERC1155Received.selector;
    }

    /**
     * @dev classic ERC-1155 onERC1155BatchReceived hook.
     * Same as onERC1155Received, but for multiple tokens at the same time
     */
    function onERC1155BatchReceived(
        address,
        address owner,
        uint256[] memory objectIds,
        uint256[] memory amounts,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(msg.sender == _source, "Unauthorized action!");
        for (uint256 i = 0; i < objectIds.length; i++) {
            _mint(owner, objectIds[i], amounts[i], false);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev this method sends the correct creation parameters for the new ERC-20 to be minted.
     * It takes thata from the wrapped ERC1155 NFT or from the parameters passed at construction time.
     */
    function getMintData(uint256 objectId)
        public
        virtual
        override
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 decimals
        )
    {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        if (
            _source != address(0) &&
            (_supportsName || _supportsSymbol || _supportsDecimals)
        ) {
            IERC1155Views views = IERC1155Views(_source);
            name = _supportsName ? views.name(objectId) : name;
            symbol = _supportsSymbol ? views.symbol(objectId) : symbol;
            decimals = _supportsDecimals ? views.decimals(objectId) : decimals;
        }
    }

    /**
     * @dev get the address of the ERC20 Contract used as a model
     */
    function getModel() public virtual override view returns (address) {
        return _model;
    }

    /**
     * @dev Utility method to convert from decimals notation the original NFT (if any) to the ERC20 ones.
     */
    function fromDecimals(uint256 objectId, uint256 amount)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _supportsDecimals ? amount : (amount / (10**decimals(objectId)));
    }

    /**
     * @dev Utility method to convert to decimals notation the original NFT (if any) to the ERC20 ones.
     */
    function toDecimals(uint256 objectId, uint256 amount)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _supportsDecimals ? amount : (amount * (10**decimals(objectId)));
    }

    /**
     * @dev Returns the address of the wrapped ERC1155 NFT (if any)
     */
    function source() public virtual override view returns (address) {
        return _source;
    }

    /**
     * @dev Gives back the address of the ERC20 Token representing this Token Id
     */
    function asERC20(uint256 objectId)
        public
        virtual
        override
        view
        returns (IERC20NFTWrapper)
    {
        return IERC20NFTWrapper(_dest[objectId]);
    }

    /**
     * @dev Returns the total supply of the given token id
     * @param objectId the id of the token whose availability you want to know
     */
    function totalSupply(uint256 objectId)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return fromDecimals(objectId, asERC20(objectId).totalSupply());
    }

    /**
     * @dev Returns the name of the given token id
     * @param objectId the id of the token whose name you want to know
     */
    function name(uint256 objectId)
        public
        virtual
        override
        view
        returns (string memory)
    {
        return asERC20(objectId).name();
    }

    function name() public virtual override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the given token id
     * @param objectId the id of the token whose symbol you want to know
     */
    function symbol(uint256 objectId)
        public
        virtual
        override
        view
        returns (string memory)
    {
        return asERC20(objectId).symbol();
    }

    function symbol() public virtual override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the given token id
     * @param objectId the id of the token whose decimals you want to know
     */
    function decimals(uint256 objectId)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return asERC20(objectId).decimals();
    }

    /**
     * @dev Returns the uri of the given token id
     * @param objectId the id of the token whose uri you want to know
     */
    function uri(uint256 objectId)
        public
        virtual
        override
        view
        returns (string memory)
    {
        return
            _source == address(0)
                ? _objectUris[objectId]
                : IERC1155Views(_source).uri(objectId);
    }

    /**
     * @dev Classic ERC1155 Standard Method
     */
    function balanceOf(address account, uint256 objectId)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return fromDecimals(objectId, asERC20(objectId).balanceOf(account));
    }

    /**
     * @dev Classic ERC1155 Standard Method
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory objectIds
    ) public virtual override view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            balances[i] = balanceOf(accounts[i], objectIds[i]);
        }
    }

    /**
     * @dev Classic ERC1155 Standard Method
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        address sender = _msgSender();
        require(
            sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /**
     * @dev Classic ERC1155 Standard Method
     */
    function isApprovedForAll(address account, address operator)
        public
        virtual
        override
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Classic ERC1155 Standard Method
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 objectId,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        asERC20(objectId).transferFrom(from, to, toDecimals(objectId, amount));

        emit TransferSingle(operator, from, to, objectId, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            from,
            to,
            objectId,
            amount,
            data
        );
    }

    /**
     * @dev Classic ERC1155 Standard Method
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory objectIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        for (uint256 i = 0; i < objectIds.length; i++) {
            asERC20(objectIds[i]).transferFrom(
                from,
                to,
                toDecimals(objectIds[i], amounts[i])
            );
        }

        address operator = _msgSender();

        emit TransferBatch(operator, from, to, objectIds, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            objectIds,
            amounts,
            data
        );
    }

    function emitTransferSingleEvent(address sender, address from, address to, uint256 objectId, uint256 amount) public override {
        require(_dest[objectId] == msg.sender, "Unauthorized Action!");
        uint256 entireAmount = fromDecimals(objectId, amount);
        if(entireAmount == 0) {
            return;
        }
        emit TransferSingle(sender, from, to, objectId, entireAmount);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver(to).onERC1155Received.selector
                ) {
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
    ) internal virtual {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155Receiver(to).onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _checkAndInsertSelector(bytes4 selector)
        internal
        virtual
        returns (bool response)
    {
        if (_source == address(0)) {
            _registerInterface(selector);
            return true;
        }
        try ERC165(_source).supportsInterface(selector) returns (bool res) {
            if (response = res) {
                _registerInterface(selector);
            }
        } catch {}
    }

    function _clone(address original) internal returns (address copy) {
        assembly {
            mstore(
                0,
                or(
                    0x5880730000000000000000000000000000000000000000803b80938091923cF3,
                    mul(original, 0x1000000000000000000)
                )
            )
            copy := create(0, 0, 32)
            switch extcodesize(copy)
                case 0 {
                    invalid()
                }
        }
    }

    function _mint(
        address from,
        uint256 oldObjectId,
        uint256 amount,
        bool generateObjectId
    ) internal virtual returns (uint256, address) {
        uint256 objectId = oldObjectId;
        IERC20NFTWrapper wrapper = IERC20NFTWrapper(_dest[objectId]);
        if (_dest[objectId] == address(0) || generateObjectId) {
            require(
                amount > _getTokenUnity(objectId),
                "You need to pass more than a token"
            );
            wrapper = IERC20NFTWrapper(_clone(getModel()));
            if(generateObjectId) {
                objectId = uint256(address(wrapper));
            }
            wrapper.init(objectId);
            _isMine[_dest[objectId] = address(wrapper)] = true;
            emit Mint(objectId, address(wrapper));
        }
        wrapper.mint(from, _convertForMint(objectId, amount));
        emit TransferSingle(address(this), address(0), from, objectId, amount);
        return (objectId, address(wrapper));
    }

    function _getTokenUnity(uint256 objectId)
        internal
        virtual
        view
        returns (uint256)
    {
        if (_source == address(0)) {
            return (10**18);
        }
        if (_supportsDecimals) {
            return (10**IERC1155Views(_source).decimals(objectId));
        }
        return 1;
    }

    function _convertForMint(uint256 objectId, uint256 amount)
        internal
        virtual
        view
        returns (uint256)
    {
        if (_source != address(0) && _supportsDecimals) {
            return amount * (10**IERC1155Views(_source).decimals(objectId));
        }
        return amount;
    }

    function _setAndCheckNameAndSymbol(
        string memory inputName,
        string memory inputSymbol
    ) internal virtual {
        _name = inputName;
        _symbol = inputSymbol;
        if (_source != address(0)) {
            IERC1155Data data = IERC1155Data(_source);
            try data.name() returns (string memory n) {
                _name = n;
            } catch {}
            try data.symbol() returns (string memory s) {
                _symbol = s;
            } catch {}
        }
        require(keccak256(bytes(_name)) != keccak256(""), "Name is mandatory");
        require(
            keccak256(bytes(_symbol)) != keccak256(""),
            "Symbol is mandatory"
        );
    }
}

// File: contracts\standalone\voting\DFOSuperSaiyanToken.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



/**
 * @title DFOSuperSaiyanToken
 */
contract DFOSuperSaiyanToken is IDFOSuperSaiyanToken, SuperSaiyanToken(address(0), address(0), "", "") {

    address private _doubleProxy;

    constructor(
        address model,
        address doubleProxy,
        string memory name,
        string memory symbol
    ) public {
        if(model != address(0)) {
            init(model, doubleProxy, name, symbol);
        }
    }

    function init(
        address model,
        address doubleProxy,
        string memory name,
        string memory symbol
    ) public override(ISuperSaiyanToken, SuperSaiyanToken) {
        super.init(model, address(0), name, symbol);
        _doubleProxy = doubleProxy;
    }

    modifier byDFO {
        if(_doubleProxy != address(0)) {
            require(IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized Action!");
        }
        _;
    }

    function doubleProxy() public override view returns(address) {
        return _doubleProxy;
    }

    function setDoubleProxy(address newDoubleProxy) public override byDFO {
        _doubleProxy = newDoubleProxy;
    }

    function mint(uint256 amount, string memory objectUri)
        public
        virtual
        override(ISuperSaiyanToken, SuperSaiyanToken)
        byDFO
        returns (uint256 objectId, address tokenAddress)
    {
        (objectId, tokenAddress) = super.mint(amount, objectUri);
        emit UriChanged(objectId, "", objectUri);
    }

    function setUri(uint256 objectId, string memory newUri) public byDFO override {
        emit UriChanged(objectId, _objectUris[objectId], newUri);
        _objectUris[objectId] = newUri;
    }
}