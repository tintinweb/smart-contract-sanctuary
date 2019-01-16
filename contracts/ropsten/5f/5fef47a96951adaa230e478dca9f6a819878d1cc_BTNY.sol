pragma solidity ^0.4.24;

interface ERC721 {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    external;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

interface ERC721TokenReceiver {
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    external
    returns(bytes4);
}

interface ERC721Enumerable {
  function totalSupply()
    external
    view
    returns (uint256);

  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256);

  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256);
}

interface ERC721Metadata {
  function name()
    external
    view
    returns (string _name);

  function symbol()
    external
    view
    returns (string _symbol);

  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string, string, string, uint256);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

interface ERC165 {
  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool);

}

contract SupportsInterface is
  ERC165
{
  mapping(bytes4 => bool) internal supportedInterfaces;

  constructor()
    public
  {
    supportedInterfaces[0x01ffc9a7] = true; // ERC165
  }

  function supportsInterface(
    bytes4 _interfaceID
  )
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceID];
  }

}

contract NFToken is
  ERC721,
  SupportsInterface
{
  using SafeMath for uint256;
  using AddressUtils for address;

  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApprovals;
  mapping (address => uint256) internal ownerToNFTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;
  bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  modifier canOperate(
    uint256 _tokenId
  ) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
    _;
  }

  modifier canTransfer(
    uint256 _tokenId
  ) {
    address tokenOwner = idToOwner[_tokenId];
    require(
      tokenOwner == msg.sender
      || getApproved(_tokenId) == msg.sender
      || ownerToOperators[tokenOwner][msg.sender]
    );

    _;
  }

  modifier validNFToken(
    uint256 _tokenId
  ) {
    require(idToOwner[_tokenId] != address(0));
    _;
  }

  constructor()
    public
  {
    supportedInterfaces[0x80ac58cd] = true; // ERC721
  }

  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256)
  {
    require(_owner != address(0));
    return ownerToNFTokenCount[_owner];
  }

  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address _owner)
  {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0));
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    external
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
  {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);
  }

  function approve(
    address _approved,
    uint256 _tokenId
  )
    external
    canOperate(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner);

    idToApprovals[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }

  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external
  {
    require(_operator != address(0));
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function getApproved(
    uint256 _tokenId
  )
    public
    view
    validNFToken(_tokenId)
    returns (address)
  {
    return idToApprovals[_tokenId];
  }

  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool)
  {
    require(_owner != address(0));
    require(_operator != address(0));
    return ownerToOperators[_owner][_operator];
  }

  function _safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    canTransfer(_tokenId)
    validNFToken(_tokenId)
  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from);
    require(_to != address(0));

    _transfer(_to, _tokenId);

    if (_to.isContract()) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == MAGIC_ON_ERC721_RECEIVED);
    }
  }

  function _transfer(
    address _to,
    uint256 _tokenId
  )
    private
  {
    address from = idToOwner[_tokenId];
    clearApproval(_tokenId);

    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);

    emit Transfer(from, _to, _tokenId);
  }

  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(_to != address(0));
    require(_tokenId != 0);
    require(idToOwner[_tokenId] == address(0));

    _addNFToken(_to, _tokenId);

    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn(
    address _owner,
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    internal
  {
    clearApproval(_tokenId);
    _removeNFToken(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  function clearApproval(
    uint256 _tokenId
  )
    private
  {
    if(idToApprovals[_tokenId] != 0)
    {
      delete idToApprovals[_tokenId];
    }
  }

  function _removeNFToken(
    address _from,
    uint256 _tokenId
  )
   internal
  {
    require(idToOwner[_tokenId] == _from);
    assert(ownerToNFTokenCount[_from] > 0);
    ownerToNFTokenCount[_from] = ownerToNFTokenCount[_from] - 1;
    delete idToOwner[_tokenId];
  }

  function _addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    require(idToOwner[_tokenId] == address(0));

    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to] = ownerToNFTokenCount[_to].add(1);
  }
}

