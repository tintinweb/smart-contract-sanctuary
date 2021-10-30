/**
 *Submitted for verification at polygonscan.com on 2021-10-30
*/

// File: src/contracts/ERC721Full.sol

// File: @openzeppelin/contracts/introspection/IERC165.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/drafts/Counters.sol

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
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol

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

// File: @openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol

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




contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
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

// File: @openzeppelin/contracts/token/ERC721/ERC721Full.sol

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

// File: src/contracts/NFTSelfie.sol

pragma solidity 0.5.0;



contract NFTSelfie is ERC721Full, Ownable {

    uint256 currentSupply;
    uint256 public constant peakCapacity = 100;

    mapping(uint256 => bool) _tokenExists;
    mapping(address => bool) _addressExists;

    constructor() ERC721Full("NFT Selfie", "SELFIE") public {
        currentSupply = 0;
    }

    function mint(string memory tokenURI, uint256 tokenId) payable public returns (bool)  {
        require(tokenId == currentSupply+1, "Invalid tokenId. The tokenId must be equivalent to currentSupply+1");
        require(!_addressExists[msg.sender], "Sender of transaction owns an NFT Selfie. Please use a different address.");
        require(!_tokenExists[tokenId], "Desired NFT Selfie is unavailable. Please use a different tokenId.");
        require(currentSupply < peakCapacity, "No more NFT Selfies available. Peak capacity reached.");

        if (tokenId == 1) {
            require(msg.value == 0 ether, "Invalid payment. Selfie #1 must be issued for 0 MATIC");
        } else if (tokenId == 2) {
            require(msg.value == 1 ether, "Invalid payment. Selfie #2 must be issued for 1 MATIC");
        } else if (tokenId == 3) {
            require(msg.value == 4 ether, "Invalid payment. Selfie #3 must be issued for 4 MATIC");
        } else if (tokenId == 4) {
            require(msg.value == 9 ether, "Invalid payment. Selfie #4 must be issued for 9 MATIC");
        } else if (tokenId == 5) {
            require(msg.value == 16 ether, "Invalid payment. Selfie #5 must be issued for 16 MATIC");
        } else if (tokenId == 6) {
            require(msg.value == 25 ether, "Invalid payment. Selfie #6 must be issued for 25 MATIC");
        } else if (tokenId == 7) {
            require(msg.value == 36 ether, "Invalid payment. Selfie #7 must be issued for 36 MATIC");
        } else if (tokenId == 8) {
            require(msg.value == 49 ether, "Invalid payment. Selfie #8 must be issued for 49 MATIC");
        } else if (tokenId == 9) {
            require(msg.value == 64 ether, "Invalid payment. Selfie #9 must be issued for 64 MATIC");
        } else if (tokenId == 10) {
            require(msg.value == 81 ether, "Invalid payment. Selfie #10 must be issued for 81 MATIC");
        } else if (tokenId == 11) {
            require(msg.value == 100 ether, "Invalid payment. Selfie #11 must be issued for 100 MATIC");
        } else if (tokenId == 12) {
            require(msg.value == 121 ether, "Invalid payment. Selfie #12 must be issued for 121 MATIC");
        } else if (tokenId == 13) {
            require(msg.value == 144 ether, "Invalid payment. Selfie #13 must be issued for 144 MATIC");
        } else if (tokenId == 14) {
            require(msg.value == 169 ether, "Invalid payment. Selfie #14 must be issued for 169 MATIC");
        } else if (tokenId == 15) {
            require(msg.value == 196 ether, "Invalid payment. Selfie #15 must be issued for 196 MATIC");
        } else if (tokenId == 16) {
            require(msg.value == 225 ether, "Invalid payment. Selfie #16 must be issued for 225 MATIC");
        } else if (tokenId == 17) {
            require(msg.value == 256 ether, "Invalid payment. Selfie #17 must be issued for 256 MATIC");
        } else if (tokenId == 18) {
            require(msg.value == 289 ether, "Invalid payment. Selfie #18 must be issued for 289 MATIC");
        } else if (tokenId == 19) {
            require(msg.value == 324 ether, "Invalid payment. Selfie #19 must be issued for 324 MATIC");
        } else if (tokenId == 20) {
            require(msg.value == 361 ether, "Invalid payment. Selfie #20 must be issued for 361 MATIC");
        } else if (tokenId == 21) {
            require(msg.value == 400 ether, "Invalid payment. Selfie #21 must be issued for 400 MATIC");
        } else if (tokenId == 22) {
            require(msg.value == 441 ether, "Invalid payment. Selfie #22 must be issued for 441 MATIC");
        } else if (tokenId == 23) {
            require(msg.value == 484 ether, "Invalid payment. Selfie #23 must be issued for 484 MATIC");
        } else if (tokenId == 24) {
            require(msg.value == 529 ether, "Invalid payment. Selfie #24 must be issued for 529 MATIC");
        } else if (tokenId == 25) {
            require(msg.value == 576 ether, "Invalid payment. Selfie #25 must be issued for 576 MATIC");
        } else if (tokenId == 26) {
            require(msg.value == 625 ether, "Invalid payment. Selfie #26 must be issued for 625 MATIC");
        } else if (tokenId == 27) {
            require(msg.value == 676 ether, "Invalid payment. Selfie #27 must be issued for 676 MATIC");
        } else if (tokenId == 28) {
            require(msg.value == 729 ether, "Invalid payment. Selfie #28 must be issued for 729 MATIC");
        } else if (tokenId == 29) {
            require(msg.value == 784 ether, "Invalid payment. Selfie #29 must be issued for 784 MATIC");
        } else if (tokenId == 30) {
            require(msg.value == 841 ether, "Invalid payment. Selfie #30 must be issued for 841 MATIC");
        } else if (tokenId == 31) {
            require(msg.value == 900 ether, "Invalid payment. Selfie #31 must be issued for 900 MATIC");
        } else if (tokenId == 32) {
            require(msg.value == 961 ether, "Invalid payment. Selfie #32 must be issued for 961 MATIC");
        } else if (tokenId == 33) {
            require(msg.value == 1024 ether, "Invalid payment. Selfie #33 must be issued for 1024 MATIC");
        } else if (tokenId == 34) {
            require(msg.value == 1089 ether, "Invalid payment. Selfie #34 must be issued for 1089 MATIC");
        } else if (tokenId == 35) {
            require(msg.value == 1156 ether, "Invalid payment. Selfie #35 must be issued for 1156 MATIC");
        } else if (tokenId == 36) {
            require(msg.value == 1225 ether, "Invalid payment. Selfie #36 must be issued for 1225 MATIC");
        } else if (tokenId == 37) {
            require(msg.value == 1296 ether, "Invalid payment. Selfie #37 must be issued for 1296 MATIC");
        } else if (tokenId == 38) {
            require(msg.value == 1369 ether, "Invalid payment. Selfie #38 must be issued for 1369 MATIC");
        } else if (tokenId == 39) {
            require(msg.value == 1444 ether, "Invalid payment. Selfie #39 must be issued for 1444 MATIC");
        } else if (tokenId == 40) {
            require(msg.value == 1521 ether, "Invalid payment. Selfie #40 must be issued for 1521 MATIC");
        } else if (tokenId == 41) {
            require(msg.value == 1600 ether, "Invalid payment. Selfie #41 must be issued for 1600 MATIC");
        } else if (tokenId == 42) {
            require(msg.value == 1681 ether, "Invalid payment. Selfie #42 must be issued for 1681 MATIC");
        } else if (tokenId == 43) {
            require(msg.value == 1764 ether, "Invalid payment. Selfie #43 must be issued for 1764 MATIC");
        } else if (tokenId == 44) {
            require(msg.value == 1849 ether, "Invalid payment. Selfie #44 must be issued for 1849 MATIC");
        } else if (tokenId == 45) {
            require(msg.value == 1936 ether, "Invalid payment. Selfie #45 must be issued for 1936 MATIC");
        } else if (tokenId == 46) {
            require(msg.value == 2025 ether, "Invalid payment. Selfie #46 must be issued for 2025 MATIC");
        } else if (tokenId == 47) {
            require(msg.value == 2116 ether, "Invalid payment. Selfie #47 must be issued for 2116 MATIC");
        } else if (tokenId == 48) {
            require(msg.value == 2209 ether, "Invalid payment. Selfie #48 must be issued for 2209 MATIC");
        } else if (tokenId == 49) {
            require(msg.value == 2304 ether, "Invalid payment. Selfie #49 must be issued for 2304 MATIC");
        } else if (tokenId == 50) {
            require(msg.value == 2401 ether, "Invalid payment. Selfie #50 must be issued for 2401 MATIC");
        } else if (tokenId == 51) {
            require(msg.value == 2500 ether, "Invalid payment. Selfie #51 must be issued for 2500 MATIC");
        } else if (tokenId == 52) {
            require(msg.value == 2601 ether, "Invalid payment. Selfie #52 must be issued for 2601 MATIC");
        } else if (tokenId == 53) {
            require(msg.value == 2704 ether, "Invalid payment. Selfie #53 must be issued for 2704 MATIC");
        } else if (tokenId == 54) {
            require(msg.value == 2809 ether, "Invalid payment. Selfie #54 must be issued for 2809 MATIC");
        } else if (tokenId == 55) {
            require(msg.value == 2916 ether, "Invalid payment. Selfie #55 must be issued for 2916 MATIC");
        } else if (tokenId == 56) {
            require(msg.value == 3025 ether, "Invalid payment. Selfie #56 must be issued for 3025 MATIC");
        } else if (tokenId == 57) {
            require(msg.value == 3136 ether, "Invalid payment. Selfie #57 must be issued for 3136 MATIC");
        } else if (tokenId == 58) {
            require(msg.value == 3249 ether, "Invalid payment. Selfie #58 must be issued for 3249 MATIC");
        } else if (tokenId == 59) {
            require(msg.value == 3364 ether, "Invalid payment. Selfie #59 must be issued for 3364 MATIC");
        } else if (tokenId == 60) {
            require(msg.value == 3481 ether, "Invalid payment. Selfie #60 must be issued for 3481 MATIC");
        } else if (tokenId == 61) {
            require(msg.value == 3600 ether, "Invalid payment. Selfie #61 must be issued for 3600 MATIC");
        } else if (tokenId == 62) {
            require(msg.value == 3721 ether, "Invalid payment. Selfie #62 must be issued for 3721 MATIC");
        } else if (tokenId == 63) {
            require(msg.value == 3844 ether, "Invalid payment. Selfie #63 must be issued for 3844 MATIC");
        } else if (tokenId == 64) {
            require(msg.value == 3969 ether, "Invalid payment. Selfie #64 must be issued for 3969 MATIC");
        } else if (tokenId == 65) {
            require(msg.value == 4096 ether, "Invalid payment. Selfie #65 must be issued for 4096 MATIC");
        } else if (tokenId == 66) {
            require(msg.value == 4225 ether, "Invalid payment. Selfie #66 must be issued for 4225 MATIC");
        } else if (tokenId == 67) {
            require(msg.value == 4356 ether, "Invalid payment. Selfie #67 must be issued for 4356 MATIC");
        } else if (tokenId == 68) {
            require(msg.value == 4489 ether, "Invalid payment. Selfie #68 must be issued for 4489 MATIC");
        } else if (tokenId == 69) {
            require(msg.value == 4624 ether, "Invalid payment. Selfie #69 must be issued for 4624 MATIC");
        } else if (tokenId == 70) {
            require(msg.value == 4761 ether, "Invalid payment. Selfie #70 must be issued for 4761 MATIC");
        } else if (tokenId == 71) {
            require(msg.value == 4900 ether, "Invalid payment. Selfie #71 must be issued for 4900 MATIC");
        } else if (tokenId == 72) {
            require(msg.value == 5041 ether, "Invalid payment. Selfie #72 must be issued for 5041 MATIC");
        } else if (tokenId == 73) {
            require(msg.value == 5184 ether, "Invalid payment. Selfie #73 must be issued for 5184 MATIC");
        } else if (tokenId == 74) {
            require(msg.value == 5329 ether, "Invalid payment. Selfie #74 must be issued for 5329 MATIC");
        } else if (tokenId == 75) {
            require(msg.value == 5476 ether, "Invalid payment. Selfie #75 must be issued for 5476 MATIC");
        } else if (tokenId == 76) {
            require(msg.value == 5625 ether, "Invalid payment. Selfie #76 must be issued for 5625 MATIC");
        } else if (tokenId == 77) {
            require(msg.value == 5776 ether, "Invalid payment. Selfie #77 must be issued for 5776 MATIC");
        } else if (tokenId == 78) {
            require(msg.value == 5929 ether, "Invalid payment. Selfie #78 must be issued for 5929 MATIC");
        } else if (tokenId == 79) {
            require(msg.value == 6084 ether, "Invalid payment. Selfie #79 must be issued for 6084 MATIC");
        } else if (tokenId == 80) {
            require(msg.value == 6241 ether, "Invalid payment. Selfie #80 must be issued for 6241 MATIC");
        } else if (tokenId == 81) {
            require(msg.value == 6400 ether, "Invalid payment. Selfie #81 must be issued for 6400 MATIC");
        } else if (tokenId == 82) {
            require(msg.value == 6561 ether, "Invalid payment. Selfie #82 must be issued for 6561 MATIC");
        } else if (tokenId == 83) {
            require(msg.value == 6724 ether, "Invalid payment. Selfie #83 must be issued for 6724 MATIC");
        } else if (tokenId == 84) {
            require(msg.value == 6889 ether, "Invalid payment. Selfie #84 must be issued for 6889 MATIC");
        } else if (tokenId == 85) {
            require(msg.value == 7056 ether, "Invalid payment. Selfie #85 must be issued for 7056 MATIC");
        } else if (tokenId == 86) {
            require(msg.value == 7225 ether, "Invalid payment. Selfie #86 must be issued for 7225 MATIC");
        } else if (tokenId == 87) {
            require(msg.value == 7396 ether, "Invalid payment. Selfie #87 must be issued for 7396 MATIC");
        } else if (tokenId == 88) {
            require(msg.value == 7569 ether, "Invalid payment. Selfie #88 must be issued for 7569 MATIC");
        } else if (tokenId == 89) {
            require(msg.value == 7744 ether, "Invalid payment. Selfie #89 must be issued for 7744 MATIC");
        } else if (tokenId == 90) {
            require(msg.value == 7921 ether, "Invalid payment. Selfie #90 must be issued for 7921 MATIC");
        } else if (tokenId == 91) {
            require(msg.value == 8100 ether, "Invalid payment. Selfie #91 must be issued for 8100 MATIC");
        } else if (tokenId == 92) {
            require(msg.value == 8281 ether, "Invalid payment. Selfie #92 must be issued for 8281 MATIC");
        } else if (tokenId == 93) {
            require(msg.value == 8464 ether, "Invalid payment. Selfie #93 must be issued for 8464 MATIC");
        } else if (tokenId == 94) {
            require(msg.value == 8649 ether, "Invalid payment. Selfie #94 must be issued for 8649 MATIC");
        } else if (tokenId == 95) {
            require(msg.value == 8836 ether, "Invalid payment. Selfie #95 must be issued for 8836 MATIC");
        } else if (tokenId == 96) {
            require(msg.value == 9025 ether, "Invalid payment. Selfie #96 must be issued for 9025 MATIC");
        } else if (tokenId == 97) {
            require(msg.value == 9216 ether, "Invalid payment. Selfie #97 must be issued for 9216 MATIC");
        } else if (tokenId == 98) {
            require(msg.value == 9409 ether, "Invalid payment. Selfie #98 must be issued for 9409 MATIC");
        } else if (tokenId == 99) {
            require(msg.value == 9604 ether, "Invalid payment. Selfie #99 must be issued for 9604 MATIC");
        } else if (tokenId == 100) {
            require(msg.value == 9801 ether, "Invalid payment. Selfie #100 must be issued for 9801 MATIC");
        } else {
            revert("Invalid tokenId. Please try again using our dApp (nftselfies.xyz)");
        }

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _tokenExists[tokenId] = true;
        _addressExists[msg.sender] = true;

        currentSupply += 1;
        
        return true;
    }

    function withdraw() payable onlyOwner public {
        msg.sender.transfer(address(this).balance);
    }

}