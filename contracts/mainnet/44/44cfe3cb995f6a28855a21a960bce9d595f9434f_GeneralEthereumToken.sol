pragma solidity ^0.4.25;




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {


    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }


        c = a * b;
        assert(c / a == b);
        return c;
    }


    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }


    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}




/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {


    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }


}




/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;


    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    * after a `safetransfer`. This function MAY throw to revert and reject the
    * transfer. This function MUST use 50,000 gas or less. Return of other
    * than the magic value MUST result in the transaction being reverted.
    * Note: the contract address is always the message sender.
    * @param _from The sending address
    * @param _tokenId The NFT identifier which is being transfered
    * @param _data Additional data with no specified format
    * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    */
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {


    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}




/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);


    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);


    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);


    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;
}




/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
    function tokenByIndex(uint256 _index) public view returns (uint256);
}




/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}




/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {


}




contract ERC721Holder is ERC721Receiver {
    function onERC721Received(address, uint256, bytes) public returns(bytes4) {
        return ERC721_RECEIVED;
    }
}




/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {
    bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
     */


    /**
     * @dev a mapping of interface id to whether or not it&#39;s supported
     */
    mapping(bytes4 => bool) internal supportedInterfaces;


    /**
     * @dev A contract implementing SupportsInterfaceWithLookup
     * implement ERC165 itself
     */
    constructor() public {
        _registerInterface(InterfaceId_ERC165);
    }


    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool) {
        return supportedInterfaces[_interfaceId];
    }


    /**
     * @dev private method for registering an interface
     */
    function _registerInterface(bytes4 _interfaceId) internal {
        require(_interfaceId != 0xffffffff);
        supportedInterfaces[_interfaceId] = true;
    }
}




/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {


    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
     *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
     *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
     *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
     */


    bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
    /*
     * 0x4f558e79 ===
     *   bytes4(keccak256(&#39;exists(uint256)&#39;))
     */


    using SafeMath for uint256;
    using AddressUtils for address;


    // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;


    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;


    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;


    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;


    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;


    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }


    /**
     * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
     * @param _tokenId uint256 ID of the token to validate
     */
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }


    constructor() public {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721);
        _registerInterface(InterfaceId_ERC721Exists);
    }


    /**
     * @dev Gets the balance of the specified address
     * @param _owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }


    /**
     * @dev Gets the owner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }


    /**
     * @dev Returns whether the specified token exists
     * @param _tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }


    /**
     * @dev Approves another address to transfer the given token ID
     * @dev The zero address indicates there is no approved address.
     * @dev There can only be one approved address per token at a given time.
     * @dev Can only be called by the token owner or an approved operator.
     * @param _to address to be approved for the given token ID
     * @param _tokenId uint256 ID of the token to be approved
     */
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));


        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }


    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }


    /**
     * @dev Sets or unsets the approval of a given operator
     * @dev An operator is allowed to transfer all tokens of the sender on their behalf
     * @param _to operator address to set the approval
     * @param _approved representing the status of the approval to be set
     */
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }


    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param _owner owner address which you want to query the approval of
     * @param _operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }


    /**
     * @dev Transfers the ownership of a given token ID to another address
     * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));


        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);


        emit Transfer(_from, _to, _tokenId);
    }


    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }


    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * @dev If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
     *  the transfer is reverted.
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }


    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *  is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
            _spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender)
        );
    }


    /**
     * @dev Internal function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }


    /**
     * @dev Internal function to clear current approval of a given token ID
     * @dev Reverts if the given address is not indeed the owner of the token
     * @param _owner owner of the token
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }


    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }


    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }


    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }


        bytes4 retval = ERC721Receiver(_to).onERC721Received(
        _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 contract Ownable {
     address public owner;
     address public pendingOwner;
     address public manager;


     event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     /**
     * @dev Throws if called by any account other than the owner.
     */
     modifier onlyOwner() {
         require(msg.sender == owner);
         _;
     }


     /**
      * @dev Modifier throws if called by any account other than the manager.
      */
     modifier onlyManager() {
         require(msg.sender == manager);
         _;
     }


     /**
      * @dev Modifier throws if called by any account other than the pendingOwner.
      */
     modifier onlyPendingOwner() {
         require(msg.sender == pendingOwner);
         _;
     }


     constructor() public {
         owner = msg.sender;
     }


     /**
      * @dev Allows the current owner to set the pendingOwner address.
      * @param newOwner The address to transfer ownership to.
      */
     function transferOwnership(address newOwner) public onlyOwner {
         pendingOwner = newOwner;
     }


     /**
      * @dev Allows the pendingOwner address to finalize the transfer.
      */
     function claimOwnership() public onlyPendingOwner {
         emit OwnershipTransferred(owner, pendingOwner);
         owner = pendingOwner;
         pendingOwner = address(0);
     }


     /**
      * @dev Sets the manager address.
      * @param _manager The manager address.
      */
     function setManager(address _manager) public onlyOwner {
         require(_manager != address(0));
         manager = _manager;
     }


 }






