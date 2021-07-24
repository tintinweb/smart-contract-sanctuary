/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
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

  function ERC721Token(string _name, string _symbol) public {
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

contract BargainNFT is Ownable, ERC721Token, ERC721Holder {
    using Strings for string;
    using Integers for uint;

    function BargainNFT () ERC721Token("BargainNFT" ,"BARGAINNFT") public {

    }

    struct DigitalNFT {
        string ipfsHash;
        address publisher;
        string name;
        string description;
        string typeFile;
        uint unit;
        uint total;
    }

    uint256 maxTotalSupply = 20000000000000000000000;
    bool public mintEnable = false;

    IERC20 public addressBargainToken;

    uint128 public feeToOwner = 8;
    uint128 public percentMintBargainToken = 1;
    uint256 public amountMintBargainToken = 10000000000000000;

    mapping (address => uint) public depositedTokens;

    DigitalNFT[] public digitalNFTs;
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
        string typeFile;
        uint unit;
        uint total;
    }

    mapping (uint256 => SellingItem) public tokenIdToSellingItem;

    uint128 public createNFTFee = 0.005 ether;
    uint128 public publisherCut = 200; 

    /*** Modifier ***/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*** Owner Action ***/
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function setMaxSupplyBargainToken(uint256 _value) public onlyOwner {
        maxTotalSupply = _value;
    }

    function setPercentMintBargainToken(uint128 _value) public onlyOwner {
        percentMintBargainToken = _value;
    }

    function setMintEnable(bool _value) public onlyOwner {
        mintEnable = _value;
    }

    function setCreateNFTFee(uint128 _fee) public onlyOwner {
        createNFTFee = _fee;
    }

    function setBargainToken(address _address) public onlyOwner {
        addressBargainToken = IERC20(_address);
    }

    function setAmountMint(uint256 _amount) public onlyOwner {
        amountMintBargainToken = _amount;
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

    function mintNFT(string _ipfsHash, string _name, string _description, string _typeFile, uint _total) public payable {
        require(msg.value == createNFTFee);
        require(ipfsHashToTokenId[_ipfsHash] == 0);
        
        if(_total == 0){
          _total = 1;
        }       

        if(mintEnable){
          if(addressBargainToken.getTotalSupply() <= maxTotalSupply){
              require(addressBargainToken.mint(msg.sender, amountMintBargainToken));
          }
        }
        
        uint unitItem;

        for(uint i = 0; i < _total; i++){
          unitItem = i.add(1);

          DigitalNFT memory _digitalNFT = DigitalNFT({
              ipfsHash: _ipfsHash, 
              publisher: msg.sender, 
              name: _name, 
              description: _description,
              typeFile: _typeFile,
              unit: unitItem,
              total: _total
          });

          uint256 newDigitalNFTId = digitalNFTs.push(_digitalNFT) - 1;
          ipfsHashToTokenId[_ipfsHash] = newDigitalNFTId;
          _mint(msg.sender, newDigitalNFTId);

          publishedTokensCount[msg.sender]++;
          uint256 length = publishedTokens[msg.sender].length;
          publishedTokens[msg.sender].push(newDigitalNFTId);
          publishedTokensIndex[msg.sender][newDigitalNFTId] = length;
        }
        
    }

    function addNFTSellingItem(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        require(tokenIdToSellingItem[_tokenId].seller == address(0));
        SellingItem memory _sellingItem = SellingItem(
            msg.sender, 
            uint256(_price), 
            digitalNFTs[_tokenId].ipfsHash, 
            digitalNFTs[_tokenId].name, 
            digitalNFTs[_tokenId].description,
            digitalNFTs[_tokenId].typeFile, 
            digitalNFTs[_tokenId].unit,
            digitalNFTs[_tokenId].total
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

    function purchaseNFT(uint256 _tokenId) public payable {
        uint256 priceItemEther = tokenIdToSellingItem[_tokenId].price;
        address sellerAddress = tokenIdToSellingItem[_tokenId].seller;

        require(sellerAddress != address(0));
        require(sellerAddress != msg.sender);
        require(priceItemEther == msg.value);

        if(mintEnable){
          if(addressBargainToken.getTotalSupply() <= maxTotalSupply){ 
              require(addressBargainToken.mint(msg.sender, _computeAmountMintToken(priceItemEther)));
          }
        }

        uint256 feeToOwnerItem = priceItemEther.mul(feeToOwner).div(100);
        uint256 priceItemEtherFee = priceItemEther.sub(feeToOwnerItem);

        sellerAddress.transfer(priceItemEtherFee);

        SellingItem memory sellingItem = tokenIdToSellingItem[_tokenId];

        if (sellingItem.price > 0) {
            uint256 actualPublisherCut = _computePublisherCut(sellingItem.price);
            digitalNFTs[_tokenId].publisher.transfer(actualPublisherCut);
        }

        delete tokenIdToSellingItem[_tokenId];
        this.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /*** Tools ***/
    function _computePublisherCut(uint256 _price) internal view returns (uint256) {
        return _price.mul(publisherCut).div(10000);
    }

    function _computeAmountMintToken(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(percentMintBargainToken).div(100);
    }

}