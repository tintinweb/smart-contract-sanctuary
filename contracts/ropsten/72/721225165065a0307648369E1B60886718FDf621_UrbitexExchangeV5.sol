// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interface/IAzimuth.sol";
import "./interface/IEcliptic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract UrbitexExchangeV5 is Context, Ownable {

    //  azimuth: points state data store
    //
    IAzimuth public azimuth;
    
    // fee: exchange transaction fee 
    // 
    uint256 fee;

    // prices: registry which holds the prices set by sellers for their azimuth points in the marketplace
    //
    mapping(uint32 => uint256) prices;

    // EVENTS

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _point,
        uint256 _price
    );

    // IMPLEMENTATION

    //  constructor(): configure the points data store and exchange fee
    //
    constructor(IAzimuth _azimuth, uint256 _fee) 
        payable 
    {     
        require(100000 > _fee, "Input value must be less than 100000");
        azimuth = _azimuth;
        fee = _fee;
    }

    //  purchase(): purchase and transfer azimuth point from the seller to the buyer
    //
    function purchase(uint32 _point)
        external
        payable
    {
        IEcliptic ecliptic = IEcliptic(azimuth.owner());
        
        // get the point's owner 
        address payable seller = payable(azimuth.getOwner(_point));

        // get the price of the point from the registry
        uint256 price = prices[_point];

        // buyer must pay the exact price as what's stored in the registry for that point
        require(msg.value == price, "Amount transferred does not match price in registry");

        // amount cannot be zero.
        require(0 < msg.value, "Amount must be greater than zero");

        // the exchange must be an approved transfer proxy for this point.
        (bool success) = ecliptic.isApprovedForAll(seller, address(this));
        require(success, "The exchange is not authorized as a transfer proxy for this point");

        // when all conditions are met, transfer the point from the seller to the buyer
        ecliptic.transferFrom(seller, _msgSender(), _point); 

        // set the price of the point in the registry to 0
        prices[_point] = 0;

        // deduct exchange fee and transfer remaining amount to the seller
        seller.transfer(msg.value/100000*(100000-fee));    

        emit Transfer(seller, _msgSender(), _point, msg.value);
    }

    // addListing(): add a point and its corresponding price to the registry
    //
    function addListing(uint32 _point, uint256 _price) external returns(bool success)
    {
        // using canTransfer() here instead of isOwner(), since the owner can authorize a third-party
        // operator to transfer.
        // 
        require(azimuth.canTransfer(_point, _msgSender()), "The message sender is not the point owner or an authorized proxy address");
        
        // listed price must be greater than zero
        require(0 < _price, "The listed price must be greater than zero");

        // set the price of the point, add it to the prices registry 
        prices[_point] = _price;

        return true;
    }
    
    // getListedPrice(): check the listed price of an azimuth point 
    // 
    function getListedPrice(uint32 _point) external view returns (uint256){                
        return prices[_point];  
    }

    // EXCHANGE OWNER OPERATIONS

    // removeListing(): this function is available to the exchange owner to manually remove a listed price, if ever needed.
    //
    function removeListing(uint32 _point) external onlyOwner {                        
        prices[_point] = 0;
    }

    function changeFee(uint256 _fee) external onlyOwner  {
        require(100000 > _fee, "Input value must be less than 100000");
        fee = _fee;       
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
pragma solidity ^0.8.0;

interface IAzimuth {
    function isOwner(uint32, address) external returns (bool);
    function owner() external returns (address);
    function isSpawnProxy(uint32, address) external returns (bool);
    function hasBeenLinked(uint32) external returns (bool);
    function getPrefix(uint32) external returns (uint16);
    function getOwner(uint32) view external returns (address);
    function canTransfer(uint32, address) view external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEcliptic {
    function isApprovedForAll(address, address) external returns (bool);
    function transferFrom(address, address, uint256) external;
    function spawn(uint32, address) external;
    function getPrefix(uint32) external returns (uint16);
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