/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract GeneralEthereumToken is SupportsInterfaceWithLookup, ERC721, ERC721BasicToken, Ownable {


    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
    /**
     * 0x780e9d63 ===
     *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
     *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
     *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
     */


    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    /**
     * 0x5b5e139f ===
     *   bytes4(keccak256(&#39;name()&#39;)) ^
     *   bytes4(keccak256(&#39;symbol()&#39;)) ^
     *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
     */


    // Token name
    string public name_ = "GeneralEthereumToken";


    // Token symbol
    string public symbol_ = "GET";
    
    uint public tokenIDCount = 0;


    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;


    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;


    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;


    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;


    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;


    struct Data{
        string information;
        string URL;
    }
    
    mapping(uint256 => Data) internal tokenData;
    /**
     * @dev Constructor function
     */
    constructor() public {




        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(InterfaceId_ERC721Enumerable);
        _registerInterface(InterfaceId_ERC721Metadata);
    }


    /**
     * @dev External function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to address the beneficiary that will own the minted token
     */
    function mint(address _to) external onlyManager {
        _mint(_to, tokenIDCount++);
    }


    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view returns (string) {
        return name_;
    }


    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view returns (string) {
        return symbol_;
    }


    function arrayOfTokensByAddress(address _holder) public view returns(uint256[]) {
        return ownedTokens[_holder];
    }


    /**
     * @dev Returns an URI for a given token ID
     * @dev Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
    }


    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param _owner address owning the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }


    /**
     * @dev Gets the total amount of tokens stored by the contract
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }


    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * @dev Reverts if the index is greater or equal to the total number of tokens
     * @param _index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return allTokens[_index];
    }


    /**
     * @dev Internal function to set the token URI for a given token
     * @dev Reverts if the token ID does not exist
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }


    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }


    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);


        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];


        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are
        // going to be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are
        // first swapping the lastToken to the first position, and then dropping the element placed in the last
        // position of the list


        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }


    /**
     * @dev Internal function to mint a new token
     * @dev Reverts if the given token ID already exists
     * @param _to address the beneficiary that will own the minted token
     */
    function _mint(address _to, uint256 _id) internal {
        allTokens.push(_id);
        allTokensIndex[_id] = _id;
        super._mint(_to, _id);
    }
    
    function addTokenData(uint _tokenId, string _information, string _URL) public {
            require(ownerOf(_tokenId) == msg.sender);
            tokenData[_tokenId].information = _information;
            tokenData[_tokenId].URL = _URL;


        
    }
    
    function getTokenData(uint _tokenId) public view returns(string Liscence, string URL){
        require(exists(_tokenId));
        Liscence = tokenData[_tokenId].information;
        URL = tokenData[_tokenId].URL;
    }
    
    function() payable{
        require(msg.value > 0.16 ether);
        _mint(msg.sender, tokenIDCount++);
    }
    
    function withdraw() public onlyManager{
        require(0.5 ether > 0);
        manager.transfer(0.5 ether);
    }
}