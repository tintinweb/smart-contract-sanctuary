/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.2;

/**
* @title IERC165
* @dev https://eips.ethereum.org/EIPS/eip-165
* @dev source : openzeppelin-solidity/contracts/introspection/IERC165.sol
*/
interface IERC165 {
    /**
    * @notice Query if a contract implements an interface
    * @param interfaceId The interface identifier, as specified in ERC-165
    * @dev Interface identification is specified in ERC-165. This function
    * uses less than 30,000 gas.
    */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
* @title SafeMath
* @dev Unsigned math operations with safety checks that revert on error
* @dev source : openzeppelin-solidity/contracts/math/SafeMath.sol
*/
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "error");

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "cannot divide by 0 or negative");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "result cannot be lower than 0");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "both numbers have to be positive");

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "cannot divide by 0");
        return a % b;
    }
}

/**
* @title Counters
* @author Matt Condon (@shrugs)
* @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
* of elements in a mapping, issuing ERC721 ids, or counting request ids
*
* Include with `using Counters for Counters.Counter;`
* Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the SafeMath
* overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
* directly accessed.
* @dev source : openzeppelin-solidity/contracts/drafts/Counters.sol
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

contract Storage {
    using Counters for Counters.Counter;

    // Token name
    string internal _name;
    // Token symbol
    string internal _symbol;
    // Token base uri
    string internal _baseTokenURI;

    // ERC165 supported interfaces
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    
    // OpenSea proxy registry
    address public proxyRegistryAddress;

    // token id tracker
    uint256 internal _currentTokenId = 0;
    
    // Array with all token ids, used for enumeration
    uint256[] internal _allTokens;

    // mapping of interface id to whether or not it's supported    
    mapping(bytes4 => bool) internal _supportedInterfaces;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => Counters.Counter) internal _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal _operatorApprovals;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal _ownedTokensIndex;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal _allTokensIndex;

    
}

/**
* @title ERC165
* @author Matt Condon (@shrugs)
* @dev Implements ERC165 using a lookup table.
* @dev source : openzeppelin-solidity/contracts/introspection/ERC165.sol
*/
contract ERC165 is IERC165, Storage {

    /**
    * @dev implement supportsInterface(bytes4) using a lookup table
    */
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
    * @dev internal method for registering an interface
    */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "bad interface");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
* @title ERC721 Non-Fungible Token Standard basic interface
* @dev see https://eips.ethereum.org/EIPS/eip-721
* @dev source : openzeppelin-solidity/contracts/token/ERC721/IERC721.sol
*/
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFromWithData(address from, address to, uint256 tokenId, bytes calldata data) external;
}

