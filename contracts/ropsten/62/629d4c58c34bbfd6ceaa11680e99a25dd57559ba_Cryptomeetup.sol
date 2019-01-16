pragma solidity ^0.4.23;

contract Config {
    uint256 internal increaseLimit1 = 0.02  ether;
    uint256 internal increaseLimit2 = 0.5  ether;
    uint256 internal increaseLimit3 = 2.0  ether;
    uint256 internal increaseLimit4 = 5.0  ether;  

    uint256 internal initPrice = 0.01 ether;

    uint256 internal period = 3600 * 24 * 30;

    uint256 internal devCut1 = 5;
    uint256 internal devCut2 = 4;
    uint256 internal devCut3 = 3;
    uint256 internal devCut4 = 2;
}

// tokenId 必须从1开始，否则新开一轮的时候有问题

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * Utility library of inline functions on addresses
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
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account&#39;s access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}


/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public;
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}


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
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes data) public returns (bytes4);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string);
    function symbol() external view returns (string);
    function tokenURI(uint256 tokenId) external view returns (string);
}


/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 is IERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *     bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
     */

    /**
     * @dev a mapping of interface id to whether or not it&#39;s supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor () internal {
        _registerInterface(_InterfaceId_ERC165);
    }

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
     *     bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
     *     bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
     *     bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
     */

    constructor () public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_InterfaceId_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
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
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

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
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
        // solium-disable-next-line arg-overflow
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Returns whether the specified token exists
     * @param tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
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
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        _addTokenTo(to, tokenId);
        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        _clearApproval(tokenId);
        _removeTokenFrom(owner, tokenId);
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
     * @dev Internal function to add a token ID to the list of a given address
     * Note that this function is left internal to make ERC721Enumerable possible, but is not
     * intended to be called by custom derived contracts: in particular, it emits no Transfer event.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenTo(address to, uint256 tokenId) internal {
        require(_tokenOwner[tokenId] == address(0));
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * Note that this function is left internal to make ERC721Enumerable possible, but is not
     * intended to be called by custom derived contracts: in particular, it emits no Transfer event,
     * and doesn&#39;t clear approvals.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _tokenOwner[tokenId] = address(0);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
    */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

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
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes _data) internal returns (bool) {
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
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;
    /**
     * 0x780e9d63 ===
     *     bytes4(keccak256(&#39;totalSupply()&#39;)) ^
     *     bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
     */

    /**
     * @dev Constructor function
     */
    constructor () public {
        // register the supported interface to conform to ERC721 via ERC165
        _registerInterface(_InterfaceId_ERC721Enumerable);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * This function is internal due to language limitations, see the note in ERC721.sol.
     * It is not intended to be called by custom derived contracts: in particular, it emits no Transfer event.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenTo(address to, uint256 tokenId) internal {
        super._addTokenTo(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * This function is internal due to language limitations, see the note in ERC721.sol.
     * It is not intended to be called by custom derived contracts: in particular, it emits no Transfer event,
     * and doesn&#39;t clear approvals.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFrom(address from, uint256 tokenId) internal {
        super._removeTokenFrom(from, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        // Since the token is being destroyed, we also clear its index
        // TODO(nventuro): 0 is still a valid index, so arguably this isnt really helpful, remove?
        _ownedTokensIndex[tokenId] = 0;
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
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * Deprecated, use _burn(uint256) instead
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Reorg all tokens array
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 lastToken = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastToken;
        _allTokens[lastTokenIndex] = 0;

        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
        _allTokensIndex[lastToken] = tokenIndex;
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
     * @dev Private function to add a token to this extension&#39;s ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 newOwnedTokensLength = _ownedTokens[to].push(tokenId);
        // No need to use SafeMath since the length after a push cannot be zero
        _ownedTokensIndex[tokenId] = newOwnedTokensLength - 1;
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
        uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token&#39;s index

        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going
        // to be zero. The swap operation will therefore have no effect, but the token _will_ be deleted during the
        // &#39;pop&#39; operation.

        // This also deletes the contents at the last position of the array
        _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn&#39;t been cleared: it still points to the old slot (now occcupied by
        // lasTokenId).
    }
}


contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    /**
     * 0x5b5e139f ===
     *     bytes4(keccak256(&#39;name()&#39;)) ^
     *     bytes4(keccak256(&#39;symbol()&#39;)) ^
     *     bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
     */

    /**
     * @dev Constructor function
     */
    constructor (string name, string symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721Metadata);
    }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token
     * Reverts if the token ID does not exist
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * Deprecated, use _burn(uint256) instead
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


/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
}


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
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


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @return true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


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


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
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


/**
 * @title ERC721Mintable
 * @dev ERC721 minting logic
 */
contract ERC721Mintable is ERC721, MinterRole {
    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param tokenId The token id to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 tokenId) internal onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}


contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


