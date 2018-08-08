pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
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

interface ERC165 {
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract SupportsInterface is ERC165 {
    
    mapping(bytes4 => bool) internal supportedInterfaces;

    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
    }

    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }
}

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface ERC721Metadata {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC721TokenReceiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

contract NFToken is ERC721, SupportsInterface {

    using SafeMath for uint256;
    using AddressUtils for address;
    
    // A mapping from NFT ID to the address that owns it.
    mapping (uint256 => address) internal idToOwner;
    
    // Mapping from NFT ID to approved address.
    mapping (uint256 => address) internal idToApprovals;
    
    // Mapping from owner address to count of his tokens.
    mapping (address => uint256) internal ownerToNFTokenCount;
    
    // Mapping from owner address to mapping of operator addresses.
    mapping (address => mapping (address => bool)) internal ownerToOperators;
    
    /**
    * @dev Magic value of a smart contract that can recieve NFT.
    * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
    */
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }


    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || getApproved(_tokenId) == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0));
        _;
    }

    constructor() public {
        supportedInterfaces[0x80ac58cd] = true; // ERC721
    }


    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return ownerToNFTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }
    
    function transfer(address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);

        idToApprovals[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        require(_operator != address(0));
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view validNFToken(_tokenId) returns (address) {
        return idToApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        require(_owner != address(0));
        require(_operator != address(0));
        return ownerToOperators[_owner][_operator];
    }

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) internal canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (_to.isContract()) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _transfer(address _to, uint256 _tokenId) private {
        address from = idToOwner[_tokenId];
        clearApproval(_tokenId);
        removeNFToken(from, _tokenId);
        addNFToken(_to, _tokenId);
        emit Transfer(from, _to, _tokenId);
    }
   

    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        require(_tokenId != 0);
        require(idToOwner[_tokenId] == address(0));

        addNFToken(_to, _tokenId);

        emit Transfer(address(0), _to, _tokenId);
    }

    function _burn(address _owner, uint256 _tokenId) validNFToken(_tokenId) internal { 
        clearApproval(_tokenId);
        removeNFToken(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

    function clearApproval(uint256 _tokenId) private {
        if(idToApprovals[_tokenId] != 0) {
            delete idToApprovals[_tokenId];
        }
    }

    function removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        assert(ownerToNFTokenCount[_from] > 0);
        ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
        delete idToOwner[_tokenId];
    }

    function addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0));

        idToOwner[_tokenId] = _to;
        ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
    }
}


contract NFTokenEnumerable is NFToken, ERC721Enumerable {

    // Array of all NFT IDs.
    uint256[] internal tokens;

    // Mapping from token ID its index in global tokens array.
    mapping(uint256 => uint256) internal idToIndex;

    // Mapping from owner to list of owned NFT IDs.
    mapping(address => uint256[]) internal ownerToIds;

    // Mapping from NFT ID to its index in the owner tokens list.
    mapping(uint256 => uint256) internal idToOwnerIndex;

    constructor() public {
        supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
    }

    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);
        uint256 length = tokens.push(_tokenId);
        idToIndex[_tokenId] = length - 1;
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);
        assert(tokens.length > 0);

        uint256 tokenIndex = idToIndex[_tokenId];
        // Sanity check. This could be removed in the future.
        assert(tokens[tokenIndex] == _tokenId);
        uint256 lastTokenIndex = tokens.length - 1;
        uint256 lastToken = tokens[lastTokenIndex];

        tokens[tokenIndex] = lastToken;

        tokens.length--;
        // Consider adding a conditional check for the last token in order to save GAS.
        idToIndex[lastToken] = tokenIndex;
        idToIndex[_tokenId] = 0;
    }

    function removeNFToken(address _from, uint256 _tokenId) internal
    {
        super.removeNFToken(_from, _tokenId);
        assert(ownerToIds[_from].length > 0);

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;
        uint256 lastToken = ownerToIds[_from][lastTokenIndex];

        ownerToIds[_from][tokenToRemoveIndex] = lastToken;

        ownerToIds[_from].length--;
        // Consider adding a conditional check for the last token in order to save GAS.
        idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        idToOwnerIndex[_tokenId] = 0;
    }

    function addNFToken(address _to, uint256 _tokenId) internal {
        super.addNFToken(_to, _tokenId);

        uint256 length = ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = length - 1;
    }

    function totalSupply() external view returns (uint256) {
        return tokens.length;
    }

    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_index < tokens.length);
        // Sanity check. This could be removed in the future.
        assert(idToIndex[tokens[_index]] == _index);
        return tokens[_index];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

}

