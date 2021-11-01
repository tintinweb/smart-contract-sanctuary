/**
 *Submitted for verification at BscScan.com on 2021-11-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// File: contracts\Ownable.sol

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

// File: contracts\IERC20.sol

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
    function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    function nonCryptoNFTVault() external returns(address);
    function mainPerecentage() external returns(uint256);
    function authorPercentage() external returns(uint256);
    function platformPerecentage() external returns(uint256);
    function updateAliaBalance(string calldata stringId, uint256 amount) external returns(bool);
    function getSellDetail(uint256 tokenId) external view returns (address, uint256, uint256, address, uint256, uint256, uint256);
    function getNonCryptoWallet(string calldata ownerId) external view returns(uint256);
    function getNonCryptoOwner(uint256 tokenId) external view returns(string memory);
    function adminOwner(address _address) external view returns(bool);
     function getAuthor(uint256 tokenIdFunction) external view returns (address);
     function _royality(uint256 tokenId) external view returns (uint256);
     function getrevenueAddressBlindBox(string calldata info) external view returns(address);
     function getboxNameByToken(uint256 token) external view returns(string memory);
    //Revenue share
    function addNonCryptoAuthor(string calldata artistId, uint256 tokenId, bool _isArtist) external returns(bool);
    function transferAliaArtist(address buyer, uint256 price, address nftVaultAddress, uint256 tokenId ) external returns(bool);
    function checkArtistOwner(string calldata artistId, uint256 tokenId) external returns(bool);
    function checkTokenAuthorIsArtist(uint256 tokenId) external returns(bool);
    function withdraw(uint) external;
    function deposit() payable external;
    // function approve(address spender, uint256 rawAmount) external;

    // BlindBox ref:https://noborderz.slack.com/archives/C0236PBG601/p1633942033011800?thread_ts=1633941154.010300&cid=C0236PBG601
    function isSellable (string calldata name) external view returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function burn (uint256 tokenId) external;

}

// File: contracts\INFT.sol

pragma solidity ^0.5.0;

// import "../openzeppelin-solidity/contracts/token/ERC721/IERC721Full.sol";

interface INFT {
    function transferFromAdmin(address owner, address to, uint256 tokenId) external;
    function mintWithTokenURI(address to, string calldata tokenURI) external returns (uint256);
    function getAuthor(uint256 tokenIdFunction) external view returns (address);
    function updateTokenURI(uint256 tokenIdT, string calldata uriT) external;
    //
    function mint(address to, string calldata tokenURI) external returns (uint256);
    function transferOwnership(address newOwner) external;
    function ownerOf(uint256 tokenId) external view returns(address);
    function transferFrom(address owner, address to, uint256 tokenId) external;
}

// File: contracts\IFactory.sol

pragma solidity ^0.5.0;


contract IFactory {
    function create(string calldata name_, string calldata symbol_, address owner_) external returns(address);
    function getCollections(address owner_) external view returns(address [] memory);
}

// File: contracts\LPInterface.sol

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

// File: openzeppelin-solidity\contracts\math\SafeMath.sol

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

// File: contracts\Proxy\DexStorage.sol

pragma solidity ^0.5.0;






///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @title DexStorage
 * @dev Defining dex storage for the proxy contract.
 */
///////////////////////////////////////////////////////////////////////////////////////////////////

