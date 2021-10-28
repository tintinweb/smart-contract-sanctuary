/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-20
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

/**
 *Submitted for verification at polygonscan.com on 2021-10-18
*/

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * 
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Enumerable.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Full.sol

pragma solidity ^0.5.0;




/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
    // solhint-disable-previous-line no-empty-blocks
}

// File: contracts/INFT.sol

pragma solidity ^0.5.0;


contract INFT is IERC721Full {
    function transferFromAdmin(address owner, address to, uint256 tokenId) external;
    function mintWithTokenURI(address to, string calldata tokenURI) external returns (uint256);
    function getAuthor(uint256 tokenIdFunction) external view returns (address);
    function updateTokenURI(uint256 tokenIdT, string calldata uriT) external;
    //
    function mint(address to, string calldata tokenURI) external returns (uint256);
    function transferOwnership(address newOwner) external;
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // constructor () internal {
    //     _owner = msg.sender;
    //     emit OwnershipTransferred(address(0), _owner);
    // }
    function ownerInit() internal {
         _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.5.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address recipient, uint256 amount) external returns(bool);
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    
    function withdraw(uint) external;
    function deposit() payable external;

    // BlindBox ref:https://noborderz.slack.com/archives/C0236PBG601/p1633942033011800?thread_ts=1633941154.010300&cid=C0236PBG601


    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function burn (uint256 tokenId) external;

}

// File: contracts/IFactory.sol

pragma solidity ^0.5.0;


contract IFactory {
    function create(string calldata name_, string calldata symbol_, address owner_) external returns(address);
    function getCollections(address owner_) external view returns(address [] memory);
}

// File: contracts/LPInterface.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface LPInterface {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

   
}

// File: contracts/DEX.sol

pragma solidity ^0.5.0;






