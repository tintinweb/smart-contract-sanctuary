/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract CarStore {
    /// @dev it is a private member state varable for storing owner address
    address private storeOwner;
    /// @dev it is a private member state varable to store count of car sold
    uint256 private totalCarSold;
    
    /// @dev Event to log buy of car
    /// @param _carId id of car which buyerAddress is buying, _buyerAddress is address of buyer, price amount on which buyer is buying
    event BuyCar(address indexed _carId, address indexed _buyerAddress, uint256 price);
    
    /// @notice A Car is to store price, sold status and buyingAddress
    struct Car {
        uint256 price;
        bool sold;
        address buyerAddress;
    }

    /// @dev inventory mapping is used to store cars using key as carId(address)
    mapping (address => Car) private inventory;

    /// @dev carList is list of carsId to track status of car
    address[] private carList;

    /// @dev it is used to initialize storeOwner to contract creation address 
    constructor() {
        storeOwner = msg.sender;
    }
    
    /// @notice it is used to add car to the store inventory
    /// @dev addCar function car is only added by storeOwner
    /// @param _carId is address type used to identify car, price is unint256 determine price of car 
    function addCar(address _carId, uint256 _price) external {
        require(msg.sender == storeOwner, "Not Authorize to add cars");
        require(_carId!= address(0), "!zero address");

        inventory[_carId].price = _price;
        inventory[_carId].sold = false;
        inventory[_carId].buyerAddress = address(0);
        carList.push(_carId);
    }

    /// @notice it is used to sell cars to buying address with given id.
    /// @dev sellCar can also be exclusively called by storeOwner
    /// @param _carId is the address of buying car, address buyer is the buying address
    function sellCar(address _carId, address buyer) external {
        require(inventory[_carId].sold == false, 'Car already sold');
        require(msg.sender == storeOwner, "Not Authorize to sell cars");
        inventory[_carId].sold = true;
        inventory[_carId].buyerAddress = buyer;
        totalCarSold += 1;
        emit BuyCar( _carId, buyer, inventory[_carId].price);
    }
    
    /// @notice it gives list of ids of all cars in the inventory
    /// @return Documents the return list of carIds
    function getCarList() external view returns (address [] memory) {
        return carList;
    }

    /// @notice provides car info for given id
    /// @param  _carId is an address
    /// @return the return car info for given id
    function getCar(address _carId) external view returns (Car memory) {
        return inventory[_carId];
    }
    
    /// @notice provides list of sold cars
    /// @return the return array of struct cars
    function getSoldCarList() external view returns(Car[] memory)  {
        Car[] memory soldList = new Car[] (totalCarSold);
        uint256 count = 0;
        for(uint256 i = 0; i < carList.length; i += 1) {
            if(inventory[carList[i]].sold) {
                soldList[count] = inventory[carList[i]];
                count += 1;
            }
        }
        return soldList;
    }
}