contract DexStorage {
  using SafeMath for uint256;
   address x; // dummy variable, never set or use its value in any logic contracts. It keeps garbage value & append it with any value set on it.
   IERC20 ALIA;
   INFT XNFT;
   IFactory factory;
   IERC20 OldNFTDex;
   IERC20 BUSD;
   IERC20 BNB;
   struct RDetails {
       address _address;
       uint256 percentage;
   }
  struct AuthorDetails {
    address _address;
    uint256 royalty;
    string ownerId;
    bool isSecondry;
  }
  // uint256[] public sellList; // this violates generlization as not tracking tokenIds agains nftContracts/collections but ignoring as not using it in logic anywhere (uncommented)
  mapping (uint256 => mapping(address => AuthorDetails)) internal _tokenAuthors;
  mapping (address => bool) public adminOwner;
  address payable public platform;
  address payable public authorVault;
  uint256 internal platformPerecentage;
  struct fixedSell {
  //  address nftContract; // adding to support multiple NFT contracts buy/sell 
    address seller;
    uint256 price;
    uint256 timestamp;
    bool isDollar;
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
    bool isDollar;
    uint256 currencyType;
    // address nftAddress;
  }

  
  // tokenId => nftContract => fixedSell
  mapping (uint256 => mapping (address  => fixedSell)) internal _saleTokens;
  mapping(address => bool) public _supportNft;
  // tokenId => nftContract => auctionSell
  mapping(uint256 => mapping ( address => auctionSell)) internal _auctionTokens;
  address payable public nonCryptoNFTVault;
  // tokenId => nftContract => ownerId
  mapping (uint256=> mapping (address => string)) internal _nonCryptoOwners;
  struct balances{
    uint256 bnb;
    uint256 Alia;
    uint256 BUSD;
  }
  mapping (string => balances) internal _nonCryptoWallet;
 
  LPInterface LPAlia;
  LPInterface LPBNB;
  uint256 public adminDiscount;
  address admin;
  mapping (string => address) internal revenueAddressBlindBox;
  mapping (uint256=>string) internal boxNameByToken;
   bool public collectionConfig;
  uint256 public countCopy;
  mapping (uint256=> mapping( address => mapping(uint256 => bool))) _allowedCurrencies;
  IERC20 token;
//   struct offer {
//       address _address;
//       string ownerId;
//       uint256 currencyType;
//       uint256 price;
//   }
//   struct offers {
//       uint256 count;
//       mapping (uint256 => offer) _offer;
//   }
//   mapping(uint256 => mapping(address => offers)) _offers;
  uint256[] allowedArray;

}

// File: contracts\NonCryptoDex.sol

pragma solidity ^0.5.0;