contract NFTokenEnumerable is
  NFToken,
  ERC721Enumerable
{
  uint256[] internal tokens;
  mapping(uint256 => uint256) internal idToIndex;
  mapping(address => uint256[]) internal ownerToIds;
  mapping(uint256 => uint256) internal idToOwnerIndex;
  constructor()
    public
  {
    supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
  }

  function _mint(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    super._mint(_to, _tokenId);
    uint256 length = tokens.push(_tokenId);
    idToIndex[_tokenId] = length - 1;
  }

  function _burn(
    address _owner,
    uint256 _tokenId
  )
    internal
  {
    super._burn(_owner, _tokenId);
    assert(tokens.length > 0);

    uint256 tokenIndex = idToIndex[_tokenId];
    // Sanity check. This could be removed in the future.
    assert(tokens[tokenIndex] == _tokenId);
    uint256 lastTokenIndex = tokens.length - 1;
    uint256 lastToken = tokens[lastTokenIndex];

    tokens[tokenIndex] = lastToken;

    tokens.length--;
    idToIndex[lastToken] = tokenIndex;
    idToIndex[_tokenId] = 0;
  }

  function removeNFToken(
    address _from,
    uint256 _tokenId
  )
   internal
  {
    super._removeNFToken(_from, _tokenId);
    assert(ownerToIds[_from].length > 0);

    uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
    uint256 lastTokenIndex = ownerToIds[_from].length - 1;
    uint256 lastToken = ownerToIds[_from][lastTokenIndex];

    ownerToIds[_from][tokenToRemoveIndex] = lastToken;

    ownerToIds[_from].length--;
    idToOwnerIndex[lastToken] = tokenToRemoveIndex;
    idToOwnerIndex[_tokenId] = 0;
  }

  function addNFToken(
    address _to,
    uint256 _tokenId
  )
    internal
  {
    super._addNFToken(_to, _tokenId);

    uint256 length = ownerToIds[_to].push(_tokenId);
    idToOwnerIndex[_tokenId] = length - 1;
  }

  function totalSupply()
    external
    view
    returns (uint256)
  {
    return tokens.length;
  }

  function tokenByIndex(
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < tokens.length);
    assert(idToIndex[tokens[_index]] == _index);
    return tokens[_index];
  }

  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    external
    view
    returns (uint256)
  {
    require(_index < ownerToIds[_owner].length);
    return ownerToIds[_owner][_index];
  }
}

contract NFTokenMetadata is
  NFToken,
  ERC721Metadata
{
  struct Character {
    string uri;
    string chtype;
    string name;
    uint256 honey;
  }

  string internal nftName = "Bitney";
  string internal nftSymbol = "BTNY";
  mapping (uint256 => Character) internal idToUri;

  constructor()
    public
  {
    supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
  }

  function _setTokenUri(
    uint256 _tokenId,
    string _uri,
    string _chtype,
    string _name,
    uint256 _honey)
    validNFToken(_tokenId)
    internal
  {
    idToUri[_tokenId] = Character(_uri, _chtype, _name, _honey);
  }

  function name()
    external
    view
    returns (string _name)
  {
    _name = nftName;
  }

  function symbol()
    external
    view
    returns (string _symbol)
  {
    _symbol = nftSymbol;
  }

  function tokenURI(
    uint256 _tokenId
  )
    validNFToken(_tokenId)
    external
    view
    returns (string, string, string, uint256)
  {
    Character memory character = idToUri[_tokenId];
    return (character.uri, character.chtype, character.name, character.honey);
  }
}

contract BTNY is NFTokenMetadata, NFTokenEnumerable {
  function mint(address _to, uint256 _tokenId)external
  {
    super._mint(_to, _tokenId);
  }

  function burn(address _owner, uint256 _tokenId) external
  {
    super._burn(_owner, _tokenId);
  }

  function removeNFBTNY(address _from, uint256 _tokenId) external
  {
    super.removeNFToken(_from, _tokenId);
  }

  function addNFBTNY(address _to, uint256 _tokenId) external
  {
    super.addNFToken(_to, _tokenId);
  }

  function setTokenUri(uint256 _tokenId, string _uri, string _chtype, string _name, uint256 _honey) external
  {
    super._setTokenUri(_tokenId, _uri, _chtype, _name, _honey);
  }
}