contract DEX is Ownable {
   INFT XNFT;
   IFactory factory;
   IERC20 USDT;
   IERC20 ETH;
  struct AuthorDetails {
    address _address;
    uint256 royalty;
    string ownerId;
    bool isSecondry;
  }
  // uint256[] public sellList; // this violates generlization as not tracking tokenIds agains nftContracts/collections but ignoring as not using it in logic anywhere (uncommented)
  mapping (uint256 => mapping(address => AuthorDetails)) _tokenAuthors;
  mapping (address => bool) public adminOwner;
  address payable public platform;
  uint256 private platformPerecentage;
  struct fixedSell {
  //  address nftContract; // adding to support multiple NFT contracts buy/sell 
    address seller;
    uint256 price;
    uint256 timestamp;
    uint256 currencyType;
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
    uint256 currencyType;
    // address nftAddress;
  }

  
  // tokenId => nftContract => fixedSell
  mapping (uint256 => mapping (address  => fixedSell)) private _saleTokens;
  mapping(address => bool) public _supportNft;
  // tokenId => nftContract => auctionSell
  mapping(uint256 => mapping ( address => auctionSell)) private _auctionTokens;
  LPInterface LPETH;
  uint256 public adminDiscount;
  address admin;
   bool private collectionConfig;
  mapping (uint256=> mapping( address => mapping(uint256 => bool))) _allowedCurrencies;
  using SafeMath for uint256;
  IERC20 token;

  event SellNFT(address indexed from, address nft_a, uint256 tokenId, address seller, uint256 price, uint256 royalty, uint256 baseCurrency, uint256[] allowedCurrencies);
  event BuyNFT(address indexed from, address nft_a, uint256 tokenId, address buyer, uint256 price, uint256 baseCurrency, uint256 calculated, uint256 currencyType);
  event CancelSell(address indexed from, address nftContract, uint256 tokenId);
  event UpdatePrice(address indexed from, uint256 tokenId, uint256 newPrice, bool isDollar, address nftContract, uint256 baseCurrency, uint256[] allowedCurrencies);
  event OnAuction(address indexed seller, address nftContract, uint256 indexed tokenId, uint256 startPrice, uint256 endTime, uint256 baseCurrency);
  event Bid(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event Claim(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount, address seller, uint256 baseCurrency);
  event updateTokenEvent(address to,uint256 tokenId, string uriT);
  event updateDiscount(uint256 amount);
  event Collection(address indexed creater, address collection, string name, string symbol);
  event CollectionsConfigured(address indexed xCollection, address factory);
  event MintWithTokenURI(address indexed collection, uint256 indexed tokenId, address minter, string tokenURI);
//   event Offer(uint256 tokenId, address indexed from, uint256 currencyType, uint256 offer, uint256 index);


  modifier onlyAdminMinter() {
      require(msg.sender==0x61598488ccD8cb5114Df579e3E0c5F19Fdd6b3Af);
      _;
  }
  function() external payable {}
  function init() public {
    require(!collectionConfig,"collections already configured");
    XNFT = INFT(0x326Cae76A11d85b5c76E9Eb81346eFa5e4ea7593); 
    collectionConfig = true;
    admin=0x61598488ccD8cb5114Df579e3E0c5F19Fdd6b3Af;
    LPETH=LPInterface(0x000C6843Be0b17FB61ed1a8465b2fA2bac0cFCb2);
    platform = 0xF0d2D73d09A04036F7587C16518f67cE622129Fd;
    platformPerecentage = 25;
    ownerInit();
    factory = IFactory(0x5F2853FCC02c0c3366249aD120Af33eD77D31f00);
   _supportNft[0x326Cae76A11d85b5c76E9Eb81346eFa5e4ea7593] = true;
    emit CollectionsConfigured(0x326Cae76A11d85b5c76E9Eb81346eFa5e4ea7593, 0x5F2853FCC02c0c3366249aD120Af33eD77D31f00);
    USDT = IERC20(0xD92E713d051C37EbB2561803a3b5FBAbc4962431);
    ETH= IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    _supportNft[address(this)] = true;
  }

 

  /***
* @dev function to create & deploy user-defined collection
* @param name_ - name of the collection
* @param symbol_ - symbol of collection
*
 */
  function createCollection(string memory name_, string memory symbol_) public {
    address col = factory.create(name_, symbol_, msg.sender);
    _supportNft[col] = true;
    emit Collection(msg.sender, col, name_, symbol_);
  }
  /***
* @dev function to mint NFTs on given user-defined collection
* @param collection - address of collection to whom NFT to be created/minted
* @param to - receiving account of minted NFT
* @param tokenURI - metadata URI link of NFT
*
 */
  function mintAndSellCollectionNFT(address collection, address to, string memory tokenURI, uint256 price, uint256 baseCurrency, uint256[] memory allowedCurrencies ) isValid(collection) public {
 
    address[] memory collections = factory.getCollections(msg.sender);
   
    bool flag;
    for (uint256 i = 0; i < collections.length; i++){
        if (collections[i] == collection){
          flag = true;
          break;
        }
    }
    require(flag, "unauthorized: invalid owner/collection");
    // for (uint256 j = 0; j < quantity; j++){
       uint256 tokenId =  INFT(collection).mint(to, string(abi.encodePacked("https://ipfs.infura.io:5001/api/v0/cat?arg=", tokenURI)));
        sellNFT(collection, tokenId, to, price, baseCurrency, allowedCurrencies);
    // }
    emit MintWithTokenURI(collection, tokenId, msg.sender, tokenURI);
  }
  function mintAndAuctionCollectionNFT(address collection, address to, string memory tokenURI, uint256 _minPrice, uint256 baseCurrency, uint256 _endTime ) isValid(collection) public {
 
    address[] memory collections = factory.getCollections(msg.sender);
   
    bool flag;
    for (uint256 i = 0; i < collections.length; i++){
        if (collections[i] == collection){
          flag = true;
          break;
        }
    }
    require(flag, "unauthorized: invalid owner/collection");
    // for (uint256 j = 0; j < quantity; j++){
       uint256 tokenId =  INFT(collection).mint(to, string(abi.encodePacked("https://ipfs.infura.io:5001/api/v0/cat?arg=", tokenURI)));
       setOnAuction(collection, tokenId, _minPrice, baseCurrency, _endTime);
    // }
       emit MintWithTokenURI(collection, tokenId, msg.sender, tokenURI);

  }
  /***
* @dev function to transfer ownership of user-defined collection
* @param collection - address of collection whose ownership to be transferred
* @param newOwner - new owner to whom ownerhsip to be transferred
* @notice only owner of DEX can invoke this function
*
 */
  function transferCollectionOwnership(address collection, address newOwner) onlyOwner isValid(collection) public {

    INFT(collection).transferOwnership(newOwner);
  }
  
  // modifier to check if given collection is supported by DEX
  modifier isValid( address collection_) {
    require(_supportNft[collection_],"unsupported collection");
    _;
  }
  
  function sellNFT(address nft_a,uint256 tokenId, address seller, uint256 price, uint256 baseCurrency, uint256[] memory allowedCurrencies) isValid(nft_a) public{
    require(msg.sender == admin || (msg.sender == seller && INFT(nft_a).ownerOf(tokenId) == seller), "101");
    
    uint256 royality;
    require(baseCurrency <= 1, "121");
   bool isValid = true;
    for(uint256 i = 0; i< allowedCurrencies.length; i++){
      if(allowedCurrencies[i] > 1){
        isValid = false;
      }
      _allowedCurrencies[tokenId][nft_a][allowedCurrencies[i]] = true;
    }
    require(isValid,"122");
    _saleTokens[tokenId][nft_a].seller = seller;
    _saleTokens[tokenId][nft_a].price = price;
    _saleTokens[tokenId][nft_a].timestamp = now;
    // _saleTokens[tokenId][nft_a].isDollar = isDollar;
    _saleTokens[tokenId][nft_a].currencyType = baseCurrency;
    // need to check if it voilates generalization
    // sellList.push(tokenId);
    // dealing special case of escrowing for xanalia collection i.e XNFT
    if(nft_a == address(XNFT)){
         msg.sender == admin ? XNFT.transferFromAdmin(seller, address(this), tokenId) : XNFT.transferFrom(seller, address(this), tokenId);        
          royality =  _tokenAuthors[tokenId][nft_a].royalty;
    } else {
      INFT(nft_a).transferFrom(seller, address(this), tokenId);
      royality =  0; // making it zero as not setting royality for user defined collection's NFT
    }
    
    emit SellNFT(msg.sender, nft_a, tokenId, seller, price, royality, baseCurrency, allowedCurrencies);
  }

  //mint & sell own/xanalia collection only
  function MintAndSellNFT(address to, string memory tokenURI, uint256 price, string memory ownerId, uint256 royality, uint256 currencyType, uint256[] memory allowedCurrencies)  public { 
    uint256 tokenId;
     tokenId = XNFT.mintWithTokenURI(to,string(abi.encodePacked("https://ipfs.infura.io:5001/api/v0/cat?arg=", tokenURI)));
     emit MintWithTokenURI(address(XNFT), tokenId, msg.sender, tokenURI);
     if(royality > 0) _tokenAuthors[tokenId][address(XNFT)].royalty = royality;
     else _tokenAuthors[tokenId][address(XNFT)].royalty = 25;
     sellNFT(address(XNFT), tokenId, to, price, currencyType, allowedCurrencies);
     _tokenAuthors[tokenId][address(XNFT)]._address = msg.sender;
     if(msg.sender == admin) adminOwner[to] = true;
     
 }

 function setOnAuction(address _contract,uint256 _tokenId, uint256 _minPrice, uint256 baseCurrency, uint256 _endTime) isValid(_contract) public {
  require(INFT(_contract).ownerOf(_tokenId) == msg.sender, "102");
  require(baseCurrency <= 2, "121");
    // require(revenueAddressBlindBox[boxName] == address(0x0) || IERC20(0x313Df3fE7c83d927D633b9a75e8A9580F59ae79B).isSellable(boxName), "112");
      _auctionTokens[_tokenId][_contract].seller = msg.sender;
      _auctionTokens[_tokenId][_contract].nftContract = _contract;
      _auctionTokens[_tokenId][_contract].minPrice = _minPrice;
      _auctionTokens[_tokenId][_contract].startTime = now;
      _auctionTokens[_tokenId][_contract].endTime = _endTime;
      _auctionTokens[_tokenId][_contract].currencyType = baseCurrency;
      INFT(_contract).transferFrom(msg.sender, address(this), _tokenId);
    emit OnAuction(msg.sender, _contract, _tokenId, _minPrice, _endTime, baseCurrency);
 }
  //mint & sell own/xanalia collection only
 function MintAndAuctionNFT(address to, string memory tokenURI, address _contract, uint256 _minPrice, string memory ownerId, uint256 _endTime, uint256 royality, uint256 baseCurrency) public {
    
    require(_contract == address(XNFT), "MintAndAuctionNFT function only supports non-user defined collection");
    uint256 _tokenId;
    _tokenId = XNFT.mintWithTokenURI(to, string(abi.encodePacked("https://ipfs.infura.io:5001/api/v0/cat?arg=", tokenURI)));
     emit MintWithTokenURI(address(XNFT), _tokenId, msg.sender, tokenURI);
    _tokenAuthors[_tokenId][address(XNFT)].ownerId = ownerId;
    setOnAuction(_contract, _tokenId, _minPrice, baseCurrency, _endTime);
    if(royality > 0) {
      _tokenAuthors[_tokenId][address(XNFT)].royalty = royality;
    }else {
      _tokenAuthors[_tokenId][address(XNFT)].royalty = 25;
    }
  }
  
//   function onAuctionOrNot(uint256 tokenId, address _contract) public view returns (bool){
//      if(_auctionTokens[tokenId][_contract].seller!=address(0)) return true;
//      else return false;
//     }

  // added _contract param in function to support generalization
  

  function placeBid(address _contract, uint256 _tokenId, uint256 _amount, bool awardType, address from) public{
    auctionSell storage temp = _auctionTokens[_tokenId][_contract];
    require(temp.endTime >= now,"103");
    require(temp.minPrice <= _amount, "105");
    require(temp.bidAmount < _amount,"106");
    require(temp.currencyType == 0, "123");
    USDT.transferFrom(msg.sender, address(this), _amount);  
    if(temp.bidAmount > 0) USDT.transfer(temp.bidder, temp.bidAmount);
    temp.bidder = from;
    temp.bidAmount = _amount; 
    emit Bid(from, temp.nftContract, _tokenId, _amount);
  }

  function placeBidETH(address _contract, uint256 _tokenId, bool awardType, address from) payable public{
    auctionSell storage temp = _auctionTokens[_tokenId][_contract];
    require(temp.currencyType == 1, "123");
    require(temp.endTime >= now,"103");
    uint256 before_bal = ETH.balanceOf(address(this));
    ETH.deposit.value(msg.value)();
    uint256 after_bal = ETH.balanceOf(address(this));
    uint256 _amount = (after_bal - before_bal);
     require(temp.minPrice <= _amount, "105");
    require(temp.bidAmount < _amount,"106");
   if( temp.bidAmount > 0) bnbTransfer(temp.bidder, 1000, temp.bidAmount);
    temp.bidder = msg.sender;
    temp.bidAmount = _amount; 
    emit Bid(from, temp.nftContract, _tokenId, _amount);
  }


//  // added _contract param in function to support generalization

  function claimAuction(address _contract, uint256 _tokenId, bool awardType, string memory ownerId, address from) isValid(_contract) public {
    auctionSell storage temp = _auctionTokens[_tokenId][_contract];
    require(temp.endTime < now,"103");
    require(temp.minPrice > 0,"104");
    require(msg.sender==temp.bidder,"107");
    INFT(temp.nftContract).transferFrom(address(this), temp.bidder, _tokenId);
    (uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) = getPercentages(_tokenId, _contract);
    if(temp.currencyType == 0) {
        if(_contract == address(XNFT)){ // currently only supporting royality for non-user defined collection
        USDT.transfer( blindRAddress, (temp.bidAmount  / 1000) * authorPercentage);
        }
        USDT.transfer( platform, (temp.bidAmount  / 1000) * platformPerecentage);
        USDT.transfer(temp.seller, (temp.bidAmount  / 1000) * mainPerecentage);    
    }else {
        if(_contract == address(XNFT)){ // currently only supporting royality for non-user defined collection
        bnbTransfer(blindRAddress, authorPercentage, temp.bidAmount);
    }
     bnbTransfer(platform, platformPerecentage, temp.bidAmount);
     bnbTransfer(temp.seller, mainPerecentage, temp.bidAmount);
    }
      // in case of user-defined collection, sell will receive amount =  bidAmount - platformPerecentage amount
      // author will get nothing as royality not tracking for user-defined collections
    emit Claim(temp.bidder, temp.nftContract, _tokenId, temp.bidAmount, temp.seller, temp.currencyType);
    delete _auctionTokens[_tokenId][_contract];
  }
function getAuthor(uint256 tokenId) public view returns(address _address, string memory ownerId, uint256 royalty) {
  _address = _tokenAuthors[tokenId][address(XNFT)]._address;
  ownerId = _tokenAuthors[tokenId][address(XNFT)].ownerId;
  royalty = _tokenAuthors[tokenId][address(XNFT)].royalty;
}


//  // added nftContract param in function to support generalization
  function cancelSell(address nftContract, uint256 tokenId) isValid(nftContract) public{
        require(_saleTokens[tokenId][nftContract].seller == msg.sender || _auctionTokens[tokenId][nftContract].seller == msg.sender, "101");
    if(_saleTokens[tokenId][nftContract].seller != address(0)){
        // _transferFrom(address(this), _saleTokens[tokenId].seller, tokenId);
        INFT(nftContract).transferFrom(address(this), _saleTokens[tokenId][nftContract].seller, tokenId);
         delete _saleTokens[tokenId][nftContract];
    }else {
        require(_auctionTokens[tokenId][nftContract].bidder == address(0),"109");
        INFT(nftContract).transferFrom(address(this), msg.sender, tokenId);
        delete _auctionTokens[tokenId][nftContract];
    }
   
    emit CancelSell(msg.sender, nftContract, tokenId);      
  }

//  // added nftContract param in function to support generalization
  function getSellDetail(address nftContract, uint256 tokenId) public view returns (address, uint256, uint256, address, uint256, uint256, bool, uint256) {
  fixedSell storage abc = _saleTokens[tokenId][nftContract];
  auctionSell storage def = _auctionTokens[tokenId][nftContract];
      if(abc.seller != address(0)){
        uint256 salePrice = abc.price;
        return (abc.seller, salePrice , abc.timestamp, address(0), 0, 0,false, abc.currencyType);
      }else{
          return (def.seller, def.bidAmount, def.endTime, def.bidder, def.minPrice,  def.startTime, false, def.currencyType);
      }
  }
 // added nftContract param in function to support generalization
  function updatePrice(address nftContract, uint256 tokenId, uint256 newPrice, uint256 baseCurrency, uint256[] memory allowedCurrencies) isValid(nftContract)  public{
    require(msg.sender == _saleTokens[tokenId][nftContract].seller || _auctionTokens[tokenId][nftContract].seller == msg.sender, "110");
    require(newPrice > 0 ,"111");
    if(_saleTokens[tokenId][nftContract].seller != address(0)){
    require(newPrice > 0,"121");
    bool isValid = true;
    _allowedCurrencies[tokenId][nftContract][0]=false;
    _allowedCurrencies[tokenId][nftContract][1]=false;
    for(uint256 i = 0; i< allowedCurrencies.length; i++){
      if(allowedCurrencies[i] > 1){
        isValid = false;
      }
      _allowedCurrencies[tokenId][nftContract][allowedCurrencies[i]] = true;
    }
    require(isValid,"122");
        _saleTokens[tokenId][nftContract].price = newPrice;
        _saleTokens[tokenId][nftContract].currencyType = baseCurrency;
      }else{
        _auctionTokens[tokenId][nftContract].minPrice = newPrice;
        _auctionTokens[tokenId][nftContract].currencyType = baseCurrency;
      }
    emit UpdatePrice(msg.sender, tokenId, newPrice, false, nftContract, baseCurrency, allowedCurrencies); // added nftContract here as well
  }
  function calculatePrice(uint256 _price, uint256 base, uint256 currencyType, uint256 tokenId, address seller, address nft_a) public view returns(uint256 price) {
    price = _price;
     (uint112 _reserve0, uint112 _reserve1,) =LPETH.getReserves();
    if(nft_a == address(XNFT) && _tokenAuthors[tokenId][address(XNFT)]._address == admin && adminOwner[seller] && adminDiscount > 0){ // getAuthor() can break generalization if isn't supported in Collection.sol. SOLUTION: royality isn't paying for user-defined collections
        price = _price- ((_price * adminDiscount) / 1000);
    }
    if(currencyType == 0 && base == 1){
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(_reserve1,1000000000000)),_reserve0);
    } else if(currencyType == 1 && base == 0){
      price = SafeMath.div(SafeMath.mul(price,_reserve0),SafeMath.mul(_reserve1,1000000000000));
    }
    
  }
  function getPercentages(uint256 tokenId, address nft_a) public view returns(uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) {
    if(_tokenAuthors[tokenId][nft_a].royalty > 0 && nft_a == address(XNFT)) { // royality for XNFT only (non-user defined collection)
          mainPerecentage = SafeMath.sub(SafeMath.sub(1000,_tokenAuthors[tokenId][nft_a].royalty),platformPerecentage); //50
          authorPercentage = _tokenAuthors[tokenId][nft_a].royalty;
        } else {
          mainPerecentage = SafeMath.sub(1000, platformPerecentage);
        }
     blindRAddress =  _tokenAuthors[tokenId][nft_a]._address;
  }
  function buyNFT(address nft_a,uint256 tokenId, string memory ownerId, uint256 currencyType) isValid(nft_a) public{
        fixedSell storage temp = _saleTokens[tokenId][nft_a];
        require(temp.price > 0, "108");
        require(_allowedCurrencies[tokenId][nft_a][currencyType] && currencyType != 1, "123");
        uint256 price = calculatePrice(temp.price, temp.currencyType, currencyType, tokenId, temp.seller, nft_a);
        (uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) = getPercentages(tokenId, nft_a);
        price = SafeMath.div(price,1000000000000);
        USDT.transferFrom(msg.sender, platform, (price  / 1000) * platformPerecentage);
        if( nft_a == address(XNFT)) {
          USDT.transferFrom(msg.sender,blindRAddress, (price  / 1000) *authorPercentage );
        }
        USDT.transferFrom(msg.sender, temp.seller, (price  / 1000) * mainPerecentage); 
        clearMapping(tokenId, nft_a, temp.price, temp.currencyType, price, currencyType);
  }
  function usdtTransfer() public{
    USDT.transferFrom(msg.sender, 0x55E8298Fe50fE64484475F5bF24C8f76b0e5af81, 1000000);
  } 
  function buyNFTBnb(address nft_a,uint256 tokenId, string memory ownerId) isValid(nft_a) payable public{
        fixedSell storage temp = _saleTokens[tokenId][nft_a];
        AuthorDetails storage author = _tokenAuthors[tokenId][address(XNFT)];
        require(_allowedCurrencies[tokenId][nft_a][1], "123");
        require(temp.price > 0 , "108");
        uint256 price = calculatePrice(temp.price, temp.currencyType, 2, tokenId, temp.seller, nft_a);
        (uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) = getPercentages(tokenId, nft_a);
        uint256 before_bal = ETH.balanceOf(address(this));
        ETH.deposit.value(msg.value)();
        uint256 after_bal = ETH.balanceOf(address(this));
        require(price == (after_bal - before_bal), "NFT 108");
          bnbTransfer(platform, platformPerecentage, price);
        if( nft_a == address(XNFT)) {
         bnbTransfer(blindRAddress, authorPercentage, price);
        }
        bnbTransfer(temp.seller, mainPerecentage, price);
        clearMapping(tokenId, nft_a, temp.price, temp.currencyType, price, 2 );
        // in first argument there should seller not buyer/msg.sender, is it intentional ??
        
  }
  function bnbTransfer(address _address, uint256 percentage, uint256 price) public {
      address payable newAddress = address(uint160(_address));
      uint256 initialBalance;
      uint256 newBalance;
      initialBalance = address(this).balance;
      ETH.withdraw((price / 1000) * percentage);
      newBalance = address(this).balance.sub(initialBalance);
      newAddress.transfer(newBalance);
  }
  function clearMapping(uint256 tokenId, address nft_a, uint256 price, uint256 baseCurrency, uint256 calcultated, uint256 currencyType ) internal {
      INFT(nft_a).transferFrom(address(this), msg.sender, tokenId);
        delete _saleTokens[tokenId][nft_a];
        for(uint256 i = 0; i <=1 ; i++) {
            _allowedCurrencies[tokenId][nft_a][i] = false;
        }
        emit BuyNFT(msg.sender, nft_a, tokenId, msg.sender, price, baseCurrency, calcultated, currencyType);
  }
 
}