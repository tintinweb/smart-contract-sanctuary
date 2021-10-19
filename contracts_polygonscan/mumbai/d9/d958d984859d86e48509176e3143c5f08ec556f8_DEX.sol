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
    function transferFrom(address from, address to, uint256 tokenId) public;
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
    function transferFromAdmin(address owner, uint256 tokenId) external;
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
    //Revenue share
    function addNonCryptoAuthor(string calldata artistId, uint256 tokenId, bool _isArtist) external returns(bool);
    function transferAliaArtist(address buyer, uint256 price, address nftVaultAddress, uint256 tokenId ) external returns(bool);
    function checkArtistOwner(string calldata artistId, uint256 tokenId) external returns(bool);
    function checkTokenAuthorIsArtist(uint256 tokenId) external returns(bool);
    function withdraw(uint) external;
    function deposit() payable external;

    // BlindBox ref:https://noborderz.slack.com/archives/C0236PBG601/p1633942033011800?thread_ts=1633941154.010300&cid=C0236PBG601
    function isSellable (string calldata name) external view returns(bool);

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
   IERC20 ALIA;
   INFT XNFT;
   IFactory factory;
   IERC20 OldNFTDex;
   IERC20 BUSD;
   IERC20 BNB;
  struct AuthorDetails {
    address _address;
    uint256 royalty;
    string ownerId;
  }
  // uint256[] public sellList; // this violates generlization as not tracking tokenIds agains nftContracts/collections but ignoring as not using it in logic anywhere (uncommented)
  mapping (uint256 => mapping(address => AuthorDetails)) _tokenAuthors;
    mapping (address => bool) public adminOwner;
  address payable public platform;
  address payable public authorVault;
  uint256 private platformPerecentage;
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
    address nftAddress;
  }

  
  // tokenId => nftContract => fixedSell
  mapping (uint256 => mapping (address  => fixedSell)) private _saleTokens;
  mapping(address => bool) public _supportNft;
  // tokenId => nftContract => auctionSell
  mapping(uint256 => mapping ( address => auctionSell)) private _auctionTokens;
  address payable public nonCryptoNFTVault;
  // tokenId => nftContract => ownerId
  mapping (uint256=> mapping (address => string)) _nonCryptoOwners;
  struct balances{
    uint256 bnb;
    uint256 Alia;
    uint256 BUSD;
  }
  mapping (string => balances) _nonCryptoWallet;
 
  LPInterface LPAlia;
  // LPInterface LPBNB;
  uint256 public adminDiscount;
  address admin;
  mapping (string => address) revenueAddressBlindBox;
  mapping (uint256=>string) boxNameByToken;
   bool private collectionConfig;

  uint256 public countCopy;
  
  address award;

  event SellNFT(address indexed from, address nft_a, uint256 tokenId, address seller, uint256 price, bool isDollar, uint256 royalty);
  event BuyNFT(address indexed from, address nft_a, uint256 tokenId, address buyer);
  event CancelSell(address indexed from, uint256 tokenId);
  event UpdatePrice(address indexed from, uint256 tokenId, uint256 newPrice, uint256 newDollarPrice);
  event OnAuction(address indexed seller, address nftContract, uint256 indexed tokenId, uint256 startPrice, uint256 endTime);
  event Bid(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event Claim(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);
  event BuyNFTNonCrypto( address indexed from, address nft_a, uint256 tokenId, string buyer);
  event SellNFTNonCrypto( address indexed from, address nft_a, uint256 tokenId, string seller, uint256 price, bool isDollar);
  event MintWithTokenURINonCrypto(address indexed from, string to, string tokenURI);
  event TransferPackNonCrypto(address indexed from, string to, uint256 tokenId);
  event updateTokenEvent(address to,uint256 tokenId, string uriT);
  event updateDiscount(uint256 amount);
  event awardAuctionNFT(address indexed from, address nft_a, uint256 tokenId, string seller, uint256 startPrice, bool isDollar, uint256 endTime);
  event Collection(address indexed creater, address collection);
  event CollectionsConfigured(address indexed xCollection, address factory);
  event NFT(address indexed collection, address minter, uint256 quantity, string tokenURI);


  modifier onlyAdminMinter() {
      require(msg.sender==0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859);
      _;
  }
     function mintAdmin(uint256 index) public {
    require(msg.sender == admin,"Not authorized");
    for(uint256 i=1; i<=index; i++){
      countCopy++; 
    // string memory uri = string(abi.encodePacked("https://ipfs.infura.io:5001/api/v0/object/get?arg=", OldNFTDex.tokenURI(countCopy)));
    string memory uri = OldNFTDex.tokenURI(countCopy);
    address to = OldNFTDex.ownerOf(countCopy);
    // OldNFTDex.burn(countCopy);
    if(to == 0xC84E3F06Ae0f2cf2CA782A1cd0F653663c99280d) {
      XNFT.mintWithTokenURI(address(this),uri);
      updateSellDetail(countCopy);
    } else {
      XNFT.mintWithTokenURI(to, uri);
      adminOwner[to] = OldNFTDex.adminOwner(to);
      if(to == nonCryptoNFTVault){
         string memory ownerId = OldNFTDex.getNonCryptoOwner(countCopy);
        _nonCryptoOwners[countCopy][address(this)] = ownerId;
        _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
      }
      setAuthor(countCopy);
    }
    }
  }

  function updateSellDetail(uint256 tokenId) internal {
    (address seller, uint256 price, uint256 endTime, address bidder, uint256 minPrice, uint256 startTime, uint256 isDollar) = OldNFTDex.getSellDetail(tokenId);
    if(minPrice == 0){
      _saleTokens[tokenId][address(this)].seller = seller;
      _saleTokens[tokenId][address(this)].price = price;
      _saleTokens[tokenId][address(this)].timestamp = endTime;
      if(isDollar == 1){
        _saleTokens[tokenId][address(this)].isDollar = true;
      }
      if(seller == nonCryptoNFTVault){
        string memory ownerId = OldNFTDex.getNonCryptoOwner(tokenId);
        _nonCryptoOwners[tokenId][address(this)] = ownerId;
        _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
      }
    } else {
      _auctionTokens[tokenId][address(this)].seller = seller;
      _auctionTokens[tokenId][address(this)].nftContract = address(this);
      _auctionTokens[tokenId][address(this)].minPrice = minPrice;
      _auctionTokens[tokenId][address(this)].startTime = startTime;
      _auctionTokens[tokenId][address(this)].endTime = endTime;
      _auctionTokens[tokenId][address(this)].bidder = bidder;
      _auctionTokens[tokenId][address(this)].bidAmount = price;
      if(seller == nonCryptoNFTVault ){
         string memory ownerId = OldNFTDex.getNonCryptoOwner(tokenId);
        _nonCryptoOwners[tokenId][address(this)] = ownerId;
        _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
        _auctionTokens[tokenId][address(this)].isDollar = true;
      }
    }
  }

  function setAuthor(uint256 tokenId) internal{
    address author = OldNFTDex.getAuthor(tokenId);
    _tokenAuthors[tokenId][address(this)]._address = author;
    _tokenAuthors[tokenId][address(this)].royalty = OldNFTDex._royality(tokenId);
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
    emit Collection(msg.sender, col);
  }
  /***
* @dev function to mint NFTs on given user-defined collection
* @param collection - address of collection to whom NFT to be created/minted
* @param to - receiving account of minted NFT
* @param tokenURI - metadata URI link of NFT
* @param quantity - number of NFTs to be minted of given URI
*
 */
  function mintNFT(address collection, address to, string memory tokenURI, uint256 quantity ) isValid(collection) public {
 
    address[] memory collections = factory.getCollections(msg.sender);
   
    bool flag;
    for (uint256 i = 0; i < collections.length; i++){
        if (collections[i] == collection){
          flag = true;
          break;
        }
    }
    require(flag, "unauthorized: invalid owner/collection");
    for (uint256 j = 0; j < quantity; j++){
        INFT(collection).mint(to, tokenURI);
    }
    emit NFT(collection, msg.sender, quantity, tokenURI);
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
  
  function sellNFT(address nft_a,uint256 tokenId, address seller, uint256 price, bool isDollar) isValid(nft_a) public{
    require(msg.sender == admin || (msg.sender == seller && INFT(nft_a).ownerOf(tokenId) == seller), "101");
    string storage boxName = boxNameByToken[tokenId];
    uint256 royality;
    require(revenueAddressBlindBox[boxName] == address(0x0) || IERC20(0x313Df3fE7c83d927D633b9a75e8A9580F59ae79B).isSellable(boxName), "112");
    _saleTokens[tokenId][nft_a].seller = seller;
    _saleTokens[tokenId][nft_a].price = price;
    _saleTokens[tokenId][nft_a].timestamp = now;
    _saleTokens[tokenId][nft_a].isDollar = isDollar;
    // need to check if it voilates generalization
    // sellList.push(tokenId);
    // dealing special case of escrowing for xanalia collection i.e XNFT
    if(nft_a == address(XNFT)){
          msg.sender == admin ? XNFT.transferFromAdmin(seller, tokenId) :  XNFT.transferFrom(seller, address(this), tokenId) ;
          royality =  _tokenAuthors[tokenId][nft_a].royalty;
    } else {
      INFT(nft_a).transferFrom(seller, address(this), tokenId);
      royality =  0; // making it zero as not setting royality for user defined collection's NFT
    }
    
    emit SellNFT(msg.sender, nft_a, tokenId, seller, price, isDollar, royality);
  }

  //mint & sell own/xanalia collection only
  function MintAndSellNFT(address to, string memory tokenURI, uint256 price, string memory ownerId, uint256 royality, bool isDollar, bool _isArtist)  public { 
    uint256 tokenId;
     tokenId = XNFT.mintWithTokenURI(to, tokenURI);
     sellNFT(address(this), tokenId, to, price, isDollar);
     _tokenAuthors[tokenId][address(this)]._address = msg.sender;
     if(royality > 0) _tokenAuthors[tokenId][address(this)].royalty = royality;
     else _tokenAuthors[tokenId][address(this)].royalty = 25;
     if(msg.sender == admin) adminOwner[to] = true;
     if(msg.sender == nonCryptoNFTVault){
      emit MintWithTokenURINonCrypto(msg.sender, ownerId, tokenURI);
      _nonCryptoOwners[tokenId][address(this)] = ownerId;
      _tokenAuthors[tokenId][address(this)].ownerId = ownerId;
      emit SellNFTNonCrypto(msg.sender, address(this), tokenId, ownerId, price, isDollar);
     }
 }

 function setOnAuction(address _contract,uint256 _tokenId, uint256 _minPrice, bool isDollar, uint256 _endTime) isValid(_contract) public {
  require(INFT(_contract).ownerOf(_tokenId) == msg.sender, "102");
  string storage boxName = boxNameByToken[_tokenId];
  require(revenueAddressBlindBox[boxName] == address(0x0) || IERC20(0x313Df3fE7c83d927D633b9a75e8A9580F59ae79B).isSellable(boxName), "112");
  _auctionTokens[_tokenId][_contract].seller = msg.sender;
      _auctionTokens[_tokenId][_contract].nftContract = _contract;
      _auctionTokens[_tokenId][_contract].minPrice = _minPrice;
      _auctionTokens[_tokenId][_contract].startTime = now;
      _auctionTokens[_tokenId][_contract].endTime = _endTime;
      if(_minPrice == 0 && msg.sender == nonCryptoNFTVault ){
      emit awardAuctionNFT(msg.sender, address(this), _tokenId, _nonCryptoOwners[_tokenId][address(this)], _minPrice, true, _endTime);
        _auctionTokens[_tokenId][_contract].isDollar = true;
      }
      INFT(_contract).transferFrom(msg.sender, address(this), _tokenId);
    emit OnAuction(msg.sender, _contract, _tokenId, _minPrice, _endTime);
 }
  //mint & sell own/xanalia collection only
 function MintAndAuctionNFT(address to, string memory tokenURI, address _contract, uint256 _minPrice, string memory ownerId, uint256 _endTime, uint256 royality, bool isDollar) public {
    
    require(_contract == address(XNFT), "MintAndAuctionNFT function only supports non-user defined collection");
    uint256 _tokenId;
    _tokenId = XNFT.mintWithTokenURI(to, tokenURI);
    _tokenAuthors[_tokenId][address(this)].ownerId = ownerId;
    if(msg.sender == nonCryptoNFTVault){
      emit MintWithTokenURINonCrypto(msg.sender, ownerId, tokenURI);
      _nonCryptoOwners[_tokenId][address(this)] = ownerId;
      _tokenAuthors[_tokenId][address(this)].ownerId = ownerId;
    }
    setOnAuction(_contract, _tokenId, _minPrice, isDollar, _endTime);
    if(royality > 0) {
      _tokenAuthors[_tokenId][address(this)].royalty = royality;
    }else {
      _tokenAuthors[_tokenId][address(this)].royalty = 25;
    }
  }
  
//   function onAuctionOrNot(uint256 tokenId, address _contract) public view returns (bool){
//      if(_auctionTokens[tokenId][_contract].seller!=address(0)) return true;
//      else return false;
//     }

  // added _contract param in function to support generalization
  

//   function placeBid(address _contract, uint256 _tokenId, uint256 _amount, bool awardType, address from) public{
//     auctionSell storage temp = _auctionTokens[_tokenId][_contract];

//     require(temp.endTime >= now,"103");
//     require(temp.minPrice < _amount || _dollarPrice[_tokenId] < _amount, "105");
//     require(temp.bidAmount < _amount,"106");
//     if(!awardType) {  
//       ALIA.transferFrom(msg.sender, address(this), _amount);  
//       temp.bidAmount > 0 && ALIA.transfer(temp.bidder, temp.bidAmount);
//     }
//     temp.bidder = from;
//     temp.bidAmount = _amount; 
//     emit Bid(from, temp.nftContract, _tokenId, _amount, awardType);
//   }


//  // added _contract param in function to support generalization

//   function claimAuction(address _contract, uint256 _tokenId, bool awardType, string memory ownerId, address from) isValid(_contract) public {
//     auctionSell storage temp = _auctionTokens[_tokenId][_contract];
//     require(temp.endTime < now,"103");
//     require(temp.minPrice > 0,"104");
//     require(msg.sender==temp.bidder,"107");
//     INFT(temp.nftContract).transferFrom(address(this), temp.bidder, _tokenId);

//     mainPerecentage = SafeMath.sub(SafeMath.sub(1000,_tokenAuthors[tokenId][address(this)].royalty),platformPerecentage); //50
//     authorPercentage = _tokenAuthors[tokenId][address(this)].royalty;

//     address blindRAddress = revenueAddressBlindBox[boxNameByToken[_tokenId]];
//     if(blindRAddress == address(0x0)){
//       // blindRAddress=  _tokenAuthors[_tokenId];
//       blindRAddress=  XNFT.getAuthor(_tokenId);
//       ALIA.transfer( platform, (temp.bidAmount / 1000) * platformPerecentage);
//     } else { // it seems overwritting perviously set percentages at "else" scenrio, is it intentional ??
//       mainPerecentage = 865;
//       authorPercentage =135;
//     }
//     if(_contract == address(XNFT)){ // currently only supporting royality for non-user defined collection
//     ALIA.transfer( blindRAddress, (temp.bidAmount  / 1000) * authorPercentage);
//     ALIA.transfer(temp.seller, (temp.bidAmount  / 1000) * mainPerecentage);
//     } else {
//       // in case of user-defined collection, sell will receive amount =  bidAmount - platformPerecentage amount
//       ALIA.transfer(temp.seller, SafeMath.sub(temp.bidAmount, (temp.bidAmount / 1000) * platformPerecentage));
//       // author will get nothing as royality not tracking for user-defined collections
//     }
//     emit Claim(temp.bidder, temp.nftContract, _tokenId, temp.bidAmount);
//     delete _auctionTokens[_tokenId][_contract];
//   }


//  // added nftContract param in function to support generalization
//   function cancelSell(address nftContract, uint256 tokenId) isValid(nftContract) public{
//         require(_saleTokens[tokenId][nftContract].seller == msg.sender || _auctionTokens[tokenId][nftContract].seller == msg.sender, "101");
//     if(_saleTokens[tokenId][nftContract].seller != address(0)){
//         // _transferFrom(address(this), _saleTokens[tokenId].seller, tokenId);
//         INFT(nftContract).transferFrom(address(this), _saleTokens[tokenId][nftContract].seller, tokenId);
//          delete _saleTokens[tokenId][nftContract];
//     }else {
//         require(_auctionTokens[tokenId][nftContract].bidder == address(0),"109");
//         INFT(_auctionTokens[tokenId][nftContract].nftContract).transferFrom(address(this), msg.sender, tokenId);
//         delete _auctionTokens[tokenId][nftContract];
//     }
   
//     emit CancelSell(msg.sender, tokenId);      
//   }

//  // added nftContract param in function to support generalization
  function getSellDetail(address nftContract, uint256 tokenId) public view returns (address, uint256, uint256, address, uint256, uint256, bool) {
  fixedSell storage abc = _saleTokens[tokenId][nftContract];
  auctionSell storage def = _auctionTokens[tokenId][nftContract];
      if(abc.seller != address(0)){
        uint256 salePrice = abc.price;
        return (abc.seller, salePrice , abc.timestamp, address(0), 0, 0,abc.isDollar);
      }else{
          return (def.seller, def.bidAmount, def.endTime, def.bidder, def.minPrice,  def.startTime, def.isDollar);
      }
  }
//  // added nftContract param in function to support generalization
//   function updatePrice(address nftContract, uint256 tokenId, uint256 newPrice, uint256 newDollarPrice) isValid(nftContract)  public{
//     require(msg.sender == _saleTokens[tokenId][nftContract].seller || _auctionTokens[tokenId][nftContract].seller == msg.sender, "110");
//     require(newPrice > 0 || newDollarPrice > 0,"111");
//     if(_saleTokens[tokenId][nftContract].seller != address(0)){
//           if(newPrice == 0){
//             _dollarPrice[tokenId][nftContract] = newDollarPrice; // here to support generalization dollarPrice mapping neet to be changed to keep track nftContracts as well, DONE
//             _saleTokens[tokenId][nftContract].price = 0;
//           } else {
//             _saleTokens[tokenId][nftContract].price = newPrice;
//             _dollarPrice[tokenId][nftContract] = 0; // same goes with dollar price here, DONE
//           }
//       }else{
//           _auctionTokens[tokenId][nftContract].minPrice = newPrice;
//       }
//     emit UpdatePrice(msg.sender, tokenId, newPrice, newDollarPrice, nftContract); // added nftContract here as well
//   }
  
//   function buyNFT(address nft_a,uint256 tokenId, string memory ownerId) isValid(nft_a) public{
//         fixedSell storage temp = _saleTokens[tokenId][nft_a];
//         require(temp.price > 0 || _dollarPrice[tokenId][nft_a] > 0 , "108");
//         uint256 price;
//         if(nft_a == address(XNFT) && XNFT.getAuthor(tokenId) == admin && adminOwner[temp.seller] && adminDiscount > 0){ // getAuthor() can break generalization if isn't supported in Collection.sol. SOLUTION: royality isn't paying for user-defined collections
//         temp.price = temp.price- ((temp.price * adminDiscount) / 1000);
//           _dollarPrice[tokenId][nft_a] = _dollarPrice[tokenId][nft_a] - ((_dollarPrice[tokenId][nft_a]  * adminDiscount) / 1000);
//         }
//          if(temp.price > 0){
//           price = temp.price;
//         } else {
//          (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
//          (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
//          price = SafeMath.div(SafeMath.mul(SafeMath.mul(_dollarPrice[tokenId][nft_a],reserve0), _reserve0),SafeMath.mul(_reserve1,reserve1));
//         }
//         if(_royality[tokenId] > 0 && nft_a == address(XNFT)) { // royality for XNFT only (non-user defined collection)
//           mainPerecentage = SafeMath.sub(SafeMath.sub(1000,_royality[tokenId]),platformPerecentage); //50
//           authorPercentage = _royality[tokenId];
//         } else {
//           mainPerecentage = 950;
//           authorPercentage = 25;
//         }
        
//         if(msg.sender == nonCryptoNFTVault) {
//           ALIA.mint(nonCryptoNFTVault, price);
//           ALIA.transferFrom(nonCryptoNFTVault, platform, (price * 5)/100); // transferring from nonCryptoNFTVault who isn't approved, is it intentional ?
//           price= price - ((price * 5)/100);
            
//         }
//         address blindRAddress = revenueAddressBlindBox[boxNameByToken[tokenId]];
//         if(blindRAddress == address(0x0)){
//           blindRAddress=XNFT.getAuthor(tokenId);
//           ALIA.transferFrom(msg.sender, platform, (price  / 1000) * platformPerecentage);
//         } else {
//           mainPerecentage = 865;
//           authorPercentage =135;
          
//         }
//         if( nft_a == address(XNFT)) {
//           ALIA.transferFrom(msg.sender, blindRAddress, (price  / 1000) * authorPercentage);
//           ALIA.transferFrom(msg.sender, temp.seller, (price  / 1000) * mainPerecentage);
//         } else {
//           // in case of user-defined collection, seller will receive amount =  bidAmount - platformPerecentage
//           ALIA.transferFrom(msg.sender, temp.seller, SafeMath.sub(price, (price  / 1000) * platformPerecentage));
//           // author will get nothing as royality not tracking for user-defined collections
//         }
//         if(temp.seller == nonCryptoNFTVault) {
//           _nonCryptoWallet[_nonCryptoOwners[tokenId][nft_a]] += (price / 1000) * mainPerecentage;
//           // updateAliaBalance(_nonCryptoOwners[tokenId], (price / 1000) * mainPerecentage);
//           delete _nonCryptoOwners[tokenId][nft_a];
//         }
//         if(msg.sender == nonCryptoNFTVault) {
//           _nonCryptoOwners[tokenId][nft_a] = ownerId;
//         emit BuyNFTNonCrypto( msg.sender, address(this), tokenId, ownerId); 
//         }
//         INFT(nft_a).transferFrom(address(this), msg.sender, tokenId);
//         delete _saleTokens[tokenId][nft_a];
//         _dollarPrice[tokenId][nft_a] = 0;
//         // in first argument there should seller not buyer/msg.sender, is it intentional ??
//         emit BuyNFT(msg.sender, nft_a, tokenId, msg.sender);
//   }  
 // added nftContract parameter to support selling NFTs of user-defined collections for NonCrypto.
  // function sellNFTNonCrypto(address nftContract, uint256 tokenId, string memory sellerId, uint256 price, bool isDollar) isValid(nftContract) public {
  //  //  sellNFT(address(this), tokenId, nonCryptoNFTVault, price, isDollar);
  //  // to support generalization
  //  sellNFT(nftContract, tokenId, nonCryptoNFTVault, price, isDollar);
  //   emit SellNFTNonCrypto( msg.sender, nftContract, tokenId, sellerId, price, isDollar);
  // }
  
  // function getNonCryptoWallet(string memory ownerId) public view returns(uint256) {
  //   return  _nonCryptoWallet[ownerId];
  // }
  // // added nftContract parameter to support generlization
  // function getNonCryptoOwner(address nftContract, uint256 tokenId) public view returns(string memory) {
  //     return _nonCryptoOwners[tokenId][nftContract];
  // }
  
  // function setAdminDiscount(uint256 _discount) onlyAdminMinter public {
  //   adminDiscount = _discount;
  //   emit updateDiscount(_discount);
  // }
  // // only xanalia collection i.e XNFT NFT's uri can be updated
  //  function updateTokenURI(uint256 tokenIdT, string memory uriT) public{
  //    // anyone can update tokenURI of NFTs owned by admin, is it intentional ??
  //       require(XNFT.getAuthor(tokenIdT) == admin,"102");
  //       // _tokenURIs[tokenIdT] = uriT;
  //       XNFT.updateTokenURI(tokenIdT, uriT);
  //       emit updateTokenEvent(msg.sender, tokenIdT, uriT);
  // }

  //  modifier blindBoxAdd{
  // require(msg.sender == 0x313Df3fE7c83d927D633b9a75e8A9580F59ae79B, "not authorized");
  // _;
  // }

// blindboxes only can be created on XNFT, no generalization required.
  // function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId, string calldata boxName) blindBoxAdd external returns(uint256){
  // uint256 tokenId;
  
  // tokenId = XNFT.mintWithTokenURI(seller, tokenURI, 1, flag);
  // boxNameByToken[tokenId] = boxName;
  // // tokenSellTimeBlindbox[boxName] = blindTokenTime;
  //     if(to == nonCryptoNFTVault){
  //     // emit MintWithTokenURINonCrypto(msg.sender, ownerId, tokenURI, 1, flag);
  //     emit TransferPackNonCrypto(msg.sender, ownerId, tokenId);
  //       _nonCryptoOwners[tokenId][address(this)] = ownerId;
  //     }
  //     XNFT.transferFrom(seller, to, tokenId);
  //     return tokenId;
  // }

  // function mintAliaForNonCrypto(uint256 price,address from) blindBoxAdd external returns (bool){
  //     if(from == nonCryptoNFTVault) ALIA.mint(nonCryptoNFTVault, price);
  //     return true;
  // }
  
  // function registerAddressBlindbox(address _address, string calldata name) blindBoxAdd external returns(bool) {
  //   revenueAddressBlindBox[name] = _address;
  // }

  // function withdrawAlia(address to, uint256 amount, string memory userId) public {
  //   require(msg.sender == nonCryptoNFTVault, "101");
  //   require(_nonCryptoWallet[userId] >= amount, "100");
  //   ALIA.transferFrom(nonCryptoNFTVault, platform, (amount / 100) * 5 );
  //   uint256 userReceived = amount - ((amount / 100) * 5);
  //   ALIA.transferFrom(nonCryptoNFTVault, to, userReceived);
  //   _nonCryptoWallet[userId] -= amount;
  // }
}

// contract NFTDexV08Polygon is ERC721Full, ERC721MetadataMintable, Ownable {

//     function setOnAuction(address _contract,uint256 _tokenId, uint256 _minPrice, uint256 priceDollar, uint256 _endTime) public {

//     require(ownerOf(_tokenId) == msg.sender, "102");
//       _auctionTokens[_tokenId].seller = msg.sender;
//       _auctionTokens[_tokenId].nftContract = _contract;
//       _auctionTokens[_tokenId].minPrice = _minPrice;
//       _auctionTokens[_tokenId].startTime = now;
//       _auctionTokens[_tokenId].endTime = _endTime;
//       if(_minPrice == 0 && msg.sender == nonCryptoNFTVault ){
//       emit awardAuctionNFT(msg.sender, address(this), _tokenId, _nonCryptoOwners[_tokenId], _minPrice, priceDollar, _endTime);
//         _dollarPrice[_tokenId] = priceDollar;
//       }
//       ERC721Full(_contract).transferFrom(msg.sender, address(this), _tokenId);
//     emit OnAuction(msg.sender, _contract, _tokenId, _minPrice, priceDollar, _endTime);
//   }

//   function MintAndAuctionNFT(address to, string memory tokenURI,uint256 quantity, bool flag, address _contract, uint256 _minPrice, string memory ownerId, uint256 _endTime, uint256 royality, uint256 priceDollar) public {
//       uint256 _tokenId;
//       for(uint256 i = 0; i<quantity; i++)
//       {
//       _tokenId = mintWithTokenURI(to, tokenURI, 1, flag);
//       if(msg.sender == nonCryptoNFTVault){
//         emit MintWithTokenURINonCrypto(msg.sender, ownerId, tokenURI, quantity, flag);
//         _nonCryptoOwners[_tokenId] = ownerId;
//       }
//       setOnAuction(_contract, _tokenId, _minPrice, priceDollar, _endTime);
//       if(royality > 0) _royality[_tokenId] = royality;
//       if(msg.sender == admin) adminOwner[to] = true;
      
//       }
//     }
  


//   function claimAuction(uint256 _tokenId, bool awardType, string memory ownerId, address from) public {
//     auctionSell storage temp = _auctionTokens[_tokenId];
//     require(temp.endTime < now,"103");
//     require((!awardType && msg.sender==temp.bidder) ||  (msg.sender == award && from == temp.bidder),"107");
//     ERC721Full(temp.nftContract).transferFrom(address(this), temp.bidder, _tokenId);
//     if(_royality[_tokenId] > 0) {
//       mainPerecentage = SafeMath.sub(SafeMath.sub(1000,_royality[_tokenId]),platformPerecentage); //50
//       authorPercentage = _royality[_tokenId];
//     } else {
//       mainPerecentage = 950;
//       authorPercentage = 25;
//     }
//     uint256 price = temp.bidAmount;
//     if(awardType) {
//       (uint112 reserve0, uint112 reserve1,) = LPAlia.getReserves();
//       price = SafeMath.div(SafeMath.mul(price,reserve1),SafeMath.mul(reserve0,1000000000000));
//     //   _nonCryptoWallet[_nonCryptoOwners[_tokenId]] += (price / 1000) * mainPerecentage;
//         // delete _nonCryptoOwners[_tokenId];
//        if(from == nonCryptoNFTVault ){
//          ALIA.mint(nonCryptoNFTVault, price);
//          ALIA.transferFrom(nonCryptoNFTVault, platform, (price * 5)/100);
//           price= price - ((price * 5)/100);
//         //  _nonCryptoOwners[_tokenId] = ownerId;
//        }
//        ALIA.transferFrom(from, address(this), price);
//     }
//       ALIA.transfer(aliaHolder,price );
//       revenueShare.transferAlia(price, _tokenId, [mainPerecentage, platformPerecentage,authorPercentage], [aliaHolder, temp.seller, _tokenAuthors[tokenId],platform, nonCryptoNFTVault], _nonCryptoOwners[_tokenId]);
//     //   uint256 authorPrice = (price  / 1000) * authorPercentage;
//     //  if(revenueShare.checkTokenAuthorIsArtist(_tokenId) ){
//     //       ALIA.transfer(aliaHolder,authorPrice );
//     //       revenueShare.transferAliaArtist(aliaHolder, authorPrice, nonCryptoNFTVault, _tokenId, platform,platformPerecentage);
//     //       // revenueShare.transferAliaArtist(aliaHolder, , nonCryptoNFTVault, tokenId,platform, platformPerecentage);
//     //     }else{
//     //       ALIA.transfer(_tokenAuthors[_tokenId], authorPrice);
//     //     }
//     //   ALIA.transfer(temp.seller, (price / 1000) * mainPerecentage);
//     //   ALIA.transfer( platform, (price/ 1000) * platformPerecentage);
//     emit Claim(temp.bidder, temp.nftContract, _tokenId, temp.bidAmount, awardType);
//     if(awardType){
//         // delete _nonCryptoOwners[_tokenId];
//         _nonCryptoOwners[_tokenId] = ownerId;
//     }
//     _dollarPrice[_tokenId] = 0;
//     delete _auctionTokens[_tokenId];
//   }

//   function updateBidder(uint256 _tokenId,address bidAddr, uint256 _amount) public{
//     require(msg.sender == award);    
//     _auctionTokens[_tokenId].bidder = bidAddr;  
//     _auctionTokens[_tokenId].bidAmount = _amount; 
//   }


//   function cancelSell(uint256 tokenId) public{
//     require(_saleTokens[tokenId].seller == msg.sender || _auctionTokens[tokenId].seller == msg.sender, "101");
//     if(_saleTokens[tokenId].seller != address(0)){
//          _transferFrom(address(this), _saleTokens[tokenId].seller, tokenId);
//          delete _saleTokens[tokenId];
//     }else {
//         require(_auctionTokens[tokenId].bidder == address(0),"109");
//         ERC721Full(_auctionTokens[tokenId].nftContract).transferFrom(address(this), msg.sender, tokenId);
//         delete _auctionTokens[tokenId];
//     }
//     emit CancelSell(msg.sender, tokenId);        
//   }

//   function getSellDetail(uint256 tokenId) public view returns (address, uint256, uint256, address, uint256, uint256, uint256) {
//       if(_saleTokens[tokenId].seller != address(0)){
//         uint256 salePrice = _saleTokens[tokenId].price;
//         return (_saleTokens[tokenId].seller, salePrice > 0 ? salePrice : _dollarPrice[tokenId], _saleTokens[tokenId].timestamp, address(0), 0, 0,salePrice == 0 ? 1 : 0);
//       }else{
//         auctionSell storage temp = _auctionTokens[tokenId];
//         return (temp.seller, temp.bidAmount, temp.endTime, temp.bidder, temp.minPrice == 0 ? _dollarPrice[tokenId] : temp.minPrice,  temp.startTime,temp.minPrice == 0 ? 1 : 0);
//        }
//   }

//   function updatePrice(uint256 tokenId, uint256 newPrice, uint256 newDollarPrice)  public{
//     require(msg.sender == _saleTokens[tokenId].seller || _auctionTokens[tokenId].seller == msg.sender, "110");
//     require(newPrice > 0 || newDollarPrice > 0);
//     if(_saleTokens[tokenId].seller != address(0)){
//           if(newPrice == 0){
//             _dollarPrice[tokenId] = newDollarPrice;
//             _saleTokens[tokenId].price = 0;
//           } else {
//             _saleTokens[tokenId].price = newPrice;
//             _dollarPrice[tokenId] = 0;
//           }
//       }else{
//           _auctionTokens[tokenId].minPrice = newPrice;
//       }
//     emit UpdatePrice(msg.sender, tokenId, newPrice, newDollarPrice);
//   }
  
//   function buyNFT(address nft_a,uint256 tokenId, string memory ownerId) public{
//         fixedSell storage temp = _saleTokens[tokenId];
//         require(temp.price > 0 || _dollarPrice[tokenId] > 0);
//         uint256 price;
//         // bool isArtistAuthor = revenueShare.checkTokenAuthorIsArtist(tokenId);
//         if(_tokenAuthors[tokenId] == admin && adminOwner[temp.seller] && adminDiscount > 0){
//         temp.price = temp.price- ((temp.price * adminDiscount) / 1000);
//           _dollarPrice[tokenId] = _dollarPrice[tokenId] - ((_dollarPrice[tokenId]  * adminDiscount) / 1000);
//         }
//          if(temp.price > 0){
//           price = temp.price;
//         } else {
//           (uint112 reserve0, uint112 reserve1,) =LPAlia.getReserves();
//            price = SafeMath.div(SafeMath.mul(_dollarPrice[tokenId],reserve1),SafeMath.mul(reserve0,1000000000000));
//         }
//         if(_royality[tokenId] > 0) {
//           mainPerecentage = SafeMath.sub(SafeMath.sub(1000,_royality[tokenId]),platformPerecentage); //50
//           authorPercentage = _royality[tokenId];
//         } else {
//           mainPerecentage = 950;
//           authorPercentage = 25;
//         }
//         if(msg.sender == nonCryptoNFTVault) {
//           ALIA.mint(nonCryptoNFTVault, price);
//           ALIA.transferFrom(nonCryptoNFTVault, platform, (price * 5)/100);
//           price= price - ((price * 5)/100);
        
//           emit BuyNFTNonCrypto( msg.sender, address(this), tokenId, ownerId);     
//         }

//         ALIA.transferFrom(msg.sender, aliaHolder, price);
//         revenueShare.transferAlia(price, tokenId, [mainPerecentage, platformPerecentage,authorPercentage], [aliaHolder, temp.seller, _tokenAuthors[tokenId],platform, nonCryptoNFTVault], _nonCryptoOwners[tokenId]);
//         _transferFrom(address(this), msg.sender, tokenId);
//         if(msg.sender == nonCryptoNFTVault)_nonCryptoOwners[tokenId] = ownerId;
//         else delete _nonCryptoOwners[tokenId];
//         delete _saleTokens[tokenId];
//          _dollarPrice[tokenId] = 0;
//         emit BuyNFT(msg.sender, nft_a, tokenId, msg.sender);
//   }  
//   function sellNFTNonCrypto(uint256 tokenId, string memory sellerId, uint256 price, uint256 priceDollar) public {
//     sellNFT(address(this), tokenId, nonCryptoNFTVault, price, priceDollar);
//     emit SellNFTNonCrypto( msg.sender, address(this), tokenId, sellerId, price, priceDollar);
//   }
  
//   function getNonCryptoWallet(string memory ownerId) public view returns(uint256) {
//     return  _nonCryptoWallet[ownerId];
//   }
  
//   function getNonCryptoOwner(uint256 tokenId) public view returns(string memory) {
//       return _nonCryptoOwners[tokenId];
//   }
  
//   function setAdminDiscount(uint256 _discount) onlyAdminMinter public {
//     adminDiscount = _discount;
//     emit updateDiscount(_discount);
//   }
  
//   modifier blindBoxAdd{
//   require(msg.sender == 0x773E9CF672c7c4B50C39856A057f5E6581418e3D || msg.sender == 0x1a4cEC7fa278803bF278397F5B09D16a7901ddBa);
//   _;
//   }

//   function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId) blindBoxAdd external returns(uint256){
//   uint256 tokenId;
//   tokenId = mintWithTokenURI(seller, tokenURI, 1, flag);
//       if(to == nonCryptoNFTVault){
//         emit MintWithTokenURINonCrypto(msg.sender, ownerId, tokenURI, 1, flag);
//         emit TransferPackNonCrypto(msg.sender, ownerId, tokenId);
//         _nonCryptoOwners[tokenId] = ownerId;
//       }
//       transferFrom(seller, to, tokenId);
//       return tokenId;
//   }

//   function mintAliaForNonCrypto(uint256 price,address from) blindBoxAdd external returns (bool){
//       if(from == nonCryptoNFTVault) ALIA.mint(nonCryptoNFTVault, price);
//       return true;
//   }
  
//   function updateTokenURI(uint256 tokenIdT, string memory uriT) public{
//         require(_tokenAuthors[tokenIdT] == admin);
//         _tokenURIs[tokenIdT] = uriT;
//         emit updateTokenEvent(msg.sender, tokenIdT, uriT);
//   }

//    function updateAliaBalance(string calldata stringId, uint256 amount) blindBoxAdd external returns(bool) {
//     _nonCryptoWallet[stringId] += amount;
//     return true;
//   } 

//   function burn(uint256 tokenId) external {
//         _burn(tokenId);
//     }
// }


// function listNftAdmin(address owner,uint256 tokenId,uint256 price) public onlyAdminMinter {
//   _saleTokens[tokenId].seller = owner;
//   _saleTokens[tokenId].price = price;
//   _saleTokens[tokenId].timestamp = now;
//   sellList.push(tokenId);
//   transferFromAdmin(owner, tokenId);
// }
// function changeNFTValut(address _newAddress) onlyOwner public {
//   nonCryptoNFTVault = _newAddress;
// }
  // function setValue(uint256 main, uint256 _author, uint256 _platform) onlyOwner public {
  //   require(SafeMath.add(SafeMath.add(main,_author),_platform)==100);
  //   mainPerecentage = main;
  //   authorPercentage = _author;
  //   platformPerecentage = _platform;
  //   emit SetValue(msg.sender, main, _author, _platform);
  // }
//   function setAddresses(address token_addr, address _platform, address _authorVault, address _lp, address lpBnb ) onlyOwner public {
//     ALIA = IERC20(token_addr);
//     platform = _platform;
//     authorVault = _authorVault;
//     LPAlia=LPInterface(_lp);
//     emit SetAddresses(msg.sender, token_addr, _platform, _authorVault);
//   }


// function transferAliaNonCrypto(string memory ownerId, uint256 amount) public {
//     require(_nonCryptoWallet[ownerId] >= amount && msg.sender == nonCryptoNFTVault);
//     _nonCryptoWallet[ownerId] -= amount;
//   }



//   function init() public {
//     require(!collectionConfig,"collections already configured");
//     XNFT = INFT(0x7D3C83C7787d65413E8ECB2631e8Ea733D4d5393); 
//     OldNFTDex = IERC20(0xC84E3F06Ae0f2cf2CA782A1cd0F653663c99280d);
//     ALIA = IERC20(0x6275BD7102b14810C7Cfe69507C3916c7885911A);
//     LPAlia=LPInterface(0x27dD65b98DDAcda1fCbdE9A28f7330f3dFAB304F);
//     collectionConfig = true;
//     admin=0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859;
//     LPAlia=LPInterface(0x52826ee949d3e1C3908F288B74b98742b262f3f1);
//     // LPBNB=LPInterface(0xe230E414f3AC65854772cF24C061776A58893aC2);
//     nonCryptoNFTVault = 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859;
//      platform = 0xF0d2D73d09A04036F7587C16518f67cE622129Fd;
//     authorVault = 0xF0d2D73d09A04036F7587C16518f67cE622129Fd;
//     platformPerecentage = 25;
//     countCopy = 3;
//     ownerInit();
//   factory = IFactory(0xCfaBcfcFCb1B8837B9D6ED0dbBB97C6fC8f9BCdb);
//   _supportNft[0x7D3C83C7787d65413E8ECB2631e8Ea733D4d5393] = true;
//   emit CollectionsConfigured(0x7D3C83C7787d65413E8ECB2631e8Ea733D4d5393, 0xCfaBcfcFCb1B8837B9D6ED0dbBB97C6fC8f9BCdb);
//   }

//   function mintAdmin(uint256 index) public {
//     require(msg.sender == admin,"Not authorized");
//     for(uint256 i=1; i<=index; i++){
//       countCopy++; 
//     // string memory uri = string(abi.encodePacked("https://ipfs.infura.io:5001/api/v0/object/get?arg=", OldNFTDex.tokenURI(countCopy)));
//     string memory uri = OldNFTDex.tokenURI(countCopy);
//     address to = OldNFTDex.ownerOf(countCopy);
//     // OldNFTDex.burn(countCopy);
//     if(to == 0xC84E3F06Ae0f2cf2CA782A1cd0F653663c99280d) {
//       XNFT.mintWithTokenURI(address(this),uri);
//       updateSellDetail(countCopy);
//     } else {
//       XNFT.mintWithTokenURI(to, uri);
//       adminOwner[to] = OldNFTDex.adminOwner(to);
//       if(to == nonCryptoNFTVault){
//          string memory ownerId = OldNFTDex.getNonCryptoOwner(countCopy);
//         _nonCryptoOwners[countCopy][address(this)] = ownerId;
//         _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
//       }
//       setAuthor(countCopy);
//     }
//     }
//   }

//   function updateSellDetail(uint256 tokenId) internal {
//     (address seller, uint256 price, uint256 endTime, address bidder, uint256 minPrice, uint256 startTime, uint256 isDollar) = OldNFTDex.getSellDetail(tokenId);
//     if(minPrice > 0){
//       _saleTokens[tokenId][address(this)].seller = seller;
//       _saleTokens[tokenId][address(this)].price = price;
//       _saleTokens[tokenId][address(this)].timestamp = endTime;
//       if(isDollar == 1){
//         _saleTokens[tokenId][address(this)].isDollar = true;
//       }
//       if(seller == nonCryptoNFTVault){
//         string memory ownerId = OldNFTDex.getNonCryptoOwner(tokenId);
//         _nonCryptoOwners[tokenId][address(this)] = ownerId;
//         _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
//       }
//     } else {
//       _auctionTokens[tokenId][address(this)].seller = seller;
//       _auctionTokens[tokenId][address(this)].nftContract = address(this);
//       _auctionTokens[tokenId][address(this)].minPrice = minPrice;
//       _auctionTokens[tokenId][address(this)].startTime = startTime;
//       _auctionTokens[tokenId][address(this)].endTime = endTime;
//       _auctionTokens[tokenId][address(this)].bidder = bidder;
//       _auctionTokens[tokenId][address(this)].bidAmount = price;
//       if(seller == nonCryptoNFTVault ){
//          string memory ownerId = OldNFTDex.getNonCryptoOwner(tokenId);
//         _nonCryptoOwners[tokenId][address(this)] = ownerId;
//         _nonCryptoWallet[ownerId].Alia = OldNFTDex.getNonCryptoWallet(ownerId);
//         _auctionTokens[tokenId][address(this)].isDollar = true;
//       }
//     }
//   }