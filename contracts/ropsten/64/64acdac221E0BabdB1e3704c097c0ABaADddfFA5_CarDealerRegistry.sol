/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity >=0.4.21 <=0.6.10;
pragma experimental ABIEncoderV2;

contract CarDealerRegistry {

    address public owner;

    struct Car {
        address carId;
        uint256 carPrice;
        uint256 isBooked;
        uint256 createdAt;
    }

    struct CarBooking {
        address carId;
        bytes32 bookingId;
        address customer;
        uint256 createdAt;
    }

    constructor(
        address _owner
    ) public {
        owner = _owner;
    }

    // mapping for: carId -> carEntity
    mapping(address => Car) private carMap;

    //storage variables for Booking, and related Mappings

    // bookingId -> CarBooking
    mapping(bytes32 => CarBooking) private carBookingMap;

    //customer => CarBookingId
    mapping(address => bytes32[]) private customerBookings;
 
    modifier onlyOwner {
        require(msg.sender == owner, "only Owner can invoke the function");
        _;
    }

    function getOwner() public view returns(address){
        return owner;
    }

    function addACarToInventory(address carAddress, uint256 carPrice) onlyOwner public  {
        require(!doesCarExist(carAddress), "Car is already exists in inventory" );
        require(carPrice > 0, "invalid carPrice");
        Car memory carObjectForPersistence;
        carObjectForPersistence = Car({
                                                        carId : carAddress,
                                                        carPrice: carPrice,
                                                        isBooked : 0,
                                                        createdAt : block.timestamp});
        carMap[carAddress] = carObjectForPersistence;
    }

    function doesCarExist(address carAddress) public view returns(bool){
        require(isAValidAddress(carAddress), "carAddress is Invalid");
        return carMap[carAddress].carId  == carAddress;
    }

    modifier isAValidCar(address carAddress){
        require(doesCarExist(carAddress), "car doesnot exist in registry");
        _;
    }

    //create a New CarBooking & Add mapping for CarBooking
    function bookACar(
        address carId,
        bytes32 bookingId,
        address customer) isAValidCar(carId) public {      
        require(isAValidAddress(customer), "invalid customer Address");
        require(carMap[carId].isBooked<=0, "car is already Booked");

        CarBooking memory carBookingObjectForPersistence;

        carBookingObjectForPersistence = CarBooking({
                                                                                carId : carId,
                                                                                bookingId : bookingId,
                                                                                customer: customer,
                                                                                createdAt : block.timestamp
                                                                                });

        Car storage car = carMap[carId];
        car.isBooked = block.timestamp;                                                

        carBookingMap[bookingId] = carBookingObjectForPersistence;
        customerBookings[customer].push(bookingId);
    }

    function getCarBookingDetails(bytes32 bookingId) public view returns(CarBooking memory carBooking){
        require(doesBookingExist(bookingId), "CarBooking doesnot exist with this bookingId");
        return carBookingMap[bookingId];
    }

    function doesBookingExist(bytes32 bookingId) public view returns(bool){
        require(isANonEmptyByte32Value(bookingId), "invalid bookingId");
        return carBookingMap[bookingId].createdAt > 0;
    }


    function isANonEmptyString(string memory stringArgument) public pure returns(bool){
        return bytes(stringArgument).length > 0;
    }

    function isANonEmptyByte32Value(bytes32 byteArgument) public pure returns(bool){
        return byteArgument.length > 0;
    }

    function isAValidAddress(address addressArgument) public pure returns(bool){
        return addressArgument != address(0x0);
    }

    function isAValidInteger(uint integerValue) public pure returns(bool){
        return integerValue > 0;
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}