contract NonCryptoDex is Ownable, DexStorage {
   
  event SellNFT(address indexed from, address nft_a, uint256 tokenId, address seller, uint256 price, uint256 royalty, uint256 baseCurrency, uint256[] allowedCurrencies);
  event BuyNFT(address indexed from, address nft_a, uint256 tokenId, address buyer, uint256 price, uint256 baseCurrency, uint256 calculated, uint256 currencyType);
  event BuyNFTNonCrypto( address indexed from, address nft_a, uint256 tokenId, string buyer, uint256 price, uint256 baseCurrency, uint256 calculated, uint256 currencyType);
  event SellNFTNonCrypto( address indexed from, address nft_a, uint256 tokenId, string seller, uint256 price, uint256 baseCurrency, uint256[] allowedCurrencies);
  event MintWithTokenURINonCrypto(address indexed from, string to, string tokenURI, address collection);
  event TransferPackNonCrypto(address indexed from, string to, uint256 tokenId);
  event MintWithTokenURI(address indexed collection, uint256 indexed tokenId, address minter, string tokenURI);

  modifier onlyAdminMinter() {
      require(msg.sender==0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859);
      _;
  }
  function() external payable {}
  
  // modifier to check if given collection is supported by DEX
  modifier isValid( address collection_) {
    require(_supportNft[collection_],"unsupported collection");
    _;
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
     if(msg.sender == nonCryptoNFTVault){
      emit MintWithTokenURINonCrypto(msg.sender, ownerId, tokenURI, address(XNFT));
      _nonCryptoOwners[tokenId][address(XNFT)] = ownerId;
      _tokenAuthors[tokenId][address(XNFT)].ownerId = ownerId;
      emit SellNFTNonCrypto(msg.sender, address(XNFT), tokenId, ownerId, price,  currencyType, allowedCurrencies);
    }
 }
  
  function sellNFT(address nft_a,uint256 tokenId, address seller, uint256 price, uint256 baseCurrency, uint256[] memory allowedCurrencies) isValid(nft_a) public{
    require(msg.sender == admin || (msg.sender == seller && INFT(nft_a).ownerOf(tokenId) == seller), "101");
    // string storage boxName = boxNameByToken[tokenId];
    uint256 royality;
    require(baseCurrency <= 2, "121");
    // require(revenueAddressBlindBox[boxName] == address(0x0) || IERC20(0x313Df3fE7c83d927D633b9a75e8A9580F59ae79B).isSellable(boxName), "112");
    bool isValid = true;
    for(uint256 i = 0; i< allowedCurrencies.length; i++){
      if(allowedCurrencies[i] > 2){
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


  function calculatePrice(uint256 _price, uint256 base, uint256 currencyType, uint256 tokenId, address seller, address nft_a) public view returns(uint256 price) {
    price = _price;
     (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
      (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
    if(nft_a == address(XNFT) && _tokenAuthors[tokenId][address(XNFT)]._address == admin && adminOwner[seller] && adminDiscount > 0){ // getAuthor() can break generalization if isn't supported in Collection.sol. SOLUTION: royality isn't paying for user-defined collections
        price = _price- ((_price * adminDiscount) / 1000);
    }
    if(currencyType == 0 && base == 1){
      price = SafeMath.div(SafeMath.mul(SafeMath.mul(price,reserve1), _reserve1),SafeMath.mul(_reserve0,reserve0));
    } else if(currencyType == 1 && base == 0){
      
      price = SafeMath.div(SafeMath.mul(SafeMath.mul(price,reserve0), _reserve0),SafeMath.mul(_reserve1,reserve1));
      
    } else if (currencyType == 0 && base == 2) {
      price = SafeMath.div(SafeMath.mul(price,reserve0),reserve1);
      
    }else if (currencyType == 1 && base == 2) {
      price = SafeMath.div(SafeMath.mul(price,_reserve1),_reserve0);
    } else if (currencyType == 2 && base == 0) {
      price = SafeMath.div(SafeMath.mul(price,reserve1),reserve0);
    }else if (currencyType ==2 &&  base == 1) {
      price = SafeMath.div(SafeMath.mul(price,_reserve0),_reserve1);
    }
    
  }
  function getPercentages(uint256 tokenId, address nft_a) public view returns(uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) {
    if(_tokenAuthors[tokenId][nft_a].royalty > 0 && nft_a == address(XNFT)) { // royality for XNFT only (non-user defined collection)
          mainPerecentage = SafeMath.sub(SafeMath.sub(1000,_tokenAuthors[tokenId][nft_a].royalty),platformPerecentage); //50
          authorPercentage = _tokenAuthors[tokenId][nft_a].royalty;
        } else {
          mainPerecentage = SafeMath.sub(1000, platformPerecentage);
        }
     blindRAddress = revenueAddressBlindBox[boxNameByToken[tokenId]];
    if(blindRAddress != address(0x0)){
          mainPerecentage = 865;
          authorPercentage =135;    
    }
  }
  function buyNFT(address nft_a,uint256 tokenId, string memory ownerId, uint256 currencyType) isValid(nft_a) public{
        fixedSell storage temp = _saleTokens[tokenId][nft_a];
        require(temp.price > 0, "108");
        require(_allowedCurrencies[tokenId][nft_a][currencyType] && currencyType != 2, "123");
        require(msg.sender != nonCryptoNFTVault || currencyType == 0, "124" );
        uint256 price = calculatePrice(temp.price, temp.currencyType, currencyType, tokenId, temp.seller, nft_a);
        (uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) = getPercentages(tokenId, nft_a);
         token = currencyType == 1 ? BUSD :  ALIA; //IERC20(address(ALIA));
        if(msg.sender == nonCryptoNFTVault) {
          token.mint(nonCryptoNFTVault, price);
          token.transferFrom(nonCryptoNFTVault, platform, (price * 5)/100); // transferring from nonCryptoNFTVault who isn't approved, is it intentional ?
          price= price - ((price * 5)/100);
            
        }
        if(blindRAddress == address(0x0)){
         blindRAddress = _tokenAuthors[tokenId][nft_a]._address;
          token.transferFrom(msg.sender, platform, (price  / 1000) * platformPerecentage);
        }
        if( nft_a == address(XNFT)) {
          token.transferFrom(msg.sender, blindRAddress, (price  / 1000) * authorPercentage);
        }
        
        token.transferFrom(msg.sender, temp.seller, (price  / 1000) * mainPerecentage);
        if(temp.seller == nonCryptoNFTVault) {
          if(currencyType == 0){
            _nonCryptoWallet[_nonCryptoOwners[tokenId][nft_a]].Alia += (price / 1000) * mainPerecentage;
          } else {
            _nonCryptoWallet[_nonCryptoOwners[tokenId][nft_a]].BUSD += (price / 1000) * mainPerecentage;

          }
          // updateAliaBalance(_nonCryptoOwners[tokenId], (price / 1000) * mainPerecentage);
          delete _nonCryptoOwners[tokenId][nft_a];
        }
        if(msg.sender == nonCryptoNFTVault) {
          _nonCryptoOwners[tokenId][nft_a] = ownerId;
        emit BuyNFTNonCrypto(msg.sender, address(this), tokenId, ownerId, temp.price, temp.currencyType, price, currencyType); 
        }
        clearMapping(tokenId, nft_a, temp.price, temp.currencyType, price, currencyType);
        // INFT(nft_a).transferFrom(address(this), msg.sender, tokenId);
        // delete _saleTokens[tokenId][nft_a];
        // _allowedCurrencies[tokenId][0] = false;
        // _allowedCurrencies[tokenId][1] = false;
        // _allowedCurrencies[tokenId][2] = false;
        // in first argument there should seller not buyer/msg.sender, is it intentional ??
        // emit BuyNFT(msg.sender, nft_a, tokenId, msg.sender, temp.price, temp.currencyType, price, currencyType);
  } 

 // added nftContract parameter to support selling NFTs of user-defined collections for NonCrypto.
  function sellNFTNonCrypto(address nftContract, uint256 tokenId, string memory sellerId, uint256 price, uint256 currencyType) isValid(nftContract) public {
    //  sellNFT(address(this), tokenId, nonCryptoNFTVault, price, isDollar);
    // to support generalization
    allowedArray=[0];
    sellNFT(nftContract, tokenId, nonCryptoNFTVault, price, currencyType, allowedArray);
     emit SellNFTNonCrypto( msg.sender, nftContract, tokenId, sellerId, price,  currencyType, allowedArray);
  }
  
   function getNonCryptoWallet(string memory ownerId) public view returns(uint256) {
     return  _nonCryptoWallet[ownerId].Alia;
   }
   // added nftContract parameter to support generlization
   function getNonCryptoOwner(address nftContract, uint256 tokenId) public view returns(string memory) {
       return _nonCryptoOwners[tokenId][nftContract];
   }
 
   function withdrawAlia(address to, uint256 amount, string memory userId) public {
     require(msg.sender == nonCryptoNFTVault, "101");
     require(_nonCryptoWallet[userId].Alia >= amount, "100");
     ALIA.transferFrom(nonCryptoNFTVault, platform, (amount / 100) * 5 );
     uint256 userReceived = amount - ((amount / 100) * 5);
     ALIA.transferFrom(nonCryptoNFTVault, to, userReceived);
     _nonCryptoWallet[userId].Alia -= amount;
   }
     function clearMapping(uint256 tokenId, address nft_a, uint256 price, uint256 baseCurrency, uint256 calcultated, uint256 currencyType ) internal {
      INFT(nft_a).transferFrom(address(this), msg.sender, tokenId);
        delete _saleTokens[tokenId][nft_a];
        for(uint256 i = 0; i <=2 ; i++) {
            _allowedCurrencies[tokenId][nft_a][i] = false;
        }
        // _allowedCurrencies[tokenId][1] = false;
        // _allowedCurrencies[tokenId][2] = false;
        emit BuyNFT(msg.sender, nft_a, tokenId, msg.sender, price, baseCurrency, calcultated, currencyType);
  }
 
}