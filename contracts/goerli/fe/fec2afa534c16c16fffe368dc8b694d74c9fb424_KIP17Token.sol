/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.5.0;

// File: contracts/introspection/IKIP13.sol
/**
 * @dev Interface of the KIP-13 standard, as defined in the
 * [KIP-13](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others.
 *
 * For an implementation, see `KIP13`.
 */
interface IKIP13 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [KIP-13 section](http://kips.klaytn.com/KIPs/kip-13-interface_query_standard#how-interface-identifiers-are-defined)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: contracts/token/KIP17/IKIP17.sol
/**
 * @dev Required interface of an KIP17 compliant contract.
 */
contract IKIP17 is IKIP13 {
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
// File: contracts/token/KIP17/IERC721Receiver.sol
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
// File: contracts/token/KIP17/IKIP17Receiver.sol
/**
 * @title KIP17 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from KIP17 asset contracts.
 * @dev see http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The KIP17 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onKIP17Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the KIP17 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`
     */
    function onKIP17Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}
// File: contracts/math/SafeMath.sol
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
// File: contracts/utils/Address.sol
/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
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
// File: contracts/drafts/Counters.sol
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
// File: contracts/introspection/KIP13.sol
/**
 * @dev Implementation of the `IKIP13` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
contract KIP13 is IKIP13 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_KIP13 = 0x01ffc9a7;
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for KIP13 itself here
        _registerInterface(_INTERFACE_ID_KIP13);
    }
    /**
     * @dev See `IKIP13.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }
    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual KIP13 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IKIP13.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the KIP13 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "KIP13: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}
// File: contracts/token/KIP17/KIP17.sol
/**
 * @title KIP17 Non-Fungible Token Standard basic implementation
 * @dev see http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17 is KIP13, IKIP17 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;
    // Equals to `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IKIP17Receiver(0).onKIP17Received.selector`
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;
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
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_KIP17 = 0x80ac58cd;
    constructor () public {
        // register the supported interfaces to conform to KIP17 via KIP13
        _registerInterface(_INTERFACE_ID_KIP17);
    }
    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "KIP17: balance query for the zero address");
        return _ownedTokensCount[owner].current();
    }
    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "KIP17: owner query for nonexistent token");
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
        require(to != owner, "KIP17: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "KIP17: approve caller is not owner nor approved for all"
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
        require(_exists(tokenId), "KIP17: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "KIP17: approve to caller");
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
        require(_isApprovedOrOwner(msg.sender, tokenId), "KIP17: transfer caller is not owner nor approved");
        _transferFrom(from, to, tokenId);
    }
    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onKIP17Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`; otherwise,
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
     * If the target address is a contract, it must implement `onKIP17Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onKIP17Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnKIP17Received(from, to, tokenId, _data), "KIP17: transfer to non KIP17Receiver implementer");
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
        require(_exists(tokenId), "KIP17: operator query for nonexistent token");
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
        require(to != address(0), "KIP17: mint to the zero address");
        require(!_exists(tokenId), "KIP17: token already minted");
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
        require(ownerOf(tokenId) == owner, "KIP17: burn of token that is not own");
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
        require(ownerOf(tokenId) == from, "KIP17: transfer of token that is not own");
        require(to != address(0), "KIP17: transfer to the zero address");
        _clearApproval(tokenId);
        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    /**
     * @dev Internal function to invoke `onKIP17Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnKIP17Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        bool success; 
        bytes memory returndata;
        if (!to.isContract()) {
            return true;
        }
        // Logic for compatibility with ERC721.
        (success, returndata) = to.call(
            abi.encodeWithSelector(_ERC721_RECEIVED, msg.sender, from, tokenId, _data)
        );
        if (returndata.length != 0 && abi.decode(returndata, (bytes4)) == _ERC721_RECEIVED) {
            return true;
        }
        (success, returndata) = to.call(
            abi.encodeWithSelector(_KIP17_RECEIVED, msg.sender, from, tokenId, _data)
        );
        if (returndata.length != 0 && abi.decode(returndata, (bytes4)) == _KIP17_RECEIVED) {
            return true;
        }
        return false;
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
// File: contracts/token/KIP17/IKIP17Enumerable.sol
/**
 * @title KIP-17 Non-Fungible Token Standard, optional enumeration extension
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Enumerable is IKIP17 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}
// File: contracts/token/KIP17/KIP17Enumerable.sol
/**
 * @title KIP-17 Non-Fungible Token with optional enumeration extension logic
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17Enumerable is KIP13, KIP17, IKIP17Enumerable {
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
    bytes4 private constant _INTERFACE_ID_KIP17_ENUMERABLE = 0x780e9d63;
    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Enumerable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_ENUMERABLE);
    }
    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "KIP17Enumerable: owner index out of bounds");
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
        require(index < totalSupply(), "KIP17Enumerable: global index out of bounds");
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
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
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
// File: contracts/token/KIP17/IKIP17Metadata.sol
/**
 * @title KIP-17 Non-Fungible Token Standard, optional metadata extension
 * @dev See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract IKIP17Metadata is IKIP17 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: contracts/token/KIP17/KIP17Metadata.sol
contract KIP17Metadata is KIP13, KIP17, IKIP17Metadata {
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
    bytes4 private constant _INTERFACE_ID_KIP17_METADATA = 0x5b5e139f;
    /**
     * @dev Constructor function
     */
    constructor () public {
        // register the supported interfaces to conform to KIP17 via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_METADATA);
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
        require(_exists(tokenId), "KIP17Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }
    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "KIP17Metadata: URI set of nonexistent token");
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

    function _setMetadata(string memory name, string memory symbol) internal {
        _name = name;
        _symbol = symbol;
    }
}

// File: contracts/access/Roles.sol
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
     * @dev Remove an account's access to this role.
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
// File: contracts/access/roles/MinterRole.sol
contract MinterRole {
    using Roles for Roles.Role;
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    Roles.Role private _minters;

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
// File: contracts/token/KIP17/KIP17MetadataMintable.sol
/**
 * @title KIP17MetadataMintable
 * @dev KIP17 minting logic with metadata.
 */
contract KIP17MetadataMintable is KIP13, KIP17, KIP17Metadata, MinterRole {
    /*
     *     bytes4(keccak256('mintWithTokenURI(address,uint256,string)')) == 0x50bb4e7f
     *     bytes4(keccak256('isMinter(address)')) == 0xaa271e1a
     *     bytes4(keccak256('addMinter(address)')) == 0x983b2d56
     *     bytes4(keccak256('renounceMinter()')) == 0x98650275
     *
     *     => 0x50bb4e7f ^ 0xaa271e1a ^ 0x983b2d56 ^ 0x98650275 == 0xfac27f46
     */
    bytes4 private constant _INTERFACE_ID_KIP17_METADATA_MINTABLE = 0xfac27f46;
    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Mintable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_METADATA_MINTABLE);
    }
    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @param tokenURI The token URI of the minted token.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return true;
    }
}
// File: contracts/token/KIP17/KIP17Mintable.sol
/**
 * @title KIP17Mintable
 * @dev KIP17 minting logic.
 */
