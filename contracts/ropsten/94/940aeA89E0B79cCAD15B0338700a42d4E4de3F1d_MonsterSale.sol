/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`&#39;s account.
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
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

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
     * after a `safeTransfer`. This function MUST return the function selector,
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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract&#39;s constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
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
}

// File: openzeppelin-solidity/contracts/drafts/Counters.sol

pragma solidity ^0.5.0;


/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library&#39;s function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
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

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;


/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;)) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it&#39;s supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See `IERC165.supportsInterface`.
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
     * See `IERC165.supportsInterface`.
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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.5.0;







/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is ERC165, IERC721 {
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
     *     bytes4(keccak256(&#39;balanceOf(address)&#39;)) == 0x70a08231
     *     bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) == 0x6352211e
     *     bytes4(keccak256(&#39;approve(address,uint256)&#39;)) == 0x095ea7b3
     *     bytes4(keccak256(&#39;getApproved(uint256)&#39;)) == 0x081812fc
     *     bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) == 0xa22cb465
     *     bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) == 0xe985e9c
     *     bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) == 0x23b872dd
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) == 0x42842e0e
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;)) == 0xb88d4fde
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

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
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
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
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
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
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
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
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
     * Deprecated, use _burn(uint256) instead.
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
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
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
     * @dev Internal function to invoke `onERC721Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
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

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
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

// File: openzeppelin-solidity/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account&#39;s access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.0;


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Pausable.sol

pragma solidity ^0.5.0;



/**
 * @title ERC721 Non-Fungible Pausable token
 * @dev ERC721 modified with pausable transfers.
 */
contract ERC721Pausable is ERC721, Pausable {
    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol

pragma solidity ^0.5.0;




/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256(&#39;totalSupply()&#39;)) == 0x18160ddd
     *     bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) == 0x2f745c59
     *     bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;)) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
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

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
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
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension&#39;s ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension&#39;s token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension&#39;s ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from&#39;s tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token&#39;s index
        }

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn&#39;t been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension&#39;s token tracking data structures.
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
        // an &#39;if&#39; statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token&#39;s index

        // This also deletes the contents at the last position of the array
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Metadata.sol

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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Metadata.sol

