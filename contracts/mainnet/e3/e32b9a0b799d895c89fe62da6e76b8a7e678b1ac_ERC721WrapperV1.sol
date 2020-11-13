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

// File: node_modules\eth-item-token-standard\IERC1155Views.sol

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

// File: node_modules\eth-item-token-standard\IBaseTokenData.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

interface IBaseTokenData {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// File: node_modules\eth-item-token-standard\IERC20Data.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



interface IERC20Data is IBaseTokenData, IERC20 {
    function decimals() external view returns (uint256);
}

// File: node_modules\eth-item-token-standard\IEthItemInteroperableInterface.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



interface IEthItemInteroperableInterface is IERC20, IERC20Data {

    function init(uint256 objectId, string memory name, string memory symbol, uint256 decimals) external;

    function mainInterface() external view returns (address);

    function objectId() external view returns (uint256);

    function mint(address owner, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function permitNonce(address sender) external view returns(uint256);

    function permit(address owner, address spender, uint value, uint8 v, bytes32 r, bytes32 s) external;

    function interoperableInterfaceVersion() external pure returns(uint256 ethItemInteroperableInterfaceVersion);
}

// File: eth-item-token-standard\IEthItemMainInterface.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;






interface IEthItemMainInterface is IERC1155, IERC1155Views, IBaseTokenData {

    function init(
        address interoperableInterfaceModel,
        string calldata name,
        string calldata symbol
    ) external;

    function mainInterfaceVersion() external pure returns(uint256 ethItemInteroperableVersion);

    function toInteroperableInterfaceAmount(uint256 objectId, uint256 ethItemAmount) external view returns (uint256 interoperableInterfaceAmount);

    function toMainInterfaceAmount(uint256 objectId, uint256 erc20WrapperAmount) external view returns (uint256 mainInterfaceAmount);

    function interoperableInterfaceModel() external view returns (address, uint256);

    function asInteroperable(uint256 objectId) external view returns (IEthItemInteroperableInterface);

    function emitTransferSingleEvent(address sender, address from, address to, uint256 objectId, uint256 amount) external;

    function mint(uint256 amount, string calldata partialUri)
        external
        returns (uint256, address);

    function burn(
        uint256 objectId,
        uint256 amount
    ) external;

    function burnBatch(
        uint256[] calldata objectIds,
        uint256[] calldata amounts
    ) external;

    event NewItem(uint256 indexed objectId, address indexed tokenAddress);
    event Mint(uint256 objectId, address tokenAddress, uint256 amount);
}

// File: models\common\IEthItemModelBase.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev This interface contains the commonn data provided by all the EthItem models
 */
interface IEthItemModelBase is IEthItemMainInterface {

    /**
     * @dev Contract Initialization, the caller of this method should be a Contract containing the logic to provide the EthItemERC20WrapperModel to be used to create ERC20-based objectIds
     * @param name the chosen name for this NFT
     * @param symbol the chosen symbol (Ticker) for this NFT
     */
    function init(string calldata name, string calldata symbol) external;

    /**
     * @return modelVersionNumber The version number of the Model, it should be progressive
     */
    function modelVersion() external pure returns(uint256 modelVersionNumber);

    /**
     * @return factoryAddress the address of the Contract which initialized this EthItem
     */
    function factory() external view returns(address factoryAddress);
}

// File: @openzeppelin\contracts\token\ERC721\IERC721Receiver.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// File: models\ERC721Wrapper\1\IERC721WrapperV1.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;



/**
 * @title ERC721 NFT-Based EthItem, version 1.
 * @dev All the wrapped ERC721 NFTs will be created following this Model.
 * The minting operation can be done only by transfering the original ERC721 Item through the classic safeTransferFrom call.
 * The burning operation will send back the original wrapped NFT.
 * To initalize it, the original 'init(address,string,string)' 
 * function of the EthItem Token Standard will be used, but the first address parameter will be the original ERC721 Source Contract to Wrap, and NOT the ERC20Model, which is always taken by the Contract who creates the Wrapper.
 * As the entire amount of the contract is always 1, the owner of the object can be the 
 */
interface IERC721WrapperV1 is IEthItemModelBase, IERC721Receiver {

