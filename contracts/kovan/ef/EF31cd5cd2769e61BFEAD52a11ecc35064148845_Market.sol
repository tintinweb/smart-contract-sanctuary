// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./MarketCore.sol";


contract Market is  MarketCore {

    constructor(address factory_, address dataStore_, address _permissionManager) {
        initialize(factory_, dataStore_, _permissionManager);
    } //end constructor

}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */

 
pragma solidity ^0.8.0;
pragma abicoder v2;

//import "./ContractBase.sol";
import "../TransferBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../StructsDef.sol";
import "./IMarketDataStore.sol";
import "../interfaces/IFactory.sol";
import "../Price/PriceEngine.sol";
import "../interfaces/IPolkallyNFT.sol";
import "@openzeppelin/contracts/utils/Context.sol";
// ContractBase, TransferBase,

contract MarketCore is  Context, StructsDef, TransferBase, PriceEngine, ReentrancyGuard {

    using SafeMath for uint256;

    event NewList(uint256 _id);
    event DeListed(uint256 _id);
    event Purchase(uint256 _id, uint256 _count);

    bool initialized;
    IMarketDataStore _dataStore;
    IFactory          _factory;

    function initialize(
        address factory_, 
        address dataStore_,
        address permissionManager_
    ) internal {

        require(!initialized, "PolkallyNFT#MarketCore: ALREADY_INITIALIZED");

        _dataStore = IMarketDataStore(dataStore_);
        _factory   = IFactory(factory_);

        initiatePriceEngine(permissionManager_);

        initialized = true;
    }


    /**
     * list new Market Item
     * @param  _assetContract   - Asset Contract address 
     * @param  _tokenId   -  the Id of Token
     * @param  _assetType -  ERC1155 or ERC721
     * @param  _count   -  Total count ERC721 = 1, ERC1155 = multi  
     * @param  _price   -  the asking Price
     * @param  _paymentToken   - the token address for payment
     */
    function list(
        uint256           _categoryId,
        address           _assetContract,
        uint256           _tokenId,
        bytes32           _assetType,
        uint256           _count,
        uint256           _price,
        bytes32           _bidType,
        address           _paymentToken
    ) public payable nonReentrant returns(uint256) {

        require(_price > 0, "Market#list: INVALID_PRICE");
        require(_bidType == FIXED_PRICE_BID_LISTING || _bidType == TIMED_BID_LISTING || _bidType == OPEN_BID_LISTING, "Market#list: UNKNOWN_BID_TYPE");

        //lets save new data 
        uint256 newItemId = _dataStore.nextMarketItemId();

        PriceInfo memory _priceInfo = PriceInfo({
            paymentToken:    _paymentToken,
            value:           _price
        });

        AuctionData memory _auction = AuctionData({
            isTimeLimted:    false,
            startTime:       0,
            endTime:         0
        });

        MarketItem memory _marketItem = MarketItem({
            id:              newItemId,
            categoryId:      _categoryId,
            bidType:         _bidType,
            assetType:       _assetType,
            assetContract:   _assetContract,
            tokenId:         _tokenId,
            count:           _count,
            owner:           _msgSender(),
            askingPrice:     _priceInfo,
            auctionData:     _auction,
            isActive:        true,
            createdAt:       block.timestamp,
            updatedAt:       block.timestamp
        });

        _dataStore.saveMarketItem(newItemId, _marketItem);

        // Transfer Asset To Market Contract.
        transfer(_assetType, _assetContract, _tokenId, _msgSender(), address(this), _count);
        
        // Check Listing fee
        FeeConfig memory feeConfig = _factory.getFeeConfig();

        if(feeConfig.listingFeePercent > 0) {

            uint256 listingFee = _price.mul(feeConfig.listingFeePercent).div(10_000);
            
            if(isNativeAsset(_paymentToken)){
                require(listingFee == msg.value, "Auction#create: INVALID_ETH_FEE");
                transfer(ETH_ASSET_TYPE, _paymentToken, 0, address(this), feeConfig.adminFeeAddress, listingFee);
            } else {
                transfer(ERC20_ASSET_TYPE, _paymentToken, 0, _msgSender(), feeConfig.adminFeeAddress, listingFee);
            }

        }        

        emit NewList(newItemId);

        return newItemId;
    } //end

    /**
     * delist  Item
     * @param  _itemId   - Item Id to delist
     */
    function delist(
        uint256  _itemId
    ) public {
        
        MarketItem memory item = _dataStore.getMarketItem(_itemId);
        
        require(item.isActive, "Market#delist: INVALID_ITEM_ID");
		require(item.owner == _msgSender() || isAdmin(_msgSender()), "Market#delist: only owner can delist");

        transfer(item.assetType, item.assetContract, item.tokenId, address(this), _msgSender(), item.count);
		
		_dataStore.delMarketItem(_itemId);

		emit DeListed(_itemId);
    } //end


    /**
     * Buy Item
     * @param _id uint256 ID of the created Item
     * @param _count : uint256 Count to buy
     */
    function buy(
        uint256 _id,
        uint256 _count
    ) public payable nonReentrant {

        MarketItem memory item = _dataStore.getMarketItem(_id);
        require(item.isActive, "Market#buy: Item is not acitve");
        require(item.bidType  ==  FIXED_PRICE_BID_LISTING, "Market#buy: Item is not Fixed Price");
        require(item.count >= _count, "Market#buy: Insufficient Balance for asset on MarketPlace");

        // Transfer 
        transfer(item.assetType, item.assetContract, item.tokenId, address(this), _msgSender(), _count);

        // Pay for buying
        uint256 totalToPay = item.askingPrice.value.mul(_count);
        bool isNative = isNativeAsset(item.askingPrice.paymentToken);
        require(!isNative || totalToPay == msg.value, "Market#buy: INVALID_ETH_VALUE");

        _distribute(item.assetContract, item.tokenId, item.askingPrice.paymentToken, _msgSender(), item.owner, totalToPay);
        
        item.count = item.count.sub(_count);
        item.isActive = item.count > 0;
        item.updatedAt = block.timestamp;

        _dataStore.saveMarketItem(_id, item);
        
        emit Purchase(_id, _count);  
    }

    function _distribute(address contractAddr, uint256 tokenId, address paymentToken, address from, address to, uint256 amount) internal {
        address royaltyReceiver = address(0x0);
        uint256 royalty = 0;

        if(_factory.checkRoyalties(contractAddr)) {
            (royaltyReceiver, royalty) = IPolkallyNFT(contractAddr).royaltyInfo(tokenId, amount);
        }
        
        FeeConfig memory feeConfig = _factory.getFeeConfig();
        
        uint256 _sellerFee = amount.mul(feeConfig.sellTxFeePercent).div(10_000);
        uint256 _buyerFee = amount.mul(feeConfig.buyTxFeePercent).div(10_000);
        uint256 _sellerCommission = (amount.sub(royalty).sub(_sellerFee)).sub(_buyerFee);
        uint256 _adminCommission = amount.sub(royalty).sub(_sellerCommission);
        
        if(royaltyReceiver != address(0x0) && royalty > 0) {
            transfer(ERC20_ASSET_TYPE, paymentToken, tokenId, from, royaltyReceiver, royalty);
        }
        if(_sellerCommission > 0) {
            transfer(ERC20_ASSET_TYPE, paymentToken, tokenId, from, to, _sellerCommission);
        }
        if(_adminCommission > 0) {
            transfer(ERC20_ASSET_TYPE, paymentToken, tokenId, from, feeConfig.adminFeeAddress, _adminCommission);
        }
    }


    /**
     * @dev get market items
     * @param queryFilter the query filter
     * @param isAdmin wether is admin
     */
    function _getMarketItems(
        uint256 lastItemId,
        MarketDataFilter memory queryFilter,
        bool isAdmin
    ) private view returns (MarketItem[] memory) {
        
        uint256 totalMarketItems = _dataStore.totalMarketItems();

        if(totalMarketItems == 0){
            return (new MarketItem[](0));
        }

        require(lastItemId >= 0 && lastItemId <= totalMarketItems, "Market#getMarketItems: INVALID_LAST_ITEM_ID");

        if(lastItemId == 0) {
            lastItemId = totalMarketItems;
        }

        uint256 dataPerPage  =  _factory.getConfigs().dataPerPage;

        MarketItem[]  memory _marketItemsArray = new MarketItem[](dataPerPage);

        //uint256 _counter;

        for(uint256 i = lastItemId; i >= 1; lastItemId--) {

            if((_marketItemsArray.length - 1) == dataPerPage){
                break;
            }

            MarketItem memory item = _dataStore.getMarketItem(i);

            if(!isAdmin && !item.isActive) continue;

            if(queryFilter.bidType != ""){
                if( item.bidType != queryFilter.bidType) continue;
            }

            if(queryFilter.minAskingPrice > 0){
                if( !(item.askingPrice.value >=  queryFilter.minAskingPrice) ) continue;
            }
            
           if(queryFilter.maxAskingPrice > 0) {
               if(!(item.askingPrice.value <=  queryFilter.maxAskingPrice)) continue;
           }

           if(queryFilter.owner != address(0)) {
               if(item.owner != queryFilter.owner) continue;
           }

            if( bytes(queryFilter.keyword).length > 0 ){
                //lets get the nft name
                //first lets 
            }

            _marketItemsArray[i] = item;
        } //end loop

        return _marketItemsArray;
    }//end 

    
    /**
     * @dev get market items
     * @param queryFilter the query filter
     * @param lastItemId the last item id from previous query
     */
    function adminFetchMarketItems(
        uint256 lastItemId,
        MarketDataFilter memory queryFilter
    ) external view onlyAdmin returns (MarketItem[] memory) {
        return _getMarketItems(lastItemId, queryFilter, true);
    }


        
    /**
     * @dev get market items
     * @param queryFilter the query filter
     */
    function fetchMarketItems(
        uint256 lastItemId,
        MarketDataFilter memory queryFilter
    ) external view returns (MarketItem[] memory) {
        return _getMarketItems(lastItemId, queryFilter, false);
    }
} //en class

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;

