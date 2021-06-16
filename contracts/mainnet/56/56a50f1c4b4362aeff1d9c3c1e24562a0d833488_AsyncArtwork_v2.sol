/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// File: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

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
contract Context is Initializable {
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

// File: @openzeppelin/contracts-ethereum-package/contracts/introspection/IERC165.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is Initializable, IERC165 {
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

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/drafts/Counters.sol

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

// File: @openzeppelin/contracts-ethereum-package/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is Initializable, IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function initialize() public initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
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

    uint256[50] private ______gap;
}

// File: contracts/ERC721.sol

pragma solidity ^0.5.0;









/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Initializable, Context, ERC165, IERC721 {
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

    function initialize() public initializer {
        ERC165.initialize();

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    function _hasBeenInitialized() internal view returns (bool) {
        return supportsInterface(_INTERFACE_ID_ERC721);
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
     * Requires the _msgSender() to be the owner, approved, or operator
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

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.5.0;



/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is Initializable, IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: contracts/ERC721Enumerable.sol

pragma solidity ^0.5.0;






/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is Initializable, Context, ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    function initialize() public initializer {
        require(ERC721._hasBeenInitialized());
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function _hasBeenInitialized() internal view returns (bool) {
        return supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    // /**
    //  * @dev Internal function to burn a specific token.
    //  * Reverts if the token does not exist.
    //  * Deprecated, use {ERC721-_burn} instead.
    //  * @param owner owner of the token to burn
    //  * @param tokenId uint256 ID of the token being burned
    //  */
    // function _burn(address owner, uint256 tokenId) internal {
    //     super._burn(owner, tokenId);

    //     _removeTokenFromOwnerEnumeration(owner, tokenId);
    //     // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
    //     _ownedTokensIndex[tokenId] = 0;

    //     // _removeTokenFromAllTokensEnumeration(tokenId);
    // }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
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

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    // function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    //     // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
    //     // then delete the last slot (swap and pop).

    //     uint256 lastTokenIndex = _allTokens.length.sub(1);
    //     uint256 tokenIndex = _allTokensIndex[tokenId];

    //     // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
    //     // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
    //     // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
    //     uint256 lastTokenId = _allTokens[lastTokenIndex];

    //     _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    //     _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    //     // This also deletes the contents at the last position of the array
    //     _allTokens.length--;
    //     _allTokensIndex[tokenId] = 0;
    // }

    uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.5.0;



/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is Initializable, IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/ERC721Metadata.sol

pragma solidity ^0.5.0;






contract ERC721Metadata is Initializable, Context, ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

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
    function initialize(string memory name, string memory symbol) public initializer {
        require(ERC721._hasBeenInitialized());

        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function _hasBeenInitialized() internal view returns (bool) {
        return supportsInterface(_INTERFACE_ID_ERC721_METADATA);
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
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    // *
    //  * @dev Internal function to burn a specific token.
    //  * Reverts if the token does not exist.
    //  * Deprecated, use _burn(uint256) instead.
    //  * @param owner owner of the token to burn
    //  * @param tokenId uint256 ID of the token being burned by the msg.sender
     
    // function _burn(address owner, uint256 tokenId) internal {
    //     super._burn(owner, tokenId);

    //     // Clear metadata (if any)
    //     if (bytes(_tokenURIs[tokenId]).length != 0) {
    //         delete _tokenURIs[tokenId];
    //     }
    // }

    uint256[50] private ______gap;
}

// File: contracts/AsyncArtwork_v2.sol

pragma solidity ^0.5.12;




// interface for the v1 contract
interface AsyncArtwork_v1 {
    function getControlToken(uint256 controlTokenId)
        external
        view
        returns (int256[] memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// Copyright (C) 2020 Asynchronous Art, Inc.
// GNU General Public License v3.0
// Full notice https://github.com/asyncart/async-contracts/blob/master/LICENSE

contract AsyncArtwork_v2 is
    Initializable,
    ERC721,
    ERC721Enumerable,
    ERC721Metadata
{
    // An event whenever the platform address is updated
    event PlatformAddressUpdated(address platformAddress);

    event PermissionUpdated(
        uint256 tokenId,
        address tokenOwner,
        address permissioned
    );

    // An event whenever a creator is whitelisted with the token id and the layer count
    event CreatorWhitelisted(
        uint256 tokenId,
        uint256 layerCount,
        address creator
    );

    // An event whenever royalty amount for a token is updated
    event PlatformSalePercentageUpdated(
        uint256 tokenId,
        uint256 platformFirstPercentage,
        uint256 platformSecondPercentage
    );

    event DefaultPlatformSalePercentageUpdated(
        uint256 defaultPlatformFirstSalePercentage,
        uint256 defaultPlatformSecondSalePercentage
    );

    // An event whenever artist secondary sale percentage is updated
    event ArtistSecondSalePercentUpdated(uint256 artistSecondPercentage);

    // An event whenever a bid is proposed
    event BidProposed(uint256 tokenId, uint256 bidAmount, address bidder);

    // An event whenever an bid is withdrawn
    event BidWithdrawn(uint256 tokenId);

    // An event whenever a buy now price has been set
    event BuyPriceSet(uint256 tokenId, uint256 price);

    // An event when a token has been sold
    event TokenSale(
        // the id of the token
        uint256 tokenId,
        // the price that the token was sold for
        uint256 salePrice,
        // the address of the buyer
        address buyer
    );

    // An event when a token(s) first sale requirement has been waived
    event FirstSaleWaived(
        // the ids of the token
        uint256[] tokenIds
    );

    // An event whenever a control token has been updated
    event ControlLeverUpdated(
        // the id of the token
        uint256 tokenId,
        // an optional amount that the updater sent to boost priority of the rendering
        uint256 priorityTip,
        // the number of times this control lever can now be updated
        int256 numRemainingUpdates,
        // the ids of the levers that were updated
        uint256[] leverIds,
        // the previous values that the levers had before this update (for clients who want to animate the change)
        int256[] previousValues,
        // the new updated value
        int256[] updatedValues
    );

    // struct for a token that controls part of the artwork
    struct ControlToken {
        // number that tracks how many levers there are
        uint256 numControlLevers;
        // The number of update calls this token has (-1 for infinite)
        int256 numRemainingUpdates;
        // false by default, true once instantiated
        bool exists;
        // false by default, true once setup by the artist
        bool isSetup;
        // the levers that this control token can use
        mapping(uint256 => ControlLever) levers;
    }

    // struct for a lever on a control token that can be changed
    struct ControlLever {
        // // The minimum value this token can have (inclusive)
        int256 minValue;
        // The maximum value this token can have (inclusive)
        int256 maxValue;
        // The current value for this token
        int256 currentValue;
        // false by default, true once instantiated
        bool exists;
    }

    // struct for a pending bid
    struct PendingBid {
        // the address of the bidder
        address payable bidder;
        // the amount that they bid
        uint256 amount;
        // false by default, true once instantiated
        bool exists;
    }

    struct WhitelistReservation {
        // the address of the creator
        address creator;
        // the amount of layers they're expected to mint
        uint256 layerCount;
    }

    // track whether this token was sold the first time or not (used for determining whether to use first or secondary sale percentage)
    mapping(uint256 => bool) public tokenDidHaveFirstSale;
    // if a token's URI has been locked or not
    mapping(uint256 => bool) public tokenURILocked;
    // map control token ID to its buy price
    mapping(uint256 => uint256) public buyPrices;
    // mapping of addresses to credits for failed transfers
    mapping(address => uint256) public failedTransferCredits;
    // mapping of tokenId to percentage of sale that the platform gets on first sales
    mapping(uint256 => uint256) public platformFirstSalePercentages;
    // mapping of tokenId to percentage of sale that the platform gets on secondary sales
    mapping(uint256 => uint256) public platformSecondSalePercentages;
    // what tokenId creators are allowed to mint (and how many layers)
    mapping(uint256 => WhitelistReservation) public creatorWhitelist;
    // for each token, holds an array of the creator collaborators. For layer tokens it will likely just be [artist], for master tokens it may hold multiples
    mapping(uint256 => address payable[]) public uniqueTokenCreators;
    // map a control token ID to its highest bid
    mapping(uint256 => PendingBid) public pendingBids;
    // map a control token id to a control token struct
    mapping(uint256 => ControlToken) public controlTokenMapping;
    // mapping of addresses that are allowed to control tokens on your behalf
    mapping(address => mapping(uint256 => address))
        public permissionedControllers;
    // the percentage of sale that an artist gets on secondary sales
    uint256 public artistSecondSalePercentage;
    // gets incremented to placehold for tokens not minted yet
    uint256 public expectedTokenSupply;
    // the minimum % increase for new bids coming
    uint256 public minBidIncreasePercent;
    // the address of the platform (for receving commissions and royalties)
    address payable public platformAddress;
    // the address of the contract that can upgrade from v1 to v2 tokens
    address public upgraderAddress;
    // the address of the contract that can whitelist artists to mint
    address public minterAddress;

    // v3 vairables
    uint256 public defaultPlatformFirstSalePercentage;
    uint256 public defaultPlatformSecondSalePercentage;

    function setup(
        string memory name,
        string memory symbol,
        uint256 initialExpectedTokenSupply,
        address _upgraderAddress
    ) public initializer {
        ERC721.initialize();
        ERC721Enumerable.initialize();
        ERC721Metadata.initialize(name, symbol);

        // starting royalty amounts
        artistSecondSalePercentage = 10;

        // intitialize the minimum bid increase percent
        minBidIncreasePercent = 1;

        // by default, the platformAddress is the address that mints this contract
        platformAddress = msg.sender;

        // set the upgrader address
        upgraderAddress = _upgraderAddress;

        // set the initial expected token supply
        expectedTokenSupply = initialExpectedTokenSupply;

        require(expectedTokenSupply > 0);
    }

    // modifier for only allowing the platform to make a call
    modifier onlyPlatform() {
        require(msg.sender == platformAddress);
        _;
    }

    // modifier for only allowing the minter to make a call
    modifier onlyMinter() {
        require(msg.sender == minterAddress);
        _;
    }

    modifier onlyWhitelistedCreator(uint256 masterTokenId, uint256 layerCount) {
        require(creatorWhitelist[masterTokenId].creator == msg.sender);
        require(creatorWhitelist[masterTokenId].layerCount == layerCount);
        _;
    }

    function setExpectedTokenSupply(uint256 newExpectedTokenSupply)
        external
        onlyPlatform
    {
        expectedTokenSupply = newExpectedTokenSupply;
    }

    // reserve a tokenID and layer count for a creator. Define a platform royalty percentage per art piece (some pieces have higher or lower amount)
    function whitelistTokenForCreator(
        address creator,
        uint256 masterTokenId,
        uint256 layerCount,
        uint256 platformFirstSalePercentage,
        uint256 platformSecondSalePercentage
    ) external onlyMinter {
        // the tokenID we're reserving must be the current expected token supply
        require(masterTokenId == expectedTokenSupply);
        // reserve the tokenID for this creator
        creatorWhitelist[masterTokenId] = WhitelistReservation(
            creator,
            layerCount
        );
        // increase the expected token supply
        expectedTokenSupply = masterTokenId.add(layerCount).add(1);
        // define the platform percentages for this token here
        platformFirstSalePercentages[
            masterTokenId
        ] = platformFirstSalePercentage;
        platformSecondSalePercentages[
            masterTokenId
        ] = platformSecondSalePercentage;

        emit CreatorWhitelisted(masterTokenId, layerCount, creator);
    }

    // Allows the platform to change the minter address
    function updateMinterAddress(address newMinterAddress)
        external
        onlyPlatform
    {
        minterAddress = newMinterAddress;
    }

    // Allows the current platform address to update to something different
    function updatePlatformAddress(address payable newPlatformAddress)
        external
        onlyPlatform
    {
        platformAddress = newPlatformAddress;

        emit PlatformAddressUpdated(newPlatformAddress);
    }

    // Allows platform to waive the first sale requirement for a token (for charity events, special cases, etc)
    function waiveFirstSaleRequirement(uint256[] calldata tokenIds)
        external
        onlyPlatform
    {
        // This allows the token sale proceeds to go to the current owner (rather than be distributed amongst the token's creators)
        for (uint256 k = 0; k < tokenIds.length; k++) {
            tokenDidHaveFirstSale[tokenIds[k]] = true;
        }

        emit FirstSaleWaived(tokenIds);
    }

    // Allows platform to change the royalty percentage for a specific token
    function updatePlatformSalePercentage(
        uint256 tokenId,
        uint256 platformFirstSalePercentage,
        uint256 platformSecondSalePercentage
    ) external onlyPlatform {
        // set the percentages for this token
        platformFirstSalePercentages[tokenId] = platformFirstSalePercentage;
        platformSecondSalePercentages[tokenId] = platformSecondSalePercentage;
        // emit an event to notify that the platform percent for this token has changed
        emit PlatformSalePercentageUpdated(
            tokenId,
            platformFirstSalePercentage,
            platformSecondSalePercentage
        );
    }

    // Allows platform to change the default sales percentages
    function updateDefaultPlatformSalePercentage(
        uint256 _defaultPlatformFirstSalePercentage,
        uint256 _defaultPlatformSecondSalePercentage
    ) external onlyPlatform {
        defaultPlatformFirstSalePercentage = _defaultPlatformFirstSalePercentage;
        defaultPlatformSecondSalePercentage = _defaultPlatformSecondSalePercentage;

        // emit an event to notify that the platform percent has changed
        emit DefaultPlatformSalePercentageUpdated(
            defaultPlatformFirstSalePercentage,
            defaultPlatformSecondSalePercentage
        );
    }

    // Allows the platform to change the minimum percent increase for incoming bids
    function updateMinimumBidIncreasePercent(uint256 _minBidIncreasePercent)
        external
        onlyPlatform
    {
        require(
            (_minBidIncreasePercent > 0) && (_minBidIncreasePercent <= 50),
            "Bid increases must be within 0-50%"
        );
        // set the new bid increase percent
        minBidIncreasePercent = _minBidIncreasePercent;
    }

    // Allow the platform to update a token's URI if it's not locked yet (for fixing tokens post mint process)
    function updateTokenURI(uint256 tokenId, string calldata tokenURI)
        external
        onlyPlatform
    {
        // ensure that this token exists
        require(_exists(tokenId));
        // ensure that the URI for this token is not locked yet
        require(tokenURILocked[tokenId] == false);
        // update the token URI
        super._setTokenURI(tokenId, tokenURI);
    }

    // Locks a token's URI from being updated
    function lockTokenURI(uint256 tokenId) external onlyPlatform {
        // ensure that this token exists
        require(_exists(tokenId));
        // lock this token's URI from being changed
        tokenURILocked[tokenId] = true;
    }

    // Allows platform to change the percentage that artists receive on secondary sales
    function updateArtistSecondSalePercentage(
        uint256 _artistSecondSalePercentage
    ) external onlyPlatform {
        // update the percentage that artists get on secondary sales
        artistSecondSalePercentage = _artistSecondSalePercentage;
        // emit an event to notify that the artist second sale percent has updated
        emit ArtistSecondSalePercentUpdated(artistSecondSalePercentage);
    }

    function setupControlToken(
        uint256 controlTokenId,
        string calldata controlTokenURI,
        int256[] calldata leverMinValues,
        int256[] calldata leverMaxValues,
        int256[] calldata leverStartValues,
        int256 numAllowedUpdates,
        address payable[] calldata additionalCollaborators
    ) external {
        // Hard cap the number of levers a single control token can have
        require(leverMinValues.length <= 500, "Too many control levers.");
        // Hard cap the number of collaborators a single control token can have
        require(
            additionalCollaborators.length <= 50,
            "Too many collaborators."
        );
        // ensure that this token is not setup yet
        require(
            controlTokenMapping[controlTokenId].isSetup == false,
            "Already setup"
        );
        // ensure that only the control token artist is attempting this mint
        require(
            uniqueTokenCreators[controlTokenId][0] == msg.sender,
            "Must be control token artist"
        );
        // enforce that the length of all the array lengths are equal
        require(
            (leverMinValues.length == leverMaxValues.length) &&
                (leverMaxValues.length == leverStartValues.length),
            "Values array mismatch"
        );
        // require the number of allowed updates to be infinite (-1) or some finite number
        require(
            (numAllowedUpdates == -1) || (numAllowedUpdates > 0),
            "Invalid allowed updates"
        );
        // mint the control token here
        super._safeMint(msg.sender, controlTokenId);
        // set token URI
        super._setTokenURI(controlTokenId, controlTokenURI);
        // create the control token
        controlTokenMapping[controlTokenId] = ControlToken(
            leverStartValues.length,
            numAllowedUpdates,
            true,
            true
        );
        // create the control token levers now
        for (uint256 k = 0; k < leverStartValues.length; k++) {
            // enforce that maxValue is greater than or equal to minValue
            require(
                leverMaxValues[k] >= leverMinValues[k],
                "Max val must >= min"
            );
            // enforce that currentValue is valid
            require(
                (leverStartValues[k] >= leverMinValues[k]) &&
                    (leverStartValues[k] <= leverMaxValues[k]),
                "Invalid start val"
            );
            // add the lever to this token
            controlTokenMapping[controlTokenId].levers[k] = ControlLever(
                leverMinValues[k],
                leverMaxValues[k],
                leverStartValues[k],
                true
            );
        }
        // the control token artist can optionally specify additional collaborators on this layer
        for (uint256 i = 0; i < additionalCollaborators.length; i++) {
            // can't provide burn address as collaborator
            require(additionalCollaborators[i] != address(0));

            uniqueTokenCreators[controlTokenId].push(
                additionalCollaborators[i]
            );
        }
    }

    // upgrade a token from the v1 contract to this v2 version
    function upgradeV1Token(
        uint256 tokenId,
        address v1Address,
        bool isControlToken,
        address to,
        uint256 platformFirstPercentageForToken,
        uint256 platformSecondPercentageForToken,
        bool hasTokenHadFirstSale,
        address payable[] calldata uniqueTokenCreatorsForToken
    ) external {
        // get reference to v1 token contract
        AsyncArtwork_v1 v1Token = AsyncArtwork_v1(v1Address);

        // require that only the upgrader address is calling this method
        require(msg.sender == upgraderAddress, "Only upgrader can call.");
        
        // preserve the unique token creators
        uniqueTokenCreators[tokenId] = uniqueTokenCreatorsForToken;

        if (isControlToken) {
            // preserve the control token details if it's a control token
            int256[] memory controlToken = v1Token.getControlToken(tokenId);
            // Require control token to be a valid size (multiple of 3)
            require(controlToken.length % 3 == 0, "Invalid control token.");
            // Require control token to have at least 1 lever
            require(controlToken.length > 0, "Control token must have levers");
            // Setup the control token
            // Use -1 for numRemainingUpdates since v1 tokens were infinite use
            controlTokenMapping[tokenId] = ControlToken(
                controlToken.length / 3,
                -1,
                true,
                true
            );

            // set each lever for the control token. getControlToken returns levers like:
            // [minValue, maxValue, curValue, minValue, maxValue, curValue, ...] so they always come in groups of 3
            for (uint256 k = 0; k < controlToken.length; k += 3) {
                controlTokenMapping[tokenId].levers[k / 3] = ControlLever(
                    controlToken[k],
                    controlToken[k + 1],
                    controlToken[k + 2],
                    true
                );
            }
        }

        // Set the royalty percentage for this token
        platformFirstSalePercentages[tokenId] = platformFirstPercentageForToken;

        platformSecondSalePercentages[
            tokenId
        ] = platformSecondPercentageForToken;

        // whether this token has already had its first sale
        tokenDidHaveFirstSale[tokenId] = hasTokenHadFirstSale;

        // Mint and transfer the token to the original v1 token owner
        super._safeMint(to, tokenId);

        // set the same token URI
        super._setTokenURI(tokenId, v1Token.tokenURI(tokenId));
    }

    function mintArtwork(
        uint256 masterTokenId,
        string calldata artworkTokenURI,
        address payable[] calldata controlTokenArtists,
        address payable[] calldata uniqueArtists
    )
        external
        onlyWhitelistedCreator(masterTokenId, controlTokenArtists.length)
    {
        // Can't mint a token with ID 0 anymore
        require(masterTokenId > 0);
        // Mint the token that represents ownership of the entire artwork
        super._safeMint(msg.sender, masterTokenId);
        // set the token URI for this art
        super._setTokenURI(masterTokenId, artworkTokenURI);
        // set the unique artists array for future royalties
        uniqueTokenCreators[masterTokenId] = uniqueArtists;
        // iterate through all control token URIs (1 for each control token)
        for (uint256 i = 0; i < controlTokenArtists.length; i++) {
            // can't provide burn address as artist
            require(controlTokenArtists[i] != address(0));
            // determine the tokenID for this control token
            uint256 controlTokenId = masterTokenId + i + 1;
            // add this control token artist to the unique creator list for that control token
            uniqueTokenCreators[controlTokenId].push(controlTokenArtists[i]);
        }
    }

    // Bidder functions
    function bid(uint256 tokenId) external payable {
        // don't allow bids of 0
        require(msg.value > 0);
        // don't let owners/approved bid on their own tokens
        require(_isApprovedOrOwner(msg.sender, tokenId) == false);
        // check if there's a high bid
        if (pendingBids[tokenId].exists) {
            // enforce that this bid is higher by at least the minimum required percent increase
            require(
                msg.value >=
                    (
                        pendingBids[tokenId]
                            .amount
                            .mul(minBidIncreasePercent.add(100))
                            .div(100)
                    ),
                "Bid must increase by min %"
            );
            // Return bid amount back to bidder
            safeFundsTransfer(
                pendingBids[tokenId].bidder,
                pendingBids[tokenId].amount
            );
        }
        // set the new highest bid
        pendingBids[tokenId] = PendingBid(msg.sender, msg.value, true);
        // Emit event for the bid proposal
        emit BidProposed(tokenId, msg.value, msg.sender);
    }

    // allows an address with a pending bid to withdraw it
    function withdrawBid(uint256 tokenId) external {
        // check that there is a bid from the sender to withdraw (also allows platform address to withdraw a bid on someone's behalf)
        require(
            (pendingBids[tokenId].bidder == msg.sender) ||
                (msg.sender == platformAddress)
        );
        // attempt to withdraw the bid
        _withdrawBid(tokenId);
    }

    function _withdrawBid(uint256 tokenId) internal {
        require(pendingBids[tokenId].exists);
        // Return bid amount back to bidder
        safeFundsTransfer(
            pendingBids[tokenId].bidder,
            pendingBids[tokenId].amount
        );
        // clear highest bid
        pendingBids[tokenId] = PendingBid(address(0), 0, false);
        // emit an event when the highest bid is withdrawn
        emit BidWithdrawn(tokenId);
    }

    // Buy the artwork for the currently set price
    // Allows the buyer to specify an expected remaining uses they'll accept
    function takeBuyPrice(uint256 tokenId, int256 expectedRemainingUpdates)
        external
        payable
    {
        // don't let owners/approved buy their own tokens
        require(_isApprovedOrOwner(msg.sender, tokenId) == false);
        // get the sale amount
        uint256 saleAmount = buyPrices[tokenId];
        // check that there is a buy price
        require(saleAmount > 0);
        // check that the buyer sent exact amount to purchase
        require(msg.value == saleAmount);
        // if this is a control token
        if (controlTokenMapping[tokenId].exists) {
            // ensure that the remaining uses on the token is equal to what buyer expects
            require(
                controlTokenMapping[tokenId].numRemainingUpdates ==
                    expectedRemainingUpdates
            );
        }
        // Return all highest bidder's money
        if (pendingBids[tokenId].exists) {
            // Return bid amount back to bidder
            safeFundsTransfer(
                pendingBids[tokenId].bidder,
                pendingBids[tokenId].amount
            );
            // clear highest bid
            pendingBids[tokenId] = PendingBid(address(0), 0, false);
        }
        onTokenSold(tokenId, saleAmount, msg.sender);
    }

    // Take an amount and distribute it evenly amongst a list of creator addresses
    function distributeFundsToCreators(
        uint256 amount,
        address payable[] memory creators
    ) private {
        if (creators.length > 0) {
            uint256 creatorShare = amount.div(creators.length);

            for (uint256 i = 0; i < creators.length; i++) {
                safeFundsTransfer(creators[i], creatorShare);
            }
        }
    }

    // When a token is sold via list price or bid. Distributes the sale amount to the unique token creators and transfer
    // the token to the new owner
    function onTokenSold(
        uint256 tokenId,
        uint256 saleAmount,
        address to
    ) private {
        // if the first sale already happened, then give the artist + platform the secondary royalty percentage
        if (tokenDidHaveFirstSale[tokenId]) {
            // give platform its secondary sale percentage
            uint256 platformAmount;
            if (platformSecondSalePercentages[tokenId] == 0) {
                // default amount
                platformAmount = saleAmount
                    .mul(defaultPlatformSecondSalePercentage)
                    .div(100);
            } else {
                platformAmount = saleAmount
                    .mul(platformSecondSalePercentages[tokenId])
                    .div(100);
            }

            safeFundsTransfer(platformAddress, platformAmount);
            // distribute the creator royalty amongst the creators (all artists involved for a base token, sole artist creator for layer )
            uint256 creatorAmount =
                saleAmount.mul(artistSecondSalePercentage).div(100);
            distributeFundsToCreators(
                creatorAmount,
                uniqueTokenCreators[tokenId]
            );
            // cast the owner to a payable address
            address payable payableOwner = address(uint160(ownerOf(tokenId)));
            // transfer the remaining amount to the owner of the token
            safeFundsTransfer(
                payableOwner,
                saleAmount.sub(platformAmount).sub(creatorAmount)
            );
        } else {
            tokenDidHaveFirstSale[tokenId] = true;

            // give platform its first sale percentage
            uint256 platformAmount;
            if (platformFirstSalePercentages[tokenId] == 0) {
                // default value
                platformAmount = saleAmount
                    .mul(defaultPlatformFirstSalePercentage)
                    .div(100);
            } else {
                platformAmount = saleAmount
                    .mul(platformFirstSalePercentages[tokenId])
                    .div(100);
            }

            safeFundsTransfer(platformAddress, platformAmount);
            // this is a token first sale, so distribute the remaining funds to the unique token creators of this token
            // (if it's a base token it will be all the unique creators, if it's a control token it will be that single artist)
            distributeFundsToCreators(
                saleAmount.sub(platformAmount),
                uniqueTokenCreators[tokenId]
            );
        }
        // clear highest bid
        pendingBids[tokenId] = PendingBid(address(0), 0, false);
        // Transfer token to msg.sender
        _transferFrom(ownerOf(tokenId), to, tokenId);
        // Emit event
        emit TokenSale(tokenId, saleAmount, to);
    }

    // Owner functions
    // Allow owner to accept the highest bid for a token
    function acceptBid(uint256 tokenId, uint256 minAcceptedAmount) external {
        // check if sender is owner/approved of token
        require(_isApprovedOrOwner(msg.sender, tokenId));
        // check if there's a bid to accept
        require(pendingBids[tokenId].exists);
        // check that the current pending bid amount is at least what the accepting owner expects
        require(pendingBids[tokenId].amount >= minAcceptedAmount);
        // process the sale
        onTokenSold(
            tokenId,
            pendingBids[tokenId].amount,
            pendingBids[tokenId].bidder
        );
    }

    // Allows owner of a control token to set an immediate buy price. Set to 0 to reset.
    function makeBuyPrice(uint256 tokenId, uint256 amount) external {
        // check if sender is owner/approved of token
        require(_isApprovedOrOwner(msg.sender, tokenId));
        // set the buy price
        buyPrices[tokenId] = amount;
        // emit event
        emit BuyPriceSet(tokenId, amount);
    }

    // return the number of times that a control token can be used
    function getNumRemainingControlUpdates(uint256 controlTokenId)
        external
        view
        returns (int256)
    {
        require(
            controlTokenMapping[controlTokenId].isSetup,
            "Token does not exist."
        );

        return controlTokenMapping[controlTokenId].numRemainingUpdates;
    }

    // return the min, max, and current value of a control lever
    function getControlToken(uint256 controlTokenId)
        external
        view
        returns (int256[] memory)
    {
        require(
            controlTokenMapping[controlTokenId].isSetup,
            "Token does not exist."
        );

        ControlToken storage controlToken = controlTokenMapping[controlTokenId];

        int256[] memory returnValues =
            new int256[](controlToken.numControlLevers.mul(3));
        uint256 returnValIndex = 0;

        // iterate through all the control levers for this control token
        for (uint256 i = 0; i < controlToken.numControlLevers; i++) {
            returnValues[returnValIndex] = controlToken.levers[i].minValue;
            returnValIndex = returnValIndex.add(1);

            returnValues[returnValIndex] = controlToken.levers[i].maxValue;
            returnValIndex = returnValIndex.add(1);

            returnValues[returnValIndex] = controlToken.levers[i].currentValue;
            returnValIndex = returnValIndex.add(1);
        }

        return returnValues;
    }

    // anyone can grant permission to another address to control a specific token on their behalf. Set to Address(0) to reset.
    function grantControlPermission(uint256 tokenId, address permissioned)
        external
    {
        permissionedControllers[msg.sender][tokenId] = permissioned;

        emit PermissionUpdated(tokenId, msg.sender, permissioned);
    }

    // Allows owner (or permissioned user) of a control token to update its lever values
    // Optionally accept a payment to increase speed of rendering priority
    function useControlToken(
        uint256 controlTokenId,
        uint256[] calldata leverIds,
        int256[] calldata newValues
    ) external payable {
        // check if sender is owner/approved of token OR if they're a permissioned controller for the token owner
        require(
            _isApprovedOrOwner(msg.sender, controlTokenId) ||
                (permissionedControllers[ownerOf(controlTokenId)][
                    controlTokenId
                ] == msg.sender),
            "Owner or permissioned only"
        );
        // check if control exists
        require(
            controlTokenMapping[controlTokenId].isSetup,
            "Token does not exist."
        );
        // get the control token reference
        ControlToken storage controlToken = controlTokenMapping[controlTokenId];
        // check that number of uses for control token is either infinite or is positive
        require(
            (controlToken.numRemainingUpdates == -1) ||
                (controlToken.numRemainingUpdates > 0),
            "No more updates allowed"
        );
        // collect the previous lever values for the event emit below
        int256[] memory previousValues = new int256[](newValues.length);

        for (uint256 i = 0; i < leverIds.length; i++) {
            // get the control lever
            ControlLever storage lever =
                controlTokenMapping[controlTokenId].levers[leverIds[i]];

            // Enforce that the new value is valid
            require(
                (newValues[i] >= lever.minValue) &&
                    (newValues[i] <= lever.maxValue),
                "Invalid val"
            );

            // Enforce that the new value is different
            require(
                newValues[i] != lever.currentValue,
                "Must provide different val"
            );

            // grab previous value for the event emit
            previousValues[i] = lever.currentValue;

            // Update token current value
            lever.currentValue = newValues[i];
        }

        // if there's a payment then send it to the platform (for higher priority updates)
        if (msg.value > 0) {
            safeFundsTransfer(platformAddress, msg.value);
        }

        // if this control token is finite in its uses
        if (controlToken.numRemainingUpdates > 0) {
            // decrease it down by 1
            controlToken.numRemainingUpdates =
                controlToken.numRemainingUpdates -
                1;

            // since we used one of those updates, withdraw any existing bid for this token if exists
            if (pendingBids[controlTokenId].exists) {
                _withdrawBid(controlTokenId);
            }
        }

        // emit event
        emit ControlLeverUpdated(
            controlTokenId,
            msg.value,
            controlToken.numRemainingUpdates,
            leverIds,
            previousValues,
            newValues
        );
    }

    // Allows a user to withdraw all failed transaction credits
    function withdrawAllFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0);
        require(address(this).balance >= amount);

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = msg.sender.call.value(amount)("");
        require(successfulWithdraw);
    }

    // Safely transfer funds and if fail then store that amount as credits for a later pull
    function safeFundsTransfer(address payable recipient, uint256 amount)
        internal
    {
        // attempt to send the funds to the recipient
        (bool success, ) = recipient.call.value(amount).gas(2300)("");
        // if it failed, update their credit balance so they can pull it later
        if (success == false) {
            failedTransferCredits[recipient] = failedTransferCredits[recipient]
                .add(amount);
        }
    }

    // override the default transfer
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // clear a buy now price
        buyPrices[tokenId] = 0;
        // transfer the token
        super._transferFrom(from, to, tokenId);
    }
}