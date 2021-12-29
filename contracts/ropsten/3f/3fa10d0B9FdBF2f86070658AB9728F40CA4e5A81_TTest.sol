// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./interface/IAzimuth.sol";
import "./interface/IEcliptic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract TTest is Context, Ownable {

    //  azimuth: points state data store
    //
    IAzimuth public azimuth;
    
    // fee: exchange transaction fee 
    // 
    uint32 public fee;

    // priceMin: the minimum price allowed to be set for a point
    // 
    uint256 public priceMin;

    // ListedAsset: struct which stores the price and seller's address for a point listed in the marketplace
    // 
    struct ListedAsset {
        address addr;
        uint96 price;
    }

    // assets: registry which stores the ListedAsset entries
    //
    mapping(uint32 => ListedAsset) assets;

    // EVENTS

    event MarketPurchase(
        address indexed _from,
        address indexed _to,
        uint32 _point,
        uint256 _price
    );

    event ListingRemoved(
        uint32 _point
    );

    event ListingAdded(
        uint32 _point,
        uint96 _price 
    );

    // IMPLEMENTATION

    //  constructor(): configure the points data store, exchange fee, and minimum listing price.
    //
    constructor(IAzimuth _azimuth, uint32 _fee, uint256 _priceMin) 
        payable 
    {     
        azimuth = _azimuth;
        setFee(_fee);
        setPriceMin(_priceMin);
    }

    // setRegistryEntry(): utility function to add or remove entries in the registry
    function setRegistryEntry(uint32 _point, address _address, uint96 _price) internal
    {
        ListedAsset memory asset = assets[_point];

        asset = ListedAsset({
             addr: _address,
             price: _price
          });

        assets[_point] = asset;
    }

    //  purchase(): purchase and transfer point from the seller to the buyer
    //
    function purchase(uint32 _point)
        external
        payable
    {
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        
        // get the point's owner 
        address payable seller = payable(azimuth.getOwner(_point));

        // get the point's information from the registry
        ListedAsset memory asset = assets[_point];

        // check that the address in the registry matches the point's current owner
        require(asset.addr == seller, "seller address does not match registry");

        // buyer must pay the exact price as what's stored in the registry for that point
        require(msg.value == asset.price, "Amount transferred does not match price in registry");

        // in order to save on gas fees, a check that the seller has approved the exchange as a 
        // transfer proxy can happen off-chain. 

        // when all conditions are met, transfer the point from the seller to the buyer
        ecliptic.transferFrom(seller, _msgSender(), _point); 

        // set the price of the point in the registry to 0 and clear the associated address.
        // 'asset' already declared in memory so not using the utility function this time
        // 
        asset = ListedAsset({
             addr: address(0),
             price: 0
          });

        assets[_point] = asset;

        // deduct exchange fee and transfer remaining amount to the seller
        seller.transfer(msg.value/100000*(100000-fee));    

        emit MarketPurchase(seller, _msgSender(), _point, msg.value);
    }

    // addListing(): add a point to the registry, including its corresponding price and owner address
    //
    function addListing(uint32 _point, uint96 _price) external
    {
        // intentionally using isOwner() instead of canTransfer(), which excludes third-party proxy addresses.
        // this will ensure the exchange owner also cannot maliciously list an owner's points.
        // 
        require(azimuth.isOwner(_point, _msgSender()), "The message sender is not the point owner");
        
        // listed price must be greater than the minimum price set by the exchange
        // require(priceMin < _price, "The listed price must exceed the minimum price set by the exchange");

        // add the price of the point and the seller address to the registry
        //         
        setRegistryEntry(_point, _msgSender(), _price);        
        
        emit ListingAdded(_point, _price);

    }

    // removeListing(): clear the information for this point in the registry. This function has also been made available
    // to the exchange owner to remove stale listings.
    //
    function removeListing(uint32 _point) external 
    {   
        require(azimuth.isOwner(_point, _msgSender()) || _msgSender() == owner(), "The message sender is not the point owner or the exchange owner");
        
        setRegistryEntry(_point, address(0), 0);

        emit ListingRemoved(_point);
    }

    // getPointInfo(): check the listed price and seller address of a point 
    // 
    function getPointInfo(uint32 _point) external view returns (address, uint256) {
        return (assets[_point].addr, assets[_point].price);
    }

    // EXCHANGE OWNER OPERATIONS
     
    // setFee(): the fee calculation is a percentage of the listed price.
    // for example, an input of 2500 here will be 2.5%
    // 
    function setFee(uint32 _fee) public onlyOwner  {
        require(100000 > _fee, "Input value must be less than 100000");
        fee = _fee;
    }
    // setPriceMin(): the minimum listed price allowed by the exchange
    function setPriceMin(uint256 _priceMin) public onlyOwner  {
        require(0 < _priceMin, "Minimum price must be greater than 0");
        priceMin = _priceMin;
    }
             
    function withdraw(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        _target.transfer(address(this).balance);
    }

    function close(address payable _target) external onlyOwner  {
        require(address(0) != _target);
        selfdestruct(_target);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IAzimuth {
    function owner() external returns (address);
    function isSpawnProxy(uint32, address) external returns (bool);
    function hasBeenLinked(uint32) external returns (bool);
    function getPrefix(uint32) external returns (uint16);
    function getOwner(uint32) view external returns (address);
    function canTransfer(uint32, address) view external returns (bool);
    function isOwner(uint32, address) view external returns (bool);
    function getKeyRevisionNumber(uint32 _point) view external returns(uint32);
    function getSpawnCount(uint32 _point) view external returns(uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IEcliptic {
    function isApprovedForAll(address, address) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function spawn(uint32, address) external;
    function transferPoint(uint32, address, bool) external;


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