contract Cryptomeetup is ERC721Full, ERC721Pausable, ERC721Mintable, ERC721Holder, Config {
    mapping (uint256 => uint256) private priceOf;

    struct Global {
        uint256 begin;
        uint256 end;
        address lastone;
    }

    mapping(uint256 => Global) global; 
    uint256 indexOfGlobal;

    event Bought(uint256 indexed _itemId, address indexed _owner, uint256 _price);
    event Sold(uint256 indexed _itemId, address indexed _owner, uint256 _price);    

    constructor() ERC721Metadata("cryptomeetup", "CMU") public {
    }

    function transferERC721Token(address contractaddr, uint256 tokenId) public onlyMinter {
        require(contractaddr.isContract());
        IERC721 _tokenobj = IERC721(contractaddr);
        _tokenobj.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function transferERC20Token(address contractaddr) public onlyMinter {
        require(contractaddr.isContract());
        IERC20 _tokenobj = IERC20(contractaddr);
        uint256 _amount = _tokenobj.balanceOf(address(this));
        _tokenobj.transfer(msg.sender, _amount);
    }

    function mint(address to, uint256 tokenId, uint256 tokenprice) public onlyMinter returns (bool) {
        mint(to, tokenId);
        priceOf[tokenId] = tokenprice;
        return true;
    }

    function init(uint256 l, uint256 r, uint256 price) public onlyMinter {
        for(uint256 i = l; i < r; i++) {
            mint(msg.sender, i, price);
        }

        indexOfGlobal = 1;
        global[indexOfGlobal].begin = now;
        global[indexOfGlobal].end = now.add(period);
        global[indexOfGlobal].lastone = address(0);
    }

    function calculateDevCut(uint256 price) public view returns (uint256 _devCut) {
        if (price < increaseLimit1) {
            return price.mul(devCut1).div(100); // 5%
        } else if (price < increaseLimit2) {
            return price.mul(devCut2).div(100); // 4%
        } else if (price < increaseLimit3) {
            return price.mul(devCut3).div(100); // 3%
        } else if (price < increaseLimit4) {
            return price.mul(devCut3).div(100); // 3%
        } else {
            return price.mul(devCut4).div(100); // 2%
        }
    }

    function calculateNextPrice(uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price < increaseLimit1) {
            return _price.mul(200).div(95);
        } else if (_price < increaseLimit2) {
            return _price.mul(135).div(96);
        } else if (_price < increaseLimit3) {
            return _price.mul(125).div(97);
        } else if (_price < increaseLimit4) {
            return _price.mul(117).div(97);
        } else {
            return _price.mul(115).div(98);
        }
    }  

    function nextPriceOf(uint256 tokenID) public view returns (uint256) {
        return calculateNextPrice(priceOfToken(tokenID));
    }    

    function buy(uint256 tokenId) payable public {
        require(priceOfToken(tokenId) > 0);
        require(ownerOf(tokenId) != address(0));        

        if(global[indexOfGlobal].end <= now) {
            newGlobal();
            buyinternal(tokenId, msg.sender, msg.value);
        } else {
            buyinternal(tokenId, msg.sender, msg.value);
        }
    }

    function buyinternal(uint256 tokenId, address payer, uint256 amount)  internal {
        require(priceOfToken(tokenId) > 0);
        require(ownerOf(tokenId) != address(0));
        require(amount >= priceOfToken(tokenId));
        require(ownerOf(tokenId) != payer);
        require(!payer.isContract());
        require(payer != address(0));
        require(global[indexOfGlobal].end > now);

        address oldOwner = ownerOf(tokenId);
        address newOwner = payer;
        uint256 price = priceOfToken(tokenId);
        uint256 excess = amount.sub(price);

        _transferFrom(oldOwner, newOwner, tokenId);
        priceOf[tokenId] = nextPriceOf(tokenId);

        emit Bought(tokenId, newOwner, price);
        emit Sold(tokenId, oldOwner, price);

        // Devevloper&#39;s cut which is left in contract and accesed by
        // `withdrawAll` and `withdrawAmountTo` methods.
        uint256 devCut = calculateDevCut(price);

        // Transfer payment to old owner minus the developer&#39;s cut.
        oldOwner.transfer(price.sub(devCut));

        if (excess > 0) {
            newOwner.transfer(excess);
        }

    }

    function newGlobal() internal {
        for (uint256 i = 1; i <= _allTokens.length; i++) {
            priceOf[i] = initPrice;
        }
        indexOfGlobal++;
        global[indexOfGlobal].begin = now;
        global[indexOfGlobal].end = now.add(period);
        global[indexOfGlobal].lastone = address(0);
    }


    /* Withdraw */
    /*
        NOTICE: These functions withdraw the developer&#39;s cut which is left
        in the contract by `buy`. User funds are immediately sent to the old
        owner in `buy`, no user funds are left in the contract.
    */
    function withdrawAll() onlyMinter public {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawAmount(uint256 _amount) onlyMinter public {
        msg.sender.transfer(_amount);
    }

    function priceOfToken(uint256 tokenID) public view returns (uint256) {
        return priceOf[tokenID];
    }    

    function allOf (uint256 _itemId) external view returns (address _owner, uint256 _price, uint256 _nextPrice) {
        return (ownerOf(_itemId), priceOfToken(_itemId), nextPriceOf(_itemId));
    }

    function getIndexOfGlobal() public view returns(uint256) {
        return indexOfGlobal;
    }

    function getGlobal(uint256 index) public view returns(uint256 _begin, uint256 _end, address _lastone) {
        require(index <= indexOfGlobal);

        _begin = global[index].begin;
        _end = global[index].end;
        _lastone = global[index].lastone;
    }

    function getNowGlobal() public view returns(uint256, uint256, address) {
        getGlobal(indexOfGlobal);
    }
}