contract KIP17Mintable is KIP17, MinterRole {
    /*
     *     bytes4(keccak256('isMinter(address)')) == 0xaa271e1a
     *     bytes4(keccak256('addMinter(address)')) == 0x983b2d56
     *     bytes4(keccak256('renounceMinter()')) == 0x98650275
     *     bytes4(keccak256('mint(address,uint256)')) == 0x40c10f19
     *
     *     => 0xaa271e1a ^ 0x983b2d56 ^ 0x98650275 ^ 0x40c10f19 == 0xeab83e20
     */
    bytes4 private constant _INTERFACE_ID_KIP17_MINTABLE = 0xeab83e20;
    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Mintable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_MINTABLE);
    }
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
// File: contracts/token/KIP17/KIP17Burnable.sol
/**
 * @title KIP17 Burnable Token
 * @dev KIP17 Token that can be irreversibly burned (destroyed).
 * See http://kips.klaytn.com/KIPs/kip-17-non_fungible_token
 */
contract KIP17Burnable is KIP13, KIP17 {
    /*
     *     bytes4(keccak256('burn(uint256)')) == 0x42966c68
     *
     *     => 0x42966c68 == 0x42966c68
     */
    bytes4 private constant _INTERFACE_ID_KIP17_BURNABLE = 0x42966c68;
    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Burnable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_BURNABLE);
    }
    /**
     * @dev Burns a specific KIP17 token.
     * @param tokenId uint256 id of the KIP17 token to be burned.
     */
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "KIP17Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}
// File: contracts/access/roles/PauserRole.sol
contract PauserRole {
    using Roles for Roles.Role;
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    Roles.Role private _pausers;
  
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
// File: contracts/lifecycle/Pausable.sol
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
// File: contracts/token/KIP17/KIP17Pausable.sol
/**
 * @title KIP17 Non-Fungible Pausable token
 * @dev KIP17 modified with pausable transfers.
 */
contract KIP17Pausable is KIP13, KIP17, Pausable {
    /*
     *     bytes4(keccak256('paused()')) == 0x5c975abb
     *     bytes4(keccak256('pause()')) == 0x8456cb59
     *     bytes4(keccak256('unpause()')) == 0x3f4ba83a
     *     bytes4(keccak256('isPauser(address)')) == 0x46fbf68e
     *     bytes4(keccak256('addPauser(address)')) == 0x82dc1ec4
     *     bytes4(keccak256('renouncePauser()')) == 0x6ef8d66d
     *
     *     => 0x5c975abb ^ 0x8456cb59 ^ 0x3f4ba83a ^ 0x46fbf68e ^ 0x82dc1ec4 ^ 0x6ef8d66d == 0x4d5507ff
     */
    bytes4 private constant _INTERFACE_ID_KIP17_PAUSABLE = 0x4d5507ff;
    /**
     * @dev Constructor function.
     */
    constructor () public {
        // register the supported interface to conform to KIP17Pausable via KIP13
        _registerInterface(_INTERFACE_ID_KIP17_PAUSABLE);
    }
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
// File: contracts/token/KIP17/KIP17Token.sol
contract KIP17Token is  KIP17, KIP17Enumerable, KIP17Metadata, KIP17Mintable, KIP17MetadataMintable, KIP17Burnable, KIP17Pausable {
    bool private initialized;

    string internal constant ARLEADY_INITIALIZED = "already initialized";

    function initialize(
      address _owner,
      string memory _name,
      string memory _symbol
    ) public {
      require(!initialized, ARLEADY_INITIALIZED);
      _addMinter(_owner);
      _addPauser(_owner);

      _setMetadata(_name, _symbol);
      initialized = true;
    }

}