/**
* @title ERC721 token receiver interface
* @dev Interface for any contract that wants to support safeTransfers
* from ERC721 asset contracts.
* @dev source : openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol
*/
interface IERC721Receiver {
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

/**
* Utility library of inline functions on addresses
* @dev source : openzeppelin-solidity/contracts/utils/Address.sol
*/
library Address {
    /**
    * Returns whether the target address is a contract
    * @dev This function will return false if invoked during the constructor of a contract,
    * as the code is not actually created until after the constructor finishes.
    * @param account address of the account to check
    * @return whether the target address is a contract
    */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
* @title ERC721 Non-Fungible Token Standard basic implementation
* @dev see https://eips.ethereum.org/EIPS/eip-721
* @dev source : openzeppelin-solidity/contracts/token/ERC721/ERC721.sol
*/
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    /**
    * @dev Gets the balance of the specified address
    * @param owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "owner cannot be address 0");
        return _ownedTokensCount[owner].current();
    }

    /**
    * @dev Gets the owner of the specified token ID
    * @param tokenId uint256 ID of the token to query the owner of
    * @return address currently marked as the owner of the given token ID
    */
    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "owner cannot be address 0");
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
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "cannot approve yourself");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "permission denied");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
    * @dev Gets the approved address for a token ID, or zero if no address set
    * Reverts if the token ID does not exist.
    * @param tokenId uint256 ID of the token to query the approval of
    * @return address currently approved for the given token ID
    */
    function getApproved(uint256 tokenId) public override view returns (address) {
        require(_exists(tokenId), "tokenID doesn't exist");
        return _tokenApprovals[tokenId];
    }

    /**
    * @dev Sets or unsets the approval of a given operator
    * An operator is allowed to transfer all tokens of the sender on their behalf
    * @param to operator address to set the approval
    * @param approved representing the status of the approval to be set
    */
    function setApprovalForAll(address to, bool approved) public override {
        require(to != msg.sender, "cannot approve yourself");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
    * @dev Tells whether an operator is approved by a given owner
    * @param owner owner address which you want to query the approval of
    * @param operator operator address which you want to query the approval of
    * @return bool whether the given operator is approved by the given owner
    */
    function isApprovedForAll(address owner, address operator) public override virtual view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
    * @dev Transfers the ownership of a given token ID to another address
    * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
    * Requires the msg.sender to be the owner, approved, or operator
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "spender is not approved");

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
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFromWithData(from, to, tokenId, "");
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
    function safeTransferFromWithData(address from, address to, uint256 tokenId, bytes memory _data) public override {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "data check is not ok");
    }

    /**
    * @dev Returns whether the specified token exists
    * @param tokenId uint256 ID of the token to query the existence of
    * @return bool whether the token exists
    */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
    * @dev Returns whether the given spender can transfer a given token ID
    * @param spender address of the spender to query
    * @param tokenId uint256 ID of the token to be transferred
    * @return bool whether the msg.sender is approved for the given token ID,
    * is an operator of the owner, or is the owner of the token
    */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
    * @dev Internal function to mint a new token
    * Reverts if the given token ID already exists
    * @param to The address that will own the minted token
    * @param tokenId uint256 ID of the token to be minted
    */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "cannot mint to address 0");
        require(!_exists(tokenId), "token already exists");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * Reverts if the token does not exist
    * Deprecated, use _burn(uint256) instead.
    * @param owner owner of the token to burn
    * @param tokenId uint256 ID of the token being burned
    */
    function _burn(address owner, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == owner, "address is not owner of tokenID");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * Reverts if the token does not exist
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
    function _transferFrom(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "sender is not owner of the token");
        require(to != address(0), "cannot send to 0 address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
    * @dev Internal function to invoke `onERC721Received` on a target address
    * The call is not executed if the target address is not a contract
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
    * @dev Private function to clear current approval of a given token ID
    * @param tokenId uint256 ID of the token to be transferred
    */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

/**
* @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
* @dev source : openzeppelin-solidity/contracts/token/ERC721/IERC721Full.sol
*/
interface IERC721Full is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}


