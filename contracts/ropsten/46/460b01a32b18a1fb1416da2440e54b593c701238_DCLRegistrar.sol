/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-25
*/

/**
 *Submitted for verification at Etherscan.io on 2020-02-04
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
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public;

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public;
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4);
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
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
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
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

    constructor() internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
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
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
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
    mapping(uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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

    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            'ERC721: balance query for the zero address'
        );

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(
            owner != address(0),
            'ERC721: owner query for nonexistent token'
        );

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
        require(to != owner, 'ERC721: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721: approve caller is not owner nor approved for all'
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
        require(
            _exists(tokenId),
            'ERC721: approved query for nonexistent token'
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), 'ERC721: approve to caller');

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, '');
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );
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
    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            'ERC721: operator query for nonexistent token'
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        _safeMint(to, tokenId, '');
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(tokenId), 'ERC721: token already minted');

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
        require(
            ownerOf(tokenId) == owner,
            'ERC721: burn of token that is not own'
        );

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
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            'ERC721: transfer of token that is not own'
        );
        require(to != address(0), 'ERC721: transfer to the zero address');

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
     * This function is deprecated.
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
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval =
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            );
        return (retval == _ERC721_RECEIVED);
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.5.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol

pragma solidity ^0.5.0;

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
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
    constructor() public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            'ERC721Enumerable: owner index out of bounds'
        );
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
        require(
            index < totalSupply(),
            'ERC721Enumerable: global index out of bounds'
        );
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal {
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

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use {ERC721-_burn} instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner)
        internal
        view
        returns (uint256[] storage)
    {
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
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
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
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
    constructor(string memory name, string memory symbol) public {
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
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI query for nonexistent token'
        );
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(
            _exists(tokenId),
            'ERC721Metadata: URI set of nonexistent token'
        );
        _tokenURIs[tokenId] = uri;
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

// File: @openzeppelin/contracts/token/ERC721/ERC721Full.sol

pragma solidity ^0.5.0;

/**
 * @title Full ERC721 Token
 * @dev This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology.
 *
 * See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor(string memory name, string memory symbol)
        public
        ERC721Metadata(name, symbol)
    {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// File: contracts/interfaces/IENSRegistry.sol

pragma solidity ^0.5.15;

/**
 * @title EnsRegistry
 * @dev Extract of the interface for BNS Registry
 */
contract IENSRegistry {
    function setOwner(bytes32 node, address owner) public;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) public;

    function setResolver(bytes32 node, address resolver) public;

    function owner(bytes32 node) public view returns (address);

    function resolver(bytes32 node) public view returns (address);
}

// File: contracts/interfaces/IENSResolver.sol

pragma solidity ^0.5.15;

/**
 * @title EnsResolver
 * @dev Extract of the interface for BNS Resolver
 */
