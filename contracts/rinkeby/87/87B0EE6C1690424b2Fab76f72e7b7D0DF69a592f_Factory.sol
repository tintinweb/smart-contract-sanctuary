// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */

 /**
  ** K100 - Invalid CategoryId
  ** K200 -
  */
 
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ContractBase.sol";
import "./Category.sol";
import "./Collection.sol";
///import "./Market.sol";
//import "./Auction.sol";

contract Factory is ContractBase, Category, Collection  {

    bool public initialized;

   //config
    StructsDef.ConfigsData private  _initialConfig = StructsDef.ConfigsData({
        
       //erc721 contract 
        erc721Contract: address(0), // please change them here or in admin function
        
        // erc1155 config
        erc1155Contract: address(0), // please change them here or in admin function

        dataPerPage: 15, // items per page for listing data 

        // Fee config structure
        _feeConfig: StructsDef.FeeConfig({
            
            // the maximum royalty a user can set or an asset in basis point system
            maxRoyaltyPercent:  6000,  /// 6000 => 60%  

            // minting fee in basis point system, example: 1% => 100
            mintFeePercent: 100,  // 100 => 1%

            // the fee applied to every asset sold, this will be billed the asset owner
            sellTxFeePercent:  500,  // 500 => 5%
            
            //fee in basis point, this will charged to buyers
            buyTxFeePercent:  0, 

            // listing fee in KALLY
            listingFeePercent:  0, // Fee for listing into the marketplace

            // admin fee address
            adminFeeAddress: address(0x0)
        })


    });

    /**
     * initialize contract
     */
    function initialize (address _storeAddress, address _permissionManager) external onlyOwner {

        require(!initialized, "POLKALLY_DAPP#Factory: ALREADY_INITIALIZED");

        initalizeContractBase(_storeAddress, _permissionManager, _initialConfig);

        initialized = true;
    }

}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./StructsDef.sol";
import "./interfaces/IDataStore.sol";
import "./interfaces/IPolkallyNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PermissionManager/PM.sol";

