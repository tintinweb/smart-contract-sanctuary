/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// File: contracts/IERC165.sol

pragma solidity ^0.5.16;

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

// File: contracts/ERC165.sol

pragma solidity ^0.5.16;


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

// File: contracts/IERC721.sol

pragma solidity ^0.5.16;


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
    function approve(address to, uint256 tokenId) public ;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public  view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: contracts/SafeMath.sol

pragma solidity ^0.5.16;

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

// File: contracts/Address.sol

pragma solidity ^0.5.16;

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

// File: contracts/Counters.sol

pragma solidity ^0.5.16;


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

// File: contracts/IERC721Receiver.sol

pragma solidity ^0.5.16;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public returns (bytes4);
}

// File: contracts/ERC721.sol

pragma solidity ^0.5.16;






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

// File: contracts/IERC721Enumerable.sol

pragma solidity ^0.5.16;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: contracts/ERC721Enumerable.sol

pragma solidity ^0.5.16;




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

// File: contracts/IERC721Metadata.sol

pragma solidity ^0.5.16;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: contracts/ERC721Metadata.sol

pragma solidity ^0.5.16;




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

// File: contracts/ERC721Full.sol

pragma solidity ^0.5.16;




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

// File: contracts/Ownable.sol

pragma solidity ^0.5.16;


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  constructor (address _owner) public {
    owner = _owner;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

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

// File: contracts/DUNKNFT.sol

pragma solidity ^0.5.16;




contract DUNKNFT is ReentrancyGuard, ERC721Full, Ownable{
    
    string[] public sneakers;
    
    uint256[] tokensForAuction;
    uint256 public NFTSold = 0;
    uint256 public availableForAuction = 0;
    
    address payable public adminAccount;
    
    address public platform;
    
    mapping (string => bool) public exists;
    mapping (uint256 => autionToken) public auctionTokenDetail;
    mapping (uint256 => address) public previousOwner;
    mapping (uint256 => uint256) public tokenTier;
    
    struct autionToken{
        uint256 _startAmount;
        uint256 _maxBid;
        address payable _maxBidder;
        uint256 _bidCount;
        bool availability;
    }
    
    modifier onlyPlatform() {
    require(msg.sender == platform,"Not Platform Contract");
    _;
    }
    
    constructor(string memory _name, string memory _symbol, address payable _adminAccount) ERC721Full(_name, _symbol) public Ownable(msg.sender){
        adminAccount = _adminAccount;
    }
    
    function () external payable {
    }

    function mint(string memory _sneakers, address _beneficiary, string memory _tokenMetaData) public onlyPlatform returns (uint256) {
        
        require(exists[_sneakers] == false,"alread exist!");
        
        uint256 _id = sneakers.push(_sneakers);
        _mint(_beneficiary,_id);
        _setTokenURI(_id,_tokenMetaData);
        exists[_sneakers] = true;
        return _id;
    }
    
    function callAuction(uint256 _tokenID, uint256 _startAmount, address _beneficiary) public onlyPlatform{
        
        require(_beneficiary == ownerOf(_tokenID),"not the owner of token");
        
        require(!auctionTokenDetail[_tokenID].availability,"already listed!");
        
        tokensForAuction.push(_tokenID);
        
        auctionTokenDetail[_tokenID]._startAmount = _startAmount;
        auctionTokenDetail[_tokenID].availability = true;
        
        availableForAuction++;
    }
    
    function closeAuction(uint256 _tokenID, address _beneficiary) public nonReentrant onlyPlatform{
        require(_beneficiary == ownerOf(_tokenID),"not the owner of token");
        
        address payable bidder = auctionTokenDetail[_tokenID]._maxBidder;
        uint256 bidAmount = auctionTokenDetail[_tokenID]._maxBid;
        
        auctionTokenDetail[_tokenID]._startAmount = 0;
        auctionTokenDetail[_tokenID]._maxBid = 0;
        auctionTokenDetail[_tokenID]._bidCount = 0;
        auctionTokenDetail[_tokenID]._maxBidder = address(0);
        auctionTokenDetail[_tokenID].availability = false;
        
        if (bidAmount > 0){
            
            bidder.transfer(bidAmount);
            
        }
    }
    
    function makeBid(uint256 _tokenID, uint256 _value, address payable _beneficiary,uint256 userTier) public nonReentrant onlyPlatform{
        
        require(_value > 0, "Invalid value!");
        
        require(auctionTokenDetail[_tokenID].availability,"token not available to bid");
        
        require(_beneficiary != ownerOf(_tokenID),"Owner cannot bid");
        
        require(_value > auctionTokenDetail[_tokenID]._maxBid,"Bid should be greater");
        
        require(_value > auctionTokenDetail[_tokenID]._startAmount,"Bid should be greater than start amount");
        
        require(userTier >= tokenTier[_tokenID],"User tier not allowed!");
        
        address payable previousHighestBidder;
        uint256 previousHighestBid;
        
        if(auctionTokenDetail[_tokenID]._maxBid < _value){
            
            previousHighestBid = auctionTokenDetail[_tokenID]._maxBid;
            previousHighestBidder = auctionTokenDetail[_tokenID]._maxBidder;
            
            auctionTokenDetail[_tokenID]._bidCount++;
            auctionTokenDetail[_tokenID]._maxBidder = _beneficiary;
            auctionTokenDetail[_tokenID]._maxBid = _value;
            
        }
        
        previousHighestBidder.transfer(previousHighestBid);
        
    }
    
    function acceptBid(uint256 _tokenID, uint256 _tier) public nonReentrant {
        
        require(msg.sender == ownerOf(_tokenID),"not the owner of token");
        
        require(auctionTokenDetail[_tokenID]._bidCount > 0,"no bid made");
        
        auctionTokenDetail[_tokenID].availability = false;
        
        address buyer = auctionTokenDetail[_tokenID]._maxBidder;
        uint256 bidValue = auctionTokenDetail[_tokenID]._maxBid;
        address payable seller = msg.sender;
        
        uint256 amountToAcceptor;
        uint256 platformFee;
        
        if(_tier == 0){
            platformFee = (bidValue.mul(15)).div(100);
            amountToAcceptor = bidValue.sub(platformFee);
        }
        else if(_tier == 1){
            platformFee = (bidValue.mul(14)).div(100);
            amountToAcceptor = bidValue.sub(platformFee);
        }
        else if(_tier == 2){
            platformFee = (bidValue.mul(13)).div(100);
            amountToAcceptor = bidValue.sub(platformFee);
        }
        
        auctionTokenDetail[_tokenID]._startAmount = 0;
        auctionTokenDetail[_tokenID]._maxBid = 0;
        auctionTokenDetail[_tokenID]._bidCount = 0;
        auctionTokenDetail[_tokenID]._maxBidder = address(0);
        
        previousOwner[_tokenID] = ownerOf(_tokenID);
        
        transferFrom(seller,buyer,_tokenID);
        
        seller.transfer(amountToAcceptor);
        adminAccount.transfer(platformFee);
        
        NFTSold++;
        availableForAuction--;
        
    }
    
    function setPlatformAddress(address _platform) public onlyOwner{
        require (_platform != address(0),"Invalid address");
        
        platform = _platform;
    }
    
    function tokenDetail(uint256 _tokenID) public view returns(uint256 _startAmount, uint256 _maxBid, address _maxBidder, uint256 _bidCount, bool availability){
        
        _startAmount = auctionTokenDetail[_tokenID]._startAmount;
        _maxBid = auctionTokenDetail[_tokenID]._maxBid;
        _maxBidder = auctionTokenDetail[_tokenID]._maxBidder;
        _bidCount = auctionTokenDetail[_tokenID]._bidCount;
        availability = auctionTokenDetail[_tokenID].availability;
        
    }
    
    function updateTokenTier(uint256 _tokenID, uint256 _tokenTier) public onlyPlatform{
        tokenTier[_tokenID] = _tokenTier;
    }
    
    function NFTContractDetails() public view returns(uint256 _totalSupply, uint256 _NFTsold, uint256 _availableForAuction){
        _totalSupply = totalSupply();
        _NFTsold = NFTSold;
        _availableForAuction = availableForAuction;
    }
    
}

// File: contracts/ERC20Basic.sol

pragma solidity ^0.5.16;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/BasicToken.sol

pragma solidity ^0.5.16;





contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    mapping(address => uint256) public stakedAmount;

    uint256 public _totalSupply;

 
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */ 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(balances[msg.sender].sub(stakedAmount[msg.sender])>= _value,"Some portion has been staked!");

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: contracts/ERC20.sol

pragma solidity ^0.5.16;


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/StandardToken.sol

pragma solidity ^0.5.16;



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0),"Invalid Address");
    require(_value <= balances[_from],"Amount greater than balance");
    require(_value <= allowed[_from][msg.sender],"Amount greater than allowance");

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    emit Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public returns (bool) {
    
    require(_spender != address(0));
    require(balances[msg.sender].sub(stakedAmount[msg.sender])>= _value,"Some portion has been staked!");
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(balances[msg.sender].sub(stakedAmount[msg.sender])>= allowance(msg.sender,_spender).add(_addedValue),"Some portion has been staked!");

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: contracts/DUNKToken.sol

pragma solidity ^0.5.16;



contract DUNKToken is StandardToken, Ownable
{
    
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    
    address public platform;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    modifier onlyPlatform() {
    require(msg.sender == platform,"Not Platform Contract");
    _;
    }
    
    constructor(string memory _name, string memory _symbol) public Ownable(msg.sender){ 
        
        name = _name;
        symbol = _symbol;
        _totalSupply = 0;

    }
    
    function mint(uint256 _value, address _beneficiary)  public onlyOwner{

        require(_value > 0,"invalid value entered");
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        _totalSupply = _totalSupply.add(_value);
        
        emit Transfer(address(0),_beneficiary, _value);
        
    }
    
    function burn(uint256 _value, address _beneficiary)  public onlyOwner {
        require(_value > 0,"Invalid value!");
        
        _totalSupply = _totalSupply.sub(_value);
        balances[_beneficiary] = balances[_beneficiary].sub(_value);
        
        emit Transfer(_beneficiary, address(0), _value);
    }
    
    function stakeToken(uint256 _value, address _beneficiary) external onlyPlatform{
        require(_value > 0,"Invalid value!");
        
        require(_value < balances[_beneficiary],"Invalid value! Greater than the owned tokens.");
        
        require(_beneficiary != address(0),"Invalid address!");
        
        stakedAmount[_beneficiary] = stakedAmount[_beneficiary].add(_value);
    }
    
    function unStakeToken(uint256 _value, address _beneficiary) external onlyPlatform{
        require(_value > 0,"Invalid value!");
        
        require(_value <= stakedAmount[_beneficiary],"Invalid value! value greater than staked amount.");
        
        require(_beneficiary != address(0),"Invalid address!");
        
        stakedAmount[_beneficiary] = stakedAmount[_beneficiary].sub(_value);
    }
    
    function mintReward(uint256 _value, address _beneficiary)  external onlyPlatform{

        require(_value > 0,"invalid value entered");
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        _totalSupply = _totalSupply.add(_value);
        
        emit Transfer(address(0),_beneficiary, _value);
        
    }
    
    function setPlatformAddress(address _platform) public onlyOwner{
        require (_platform != address(0),"Invalid address");
        
        platform = _platform;
    }
    
    function getStakedAmount(address _beneficiary) public view returns(uint256){
        return stakedAmount[_beneficiary];
    }
    
}

// File: contracts/DUNKPlatform.sol

pragma solidity ^0.5.16;






contract DUNKPlatform is ReentrancyGuard, Ownable{
    using SafeMath for uint256;
    DUNKNFT public NFT;
    DUNKToken public Token;
    uint256 public tier1;
    uint256 public tier2;
    uint256 public APY;
    uint256 day = 120;// 300;//86400
    
    mapping (address => User) public userDetail;
    
    struct User{
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 amountCollected;
        uint256 nextRewardClaimTime;
        uint256 lastCollectTime;
    }
    
    address payable public admin;
    
    constructor (/*string memory NFTName, string memory NFTSymbol, string memory tokenName, string memory tokenSymbol*/DUNKNFT _NFT,DUNKToken _Token) public Ownable(msg.sender) {
        // NFT = new DUNKNFT(NFTName,NFTSymbol,msg.sender);
        // Token = new DUNKToken(tokenName,tokenSymbol);
        NFT = _NFT;
        Token = _Token;
        tier1 = 200_000_000_000_000_000_000;
        tier2 = 1000_000_000_000_000_000_000;
        APY = 1000_000_000_000_000_000_000;
        
        admin = msg.sender;
    }
    
    function mintNFT(string memory _sneakers, address _beneficiary, string memory _tokenMetaData) public returns (uint256){
        return NFT.mint(_sneakers,_beneficiary,_tokenMetaData);
    }
    
    function callAuction(uint256 _tokenID, uint256 _startAmount) public {
        NFT.callAuction(_tokenID,_startAmount,msg.sender);
    }
    
    function closeAuction(uint256 _tokenID) nonReentrant public {
        NFT.closeAuction(_tokenID,msg.sender);
    }
    
    function makeBid(uint256 _tokenID) public nonReentrant payable  {
        uint256 value = msg.value;
        NFT.makeBid(_tokenID,value,msg.sender,getTier(msg.sender));
        address(NFT).transfer(msg.value);
    }
    
    // function acceptBid(uint256 _tokenID) nonReentrant public {
    //     NFT.acceptBid(_tokenID,msg.sender,getTier(msg.sender));
    // }
    
    function updateTokenTier(uint256 _tokenID, uint256 _tokenTier) public {
        NFT.updateTokenTier(_tokenID,_tokenTier);
    }
    
    function NFTTokenDetail(uint256 _tokenID) public view returns(uint256 _startAmount, uint256 _maxBid, address _maxBidder, uint256 _bidCount, bool availability){
        
        (_startAmount,_maxBid,_maxBidder,_bidCount,availability) = NFT.tokenDetail(_tokenID);
        
    }
    
    function NFTContractDetails() public view returns(uint256 _totalSupply, uint256 _NFTsold, uint256 _availableForAuction){
        (_totalSupply, _NFTsold, _availableForAuction) = NFT.NFTContractDetails(); 
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // function mintToken(uint256 _value, address _beneficiary) public {
    //     Token.mint(_value,_beneficiary);
    // }
    
    // function burn(uint256 _value) public {
    //     Token.burn(_value,msg.sender);
    // }
    
    function stakeToken(uint256 _value) public {
        userDetail[msg.sender].stakeAmount = (userDetail[msg.sender].stakeAmount).add(_value);
        
        if (userDetail[msg.sender].stakeTime == 0){
            userDetail[msg.sender].stakeTime = block.timestamp;
            userDetail[msg.sender].lastCollectTime = block.timestamp;
            userDetail[msg.sender].nextRewardClaimTime = block.timestamp.add(day);
        }
        
        Token.stakeToken(_value,msg.sender);
        
    }
    
    function unStakeToken(uint256 _value) public {
        require(_value <= userDetail[msg.sender].stakeAmount,"Value greater than staked value");
        
        collectAPYReward();
        
        userDetail[msg.sender].stakeAmount = (userDetail[msg.sender].stakeAmount).sub(_value);
        
        if (userDetail[msg.sender].stakeAmount == 0){
            userDetail[msg.sender].stakeTime = 0;
            userDetail[msg.sender].lastCollectTime = 0;
            userDetail[msg.sender].nextRewardClaimTime = 0;
        }
        
        Token.unStakeToken(_value,msg.sender);
    }
    
    
    function collectAPYReward() public {
        require(block.timestamp >= userDetail[msg.sender].nextRewardClaimTime,"Please wait for duration to complete!");
        
        require(userDetail[msg.sender].stakeAmount>0,"0 Tokens staked!");
        
        (uint256 rewardAmount,,uint256 totalStakeDays) = calculatedAPYForDays(msg.sender);
        
        userDetail[msg.sender].amountCollected = userDetail[msg.sender].amountCollected.add(rewardAmount);
        
        userDetail[msg.sender].lastCollectTime = userDetail[msg.sender].stakeTime.add(day.mul(totalStakeDays));
        
        userDetail[msg.sender].nextRewardClaimTime = userDetail[msg.sender].stakeTime.add(day.mul(++totalStakeDays));
    
    }
    
    function calculatedAPYForDays(address _beneficiary) public view returns(uint256 reward,uint256 _days,uint256 totalStakeDays){
        if(userDetail[_beneficiary].lastCollectTime > 0){
            totalStakeDays = (block.timestamp.sub(userDetail[_beneficiary].stakeTime)).div(day);
            _days = (block.timestamp.sub(userDetail[_beneficiary].lastCollectTime)).div(day); 
            reward = _days.mul(calculateAPYReward(_beneficiary));
        }
        else{
            _days = 0;
            reward = 0;
        }
    }
    
    function calculateAPYReward(address _beneficiary) public view returns(uint256 perDayReward){
        uint256 userAPYReward = (userDetail[_beneficiary].stakeAmount.mul(APY)).div(100_000_000_000_000_000_000);
        perDayReward = userAPYReward.div(365);
    }
    
    function claimAPYReward() public {
        
        require(userDetail[msg.sender].amountCollected > 0,"No collected reward!");
        
        uint256 userReward = userClaimableReward(msg.sender);
        
        userDetail[msg.sender].amountCollected = userDetail[msg.sender].amountCollected.sub(userDetail[msg.sender].amountCollected);
        
        Token.mintReward(userReward,msg.sender);
    }
    
    function userClaimableReward(address _beneficiary) public view returns(uint256 collectableReward){
        uint256 daysStaked = (block.timestamp.sub(userDetail[_beneficiary].stakeTime)).div(day);
        
        if (daysStaked < 10){
            uint256 deduction = ((userDetail[_beneficiary].amountCollected).mul(20)).div(100);
            collectableReward = userDetail[_beneficiary].amountCollected.sub(deduction);
        }
        else {
            collectableReward = userDetail[_beneficiary].amountCollected;
        }
    }
    
    function getTier(address _beneficiary) public view returns(uint256){
        uint256 _value = Token.getStakedAmount(_beneficiary);
        
        if(_value<tier1){
            return 0;
        }
        
        else if(_value>=tier1 && _value<tier2){
            return 1;
        }
        
        else if(_value>=tier2){
            return 2;
        }
        
    }
    
    function stakeTokenDetail(address _beneficiary) public view returns(uint256 totalTokens, uint256 staked, uint256 remainingStakable){
        totalTokens = Token.balanceOf(_beneficiary);
        staked = userDetail[_beneficiary].stakeAmount;
        remainingStakable = totalTokens.sub(staked);
    }
    
}