    /**
     * @return sourceAddress The address of the original wrapped ERC721 NFT
     */
    function source() external view returns(address sourceAddress);
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
        // This method relies in extcodesize, which returns 0 for contracts in
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

// File: eth-item-token-standard\EthItemMainInterface.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;








/**
 * @title EthItem - An improved ERC1155 token with ERC20 trading capabilities.
 * @dev In the EthItem standard, there is no a centralized storage where to save every objectId info.
 * In fact every NFT data is saved in a specific ERC20 token that can also work as a standalone one, and let transfer parts of an atomic object.
 * The ERC20 represents a unique Token Id, and its supply represents the entire supply of that Token Id.
 * You can instantiate a EthItem as a brand-new one, or as a wrapper for pre-existent classic ERC1155 NFT.
 * In the first case, you can introduce some particular permissions to mint new tokens.
 * In the second case, you need to send your NFTs to the Wrapped EthItem (using the classic safeTransferFrom or safeBatchTransferFrom methods)
 * and it will create a brand new ERC20 Token or mint new supply (in the case some tokens with the same id were transfered before yours).
 */
contract EthItemMainInterface is IEthItemMainInterface, Context, ERC165 {
    using SafeMath for uint256;
    using Address for address;

    bytes4 internal constant _INTERFACEobjectId_ERC1155 = 0xd9b67a26;

    string internal _name;
    string internal _symbol;

    mapping(uint256 => string) internal _objectUris;

    mapping(uint256 => address) internal _dest;
    mapping(address => bool) internal _isMine;

    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    address internal _interoperableInterfaceModel;
    uint256 internal _interoperableInterfaceModelVersion;

    uint256 internal _decimals;

    /**
     * @dev Constructor
     * When you create a EthItem, you can specify if you want to create a brand new one, passing the classic data like name, symbol, amd URI,
     * or wrap a pre-existent ERC1155 NFT, passing its contract address.
     * You can use just one of the two modes at the same time.
     * In both cases, a ERC20 token address is mandatory. It will be used as a model to be cloned for every minted NFT.
     * @param erc20NFTWrapperModel the address of the ERC20 pre-deployed model. I will not be used in the procedure, but just cloned as a brand-new one every time a new NFT is minted.
     * @param name the name of the brand new EthItem to be created. If you are wrapping a pre-existing ERC1155 NFT, this must be blank.
     * @param symbol the symbol of the brand new EthItem to be created. If you are wrapping a pre-existing ERC1155 NFT, this must be blank.
     */
    constructor(
        address erc20NFTWrapperModel,
        string memory name,
        string memory symbol
    ) public {
        if(erc20NFTWrapperModel != address(0)) {
            init(erc20NFTWrapperModel, name, symbol);
        }
    }

    /**
     * @dev Utility method which contains the logic of the constructor.
     * This is a useful trick to instantiate a contract when it is cloned.
     */
    function init(
        address interoperableInterfaceModel,
        string memory name,
        string memory symbol
    ) public virtual override {
        require(
            _interoperableInterfaceModel == address(0),
            "Init already called!"
        );

        require(
            interoperableInterfaceModel != address(0),
            "Model should be a valid ethereum address"
        );
        _interoperableInterfaceModelVersion = IEthItemInteroperableInterface(_interoperableInterfaceModel = interoperableInterfaceModel).interoperableInterfaceVersion();
        require(
            keccak256(bytes(name)) != keccak256(""),
            "Name is mandatory"
        );
        require(
            keccak256(bytes(symbol)) != keccak256(""),
            "Symbol is mandatory"
        );

        _name = name;
        _symbol = symbol;
        _decimals = 18;

        _registerInterface(this.safeBatchTransferFrom.selector);
        _registerInterface(_INTERFACEobjectId_ERC1155);
        _registerInterface(this.balanceOf.selector);
        _registerInterface(this.balanceOfBatch.selector);
        _registerInterface(this.setApprovalForAll.selector);
        _registerInterface(this.isApprovedForAll.selector);
        _registerInterface(this.safeTransferFrom.selector);
        _registerInterface(this.uri.selector);
        _registerInterface(this.totalSupply.selector);
        _registerInterface(0x00ad800c); //name(uint256)
        _registerInterface(0x4e41a1fb); //symbol(uint256)
        _registerInterface(this.decimals.selector);
        _registerInterface(0x06fdde03); //name()
        _registerInterface(0x95d89b41); //symbol()
    }

    function mainInterfaceVersion() public pure virtual override returns(uint256) {
        return 1;
    }

    /**
     * @dev Mint
     * If the EthItem does not wrap a pre-existent NFT, this call is used to mint new NFTs, according to the permission rules provided by the Token creator.
     * @param amount The amount of tokens to be created. It must be greater than 1 unity.
     * @param objectUri The Uri to locate this new token's metadata.
     */
    function mint(uint256 amount, string memory objectUri)
        public
        virtual
        override
        returns (uint256 objectId, address tokenAddress)
    {
        require(
            amount > 1,
            "You need to pass more than a token"
        );
        require(
            keccak256(bytes(objectUri)) != keccak256(""),
            "Uri cannot be empty"
        );
        (objectId, tokenAddress) = _mint(msg.sender, amount);
        _objectUris[objectId] = objectUri;
    }

    /**
     * @dev Burn
     * You can choose to burn your NFTs.
     * In case this Token wraps a pre-existent ERC1155 NFT, you will receive the wrapped NFTs.
     */
    function burn(
        uint256 objectId,
        uint256 amount
    ) public virtual override {
        uint256[] memory objectIds = new uint256[](1);
        objectIds[0] = objectId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        _burn(msg.sender, objectIds, amounts);
        emit TransferSingle(msg.sender, msg.sender, address(0), objectId, amount);
    }

    /**
     * @dev Burn Batch
     * Same as burn, but for multiple NFTs at the same time
     */
    function burnBatch(
        uint256[] memory objectIds,
        uint256[] memory amounts
    ) public virtual override {
        _burn(msg.sender, objectIds, amounts);
        emit TransferBatch(msg.sender, msg.sender, address(0), objectIds, amounts);
    }

    function _burn(address owner, 
        uint256[] memory objectIds,
        uint256[] memory amounts) internal virtual {
        for (uint256 i = 0; i < objectIds.length; i++) {
            asInteroperable(objectIds[i]).burn(
                owner,
                toInteroperableInterfaceAmount(objectIds[i], amounts[i])
            );
        }
    }

    /**
     * @dev get the address of the ERC20 Contract used as a model
     */
    function interoperableInterfaceModel() public virtual override view returns (address, uint256) {
        return (_interoperableInterfaceModel, _interoperableInterfaceModelVersion);
    }

    /**
     * @dev Gives back the address of the ERC20 Token representing this Token Id
     */
    function asInteroperable(uint256 objectId)
        public
        virtual
        override
        view
        returns (IEthItemInteroperableInterface)
    {
        return IEthItemInteroperableInterface(_dest[objectId]);
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
        return toMainInterfaceAmount(objectId, asInteroperable(objectId).totalSupply());
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
        return asInteroperable(objectId).name();
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
        return asInteroperable(objectId).symbol();
    }

    function symbol() public virtual override view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the given token id
     */
    function decimals(uint256)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return 1;
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
        return _objectUris[objectId];
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
        return toMainInterfaceAmount(objectId, asInteroperable(objectId).balanceOf(account));
    }