//import "./ContractBase.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
import "./StructsDef.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";


contract TransferBase is  StructsDef, ERC721Holder, ERC1155Holder {
    
    address constant NATIVE_TOKEN = address(0x0);

    //event
    event Transfer(bytes32 assetType, address token, uint256 tokenId, address from, address to, uint256 value);

    function transfer(
        bytes32 assetType,
        address token,
        uint256 tokenId,
        address from,
        address to,
        uint256 value
    ) internal {
        if (assetType == ETH_ASSET_TYPE || (assetType == ERC20_ASSET_TYPE && isNativeAsset(token))) {
            (bool success, ) = to.call{ value: value }("");
            require(success, "TransferBase#transfer: ETH transfer failed");
        } else if (assetType == ERC20_ASSET_TYPE) {
            require(IERC20(token).transferFrom(from, to, value), "TransferBase#transfer: ERC20 transfer failed");
        } else if (assetType == ERC721_ASSET_TYPE) {
            require(value == 1, "TransferBase#transfer: erc721 value error");
            IERC721(token).safeTransferFrom(from, to, tokenId); 
        } else if (assetType == ERC1155_ASSET_TYPE) {
            IERC1155(token).safeTransferFrom(from, to, tokenId, value, "");
        } else {
            revert("TransferBase#transfer: INVALID ASSET TYPE");
        }
        emit Transfer(assetType, token, tokenId, from, to, value);
    }


    function isNativeAsset(
        address token
    ) internal pure returns (bool) {
        return token == NATIVE_TOKEN;
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
    bytes32 constant public FIXED_PRICE_BID_LISTING = bytes32(keccak256("FIXED_PRICE_BID_LISTING"));
    bytes32 constant public TIMED_BID_LISTING = bytes32(keccak256("TIMED_BID_LISTING"));
    bytes32 constant public OPEN_BID_LISTING = bytes32(keccak256("OPEN_BID_LISTING"));

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
        string                    name;
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
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;
import "../StructsDef.sol";
import "../Storage/StoreVars.sol";

abstract contract IMarketDataStore is StructsDef, StoreVars {

    // Markets
    function nextMarketItemId()  virtual public returns(uint256);
    function getMarketItem(uint256 _id) virtual public view returns(MarketItem memory);
    function saveMarketItem(uint256 _id, MarketItem memory _marketInfo)  virtual public;
    function delMarketItem(uint256 _id) virtual public;
    
}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;
import "../StructsDef.sol";

abstract contract IFactory is StructsDef {

    address public _dataStore;

    function getConfigs()  virtual public view returns (ConfigsData memory);

    function getFeeConfig() virtual public view returns (FeeConfig memory);

    function checkRoyalties(address _contract) virtual public view returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;


//import "./ContractBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../PermissionManager/PM.sol";

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}


contract PriceEngine is PM {
    
    using SafeMath for uint256;

    /// Chainlink Aggregators
    mapping(address => AggregatorV3Interface) public aggregators;
    
    // events
    event AggregatorUpdated(address tokenAddress, address source);

    constructor() {}

    /**
     * initiate permission manager
     */
    function initiatePriceEngine(address permissionManager_) internal {
        initializePermissionManager(permissionManager_);
    }

    /**
     * Try to get the USD price of Token from Chain Link.
     * @param tokenAddress The token to get the price of
     * @return The price. Return 0 if the aggregator is not set.
     */
    function getPriceFromChainlink(address tokenAddress) internal view returns (uint256) {
        AggregatorV3Interface aggregator = aggregators[tokenAddress];
        if (address(aggregator) != address(0)) {
            ( , int answer, , , ) = aggregator.latestRoundData();

            // It's fine for price to be 0. We have two price feeds.
            if (answer == 0) {
                return 0;
            }

            // Extend the decimals to 1e18.
            uint256 price = uint256(answer).mul(10**(18 - uint(aggregator.decimals())));
            return price;
        }
        return 0;
    }


    function _setAggregators(address[] calldata tokenAddresses, address[] calldata sources) external virtual  onlySuperAdmin {
        for (uint i = 0; i < tokenAddresses.length; i++) {
            aggregators[tokenAddresses[i]] = AggregatorV3Interface(sources[i]);
            emit AggregatorUpdated(tokenAddresses[i], sources[i]);
        }
    }

}

// SPDX-License-Identifier:  GPLv3
pragma solidity ^0.8.0;

interface IPolkallyNFT {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice ) external view returns (address, uint256); 
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */

pragma solidity ^0.8.0;


interface IPermissionManager {
    function isSuperAdmin(address _address) external view  returns(bool);
    function isAdmin(address _address) external view  returns(bool);
    function isModerator(address _address) external view returns(bool);
    //function isStorageEditor(address _address) external view  returns(bool);
    function hasRole(string memory roleName, address _address) external view returns (bool);
    function grantRole(string memory roleName, address _address) external;
}

contract PM {

    event SetPermissionManager(address indexed _contract);

    IPermissionManager public PERMISSION_MANAGER;

    bool pmInitialized;
    
    address _owner;

    constructor() {
      _owner = msg.sender;
    }

    /**
     * initializePM
     */
    function initializePermissionManager(address _permissionManager) internal {
      
      require(!pmInitialized, "PERMISSION_MANAGER_ALREADY_INITIALIZED");

      require(_owner == msg.sender, "ONLY_CONTRACT_OWNER_CAN_INITIALIZE");
      
      PERMISSION_MANAGER = IPermissionManager(_permissionManager);

      //lets add contract as permitted to write on storage
      //PERMISSION_MANAGER.grantRole("STORAGE_EDITOR", address(this));

      emit SetPermissionManager(_permissionManager);

      pmInitialized = true;
    }

   
    /**
     * @dev  set permission manager contract
     */
    function setPermissionManager(address _newAddress) external onlySuperAdmin () {
      
      PERMISSION_MANAGER = IPermissionManager(_newAddress);

      emit SetPermissionManager(_newAddress);
    }

    /**
    * superAdminOnly - a modifier which allows only super admin
    */
    modifier onlySuperAdmin () {
      require(isSuperAdmin(msg.sender), "ONLY_SUPER_ADMINS_ALLOWED" );
      _;
    }

    /**
    * OnlyAdmin
    * This also allows super admins
    */
    modifier onlyAdmin () {
      require(isAdmin(msg.sender), "ONLY_ADMINS_ALLOWED");
      _;
    }

    /**
    * OnlyModerator
    */
    modifier onlyModerator() {
      require(PERMISSION_MANAGER.isModerator(msg.sender), "MODERATORS_ONLY_ALLOWED" );
      _;
    }

   
    /**
     * hasRole
     */
    function hasRole(string memory roleName, address _address) public view returns(bool){
      return PERMISSION_MANAGER.hasRole(roleName,_address);
    }


    /**
     * grant role
     */
    function grantRole(string memory roleName, address _address) public onlySuperAdmin {
      PERMISSION_MANAGER.grantRole(roleName, _address);
    }

    
    function isAdmin(address _address) public view returns(bool){
      return PERMISSION_MANAGER.isAdmin(_address);
    }

    function isSuperAdmin(address _address) public view returns(bool){
      return PERMISSION_MANAGER.isSuperAdmin(_address);
    }


} //end function