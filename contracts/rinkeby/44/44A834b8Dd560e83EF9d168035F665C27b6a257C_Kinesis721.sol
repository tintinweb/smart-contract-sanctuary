/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File contracts/libs/IERC165.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 */
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


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
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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

pragma solidity ^0.8.0;
/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}



pragma solidity ^0.8.0;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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

// SPDX-License-Identifier: MIT
// File: contracts/Kinesis721.sol
pragma solidity ^0.8.0;

contract Kinesis721 is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId,
        uint256 _invocations,
        uint256 _value
    );

    event Burn(
        address indexed _burnerAddress,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    struct WhitelistedBuyer {
        address addr;
        uint256 claimAmount;
        uint256 hasMinted;
    }

    struct Project {
        string name;
        string artist;
        string description;
        string website;
        string license;
        bool dynamic;
        address payable artistAddress;
        address payable additionalPayee;
        uint256 additionalPayeePercentage;
        uint256 secondMarketRoyalty;
        uint256 pricePerTokenInWei;
        string projectBaseURI;
        string projectBaseIpfsURI;
        uint256 invocations;
        uint256 maxInvocations;
        string scriptJSON;
        mapping(uint256 => string) scripts;
        uint scriptCount;
        string ipfsHash;
        uint256 hashes;
        bool useIpfs;
        bool active;
        bool locked;
        bool paused;
        bool privateSaleIsActive;
        bool claimable;
        uint256 maxPurchaseable;
        mapping(address => WhitelistedBuyer) whitelist;
        mapping(uint256 => bool) isTokenClaimable;
    }

    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Project) projects;

    address payable public kinesisAddress;
    uint256 public kinesisPercentage = 10;

    mapping(uint256 => string) public staticIpfsImageLink;
    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => uint256[]) internal projectIdToTokenIds;
    mapping(uint256 => bytes32[]) internal tokenIdToHashes;
    mapping(bytes32 => uint256) public hashToTokenId;
    mapping(uint256 => uint256) internal tokenIdToProjectArrayIndex;

    address public admin;
    mapping(address => bool) public isAuthorized;

    uint256 public nextProjectId;

    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }

    modifier onlyUnlocked(uint256 _projectId) {
        require(!projects[_projectId].locked, "Only if unlocked");
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(msg.sender == projects[_projectId].artistAddress, "Only artist");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyAuthorized() {
        require(isAuthorized[msg.sender], "Only authorized");
        _;
    }

    modifier onlyArtistOrAuthorized(uint256 _projectId) {
        require(isAuthorized[msg.sender] || msg.sender == projects[_projectId].artistAddress, "Only artist or authorized");
        _;
    }

    constructor() ERC721("KinesisArt", "KINESIS") {
        admin = msg.sender;
        isAuthorized[msg.sender] = true;
        kinesisAddress = payable(msg.sender);
    }

    function addAllProjectTokensToClaimable(uint256 _projectId, uint256 _oldProjectId) public onlyAuthorized {
        require(projects[_projectId].claimable, "Project is not claimable");
        addTokenListToClaimable(_projectId, projectIdToTokenIds[_oldProjectId]);
    }

    function addTokenListToClaimable(uint256 _projectId, uint256[] memory _tokenIdArr) public onlyAuthorized{
        require(projects[_projectId].claimable, "Project is not claimable");
        for (uint256 i = 0; i < _tokenIdArr.length; i++) {
            addTokenToClaimable(_projectId, _tokenIdArr[i]);
        }
    }

    function addTokenToClaimable(uint256 _projectId, uint256 _tokenId) public onlyAuthorized {
        require(projects[_projectId].claimable, "Project is not claimable");
        projects[_projectId].isTokenClaimable[_tokenId] = true;
    }

    function claimForToken(uint256 _projectId, uint256 _tokenId) public payable {
        require(projects[_projectId].claimable, "Not a claimable project");
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved");
        require(projects[_projectId].isTokenClaimable[_tokenId], "Token is not claimable, or has already been claimed");
        require(projects[_projectId].active || msg.sender == projects[_projectId].artistAddress, "Project must exist and be active");

        projects[_projectId].isTokenClaimable[_tokenId] = false;
        _mintToken(msg.sender, _projectId);
    }

    function mint(uint256 _projectId, uint256 amountToMint) public payable {
        require(totalSupply() < projects[_projectId].maxInvocations, "All NFTs have been minted.");
        require(amountToMint > 0, "You must mint at least one piece.");
        require(amountToMint <= projects[_projectId].maxPurchaseable, "You are minting too many pieces at once!");
        require(totalSupply() + amountToMint <= projects[_projectId].maxInvocations, "The amount of pieces you are trying to mint exceeds the max supply.");
        require(projects[_projectId].active || msg.sender == projects[_projectId].artistAddress, "Project must exist and be active");
        require(!projects[_projectId].paused || msg.sender == projects[_projectId].artistAddress, "Purchases are paused.");        
        require(!projects[_projectId].claimable, "This project can only be claimed, not minted");
        require(projects[_projectId].pricePerTokenInWei * amountToMint <= msg.value, "Incorrect Ether value.");
        if (projects[_projectId].privateSaleIsActive) {
            require(isWhitelisted(_projectId, msg.sender), "Buyer not whitelisted for this private sale");
            require(projects[_projectId].whitelist[msg.sender].hasMinted < projects[_projectId].whitelist[msg.sender].claimAmount, "You have already reached your allotted mint count");
            require(projects[_projectId].whitelist[msg.sender].hasMinted.add(amountToMint) <= projects[_projectId].whitelist[msg.sender].claimAmount, "This transaction would exceed your allotted mints!");
            projects[_projectId].whitelist[msg.sender].hasMinted = projects[_projectId].whitelist[msg.sender].hasMinted.add(amountToMint);
        }

        for (uint256 i = 0; i < amountToMint; i++) {
            _mintToken(msg.sender, _projectId);
        }
        _splitFunds(_projectId);
   }

    function _mintToken(address _to, uint256 _projectId) internal returns (uint256 _tokenId) {

        uint256 tokenIdToBe = (_projectId * ONE_MILLION) + projects[_projectId].invocations;
        tokenIdToProjectArrayIndex[tokenIdToBe] = projects[_projectId].invocations;

        projects[_projectId].invocations = projects[_projectId].invocations.add(1);

        for (uint256 i = 0; i < projects[_projectId].hashes; i++) {
            bytes32 hash = keccak256(abi.encodePacked(projects[_projectId].invocations, block.number.add(i), msg.sender));
            tokenIdToHashes[tokenIdToBe].push(hash);
            hashToTokenId[hash] = tokenIdToBe;
        }

        _safeMint(_to, tokenIdToBe);

        tokenIdToProjectId[tokenIdToBe] = _projectId;
        projectIdToTokenIds[_projectId].push(tokenIdToBe);

        emit Mint(_to, tokenIdToBe, _projectId, projects[_projectId].invocations, projects[_projectId].pricePerTokenInWei);

        return tokenIdToBe;
    }

    function _splitFunds(uint256 _projectId) internal {
        if (msg.value > 0) {

            uint256 pricePerTokenInWei = projects[_projectId].pricePerTokenInWei;
            uint256 refund = msg.value.sub(projects[_projectId].pricePerTokenInWei);

            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }

            uint256 foundationAmount = pricePerTokenInWei.div(100).mul(kinesisPercentage);
            if (foundationAmount > 0) {
                kinesisAddress.transfer(foundationAmount);
            }

            uint256 projectFunds = pricePerTokenInWei.sub(foundationAmount);

            uint256 additionalPayeeAmount;
            if (projects[_projectId].additionalPayeePercentage > 0) {
                additionalPayeeAmount = projectFunds.div(100).mul(projects[_projectId].additionalPayeePercentage);
                if (additionalPayeeAmount > 0) {
                    projects[_projectId].additionalPayee.transfer(additionalPayeeAmount);
                }
            }

            uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
            if (creatorFunds > 0) {
                projects[_projectId].artistAddress.transfer(creatorFunds);
            }
        }
    }

    function updateKinesisAddress(address payable _kinesisAddress) public onlyAdmin {
        kinesisAddress = _kinesisAddress;
    }

    function updateKinesisPercentage(uint256 _kinesisPercentage) public onlyAdmin {
        require(_kinesisPercentage <= 50, "Max of 50%");
        kinesisPercentage = _kinesisPercentage;
    }

    function addAuthorized(address _address) public onlyAdmin {
        isAuthorized[_address] = true;
    }

    function removeAuthorized(address _address) public onlyAdmin {
        isAuthorized[_address] = false;
    }

    function bulkAddToWhitelist(uint256 _projectId, WhitelistedBuyer[] calldata _whitelistArray) onlyAuthorized external {
        for(uint i=0; i<_whitelistArray.length; i++){
            addAddressToWhitelist(_projectId, _whitelistArray[i].addr, _whitelistArray[i].claimAmount);
        }
    }

    function addAddressToWhitelist(uint256 _projectId, address _addr, uint _claimAmount) onlyAuthorized public returns(bool success) {
        require(!isWhitelisted(_projectId, _addr), "Already authorized");
        projects[_projectId].whitelist[_addr].addr = _addr;
        projects[_projectId].whitelist[_addr].claimAmount = _claimAmount;
        projects[_projectId].whitelist[_addr].hasMinted = 0;
        success = true;
    }

    function isWhitelisted(uint256 _projectId, address addr) public view returns (bool isWhiteListed) {
        return projects[_projectId].whitelist[addr].addr == addr;
    }

    function whitelistMintCountFor(uint256 _projectId, address _addr) public view returns (uint256) {
        return projects[_projectId].whitelist[_addr].hasMinted;
    }
    
    function toggleProjectIsLocked(uint256 _projectId) public onlyAuthorized onlyUnlocked(_projectId) {
        projects[_projectId].locked = true;
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyAuthorized {
        projects[_projectId].active = !projects[_projectId].active;
    }

    function updateProjectArtistAddress(uint256 _projectId, address payable _artistAddress) public onlyArtistOrAuthorized(_projectId) {
        projects[_projectId].artistAddress = _artistAddress;
    }

    function toggleProjectIsPaused(uint256 _projectId) public onlyArtistOrAuthorized(_projectId) {
        projects[_projectId].paused = !projects[_projectId].paused;
    }

    function toggleProjectIsPrivateSale(uint256 _projectId) public onlyArtistOrAuthorized(_projectId) {
        projects[_projectId].privateSaleIsActive = !projects[_projectId].privateSaleIsActive;
    }

    function toggleProjectIsClaimable(uint256 _projectId) public onlyArtistOrAuthorized(_projectId) {
        projects[_projectId].claimable = !projects[_projectId].claimable;
    }

    function addProject(uint256 _pricePerTokenInWei, bool _dynamic) public onlyAuthorized {

        uint256 projectId = nextProjectId;
        projects[projectId].artistAddress = payable(msg.sender);
        projects[projectId].pricePerTokenInWei = _pricePerTokenInWei;
        projects[projectId].paused=true;
        projects[projectId].dynamic=_dynamic;
        projects[projectId].maxInvocations = ONE_MILLION;
        projects[projectId].maxPurchaseable = 10;
        addAddressToWhitelist(projectId, msg.sender, ONE_MILLION);
        if (!_dynamic) {
            projects[projectId].hashes = 0;
        } else {
            projects[projectId].hashes = 1;
        }
        nextProjectId = nextProjectId.add(1);
    }

    function updateProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) onlyArtist(_projectId) public {
        projects[_projectId].pricePerTokenInWei = _pricePerTokenInWei;
    }

    function updateProjectName(uint256 _projectId, string memory _projectName) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        projects[_projectId].name = _projectName;
    }

    function updateProjectArtistName(uint256 _projectId, string memory _projectArtistName) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        projects[_projectId].artist = _projectArtistName;
    }

    function updateProjectMaxPurchaseable(uint256 _projectId, uint256 _maxPurchaseable) public onlyArtistOrAuthorized(_projectId) {
        projects[_projectId].maxPurchaseable = _maxPurchaseable;
    }

    function updateProjectAdditionalPayeeInfo(uint256 _projectId, address payable _additionalPayee, uint256 _additionalPayeePercentage) onlyArtist(_projectId) public {
        require(_additionalPayeePercentage <= 100, "Max of 100%");
        projects[_projectId].additionalPayee = _additionalPayee;
        projects[_projectId].additionalPayeePercentage = _additionalPayeePercentage;
    }

    function updateProjectSecondaryMarketRoyaltyPercentage(uint256 _projectId, uint256 _secondMarketRoyalty) onlyArtist(_projectId) public {
        require(_secondMarketRoyalty <= 100, "Max of 100%");
        projects[_projectId].secondMarketRoyalty = _secondMarketRoyalty;
    }

    function updateProjectDescription(uint256 _projectId, string memory _projectDescription) onlyArtist(_projectId) public {
        projects[_projectId].description = _projectDescription;
    }

    function updateProjectWebsite(uint256 _projectId, string memory _projectWebsite) onlyArtist(_projectId) public {
        projects[_projectId].website = _projectWebsite;
    }

    function updateProjectLicense(uint256 _projectId, string memory _projectLicense) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        projects[_projectId].license = _projectLicense;
    }

    function updateProjectMaxInvocations(uint256 _projectId, uint256 _maxInvocations) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        require(_maxInvocations > projects[_projectId].invocations, "You must set max invocations greater than current invocations");
        require(_maxInvocations <= ONE_MILLION, "Cannot exceed 1,000,000");
        projects[_projectId].maxInvocations = _maxInvocations;
    }

    function updateProjectHashesGenerated(uint256 _projectId, uint256 _hashes) onlyUnlocked(_projectId) onlyAuthorized() public {
        require(projects[_projectId].invocations == 0, "Can not modify hashes generated after a token is minted.");
        require(projects[_projectId].dynamic, "Can only modify hashes on dynamic projects.");
        require(_hashes <= 100 && _hashes >= 0, "Hashes generated must be a positive integer and max hashes per invocation are 100");
        projects[_projectId].hashes = _hashes;
    }

    function addProjectScript(uint256 _projectId, string memory _script) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        projects[_projectId].scripts[projects[_projectId].scriptCount] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount.add(1);
    }

    function updateProjectScript(uint256 _projectId, uint256 _scriptId, string memory _script) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        require(_scriptId < projects[_projectId].scriptCount, "scriptId out of range");
        projects[_projectId].scripts[_scriptId] = _script;
    }

    function removeProjectLastScript(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        require(projects[_projectId].scriptCount > 0, "there are no scripts to remove");
        delete projects[_projectId].scripts[projects[_projectId].scriptCount - 1];
        projects[_projectId].scriptCount = projects[_projectId].scriptCount.sub(1);
    }

    function updateProjectScriptJSON(uint256 _projectId, string memory _projectScriptJSON) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        projects[_projectId].scriptJSON = _projectScriptJSON;
    }

    function updateProjectIpfsHash(uint256 _projectId, string memory _ipfsHash) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
        projects[_projectId].ipfsHash = _ipfsHash;
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _newBaseURI) onlyArtist(_projectId) public {
        projects[_projectId].projectBaseURI = _newBaseURI;
    }

    function updateProjectBaseIpfsURI(uint256 _projectId, string memory _projectBaseIpfsURI) onlyArtist(_projectId) public {
        projects[_projectId].projectBaseIpfsURI = _projectBaseIpfsURI;
    }

    function toggleProjectUseIpfsForStatic(uint256 _projectId) onlyArtist(_projectId) public {
        require(!projects[_projectId].dynamic, "can only set static IPFS hash for static projects");
        projects[_projectId].useIpfs = !projects[_projectId].useIpfs;
    }

    function toggleProjectIsDynamic(uint256 _projectId) onlyUnlocked(_projectId) onlyArtistOrAuthorized(_projectId) public {
      require(projects[_projectId].invocations == 0, "Can not switch after a token is minted.");
        if (projects[_projectId].dynamic) {
            projects[_projectId].hashes = 0;
        } else {
            projects[_projectId].hashes = 1;
        }
        projects[_projectId].dynamic = !projects[_projectId].dynamic;
    }

    function overrideTokenDynamicImageWithIpfsLink(uint256 _tokenId, string memory _ipfsHash) onlyArtist(tokenIdToProjectId[_tokenId]) public {
        staticIpfsImageLink[_tokenId] = _ipfsHash;
    }

    function clearTokenIpfsImageUri(uint256 _tokenId) onlyArtist(tokenIdToProjectId[_tokenId]) public {
        delete staticIpfsImageLink[tokenIdToProjectId[_tokenId]];
    }

    function projectDetails(uint256 _projectId) view public returns (string memory projectName, string memory artist, string memory description, string memory website, string memory license, bool dynamic) {
        projectName = projects[_projectId].name;
        artist = projects[_projectId].artist;
        description = projects[_projectId].description;
        website = projects[_projectId].website;
        license = projects[_projectId].license;
        dynamic = projects[_projectId].dynamic;
    }

    function projectTokenInfo(uint256 _projectId) view public returns (address artistAddress, uint256 pricePerTokenInWei, uint256 invocations, uint256 maxInvocations, bool active, address additionalPayee, uint256 additionalPayeePercentage, bool privateSaleActive, uint256 maxPurchaseable, bool claimable) {
        artistAddress = projects[_projectId].artistAddress;
        pricePerTokenInWei = projects[_projectId].pricePerTokenInWei;
        invocations = projects[_projectId].invocations;
        maxInvocations = projects[_projectId].maxInvocations;
        active = projects[_projectId].active;
        additionalPayee = projects[_projectId].additionalPayee;
        additionalPayeePercentage = projects[_projectId].additionalPayeePercentage;
        maxPurchaseable = projects[_projectId].maxPurchaseable;
        privateSaleActive = projects[_projectId].privateSaleIsActive;
        claimable = projects[_projectId].claimable;
    }

    function projectScriptInfo(uint256 _projectId) view public returns (string memory scriptJSON, uint256 scriptCount, uint256 hashes, string memory ipfsHash, bool locked, bool paused) {
        scriptJSON = projects[_projectId].scriptJSON;
        scriptCount = projects[_projectId].scriptCount;
        hashes = projects[_projectId].hashes;
        ipfsHash = projects[_projectId].ipfsHash;
        locked = projects[_projectId].locked;
        paused = projects[_projectId].paused;
    }

    function projectScriptByIndex(uint256 _projectId, uint256 _index) view public returns (string memory){
        return projects[_projectId].scripts[_index];
    }

    function projectURIInfo(uint256 _projectId) view public returns (string memory projectBaseURI, string memory projectBaseIpfsURI, bool useIpfs) {
        projectBaseURI = projects[_projectId].projectBaseURI;
        projectBaseIpfsURI = projects[_projectId].projectBaseIpfsURI;
        useIpfs = projects[_projectId].useIpfs;
    }

    function projectShowAllTokens(uint _projectId) public view returns (uint256[] memory){
        return projectIdToTokenIds[_projectId];
    }

    function showTokenHashes(uint _tokenId) public view returns (bytes32[] memory){
        return tokenIdToHashes[_tokenId];
    }

    function getRoyaltyData(uint256 _tokenId) public view returns (address artistAddress, address additionalPayee, uint256 additionalPayeePercentage, uint256 royaltyFeeByID) {
        artistAddress = projects[tokenIdToProjectId[_tokenId]].artistAddress;
        additionalPayee = projects[tokenIdToProjectId[_tokenId]].additionalPayee;
        additionalPayeePercentage = projects[tokenIdToProjectId[_tokenId]].additionalPayeePercentage;
        royaltyFeeByID = projects[tokenIdToProjectId[_tokenId]].secondMarketRoyalty;
    }

    function burn(uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721Burnable: caller is not owner nor approved");
        // move last element to deleted slot, then decrease array size
        uint256 proj_id = tokenIdToProjectId[_tokenId];
        uint oldIndex = tokenIdToProjectArrayIndex[_tokenId];
        projectIdToTokenIds[proj_id][oldIndex] = projectIdToTokenIds[proj_id][projectIdToTokenIds[proj_id].length - 1];
        tokenIdToProjectArrayIndex[projectIdToTokenIds[proj_id][oldIndex]] = oldIndex;
        projectIdToTokenIds[proj_id].pop();
        for (uint256 i = 0; i < tokenIdToHashes[_tokenId].length; i++) {
            delete hashToTokenId[tokenIdToHashes[_tokenId][i]];
        }
        delete tokenIdToHashes[_tokenId];
        delete tokenIdToProjectId[_tokenId];  
        _burn(_tokenId);

        emit Burn(msg.sender, _tokenId, proj_id);
    }

    function tokenURI(uint256 _tokenId) public view virtual override onlyValidTokenId(_tokenId) returns (string memory) {
        if (bytes(staticIpfsImageLink[_tokenId]).length > 0) {
            return string(abi.encodePacked(projects[tokenIdToProjectId[_tokenId]].projectBaseIpfsURI, staticIpfsImageLink[_tokenId]));
        }

        if (!projects[tokenIdToProjectId[_tokenId]].dynamic && projects[tokenIdToProjectId[_tokenId]].useIpfs) {
            return string(abi.encodePacked(projects[tokenIdToProjectId[_tokenId]].projectBaseIpfsURI, projects[tokenIdToProjectId[_tokenId]].ipfsHash));
        }

        return string(abi.encodePacked(projects[tokenIdToProjectId[_tokenId]].projectBaseURI, Strings.toString(_tokenId)));
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        admin = newOwner;
        isAuthorized[newOwner] = true;
        kinesisAddress = payable(newOwner);
        super.transferOwnership(newOwner);
    }
}