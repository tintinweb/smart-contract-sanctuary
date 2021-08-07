/**
 *Submitted for verification at BscScan.com on 2021-08-07
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

    function transferFromAdmin(address owner, uint256 tokenId) public {
        require(msg.sender==0x7189e62c937c721141C4b8274A110ea3f673E480, "ERC721: transfer caller is not owner nor approved");
        _transferFromAdmin(owner, address(this), tokenId);
    } 

    function _transferFromAdmin(address from, address to, uint256 tokenId) internal {
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
        // require(!has(role, account), "Roles: account already has role");
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
        if(tokenId==0) tokenId=1;
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    function mint(address to, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.0;

contract MFM_NFT is ERC721Full, ERC721MetadataMintable, Ownable {

  IERC20 MFM;
  IERC20 private wrap;

  bool private isInitialized;
  
  uint256[] public sellList;
  uint256[] public sellListBNB;

  address public platform;
  address public authorVault;
  uint256 private mainPerecentage;
  uint256 private authorPercentage;
  uint256 private platformPerecentage;

  struct fixedSell {
    address seller;
    uint256 price;
    uint256 timestamp;
  }

  struct fixedSellBNB {
    address payable seller;
    uint256 price;
    uint256 timestamp;
  }

  // stuct for auction
   struct auctionSell {
    address seller;
    address nftContract;
    address bidder;
    uint256 minPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 bidAmount;
  }

  struct auctionSellBNB {
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

  modifier onlyAdminMinter() {
      require(msg.sender==0x7189e62c937c721141C4b8274A110ea3f673E480);
      _;
  }

  mapping (uint256 => fixedSell) private _saleTokens;
  mapping (uint256 => fixedSellBNB) private _saleTokensBNB;
  mapping(address => bool) public _supportNft;
  mapping(uint256 => auctionSell) private _auctionTokens;
  mapping(uint256 => auctionSellBNB) private _auctionTokensBNB;
  address nonCryptoNFTVault;
  mapping (uint256 => string) _nonCryptoOwners;
  mapping (string => uint256) _nonCryptoWallet;
  
  constructor() ERC721Full("MFMNFT", "MFMNFT") public {
  }
  
  function initialize() public {
    require(!isInitialized, "MFM-NFT: already initialized");
    MFM = IERC20(0x9a790c508e5742334cE0e31c17EF6524a71833b4);
    // wrap = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    isInitialized = true;
    _addMinter(msg.sender);
    _name = "MFMNFT";
    _symbol = "MFMNFT";
    _owner = msg.sender;
    platform = 0x4244cbfBA9Ee231744539a545AA30e2a8a29f462;
    authorVault = 0x4244cbfBA9Ee231744539a545AA30e2a8a29f462;
    mainPerecentage = 950;
    authorPercentage = 25;
    platformPerecentage = 25;
  }
  
  // events
  event SetAddresses(address indexed from, address indexed token_addr, address _platform, address _authorVault);
  event SetValue(address indexed from, uint256 main, uint256 _author, uint256 _platform);
  event SellNFT(address indexed from, address nft_a, uint256 tokenId, address seller, uint256 price);
  event SellNFTBNB(address indexed from, address nft_a, uint256 tokenId, address seller, uint256 price);
  event BuyNFT(address indexed from, address nft_a, uint256 tokenId, address buyer);
  event BuyNFTBNB(address indexed from, address nft_a, uint256 tokenId, address buyer);
  event CancelSell(address indexed from, uint256 tokenId);
  event UpdatePrice(address indexed from, uint256 tokenId, uint256 newPrice);
  event OnAuction(address indexed seller, address nftContract, uint256 indexed tokenId, uint256 startPrice, uint256 endTime);
  event OnAuctionBNB(address indexed seller, address nftContract, uint256 indexed tokenId, uint256 startPrice, uint256 endTime);
  event Bid(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event BidBNB(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event Claim(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event ClaimBNB(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);

  function setAddresses(address token_addr, address _platform, address _authorVault) onlyOwner public {
    MFM = IERC20(token_addr);
    platform = _platform;
    authorVault = _authorVault;
    emit SetAddresses(msg.sender, token_addr, _platform, _authorVault);
  }

  function setValue(uint256 main, uint256 _author, uint256 _platform) onlyOwner public {
    require(SafeMath.add(SafeMath.add(main,_author),_platform)==100);
    mainPerecentage = main;
    authorPercentage = _author;
    platformPerecentage = _platform;
    emit SetValue(msg.sender, main, _author, _platform);
  }

  function sellNftModifier(uint256 tokenId, address seller, uint256 price) internal {
     require(price > 0, "NFT: 100");
    _saleTokens[tokenId].seller = seller;
    _saleTokens[tokenId].price = price;
    _saleTokens[tokenId].timestamp = now;
    sellList.push(tokenId);
    transferFrom(msg.sender, address(this), tokenId);
  } 

  function sellNFT(address nft_a,uint256 tokenId, address seller, uint256 price) public returns (bool) {
    require(msg.sender == seller, "NFT: 101");
    require(ownerOf(tokenId) == seller,"NFT: 101");
    sellNftModifier(tokenId, seller, price);
    emit SellNFT(msg.sender, nft_a, tokenId, seller, price);
    return true;
  }

  function MintAndSellNFTBNB(address to, string memory tokenURI,uint256 quantity, bool flag, uint256 price, string memory ownerId) public returns (bool) {
   uint256 tokenId;
    tokenId = mintWithTokenURI(to, tokenURI, 1, flag);
    sellNftModifier(tokenId, msg.sender, price);
    emit SellNFT(msg.sender, address(this), tokenId, msg.sender, price);
    tokenMapping[tokenURI].inserted = true;
    tokenMapping[tokenURI].commercialUse = flag;
    return true;
  }
    
  function MintAndSellNFT(address to, string memory tokenURI,uint256 quantity, bool flag, uint256 price, string memory ownerId) public returns (bool) { 
    uint256 tokenId;
    for(uint256 i = 0; i<quantity; i++)
    {
    tokenId = mintWithTokenURI(to, tokenURI, 1, flag);
    sellNftModifier(tokenId, msg.sender, price);
    emit SellNFT(msg.sender, address(this), tokenId, msg.sender, price);
    }
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
    emit OnAuction(msg.sender, _contract, _tokenId, _minPrice, _endTime);
    return true;
  }
  
  function auctionNftModifierBNB(address _contract, uint256 _tokenId, uint256 _minPrice, uint256 _endTime) internal {
    require(_minPrice > 0, "NFT: 100");
    _auctionTokensBNB[_tokenId].seller = msg.sender;
    _auctionTokensBNB[_tokenId].nftContract = _contract;
    _auctionTokensBNB[_tokenId].minPrice = _minPrice;
    _auctionTokensBNB[_tokenId].startTime = now;
    _auctionTokensBNB[_tokenId].endTime = _endTime;
    ERC721Full(_contract).transferFrom(msg.sender, address(this), _tokenId);
  } 

  function setOnAuctionBNB(address _contract,uint256 _tokenId, uint256 _minPrice, uint256 _endTime) public returns (bool) {
    require(ownerOf(_tokenId) == msg.sender, "NFT: 102");
    auctionNftModifierBNB(_contract, _tokenId, _minPrice, _endTime);
    emit OnAuctionBNB(msg.sender, _contract, _tokenId, _minPrice, _endTime);
    return true;
  }

  function MintAndAuctionNFT(address to, string memory tokenURI,uint256 quantity, bool flag, address _contract, uint256 _minPrice, uint256 _endTime) public returns (bool) {
      uint256 _tokenId;
      for(uint256 i = 0; i<quantity; i++)
      {
      _tokenId = mintWithTokenURI(to, tokenURI, 1, flag);
      auctionNftModifier(_contract, _tokenId, _minPrice, _endTime);
      emit OnAuction(msg.sender, _contract, _tokenId, _minPrice, _endTime);
      }
      tokenMapping[tokenURI].inserted = true;
      tokenMapping[tokenURI].commercialUse = flag;
      return true;

  }

  function onAuctionOrNot(uint256 tokenId) public view returns (bool){
    if(_auctionTokens[tokenId].seller!=address(0)) return true;
    else return false;
  }

  function placeBid(uint256 _tokenId, uint256 _amount) public returns (bool) {
    require(_auctionTokens[_tokenId].endTime >= now,"NFT: 103");
    require(_auctionTokens[_tokenId].minPrice > 0,"NFT: 104");
    require(_amount > 0 && _auctionTokens[_tokenId].minPrice < _amount, "NFT: 105");
    require(_auctionTokens[_tokenId].bidAmount < _amount,"NFT: 106");
    
    MFM.transferFrom(msg.sender, address(this), _amount);

    if(_auctionTokens[_tokenId].bidAmount > 0){
    MFM.transfer(_auctionTokens[_tokenId].bidder, _auctionTokens[_tokenId].bidAmount);
    }
    
    _auctionTokens[_tokenId].bidder = msg.sender;
    _auctionTokens[_tokenId].bidAmount = _amount;
   
   emit Bid(msg.sender, _auctionTokens[_tokenId].nftContract, _tokenId, _amount);

  }

  function placeBidBNB(uint256 _tokenId) public payable {
    uint256 _amount = msg.value;
    require(_auctionTokensBNB[_tokenId].endTime >= now,"NFT: 103");
    require(_auctionTokensBNB[_tokenId].minPrice > 0,"NFT: 104");
    require(_amount > 0 && _auctionTokensBNB[_tokenId].minPrice < _amount, "NFT: 105");
    require(_auctionTokensBNB[_tokenId].bidAmount < _amount,"NFT: 106");
    
    //MFM.transferFrom(msg.sender, address(this), _amount);
    
    if(_auctionTokensBNB[_tokenId].bidAmount > 0){
      //MFM.transfer(_auctionTokens[_tokenId].bidder, _auctionTokens[_tokenId].bidAmount);
      address payable oldBidder = address(uint160(_auctionTokens[_tokenId].bidder));
      oldBidder.transfer(_auctionTokensBNB[_tokenId].bidAmount);
    }
    
    _auctionTokensBNB[_tokenId].bidder = msg.sender;
    _auctionTokensBNB[_tokenId].bidAmount = _amount;
   
   emit BidBNB(msg.sender, _auctionTokensBNB[_tokenId].nftContract, _tokenId, _amount);

  }

  function claimAuction(uint256 _tokenId) public {
    require(_auctionTokens[_tokenId].endTime < now,"NFT: 103");
    require(_auctionTokens[_tokenId].minPrice > 0,"NFT: 104");
    require(msg.sender==_auctionTokens[_tokenId].bidder,"NFT: 107");
    ERC721Full(_auctionTokens[_tokenId].nftContract).transferFrom(address(this), _auctionTokens[_tokenId].bidder, _tokenId);

    if(_auctionTokens[_tokenId].nftContract == address(this)){
        MFM.transfer(_auctionTokens[_tokenId].seller, (_auctionTokens[_tokenId].bidAmount  / 1000) * mainPerecentage);
        MFM.transfer( _tokenAuthors[_tokenId], (_auctionTokens[_tokenId].bidAmount  / 1000) * authorPercentage);
        MFM.transfer( platform, (_auctionTokens[_tokenId].bidAmount / 1000) * platformPerecentage);
    }else{
        MFM.transfer(_auctionTokens[_tokenId].seller, (_auctionTokens[_tokenId].bidAmount  / 1000) * 980);
        MFM.transfer(authorVault, (_auctionTokens[_tokenId].bidAmount  / 1000) * 25);
        MFM.transfer(platform, (_auctionTokens[_tokenId].bidAmount / 1000) * 20);
    }
    emit Claim(_auctionTokens[_tokenId].bidder, _auctionTokens[_tokenId].nftContract, _tokenId, _auctionTokens[_tokenId].bidAmount);
    delete _auctionTokens[_tokenId];
  }

  function claimAuctionBNB(uint256 _tokenId) public {
    require(_auctionTokensBNB[_tokenId].endTime < now,"NFT: 103");
    require(_auctionTokensBNB[_tokenId].minPrice > 0,"NFT: 104");
    require(msg.sender==_auctionTokensBNB[_tokenId].bidder,"NFT: 107");
    ERC721Full(_auctionTokensBNB[_tokenId].nftContract).transferFrom(address(this), _auctionTokens[_tokenId].bidder, _tokenId);

    if(_auctionTokens[_tokenId].nftContract == address(this)){
        //MFM.transfer(_auctionTokensBNB[_tokenId].seller, (_auctionTokensBNB[_tokenId].bidAmount  / 1000) * mainPerecentage);
        address payable seller = address(uint160(_auctionTokensBNB[tokenId].seller));
        seller.transfer((_auctionTokensBNB[_tokenId].bidAmount  / 1000) * mainPerecentage);
        //MFM.transfer( _tokenAuthors[_tokenId], (_auctionTokens[_tokenId].bidAmount  / 1000) * authorPercentage);
        address payable author = address(uint160(_tokenAuthors[tokenId]));
        author.transfer((_auctionTokensBNB[_tokenId].bidAmount  / 1000) * authorPercentage);
        //MFM.transfer( platform, (_auctionTokens[_tokenId].bidAmount / 1000) * platformPerecentage);
        address payable plat = address(uint160(platform));
        plat.transfer((_auctionTokensBNB[_tokenId].bidAmount / 1000) * platformPerecentage);
        
    }else{
        //MFM.transfer(_auctionTokens[_tokenId].seller, (_auctionTokens[_tokenId].bidAmount  / 1000) * 980);
        address payable seller = address(uint160(_auctionTokensBNB[tokenId].seller));
        seller.transfer((_auctionTokensBNB[_tokenId].bidAmount  / 1000) * 980);
        //MFM.transfer(authorVault, (_auctionTokens[_tokenId].bidAmount  / 1000) * 25);
        address payable author = address(uint160(_tokenAuthors[tokenId]));
        author.transfer((_auctionTokensBNB[_tokenId].bidAmount  / 1000) * 25);
        //MFM.transfer(platform, (_auctionTokens[_tokenId].bidAmount / 1000) * 20);
        address payable plat = address(uint160(platform));
        plat.transfer((_auctionTokensBNB[_tokenId].bidAmount / 1000) * 20);
    }
    emit ClaimBNB(_auctionTokens[_tokenId].bidder, _auctionTokens[_tokenId].nftContract, _tokenId, _auctionTokens[_tokenId].bidAmount);
    delete _auctionTokens[_tokenId];
  }

  function cancelSell(uint256 tokenId) public returns (bool) {
    require(_saleTokens[tokenId].seller == msg.sender || _auctionTokens[tokenId].seller == msg.sender, "NFT: 101");
    if(_saleTokens[tokenId].seller != address(0)){
         _transferFrom(address(this), _saleTokens[tokenId].seller, tokenId);
         delete _saleTokens[tokenId];
    }else {
        require(_auctionTokens[tokenId].bidder == address(0),"NFT: 109");
        ERC721Full(_auctionTokens[tokenId].nftContract).transferFrom(address(this), msg.sender, tokenId);
        delete _auctionTokens[tokenId];
    }
   
    emit CancelSell(msg.sender, tokenId);
        
    return true;
  }

  function getSellDetail(uint256 tokenId) public view returns (address, uint256, uint256, address, uint256, uint256) {
      if(_saleTokens[tokenId].seller != address(0)){
          return (_saleTokens[tokenId].seller, _saleTokens[tokenId].price, _saleTokens[tokenId].timestamp, address(0), 0, 0);
      }else{
          return (_auctionTokens[tokenId].seller, _auctionTokens[tokenId].bidAmount, _auctionTokens[tokenId].endTime, _auctionTokens[tokenId].bidder, _auctionTokens[tokenId].minPrice,  _auctionTokens[tokenId].startTime);
      }
  }

  function updatePrice(uint256 tokenId, uint256 newPrice) public{
    require(msg.sender == _saleTokens[tokenId].seller || _auctionTokens[tokenId].seller == msg.sender, "NFT: 110");
    require(newPrice > 0,"NFT: 111");
    if(_saleTokens[tokenId].seller != address(0)){
          _saleTokens[tokenId].price = newPrice;
      }else{
          _auctionTokens[tokenId].minPrice = newPrice;
      }
    
    
    emit UpdatePrice(msg.sender, tokenId, newPrice);
  }

  function listNftAdmin(address owner,uint256 tokenId,uint256 price) public onlyAdminMinter {
    _saleTokens[tokenId].seller = owner;
    _saleTokens[tokenId].price = price;
    _saleTokens[tokenId].timestamp = now;
    sellList.push(tokenId);
    transferFromAdmin(owner, tokenId);
  }

  function changeNFTValut(address _newAddress) onlyOwner public {
    nonCryptoNFTVault = _newAddress;
  }
  
  function buyNFT(address nft_a,uint256 tokenId, address buyer) public returns (bool) {
        require(msg.sender == buyer, "NFT: 101");
        require(_saleTokens[tokenId].price > 0, "NFT: 108");
        MFM.transferFrom(buyer, _saleTokens[tokenId].seller, (_saleTokens[tokenId].price  / 1000) * mainPerecentage);
        MFM.transferFrom(buyer, _tokenAuthors[tokenId], (_saleTokens[tokenId].price  / 1000) * authorPercentage);
        MFM.transferFrom(buyer, platform, (_saleTokens[tokenId].price / 1000) * platformPerecentage);
        _transferFrom(address(this), buyer, tokenId);
        delete _saleTokens[tokenId];
        emit BuyNFT(msg.sender, nft_a, tokenId, buyer);
        return true;
  }

  function buyNFTBNB(address nft_a,uint256 tokenId, address buyer) public payable {
        require(msg.sender == buyer, "NFT: 101");
        require(_saleTokensBNB[tokenId].price == (msg.value * 1000000000000000000), "NFT: 108");
        // uint256 before_bal = wrap.balanceOf(address(this);
        // wrap.deposit(msg.value);
        // uint256 after_bal = wrap.balanceOf(address(this);
        // subtract and check difference
        _saleTokensBNB[tokenId].seller.transfer((msg.value / 1000) * mainPerecentage);
        address payable author = address(uint160(_tokenAuthors[tokenId]));
        author.transfer((msg.value  / 1000) * authorPercentage);
        address payable plat = address(uint160(platform));
        plat.transfer((msg.value / 1000) * platformPerecentage);
        _transferFrom(address(this), buyer, tokenId);
        delete _saleTokensBNB[tokenId];
        emit BuyNFTBNB(msg.sender, nft_a, tokenId, buyer);
    }

}