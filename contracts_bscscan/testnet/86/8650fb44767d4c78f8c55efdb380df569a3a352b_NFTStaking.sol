/**
 *Submitted for verification at BscScan.com on 2021-12-30
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract TokenList {

    // "Listed" (hard-coded) tokens
    address private constant natureToken = 0x729b71473d933757b52067341e0d69042466DD75;
    // Index of _extraTokens[0] + 1
    uint256 private constant extraTokensStartId = 2;

    enum TokenType {unknown, Erc20, Erc721, Erc1155}

    struct Token {
        address addr;
        TokenType _type;
        uint8 decimals;
    }

    // Extra tokens (addition to the hard-coded tokens list)
    Token[] private _extraTokens;

    function _listedToken(
        uint8 tokenId
    ) internal pure virtual returns(address, TokenType, uint8 decimals) {
        if (tokenId == 1) return (natureToken, TokenType.Erc20, 18);

        return (address(0), TokenType.unknown, 0);
    }

    function _tokenAddr(uint8 tokenId) internal view returns(address) {
        (address addr,, ) = _token(tokenId);
        return addr;
    }

    function _token(
        uint8 tokenId
    ) internal view returns(address, TokenType, uint8 decimals) {
        if (tokenId < extraTokensStartId) return _listedToken(tokenId);

        uint256 i = tokenId - extraTokensStartId;
        Token memory token = _extraTokens[i];
        return (token.addr, token._type, token.decimals);
    }

    function _addTokens(
        address[] memory addresses,
        TokenType[] memory types,
        uint8[] memory decimals
    ) internal {
        require(
            addresses.length == types.length && addresses.length == decimals.length,
            "TokList:INVALID_LISTS_LENGTHS"
        );
        require(
            addresses.length + _extraTokens.length + extraTokensStartId <= 256,
            "TokList:TOO_MANY_TOKENS"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "TokList:INVALID_TOKEN_ADDRESS");
            require(types[i] != TokenType.unknown, "TokList:INVALID_TOKEN_TYPE");
            _extraTokens.push(Token(addresses[i], types[i], decimals[i]));
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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


library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeBEP20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeBEP20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

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


// File @openzeppelin/contracts/token/ERC1155/[email protected]

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

// File @openzeppelin/contracts/introspection/[email protected]

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

    constructor () public {
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
interface IBEP20 {
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
/**
 * It accepts deposits of a pre-defined ERC-20 token(s), the "deposit" token.
 * The deposit token will be repaid with another ERC-20 token, the "repay"
 * token (e.g. a stable-coin), at a pre-defined rate.
 *
 * On top of the deposit token, a particular NFT (ERC-1155) instance may be
 * required to be deposited as well. If so, this exact NFT will be returned.
 *
 * Note the `treasury` account that borrows and repays tokens.
 */


/**
 * It accepts deposits of a pre-defined ERC-20 token(s), the "deposit" token.
 * The deposit token will be repaid with another ERC-20 token, the "repay"
 * token (e.g. a stable-coin), at a pre-defined rate.
 *
 * On top of the deposit token, a particular NFT (ERC-721) instance may be
 * required to be deposited as well. If so, this exact NFT will be returned.
 *
 * Note the `treasury` account that borrows and repays tokens.
 */