contract NFTStandard is NFTokenEnumerable, ERC721Metadata {
    string internal nftName;
    string internal nftSymbol;
    
    mapping (uint256 => string) internal idToUri;
    
    constructor(string _name, string _symbol) public {
        nftName = _name;
        nftSymbol = _symbol;
        supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
    }
    
    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);
        if (bytes(idToUri[_tokenId]).length != 0) {
        delete idToUri[_tokenId];
        }
    }
    
    function _setTokenUri(uint256 _tokenId, string _uri) validNFToken(_tokenId) internal {
        idToUri[_tokenId] = _uri;
    }
    
    function name() external view returns (string _name) {
        _name = nftName;
    }
    
    function symbol() external view returns (string _symbol) {
        _symbol = nftSymbol;
    }
    
    function tokenURI(uint256 _tokenId) validNFToken(_tokenId) external view returns (string) {
        return idToUri[_tokenId];
    }
}

contract BasicAccessControl {
    address public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }


    function AddModerator(address _newModerator) onlyOwner public {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }
    
    function RemoveModerator(address _oldModerator) onlyOwner public {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) onlyOwner public {
        isMaintaining = _isMaintaining;
    }
}

interface EtheremonAdventureHandler {
    function handleSingleItem(address _sender, uint _classId, uint _value, uint _target, uint _param) external;
    function handleMultipleItems(address _sender, uint _classId1, uint _classId2, uint _classId3, uint _target, uint _param) external;
}

contract EtheremonAdventureItem is NFTStandard("EtheremonAdventure", "EMOND"), BasicAccessControl {
    uint constant public MAX_OWNER_PERS_SITE = 10;
    uint constant public MAX_SITE_ID = 108;
    uint constant public MAX_SITE_TOKEN_ID = 1080;
    
    // smartcontract
    address public adventureHandler;
    
    // class sites: 1 -> 108
    // shard: 109 - 126
    // level, exp
    struct Item {
        uint classId;
        uint value;
    }
    
    uint public totalItem = MAX_SITE_TOKEN_ID;
    mapping (uint => Item) public items; // token id => info
    
    modifier requireAdventureHandler {
        require(adventureHandler != address(0));
        _;        
    }
    
    function setAdventureHandler(address _adventureHandler) onlyModerators external {
        adventureHandler = _adventureHandler;
    }
    
    function setTokenURI(uint256 _tokenId, string _uri) onlyModerators external {
        _setTokenUri(_tokenId, _uri);
    }
    
    function spawnSite(uint _classId, uint _tokenId, address _owner) onlyModerators external {
        if (_owner == address(0)) revert();
        if (_classId > MAX_SITE_ID || _classId == 0 || _tokenId > MAX_SITE_TOKEN_ID || _tokenId == 0) revert();
        
        Item storage item = items[_tokenId];
        if (item.classId != 0) revert(); // token existed
        item.classId = _classId;
        
        _mint(_owner, _tokenId);
    }
    
    function spawnItem(uint _classId, uint _value, address _owner) onlyModerators external returns(uint) {
        if (_owner == address(0)) revert();
        if (_classId <= MAX_SITE_ID) revert();
        
        totalItem += 1;
        Item storage item = items[totalItem];
        item.classId = _classId;
        item.value = _value;
        
        _mint(_owner, totalItem);
        return totalItem;
    }
    
    
    // public write 
    function useSingleItem(uint _tokenId, uint _target, uint _param) isActive requireAdventureHandler public {
        // check ownership
        if (_tokenId == 0 || idToOwner[_tokenId] != msg.sender) revert();
        Item storage item = items[_tokenId];
        
        EtheremonAdventureHandler handler = EtheremonAdventureHandler(adventureHandler);
        handler.handleSingleItem(msg.sender, item.classId, item.value, _target, _param);
        
        _burn(msg.sender, _tokenId);
    }
    
    function useMultipleItem(uint _token1, uint _token2, uint _token3, uint _target, uint _param) isActive requireAdventureHandler public {
        if (_token1 > 0 && idToOwner[_token1] != msg.sender) revert();
        if (_token2 > 0 && idToOwner[_token2] != msg.sender) revert();
        if (_token3 > 0 && idToOwner[_token3] != msg.sender) revert();
        
        Item storage item1 = items[_token1];
        Item storage item2 = items[_token2];
        Item storage item3 = items[_token3];
        
        EtheremonAdventureHandler handler = EtheremonAdventureHandler(adventureHandler);
        handler.handleMultipleItems(msg.sender, item1.classId, item2.classId, item3.classId, _target, _param);
        
        if (_token1 > 0) _burn(msg.sender, _token1);
        if (_token2 > 0) _burn(msg.sender, _token2);
        if (_token3 > 0) _burn(msg.sender, _token3);
    }
    
    
    // public read 
    function getItemInfo(uint _tokenId) constant public returns(uint classId, uint value) {
        Item storage item = items[_tokenId];
        classId = item.classId;
        value = item.value;
    }

}