/**
* @title Full ERC721 Token
* This implementation includes all the required and some optional functionality of the ERC721 standard
* Moreover, it includes approve all functionality using operator terminology
* @dev see https://eips.ethereum.org/EIPS/eip-721
* @dev source : openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol
*/
contract ERC721Full is ERC721, IERC721Full {
    using SafeMath for uint256;

    /**
    * @dev Constructor function
    */
    function init (string memory name, string memory symbol) internal {
        _name = name;
        _symbol = symbol;
    }

    /**
    * @dev Gets the token name
    * @return string representing the token name
    */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Gets the token ID at a given index of the tokens list of the requested owner
    * @param owner address owning the tokens list to be accessed
    * @param index uint256 representing the index to be accessed of the requested tokens list
    * @return uint256 token ID at the given index of the tokens list owned by the requested address
    */
    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256) {
        require(index < balanceOf(owner), "index is too high");
        return _ownedTokens[owner][index];
    }

    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() public override view returns (uint256) {
        return _allTokens.length;
    }

    /**
    * @dev Gets the token ID at a given index of all the tokens in this contract
    * Reverts if the index is greater or equal to the total number of tokens
    * @param index uint256 representing the index to be accessed of the tokens list
    * @return uint256 token ID at the given index of the tokens list
    */
    function tokenByIndex(uint256 index) public override view returns (uint256) {
        require(index < totalSupply(), "index is too high");
        return _allTokens[index];
    }

    /**
    * @dev Internal function to transfer ownership of a given token ID to another address.
    * As opposed to transferFrom, this imposes no restrictions on msg.sender.
    * @param from current owner of the token
    * @param to address to receive the ownership of the given token ID
    * @param tokenId uint256 ID of the token to be transferred
    */
    function _transferFrom(address from, address to, uint256 tokenId) internal override {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
    * @dev Internal function to mint a new token
    * Reverts if the given token ID already exists
    * @param to address the beneficiary that will own the minted token
    * @param tokenId uint256 ID of the token to be minted
    */
    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * Reverts if the token does not exist
    * Deprecated, use _burn(uint256) instead
    * @param owner owner of the token to burn
    * @param tokenId uint256 ID of the token being burned
    */
    function _burn(address owner, uint256 tokenId) internal override {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);

    }

    /**
    * @dev Gets the list of token IDs of the requested owner
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
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        _ownedTokens[from].pop();
    }

    /**
    * @dev Private function to remove a token from this extension's token tracking data structures.
    * This has O(1) time complexity, but alters the order of the _allTokens array.
    * @param tokenId uint256 ID of the token to be removed from the tokens list
    */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex; 

        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }

    /**
     * @dev
     * @notice Non-Standard method to retrieve all NFTs that specific owner owns
     * @return uint[] containing all NFTs that owner owns
     */
    function tokensOf(address owner) public view returns (uint[] memory) {
        return _tokensOfOwner(owner);
    }
}


/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
* functions, this simplifies the implementation of "user permissions".
* @dev source : openzeppelin-solidity/contracts/ownership/Ownable.sol
*/
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @return the address of the owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(isOwner(), "sender is not owner");
        _;
    }

    /**
    * @return true if `msg.sender` is the owner of the contract.
    */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    * @notice Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "new owner cannot be address 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Administrable
 * @dev Handle allowances for NFTs administration :
 *      - minting
 *      - burning
 *      - access to admin web interfaces
 * @dev ADMINS STORAGE 
 * @dev rights are integer(int16) defined as follow :
 *       1 : address can only mint tokens 
 *       2 : address can mint AND burn tokens