contract NFTStaking is Ownable, ReentrancyGuard, TokenList {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // On a deposit withdrawal, a user receives the "repay" token
    // (but not the originally deposited ERC-20 token).
    // The amount (in the  "repay" token units) to be repaid is:
    // `amountDue = Deposit.amount * TermSheet.rate/1e+9`                (1)

    // If interim withdrawals allowed, the amount which can not be withdrawn
    // before the deposit period ends is:
    // `minBalance = Deposit.amountDue * Deposit.lockedShare / 65535`    (2)
    //
    // (note: `TermSheet.earlyRepayableShare` defines `Deposit.lockedShare`)

    // Limit on the deposited ERC-20 token amount
    struct Limit {
        // Min token amount to deposit
        uint224 minAmount;
        // Max deposit amount multiplier, scaled by 1e+4
        // (no limit, if set to 0):
        // `maxAmount = minAmount * maxAmountFactor/1e4`
        uint32 maxAmountFactor;
    }

    // Terms of deposit(s)
    struct TermSheet {
        // Remaining number of deposits allowed under this term sheet
        // (if set to zero, deposits disabled; 255 - no limitations applied)
        uint8 availableQty;
        // ID of the ERC-20 token to deposit
        uint8 inTokenId;
        // ID of the ERC-721 token (contract) to deposit
        // (if set to 0, no ERC-721 token is required to be deposited)
        uint8 nfTokenId;
        // ID of the ERC-20 token to return instead of the deposited token
        uint8 outTokenId;
        // Maximum amount that may be withdrawn before the deposit period ends,
        // in 1/255 shares of the deposit amount.
        // The amount linearly increases from zero to this value with time.
        // (if set to zero, early withdrawals are disabled)
        uint8 earlyRepayableShare;
        // Fees on early withdrawal, in 1/255 shares of the amount withdrawn
        // (fees linearly decline to zero towards the repayment time)
        // (if set to zero, no fees charged)
        uint8 earlyWithdrawFees;
        // ID of the deposit amount limit (equals to: index in `_limits` + 1)
        // (if set to 0, no limitations on the amount applied)
        uint16 limitId;
        // Deposit period in hours
        uint16 depositHours;
        // Min time between interim (early) withdrawals
        // (if set to 0, no limits on interim withdrawal time)
        uint16 minInterimHours;
        // Rate to compute the "repay" amount, scaled by 1e+9 (see (1))
        uint64 rate;
        // Bit-mask for NFT IDs (in the range 1..64) allowed to deposit
        // (if set to 0, no limitations on NFT IDs applied)
        uint64 allowedNftNumBitMask;
    }

    struct Roll {
        uint32 timeDeposit;
        uint32 lastRoll;
        uint256 rate;
    }

    struct UserRolls {
        // Set of (unique) roll IDs
        uint256[] ids;
        // Mapping from roll ID to roll data
        mapping(uint256 => Roll) data;
    }

    // Parameters of a deposit
    struct Deposit {
        uint176 amountDue;      // Amount due, in "repay" token units
        uint32 maturityTime;    // Time the final withdrawal is allowed since
        uint32 lastWithdrawTime;// Time of the most recent interim withdrawal
        uint16 lockedShare;     // in 1/65535 shares of `amountDue` (see (2))
        // Note:
        // - the depositor account and the deposit ID linked via mappings
        // - other props (eg.: `termsId`) encoded within the ID of a deposit
    }

    // Deposits of a user
    struct UserDeposits {
        // Set of (unique) deposit IDs
        uint256[] ids;
        // Mapping from deposit ID to deposit data
        mapping(uint256 => Deposit) data;
    }

    // Number of deposits made so far
    uint32 public depositQty;

    // Account that controls the tokens deposited
    address public treasury;

    // Limits on "deposit" token amount
    Limit[] private _limits;

    // Info on each TermSheet
    TermSheet[] internal _termSheets;

    // Mappings from a "repay" token ID to the total amount due
    mapping(uint256 => uint256) public totalDue; // in "repay" token units

    // Mapping from user account to user deposits
    mapping(address => UserDeposits) internal _deposits;

    // Mapping from user account to user rolls
    mapping(address => UserRolls) internal _rolls;

    mapping(uint256 => mapping(address=> uint256[])) public termIDToDepositId;

    mapping(uint256 => mapping(address => uint256)) public latestDeposit;



    event NewDeposit(
        uint256 indexed inTokenId,
        uint256 indexed outTokenId,
        address indexed user,
        uint256 depositId,
        uint256 termsId,
        uint256 amount, // amount deposited (in deposit token units)
        uint256 amountDue, // amount to be returned (in "repay" token units)
        uint256 maturityTime // UNIX-time when the deposit is unlocked
    );

    // User withdraws the deposit
    event Withdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount // amount sent to user (in deposit token units)
    );

    event InterimWithdraw(
        address indexed user,
        uint256 depositId,
        uint256 amount, // amount sent to user (in "repay" token units)
        uint256 fees // withheld fees (in "repay" token units)
    );

    // termsId is the index in the `_termSheets` array + 1
    event NewTermSheet(uint256 indexed termsId);
    event TermsEnabled(uint256 indexed termsId);
    event TermsDisabled(uint256 indexed termsId);
    
    mapping(uint256 => mapping(address => bool)) public _hasDeposit;

    uint256 public OVERALL_PROBABILITY = 1000000;
    

    uint256 internal seed = 12345678;
    constructor(address _treasury) public {
        _setTreasury(_treasury);
    }

    function depositIds(
        address user
    ) external view returns (uint256[] memory) {
        _revertZeroAddress(user);
        UserDeposits storage userDeposits = _deposits[user];
        return userDeposits.ids;
    }

    function depositData(
        address user,
        uint256 depositId
    ) external view returns(uint256 termsId, Deposit memory params, Roll memory rollparams) {
        params = _deposits[_nonZeroAddr(user)].data[depositId];
        rollparams = _rolls[_nonZeroAddr(user)].data[depositId];
        termsId = 0;
        if (params.maturityTime !=0) {
            (termsId, , , ) = _decodeDepositId(depositId);
        }
    }

    function depositDataV2(
        address user,
        uint256 _termsId
    ) external view returns(bool hasDeposit,Deposit memory params, Roll memory rollparams) {
        _revertZeroAddress(user);
        hasDeposit = _hasDeposit[_termsId][user];
        if(hasDeposit){
            UserDeposits storage userDeposits = _deposits[user];
            uint256 depositId = userDeposits.ids[_termsId-1];
            params = _deposits[_nonZeroAddr(user)].data[depositId];
             rollparams = _rolls[_nonZeroAddr(user)].data[depositId];
        }else{
            params = Deposit(
                0,
                0,
                0,
                0
            );
        }
    }

    function changeOverallProbability(uint256 _amount) public onlyOwner{
        OVERALL_PROBABILITY = _amount;
    } 
    function termSheet(
        uint256 termsId
    ) external view returns (TermSheet memory) {
        return _termSheets[_validTermsID(termsId) - 1];
    }

    function termSheetsNum() external view returns (uint256) {
        return _termSheets.length;
    }

    function allTermSheets() external view returns(TermSheet[] memory) {
        return _termSheets;
    }

    function depositLimit(
        uint256 limitId
    ) external view returns (Limit memory) {
        return _limits[_validLimitID(limitId) - 1];
    }

    function depositLimitsNum() external view returns (uint256) {
        return _limits.length;
    }

    function getTokenData(
        uint256 tokenId
    ) external view returns(address, TokenType, uint8 decimals) {
        return _token(uint8(tokenId));
    }

    function isAcceptableNft(
        uint256 termsId,
        address nftContract,
        uint256 nftId
    ) external view returns(bool) {
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        if (tS.nfTokenId != 0 && _tokenAddr(tS.nfTokenId) == nftContract) {
            return _isAllowedNftId(nftId, tS.allowedNftNumBitMask);
        }
        return false;
    }

    function idsToBitmask(
        uint256[] memory ids
    ) pure external returns(uint256 bitmask) {
        bitmask = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            require(id != 0 && id <= 64, "NFTStaking:unsupported NFT ID");
            bitmask = bitmask | (id == 1 ? 1 : 2 << (id - 2));
        }
    }

    function computeEarlyWithdrawal(
        address user,
        uint256 depositId
    ) external view returns (uint256 amountToUser, uint256 fees) {
        Deposit memory _deposit = _deposits[user].data[depositId];
        require(_deposit.amountDue != 0, "NFTStaking:unknown or repaid deposit");
        
        (uint256 termsId, , , ) = _decodeDepositId(depositId);
        TermSheet memory tS = _termSheets[termsId - 1];

        (amountToUser, fees, ) = _computeEarlyWithdrawal(_deposit, tS, now);
    }

    function roll(uint256 depositId) public returns (uint256 rate) {

        UserDeposits storage userDeposits = _deposits[msg.sender];
        Deposit storage _deposit = userDeposits.data[depositId];

        require(_deposit.amountDue != 0, "NFTStaking:unknown or repaid deposit");

        (
            uint16 termsId,
            ,
            ,
            
        ) = _decodeDepositId(depositId);


        require(_hasDeposit[termsId][msg.sender] == true, "NFTStaking: user has an existing deposit in current Termsheet");
        UserRolls storage userRolls = _rolls[msg.sender];
        Roll storage _roll = userRolls.data[depositId];
        
        uint32 lastRoll = _roll.lastRoll;
        uint32 timeDeposit = _roll.timeDeposit;
        uint32 currentTime = safe32(now);
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        uint32 twelvehours = 43200;
        
        if(lastRoll != timeDeposit){
            require(lastRoll < currentTime - twelvehours, "NFTStaking: 12hours has not been completed yet");
        }
        // div by 1e6
        
        rate = _pickRandomNumber().add(1e6);
        uint256 amountDue = uint256(_deposit.amountDue).mul(rate).div(1e6);
        
        totalDue[tS.outTokenId] = totalDue[tS.outTokenId].add(amountDue).sub(_deposit.amountDue);
        _deposit.amountDue = uint176(amountDue);
        _roll.lastRoll = safe32(now);
        _roll.rate = rate;
        // require(_roll.)

        
    }

    function _pickRandomNumber(
    ) internal returns (uint256) {
        uint256 value = uint256(_random().mod(OVERALL_PROBABILITY));
        if(value == 0 ){
            return 1;
        }
        return value;
    } 


    function _random() internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, seed)));
        seed = randomNumber;
        return randomNumber;
    }

    function deposit(
        uint256 termsId,    // term sheet ID
        uint256 amount,     // amount in deposit token units
        uint256 nftId       // ID of the NFT instance (0 if no NFT required)
    ) public nonReentrant {
        TermSheet memory tS = _termSheets[_validTermsID(termsId) - 1];
        require(tS.availableQty != 0, "NFTStaking:terms disabled or unknown");
        require(_hasDeposit[termsId][msg.sender] == false, "NFTStaking: user has an existing deposit in current Termsheet");
        if (tS.availableQty != 255) {
            _termSheets[termsId - 1].availableQty = --tS.availableQty;
            if ( tS.availableQty == 0) emit TermsDisabled(termsId);
        }

        if (tS.limitId != 0) {
            Limit memory l = _limits[tS.limitId - 1];
            require(amount >= l.minAmount, "NFTStaking:too small deposit amount");
            if (l.maxAmountFactor != 0) {
                require(
                    amount <=
                        uint256(l.minAmount).mul(l.maxAmountFactor) / 1e4,
                    "NFTStaking:too big deposit amount"
                );
            }
        }

        uint256 serialNum = depositQty + 1;
        depositQty = uint32(serialNum); // overflow risk ignored

        uint256 depositId = _encodeDepositId(
            serialNum,
            termsId,
            tS.outTokenId,
            tS.nfTokenId,
            nftId
        );

        address tokenIn;
        uint256 amountDue;
        {
            uint8 decimalsIn;
            (tokenIn,, decimalsIn) = _token(tS.inTokenId);
            (,, uint8 decimalsOut) = _token(tS.outTokenId);
            amountDue = _amountOut(amount, tS.rate, decimalsIn, decimalsOut);
        }

        require(amountDue < 2**178, "NFTStaking:O2");
        uint32 maturityTime = safe32(now.add(uint256(tS.depositHours) *3600));

        if (tS.nfTokenId == 0) {
            require(nftId == 0, "NFTStaking:unexpected non-zero nftId");
        } else {
            require(
                nftId < 2**16 &&
                _isAllowedNftId(nftId, tS.allowedNftNumBitMask),
                "NFTStaking:disallowed NFT instance"
            );
            require(nftId == 1, "NFTStaking: wrong nft id");
                IERC1155(_tokenAddr(tS.nfTokenId)).safeTransferFrom(msg.sender, address(this), nftId, 1, "");
        }

        IBEP20(tokenIn).safeTransferFrom(msg.sender, treasury, amount);

        // inverted and re-scaled from 255 to 65535
        uint256 lockedShare = uint(255 - tS.earlyRepayableShare) * 65535/255;
        _registerDeposit(
            _deposits[msg.sender],
            depositId,
            Deposit(
                uint176(amountDue),
                maturityTime,
                safe32(now),
                uint16(lockedShare)
            )
        );
        _registerRoll(_rolls[msg.sender], depositId, Roll(safe32(now),safe32(now),0));
        termIDToDepositId[termsId][msg.sender].push(depositId);
        latestDeposit[termsId][msg.sender] =  latestDeposit[termsId][msg.sender].add(1);
        totalDue[tS.outTokenId] = totalDue[tS.outTokenId].add(amountDue);

        _hasDeposit[termsId][msg.sender] = true;

        emit NewDeposit(
            tS.inTokenId,
            tS.outTokenId,
            msg.sender,
            depositId,
            termsId,
            amount,
            amountDue,
            maturityTime
        );
    }

    // Entirely withdraw the deposit (when the deposit period ends)
    function withdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, false);
    }

    // Early withdrawal of the unlocked "repay" token amount (beware of fees!!)
    function interimWithdraw(uint256 depositId) public nonReentrant {
        _withdraw(depositId, true);
    }

    function addTerms(TermSheet[] memory termSheets) public onlyOwner {
        for (uint256 i = 0; i < termSheets.length; i++) {
            _addTermSheet(termSheets[i]);
        }
    }

    function updateAvailableQty(
        uint256 termsId,
        uint256 newQty
    ) external onlyOwner {
        require(newQty <= 255, "NFTStaking:INVALID_availableQty");
        _termSheets[_validTermsID(termsId) - 1].availableQty = uint8(newQty);
        if (newQty == 0) {
            emit TermsDisabled(termsId);
        } else {
            emit TermsEnabled(termsId);
        }
    }

    function addLimits(Limit[] memory limits) public onlyOwner {
        // Risk of `limitId` (16 bits) overflow ignored
        for (uint256 i = 0; i < limits.length; i++) {
            _addLimit(limits[i]);
        }
    }

    function addTokens(
        address[] memory addresses,
        TokenType[] memory types,
        uint8[] memory decimals
    ) external onlyOwner {
        _addTokens(addresses, types, decimals);
    }

    function setTreasury(address _treasury) public onlyOwner {
        _setTreasury(_treasury);
    }

    // Save occasional airdrop or mistakenly transferred tokens
    function transferFromContract(IBEP20 token, uint256 amount, address to)
        external
        onlyOwner
    {
        _revertZeroAddress(to);
        token.safeTransfer(to, amount);
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata 
    ) external pure virtual returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata 
    ) external pure virtual returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    // Other parameters, except `serialNum`, encoded for gas saving & UI sake
    function _encodeDepositId(
        uint256 serialNum,  // Incremental num, unique for every deposit
        uint256 termsId,    // ID of the applicable term sheet
        uint256 outTokenId, // ID of the ERC-20 token to repay deposit in
        uint256 nfTokenId,  // ID of the deposited ERC-721 token (contract)
        uint256 nftId       // ID of the deposited ERC-721 token instance
    ) internal pure returns (uint256 depositId) {
        depositId = nftId
        | (nfTokenId << 16)
        | (outTokenId << 24)
        | (termsId << 32)
        | (serialNum << 48);
    }

    function _decodeDepositId(uint256 depositId) internal pure
    returns (
        uint16 termsId,
        uint8 outTokenId,
        uint8 nfTokenId,
        uint16 nftId
    ) {
        termsId = uint16(depositId >> 32);
        outTokenId = uint8(depositId >> 24);
        nfTokenId = uint8(depositId >> 16);
        nftId = uint16(depositId);
    }

    function _withdraw(uint256 depositId, bool isInterim) internal {
        UserDeposits storage userDeposits = _deposits[msg.sender];
        Deposit memory _deposit = userDeposits.data[depositId];

        UserRolls storage userRolls = _rolls[msg.sender];

        require(_deposit.amountDue != 0, "NFTStaking:unknown or repaid deposit");

        uint256 amountToUser;
        uint256 amountDue = 0;
        uint256 fees = 0;

        (
            uint16 termsId,
            uint8 outTokenId,
            uint8 nfTokenId,
            uint16 nftId
        ) = _decodeDepositId(depositId);

        if (isInterim) {
            TermSheet memory tS = _termSheets[termsId - 1];
            require(
                now >= uint256(_deposit.lastWithdrawTime) + tS.minInterimHours * 3600,
                "NFTStaking:withdrawal not yet allowed"
            );

            uint256 lockedShare;
            (amountToUser, fees, lockedShare) = _computeEarlyWithdrawal(
                _deposit,
                tS,
                now
            );
            amountDue = uint256(_deposit.amountDue).sub(amountToUser).sub(fees);
            _deposit.lockedShare = uint16(lockedShare);

            emit InterimWithdraw(msg.sender, depositId, amountToUser, fees);
        } else {
            // require(now >= _deposit.maturityTime, "NFTStaking:deposit is locked");
            amountToUser = uint256(_deposit.amountDue);

            if (nftId != 0) {
                IERC1155(_tokenAddr(nfTokenId)).safeTransferFrom(address(this), msg.sender, nftId, 1, "");
            }
            _deregisterDeposit(userDeposits, depositId);
            _deregisterRoll(userRolls, depositId);

            emit Withdraw(msg.sender, depositId, amountToUser);
        }

        _deposit.lastWithdrawTime = safe32(now);
        _deposit.amountDue = uint176(amountDue);
        userDeposits.data[depositId] = _deposit;

        totalDue[outTokenId] = totalDue[outTokenId]
            .sub(amountToUser)
            .sub(fees);

        _hasDeposit[termsId][msg.sender] = false;

        IBEP20(_tokenAddr(outTokenId))
            .safeTransferFrom(treasury, msg.sender, amountToUser);
    }

    function _computeEarlyWithdrawal(
        Deposit memory d,
        TermSheet memory tS,
        uint256 timeNow
    ) internal pure returns (
        uint256 amountToUser,
        uint256 fees,
        uint256 newlockedShare
    ) {
        require(d.lockedShare != 65535, "NFTStaking:early withdrawals banned");

        amountToUser = 0;
        fees = 0;
        newlockedShare = 0;

        if (timeNow > d.lastWithdrawTime && timeNow < d.maturityTime) {
            // values are too small for overflow; if not, safemath used
            {
                uint256 timeSincePrev = timeNow - d.lastWithdrawTime;
                uint256 timeLeftPrev = d.maturityTime - d.lastWithdrawTime;
                uint256 repayable = uint256(d.amountDue)
                    .mul(65535 - d.lockedShare)
                    / 65535;

                amountToUser = repayable.mul(timeSincePrev).div(timeLeftPrev);
                newlockedShare = uint256(65535).sub(
                    repayable.sub(amountToUser)
                    .mul(65535)
                    .div(uint256(d.amountDue).sub(amountToUser))
                );
            }
            {
                uint256 term = uint256(tS.depositHours) * 3600; // can't be 0
                uint256 timeLeft = d.maturityTime - timeNow;
                fees = amountToUser
                    .mul(uint256(tS.earlyWithdrawFees))
                    .mul(timeLeft)
                    / term // fee rate linearly drops to 0
                    / 255; // `earlyWithdrawFees` scaled down

            }
            amountToUser = amountToUser.sub(fees); // fees withheld
        }
    }

    function _amountOut(
        uint256 amount,
        uint64 rate,
        uint8 decIn,
        uint8 decOut
    ) internal pure returns(uint256 out) {
        if (decOut > decIn + 9) { // rate is scaled (multiplied) by 1e9
            out = amount.mul(rate).mul(10 ** uint256(decOut - decIn - 9));
        } else {
            out = amount.mul(rate).div(10 ** uint256(decIn + 9 - decOut));
        }
        return out;
    }

    function _addTermSheet(TermSheet memory tS) internal {
        (, TokenType _type,) = _token(tS.inTokenId);
        require(_type == TokenType.Erc20, "NFTStaking:INVALID_DEPOSIT_TOKEN");
        (, _type,) = _token(tS.outTokenId);
        require(_type == TokenType.Erc20, "NFTStaking:INVALID_REPAY_TOKEN");
        if (tS.nfTokenId != 0) {
            (, _type,) = _token(tS.nfTokenId);
            require(_type == TokenType.Erc1155, "NFTStaking:INVALID_NFT_TOKEN");
        }
        if (tS.earlyRepayableShare == 0) {
            require(
                tS.earlyWithdrawFees == 0 && tS.minInterimHours == 0,
                "NFTStaking:INCONSISTENT_PARAMS"
            );
        }

        if (tS.limitId != 0) _validLimitID(tS.limitId);
        require(
             tS.depositHours != 0 && tS.rate != 0,
            "NFTStaking:INVALID_ZERO_PARAM"
        );

        // Risk of termsId (16 bits) overflow ignored
        _termSheets.push(tS);

        emit NewTermSheet(_termSheets.length);
        if (tS.availableQty != 0 ) emit TermsEnabled(_termSheets.length);
    }

    function _addLimit(Limit memory l) internal {
        require(l.minAmount != 0, "NFTStaking:INVALID_minAmount");
        _limits.push(l);
    }

    function _isAllowedNftId(
        uint256 nftId,
        uint256 allowedBitMask
    ) internal pure returns(bool) {
        if (allowedBitMask == 0) return true;
        uint256 idBitMask = nftId == 1 ? 1 : (2 << (nftId - 2));
        return (allowedBitMask & idBitMask) != 0;
    }

    function _registerDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId,
        Deposit memory _deposit
    ) internal {
        userDeposits.data[depositId] = _deposit;
        userDeposits.ids.push(depositId);
    }

    function _registerRoll(
        UserRolls storage userRolls,
        uint256 depositId,
        Roll memory _roll
    ) internal {
        userRolls.data[depositId] = _roll;
        userRolls.ids.push(depositId);
    }

    function _deregisterRoll(
        UserRolls storage userRolls,
        uint256 depositId
    ) internal {
        _removeArrayElement(userRolls.ids, depositId);
    }

    function _deregisterDeposit(
        UserDeposits storage userDeposits,
        uint256 depositId
    ) internal {
        _removeArrayElement(userDeposits.ids, depositId);
    }

    // Assuming the given array does contain the given element
    function _removeArrayElement(uint256[] storage arr, uint256 el) internal {
        uint256 lastIndex = arr.length - 1;
        if (lastIndex != 0) {
            uint256 replaced = arr[lastIndex];
            if (replaced != el) {
                // Shift elements until the one being removed is replaced
                do {
                    uint256 replacing = replaced;
                    replaced = arr[lastIndex - 1];
                    lastIndex--;
                    arr[lastIndex] = replacing;
                } while (replaced != el && lastIndex != 0);
            }
        }
        // Remove the last (and quite probably the only) element
        arr.pop();
    }

    function _setTreasury(address _treasury) internal {
        _revertZeroAddress(_treasury);
        treasury = _treasury;
    }

    function _revertZeroAddress(address _address) private pure {
        require(_address != address(0), "NFTStaking:ZERO_ADDRESS");
    }

    function _nonZeroAddr(address _address) private pure returns (address) {
        _revertZeroAddress(_address);
        return _address;
    }

    function _validTermsID(uint256 termsId) private view returns (uint256) {
        require(
            termsId != 0 && termsId <= _termSheets.length,
            "NFTStaking:INVALID_TERMS_ID"
        );
        return termsId;
    }

    function _validLimitID(uint256 limitId) private view returns (uint256) {
        require(
            limitId != 0 && limitId <= _limits.length,
            "NFTStaking:INVALID_LIMITS_ID"
        );
        return limitId;
    }

    function safe32(uint256 n) private pure returns (uint32) {
        require(n < 2**32, "NFTStaking:UNSAFE_UINT32");
        return uint32(n);
    }
}