    /**
     * @dev Classic ERC1155 Standard Method
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory objectIds
    ) public virtual override view returns (uint256[] memory balances) {
        balances = new uint256[](accounts.length);
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
        address operator = _msgSender();
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not owner nor approved"
        );

        asInteroperable(objectId).transferFrom(from, to, toInteroperableInterfaceAmount(objectId, amount));

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
            asInteroperable(objectIds[i]).transferFrom(
                from,
                to,
                toInteroperableInterfaceAmount(objectIds[i], amounts[i])
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
        uint256 entireAmount = toMainInterfaceAmount(objectId, amount);
        if(entireAmount == 0) {
            return;
        }
        emit TransferSingle(sender, from, to, objectId, entireAmount);
    }

    function toInteroperableInterfaceAmount(uint256 objectId, uint256 mainInterfaceAmount) public override virtual view returns (uint256 interoperableInterfaceAmount) {
        interoperableInterfaceAmount = mainInterfaceAmount * (10**asInteroperable(objectId).decimals());
    }

    function toMainInterfaceAmount(uint256 objectId, uint256 interoperableInterfaceAmount) public override virtual view returns (uint256 mainInterfaceAmount) {
        mainInterfaceAmount = interoperableInterfaceAmount / (10**asInteroperable(objectId).decimals());
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
        uint256 amount
    ) internal virtual returns (uint256 objectId, address wrapperAddress) {
        IEthItemInteroperableInterface wrapper = IEthItemInteroperableInterface(wrapperAddress = _clone(_interoperableInterfaceModel));
        _isMine[_dest[objectId = uint256(wrapperAddress)] = wrapperAddress] = true;
        wrapper.init(objectId, _name, _symbol, _decimals);
        wrapper.mint(from, amount * (10**_decimals));
        emit NewItem(objectId, wrapperAddress);
        emit Mint(objectId, wrapperAddress, amount);
        emit TransferSingle(address(this), address(0), from, objectId, amount);
    }
}

// File: orchestrator\IEthItemOrchestratorDependantElement.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


interface IEthItemOrchestratorDependantElement is IERC165 {

    /**
     * @dev GET - The DoubleProxy of the DFO linked to this Contract
     */
    function doubleProxy() external view returns (address);