*/
contract Administrable is Ownable {
    
    mapping(address => int16) private admins;

    event AdminRightsGranted(address indexed newAdmin, int16 adminRights);
    event AdminRightsRevoked(address indexed noAdmin);

    /**
    * @dev know if an address has admin rights and its type of rights
    * @param _admin the address to find admin rights of
    * @return int16 the admin right for _admin :
    *       1 : address can only mint tokens 
    *       2 : address can mint AND burn tokens 
    */
    function adminRightsOf(address _admin) public view returns(int16) {
        if (_admin == owner()) return 2;
        else return admins[_admin];
    }

    /**
    * @dev verifiy if an address can mint new tokens
    * @param _admin : the address to verify minting rights of
    * @return a boolean, truthy when _admin has rights to mint new tokens
    */
    function isMinter(address _admin) public view returns (bool) {
        if (_admin == owner()) return true;
        else return(
            admins[_admin] > 0
        );
    }


    /**
    * @dev verifiy if an address has rights to mint and burn new tokens
    * @param _admin : the address to verify minter-burner rights of
    * @return a boolean, truthy when _admin has rights to mint and burn new tokens
    */
    function isMinterBurner(address _admin) public view returns (bool) {
        if (_admin == owner()) return true;
        else return(
            admins[_admin] == 2
        );
    }


    /**
    * @dev canMint external 
    * @return bool : truthy if msg.sender has admin rights to mint new tokens
    */
    function canMint() public view returns(bool) {
        return(
            isMinter(msg.sender)
        );
    }


    /**
    * @dev canBurn external
    * @return bool : truthy if msg.sender has admin rights to mint new tokens and burn existing tokens
    */
    function canMintBurn() public view returns(bool) {
        return(
            isMinterBurner(msg.sender)
        );
    }

    /**
    * @dev onlyMinter internal
    */
    modifier onlyMinter() {
        require(
            canMint(),
            "denied : no admin minting rights"
        );
        _;
    }

    /**
    * @dev onlyBurner internal
    */
    modifier onlyMinterBurner() {
        require(
            canMintBurn(),
            "denied : no admin burning rights"
        );
        _;
    }

    modifier validAddress(address _admin) {
        require(_admin != address(0), "invalid admin address");
        _;
    }

    /**
    * @dev owner can grant admin access to allow any address to mint new tokens
    * @dev Restricted to CONTRACT OWNER ONLY
    * @param _admin : address to grant admin minter rights to
    */
    function grantMinterRights(address _admin) external onlyOwner validAddress(_admin) {
        admins[_admin] = 1;
        emit AdminRightsGranted(_admin, 1);
    }

    /**
    * @dev owner can grant admin access to allow any address to mint new tokens and to burn existing tokens
    * @dev Restricted to CONTRACT OWNER ONLY
    * @param _admin : address to grant admin minter and burner rights to
    */
    function grantMinterBurnerRights(address _admin) external onlyOwner validAddress(_admin) {
        admins[_admin] = 2;
        emit AdminRightsGranted(_admin, 2);
    }

    /**
    * @dev owner can revoke admin right of any admin address
    * @dev Restricted to CONTRACT OWNER ONLY
    * @param _admin : address to revoke admin access to
    */
    function revokeAdminRights(address _admin) external onlyOwner validAddress(_admin) {
        admins[_admin] = 0;
        emit AdminRightsRevoked(_admin);
    }

}

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function fromAddress(address addr) internal pure returns(string memory) {
        bytes20 addrBytes = bytes20(addr);
        bytes16 hexAlphabet = "0123456789abcdef";
        bytes memory result = new bytes(42);
        result[0] = "0";
        result[1] = "x";
        for (uint i = 0; i < 20; i++) {
            result[i * 2 + 2] = hexAlphabet[uint8(addrBytes[i] >> 4)];
            result[i * 2 + 3] = hexAlphabet[uint8(addrBytes[i] & 0x0f)];
        }
        return string(result);
    }
}

/**
* @title OwnableDelegateProxy
* @dev OpenSea compliant feature
*/
contract OwnableDelegateProxy { }

