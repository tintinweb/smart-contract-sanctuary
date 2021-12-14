/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
    function getApproved(uint tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
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

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     */
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint) private _balances;

    // Mapping from token ID to approved address
    mapping(uint => address) private _tokenApprovals;

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
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
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
    function tokenURI(uint tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint tokenId)
    public
    view
    virtual
    override
    returns (address)
    {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint tokenId)
    internal
    view
    virtual
    returns (bool)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        ERC721.isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint);
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function tokenByIndex(uint index) external view returns (uint);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint => uint)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint => uint) private _ownedTokensIndex;

    // The current index of the token
    uint currentIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ERC721)
    returns (bool)
    {
        return
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][uint(index)];
    }

    function totalSupply() public view virtual override returns (uint) {
        return currentIndex;
    }

    function tokenByIndex(uint index)
    public
    view
    virtual
    override
    returns (uint)
    {
        require(
            index < currentIndex,
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual override {
        require (to != address(0), "Token not burnable");

        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            currentIndex++;
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }

        if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint tokenId) private {
        uint length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _removeTokenFromOwnerEnumeration(address from, uint tokenId)
    private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint lastTokenIndex = uint(ERC721.balanceOf(from) - 1);
        uint tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}

library Convertible {
    function convertAddressToString(address sender) internal pure returns (string memory) {
        return toString(abi.encodePacked(sender));
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    
    function sliceString(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);    
    }
    
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
    
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
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
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @dev Converts a numeric string to it's unsigned integer representation.
    /// @param v The string to be converted.
    function bytesToUInt(bytes32 v) pure internal returns (uint256 ret) {
        if (v == 0x0) {
            revert();
        }

        uint digit;

        for (uint i = 0; i < 32; i++) {
            digit = uint((uint(v) / (2 ** (8 * (31 - i)))) & 0xff);
            if (digit == 0) {
                break;
            }
            else if (digit < 48 || digit > 57) {
               revert();
            }
            ret *= 10;
            ret += (digit - 48);
        }
        return ret;
    }
}

/**
 * @title SafeERC20
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
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
        IBEP20 token,
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
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
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

/**
 * Coin98 Staking Contract
 * The main Token used for staking is Coin98 (C98)
 * Each staking in the Contract will have an NFT ID with a prefix + 12 random numbers
 * The Default locked time after staking is based on locked_time (E.g 15 days)
 * The Default floating_rate is the profit when a user does not meet the condition in any package and wants to withdraw soon
 * Example 9898 1234 5678 9101
 * Naming will be free at the first time when first inititiating a staking. After that, will charge a naming_fee will be charged each time the staking name is changed
 */
contract Coin98Stake is ERC721Enumerable, Ownable {
    using SafeERC20 for IBEP20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    uint256 private Percent = 10000;
    uint256 yearTimestamp = 31104000;
    
    string public baseTokenURI;
    Counters.Counter private _tokenIdTracker;

    // Meta information
    struct MetaInfo {
        uint256 total_staked; // Total Meta staked amount
        uint256 max_staked; // Max Meta staked amount
        uint256 naming_fee; // The Fee charged when changing the Staking name
        uint256 id_fee; // The Fee charged when user wants to customize NFT ID
        uint256 locked_time; // The Lock time after tokens are deposited
        uint256 pending_time; // The Pending time after over staked time
        uint256 floating_rate; // Floating rate
        string name_prefix; // Prefix first for Name
        string nft_prefix; // Prefix first for NFT ID
    }
    
    // Package information
    struct PackageInfo {
        address meta; // Meta token address
        uint256 min; // Min package amount
        uint256 max; // Max package amount
        uint256 time; // Package time
        uint256 rate; // Package rate
    }
    
    // Stake information
    struct StakeInfo {
        bool pending_flag; // Flag for checking pending_time
        bool flag; // Flag for check staked status
        string name; // Staking name
        uint256 amount; // Staking amount
        uint256 time; // Staking time
        string packageID; // Package ID
        
        bool isCustomID; // Flag for checking the custom ID
        address meta; // Meta token address
        uint256 package_time; // Package time
        uint256 pending_time; // Pending time
        uint256 rate; // Package rate

        // Saved Informations after unstaked        
        uint256 unstaked_time; // Unstaked Time
        uint256 claim_pending_time; // Claim Pending Time
        uint256 earn_staked; // Earn Staked

        // Read Informations
        uint256 id; // NFT ID
        uint256 est_staked; // Estimated Staked
    }

   // Map the meta address for each Meta information
    mapping(address => MetaInfo) public MetaInfos;
    // Map the package id for each information
    mapping(string => PackageInfo) public PackageInfos;
    // Map the stakeId for each information
    mapping(uint256 => StakeInfo) private StakeInfos;
    
    // emit event when a user starts staking
    event _stake(uint256 id,bool isCustomID);
    // emit event when a user renames an NFT
    event _renaming(uint256 id,string name);
    // emit event when a user unstakes
    event _unstake(uint256 id,uint256 amount, uint256 time);
    // emit event when a user claim pending
    event _claim(uint256 id,uint256 amount, uint256 time);

    constructor(string memory baseURI) ERC721("Coin98 Staking Certificate", "C98SC"){
        setBaseURI(baseURI);
    }

    /**
     * @dev Register a new meta for the package register in
     *
     * Requirements:
     *
     * - `token` the meta staked token.
     * - `max` the maximum staked amount in meta.
     * - `naming_fee` the fee charged when changing an NFT's name.
     * - `id_fee` the fee charged when customizing an NFT's ID.
     * - `lockedTime` the lock time after depositing tokens
     * - `pending_time` the pending time after over staked time
     * - `floatingRate` the default rate when a user does not meet the package rate condition.
     * - `name_prefix` the prefix first for name NFT
     * - `nft_prefix` the prefix first for NFT ID
     */
    function registerMeta(
        address _token,
        uint256 _max_staked,
        uint256 _naming_fee,
        uint256 _id_fee,
        uint256 _locked_time,
        uint256 _pending_time,
        uint256 _floating_rate,
        string memory _name_prefix,
        string memory _nft_prefix
    )
        public
        onlyOwner()
    {
        uint256 nameSize = bytes(_name_prefix).length;
        require(nameSize <= 5, "C98Stake: Name prefix size error");
        uint256 nftPrefixSize = bytes(_nft_prefix).length;
        require(nftPrefixSize == 4, "C98Stake: NFT prefix size error");

        MetaInfo storage metaInfo = MetaInfos[_token];

        metaInfo.floating_rate = _floating_rate;
        metaInfo.max_staked = _max_staked;
        metaInfo.naming_fee = _naming_fee;
        metaInfo.id_fee = _id_fee;
        metaInfo.pending_time = _pending_time;
        metaInfo.locked_time = _locked_time;
        metaInfo.name_prefix = _name_prefix;
        metaInfo.nft_prefix = _nft_prefix;
    }

    function validMeta(address _token) internal view returns (bool isValid){
        return MetaInfos[_token].max_staked > 0;
    }
    
    /**
     * @dev Check validate package condition
     *
     * Requirements:
     *
     * - `package` must be existed.
     * - `min` must be larger than zero and less than max.
     * - `max` must be larger than zero and larger than min.
     */
    function validPackage(string memory _package) internal view returns (bool isValid){
        PackageInfo memory pkInfo = PackageInfos[_package];
        
        return pkInfo.min > 0 && pkInfo.max > 0 && pkInfo.min < pkInfo.max;
    }
    
    function validPackageCondition(uint256 _min, uint256 _max, uint256 _time, uint256 _rate, address _meta) internal view{
        require(_min>0 && _max >0 && _min < _max , "C98Stake: Wrong numeric format");
        MetaInfo memory metaInfo = MetaInfos[_meta];

        require(_time > metaInfo.locked_time && _rate > metaInfo.floating_rate,"C98Stake: Lower than minimum time & rate");
    }

    /**
     * @dev Register a new package for the user to stake in
     *
     * Requirements:
     *
     * - `package` must not be existed.
     * - `meta` the meta staked token.
     * - `min` must be larger than zero and less than max.
     * - `max` must be larger than zero and larger than min.
     * - `time` in staking the user needs to meet before can get `rate` staked.
     * - `rate` profit if the user can meet the package time condition.
     */
    function register(
        string memory _package,
        address _meta,
        uint256 _min,
        uint256 _max,
        uint256 _time,
        uint256 _rate
    )
        public
        onlyOwner()
    {
        require(!validPackage(_package), "C98Stake: Package already existed");
        require(validMeta(_meta),"C98Stake: Unregistered Meta");
        validPackageCondition(_min,_max,_time,_rate,_meta);

        PackageInfo storage pkInfo = PackageInfos[_package];

        pkInfo.meta = _meta;
        pkInfo.min = _min;
        pkInfo.max = _max;
        pkInfo.time = _time;
        pkInfo.rate = _rate;
    }
    
    /**
     * @dev UnRegister existed package
     *
     * Requirements:
     *
     * - `package` must be existed.
    */
    function unRegister(
        string memory _package
    )
        public
        onlyOwner()
    {
        require(validPackage(_package), "C98Stake: Package not found");
        delete PackageInfos[_package];
    }

    /**
     * @dev Configure variable for existed package
     *
     * Requirements:
     *
     * - `package` must be existed.
     * - `min` must be larger than zero and less than max.
     * - `max` must be larger than zero and larger than min.
     * - `time` in staking a user needs to meet before can get `rate` staked.
     * - `rate` profit if the user can meet the package time condition.
     */
    function configurePackage(
        string memory _package,
        uint256 _min,
        uint256 _max,
        uint256 _time,
        uint256 _rate
    )
        public
        onlyOwner()
    {
        require(validPackage(_package), "C98Stake: Package not found");
        PackageInfo storage pkInfo = PackageInfos[_package];

        validPackageCondition(_min,_max,_time,_rate,pkInfo.meta);

        pkInfo.min = _min;
        pkInfo.max = _max;
        pkInfo.time = _time;
        pkInfo.rate = _rate;
    }
    
    /**
     * @dev Return `profit` staked by NFT ID
     *
     * Requirements:
     *
     * - `tokenId` must be existed.
     * -  if the `timeStaked` does not meet the`locked_time` condition or the user has already unstaked, the result will return to zero.
     * -  if the `timeStaked` does not meet the package time condition, the rate will be based on the `floating_rate`
     */
    function getStakedByTokenId(uint256 _tokenId) private view returns (uint256) {
        StakeInfo memory stakeInfo = StakeInfos[_tokenId];
        MetaInfo memory metaInfo = MetaInfos[stakeInfo.meta];

        uint256 current = block.timestamp;
        uint256 timeStaked = current - stakeInfo.time;
        
        if(!stakeInfo.flag || (timeStaked < metaInfo.locked_time)){
            return 0;
        } else {
            uint256 calRate = timeStaked < stakeInfo.package_time ? metaInfo.floating_rate: stakeInfo.rate;
            
            uint256 amountProfitBySeconds = stakeInfo.amount.div(Percent).div(yearTimestamp).mul(calRate);
            return amountProfitBySeconds.mul(timeStaked);
        }
    }

    function validateCustomName(string memory name, string memory name_prefix, address user) private pure returns (bool){
        uint256 nameSize = bytes(name).length;
        uint256 prefixNameSize = bytes(name_prefix).length;
        if(prefixNameSize == 0){
            return Convertible.compareStrings(Convertible.sliceString(1,10, Convertible.convertAddressToString(user)), name);
        }
        return Convertible.compareStrings(Convertible.sliceString(1,prefixNameSize,name), name_prefix) && nameSize == 10;
    }
    
    /**
     * @dev Staking an `amount` in the registered package and returning an NFT to msg.sender.
     *
     * Requirements:
     *
     * - `amount` must be larger than zero.
     * - `name` charge `naming_fee` when user wants to customize the name ( if following C98 Rule Ref ID not charging `naming_fee` ).
     * - `package` registered package ID
     * - `customID` The custom NFT ID is optional for user and will be charged in `id_fee`. If input 0 the system will make a random ID.
     * Emits a {_stake} event.
     */
    function stake(uint256 _amount, string memory _name, string memory _package, uint256 _customID) public {
        require(validPackage(_package), "C98Stake: Package not found");
        
        PackageInfo memory pkInfo = PackageInfos[_package];
        // Check the validity of the package min, max & the amount of transferFrom
        require(_amount >= pkInfo.min && _amount < pkInfo.max , "C98Stake: Wrong min max format");
        MetaInfo storage metaInfo = MetaInfos[pkInfo.meta];
        IBEP20 metaToken = IBEP20(pkInfo.meta);

        uint256 totalStakedFinal = metaInfo.total_staked.add(_amount);
        require(totalStakedFinal <= metaInfo.max_staked, "C98Stake: Maximum number of staked");
    
        bool _isCustomID = _customID != 0;
        //Validate the custom name if basing on C98 Ref ID Rule, it will be free of change
        uint256 nameSize = bytes(_name).length;

        bool _isNotCustomname = validateCustomName(_name, metaInfo.name_prefix, msg.sender);
        
        if(!_isNotCustomname){
            require(nameSize <= 20 && nameSize > 0,"C98Stake: Not meet name condition");
        }
        
        uint256 payAmount =  _amount.add(_isCustomID ? metaInfo.id_fee : 0 ).add(_isNotCustomname ? 0 : metaInfo.naming_fee);
        metaToken.safeTransferFrom(msg.sender, address(this), payAmount);
        
        string memory randomID;
        
        if (_isCustomID){
            randomID = Convertible.uint2str(_customID);
        } else {
            string memory randomConvert = Convertible.uint2str(uint256(keccak256(abi.encodePacked(totalToken().add(1),_amount,block.timestamp,metaInfo.nft_prefix))));
            randomID = Convertible.sliceString(10,21,randomConvert);
        }
        
        // Random string after prefix is fixed at 12
        require(bytes(randomID).length == 12);
        
        // Token ID start with nft_prefix
        uint256 nftPackageId = Convertible.bytesToUInt(Convertible.stringToBytes32(string(abi.encodePacked(metaInfo.nft_prefix,randomID))));
        
        require(!_exists(nftPackageId), "ERC721: token already minted");
        
        // Storage stake information
        StakeInfo storage stakeInfo = StakeInfos[nftPackageId];
        stakeInfo.flag = true;
        stakeInfo.amount = _amount;
        stakeInfo.time = block.timestamp;
        stakeInfo.packageID = _package;
        stakeInfo.meta = pkInfo.meta;
        
        stakeInfo.name = _name;
        stakeInfo.isCustomID = _isCustomID;
        
        stakeInfo.pending_flag = false;
        stakeInfo.pending_time = metaInfo.pending_time;
        stakeInfo.package_time = pkInfo.time;
        stakeInfo.rate = pkInfo.rate;
        
        metaInfo.total_staked = totalStakedFinal;
        _mintAnElement(msg.sender, nftPackageId, _isCustomID);
    }
    
    /**
     * @dev Renaming the existed NFT and charging `naming_fee`.
     *
     * Requirements:
     *
     * - `tokenId` must be existed.
     * - `name` must be existed.
     * Emits a {_renaming} event.
     */
    function renaming (uint256 _tokenId,string memory _name) public {
        StakeInfo storage stakeInfo = StakeInfos[_tokenId];
        MetaInfo memory metaInfo = MetaInfos[stakeInfo.meta];
        IBEP20 metaToken = IBEP20(stakeInfo.meta);

        require(ownerOf(_tokenId) == msg.sender, "C98Stake: Not meet owner condition");
        metaToken.safeTransferFrom(msg.sender, address(this), metaInfo.naming_fee);
        uint256 nameSize = bytes(_name).length;
        require(nameSize <= 20 && nameSize > 0,"C98Stake: Not meet name condition");
        
        stakeInfo.name = _name;
        emit _renaming(_tokenId, _name);
    }
    
    /**
     * @dev Unstake the `amount` in NFT and get the profit following the previous conditions.
     *
     * Requirements:
     *
     * - `tokenId` must be existed.
     * Emits a {_unstake} event.
     */
    function unstake(uint256 _tokenId) public {
        StakeInfo storage stakeInfo = StakeInfos[_tokenId];
        MetaInfo storage metaInfo = MetaInfos[stakeInfo.meta];

        uint256 _profit = getStakedByTokenId(_tokenId);
        require(_profit > 0, "C98Stake: Not meet unstake condition");
        require(ownerOf(_tokenId) == msg.sender, "C98Stake: Not meet owner condition");
        
        IBEP20 metaToken = IBEP20(stakeInfo.meta);
         
        uint256 _profitTotal = _profit.add(stakeInfo.amount);
          
        require(metaToken.balanceOf(address(this)) >= _profitTotal);
        stakeInfo.flag = false;
        metaInfo.total_staked = metaInfo.total_staked.sub(stakeInfo.amount);
        
        if(stakeInfo.pending_time == 0){
          metaToken.safeTransfer(msg.sender, _profitTotal);
        } else {
            stakeInfo.pending_flag = true;
        }
        
        stakeInfo.unstaked_time = block.timestamp;
        stakeInfo.earn_staked  = _profitTotal;
        
        emit _unstake(_tokenId, _profitTotal, stakeInfo.time);
    }

    /**
     * @dev Claim Pending the `amount` in NFT and get the earn_staked after unstake and wait for pending_time.
     *
     * Requirements:
     *
     * - `tokenId` must be existed and already unstaked.
     * Emits a {_claim} event.
     */
    function claimPending(uint256 _tokenId) public {
        StakeInfo storage stakeInfo = StakeInfos[_tokenId];

        require(stakeInfo.pending_flag, "C98Stake: Not meet claim pending condition");
        require(ownerOf(_tokenId) == msg.sender, "C98Stake: Not meet owner condition");

        IBEP20 metaToken = IBEP20(stakeInfo.meta);

        require(metaToken.balanceOf(address(this)) >= stakeInfo.earn_staked,"C98Stake: Not enough pool");

        stakeInfo.pending_flag = false;
        metaToken.safeTransfer(msg.sender, stakeInfo.earn_staked);
        
        stakeInfo.claim_pending_time = block.timestamp;
        
        emit _claim(_tokenId, stakeInfo.earn_staked, stakeInfo.time);
    }
    
    function _mintAnElement(address _to, uint256 _tokenId, bool _isCustomID) private {
        _tokenIdTracker.increment();
        _safeMint(_to, _tokenId);
        emit _stake(_tokenId, _isCustomID);
    }
    
    /**
     * @dev The Owner withdraws any tokens for emergency case
     *
     * Requirements:
     *
     * - `amount` must be larger than zero.
     */
    function withdraw(uint256 _amount, IBEP20 _token) public onlyOwner {
        require(_amount > 0);
        require(_token.balanceOf(address(this)) >= _amount);
        _token.safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Get info Staked by NFT ID
     */
    function getStakedInfo(uint256 tokenId) external view returns (StakeInfo memory) {
        StakeInfo memory stakeInfo = StakeInfos[tokenId];
        stakeInfo.est_staked = getStakedByTokenId(tokenId);
        stakeInfo.id = tokenId;
        return stakeInfo;
    }

    /**
     * @dev Get list NFT staked by address
     */
    function walletOfOwner(address _owner) external view returns (StakeInfo[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        StakeInfo[]memory addressStaked = new StakeInfo[](tokenCount);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenIndex = tokenOfOwnerByIndex(_owner, i);
            StakeInfo memory stakeInfoIndex = StakeInfos[tokenIndex];
            stakeInfoIndex.est_staked = getStakedByTokenId(tokenIndex);
            stakeInfoIndex.id = tokenIndex;
            addressStaked[i] = stakeInfoIndex;
        }
    
        return addressStaked;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function totalToken() public view returns (uint256) {
        return _tokenIdTracker.current();
    }
}