// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vehicle.sol";

contract Ride is Ownable, Vehicle {
    uint256 rideCount;

    enum appUser {
        Driver,
        Customer,
        NONE
    }

    // Ride data type
    struct RIDE_INFO {
        address driver;
        address customer;
        string pickup;
        string destination;
        uint256 distance;
        VEHICLE_INFO vehicle;
        uint256 price;
        uint256 noOfPassengers;
        bool isCancelled;
        bool isComplete;
        appUser wasCancelledBy;
        string bookingTime;
        string completeTime;
        string cancelledTime;
    }

    struct RIDE {
        uint256 rideId;
        RIDE_INFO rideDetails;
    }

    mapping(uint256 => RIDE) private _rides;


    function confirmRide(RIDE_INFO memory _rideDetails)
        public
        returns (uint256)
    {
        rideCount++;
        RIDE_INFO memory _rideInfo;
        _rideInfo.driver = _rideDetails.driver;
        _rideInfo.customer = _rideDetails.customer;
        _rideInfo.pickup = _rideDetails.pickup;
        _rideInfo.destination = _rideDetails.destination;
        _rideInfo.distance = _rideDetails.distance;
        _rideInfo.vehicle = getVehicle(_rideDetails.driver);
        _rideInfo.price = _rideDetails.price;
        _rideInfo.noOfPassengers = _rideDetails.noOfPassengers;
        _rideInfo.isComplete = false;
        _rideInfo.isCancelled = false;
        _rideInfo.wasCancelledBy = appUser.NONE;
        _rideInfo.bookingTime = "july 7";
        _rideInfo.completeTime = "";
        _rideInfo.cancelledTime = "";


       _rides[rideCount] = RIDE(rideCount, _rideInfo);

    return rideCount;
    }

    function getAllRides(uint256[] memory rideIds)
        public
        view
        returns (RIDE[] memory)
    {
        RIDE[] memory allRides;
        uint256 count = 0;

        for (uint256 i = 0; i < rideIds.length; i++) {
            uint256 rideId = rideIds[i];
            allRides[count] = _rides[rideId];
            count++;
        }

        return allRides;
    }

    function getRide(uint256 _rideId) public view returns (RIDE memory) {
        return _rides[_rideId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vehicle is Ownable {

    enum VEHICLE_TYPE { MINI, PRIME, SEDAN, SUV }

    struct VEHICLE_INFO {
        VEHICLE_TYPE vehicleType;
        string vehicleDocumentsUrl;
        string vehicle_no;
        address owner;
    }

    mapping (address => VEHICLE_INFO) private _vehicles;

    VEHICLE_INFO _vehicle;

    function addVehicle (address owner, string memory vehicleDocumentsUrl, string memory vehicle_no, VEHICLE_TYPE vehicleType ) public onlyOwner {
        _vehicle = VEHICLE_INFO(vehicleType, vehicleDocumentsUrl, vehicle_no, owner);
        _vehicles[owner] = _vehicle;
    }

    function getVehicle (address owner) public view onlyOwner returns (VEHICLE_INFO memory) {
        return _vehicles[owner];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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