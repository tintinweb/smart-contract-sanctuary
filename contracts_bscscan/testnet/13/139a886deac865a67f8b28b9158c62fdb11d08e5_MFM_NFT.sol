/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

pragma solidity ^0.5.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.5.0;

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
 
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


pragma solidity ^0.5.0;

contract IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}


pragma solidity ^0.5.0;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


pragma solidity ^0.5.0;

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


pragma solidity ^0.5.0;

library Counters {
    using SafeMath for uint256;

    struct Counter {
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


pragma solidity ^0.5.0;

contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) private _supportedInterfaces;
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


pragma solidity ^0.5.0;

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }

 
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }


    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

  
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

 
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

   
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

  
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

 
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");
        _clearApproval(tokenId);
        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);
        emit Transfer(owner, address(0), tokenId);
    }


    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

 
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _clearApproval(tokenId);
        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }


    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}


pragma solidity ^0.5.0;

contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) public view returns (uint256);
}


pragma solidity ^0.5.0;

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);
        _removeTokenFromOwnerEnumeration(owner, tokenId);
        _ownedTokensIndex[tokenId] = 0;
        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

 
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        _ownedTokens[from].length--;
    }

 
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }

    //Custom functions
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
     return _ownedTokens[owner];
    }
    function allTokens() public view returns (uint256[] memory) {
      return _allTokens;
    }
    function onSell() public view returns (uint256[] memory) {
      return _ownedTokens[address(this)];
    }
}


pragma solidity ^0.5.0;

contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


pragma solidity ^0.5.0;

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
    string internal _name;

    string internal _symbol;

    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }


    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


pragma solidity ^0.5.0;

contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
    }
}


pragma solidity ^0.5.0;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


pragma solidity ^0.5.0;

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
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


pragma solidity ^0.5.0;

contract ERC721MetadataMintable is ERC721, ERC721Metadata, MinterRole {
 
     uint256 tokenId;
     struct tokenInfo{
       bool inserted;
       bool commercialUse;
     }
    mapping(uint256 => address) internal _tokenAuthors;
    mapping(string => tokenInfo) internal tokenMapping;
    event MintWithTokenURI(string action , address indexed from , address to, string tokenURI, uint256 quantity, bool flag);

  function mintWithTokenURI(address to, string memory tokenURI,uint256 quantity, bool flag) internal returns (uint256) {
        require(tokenMapping[tokenURI].inserted==false,"Cannot insert same URI");
        if(tokenId==0) tokenId=3001;
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        _tokenAuthors[tokenId] = msg.sender;
        tokenId++;        
        emit MintWithTokenURI("mintWithTokenURI", msg.sender, to, tokenURI, quantity, flag);
        return tokenId-1;
    }
    function getAuthor(uint256 tokenIdFunction) public view returns (address) {
     return _tokenAuthors[tokenIdFunction];
   }
}


pragma solidity ^0.5.0;

contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function withdraw(uint) external;
    function deposit() payable external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    function mint(address to, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.0;

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


pragma solidity ^0.5.0;

contract MFM_NFT is ERC721Full, ERC721MetadataMintable, Ownable {

  using SafeMath for uint256;
  using Strings for string;
	
  IERC20 MFM;
  IERC20 private wrap;

  bool private isInitialized;
  uint256[] public sellList;

  address payable public  platform;
  address payable public authorVault;
  uint256 public itemPrice; 
  uint256 private platformPerecentage;
  string public _baseURI;

  struct fixedSell {
    address seller;
    uint256 price;
    uint256 timestamp;
  }
  
   struct auctionSell {
    address seller;
    address nftContract;
    address bidder;
    uint256 minPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 bidAmount;
  }

  modifier validAddress( address addr ) {
      require(addr != address(0x0));
      _;
  }

  mapping (uint256 => fixedSell) private _saleTokens;
  mapping(uint256 => auctionSell) private _auctionTokens;
  mapping (uint256 => uint256) private _royality;
  mapping(uint256 => uint256) private _spaceCards;


  constructor() ERC721Full("SpaceNFT", "SpaceNFT") public {
      
  }
  
    function() external payable {}
  
    function initialize() public {
    require(!isInitialized, "MFM-NFT: already initialized");
    wrap = IERC20(0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd);
    isInitialized = true;
    _addMinter(msg.sender);
    _name = "MFMNFT";
    _symbol = "MFMNFT";
    _owner = msg.sender;
    platform = 0x0Ba6D5893166676B18Ab798a865671d36F11b793;
    platformPerecentage = 25;
    itemPrice = 10000000000000;
    _baseURI = "https://qaapi.space-nft.io/getSpaceCard/";
  }

 // events
  event SellNFT(address indexed from, address nft_a, uint256 tokenId, address seller, uint256 price,uint256 royalty);
  event BuyNFT(address indexed from, address nft_a, uint256 tokenId, address buyer);
  event OnAuction(address indexed seller, address nftContract, uint256 indexed tokenId, uint256 startPrice, uint256 endTime, uint256 royalty);
  event Bid(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event Claim(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event BuyCard(address buyer,uint256 tokenId);

  function setAddresses(address payable _platform) onlyOwner public {
    platform = _platform;
  }

  function setValue( uint256 _platform) onlyOwner public {
    platformPerecentage = _platform;
  }

 function sellNftModifier(uint256 tokenId, address payable seller, uint256 price) internal {
     require(price > 0, "NFT: 100");
    _saleTokens[tokenId].seller = seller;
    _saleTokens[tokenId].price = price;
    _saleTokens[tokenId].timestamp = now;
    sellList.push(tokenId);
    transferFrom(msg.sender, address(this), tokenId);
  } 

  function sellNFT(address nft_a,uint256 tokenId, address payable seller, uint256 price) public returns (bool) {
    require(msg.sender == seller, "NFT: 101");
    require(ownerOf(tokenId) == seller,"NFT: 101");
    sellNftModifier(tokenId, seller, price);
    emit SellNFT(msg.sender, nft_a, tokenId, seller, price,_royality[tokenId]);
    return true;
  }
    
    function MintAndSellNFT(address to, string memory tokenURI, bool flag, uint256 price, uint256 royality) public returns (bool) { 
    require(royality <= 500, "Royalty can't exceed 50%");
    uint256 tokenId;
    tokenId = mintWithTokenURI(to, tokenURI, 1, flag);
    sellNftModifier(tokenId, msg.sender, price);
    _royality[tokenId] = royality;
    emit SellNFT(msg.sender, address(this), tokenId, msg.sender, price,_royality[tokenId]);
    tokenMapping[tokenURI].inserted = true;
    tokenMapping[tokenURI].commercialUse = flag;
    return true;
    }

    function auctionNftModifier(address _contract, uint256 _tokenId, uint256 _minPrice, uint256 _endTime) internal {
    require(_minPrice > 0, "NFT: 100");
      _auctionTokens[_tokenId].seller = msg.sender;
      _auctionTokens[_tokenId].nftContract = _contract;
      _auctionTokens[_tokenId].minPrice = _minPrice;
      _auctionTokens[_tokenId].startTime = now;
      _auctionTokens[_tokenId].endTime = _endTime;
      ERC721Full(_contract).transferFrom(msg.sender, address(this), _tokenId);
    } 

    function setOnAuction(address _contract,uint256 _tokenId, uint256 _minPrice, uint256 _endTime) public returns (bool) {
    require(ownerOf(_tokenId) == msg.sender, "NFT: 102");
    auctionNftModifier(_contract, _tokenId, _minPrice, _endTime);
    emit OnAuction(msg.sender, _contract, _tokenId, _minPrice, _endTime,_royality[tokenId]);
    return true;
  }
  
  function MintAndAuctionNFT(address to, string memory tokenURI, bool flag, address _contract, uint256 _minPrice, uint256 _endTime, uint256 royality) public {
      require(royality <= 500, "Royalty can't exceed 50%");
      uint256 _tokenId;
      _tokenId = mintWithTokenURI(to, tokenURI, 1, flag);
      auctionNftModifier(_contract, _tokenId, _minPrice, _endTime);
      _royality[tokenId] = royality;
      emit OnAuction(msg.sender, _contract, _tokenId, _minPrice, _endTime,_royality[tokenId]);
      tokenMapping[tokenURI].inserted = true;
      tokenMapping[tokenURI].commercialUse = flag;
  }
  
  function onAuctionOrNot(uint256 tokenId) public view returns (bool){
    if(_auctionTokens[tokenId].seller!=address(0)) return true;
    else return false;
   }

 function placeBid(uint256 _tokenId) public payable returns (bool) {
    require(_auctionTokens[_tokenId].endTime >= now,"NFT: 103");
    uint256 before_bal = wrap.balanceOf(address(this));
    wrap.deposit.value(msg.value)();
    uint256 after_bal = wrap.balanceOf(address(this));
    uint256 _amount = after_bal.sub(before_bal);
    require(_auctionTokens[_tokenId].minPrice < _amount, "NFT 105");
    require(_auctionTokens[_tokenId].bidAmount < _amount,"NFT: 106");
    
    if(_auctionTokens[_tokenId].bidAmount > 0){
    uint256 initialBalance = address(this).balance;
    wrap.withdraw(_auctionTokens[_tokenId].bidAmount);
    uint256 newBalance = address(this).balance.sub(initialBalance);
    address payable refund = address(uint160(_auctionTokens[_tokenId].bidder));
    refund.transfer(newBalance);
    }
    _auctionTokens[_tokenId].bidder = msg.sender;
    _auctionTokens[_tokenId].bidAmount = _amount;
   emit Bid(msg.sender, _auctionTokens[_tokenId].nftContract, _tokenId, _amount);
   return true;
  }
 

  function claimAuction(uint256 _tokenId) public returns (bool){
    require(_auctionTokens[_tokenId].endTime < now,"NFT: 103");
    require(msg.sender == _auctionTokens[_tokenId].bidder,"NFT: 107");
    
    uint256 mainPerecentage = 975;
    mainPerecentage = mainPerecentage.sub(_royality[tokenId]);
    
    //pay seller
    
    uint256 initialBalance = address(this).balance;
    wrap.withdraw((_auctionTokens[_tokenId].bidAmount / 1000) * mainPerecentage);
    uint256 newBalance = address(this).balance.sub(initialBalance);
    address payable seller = address(uint160(_auctionTokens[tokenId].seller));
    seller.transfer(newBalance);
        
    //author fee
    if(_royality[tokenId] > 0){
    initialBalance = address(this).balance;
    wrap.withdraw((_auctionTokens[_tokenId].bidAmount / 1000) * _royality[tokenId]);
    newBalance = address(this).balance.sub(initialBalance);
    address payable author = address(uint160(_tokenAuthors[tokenId]));
    author.transfer(newBalance);
    }
    
    //platform fee
    initialBalance = address(this).balance;
    wrap.withdraw((_auctionTokens[_tokenId].bidAmount / 1000) * platformPerecentage);
    newBalance = address(this).balance.sub(initialBalance);
    platform.transfer(newBalance);
   
    ERC721Full(address(this)).transferFrom(address(this), _auctionTokens[_tokenId].bidder, _tokenId);
    emit Claim(_auctionTokens[_tokenId].bidder, _auctionTokens[_tokenId].nftContract, _tokenId, _auctionTokens[_tokenId].bidAmount);
    delete _auctionTokens[_tokenId];
    return true;
  }


  function getSellDetail(uint256 tokenId) public view returns (address, uint256, uint256, address, uint256, uint256) {
      if(_saleTokens[tokenId].seller != address(0)){
          return (_saleTokens[tokenId].seller, _saleTokens[tokenId].price, _saleTokens[tokenId].timestamp, address(0), 0, 0);
      }else{
          return (_auctionTokens[tokenId].seller, _auctionTokens[tokenId].bidAmount, _auctionTokens[tokenId].endTime, _auctionTokens[tokenId].bidder, _auctionTokens[tokenId].minPrice,  _auctionTokens[tokenId].startTime);
      }
  }

  
  function buyNFT(address nft_a,uint256 tokenId, address buyer) public payable {
        require(msg.sender == buyer, "NFT: 101");
        uint256 before_bal = wrap.balanceOf(address(this));
        wrap.deposit.value(msg.value)();
        uint256 after_bal = wrap.balanceOf(address(this));
        require(_saleTokens[tokenId].price == (after_bal - before_bal), "NFT 108");
        
        uint256 mainPerecentage = 975;
        mainPerecentage = mainPerecentage.sub(_royality[tokenId]);
    
        //pay seller
        uint256 initialBalance = address(this).balance;
        wrap.withdraw((_saleTokens[tokenId].price / 1000) * mainPerecentage);
    	uint256 newBalance = address(this).balance.sub(initialBalance);
    	address payable seller = address(uint160(_saleTokens[tokenId].seller));
        seller.transfer(newBalance);
        
        //author fee
        if(_royality[tokenId] > 0){
        initialBalance = address(this).balance;
        wrap.withdraw((_saleTokens[tokenId].price / 1000) * _royality[tokenId]);
    	newBalance = address(this).balance.sub(initialBalance);
    	address payable author = address(uint160(_tokenAuthors[tokenId]));
        author.transfer(newBalance);
        }
       
        
        //platform fee
        initialBalance = address(this).balance;
        wrap.withdraw((_saleTokens[tokenId].price / 1000) * platformPerecentage);
    	newBalance = address(this).balance.sub(initialBalance);
        platform.transfer(newBalance);
        
        _transferFrom(address(this), buyer, tokenId);
        delete _saleTokens[tokenId];
        emit BuyNFT(msg.sender, nft_a, tokenId, buyer);
    }
    
    function buyCard() public payable {
		require(msg.value == itemPrice, "Insufficient BNB");
		buy();
		platform.transfer(msg.value);
	}

	function buyCards(uint256 quantity) public payable {
		require(quantity <= 10, "Max 10 cards at once");
		require(itemPrice.mul(quantity) == msg.value, "Insufficient BNB");
		for (uint256 i = 0; i < quantity; i++) {
			buy();
		}
		platform.transfer(msg.value);
	}

    function spaceURI(uint256 tokenId) private returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId))); 
	}
	
	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
    
	function buy() private {
		for (uint256 i = 0; i < 9999; i++) {
			uint256 randID = random(1, 3000, uint256(uint160(address(msg.sender))) + i);
			if (_spaceCards[randID] == 0) {
				_spaceCards[randID] = 1;
				_royality[randID] = 0;
				string memory tokenURI = spaceURI(randID);
                _mint(msg.sender, randID);
                _setTokenURI(randID, tokenURI);
                _tokenAuthors[randID] = address(this);
			    tokenMapping[tokenURI].inserted = true;
                tokenMapping[tokenURI].commercialUse = false;
                emit BuyCard(msg.sender,randID);
                return;
			}
		}
		revert("you're very unlucky");
	}
	
	//random number
	function random(
		uint256 from,
		uint256 to,
		uint256 salty
	) private view returns (uint256) {
		uint256 seed =
			uint256(
				keccak256(
					abi.encodePacked(
						block.timestamp +
							block.difficulty +
							((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
							block.gaslimit +
							((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
							block.number +
							salty
					)
				)
			);
		return seed.mod(to - from) + from;
	}

}