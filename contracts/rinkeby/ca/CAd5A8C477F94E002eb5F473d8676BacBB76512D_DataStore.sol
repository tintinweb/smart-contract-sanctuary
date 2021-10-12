// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Razak <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./CustomStore.sol";
import "./StoreCore.sol";

contract DataStore is StoreCore, CustomStore {}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
 
pragma solidity ^0.8.0;
pragma abicoder v2;


import "./StoreCore.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StructsDef.sol";
import "./StoreVars.sol";

contract  CustomStore is StructsDef, StoreVars, StoreCore {

   //lets set variables 
    using SafeMath for uint256;

    //acounts deposit info
    //mapping(address => StructsDef.AccountInfo) private creators;

    mapping(uint256 => StructsDef.CategoryInfo) private _categories;

    function setInitialized() public onlyDataWriter {
        require(!initialized, "KALLY_DATA_STORE: ALREADY_INITIALIZED");
        initialized    = true;
    }

    ///////////////// CONFIG ////////////////


    // main config
    StructsDef.ConfigsData  public _mainConfig;

    // get config
    function getMainConfigs() public view returns (ConfigsData memory) {
        return _mainConfig;
    }

    function setConfigsData(ConfigsData memory _configsData) public onlyDataWriter returns(ConfigsData memory) {
        _mainConfig = _configsData;
        return _mainConfig;
    }

    function getMaxRoyaltyPercent() public view returns(uint256) {
        return _mainConfig._feeConfig.maxRoyaltyPercent;
    }

    function getMaintFeePercent() public view returns(uint256) {
        return _mainConfig._feeConfig.mintFeePercent;
    }

    //////////////// END CONFIG //////////////

    /////////////////// START CATEGORIES //////////////////////////

    function nextCategoryId() public onlyDataWriter returns(uint256){
        return ++totalCategories;
    }

    function getCategory(uint256 _id) public view returns(CategoryInfo memory) {
        return  _categories[_id];
    }

    function saveCategory(uint256 _id, CategoryInfo memory _catInfo) public onlyDataWriter {
        _categories[_id] =  _catInfo;
    }
    
    function setTotalDisabledCategories(uint256 _value) public onlyDataWriter {
        totalDisabledCategories = _value;
    } 
    /////////////////////// END CATEGORIES ////////////////////////



    /////////////////// START Market Items //////////////////////////

    // Market Item Info
    // marketItem Id => Item
    mapping(uint256 => StructsDef.MarketItem) private _marketItems;

    // All Bid Info
    // bidId => Bid
    mapping(uint256 => StructsDef.Bid) private _itemBids;

    // Bid Ids for auctionId
    // marketItemId => bidIDs
    mapping(uint256 => uint256[]) private _auctionBids;

    // Bid Ids for auctionId and bidder address
    // marketItemId => (address => BidId)
    mapping(uint256 => mapping(address => uint256)) private _auctionUserBids;

    //marketItemId => winningBid ID
    mapping(uint256 => uint256) private _winningBidId;

    function nextMarketItemId() public onlyDataWriter returns(uint256){
        return ++totalMarketItems;
    }

    function getMarketItem(uint256 _id) public view returns(MarketItem memory) {
        return  _marketItems[_id];
    }

    function saveMarketItem(uint256 _id, MarketItem memory _marketInfo) public onlyDataWriter {
        _marketItems[_id] =  _marketInfo;
    }
    
    function delMarketItem(uint256 _id) public onlyDataWriter {
        _marketItems[_id].isActive  =  false;
        _marketItems[_id].count     =  0;
        _marketItems[_id].updatedAt =  block.timestamp;
    }


    function nextBidId() public onlyDataWriter returns(uint256){
        return ++totalBids;
    }


    function addBid(uint256 _id, Bid memory bid) public onlyDataWriter {
        _itemBids[bid.id] = bid;
        _auctionBids[_id].push(bid.id);
        _auctionUserBids[_id][bid.bidder] = bid.id;

        // check Winning Bid
        Bid memory prevWinningBid = _itemBids[_winningBidId[_id]];

        if(!prevWinningBid.isActive || prevWinningBid.value < bid.value) {
            _winningBidId[_id] = bid.id;
        }
    }

    function increaseBid(uint256 _id, uint256 bidId, uint256 _amount) public onlyDataWriter {
        _itemBids[bidId].value = _itemBids[bidId].value.add(_amount);

         // check Winning Bid
        Bid memory prevWinningBid = _itemBids[_winningBidId[_id]];
        
        if(!prevWinningBid.isActive || prevWinningBid.value < _itemBids[bidId].value) {
            _winningBidId[_id] = bidId;
        }
    }

    function closeBid(uint256 _bidId) public onlyDataWriter {
        _itemBids[_bidId].isActive = false;
    }

    function getBidFromId(uint256 _bidId) public view returns(Bid memory) {
        return _itemBids[_bidId];
    }

    function getBidIdsForAuction(uint256 _id) public view returns (uint256[] memory) {
        return _auctionBids[_id];
    }

    function getBidsLengthForAuction(uint256 _id) public view returns(uint256) {
        return _auctionBids[_id].length;
    }

    function getUserBidForAuction(uint256 _id, address bidder) public view returns(Bid memory) {
        return _itemBids[_auctionUserBids[_id][bidder]];
    }

    function getWinningBidForAuction(uint256 _id) public view returns(Bid memory) {
        return _itemBids[_winningBidId[_id]];
    }

    /////////////////////// END Market Items ////////////////////////

    ///////////////////// START BIDS ////////////////////////////////////
    /**
     * @dev add user bid to history, this will enable us to get user history as fast as possible, without 
     * scanning through numerous 
     * @param _account the account to add bid id to
     * @param _bidId the bid id to add 
     */
    function addUserBidHistory(address _account, uint256 _bidId) public onlyDataWriter {
        _userBidHistory[_account].push(_bidId);
    }
    ///////////////////// END BIDS /////////////////////////////////



    /////////////////// START COLLECTIONS //////////////////////////
    // Collection Map
    // Collection Id => Collection
    mapping(uint256 => Collection) private _collections;

    function nextCollectionId() public onlyDataWriter returns(uint256){
        return ++totalCollections;
    }

    function getCollection(uint256 _id) public view returns(Collection memory) {
        return  _collections[_id];
    }

    function saveCollection(uint256 _id, Collection memory _collection) public onlyDataWriter {
        _collections[_id] =  _collection;
    }
     
    /////////////////////// END COLLECTIONS ////////////////////////

} //end contract

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Razak <[email protected]>
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StoreCore is Ownable {

   event SetDataWriter(address indexed oldWriter, address indexed newWritter);


   address public dataWriter;

   constructor() {
      dataWriter = msg.sender;
   }

   modifier onlyDataWriter {
      require(msg.sender == dataWriter, "KALLY_DATA_STORE: Only Data Writter is Permitted");
      _;
   } 


   //tranfer data writer
   function setDataWriter(address _dataWriter) public onlyOwner {
      address oldWriter = dataWriter;
      dataWriter = _dataWriter;
      emit SetDataWriter(oldWriter,dataWriter);
   }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */

contract StructsDef {

    /**
     * Asset Types
     */
    bytes32 constant public ETH_ASSET_TYPE = bytes32(keccak256("ETH"));
    bytes32 constant public ERC20_ASSET_TYPE = bytes32(keccak256("ERC20"));
    bytes32 constant public ERC721_ASSET_TYPE = bytes32(keccak256("ERC721"));
    bytes32 constant public ERC1155_ASSET_TYPE = bytes32(keccak256("ERC1155"));


    /**
     * Bid Types
     */
    bytes32 constant public FIXED_ASSET_TYPE = bytes32(keccak256("FixedPrice"));
    bytes32 constant public TIMED_ASSET_TYPE = bytes32(keccak256("TimedAuction"));
    bytes32 constant public OPENBID_ASSET_TYPE = bytes32(keccak256("OpenBid"));

    // Royalty Interface
    bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;


    // query filter
    struct MarketDataFilter {
        string  keyword;
        address owner;
        bytes32 bidType;
        uint256 minAskingPrice;
        uint256 maxAskingPrice;
    }

    struct NFTProps {
        uint256 price;
        uint256 royalty;
    }

   /**
    * category definition
    */
    struct CategoryInfo {
        uint256                   id;
        uint256                   parentId;
        string                    name;
        string                    ipfsHash;
        bool                      status;
        uint256                   createdAt;
        uint256                   updatedAt;
    }

    ///////////////// CONFIG STRUCT ////////////////

    struct FeeConfig {
        uint256  maxRoyaltyPercent;
        uint256  mintFeePercent;
        uint256  sellTxFeePercent;
        uint256  buyTxFeePercent;
        uint256  listingFeePercent;
        address  adminFeeAddress;
    }

    struct ConfigsData {
        address erc721Contract;
        address erc1155Contract;
        uint256 dataPerPage;
        FeeConfig _feeConfig;
    }

    ///////////////////// END CONFIG STRUCT /////////////


    ///////////////// Marketplace STRUCT ////////////////
    struct AuctionData {
        bool                      isTimeLimted;
        uint256                   startTime;
        uint256                   endTime;
    }

    struct PriceInfo {
        address                   paymentToken;
        uint256                   value;
    }

    struct MarketItem {
        uint256                   id;
        uint256                   categoryId;
        bytes32                   bidType;
        bytes32                   assetType;
        address                   assetContract;
        uint256                   tokenId;
        uint256                   count;
        address                   owner;
        PriceInfo                 askingPrice;
        AuctionData               auctionData;
        bool                      isActive;
        uint256                   createdAt;
        uint256                   updatedAt;
    }


    struct Bid {
        uint256                   id;
        uint256                   marketId;
        address                   bidder;
        address                   currency;
        uint256                   value;
        bool                      isActive;
        uint256                   createdAt;
    }

    struct Collection {
        uint256                   id;
        string                    uri;
        address                   creator;
        bool                      isActive;
        bool                      isVerified;
        uint256                   createdAt;
    }
    

    ///////////////// Marketplace STRUCT END////////////////

}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Razak <[email protected]>
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../StructsDef.sol";


contract StoreVars {

    ///////////////////////// PUBLIC MAPS //////////////////////

    mapping(address => uint256[]) _userBidHistory;
    mapping (address => uint256[]) _userBuyHistory;
    mapping(address => uint256[]) _userSellHistory;


    /////////////////////// END PUBLIC MAPS ///////////////////

    // initialized 
    bool    public  initialized;

    // total categories
    uint256  public totalCategories; 
    uint256  public totalDisabledCategories;


    // total Market Items
    uint256  public totalMarketItems;
    
    // total Bid Items
    uint256  public totalBids;

    // total Collections
    uint256  public totalCollections;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}