    /**
     * @dev SET - The DoubleProxy of the DFO linked to this Contract
     * It can be done only by the Factory controller
     * @param newDoubleProxy the new DoubleProxy address
     */
    function setDoubleProxy(address newDoubleProxy) external;

    function isAuthorizedOrchestrator(address operator) external view returns(bool);
}

// File: factory\IEthItemFactory.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @title IEthItemFactory
 * @dev This contract represents the Factory Used to deploy all the EthItems, keeping track of them.
 */
interface IEthItemFactory is IEthItemOrchestratorDependantElement {

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the EthItemERC20Wrappers (please see the eth-item-token-standard for further information).
     */
    function ethItemInteroperableInterfaceModel() external view returns (address ethItemInteroperableInterfaceModelAddress, uint256 ethItemInteroperableInterfaceModelVersion);

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the EthItemERC20Wrappers (please see the eth-item-token-standard for further information).
     * It can be done only by the Factory controller
     */
    function setEthItemInteroperableInterfaceModel(address ethItemInteroperableInterfaceModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Native EthItems.
     * Every EthItem will have its own address, but the code will be cloned from this one.
     */
    function nativeModel() external view returns (address nativeModelAddress, uint256 nativeModelVersion);

    /**
     * @dev SET - The address of the Native EthItem model.
     * It can be done only by the Factory controller
     */
    function setNativeModel(address nativeModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC1155 EthItems.
     * Every EthItem will have its own address, but the code will be cloned from this one.
     */
    function erc1155WrapperModel() external view returns (address erc1155WrapperModelAddress, uint256 erc1155WrapperModelVersion);

    /**
     * @dev SET - The address of the ERC1155 NFT-Based EthItem model.
     * It can be done only by the Factory controller
     */
    function setERC1155WrapperModel(address erc1155WrapperModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC20 EthItems.
     */
    function erc20WrapperModel() external view returns (address erc20WrapperModelAddress, uint256 erc20WrapperModelVersion);

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC20 EthItems.
     * It can be done only by the Factory controller
     */
    function setERC20WrapperModel(address erc20WrapperModelAddress) external;

    /**
     * @dev GET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC721 EthItems.
     */
    function erc721WrapperModel() external view returns (address erc721WrapperModelAddress, uint256 erc721WrapperModelVersion);

    /**
     * @dev SET - The address of the Smart Contract whose code will serve as a model for all the Wrapped ERC721 EthItems.
     * It can be done only by the Factory controller
     */
    function setERC721WrapperModel(address erc721WrapperModelAddress) external;

    /**
     * @dev GET - The elements (numerator and denominator) useful to calculate the percentage fee to be transfered to the DFO for every new Minted EthItem
     */
    function mintFeePercentage() external view returns (uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator);

    /**
     * @dev SET - The element useful to calculate the Percentage fee
     * It can be done only by the Factory controller
     */
    function setMintFeePercentage(uint256 mintFeePercentageNumerator, uint256 mintFeePercentageDenominator) external;

    /**
     * @dev Useful utility method to calculate the percentage fee to transfer to the DFO for the minted EthItem amount.
     * @param erc20WrapperAmount The amount of minted EthItem
     */
    function calculateMintFee(uint256 erc20WrapperAmount) external view returns (uint256 mintFee, address dfoWalletAddress);

    /**
     * @dev GET - The elements (numerator and denominator) useful to calculate the percentage fee to be transfered to the DFO for every Burned EthItem
     */
    function burnFeePercentage() external view returns (uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator);

    /**
     * @dev SET - The element useful to calculate the Percentage fee
     * It can be done only by the Factory controller
     */
    function setBurnFeePercentage(uint256 burnFeePercentageNumerator, uint256 burnFeePercentageDenominator) external;

    /**
     * @dev Useful utility method to calculate the percentage fee to transfer to the DFO for the burned EthItem amount.
     * @param erc20WrapperAmount The amount of burned EthItem
     */
    function calculateBurnFee(uint256 erc20WrapperAmount) external view returns (uint256 burnFee, address dfoWalletAddress);

    /**
     * @dev Business Logic to create a brand-new EthItem.
     * It raises the 'NewNativeCreated' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createNative(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewNativeCreated(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewNativeCreated(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC1155 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC1155Created' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC1155(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC1155Created(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewWrappedERC1155Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC20 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC20Created' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC20(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC20Created(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewWrappedERC20Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);

    /**
     * @dev Business Logic to wrap already existing ERC721 Tokens to obtain a new NFT-Based EthItem.
     * It raises the 'NewWrappedERC721Created' events.
     * @param modelInitCallPayload The ABI-encoded input parameters to be passed to the model to phisically create the NFT.
     * It changes according to the Model Version.
     * @param ethItemAddress The address of the new EthItem
     * @param ethItemInitResponse The ABI-encoded output response eventually received by the Model initialization procedure.
     */
    function createWrappedERC721(bytes calldata modelInitCallPayload) external returns (address ethItemAddress, bytes memory ethItemInitResponse);

    event NewWrappedERC721Created(uint256 indexed standardVersion, uint256 indexed wrappedItemModelVersion, uint256 indexed modelVersion, address tokenCreated);
    event NewWrappedERC721Created(address indexed model, uint256 indexed modelVersion, address indexed tokenCreated, address creator);
}

// File: models\common\EthItemModelBase.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;




abstract contract EthItemModelBase is IEthItemModelBase, EthItemMainInterface(address(0), "", "") {

    address internal _factoryAddress;

    function init(
        address,
        string memory,
        string memory
    ) public virtual override(IEthItemMainInterface, EthItemMainInterface) {
        revert("Cannot directly call this method.");
    }

    function init(
        string memory name,
        string memory symbol
    ) public override virtual {
        require(_factoryAddress == address(0), "Init already called!");
        (address ethItemInteroperableInterfaceModelAddress,) = IEthItemFactory(_factoryAddress = msg.sender).ethItemInteroperableInterfaceModel();
        super.init(ethItemInteroperableInterfaceModelAddress, name, symbol);
    }

    function modelVersion() public override virtual pure returns(uint256) {
        return 1;
    }

    function factory() public override view returns (address) {
        return _factoryAddress;
    }

    function _sendMintFeeToDFO(address from, uint256 objectId, uint256 erc20WrapperAmount) internal virtual returns(uint256 mintFeeToDFO) {
        address dfoWallet;
        (mintFeeToDFO, dfoWallet) = IEthItemFactory(_factoryAddress).calculateMintFee(erc20WrapperAmount);
        if(mintFeeToDFO > 0 && dfoWallet != address(0)) {
            asInteroperable(objectId).transferFrom(from, dfoWallet, mintFeeToDFO);
        }
    }

    function _sendBurnFeeToDFO(address from, uint256 objectId, uint256 erc20WrapperAmount) internal virtual returns(uint256 burnFeeToDFO) {
        address dfoWallet;
        (burnFeeToDFO, dfoWallet) = IEthItemFactory(_factoryAddress).calculateBurnFee(erc20WrapperAmount);
        if(burnFeeToDFO > 0 && dfoWallet != address(0)) {
            asInteroperable(objectId).transferFrom(from, dfoWallet, burnFeeToDFO);
        }
    }

    function mint(uint256, string memory)
        public
        virtual
        override(IEthItemMainInterface, EthItemMainInterface)
        returns (uint256, address)
    {
        revert("Cannot directly call this method.");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 objectId,
        uint256 amount,
        bytes memory data
    ) public virtual override(IERC1155, EthItemMainInterface) {
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = _msgSender();
        require(
            from == operator || isApprovedForAll(from, operator),
            "ERC1155: caller is not owner nor approved"
        );

        _doERC20Transfer(from, to, objectId, amount);

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
    ) public virtual override(IERC1155, EthItemMainInterface) {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        for (uint256 i = 0; i < objectIds.length; i++) {
            _doERC20Transfer(from, to, objectIds[i], amounts[i]);
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

    function _doERC20Transfer(address from, address to, uint256 objectId, uint256 amount) internal virtual {
        (,uint256 result) = _getCorrectERC20ValueForTransferOrBurn(from, objectId, amount);
        asInteroperable(objectId).transferFrom(from, to, result);
    }

    function _getCorrectERC20ValueForTransferOrBurn(address from, uint256 objectId, uint256 amount) internal virtual view returns(uint256 balanceOfNormal, uint256 result) {
        uint256 toTransfer = toInteroperableInterfaceAmount(objectId, amount);
        uint256 balanceOfDecimals = asInteroperable(objectId).balanceOf(from);
        balanceOfNormal = balanceOf(from, objectId);
        result = amount == balanceOfNormal ? balanceOfDecimals : toTransfer;
    }

    function _burn(
        uint256 objectId,
        uint256 amount
    ) internal virtual returns(uint256 burnt, uint256 burnFeeToDFO) {
        (uint256 balanceOfNormal, uint256 result) = _getCorrectERC20ValueForTransferOrBurn(msg.sender, objectId, amount);
        require(balanceOfNormal >= amount, "Insufficient Amount");
        burnFeeToDFO = _sendBurnFeeToDFO(msg.sender, objectId, result);
        asInteroperable(objectId).burn(msg.sender, burnt = result - burnFeeToDFO);
    }

    function _isUnique(uint256 objectId) internal virtual view returns (bool unique, uint256 unity, uint256 totalSupply, uint256 erc20Decimals) {
        erc20Decimals = asInteroperable(objectId).decimals();
        unity = erc20Decimals <= 1 ? 1 : (10**erc20Decimals);
        totalSupply = asInteroperable(objectId).totalSupply();
        unique = totalSupply <= unity;
    }

    function toMainInterfaceAmount(uint256 objectId, uint256 interoperableInterfaceAmount) public virtual view override(IEthItemMainInterface, EthItemMainInterface) returns (uint256 mainInterfaceAmount) {
        (bool unique, uint256 unity,, uint256 erc20Decimals) = _isUnique(objectId);
        if(unique && interoperableInterfaceAmount < unity) {
            uint256 half = (unity * 51) / 100;
            return mainInterfaceAmount = interoperableInterfaceAmount <= half ? 0 : 1;
        }
        return mainInterfaceAmount = interoperableInterfaceAmount / (10**erc20Decimals);
    }
}

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.2;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


// File: @openzeppelin\contracts\token\ERC721\IERC721Metadata.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.6.2;


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

// File: models\ERC721Wrapper\1\ERC721WrapperV1.sol

//SPDX_License_Identifier: MIT

pragma solidity ^0.6.0;





contract ERC721WrapperV1 is IERC721WrapperV1, EthItemModelBase {

    address internal _source;
    bool internal _idAsName;

    function init(
        address source,
        string memory name,
        string memory symbol
    ) public virtual override(IEthItemMainInterface, EthItemModelBase) {
        require(source != address(0), "Source cannot be void");
        _source = source;
        super.init(name, symbol);
        _idAsName = keccak256(bytes(name)) == keccak256(bytes(_toString(_source)));
        _registerInterface(this.onERC721Received.selector);
    }

    function source() public override view returns (address) {
        return _source;
    }

    function uri(uint256 objectId)
        public
        virtual
        override
        view
        returns (string memory)
    {
        return IERC721Metadata(_source).tokenURI(objectId);
    }

    function onERC721Received(
        address,
        address owner,
        uint256 objectId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(msg.sender == _source, "Unauthorized action!");
        _mint(owner, objectId);
        return this.onERC721Received.selector;
    }

    function burn(
        uint256 objectId,
        uint256 amount
    ) public virtual override {
        _burn(objectId, amount);
        emit TransferSingle(msg.sender, msg.sender, address(0), objectId, amount);
    }

    function burnBatch(
        uint256[] memory objectIds,
        uint256[] memory amounts
    ) public virtual override {
        for (uint256 i = 0; i < objectIds.length; i++) {
            _burn(objectIds[i], amounts[i]);
        }
        emit TransferBatch(msg.sender, msg.sender, address(0), objectIds, amounts);
    }

    function _burn(
        uint256 objectId,
        uint256 amount
    ) internal virtual override returns(uint256, uint256) {
        super._burn(objectId, amount);
        IERC721(_source).safeTransferFrom(address(this), msg.sender, objectId, "");
    }

    function _mint(
        address from,
        uint256 objectIdInput
    ) internal virtual override returns (uint256 objectId, address wrapperAddress) {
        wrapperAddress = _dest[objectId = objectIdInput];
        if (wrapperAddress == address(0)) {
            (address interoperableInterfaceModelAddress,) = interoperableInterfaceModel();
            _isMine[_dest[objectId] = wrapperAddress = _clone(interoperableInterfaceModelAddress)] = true;
            string memory name = _idAsName ? _toString(objectId) : _name;
            IEthItemInteroperableInterface(wrapperAddress).init(objectId, name, _symbol, _decimals);
            emit NewItem(objectId, wrapperAddress);
        }
        uint256 toMint = (10**_decimals) - asInteroperable(objectId).totalSupply();
        asInteroperable(objectId).mint(from, toMint);
        uint256 mintFeeToDFO = _sendMintFeeToDFO(from, objectId, toMint);
        uint256 nftAmount = toMainInterfaceAmount(objectId, toMint - mintFeeToDFO);
        if(nftAmount > 0) {
            emit Mint(objectId, wrapperAddress, nftAmount);
            emit TransferSingle(address(this), address(0), from, objectId, nftAmount);
        }
    }

    function _toString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function _toString(uint _i) internal pure returns(string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}