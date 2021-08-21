/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public  {
    owner = msg.sender;
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


contract ERC721Receiver {

  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


contract ERC721Holder is ERC721Receiver {
  function onERC721Received(address, uint256, bytes) public returns(bytes4) {
    return ERC721_RECEIVED;
  }
}

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
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
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

contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

library AddressUtils {

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

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

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }


  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }


  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

contract ERC721Token is ERC721, ERC721BasicToken {
  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping (address => uint256[]) internal ownedTokens;

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


  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
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


library Integers {

    function parseInt(string _value)
        public
        returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(_bytesValue[i] >= 48 && _bytesValue[i] <= 57);
            _ret += (uint(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }


    function toString(uint _base)
        internal
        returns (string) {

        if  (_base==0){
            return "0";
        }

        bytes memory _tmp = new bytes(32);
        uint i;
        for(i = 0;_base > 0;i++) {
            _tmp[i] = byte((_base % 10) + 48);
            _base /= 10;
        }
        bytes memory _real = new bytes(i--);
        for(uint j = 0; j < _real.length; j++) {
            _real[j] = _tmp[i--];
        }
        return string(_real);
    }


    function toByte(uint8 _base)
        public
        returns (byte _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            mstore8(m_alloc, _base)
            _ret := mload(m_alloc)
        }
    }

    function toBytes(uint _base)
        internal
        returns (bytes _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            _ret := mload(m_alloc)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _base)
        }
    }
}


library Strings {

    function concat(string _base, string _value)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i = 0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }


    function indexOf(string _base, string _value)
        internal
        returns (int) {
        return _indexOf(_base, _value, 0);
    }


    function _indexOf(string _base, string _value, uint _offset)
        internal
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for(uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }


    function length(string _base)
        internal
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }


    function substring(string _base, int _length)
        internal
        returns (string) {
        return _substring(_base, _length, 0);
    }

    function _substring(string _base, int _length, int _offset)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset+_length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for(uint i = uint(_offset); i < uint(_offset+_length); i++) {
          _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    function split(string _base, string _value)
        internal
        returns (string[] storage splitArr) {
        bytes memory _baseBytes = bytes(_base);
        uint _offset = 0;

        while(_offset < _baseBytes.length-1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit)-_offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for(uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr.push(string(_tmpBytes));
        }
        return splitArr;
    }

    function compareTo(string _base, string _value)
        internal
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for(uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }


    function compareToIgnoreCase(string _base, string _value)
        internal
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for(uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
                _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    function upper(string _base)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }


    function lower(string _base)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }


    function _upper(bytes1 _b1)
        private
        constant
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1)-32);
        }

        return _b1;
    }


    function _lower(bytes1 _b1)
        private
        constant
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1)+32);
        }

        return _b1;
    }
}

pragma solidity ^0.4.24 ;

interface IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Game is Ownable, ERC721Token("Game" ,"GAME"), ERC721Holder {
    using Strings for string;
    using Integers for uint;

    struct Characters {
        string ipfsHash;
        address publisher;
        string name;
        string description;
        uint power;
        uint amountFight;
    }

    struct Enemies {
        uint id;
        string ipfsHash;
        string name;
        uint power;
        uint256 reward;
    }

    IERC20 public addressPaymentToken;

    uint128 public feeToOwner = 3;
    uint128 public pricePower = 100;

    uint public initFight = 55;
    uint public addFightAmount = 10;

    uint256 public priceCharacter = 15000000000000000000;

    mapping (address => uint) public depositedTokens;

    Characters[] public characters;
    Enemies[] public enemies;

    mapping (string => uint256) ipfsHashToTokenId;

    mapping (address => uint256) internal publishedTokensCount;
    mapping (address => uint256[]) internal publishedTokens;

    mapping(address => mapping (uint256 => uint256)) internal publishedTokensIndex;

    struct SellingItem {
        address seller;
        uint256 price;
        string ipfsHash;
        string name;
        string description;
    }

    mapping (uint256 => SellingItem) public tokenIdToSellingItem;

    uint128 public createNFTFee = 0.00001 ether;
    uint128 public publisherCut = 100; 

    uint256 public levelChar1 = 10000000000000000000;
    uint256 public levelChar2 = 15000000000000000000;
    uint256 public levelChar3 = 18000000000000000000;
    uint256 public levelChar4 = 21000000000000000000;
    uint256 public levelChar5 = 23000000000000000000;
    uint256 public levelChar6 = 28000000000000000000;
    uint256 public levelChar7 = 33000000000000000000;
    uint256 public levelChar8 = 40000000000000000000;