contract IENSResolver {
    /**
     * Sets the address associated with an BNS node.
     * May only be called by the owner of that node in the BNS registry.
     * @param node - The node to update.
     * @param addr - The address to set.
     */
    function setAddr(bytes32 node, address addr) public;

    /**
     * Returns the address associated with an BNS node.
     * @param node - The BNS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address);
}

// File: contracts/interfaces/IBaseRegistrar.sol

pragma solidity ^0.5.15;

contract IBaseRegistrar {
    /**
     * @dev Register a name.
     * @param id - node id to be registered.
     * @param owner - owner of the node.
     * @param duration - ttl.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256);

    /**
     * @dev Renew a name.
     * @param id - node id to be renewed.
     * @param duration - ttl
     */
    function renew(uint256 id, uint256 duration) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in BNS, if you own it in the registrar.
     * @param id - node id.
     * @param owner - owner of the node.
     */
    function reclaim(uint256 id, address owner) external;

    /**
     * @dev Transfer a name to a new owner.
     * @param from - current owner of the node.
     * @param to - new owner of the node.
     * @param id - node id.
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public;

    /**
     * @dev Gets the owner of the specified token ID
     * @param tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address);
}

// File: openzeppelin-eth/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/interfaces/IERC20Token.sol

pragma solidity ^0.5.15;

contract IERC20Token is IERC20 {
    function balanceOf(address from) public view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool);

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function burn(uint256 amount) public;
}

// File: contracts/bns/DCLRegistrar.sol

pragma solidity ^0.5.15;

contract DCLRegistrar is ERC721Full, Ownable {
    using Address for address;
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

    // The BNS registry
    IENSRegistry public registry;
    // The BNS base registrar
    IBaseRegistrar public base;

    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;

    // Empty hash
    bytes32 emptyNamehash = 0x00;
    // Top domain e.g: eth
    string public topdomain;
    // Domain e.g: dcl
    string public domain;
    // Top domain hash
    bytes32 public topdomainNameHash;
    // Domain hash
    bytes32 public domainNameHash;
    // Base URI
    string public baseURI;

    // Whether the migration of v1 names has finished or not
    bool public migrated;

    // A map of subdomain hashes to its string for reverse lookup
    mapping(bytes32 => string) public subdomains;

    // Emitted when a new name is registered
    event NameRegistered(
        address indexed _caller,
        address indexed _beneficiary,
        bytes32 indexed _labelHash,
        string _subdomain,
        uint256 _createdDate
    );
    // Emitted when a user reclaim a subdomain to the BNS Registry
    event Reclaimed(
        address indexed _caller,
        address indexed _owner,
        uint256 indexed _tokenId
    );
    // Emitted when the owner of the contract reclaim the domain to the BNS Registry
    event DomainReclaimed(uint256 indexed _tokenId);
    // Emitted when the domain was transferred
    event DomainTransferred(
        address indexed _newOwner,
        uint256 indexed _tokenId
    );

    // Emitted when the registry was updated
    event RegistryUpdated(
        IENSRegistry indexed _previousRegistry,
        IENSRegistry indexed _newRegistry
    );
    // Emitted when the base was updated
    event BaseUpdated(
        IBaseRegistrar indexed _previousBase,
        IBaseRegistrar indexed _newBase
    );

    // Emitted when a controller was added
    event ControllerAdded(address indexed _controller);
    // Emitted when a controller was removed
    event ControllerRemoved(address indexed _controller);

    // Emitted when the migration was finished
    event MigrationFinished();

    // Emitted when base URI is was changed
    event BaseURI(string _oldBaseURI, string _newBaseURI);

    // Emit when the resolver is set to the owned domain
    event ResolverUpdated(
        address indexed _oldResolver,
        address indexed _newResolver
    );

    // Emit when a call is forwarred to the resolver
    event CallForwarwedToResolver(
        address indexed _resolver,
        bytes _data,
        bytes res
    );

    /**
     * @dev Check if the sender is an authorized controller
     */
    modifier onlyController() {
        require(
            controllers[msg.sender],
            'Only a controller can call this method'
        );
        _;
    }

    /**
     * @dev Check if the migration is pending
     */
    modifier isNotMigrated() {
        require(!migrated, 'The migration has finished');
        _;
    }

    /**
     * @dev Check if the migration is completed
     */
    modifier isMigrated() {
        require(migrated, 'The migration has not finished');
        _;
    }

    /**
     * @dev Constructor of the contract
     * @param _registry - address of the BNS registry contract
     * @param _base - address of the BNS base registrar contract
     * @param _topdomain - top domain (e.g. "eth")
     * @param _domain - domain (e.g. "dcl")
     * @param _baseURI - base URI for token URIs
     */
    constructor(
        IENSRegistry _registry,
        IBaseRegistrar _base,
        string memory _topdomain,
        string memory _domain,
        string memory _baseURI
    ) public ERC721Full('DCL Registrar', 'DCLENS') {
        // BNS registry
        updateRegistry(_registry);
        // BNS base registrar
        updateBase(_base);

        // Top domain string
        require(bytes(_topdomain).length > 0, 'Top domain can not be empty');
        topdomain = _topdomain;

        // Domain string
        require(bytes(_domain).length > 0, 'Domain can not be empty');
        domain = _domain;

        // Generate namehash for the top domain
        topdomainNameHash = keccak256(
            abi.encodePacked(
                emptyNamehash,
                keccak256(abi.encodePacked(topdomain))
            )
        );
        // Generate namehash for the domain
        domainNameHash = keccak256(
            abi.encodePacked(
                topdomainNameHash,
                keccak256(abi.encodePacked(domain))
            )
        );

        // Set base URI
        updateBaseURI(_baseURI);
    }

    /**
     * @dev Migrate names from v1
     * @param _names - array of names
     * @param _beneficiaries - array of beneficiaries
     * @param _createdDates - array of created dates
     */
    function migrateNames(
        bytes32[] calldata _names,
        address[] calldata _beneficiaries,
        uint256[] calldata _createdDates
    ) external onlyOwner isNotMigrated {
        for (uint256 i = 0; i < _names.length; i++) {
            string memory name = _bytes32ToString(_names[i]);
            _register(
                name,
                keccak256(abi.encodePacked(_toLowerCase(name))),
                _beneficiaries[i],
                _createdDates[i]
            );
        }
    }

    /**
     * @dev Allows to create a subdomain (e.g. "nacho.dcl.eth"), set its resolver, owner and target address
     * @param _subdomain - subdomain  (e.g. "nacho")
     * @param _beneficiary - address that will become owner of this new subdomain
     */
    function register(string calldata _subdomain, address _beneficiary)
        external
        onlyController
        isMigrated
    {
        // Make sure this contract owns the domain
        _checkOwnerOfDomain();
        // Create labelhash for the subdomain
        bytes32 subdomainLabelHash =
            keccak256(abi.encodePacked(_toLowerCase(_subdomain)));
        // Make sure it is free
        require(_available(subdomainLabelHash), 'Subdomain already owned');
        // solium-disable-next-line security/no-block-members
        _register(_subdomain, subdomainLabelHash, _beneficiary, now);
    }

    /**
     * @dev Internal function to register a subdomain
     * @param _subdomain - subdomain  (e.g. "nacho")
     * @param subdomainLabelHash - hash of the subdomain
     * @param _beneficiary - address that will become owner of this new subdomain
     */
    function _register(
        string memory _subdomain,
        bytes32 subdomainLabelHash,
        address _beneficiary,
        uint256 _createdDate
    ) internal {
        // Create new subdomain and assign the _beneficiary as the owner
        registry.setSubnodeOwner(
            domainNameHash,
            subdomainLabelHash,
            _beneficiary
        );
        // Mint an ERC721 token with the sud domain label hash as its id
        _mint(_beneficiary, uint256(subdomainLabelHash));
        // Map the ERC721 token id with the subdomain for reversion.
        subdomains[subdomainLabelHash] = _subdomain;
        // Emit registered name event
        emit NameRegistered(
            msg.sender,
            _beneficiary,
            subdomainLabelHash,
            _subdomain,
            _createdDate
        );
    }

    /**
     * @dev Re-claim the ownership of a subdomain (e.g. "nacho").
     * @notice After a subdomain is transferred by this contract, the owner in the BNS registry contract
     * is still the old owner. Therefore, the owner should call `reclaim` to update the owner of the subdomain.
     * It is also useful to recreate the subdomains in case of an BNS migration.
     * @param _tokenId - erc721 token id which represents the node (subdomain).
     */
    function reclaim(uint256 _tokenId) public onlyController {
        address owner = ownerOf(_tokenId);

        registry.setSubnodeOwner(
            domainNameHash,
            bytes32(_tokenId),
            ownerOf(_tokenId)
        );

        emit Reclaimed(msg.sender, owner, _tokenId);
    }

    /**
     * @dev Re-claim the ownership of a subdomain (e.g. "nacho").
     * @notice After a subdomain is transferred by this contract, the owner in the BNS registry contract
     * is still the old owner. Therefore, the owner should call `reclaim` to update the owner of the subdomain.
     * It is also useful to recreate the subdomains in case of an BNS migration.
     * @param _tokenId - erc721 token id which represents the node (subdomain).
     * @param _owner - new owner.
     */
    function reclaim(uint256 _tokenId, address _owner) public {
        // Check if the sender is authorized to manage the subdomain
        require(
            _isApprovedOrOwner(msg.sender, _tokenId),
            'Only an authorized account can change the subdomain settings'
        );

        registry.setSubnodeOwner(domainNameHash, bytes32(_tokenId), _owner);

        emit Reclaimed(msg.sender, _owner, _tokenId);
    }

    /**
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safetransfer`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the contract address is always the message sender.
     * @notice Handle the receipt of an NFT. Used to re-claim ownership at the BNS registry contract
     * @param _tokenId The NFT identifier which is being transferred
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address, /* _operator */
        address, /* _from */
        uint256 _tokenId,
        bytes memory /* _data */
    ) public returns (bytes4) {
        require(
            msg.sender == address(base),
            'Only base can send NFTs to this contract'
        );

        // Re-claim to update the owner at the BNS Registry
        base.reclaim(_tokenId, address(this));
        return ERC721_RECEIVED;
    }

    /**
     * @dev Check whether a name is available to be registered or not
     * @param _subdomain - name to check
     * @return whether the name is available or not
     */
    function available(string memory _subdomain) public view returns (bool) {
        // Create labelhash for the subdomain
        bytes32 subdomainLabelHash =
            keccak256(abi.encodePacked(_toLowerCase(_subdomain)));
        return _available(subdomainLabelHash);
    }

    /**
     * @dev Check whether a name is available to be registered or not
     * @param _subdomainLabelHash - hash of the name to check
     * @return whether the name is available or not
     */
    function _available(bytes32 _subdomainLabelHash)
        internal
        view
        returns (bool)
    {
        // Create namehash for the subdomain (node)
        bytes32 subdomainNameHash =
            keccak256(abi.encodePacked(domainNameHash, _subdomainLabelHash));
        // Make sure it is free
        return
            registry.owner(subdomainNameHash) == address(0) &&
            !_exists(uint256(_subdomainLabelHash));
    }

    /**
     * @dev Get the token id by its subdomain
     * @param _subdomain - string of the subdomain
     * @return token id mapped to the subdomain
     */
    function getTokenId(string memory _subdomain)
        public
        view
        returns (uint256)
    {
        string memory subdomain = _toLowerCase(_subdomain);
        bytes32 subdomainLabelHash = keccak256(abi.encodePacked(subdomain));
        uint256 tokenId = uint256(subdomainLabelHash);

        require(_exists(tokenId), 'The subdomain is not registered');

        return tokenId;
    }

    /**
     * @dev Get the owner of a subdomain
     * @param _subdomain - string of the subdomain
     * @return owner of the subdomain
     */
    function getOwnerOf(string memory _subdomain)
        public
        view
        returns (address)
    {
        return ownerOf(getTokenId(_subdomain));
    }

    /**
     * @dev Returns an URI for a given token ID.
     * @notice that throws if the token ID does not exist. May return an empty string.
     * Also, if baseURI is empty, an empty string will be returned.
     * @param _tokenId - uint256 ID of the token queried
     * @return token URI
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        if (bytes(baseURI).length == 0) {
            return '';
        }

        require(
            _exists(_tokenId),
            'ERC721Metadata: received a URI query for a nonexistent token'
        );
        return
            string(
                abi.encodePacked(
                    baseURI,
                    _toLowerCase(subdomains[bytes32(_tokenId)])
                )
            );
    }

    /**
     * @dev Re-claim the ownership of the domain (e.g. "dcl")
     * @notice After a domain is transferred by the BNS base
     * registrar to this contract, the owner in the BNS registry contract
     * is still the old owner. Therefore, the owner should call `reclaimDomain`
     * to update the owner of the domain
     * @param _tokenId - erc721 token id which represents the node (domain)
     */
    function reclaimDomain(uint256 _tokenId) public onlyOwner {
        base.reclaim(_tokenId, address(this));

        emit DomainReclaimed(_tokenId);
    }

    /**
     * @dev The contract owner can take away the ownership of any domain owned by this contract
     * @param _owner - new owner for the domain
     * @param _tokenId - erc721 token id which represents the node (domain)
     */
    function transferDomainOwnership(address _owner, uint256 _tokenId)
        public
        onlyOwner
    {
        base.transferFrom(address(this), _owner, _tokenId);
        emit DomainTransferred(_owner, _tokenId);
    }

    /**
     * @dev Update owned domain resolver
     * @param _resolver - new resolver
     */
    function setResolver(address _resolver) public onlyOwner {
        address resolver = registry.resolver(domainNameHash);

        require(_resolver.isContract(), 'New resolver should be a contract');
        require(
            _resolver != resolver,
            'New resolver should be different from old'
        );

        _checkNotAllowedAddresses(_resolver);

        registry.setResolver(domainNameHash, _resolver);

        emit ResolverUpdated(resolver, _resolver);
    }

    /**
     * @dev Forward calls to resolver
     * @param _data - data to be send in the call
     */
    function forwardToResolver(bytes memory _data) public onlyOwner {
        address resolver = registry.resolver(domainNameHash);

        _checkNotAllowedAddresses(resolver);

        (bool success, bytes memory res) = resolver.call(_data);

        require(success, 'Call failed');

        // Make sure this contract is still the owner of the domain
        _checkOwnerOfDomain();

        emit CallForwarwedToResolver(resolver, _data, res);
    }

    /**
     * @dev Authorises a controller, who can register subdomains
     * @param controller - address of the controller
     */
    function addController(address controller) external onlyOwner {
        require(!controllers[controller], 'The controller was already added');
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    /**
     * @dev Revoke controller permission for an address
     * @param controller - address of the controller
     */
    function removeController(address controller) external onlyOwner {
        require(controllers[controller], 'The controller is already disabled');
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    /**
     * @dev Update to new BNS registry
     * @param _registry The address of new BNS registry to use
     */
    function updateRegistry(IENSRegistry _registry) public onlyOwner {
        require(
            registry != _registry,
            'New registry should be different from old'
        );
        require(
            address(_registry).isContract(),
            'New registry should be a contract'
        );

        emit RegistryUpdated(registry, _registry);

        registry = _registry;
    }

    /**
     * @dev Update to new BNS base registrar
     * @param _base The address of new BNS base registrar to use
     */
    function updateBase(IBaseRegistrar _base) public onlyOwner {
        require(base != _base, 'New base should be different from old');
        require(address(_base).isContract(), 'New base should be a contract');

        emit BaseUpdated(base, _base);

        base = _base;
    }

    /**
     * @dev Set Base URI.
     * @param _baseURI - base URI for token URIs
     */
    function updateBaseURI(string memory _baseURI) public onlyOwner {
        require(
            keccak256(abi.encodePacked((baseURI))) !=
                keccak256(abi.encodePacked((_baseURI))),
            'Base URI should be different from old'
        );
        emit BaseURI(baseURI, _baseURI);
        baseURI = _baseURI;
    }

    /**
     * @dev Set the migration as finished
     */
    function migrationFinished() external onlyOwner isNotMigrated {
        migrated = true;
        emit MigrationFinished();
    }

    function _checkOwnerOfDomain() internal view {
        require(
            registry.owner(domainNameHash) == address(this) &&
                base.ownerOf(uint256(keccak256(abi.encodePacked(domain)))) ==
                address(this),
            'The contract does not own the domain'
        );
    }

    function _checkNotAllowedAddresses(address _address) internal view {
        require(
            _address != address(base) &&
                _address != address(registry) &&
                _address != address(this),
            'Invalid address'
        );
    }

    /**
     * @dev Convert bytes32 to string.
     * @param _x - to be converted to string.
     * @return string
     */
    function _bytes32ToString(bytes32 _x)
        internal
        pure
        returns (string memory)
    {
        uint256 charCount = 0;
        for (uint256 j = 0; j <= 256; j += 8) {
            bytes1 char = bytes1(_x << j);
            if (char == 0) {
                break;
            }
            charCount++;
        }

        string memory out = new string(charCount);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(0x20, out), _x)
        }

        return out;
    }

    /**
     * @dev Lowercase a string.
     * @param _str - to be converted to string.
     * @return string
     */
    function _toLowerCase(string memory _str)
        internal
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 0x20 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 0x20);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}