pragma solidity ^0.5.0;




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256(&#39;name()&#39;)) == 0x06fdde03
     *     bytes4(keccak256(&#39;symbol()&#39;)) == 0x95d89b41
     *     bytes4(keccak256(&#39;tokenURI(uint256)&#39;)) == 0xc87b56dd
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

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol

pragma solidity ^0.5.0;




/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: openzeppelin-solidity/contracts/token/ERC721/ERC721Mintable.sol

pragma solidity ^0.5.0;



/**
 * @title ERC721Mintable
 * @dev ERC721 minting logic.
 */
contract ERC721Mintable is ERC721, MinterRole {
    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}

// File: contracts/MonsterAsset.sol

pragma solidity ^0.5.2;




contract MonsterAsset is ERC721Pausable, ERC721Full, ERC721Mintable{

    uint32 public constant MONSTER_INSTANCE_ID_OFFSET = 10000000;

    // todo URI螟画峩
    string private tokenURIPrefix = "http://52.197.73.0:12929/api/v1/metadata/monster/";
    string private tokenURISuffix;

    // Mapping of monsterId and the number of monster tokens that can be generated
    mapping(uint32 => uint32) private supplyLimitForEachMonsterId;

    constructor() public ERC721Full("MonsterAsset", "WBM") {}

    // An error is returned if the specified monster token ID does not exist
    modifier mustBeValidToken(uint256 _tokenId) {
        require(_exists(_tokenId), "tokenId does not exists");
        _;
    }

    function mintMonster(address _add, uint256 _tokenId) external onlyMinter {
        uint32 _monsterId = uint32(_tokenId / MONSTER_INSTANCE_ID_OFFSET);
        uint32 _monsterIdIndex = uint32(_tokenId % MONSTER_INSTANCE_ID_OFFSET) - 1;
        require(_monsterIdIndex < supplyLimitForEachMonsterId[_monsterId], "supply over");
        mint(_add, _tokenId);
    }

    function setMonsterAssetURIAffixes(string calldata _prefix, string calldata _suffix) external onlyMinter {
        tokenURIPrefix = _prefix;
        tokenURISuffix = _suffix;
    }

    function tokenURI(uint256 _tokenId) external view mustBeValidToken(_tokenId) returns (string memory) {
        bytes memory _tokenURIPrefixBytes = bytes(tokenURIPrefix);
        bytes memory _tokenURISuffixBytes = bytes(tokenURISuffix);
        uint256 _tmpTokenId = _tokenId;
        uint256 _length;
        do {
            _length++;
            _tmpTokenId /= 10;
        } while (_tmpTokenId > 0);
        bytes memory _tokenURIBytes = new bytes(_tokenURIPrefixBytes.length + _length + _tokenURISuffixBytes.length);
        uint256 _i = _tokenURIBytes.length - _tokenURISuffixBytes.length - 1;
        _tmpTokenId = _tokenId;
        do {
            uint tmpIdAscii = 48 + _tmpTokenId % 10;
            bytes memory tmpIdOfOne = new bytes(32);
            assembly { mstore(add(tmpIdOfOne, 32), tmpIdAscii) }
            _tokenURIBytes[_i--] = tmpIdOfOne[tmpIdOfOne.length - 1];
            _tmpTokenId /= 10;
        } while (_tmpTokenId > 0);
        for (_i = 0; _i < _tokenURIPrefixBytes.length; _i++) {
            _tokenURIBytes[_i] = _tokenURIPrefixBytes[_i];
        }
        for (_i = 0; _i < _tokenURISuffixBytes.length; _i++) {
            _tokenURIBytes[_tokenURIBytes.length + _i - _tokenURISuffixBytes.length] = _tokenURISuffixBytes[_i];
        }
        return string(_tokenURIBytes);
    }

    function setSupplyLimit(uint32 _monsterId, uint32 _supplyLimit) external onlyMinter {
        // 荳�蠎ｦ險ｭ縺代◆蛻ｶ髯舌ｒ雜��∴繧句�､繧定ｨｭ螳壹＠繧医≧縺ｨ縺励◆蝣ｴ蜷医��繧ｨ繝ｩ繝ｼ
        require(
            supplyLimitForEachMonsterId[_monsterId] == 0 || _supplyLimit < supplyLimitForEachMonsterId[_monsterId],
            "_supplyLimit is bigger"
        );
        supplyLimitForEachMonsterId[_monsterId] = _supplyLimit;
    }

    function getSupplyLimit(uint32 _monsterId) public view returns (uint32) {
        return supplyLimitForEachMonsterId[_monsterId];
    }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
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

// File: contracts/ReferrerRole.sol

pragma solidity ^0.5.2;



/**
 * 繝ｪ繝輔ぃ繝ｩ繝ｼ繝ｻ蝣ｱ驟ｬ邇��ｒ邂｡逅��☆繧九Ο繝ｼ繝ｫ繧ｳ繝ｳ繝医Λ繧ｯ繝�
 */
contract ReferrerRole is Ownable {
    //菴ｿ逕ｨ縺吶ｋ繝ｭ繝ｼ繝ｫ繝ｩ繧､繝悶Λ繝ｪ縺ｮ螳夂ｾｩ
    using Roles for Roles.Role;
    //霑ｽ蜉�譎ゅ��繧､繝吶Φ繝�
    event ReferrerAdded(address indexed account,uint8 rate);
    //蜑企勁譎ゅ��繧､繝吶Φ繝�
    event ReferrerRemoved(address indexed account);
    //邂｡逅��畑繝ｭ繝ｼ繝ｫ
    Roles.Role private referrers;
    //蟇ｾ雎｡縺ｮ蝣ｱ驟ｬ邇�
    mapping(address => uint8) private rates;
    //蝗ｺ螳壼�ｱ驟ｬ邇�
    uint8 private defaultRate = 20;

    /**
    * 繧ｳ繝ｳ繧ｹ繝医Λ繧ｯ繧ｿ
    */
    constructor() public {
        referrers.add(msg.sender);
    }

    /**
    * 繝ｪ繝輔ぃ繝ｩ繝ｼ蟄伜惠繝√ぉ繝��け縺ｮ菫ｮ鬟ｾ蟄�
    */
    modifier onlyReferrer() {
        require(isReferrer(msg.sender));
        _;
    }

    /**
    * 繝ｪ繝輔ぃ繝ｩ繝ｼ蟄伜惠繝√ぉ繝��け
    * @param _account 繧｢繧ｫ繧ｦ繝ｳ繝医い繝峨Ξ繧ｹ
    * @return true/false
    */
    function isReferrer(address _account) public view returns (bool) {
        return referrers.has(_account);
    }

    /**
    * 繝ｪ繝輔ぃ繝ｩ繝ｼ繝ｻ蝣ｱ驟ｬ邇��ｒ霑ｽ蜉�縺励∪縺吶��
    * @param _account 繧｢繧ｫ繧ｦ繝ｳ繝医い繝峨Ξ繧ｹ
    * @param _newEthBackRate 蝣ｱ驟ｬ邇�
    */
    function addReferrer(address _account, uint8 _newEthBackRate) public onlyOwner() {
        referrers.add(_account);
        rates[_account] = _newEthBackRate;
        emit ReferrerAdded(_account,_newEthBackRate);
    }

    /**
    * 繝ｪ繝輔ぃ繝ｩ繝ｼ繝ｻ蝗ｺ螳壼�ｱ驟ｬ縺ｧ霑ｽ蜉�縺励∪縺吶��
    * @param _account 繧｢繧ｫ繧ｦ繝ｳ繝医い繝峨Ξ繧ｹ
    */
    function addReferrerDefaultRate(address _account) public {
        referrers.add(_account);
        rates[_account] = defaultRate;
        emit ReferrerAdded(_account,defaultRate);
    }

    /**
    * 蝗ｺ螳壼�ｱ驟ｬ邇��ｒ螟画峩縺励∪縺吶��
    * @param _newDefaultRate 螟画峩蝣ｱ驟ｬ邇�
    */
    function changeEthDefaultBackRate(uint8 _newDefaultRate) external onlyOwner() {
        defaultRate = _newDefaultRate;
    }
    /**
    * 蝣ｱ驟ｬ邇��ｒ螟画峩縺励∪縺吶��
    * @param _account 繧｢繧ｫ繧ｦ繝ｳ繝医い繝峨Ξ繧ｹ
    * @param _newEthBackRate 蝣ｱ驟ｬ邇�
    */
    function changeEthBackRate(address _account, uint8 _newEthBackRate) external onlyOwner() {
        require(isReferrer(_account));
        require(_newEthBackRate != 0);
        rates[_account] = _newEthBackRate;
    }

    /**
    * 蝣ｱ驟ｬ邇��ｒ霑斐＠縺ｾ縺吶��
    * @param _account 繧｢繧ｫ繧ｦ繝ｳ繝医い繝峨Ξ繧ｹ
    */
    function getReferrerRates(address _account) public view returns(uint256){
        return rates[_account];
    }

    /**
    * 繝ｪ繝輔ぃ繝ｩ繝ｼ繧貞炎髯､縺励∪縺吶��
    * @param  _account 繧｢繧ｫ繧ｦ繝ｳ繝医い繝峨Ξ繧ｹ
    */
    function removeReferrer(address _account) public onlyOwner() {
        referrers.remove(_account);
        rates[_account] = 0;
        emit ReferrerRemoved(_account);
    }
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: contracts/MonsterSale.sol

pragma solidity ^0.5.2;







/**
* 繝｢繝ｳ繧ｹ繧ｿ繝ｼ繝励Μ繧ｻ繝ｼ繝ｫ縺ｮ繧ｳ繝ｳ繝医Λ繧ｯ繝医〒縺吶��
*/
contract MonsterSale is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;
    // Maximum number of monsters that can be generated
    uint32 constant internal SUPPLY_LIMIT_MAX = 10000000;

    struct MonsterSaleStruct {
        uint256 startPrice;
        uint256 highestPrice;
        uint256 previousPrice;
        uint256 priceIncreaseTo;
        uint256 lowestPrice;
        uint256 becomeLowestAt;
        uint64  since;
        uint64  until;
        uint64  previousSaleAt;
        uint16  lowestPriceRate;
        uint16  decreaseRate;
        uint32  supplyLimit;
        uint32  suppliedCounts;
        uint8   currency;
        bool    exists;
    }

    // Mapping of monsterId and sales item information
    mapping(uint32 => MonsterSaleStruct) private monsterIdToMonsterSales;
    mapping(uint32 => uint256[]) public monsterTokenIds;
    mapping(uint32 => mapping(address => bool)) public hasAirDropMonster;

    MonsterAsset public monsterAsset;
    ReferrerRole public referrerRole;

    event AddSalesEvent(
        uint32 indexed monsterId,
        uint256 startPrice,
        uint256 lowestPrice,
        uint256 becomeLowestAt
    );

    event SoldMonsterEvent(
        uint32 indexed monsterId,
        uint256 indexed tokenId,
        uint256 soldPrice,
        uint256 priceIncreaseTo,
        uint256 lowestPrice,
        uint256 becomeLowestAt,
        address purchasedBy,
        uint64  paymentId,
        uint8 currency,
        address indexed referrer,
        uint64 soldAt,
        uint256 transferEth
    );

    constructor() public {}

    function setMonsterAssetAddress(address _monsterAssetAddress) external onlyOwner() {
        monsterAsset = MonsterAsset(_monsterAssetAddress);
    }

    function setReferrerAddress(address _referrerRoleAddress) external onlyOwner {
        referrerRole = ReferrerRole(_referrerRoleAddress);
    }

    function withdrawEther() external onlyOwner() {
        msg.sender.transfer(address(this).balance);
    }

    function addSales(
        uint32 _monsterId,
        uint256 _startPrice,
        uint16 _lowestPriceRate,
        uint16 _decreaseRate,
        uint64 _since,
        uint64 _until,
        uint32 _supplyLimit,
        uint8 _currency
    ) external onlyOwner() {
        require(!monsterIdToMonsterSales[_monsterId].exists, "this monsterId is already added sales");
        require(0 <= _lowestPriceRate && _lowestPriceRate <= 100, "lowestPriceRate should be between 0 and 100");
        require(1 <= _decreaseRate && _decreaseRate <= 100, "decreaseRate should be should be between 1 and 100");
        require(_until > _since, "until should be later than since");

        //譛�菴惹ｾ｡譬ｼ��� (髢句ｧ倶ｾ｡譬ｼ * 譛�菴惹ｾ｡譬ｼ繝ｬ繝ｼ繝�) / 100
        uint256 _lowestPrice = uint256(_startPrice).mul(_lowestPriceRate).div(100);
        //譛�菴惹ｾ｡譬ｼ蛻ｰ驕疲律譎ゑｼ� 86400(1譌･) * ((100 - 譛�菴惹ｾ｡譬ｼ繝ｬ繝ｼ繝�) / 萓｡譬ｼ貂帛ｰ代Ξ繝ｼ繝�) + 雋ｩ螢ｲ髢句ｧ区律
        uint256 _becomeLowestAt = uint256(86400).mul(uint256(100).sub(_lowestPriceRate)).div(_decreaseRate).add(_since);

        MonsterSaleStruct memory _monsterSale = MonsterSaleStruct({
            startPrice: _startPrice,
            highestPrice: _startPrice,
            previousPrice: _startPrice,
            priceIncreaseTo: _startPrice,
            lowestPrice:_lowestPrice,
            becomeLowestAt:_becomeLowestAt,
            since: _since,
            until: _until,
            previousSaleAt: _since,
            lowestPriceRate: _lowestPriceRate,
            decreaseRate: _decreaseRate,
            supplyLimit: _supplyLimit,
            suppliedCounts: 0,
            currency: _currency,
            exists: true
        });

        monsterIdToMonsterSales[_monsterId] = _monsterSale;
        monsterAsset.setSupplyLimit(_monsterId, _supplyLimit);

        emit AddSalesEvent(
            _monsterId,
            _startPrice,
            _lowestPrice,
            _becomeLowestAt
        );
    }

    function buyMonsters(
        uint32 _monsterId,
        uint64 _paymentId,
        address payable _referrer
    ) external whenNotPaused() nonReentrant() payable {
        return buyMonstersImpl(_monsterId, uint64(block.timestamp), _paymentId, _referrer);
    }

    function computeCurrentPrice(uint32 _monsterId) external view returns (uint8, uint256) {
        // solium-disable-next-line security/no-block-members
        return computeCurrentPriceImpl(_monsterId, uint64(block.timestamp));
    }

    function computeCurrentPriceImpl(uint32 _monsterId, uint64 _at) internal view returns (uint8, uint256) {
        MonsterSaleStruct storage monsterSale = monsterIdToMonsterSales[_monsterId];
        require(monsterSale.exists, "not exist sales of this monsterId");
        require(monsterSale.previousSaleAt <= _at, "current timestamp should not be faster than previousSaleAt");

        uint256 _lowestPrice = uint256(monsterSale.highestPrice).mul(monsterSale.lowestPriceRate).div(100);
        uint256 _secondsPassed = uint256(_at).sub(monsterSale.previousSaleAt);
        uint256 _decreasedPrice = uint256(monsterSale.priceIncreaseTo).mul(_secondsPassed).mul(monsterSale.decreaseRate).div(100).div(86400);
        uint256 currentPrice;
        if (uint256(monsterSale.priceIncreaseTo).sub(_lowestPrice) > _decreasedPrice){
            currentPrice = uint256(monsterSale.priceIncreaseTo).sub(_decreasedPrice);
        } else {
            currentPrice = _lowestPrice;
        }
        return (1, currentPrice);
    }

    function buyMonstersImpl(
        uint32 _monsterId,
        uint64 _at,
        uint64 _paymentId,
        address payable _referrer
    ) internal {
        MonsterSaleStruct storage monsterSale = monsterIdToMonsterSales[_monsterId];
        require(canBePurchasedByETH(_monsterId), "currency is not 0 (eth)");
        require(isOnSale(_monsterId, _at), "out of sales period");
        (, uint256 _price) = computeCurrentPriceImpl(_monsterId, _at);
        require(msg.value >= _price, "value is less than the price");
        require(monsterIdToMonsterSales[_monsterId].exists, "not exist sales of this monsterId");
        require(monsterTokenIds[_monsterId].length < monsterIdToMonsterSales[_monsterId].supplyLimit, "supply limit overed");

        uint256 tokenId = uint256(_monsterId).mul(SUPPLY_LIMIT_MAX).add(monsterTokenIds[_monsterId].length).add(1);
        monsterTokenIds[_monsterId].push(tokenId);
        monsterAsset.mintMonster(msg.sender, tokenId);

        if (msg.value > _price){
            msg.sender.transfer(msg.value.sub(_price));
        }

        address payable referrer;
        if (_referrer == msg.sender){
            referrer = address(0x0);
        } else {
            referrer = _referrer;
        }

        uint256 transferEth = 0;
        if ((referrer != address(0x0)) && referrerRole.isReferrer(referrer)) {
            transferEth = _price.mul(referrerRole.getReferrerRates(referrer)).div(100);
            referrer.transfer(transferEth);
        }
        monsterSale.previousPrice = uint256(_price);
        monsterSale.suppliedCounts++;
        monsterSale.previousSaleAt = _at;
        if (monsterSale.previousPrice > monsterSale.highestPrice){
            monsterSale.highestPrice = monsterSale.previousPrice;
        }

        if (monsterSale.supplyLimit > monsterSale.suppliedCounts){
            monsterSale.priceIncreaseTo = SafeMath.add(_price, _price.div((uint256(monsterSale.supplyLimit).sub(monsterSale.suppliedCounts))));
            monsterSale.lowestPrice = uint256(monsterSale.lowestPriceRate).mul(monsterSale.highestPrice).div(100);
            monsterSale.becomeLowestAt = uint256(86400).mul(100).mul((monsterSale.priceIncreaseTo.sub(monsterSale.lowestPrice))).div(monsterSale.priceIncreaseTo).div(monsterSale.decreaseRate).add(_at);
        } else {
            monsterSale.priceIncreaseTo = monsterSale.previousPrice;
            monsterSale.lowestPrice = monsterSale.previousPrice;
            monsterSale.becomeLowestAt = _at;
        }

        emit SoldMonsterEvent(
            _monsterId,
            tokenId,
            _price,
            monsterSale.priceIncreaseTo,
            monsterSale.lowestPrice,
            monsterSale.becomeLowestAt,
            msg.sender,
            _paymentId,
            0,
            referrer,
            uint64(block.timestamp),
            transferEth
        );
    }

    function airDrop(
        uint32 _monsterId,
        uint64 _paymentId
    ) external whenNotPaused() {
        MonsterSaleStruct storage monsterSale = monsterIdToMonsterSales[_monsterId];
        require(airDropMonster(_monsterId), "currency is not 1 (airdrop)");
        require(!hasAirDropMonster[_monsterId][msg.sender], "already have");
        uint64 _at = uint64(block.timestamp);
        require(isOnSale(_monsterId, _at), "out of sales period");

        require(monsterIdToMonsterSales[_monsterId].exists, "not exist sales of this monsterId");
        require(monsterTokenIds[_monsterId].length < monsterIdToMonsterSales[_monsterId].supplyLimit, "supply limit overed");

        uint256 tokenId = uint256(_monsterId).mul(SUPPLY_LIMIT_MAX).add(monsterTokenIds[_monsterId].length).add(1);
        monsterTokenIds[_monsterId].push(tokenId);
        monsterAsset.mintMonster(msg.sender, tokenId);
        hasAirDropMonster[_monsterId][msg.sender] = true;
        monsterSale.suppliedCounts++;
        monsterSale.previousSaleAt = _at;

        emit SoldMonsterEvent(
            _monsterId,
            tokenId,
            1,
            1,
            1,
            1,
            msg.sender,
            _paymentId,
            1,
            address(0x0),
            uint64(block.timestamp),
            0
        );
    }

    function canBePurchasedByETH(uint32 _monsterId) internal view returns (bool){
        return (monsterIdToMonsterSales[_monsterId].currency == 0);
    }

    function airDropMonster(uint32 _monsterId) internal view returns (bool){
        return (monsterIdToMonsterSales[_monsterId].currency == 1);
    }

    function isOnSale(uint32 _monsterId, uint64 _now) internal view returns (bool) {
        MonsterSaleStruct storage monsterSale = monsterIdToMonsterSales[_monsterId];
        require(monsterSale.exists, "isOnSale not exist sales of this monsterId");
        if (monsterSale.since <= _now && _now <= monsterSale.until) {
            return true;
        } else {
            return false;
        }
    }

    function getRemainingCount(uint32 _monsterId) external view returns (uint8, uint256) {
        return getRemainingCountImpl(_monsterId);
    }

    function getRemainingCountImpl(uint32 _monsterId) internal view returns (uint8, uint256) {
        MonsterSaleStruct storage monsterSale = monsterIdToMonsterSales[_monsterId];
        require(monsterSale.exists, "not exist sales of this monsterId");

        uint256 remaingCount = uint256(monsterSale.supplyLimit).sub(uint256(monsterSale.suppliedCounts));
        return (1, remaingCount);
    }
}