contract ContractBase is  Ownable, StructsDef, PM {
    using SafeMath for uint256;

    
    bool private isInitialized;

  
    // datastore 
    IDataStore public _dataStore;
    

    // old config data , a little backup
    ConfigsData[]  public  _oldConfigsData;

    /**
     * initialize the data store
     * @param dataStoreAddress the external datastore address
     */
    function initalizeContractBase(address dataStoreAddress, address _permissionManager, ConfigsData memory _initialConfigs) internal {
        
        require(!isInitialized, "POLKALLY#ContractBase: ALREADY_INITIALIZED");

        _dataStore = IDataStore(dataStoreAddress);

        initializePermissionManager(_permissionManager);

        _dataStore.setConfigsData(_initialConfigs);

        isInitialized = true;
    }


    /**
     * get all config data
     */
    function getConfigs() public view returns (ConfigsData memory) {
        return _dataStore.getMainConfigs();
    }

    function getFeeConfig() public view returns (FeeConfig memory) {
        return _dataStore.getMainConfigs()._feeConfig;
    }
    
    /**
     * set config 
     * @param _configData new config data
     */
    function setConfig(ConfigsData memory _configData) public onlySuperAdmin {
        
        //lets do backup first 
        _oldConfigsData.push(getConfigs());

        // lets now update
        _dataStore.setConfigsData(_configData);
    }

    /**
     * check royalties
     * @param _contract ERC721 or ERC1155 contract address to check Royalty
     */
    function checkRoyalties(address _contract) public view returns (bool) {
        (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }


    /**
     * @dev string containers, reference: https://ethereum.stackexchange.com/questions/69307/find-word-in-string-solidity
     * @param mainstr the main string to search from
     * @param substr the substr to check it existence in the main str
     */
    function strContains (string memory mainstr, string memory substr) public pure returns(bool) {
       
        bytes memory whereBytes = bytes (mainstr);
        bytes memory whatBytes = bytes (substr);

        bool found = false;
        for (uint i = 0; i < whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
       
       return found;
    } //end fun 
    
}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ContractBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Category is  ContractBase {

    using SafeMath for uint256;

    event NewCategory(uint256 _id);
    event UpdateCategory(uint256 _id);

 
    /**
     * create category
     * @param  _name     - the name of the category
     * @param  _parentId -  the category Parent, set 0 for base or parentless categoryId
     * @param  _ipfsHash -  the ipfs hash for the category meta data
     * @param  _status   - the status of the newely built category, true for enabled category, false for disabled category
     */
    function newCategory(
        string   memory   _name,
        uint256           _parentId,
        string   memory   _ipfsHash,
       // bytes32[] memory   _tags,
        bool              _status
    ) public onlyAdmin returns(uint256) {

        //if the parentId > 0, then lets verify if it exists and enabled
        if(_parentId > 0){
            CategoryInfo memory catParentInfo = _dataStore.getCategory(_parentId);
            require(catParentInfo.status, "Category#newCategory: INVALID_CATEGORY_PARENT");
        }

        //lets save new data 
        uint256 categoryId = _dataStore.nextCategoryId();

        _dataStore.saveCategory(categoryId, CategoryInfo({
            id:         categoryId,
            name:       _name,
            parentId:   _parentId,
            ipfsHash:   _ipfsHash,
            status:     _status,
            createdAt:  block.timestamp,
            updatedAt:  block.timestamp
        }));


        // if category is disabled by default, add it to disabled category count
        if(!_status) {
            _dataStore.setTotalDisabledCategories(_dataStore.totalDisabledCategories().add(1));
        }

        emit NewCategory(categoryId);

        return categoryId;
    } //end fun 


    /**
     * updateCategory - updates a category
     * @param  _id       -  he category id 
     * @param  _name     -  the name of the category
     * @param  _parentId -  the category Parent, set 0 for base or parentless categoryId
     * @param  _ipfsHash -  the ipfs hash for the category meta data
     * @param  _status   -  the status of the newely built category, true for enabled category, false for disabled category
     */
    function updateCategory(
        uint256           _id,
        string   memory   _name,
        uint256           _parentId,
        string   memory   _ipfsHash,
        bool              _status
    ) public onlyAdmin {

        require(_id > 0 && _id <= _dataStore.totalCategories(), "Category#updateCategory: INVALID_CATEGORY_ID");

        if(_parentId > 0){
            CategoryInfo memory catParentInfo = _dataStore.getCategory(_parentId);
            require(catParentInfo.status, "Category#newCategory: INVALID_CATEGORY_PARENT");
        }

        // get old category info
        CategoryInfo memory oldCatInfo = _dataStore.getCategory(_id);

        // if old category info was disabled
        if(!oldCatInfo.status) {

            //lets check if new category is now enabled 
            if(_status && _dataStore.totalDisabledCategories() > 0) {
                _dataStore.setTotalDisabledCategories(_dataStore.totalDisabledCategories().sub(1));
            }

        } else {

            // if the old category was active, lets check if it has been disabled 
            if(!_status) {
                _dataStore.setTotalDisabledCategories(_dataStore.totalDisabledCategories().add(1));
            }
        } //end keep track of disabled categories

        oldCatInfo.name         = _name;
        oldCatInfo.parentId     = _parentId;
        oldCatInfo.ipfsHash     = _ipfsHash;
        oldCatInfo.status       = _status;
        oldCatInfo.updatedAt    = block.timestamp;
     
        _dataStore.saveCategory(_id, oldCatInfo);

        emit UpdateCategory(_id);
    }

    /**
     * getCategoryById - fetch a category using it id
     * @param _id the categoryId
     */
    function getCategoryById(uint256 _id) public view returns(CategoryInfo memory) {
        require(_id > 0, "Category#getCategoryById: INVALID_CATEGORY_ID");
        
        CategoryInfo memory catData = _dataStore.getCategory(_id);
        
        require(catData.status,"Category#getCategoryById: CATEGORY_DISABLED");

        return catData;
    }


    /**
     * getParentCategories
     */
    function _getCategories(uint256 parentId, bool onlyEnabled) private view returns(CategoryInfo[] memory) {

        uint256 totalCats =  _dataStore.totalCategories().add(1);

        CategoryInfo[] memory categoryDataArray = new CategoryInfo[] (totalCats);
        
        for(uint256 i = 1; i <= totalCats; i++) {
            
            CategoryInfo memory catData = _dataStore.getCategory(i);

            // lets check for a valid category
            if(catData.createdAt == 0) continue;
            
            if(onlyEnabled && !catData.status) continue;

            if(catData.parentId == parentId) categoryDataArray[i] = catData;
        }

        return categoryDataArray;
    } //ed total cats

    /**
     * get parent categories
     */
    function getParentCategories()  public view returns(CategoryInfo[] memory) {
        return _getCategories(0, true);
    }

    /**
     * get category children
     * @param _id the id of the category which we need the sub categories
     */
    function getSubCategories(uint256 _id) public view returns(CategoryInfo[] memory) {
        return _getCategories(_id, true);
    }

    /////////////// ADMIN FUNCTIONS ////////////////
     /**
     * get parent categories
     */
    function adminFetchParentCategories()  public view onlyAdmin returns(CategoryInfo[] memory) {
        return _getCategories(0, false);
    }

    /**
     * get category children
     * @param _id the id of the category which we need the sub categories
     */
    function adminFetchSubCategories(uint256 _id) public view onlyAdmin returns(CategoryInfo[] memory) {
        return _getCategories(_id, false);
    }

    ///////////// END ADMIN FUNCTIONS /////////////////

    /**
     * get Categories 
     *
    function getCategories(
        uint256 fromId, 
        uint256 dataPerPage, 
        bytes32 searchKeyword
    ) public view returns (Category[] memory) {

        uint256 totalCategories =  _dataStore.totalCategories();

        uint256 totalActiveCategories = totalCategories.sub(_dataStore.totalDisabledCategories(), "Category#getCategories: totalActiveCategories sub error");

        if(totalActiveCategories == 0) {
            totalActiveCategories = 1;
        }

        Category[] memory categoryDataArray = new Category[] (totalActiveCategories);
        
        uint256 cursor = fromId;
        uint256 counter;

        while(true) {

            Category memory catData = _dataStore.getCategory(cursor);

            if(!catData.status) continue;

            // lets check if we had search
            if(searchKeyword != ""){
                
                for(uint256 ti = 0; ti < catData.tags.length; ti++){
                    if(searchKeyword == catData.tags[ti]){
                        categoryDataArray[counter++] = catData;
                    }
                }

                return categoryDataArray;
            } //endd if we have search


            categoryDataArray[counter++] = catData;

            if(counter >= (dataPerPage - 1) || cursor >= totalCategories) break;

            cursor++;
        }

        return categoryDataArray;
    }//end get categories   
    */



}

// SPDX-License-Identifier: MIT

/**
 * Polkally (https://polkally.com)
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;

import "./ContractBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Collection is  ContractBase {

    using SafeMath for uint256;

    event NewCollection(uint256 _id);
    event UpdateCollection(uint256 _id);


    /**
     * create collection
     * @param  _uri      - the uri of collection
     * @param  _isActive - the status of collection 
     * @param  _isVerified -  verified status of collection
     */
    function newCollection(
        string   memory   _uri,
        bool              _isActive,
        bool              _isVerified
    ) public onlyAdmin returns(uint256) {
        //lets save new data 
        uint256 collectionId = _dataStore.nextCollectionId();

        _dataStore.saveCollection(collectionId, Collection({
            id:         collectionId,
            uri:        _uri,
            creator:    _msgSender(),
            isActive:   _isActive,
            isVerified: _isVerified,
            createdAt:  block.timestamp
        }));

        emit NewCollection(collectionId);

        return collectionId;
    } //end fun 


    /**
     * updateCollection - updates a collection
     * @param  _id       -  the collection id to update 
     * @param  _uri      - the uri of collection
     * @param  _isActive - the status of collection 
     * @param  _isVerified -  verified status of collection
     */
    function updateCollection(
        uint256           _id,
        string   memory   _uri,
        bool              _isActive,
        bool              _isVerified
    ) public onlyAdmin {

        require(_id > 0 && _id <= _dataStore.totalCollections(), "Collection#updateCollection: INVALID_COLLECTION_ID");

        // get old collection info
        Collection memory oldCollection = _dataStore.getCollection(_id);

        oldCollection.uri            = _uri;
        oldCollection.isActive       = _isActive;
        oldCollection.isVerified     = _isVerified;
        
        
        _dataStore.saveCollection(_id, oldCollection);

        emit UpdateCollection(_id);
    }

    /**
     * verifyCollection - Verify collection
     * @param  _id       -  the collection id to update 
     * @param  _isVerified -  verified status of collection
     */
    function verifyCollection(
        uint256           _id,
        bool              _isVerified
    ) public onlyAdmin {

        require(_id > 0 && _id <= _dataStore.totalCollections(), "Collection#verifyCollection: INVALID_COLLECTION_ID");

        // get old collection info
        Collection memory oldCollection = _dataStore.getCollection(_id);

        require(oldCollection.isVerified != _isVerified, "Collection#verifyCollection: already done");

        oldCollection.isVerified     = _isVerified;
        
        
        _dataStore.saveCollection(_id, oldCollection);

        emit UpdateCollection(_id);
    }


    /**
     * getCollectionById - fetch a collection using it id
     * @param _id the collectionId
     */
    function getCollectionById(uint256 _id) public view returns(Collection memory) {
        require(_id > 0, "CateCollectiongory#getCollectionById: INVALID_COLLECTION_ID");
        
        Collection memory collection = _dataStore.getCollection(_id);

        return collection;
    }


    /**
     * getCategories
     */
    function getCategories(bool onlyActive, bool onlyVerifed) private view returns(Collection[] memory) {

        uint256 totalCollections =  _dataStore.totalCollections().add(1);

        Collection[] memory collectionDataArray = new Collection[] (totalCollections);
        
        for(uint256 i = 1; i <= totalCollections; i++) {
            
            Collection memory catData = _dataStore.getCollection(i);

            // lets check for a valid category
            if(catData.createdAt == 0) continue;
            
            if(onlyActive && !catData.isActive) continue;
            
            if(onlyVerifed && !catData.isVerified) continue;

            collectionDataArray[i] = catData;
        }

        return collectionDataArray;
    } //ed total cats

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
 * @author Polkally <[email protected]>
 */
 
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../StructsDef.sol";
import "../Storage/StoreVars.sol";

abstract contract IDataStore is StructsDef, StoreVars {

    function setMaxRoyaltyBps(uint256 _maxRoyaltyBps) virtual public;
    
    // categories 
    function nextCategoryId()  virtual public returns(uint256);
    function getCategory(uint256 _id) virtual public view returns(CategoryInfo memory);
    function saveCategory(uint256 _id, CategoryInfo memory _catInfo)  virtual public;
    function setTotalDisabledCategories(uint256 _value) virtual public;

    /*/ Markets
    function nextMarketItemId()  virtual public returns(uint256);
    function getMarketItem(uint256 _id) virtual public view returns(MarketItem memory);
    function saveMarketItem(uint256 _id, MarketItem memory _marketInfo)  virtual public;
    function delMarketItem(uint256 _id) virtual public;
    */

    /*/ Auction & Bids
    function nextBidId() virtual public returns(uint256);
    function addBid(uint256 _id, Bid memory bid) virtual public;
    function increaseBid(uint256 _id, uint256 bidId, uint256 _amount) virtual public;
    function closeBid(uint256 _bidId) virtual public;
    function getBidFromId(uint256 _bidId) virtual public view returns(Bid memory);
    function getBidIdsForAuction(uint256 _id) virtual public view returns (uint256[] memory);
    function getBidsLengthForAuction(uint256 _id) virtual public view returns(uint256);
    function getUserBidForAuction(uint256 _id, address bidder) virtual public view returns(Bid memory);
    function getWinningBidForAuction(uint256 _id) virtual public view returns(Bid memory);
    */
    
    // collections 
    function nextCollectionId()  virtual public returns(uint256);
    function getCollection(uint256 _id) virtual public view returns(Collection memory);
    function saveCollection(uint256 _id, Collection memory _collection)  virtual public;
    
    // Bid History
    function addUserBidHistory(address _account, uint256 _bidId) virtual public;
    
    // configs 
    function getMainConfigs() virtual public view returns(ConfigsData memory);
    function setConfigsData(ConfigsData memory _configsData) virtual public returns(ConfigsData memory);


    //basic  store 
    mapping(bytes32 => bool)     public    _boolStore;
    mapping(bytes32 => int256)   public    _intStore;
    mapping(bytes32 => uint256)  public    _uintStore;
    mapping(bytes32 => string)   public    _stringStore;
    mapping(bytes32 => address)  public    _addressStore;
    mapping(bytes32 => bytes)    public    _bytesStore;
    mapping(bytes32 => bytes32)  public    _bytes32Store;


    function setBoolean(bytes32 _k, bool _v) virtual public;
    function setInt(bytes32 _k, int _v) virtual public;
    function setUint(bytes32 _k, uint256 _v) virtual public;
    function setAddress(bytes32 _k, address _v) virtual public;
    function setString(bytes32 _k, string memory _v) virtual public;
    function setBytes(bytes32 _k, bytes memory _v) virtual public;

}

// SPDX-License-Identifier:  GPLv3
pragma solidity ^0.8.0;

interface IPolkallyNFT {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice ) external view returns (address, uint256); 
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