    uint256 public powerChar1 = 2700000000000000000;
    uint256 public powerChar2 = 4500000000000000000;
    uint256 public powerChar3 = 6300000000000000000;
    uint256 public powerChar4 = 8100000000000000000;
    uint256 public powerChar5 = 9000000000000000000;
    uint256 public powerChar6 = 11000000000000000000;
    uint256 public powerChar7 = 18000000000000000000;
    uint256 public powerChar8 = 27000000000000000000;

    /*** Modifier ***/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*** Owner Action ***/
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function withdrawToken(uint256 _amount) public onlyOwner {
        require(addressPaymentToken.transferFrom(address(this), msg.sender, _amount), "Transfer error.");
    }

    function setLevelsAdd(uint256 _levelChar1, uint256 _levelChar2, uint256 _levelChar3, uint256 _levelChar4, uint256 _levelChar5, uint256 _levelChar6, uint256 _levelChar7, uint256 _levelChar8) public onlyOwner {
        levelChar1 = _levelChar1;
        levelChar2 = _levelChar2;
        levelChar3 = _levelChar3;
        levelChar4 = _levelChar4;
        levelChar5 = _levelChar5;
        levelChar6 = _levelChar6;
        levelChar7 = _levelChar7;
        levelChar8 = _levelChar8;
    }

    function setPowerAdd(uint256 _powerChar1, uint256 _powerChar2, uint256 _powerChar3, uint256 _powerChar4, uint256 _powerChar5, uint256 _powerChar6, uint256 _powerChar7, uint256 _powerChar8) public onlyOwner {
        powerChar1 = _powerChar1;
        powerChar2 = _powerChar2;
        powerChar3 = _powerChar3;
        powerChar4 = _powerChar4;
        powerChar5 = _powerChar5;
        powerChar6 = _powerChar6;
        powerChar7 = _powerChar7;
        powerChar8 = _powerChar8;
    }

    function setEnemyReward(uint256 _value, uint256 _enemyId) public onlyOwner {
        enemies[_enemyId].reward = _value;
    }

    function setAddressPaymentToken(address _addressPaymentToken) public onlyOwner {
        addressPaymentToken = IERC20(_addressPaymentToken);
    }

    function setInitFight(uint _value) public onlyOwner {
        initFight = _value;
    }

    function setAddFightAmount(uint _value) public onlyOwner {
        addFightAmount = _value;
    }

    function setPriceCharacter(uint256 _priceCharacter) public onlyOwner {
        priceCharacter = _priceCharacter;
    }

    function setCreateNFTFee(uint128 _fee) public onlyOwner {
        createNFTFee = _fee;
    }

    function setPublisherCut(uint128 _cut) public onlyOwner {
        require(_cut > 0 && _cut < 10000);
        publisherCut = _cut;
    }

    function getIpfsHashToTokenId(string _string) public view returns (uint256){
        return ipfsHashToTokenId[_string];
    }

    function getOwnedTokens(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }

    function getAllTokens() public view returns (uint256[]) {
        return allTokens;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function publishedCountOf(address _publisher) public view returns (uint256) {
        return publishedTokensCount[_publisher];
    }

    function publishedTokenOfOwnerByIndex(address _publisher, uint256 _index) public view returns (uint256) {
        require(_index < publishedCountOf(_publisher));
        return publishedTokens[_publisher][_index];
    }

    function getPublishedTokens(address _publisher) public view returns (uint256[]) {
        return publishedTokens[_publisher];
    }

    function mintCharacter(string _ipfsHash, string _name, string _description) public {
        require(ipfsHashToTokenId[_ipfsHash] == 0);

        require(addressPaymentToken.transferFrom(msg.sender, address(this), priceCharacter), "Transfer for mint error.");

        Characters memory _digitalNFT = Characters({
            ipfsHash: _ipfsHash, 
            publisher: msg.sender, 
            name: _name, 
            description: _description,
            power: 200,
            amountFight: initFight
        });

        uint256 newDigitalNFTId = characters.push(_digitalNFT) - 1;
        ipfsHashToTokenId[_ipfsHash] = newDigitalNFTId;
        _mint(msg.sender, newDigitalNFTId);

        publishedTokensCount[msg.sender]++;
        uint256 length = publishedTokens[msg.sender].length;
        publishedTokens[msg.sender].push(newDigitalNFTId);
        publishedTokensIndex[msg.sender][newDigitalNFTId] = length;        
    }

    function createEnemy(string _ipfsHash, string _name, uint _power, uint256 _reward) public onlyOwner {
      uint leng = enemies.length -1;
        Enemies memory _enemy = Enemies({
            id: leng, 
            ipfsHash: _ipfsHash, 
            name: _name,
            power: _power,
            reward: _reward
        });

        enemies.push(_enemy) - 1;
    }

    function addNFTSellingItem(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        require(tokenIdToSellingItem[_tokenId].seller == address(0));
        SellingItem memory _sellingItem = SellingItem(
            msg.sender, 
            uint256(_price), 
            characters[_tokenId].ipfsHash, 
            characters[_tokenId].name, 
            characters[_tokenId].description
        );
        tokenIdToSellingItem[_tokenId] = _sellingItem;
        approve(address(this), _tokenId);
        safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function cancelNFTSellingItem(uint256 _tokenId) public {
        require(tokenIdToSellingItem[_tokenId].seller == msg.sender);
        this.safeTransferFrom(address(this), tokenIdToSellingItem[_tokenId].seller, _tokenId);
        delete tokenIdToSellingItem[_tokenId];
    }

    function purchaseCharacter(uint256 _tokenId, uint256 _amount) public {
        uint256 priceItemEther = tokenIdToSellingItem[_tokenId].price;
        address sellerAddress = tokenIdToSellingItem[_tokenId].seller;

        require(sellerAddress != address(0));
        require(sellerAddress != msg.sender);
        require(priceItemEther == _amount);

        uint256 feeToOwnerItem = priceItemEther.mul(feeToOwner).div(100);
        uint256 priceItemEtherFee = priceItemEther.sub(feeToOwnerItem);

        require(addressPaymentToken.transferFrom(msg.sender, sellerAddress, priceItemEtherFee), "Transfer error.");
        require(addressPaymentToken.transferFrom(msg.sender, address(this), feeToOwnerItem), "Transfer error.");

        SellingItem memory sellingItem = tokenIdToSellingItem[_tokenId];

        if (sellingItem.price > 0) {
            uint256 actualPublisherCut = _computePublisherCut(sellingItem.price);
            require(addressPaymentToken.transfer(characters[_tokenId].publisher, actualPublisherCut), "Transfer error.");
        }

        delete tokenIdToSellingItem[_tokenId];
        this.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function addPower(uint256 _tokenId) public onlyOwnerOf(_tokenId) returns (bool){
        uint powerC = characters[_tokenId].power;

        if(powerC == 200){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar1), "Transfer error.");
            characters[_tokenId].power = 300;
            return true;
        }

        if(powerC == 300){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar2), "Transfer error.");
            characters[_tokenId].power = 400;
            return true;
        }

        if(powerC == 400){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar3), "Transfer error.");
            characters[_tokenId].power = 500;
            return true;
        }

        if(powerC == 500){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar4), "Transfer error.");
            characters[_tokenId].power = 600;
            return true;
        }

        if(powerC == 600){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar5), "Transfer error.");
            characters[_tokenId].power = 700;
            return true;
        }

        if(powerC == 700){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar6), "Transfer error.");
            characters[_tokenId].power = 800;
            return true;
        }

        if(powerC== 800){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar7), "Transfer error.");
            characters[_tokenId].power = 900;
            return true;
        }

        if(powerC == 900){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), levelChar8), "Transfer error.");
            characters[_tokenId].power = 10000;
            return true;
        }

        return false;
    }

    function addFight(uint256 _tokenId) public onlyOwnerOf(_tokenId) returns (bool){
        uint powerC = characters[_tokenId].power;

        if(powerC == 200){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 300){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC== 400){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 500){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 600){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;           
        }

        if(powerC == 700){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 800){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        if(powerC == 900){
            require(addressPaymentToken.transferFrom(msg.sender, address(this), powerChar1), "Transfer error.");
            characters[_tokenId].amountFight = characters[_tokenId].amountFight + addFightAmount;
            return true;
        }

        return false;
    }

    function fight(uint256 _tokenId, uint _enemyId) public onlyOwnerOf(_tokenId) returns (string) {
        string memory msgReturn = "Lost!";
        uint amountFight;

        amountFight = characters[_tokenId].amountFight;

        require(amountFight >= 1, "Amount of fight exceeded.");
        require(characters[_tokenId].power >= enemies[_enemyId].power, "Weak character.");

        if(characters[_tokenId].power >= enemies[_enemyId].power) {
            require(addressPaymentToken.transfer(msg.sender, enemies[_enemyId].reward), "Transfer reward error.");

            characters[_tokenId].amountFight = characters[_tokenId].amountFight -1;

            msgReturn = "win";
            return msgReturn;
        }

        return msgReturn;
    }

    /*** Tools ***/
    function _computePublisherCut(uint256 _price) internal view returns (uint) {
        return _price.mul(publisherCut).div(10000);
    }

}