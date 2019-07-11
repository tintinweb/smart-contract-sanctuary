pragma solidity >=0.5.0 <0.6.0;

import "SafeMath.sol";
import "ERC721Full.sol";
import "Controlled.sol";
import "TokenClaimer.sol";

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * StickerMarket allows any address register "StickerPack" which can be sold to any address in form of "StickerPack", an ERC721 token.
 */
contract StickerType is Controlled, TokenClaimer, ERC721Full("Sticker Type","STKT") {
    using SafeMath for uint256;
    event Register(uint256 indexed packId, uint256 dataPrice, bytes contenthash, bool mintable);
    event PriceChanged(uint256 indexed packId, uint256 dataPrice);
    event MintabilityChanged(uint256 indexed packId, bool mintable);
    event ContenthashChanged(uint256 indexed packid, bytes contenthash);
    event Categorized(bytes4 indexed category, uint256 indexed packId);
    event Uncategorized(bytes4 indexed category, uint256 indexed packId);
    event Unregister(uint256 indexed packId);

    struct Pack {
        bytes4[] category;
        bool mintable;
        uint256 timestamp;
        uint256 price; //in "wei"
        uint256 donate; //in "percent"
        bytes contenthash;
    }

    uint256 registerFee;
    uint256 burnRate;

    mapping(uint256 => Pack) public packs;
    uint256 public packCount; //pack registers


    //auxilary views
    mapping(bytes4 => uint256[]) private availablePacks; //array of available packs
    mapping(bytes4 => mapping(uint256 => uint256)) private availablePacksIndex; //position on array of available packs
    mapping(uint256 => mapping(bytes4 => uint256)) private packCategoryIndex;

    /**
     * Can only be called by the pack owner, or by the controller if pack exists.
     */
    modifier packOwner(uint256 _packId) {
        address owner = ownerOf(_packId);
        require((msg.sender == owner) || (owner != address(0) && msg.sender == controller), "Unauthorized");
        _;
    }

    /**
     * @notice controller can generate packs at will
     * @param _price cost in wei to users minting with _urlHash metadata
     * @param _donate optional amount of `_price` that is donated to StickerMarket at every buy
     * @param _category listing category
     * @param _owner address of the beneficiary of buys
     * @param _contenthash EIP1577 pack contenthash for listings
     * @return packId Market position of Sticker Pack data.
     */
    function generatePack(
        uint256 _price,
        uint256 _donate,
        bytes4[] calldata _category,
        address _owner,
        bytes calldata _contenthash
    )
        external
        onlyController
        returns(uint256 packId)
    {
        require(_donate <= 10000, "Bad argument, _donate cannot be more then 100.00%");
        packId = packCount++;
        _mint(_owner, packId);
        packs[packId] = Pack(new bytes4[](0), true, block.timestamp, _price, _donate, _contenthash);
        emit Register(packId, _price, _contenthash, true);
        for(uint i = 0;i < _category.length; i++){
            addAvailablePack(packId, _category[i]);
        }
    }

    /**
     * @notice removes all market data about a marketed pack, can only be called by market controller
     * @param _packId position to be deleted
     * @param _limit limit of categories to cleanup
     */
    function purgePack(uint256 _packId, uint256 _limit)
        external
        onlyController
    {
        bytes4[] memory _category = packs[_packId].category;
        uint limit;
        if(_limit == 0) {
            limit = _category.length;
        } else {
            require(_limit <= _category.length, "Bad limit");
            limit = _limit;
        }

        uint256 len = _category.length;
        if(len > 0){
            len--;
        }
        for(uint i = 0; i < limit; i++){
            removeAvailablePack(_packId, _category[len-i]);
        }

        if(packs[_packId].category.length == 0){
            _burn(ownerOf(_packId), _packId);
            delete packs[_packId];
            emit Unregister(_packId);
        }

    }

    /**
     * @notice changes contenthash of `_packId`, can only be called by controller
     * @param _packId which market position is being altered
     * @param _contenthash new contenthash
     */
    function setPackContenthash(uint256 _packId, bytes calldata _contenthash)
        external
        onlyController
    {
        emit ContenthashChanged(_packId, _contenthash);
        packs[_packId].contenthash = _contenthash;
    }

    /**
     * @notice This method can be used by the controller to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token)
        external
        onlyController
    {
        withdrawBalance(_token, controller);
    }

    /**
     * @notice changes price of `_packId`, can only be called when market is open
     * @param _packId pack id changing price settings
     * @param _price cost in wei to users minting this pack
     * @param _donate value between 0-10000 representing percentage of `_price` that is donated to StickerMarket at every buy
     */
    function setPackPrice(uint256 _packId, uint256 _price, uint256 _donate)
        external
        packOwner(_packId)
    {
        require(_donate <= 10000, "Bad argument, _donate cannot be more then 100.00%");
        emit PriceChanged(_packId, _price);
        packs[_packId].price = _price;
        packs[_packId].donate = _donate;
    }

    /**
     * @notice add caregory in `_packId`, can only be called when market is open
     * @param _packId pack adding category
     * @param _category category to list
     */
    function addPackCategory(uint256 _packId, bytes4 _category)
        external
        packOwner(_packId)
    {
        addAvailablePack(_packId, _category);
    }

    /**
     * @notice remove caregory in `_packId`, can only be called when market is open
     * @param _packId pack removing category
     * @param _category category to unlist
     */
    function removePackCategory(uint256 _packId, bytes4 _category)
        external
        packOwner(_packId)
    {
        removeAvailablePack(_packId, _category);
    }

    /**
     * @notice Changes if pack is enabled for sell
     * @param _packId position edit
     * @param _mintable true to enable sell
     */
    function setPackState(uint256 _packId, bool _mintable)
        external
        packOwner(_packId)
    {
        emit MintabilityChanged(_packId, _mintable);
        packs[_packId].mintable = _mintable;
    }

    /**
     * @notice read available market ids in a category (might be slow)
     * @param _category listing category
     * @return array of market id registered
     */
    function getAvailablePacks(bytes4 _category)
        external
        view
        returns (uint256[] memory availableIds)
    {
        return availablePacks[_category];
    }

    /**
     * @notice count total packs in a category
     * @param _category listing category
     * @return total number of packs in category
     */
    function getCategoryLength(bytes4 _category)
        external
        view
        returns (uint256 size)
    {
        size = availablePacks[_category].length;
    }

    /**
     * @notice read a packId in the category list at a specific index
     * @param _category listing category
     * @param _index index
     * @return packId on index
     */
    function getCategoryPack(bytes4 _category, uint256 _index)
        external
        view
        returns (uint256 packId)
    {
        packId = availablePacks[_category][_index];
    }

    /**
     * @notice returns all data from pack in market
     * @param _packId pack id being queried
     * @return categories, owner, mintable, price, donate and contenthash
     */
    function getPackData(uint256 _packId)
        external
        view
        returns (
            bytes4[] memory category,
            address owner,
            bool mintable,
            uint256 timestamp,
            uint256 price,
            bytes memory contenthash
        )
    {
        Pack memory pack = packs[_packId];
        return (
            pack.category,
            ownerOf(_packId),
            pack.mintable,
            pack.timestamp,
            pack.price,
            pack.contenthash
        );
    }

    /**
     * @notice returns all data from pack in market
     * @param _packId pack id being queried
     * @return categories, owner, mintable, price, donate and contenthash
     */
    function getPackSummary(uint256 _packId)
        external
        view
        returns (
            bytes4[] memory category,
            uint256 timestamp,
            bytes memory contenthash
        )
    {
        Pack memory pack = packs[_packId];
        return (
            pack.category,
            pack.timestamp,
            pack.contenthash
        );
    }

    /**
     * @notice returns payment data for migrated contract
     * @param _packId pack id being queried
     * @return owner, mintable, price and donate
     */
    function getPaymentData(uint256 _packId)
        external
        view
        returns (
            address owner,
            bool mintable,
            uint256 price,
            uint256 donate
        )
    {
        Pack memory pack = packs[_packId];
        return (
            ownerOf(_packId),
            pack.mintable,
            pack.price,
            pack.donate
        );
    }

    /**
     * @dev adds id from "available list"
     * @param _packId altered pack
     * @param _category listing category
     */
    function addAvailablePack(uint256 _packId, bytes4 _category) private {
        require(packCategoryIndex[_packId][_category] == 0, "Duplicate categorization");
        availablePacksIndex[_category][_packId] = availablePacks[_category].push(_packId);
        packCategoryIndex[_packId][_category] = packs[_packId].category.push(_category);
        emit Categorized(_category, _packId);
    }

    /**
     * @dev remove id from "available list"
     * @param _packId altered pack
     * @param _category listing category
     */
    function removeAvailablePack(uint256 _packId, bytes4 _category) private {
        uint pos = availablePacksIndex[_category][_packId];
        require(pos > 0, "Not categorized [1]");
        delete availablePacksIndex[_category][_packId];
        if(pos != availablePacks[_category].length){
            uint256 movedElement = availablePacks[_category][availablePacks[_category].length-1]; //tokenId;
            availablePacks[_category][pos-1] = movedElement;
            availablePacksIndex[_category][movedElement] = pos;
        }
        availablePacks[_category].length--;

        uint pos2 = packCategoryIndex[_packId][_category];
        require(pos2 > 0, "Not categorized [2]");
        delete packCategoryIndex[_packId][_category];
        if(pos2 != packs[_packId].category.length){
            bytes4 movedElement2 = packs[_packId].category[packs[_packId].category.length-1]; //tokenId;
            packs[_packId].category[pos2-1] = movedElement2;
            packCategoryIndex[_packId][movedElement2] = pos2;
        }
        packs[_packId].category.length--;
        emit Uncategorized(_category, _packId);

    }

}