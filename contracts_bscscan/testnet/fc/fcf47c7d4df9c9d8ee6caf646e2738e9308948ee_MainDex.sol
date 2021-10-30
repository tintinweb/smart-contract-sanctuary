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

// File: contracts/MainDex.sol

pragma solidity ^0.5.0;




contract MainDex is Ownable, DexStorage {
   
  event updateTokenEvent(address to,uint256 tokenId, string uriT);
  event updateDiscount(uint256 amount);
  event CollectionsConfigured(address indexed xCollection, address factory);
  // event Offer(uint256 tokenId, address indexed from, uint256 currencyType, uint256 offer, uint256 index);
  address a;

  modifier onlyAdminMinter() {
      require(msg.sender==0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859);
      _;
  }
  function() external payable {}

  function init() public {
    require(!collectionConfig,"collections already configured");
    XNFT = INFT(0xCf184b05451dA92c79699FA987852D8f1e47245f); 
    OldNFTDex = IERC20(0xc2F19E2be5c5a1AA7A998f44B759eb3360587ad1);
    ALIA = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    collectionConfig = true;
    admin=0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859;
    LPAlia=LPInterface(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
    LPBNB=LPInterface(0xe230E414f3AC65854772cF24C061776A58893aC2);
    nonCryptoNFTVault = 0x61598488ccD8cb5114Df579e3E0c5F19Fdd6b3Af;
    platform = 0xF0d2D73d09A04036F7587C16518f67cE622129Fd;
    authorVault = 0xF0d2D73d09A04036F7587C16518f67cE622129Fd;
    platformPerecentage = 25;
    countCopy = 0;
    ownerInit();
   factory = IFactory(0x31C863AD3049d4b9F89e12208e4097Ff4B5f603B);
   _supportNft[0xCf184b05451dA92c79699FA987852D8f1e47245f] = true;
   emit CollectionsConfigured(0xCf184b05451dA92c79699FA987852D8f1e47245f, 0x31C863AD3049d4b9F89e12208e4097Ff4B5f603B);
    BUSD = IERC20(0x8D8108A9cFA5a669300074A602f36AF3252B7533);
    BNB= IERC20(0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F);
    _supportNft[address(this)] = true;
    
    a = 0x094616F0BdFB0b526bD735Bf66Eca0Ad254ca81F;
    
  }

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
  
//   function makeOffer(address nft_a, uint256 tokenId, uint256 currencyType, uint256 price) public {
//       require(price > 0, "126");
//       require(currencyType <= 1, "123");
        
//       IERC20 token = currencyType == 1 ? BUSD : ALIA;
//       token.transferFrom(msg.sender, address(this), price);
//       _offers[tokenId][nft_a].count++;
//       _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count] = offer(msg.sender, "", currencyType, price);
//       emit Offer(tokenId, msg.sender, currencyType, price, _offers[tokenId][nft_a].count);
//   }
//   function removeOffer(address nft_a,uint256 tokenId, uint256 index) public {
//       offer storage temp = _offers[tokenId][nft_a]._offer[index];
//       require(temp._address == msg.sender, "127");
//       require(temp.currencyType <= 1, "123");
//       IERC20 token = temp.currencyType == 1 ? BUSD : ALIA;
//       token.transfer(msg.sender, temp.price);
//       _offers[tokenId][nft_a]._offer[index] = _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count];
//       delete _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count];
//       _offers[tokenId][nft_a].count--;
//   }
//   function acceptOffer(address nft_a,uint256 tokenId, uint256 index) public {
//       require(INFT(nft_a).ownerOf(tokenId) == msg.sender || _saleTokens[tokenId][nft_a].seller == msg.sender, "101");
//       offer storage temp = _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count];
//       require(temp._address == msg.sender, "127");
//       require(temp.currencyType <= 1, "123");
//       IERC20 token = temp.currencyType == 1 ? BUSD : ALIA;
//       token.transfer(msg.sender, temp.price);
//       _offers[tokenId][nft_a].count--;
//       delete _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count];
//   }
//   function rejectOffer(address nft_a, uint256 tokenId, uint256 index) public {
//       require(INFT(nft_a).ownerOf(tokenId) == msg.sender || _saleTokens[tokenId][nft_a].seller == msg.sender , "101");
//       offer storage temp = _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count];
//       require(temp._address == msg.sender, "127");
//       require(temp.currencyType <= 1, "123");
//       IERC20 token = temp.currencyType == 1 ? BUSD : ALIA;
//       token.transfer(temp._address, temp.price);
//       _offers[tokenId][nft_a]._offer[index] = _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count];
//       delete _offers[tokenId][nft_a]._offer[_offers[tokenId][nft_a].count];
//       _offers[tokenId][nft_a].count--;
//   }

   function getAliaAddress () public view returns(address) {
      return address(ALIA);
  }

  // function getAllowedCurrencies(uint256 tokenId, address nft_a ) public view returns(uint256[] memory allowedCurrencies) {
  //   uint256[] storage temp;
  //   for(uint256 i = 0; i <=2 ; i++) {
  //     if( _allowedCurrencies[tokenId][nft_a][i]){
  //       temp.push(i);
  //     }     
  //     }
  //   allowedCurrencies = temp;
  // }

 
  
  function setAdminDiscount(uint256 _discount) onlyAdminMinter public {
    adminDiscount = _discount;
    emit updateDiscount(_discount);
  }
  // only xanalia collection i.e XNFT NFT's uri can be updated
   function updateTokenURI(uint256 tokenIdT, string memory uriT) public{
     // anyone can update tokenURI of NFTs owned by admin, is it intentional ??
        require(XNFT.getAuthor(tokenIdT) == admin,"102");
        // _tokenURIs[tokenIdT] = uriT;
        XNFT.updateTokenURI(tokenIdT, uriT);
        emit updateTokenEvent(msg.sender, tokenIdT, uriT);
  }

}