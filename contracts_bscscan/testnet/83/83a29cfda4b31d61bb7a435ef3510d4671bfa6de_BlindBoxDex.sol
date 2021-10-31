/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// File: contracts/Ownable.sol

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

// File: contracts/INFT.sol

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

// File: contracts/Proxy/DexStorage.sol

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

// File: contracts/BlindBoxDex.sol

pragma solidity ^0.5.0;




contract BlindBoxDex is Ownable, DexStorage {

  address a;

  event MintWithTokenURINonCrypto(address indexed from, string to, string tokenURI, address collection);
  event TransferPackNonCrypto(address indexed from, string to, uint256 tokenId);
  event MintWithTokenURI(address indexed collection, uint256 indexed tokenId, address minter, string tokenURI);

  modifier onlyAdminMinter() {
      require(msg.sender==0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859);
      _;
  }
  modifier blindBoxAdd{
   require(msg.sender == 0x313Df3fE7c83d927D633b9a75e8A9580F59ae79B, "not authorized");
   _;
   }
  function() external payable {}

  function updateSellDetail(uint256 tokenId) internal {
    (address seller, uint256 price, uint256 endTime, address bidder, uint256 minPrice, uint256 startTime, uint256 isDollar) = OldNFTDex.getSellDetail(tokenId);
    if(minPrice == 0){
      _saleTokens[tokenId][address(XNFT)].seller = seller;
      _saleTokens[tokenId][address(XNFT)].price = price;
      _saleTokens[tokenId][address(XNFT)].timestamp = endTime;
      if(isDollar == 1){
        _saleTokens[tokenId][address(XNFT)].isDollar = true;
      }
      _allowedCurrencies[tokenId][address(XNFT)][isDollar] = true;
      if(seller == nonCryptoNFTVault){
        string memory ownerId = OldNFTDex.getNonCryptoOwner(tokenId);
        _nonCryptoOwners[tokenId][address(XNFT)] = ownerId;
        _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
      }
    } else {
      _auctionTokens[tokenId][address(XNFT)].seller = seller;
      _auctionTokens[tokenId][address(XNFT)].nftContract = address(this);
      _auctionTokens[tokenId][address(XNFT)].minPrice = minPrice;
      _auctionTokens[tokenId][address(XNFT)].startTime = startTime;
      _auctionTokens[tokenId][address(XNFT)].endTime = endTime;
      _auctionTokens[tokenId][address(XNFT)].bidder = bidder;
      _auctionTokens[tokenId][address(XNFT)].bidAmount = price;
      if(seller == nonCryptoNFTVault ){
         string memory ownerId = OldNFTDex.getNonCryptoOwner(tokenId);
        _nonCryptoOwners[tokenId][address(XNFT)] = ownerId;
        _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
        _auctionTokens[tokenId][address(XNFT)].isDollar = true;
      }
    }
  }

  function mintAdmin(uint256 index) public {
    require(msg.sender == admin,"Not authorized");
    for(uint256 i=1; i<=index; i++){
      countCopy++; 
    // string memory uri = string(abi.encodePacked("https://ipfs.infura.io:5001/api/v0/object/get?arg=", OldNFTDex.tokenURI(countCopy)));
    string memory uri = OldNFTDex.tokenURI(countCopy);
    address to = OldNFTDex.ownerOf(countCopy);
    // OldNFTDex.burn(countCopy);
    if(to == 0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1) {
      XNFT.mintWithTokenURI(address(this),uri);
      updateSellDetail(countCopy);
    } else {
      XNFT.mintWithTokenURI(to, uri);
      adminOwner[to] = OldNFTDex.adminOwner(to);
      if(to == nonCryptoNFTVault){
         string memory ownerId = OldNFTDex.getNonCryptoOwner(countCopy);
        _nonCryptoOwners[countCopy][address(XNFT)] = ownerId;
        _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
      }
      setAuthor(countCopy);
    }
    }
  }
  function mintTokenAdmin(address to, string memory tokenURI) public {
     require(msg.sender == admin,"Not authorized");
      countCopy++;
      XNFT.mintWithTokenURI(to, tokenURI);
      setAuthor(countCopy);
  }

  function setAuthor(uint256 tokenId) internal{
    address author = OldNFTDex.getAuthor(tokenId);
    _tokenAuthors[tokenId][address(XNFT)]._address = author;
    _tokenAuthors[tokenId][address(XNFT)].royalty = OldNFTDex._royality(tokenId);
  }
  
  function blindBoxDetails(uint256 tokenId) internal {
    string memory test = OldNFTDex.getboxNameByToken(tokenId);
    address rAddress = OldNFTDex.getrevenueAddressBlindBox(test);
    boxNameByToken[tokenId] = test;
    revenueAddressBlindBox[test] = rAddress ;
    
  }

  // modifier to check if given collection is supported by DEX
  modifier isValid( address collection_) {
    require(_supportNft[collection_],"unsupported collection");
    _;
  }

function getAuthor(uint256 tokenId) public view returns(address _address, string memory ownerId) {
  _address = _tokenAuthors[tokenId][address(XNFT)]._address;
  ownerId = _tokenAuthors[tokenId][address(XNFT)].ownerId;
}

// blindboxes only can be created on XNFT, no generalization required.
   function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId, string calldata boxName) blindBoxAdd external returns(uint256){
   uint256 tokenId;
  
   tokenId = XNFT.mintWithTokenURI(seller, tokenURI); // removed parameters flag, quantity#1 as signature of mintWithTokenURI changed from accepting 4 params to 2.
   boxNameByToken[tokenId] = boxName;
   // tokenSellTimeBlindbox[boxName] = blindTokenTime;
       if(to == nonCryptoNFTVault){
       // emit MintWithTokenURINonCrypto(msg.sender, ownerId, tokenURI, 1, flag);
       emit TransferPackNonCrypto(msg.sender, ownerId, tokenId);
         _nonCryptoOwners[tokenId][address(this)] = ownerId;
       }
       XNFT.transferFrom(seller, to, tokenId);
       return tokenId;
   }

  function mintAliaForNonCrypto(uint256 price,address from) blindBoxAdd external returns (bool){
      if(from == nonCryptoNFTVault) ALIA.mint(nonCryptoNFTVault, price);
      return true;
  }
  
  function registerAddressBlindbox(address _address, string calldata name) blindBoxAdd external returns(bool) {
    revenueAddressBlindBox[name] = _address;
  }

  // Getter functions to read init() set values
    function getXNFT() public view returns(address){
   
    return address(XNFT);
  }
  function getOldNFTDex() public view returns(address){
   
    return address(OldNFTDex);
  }
  function getAlia() public view returns(address){
   
    return address(ALIA);
  } 
  function getCollectionConfig() public view returns(bool){
   
    return collectionConfig;
  }
  function getAdmin() public view returns(address){
   
    return admin;
  }
  function getLPAlia() public view returns(address){
   
    return address(LPAlia);
  }
  function getLPBNB() public view returns(address){
   
    return address(LPBNB);
  }
  function getNonCryptoNFTVault() public view returns(address){
   
    return nonCryptoNFTVault;
  }
  function getPlatform() public view returns(address){
   
    return platform;
  }
  function getAuthorVault() public view returns(address){
   
    return authorVault;
  }
  function getPlatformPerecentage() public view returns(uint256){
   
    return platformPerecentage;
  }
  function getCountCopy() public view returns(uint256){
   
    return countCopy;
  }
  function getFactory() public view returns(address){
   
    return address(factory);
  }
  function getSupportNft(address addr) public view returns(bool){
   
    return _supportNft[addr];
  }
  function getBUSD() public view returns(address){
   
    return address(BUSD);
  }
  function getBNB() public view returns(address){
   
    return address(BNB);
  }
  function getA() public view returns(address){
   
    return a;
  }


}