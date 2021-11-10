/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/drafts/Counters.sol

pragma solidity ^0.5.0;


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

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;


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
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
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
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.5.0;








/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This is an internal detail of the `ERC721` contract and its use is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Metadata.sol

pragma solidity ^0.5.0;





contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: if all token IDs share a prefix (e.g. if your URIs look like
     * `http://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     *
     * _Available since v2.5.0._
     */
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a preffix in {tokenURI} to each token's URI, when
    * they are non-empty.
    *
    * _Available since v2.5.0._
    */
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Burnable.sol

pragma solidity ^0.5.0;



/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns a specific ERC721 token.
     * @param tokenId uint256 id of the ERC721 token to be burned.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

// File: base64-sol/base64.sol

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// File: contracts/Data.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Data {

  function getBody(bytes memory input) internal pure returns (string[2] memory) {
    string[2][8] memory body = [
      [
        "Circle",
        "<circle cx=\"12\" cy=\"12\" r=\"10\"></circle>"
      ],
      [
        "Cross",
        "<path d=\"M 5,1 V 5 H 1 v 14 h 4 v 4 h 14 v -4 h 4 V 5 H 19 V 1 Z\"></path>"
      ],
      [
        "Bell",
        "<path d=\"M 6,4.1450726 3,21 12,23 21,21 18,4.1450726 c -1.040085,-4.35794012 -11.004045,-4.17303435 -12,0 z\"></path><path d=\"M 3.5,19 C 4.33,19 5,18.33 5,17.5 5,16.67 4.33,16 3.5,16 2.67,16 2,16.67 2,17.5 2,18.33 2.67,19 3.5,19 Z\"></path><path d=\"M 4.5,15 C 5.33,15 6,14.33 6,13.5 6,12.67 5.33,12 4.5,12 3.67,12 3,12.67 3,13.5 3,14.33 3.67,15 4.5,15 Z\"></path><path d=\"M 20.5,19 C 19.67,19 19,18.33 19,17.5 19,16.67 19.67,16 20.5,16 c 0.83,0 1.5,0.67 1.5,1.5 0,0.83 -0.67,1.5 -1.5,1.5 z\"></path><path d=\"M 19.5,15 C 18.67,15 18,14.33 18,13.5 18,12.67 18.67,12 19.5,12 c 0.83,0 1.5,0.67 1.5,1.5 0,0.83 -0.67,1.5 -1.5,1.5 z\"></path>"
      ],
      [
        "X",
        "<path d=\"M 14.444444,0.99999994 12,3.4444444 9.5555556,0.99999994 0.99999994,9.5555556 3.4444444,12 0.99999994,14.444444 9.5555556,23 12,20.555556 14.444444,23 23,14.444444 20.555556,12 23,9.5555556 Z\"></path>"
      ],
      [
        "Ghost",
        "<path d=\"M 4,2 5.5976562,9.9882812 1.0507812,14.535156 2.4648438,15.949219 6.0683594,12.345703 8,22 h 8 l 1.931641,-9.654297 3.603515,3.603516 1.414063,-1.414063 L 18.402344,9.9882812 20,2 Z\"></path>"
      ],
      [
        "Polygon",
        "<path d=\"M 21.999999,17.773502 12,23.547005 2.0000006,17.773502 l 0,-11.5470044 L 12,0.4529953 21.999999,6.2264977 Z\"></path>"
      ],
      [
        "Skull",
        "<circle cy=\"10\" cx=\"12\" r=\"9\"></circle><rect width=\"10\" height=\"9\" x=\"7\" y=\"14\" rx=\"1.6666667\" ry=\"1\"></rect>"
      ],
      [
        "Trapezoid",
        "<path d=\"M 7,2 6,6 H 2 l 2,8 -2,8 H 22 L 20,14 22,6 H 18 L 17,2 Z\"></path>"
      ]
    ];
    return body[random(input, 8)];
  }

  function getEyes(bytes memory input) internal pure returns (string[2] memory) {
    string[2][8] memory eyes = [
      [
        "Eyes",
        "<path d=\"M 15.5,11 C 16.33,11 17,10.33 17,9.5 17,8.67 16.33,8 15.5,8 14.67,8 14,8.67 14,9.5 c 0,0.83 0.67,1.5 1.5,1.5 z\"></path><path d=\"M 8.5,11 C 9.33,11 10,10.33 10,9.5 10,8.67 9.33,8 8.5,8 7.67,8 7,8.67 7,9.5 7,10.33 7.67,11 8.5,11 Z\"></path><path d=\"M 15.5,11 C 16.33,11 17,10.33 17,9.5 17,8.67 16.33,8 15.5,8 14.67,8 14,8.67 14,9.5 c 0,0.83 0.67,1.5 1.5,1.5 z\"></path>"
      ],
      [
        "Dizzy",
        "<rect width=\"6\" height=\"1\" x=\"9.7279215\" y=\"0.20710692\" transform=\"rotate(45)\"></rect><rect transform=\"rotate(135)\" y=\"-13.227921\" x=\"-2.2928932\" height=\"1\" width=\"6\"></rect><rect transform=\"rotate(45)\" y=\"-4.7426405\" x=\"14.67767\" height=\"1\" width=\"6\"></rect><rect width=\"6\" height=\"1\" x=\"-7.2426405\" y=\"-18.17767\" transform=\"rotate(135)\"></rect>"
      ],
      [
        "Glasses",
        "<path d=\"M 15.5,7 C 14.116667,7 13,8.1166667 13,9.5 13,10.883333 14.116667,12 15.5,12 16.883333,12 18,10.883333 18,9.5 18,8.1166667 16.883333,7 15.5,7 Z m 0,1 C 16.33,8 17,8.67 17,9.5 17,10.33 16.33,11 15.5,11 14.67,11 14,10.33 14,9.5 14,8.67 14.67,8 15.5,8 Z\"></path><path d=\"M 8.5,7 C 7.116667,7 6,8.1166667 6,9.5 6,10.883333 7.116667,12 8.5,12 9.883333,12 11,10.883333 11,9.5 11,8.1166667 9.883333,7 8.5,7 Z m 0,1 C 9.33,8 10,8.67 10,9.5 10,10.33 9.33,11 8.5,11 7.67,11 7,10.33 7,9.5 7,8.67 7.67,8 8.5,8 Z\"></path><path d=\"m 12,8 c -0.989493,0 -1.8112,0.857662 -2,2 h 0.753315 C 10.935894,9.418302 11.466399,9 12,9 c 0.533601,0 1.064106,0.418302 1.246685,1 H 14 C 13.8112,8.857662 12.989493,8 12,8 Z\"></path>"
      ],
      [
        "Eye",
        "<path d=\"M 12,6.5 A 7,7 0 0 0 6.2617188,9.494141 7,7 0 0 0 12,12.5 7,7 0 0 0 17.738281,9.505859 7,7 0 0 0 12,6.5 Z M 12,7 c 1.383333,0 2.5,1.116667 2.5,2.5 C 14.5,10.883333 13.383333,12 12,12 10.616667,12 9.5,10.883333 9.5,9.5 9.5,8.116667 10.616667,7 12,7 Z m 0,1 c -0.83,0 -1.5,0.67 -1.5,1.5 0,0.83 0.67,1.5 1.5,1.5 0.83,0 1.5,-0.67 1.5,-1.5 C 13.5,8.67 12.83,8 12,8 Z\"></path>"
      ],
      [
        "Sunglass",
        "<path d=\"m 12,8 c -0.989493,0 -1.8112,0.857662 -2,2 h 0.753315 C 10.935894,9.418302 11.466399,9 12,9 c 0.533601,0 1.064106,0.418302 1.246685,1 H 14 C 13.8112,8.857662 12.989493,8 12,8 Z\"></path><rect width=\"6\" height=\"6\" x=\"5\" y=\"7\" rx=\"1\" ry=\"1\"></rect><rect ry=\"1\" rx=\"1\" y=\"7\" x=\"13\" height=\"6\" width=\"6\"></rect>"
      ],
      [
        "Alien",
        "<path d=\"m 15.888229,10.948889 c 1.603436,-0.42964 2.724368,-1.4236277 2.509548,-2.2253461 -0.214819,-0.8017185 -1.682569,-2.0581593 -3.286006,-1.6285196 -1.603436,0.4296396 -2.724368,2.3797154 -2.509548,3.1814337 0.214819,0.801719 1.682569,1.102071 3.286006,0.672432 z\"></path><path d=\"M 8.1117707,10.948889 C 6.5083347,10.519249 5.3874027,9.5252613 5.6022227,8.7235429 5.8170417,7.9218244 7.2847917,6.6653836 8.8882287,7.0950233 10.491665,7.5246629 11.612597,9.4747387 11.397777,10.276457 11.182958,11.078176 9.7152077,11.378528 8.1117707,10.948889 Z\"></path>"
      ],
      [
        "Demon",
        "<path d=\"m 6,7 -2,2 4,4 3,-1 V 10 L 10.95313,9.970703 C 10.733059,11.127302 9.7218293,12 8.5,12 7.116667,12 6,10.883333 6,9.5 6,8.7128681 6.3690487,8.0203566 6.9355469,7.5625 Z M 7.8867188,8.1328125 C 7.3644757,8.3671413 7,8.8893367 7,9.5 7,10.33 7.67,11 8.5,11 9.33,11 10,10.33 10,9.5 10,9.463163 9.99088,9.42874 9.988281,9.3925781 Z\"></path><path d=\"M 18,7 17.064453,7.5625 C 17.630951,8.0203566 18,8.7128681 18,9.5 18,10.883333 16.883333,12 15.5,12 14.278171,12 13.266941,11.127302 13.046875,9.9707031 L 13,10 v 2 l 3,1 4,-4 z M 16.113281,8.1328125 14.011719,9.3925781 C 14.009124,9.4287398 14,9.4631634 14,9.5 14,10.33 14.67,11 15.5,11 16.33,11 17,10.33 17,9.5 17,8.8893367 16.635524,8.3671413 16.113281,8.1328125 Z\"></path>"
      ],
      [
        "Neutral",
        "<rect width=\"14\" height=\"3\" x=\"5\" y=\"8\" rx=\"1\" ry=\"1\"></rect>"
      ]
    ];
    return eyes[random(input, 8)];
  }


  function getMouth(bytes memory input) internal pure returns (string[2] memory) {
    string[2][8] memory mouth = [
      [
        "Smile",
        "<path d=\"m 12,17.5 c 2.33,0 4.31,-1.46 5.11,-3.5 H 6.89 c 0.8,2.04 2.78,3.5 5.11,3.5 z\"></path>"
      ],
      [
        "Angry",
        "<path d=\"m 12,14 c 2.33,0 4.31,1.46 5.11,3.5 H 6.89 C 7.69,15.46 9.67,14 12,14 Z\"></path>"
      ],
      [
        "Surprised",
        "<path d=\"m 12,17 c 0.83,0 1.5,-0.67 1.5,-1.5 0,-0.83 -0.67,-1.5 -1.5,-1.5 -0.83,0 -1.5,0.67 -1.5,1.5 0,0.83 0.67,1.5 1.5,1.5 z\"></path>"
      ],
      [
        "Vampire",
        "<path d=\"m 12,17.5 c 2.33,0 4.31,-1.46 5.11,-3.5 H 6.89 c 0.8,2.04 2.78,3.5 5.11,3.5 z\"></path><path d=\"m 8,15 1,5 1,-5 z\"></path><path d=\"m 14,15 1,5 1,-5 z\"></path>"
      ],
      [
        "Robot",
        "<path d=\"m 6,14 c -0.554,0 -1,0.446 -1,1 v 3 c 0,0.554 0.446,1 1,1 h 12 c 0.554,0 1,-0.446 1,-1 v -3 c 0,-0.554 -0.446,-1 -1,-1 z m 1.5,1 C 7.777,15 8,15.223 8,15.5 v 2 C 8,17.777 7.777,18 7.5,18 7.223,18 7,17.777 7,17.5 v -2 C 7,15.223 7.223,15 7.5,15 Z m 3,0 c 0.277,0 0.5,0.223 0.5,0.5 v 2 C 11,17.777 10.777,18 10.5,18 10.223,18 10,17.777 10,17.5 v -2 C 10,15.223 10.223,15 10.5,15 Z m 3,0 c 0.277,0 0.5,0.223 0.5,0.5 v 2 C 14,17.777 13.777,18 13.5,18 13.223,18 13,17.777 13,17.5 v -2 C 13,15.223 13.223,15 13.5,15 Z m 3,0 c 0.277,0 0.5,0.223 0.5,0.5 v 2 C 17,17.777 16.777,18 16.5,18 16.223,18 16,17.777 16,17.5 v -2 C 16,15.223 16.223,15 16.5,15 Z\"></path>"
      ],
      [
        "Mask",
        "<path d=\"m 8,14 c -0.554,0 -1,0.446 -1,1 v 2 c 0,0.554 1.446,2 2,2 h 6 c 0.554,0 2,-1.446 2,-2 v -2 c 0,-0.554 -0.446,-1 -1,-1 z m 1,1 h 2 v 2 c 0,0.554 -0.446,1 -1,1 -0.554,0 -1,-0.446 -1,-1 z m 4,0 h 2 v 2 c 0,0.554 -0.446,1 -1,1 -0.554,0 -1,-0.446 -1,-1 z\"></path>"
      ],
      [
        "Zipper",
        "<path d=\"M 7.5,15 C 7.223,15 7,15.223 7,15.5 V 16 H 6.5 C 6.223,16 6,16.223 6,16.5 6,16.777 6.223,17 6.5,17 H 7 v 0.5 C 7,17.777 7.223,18 7.5,18 7.777,18 8,17.777 8,17.5 V 17 h 2 v 0.5 c 0,0.277 0.223,0.5 0.5,0.5 0.277,0 0.5,-0.223 0.5,-0.5 V 17 h 2 v 0.5 c 0,0.277 0.223,0.5 0.5,0.5 0.277,0 0.5,-0.223 0.5,-0.5 V 17 h 2 v 0.5 c 0,0.277 0.223,0.5 0.5,0.5 0.277,0 0.5,-0.223 0.5,-0.5 V 17 h 0.5 C 17.777,17 18,16.777 18,16.5 18,16.223 17.777,16 17.5,16 H 17 V 15.5 C 17,15.223 16.777,15 16.5,15 16.223,15 16,15.223 16,15.5 V 16 H 14 V 15.5 C 14,15.223 13.777,15 13.5,15 13.223,15 13,15.223 13,15.5 V 16 H 11 V 15.5 C 11,15.223 10.777,15 10.5,15 10.223,15 10,15.223 10,15.5 V 16 H 8 V 15.5 C 8,15.223 7.777,15 7.5,15 Z\"></path>"
      ],
      [
        "Fang",
        "<path d=\"m 12,14 c 2.33,0 4.31,1.46 5.11,3.5 H 6.89 C 7.69,15.46 9.67,14 12,14 Z\"></path><path d=\"m 8,16 1,5 1,-5 z\"></path><path d=\"m 14,16 1,5 1,-5 z\"></path>"
      ]
    ];
    return mouth[random(input, 8)];
  }

  function getColorBodyDark(bytes memory input) internal pure returns (string[2] memory) {
    string[2][4] memory colors = [      
      [
        "#616161",
        "#424242"
      ],
      [
        "#1e88e5",
        "#1976d2"
      ],
      [
        "#039be5",
        "#0288d1"
      ],
      [
        "#00acc1",
        "#0097a7"
      ]
    ];
    return colors[random(input, 4)];
  }

  function getColorBodyLight(bytes memory input) internal pure returns (string[2] memory) {
    string[2][4] memory colors = [      
      [
        "#fdd835",
        "#fbc02d"
      ],
      [
        "#ffb300",
        "#ffa000"
      ],
      [
        "#fb8c00",
        "#f57c00"
      ],
      [
        "#f4511e",
        "#e64a19"
      ]
    ];
    return colors[random(input, 4)];
  }


  function getColorEyesMouthDark(bytes memory input) internal pure returns (string[2] memory) {
    string[2][8] memory colors = [ 
      [
        "#ba68c8",
        "#ab47bc"
      ],
      [
        "#9575cd",
        "#7e57c2"
      ],
      [
        "#7986cb",
        "#5c6bc0"
      ],
      [
        "#64b5f6",
        "#42a5f5"
      ],
      [
        "#4fc3f7",
        "#29b6f6"
      ],
      [
        "#4dd0e1",
        "#26c6da"
      ],
      [
        "#4db6ac",
        "#26a69a"
      ],
      [
        "#616161",
        "#424242"
      ]
    ];
    return colors[random(input, 8)];
  }

  function getColorEyesMouthLight(bytes memory input) internal pure returns (string[2] memory) {
    string[2][8] memory colors = [ 
      [
        "#e57373",
        "#ef5350"
      ],
      [
        "#f06292",
        "#ec407a"
      ],
      [
        "#dce775",
        "#d4e157"
      ],
      [
        "#fff176",
        "#ffee58"
      ],
      [
        "#ffd54f",
        "#ffca28"
      ],
      [
        "#ffb74d",
        "#ffa726"
      ],
      [
        "#ff8a65",
        "#ff7043"
      ],
      [
        "#eeeeee",
        "#e0e0e0"
      ]
    ];
    return colors[random(input, 8)];
  }

  function random(bytes memory input, uint256 range) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input))) % range;
  }

}

// File: contracts/Permavatar.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;








contract Permavatar is ERC721, ERC721Burnable, ERC721Metadata, Ownable, Data {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  uint256 mintFeeValue;
  address payable mintFeeAddress;
  bool mintDisabled;

  string constant header = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="600" height="600"><defs><clipPath id="clip-left"><rect width="13" height="24" x="0" y="0"></rect></clipPath><clipPath id="clip-right"><rect width="12" height="24" x="12" y="0"></rect></clipPath></defs><rect width="600" height="600" fill="#6183fa" opacity="0.2"></rect><svg viewBox="-3 -3 30 30">';
  string constant footer = '</svg></svg>';

  mapping (uint256 => address) internal _mints;

  constructor() public ERC721Metadata("Permavatar", "PA") {}

  function getMintFeeValue() public view onlyOwner returns(uint256) {
		return mintFeeValue;
	}

	function setMintFeeValue(uint256 _mintFeeValue) external onlyOwner {
		mintFeeValue = _mintFeeValue;
	}

  function getMintFeeAddress() public view onlyOwner returns(address) {
		return mintFeeAddress;
	}

	function setMintFeeAddress(address payable _mintFeeAddress) external onlyOwner {
		mintFeeAddress = _mintFeeAddress;
	}

  function getMintDisabled() public view onlyOwner returns(bool) {
		return mintDisabled;
	}

	function setMintDisabled(bool _mintDisabled) external onlyOwner {
		mintDisabled = _mintDisabled;
	}

  function getCurrentTokenId() public view returns(uint256) {
    return _tokenIds.current();
  }

  function mint() external payable returns (uint256) {
    require(mintDisabled == false, "I'm dead.");
    if (mintFeeValue > 0) {
      require(msg.value >= mintFeeValue, "I'm hungry.");
    }
    _tokenIds.increment();
    uint256 newTokenId = _tokenIds.current();
    require(newTokenId <= 9999, "I'm full.");
    _mints[newTokenId] = msg.sender;
    _safeMint(msg.sender, newTokenId);
    if (mintFeeAddress != address(0)) {
      mintFeeAddress.transfer(mintFeeValue);
    }
    return newTokenId;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    address creator = _mints[tokenId];

    string memory output;
    string memory svg;

    svg = header;

    uint256 colorType = random(abi.encodePacked("DARK_LIGHT", creator, tokenId), 2);
    
    string[2] memory colorBody;
    string[2] memory colorEyes;
    string[2] memory colorMouth;

    if (colorType == 0) {
      colorBody = getColorBodyDark(abi.encodePacked("COLOR_BODY", creator, tokenId));
      colorEyes = getColorEyesMouthLight(abi.encodePacked("COLOR_EYES", creator, tokenId));
      colorMouth = getColorEyesMouthLight(abi.encodePacked("COLOR_MOUTH", creator, tokenId));
    } else {
      colorBody = getColorBodyLight(abi.encodePacked("COLOR_BODY", creator, tokenId));
      colorEyes = getColorEyesMouthDark(abi.encodePacked("COLOR_EYES", creator, tokenId));
      colorMouth = getColorEyesMouthDark(abi.encodePacked("COLOR_MOUTH", creator, tokenId));
    }

    string[2] memory body = getBody(abi.encodePacked("PARTS_BODY", creator, tokenId));
    svg = string(abi.encodePacked(svg, '<g style="fill:', colorBody[0], '" clip-path="url(#clip-left)">', body[1], '</g>'));
    svg = string(abi.encodePacked(svg, '<g style="fill:', colorBody[1], '" clip-path="url(#clip-right)">', body[1], '</g>'));

    string[2] memory eyes = getEyes(abi.encodePacked("PARTS_EYES", creator, tokenId));
    svg = string(abi.encodePacked(svg, '<g style="fill:', colorEyes[0], '" clip-path="url(#clip-left)">', eyes[1], '</g>'));
    svg = string(abi.encodePacked(svg, '<g style="fill:', colorEyes[1], '" clip-path="url(#clip-right)">', eyes[1], '</g>'));

    string[2] memory mouth = getMouth(abi.encodePacked("PARTS_MOUTH", creator, tokenId));
    svg = string(abi.encodePacked(svg, '<g style="fill:', colorMouth[0], '" clip-path="url(#clip-left)">', mouth[1], '</g>'));
    svg = string(abi.encodePacked(svg, '<g style="fill:', colorMouth[1], '" clip-path="url(#clip-right)">', mouth[1], '</g>'));

    svg = string(abi.encodePacked(svg, footer));

    output = string(abi.encodePacked(output, '{"name": "Permavatar #', toString(tokenId), '", "description": "A permavatar is analgorithmically generated NFT. Each permavatar is uniquely generated from 8 types of face / eye / mouth / color components. ", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '", "attributes": [{"trait_type": "Body", "value": "', body[0] ,'"},{"trait_type": "Eyes", "value": "', eyes[0] ,'"},{"trait_type": "Mouth", "value": "', mouth[0] ,'"},{"trait_type": "Color", "value": "', colorBody[1] ,'"}]}'));

    output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(output))));

    return output;
  }

  function toString(uint256 value) internal pure returns (string memory) {
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

}