/**
* @title ProxyRegistry
* @dev OpenSea compliant feature
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


/**
* @title TradeableERC721Token
* ERC721 contract that whitelists a trading address, and has minting functionalities.
* @notice an external 'burn' function restricted to owner as been added
*/
contract TradeableERC721Token is ERC721Full, Administrable {
    using Strings for string;
    using SafeMath for uint256;

    function init(string memory _name, string memory _symbol, address _proxyRegistryAddress) internal {
        ERC721Full.init(_name, _symbol);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
    * @dev Mints a token to an address.
    * @param _to address of the future owner of the token
    */
    function mintTo(address _to) public onlyMinter {
        require(_to != address(0), "cannot mint to address 0");
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }

    /**
     * @dev Mint several tokens to an address.
     * @param _total total number of NFT to mint (reverts if <= 0)
     * @param _to default owner of the new created NFT (reverts if a zero address)
     */
    function batchMintTo(uint _total, address _to) public onlyMinter {
        require(_total > 0, "mint minimum 1 token");
        for (uint i = 0; i < _total; i++) mintTo(_to);
    }

    /**
    * @dev External Burn NFT method
    */
    function burn(uint _tokenId) public onlyMinterBurner {
        super._burn(_tokenId);
    }

    /**
        * @dev calculates the next token ID based on value of _currentTokenId
        * @return uint256 for the next token ID
        */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
        * @dev increments the value of _currentTokenId
        */
    function _incrementTokenId() private  {
        _currentTokenId++;
    }

    /**
    * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    */
    function isApprovedForAll(
        address owner,
        address operator
    )
    public override
    view
    returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

/**
* @title IpfsHashs
* @dev Provide methods to store and retrieve tokens IPFS CIDs
*/
contract IpfsHashs is Administrable {

    mapping (uint => mapping(string => string)) internal ipfsHashs;

    function setIpfsHash(uint tokenId, string memory docType, string memory _hash) public onlyMinter {
        require(tokenId > 0, "denied : token zero cant be used");
        ipfsHashs[tokenId][docType] = _hash;
    }

    function removeIpfsHash(uint tokenId, string memory docType) public onlyMinterBurner {
        ipfsHashs[tokenId][docType] = "";
    }

    function getIpfsHash(uint tokenId, string memory docType) public view returns (string memory) {
        return ipfsHashs[tokenId][docType];
    }

}

/**
* @title Proxiable
* @dev Etherland - EIP-1822 Proxiable contract implementation
* @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1822.md
*/
contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}


/**
 * @title Etherland NFT Assets
 * @author Mathieu Lecoq
 * september 3rd 2020 
 *
 * @dev Property
 * all rights are reserved to EtherLand ltd
 *
 * @dev deployed with compiler version 0.6.2
*/
contract Etherland is TradeableERC721Token, IpfsHashs, Proxiable {
    /**
    * @dev initialized state MUST remain set to false on Implementation Contract 
    */
    bool public initialized = false;

    /**
    * @dev event emitting when the `_baseTokenUri` is updated by owner
    */
    event BaseTokenUriUpdated(string newUri);

    /**
    * @dev Logic code implementation contact constructor
    * @dev MUST be called by deployer only if contract has not been initialized before
    */
    function init(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory baseURI,
        address _owner
    ) public {
        if (initialized != true) {
            initialized = true;

            TradeableERC721Token.init(_name, _symbol, _proxyRegistryAddress);

            _baseTokenURI = baseURI;

            // register the supported interfaces to conform to ERC721 via ERC165
            _registerInterface(_INTERFACE_ID_ERC165);
            _registerInterface(_INTERFACE_ID_ERC721_METADATA);
            _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
            _registerInterface(_INTERFACE_ID_ERC721);

            _transferOwnership(_owner);
        }
    }

    /**
    * @dev Retrieve all NFTs base token uri 
    */
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /**
    * @dev Set the base token uri for all NFTs
    */
    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
        emit BaseTokenUriUpdated(uri);
    }

    /**
    * @dev Retrieve the uri of a specific token 
    * @param _tokenId the id of the token to retrieve the uri of
    * @return computed uri string pointing to a specific _tokenId
    */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return Strings.strConcat(
            baseTokenURI(),
            Strings.uint2str(_tokenId)
        );
    }

    /**
    * @dev EIP-1822 feature
    * @dev Realize an update of the Etherland logic code 
    * @dev calls the proxy contract to update stored logic code contract address at keccak256("PROXIABLE")
    */
    function updateCode(address newCode) public onlyOwner {
        updateCodeAddress(newCode);
    }

    /**
    * @dev Mint a new token with document hash corresponding to an IPFS CID
    * @param _to address of the future owner of the token
    * @param docType string representing the type of document that is stored to IPFS (can be "pdf" or any other token related document)
    * @param _hash string representing the hash of a document with type equals to `docType`
    */
    function mintWithIpfsHash(address _to, string memory docType, string memory _hash) public onlyMinter {
        mintTo(_to);
        setIpfsHash(_currentTokenId, docType, _hash);
    }

}