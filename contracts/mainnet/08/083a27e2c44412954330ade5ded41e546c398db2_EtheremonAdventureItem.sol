pragma solidity ^0.4.23;


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
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
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

contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}

contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}

contract ERC721Receiver {
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;
    
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    
    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }


    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
    
        if (getApproved(_tokenId) != address(0) || _to != address(0)) {
            tokenApprovals[_tokenId] = _to;
            emit Approval(owner, _to, _tokenId);
        }
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }    

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }
    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }
    
    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }
    
    function _mint(address _to, uint256 _tokenId) internal {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }
    
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }


    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }
    
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }
    
    function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

contract ERC721Token is ERC721Basic, ERC721Enumerable, ERC721Metadata, ERC721BasicToken {
    string internal name_;
    string internal symbol_;

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


    constructor(string _name, string _symbol) public {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view returns (string) {
        return name_;
    }

    function symbol() public view returns (string) {
        return symbol_;
    }

    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply());
        return allTokens[_index];
    }
    

    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;

        ownedTokens[_from].length--;
        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }
    
    function _setTokenURI(uint256 _tokenId, string _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }

    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }


    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);

        // Clear metadata (if any)
        if (bytes(tokenURIs[_tokenId]).length != 0) {
            delete tokenURIs[_tokenId];
        }

        // Reorg all tokens array
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
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

contract EtheremonAdventureItem is ERC721Token("EtheremonAdventure", "EMOND"), BasicAccessControl {
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
    mapping (uint => uint[]) sites; // site class id => token id
    mapping (uint => Item) items; // token id => info
    
    modifier requireAdventureHandler {
        require(adventureHandler != address(0));
        _;        
    }
    
    function setAdventureHandler(address _adventureHandler) onlyModerators external {
        adventureHandler = _adventureHandler;
    }
    
    function setTokenURI(uint256 _tokenId, string _uri) onlyModerators external {
        _setTokenURI(_tokenId, _uri);
    }
    
    function spawnSite(uint _classId, uint _tokenId, address _owner) onlyModerators external {
        if (_owner == address(0)) revert();
        if (_classId > MAX_SITE_ID || _classId == 0 || _tokenId > MAX_SITE_TOKEN_ID || _tokenId == 0) revert();
        
        // can not spawn more than MAX_OWNER_PERS_SITE per site
        uint[] storage siteIds = sites[_classId];
        if (siteIds.length > MAX_OWNER_PERS_SITE)
            revert();
        
        Item storage item = items[_tokenId];
        if (item.classId != 0) revert(); // token existed
        item.classId = _classId;
        siteIds.push(_tokenId);
        
        _mint(_owner, _tokenId);
    }
    
    function spawnItem(uint _classId, uint _value, address _owner) onlyModerators external returns(uint) {
        if (_owner == address(0)) revert();
        if (_classId < MAX_SITE_ID) revert();
        
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
        if (_tokenId == 0 || tokenOwner[_tokenId] != msg.sender) revert();
        Item storage item = items[_tokenId];
        
        EtheremonAdventureHandler handler = EtheremonAdventureHandler(adventureHandler);
        handler.handleSingleItem(msg.sender, item.classId, item.value, _target, _param);
        
        _burn(msg.sender, _tokenId);
    }
    
    function useMultipleItem(uint _token1, uint _token2, uint _token3, uint _target, uint _param) isActive requireAdventureHandler public {
        if (_token1 > 0 && tokenOwner[_token1] != msg.sender) revert();
        if (_token2 > 0 && tokenOwner[_token2] != msg.sender) revert();
        if (_token3 > 0 && tokenOwner[_token3] != msg.sender) revert();
        
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
        value = item.classId;
    }
    
    function getSiteTokenId(uint _classId, uint _index) constant public returns(uint tokenId) {
        return sites[_classId][_index];
    }
    
    function getSiteTokenLength(uint _classId) constant public returns(uint length) {
        return sites[_classId].length;
    }
    
    function getSiteTokenIds(uint _classId) constant public returns(uint[]) {
        return sites[_classId];
    }
}