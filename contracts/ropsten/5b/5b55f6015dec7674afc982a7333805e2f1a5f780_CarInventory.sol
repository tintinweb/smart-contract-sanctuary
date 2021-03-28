/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * Car inventory management to add and record down the car sales
 */
contract CarInventory {
    
    // Owner of the shop who can add/get car and can retrive total sale.
    address admin;
    
    // Car structure which has a unique id and its price along with buyer details
    struct Car{
        address id;    // unique car id
        uint price;    // car price
        bool issold;   // true if car is sold, else false
        address buyer; // address of the car buyer
    }
    
    // Inventory mapping which maps each unique car id with its structure
    mapping(address => Car) Inventory;
    
    // Record of car ids which have been sold
    address [] sale_records; 
    
    //Events
    event AddCar(address _id, uint _price); // car id, price
    event BuyCar(address buyer, address _id, uint _price); // buyer, car id, price
    
    constructor() public
    {
        admin = msg.sender;
    }
    
    //modifier
    modifier onlyAdmin()
    {
        require(admin == msg.sender, "Only admin is allowed to perform this operation");
        _;
    }
    
    
    // Function to add a car which has its unique id and price (admin operation)
    function addCar(address _id, uint _price) external onlyAdmin()
    {
        require(_id != address(0) , "Car nust have unique ethereum address.");
        require(_price >= 0 , "Car price can not be zero or nagative.");
        require(Inventory[_id].id == address(0), "The car with this id has already been added.");
       
        Inventory[_id] = Car(_id, _price, false, address(0));
        
        // trigger event
        emit AddCar(_id, _price);
    }
    
    // Function to buy car by providing car id and sending ether as amount (anonymous operation)
    function buyCar(address _id) external payable
    {
       require(Inventory[_id].id != address(0) , "No car with this ethereum address exists.");
       require(msg.value == Inventory[_id].price , "Amount sent for buying car is not same as its price.");
       require(!Inventory[_id].issold , "Car has already been sold.");
       
       // Update buyer details in the Inventory
       Inventory[_id].buyer = msg.sender;
       Inventory[_id].issold = true;
       
       // As car has been sold, add it to sale_records
       sale_records.push(_id);
       
       // trigger event
       emit BuyCar(msg.sender, _id, msg.value);
    }
    
    // Function to get the price of a specific car which are not sold yet. (anonymous operation)
    function getCarPrice(address _id) external view returns(uint)
    {
        require(!Inventory[_id].issold, "Car has already been sold.");
        
        return Inventory[_id].price;
    }
    
    // Function to get the buyer of the car (admin operation)
    function getCarBuyer(address _id) external view onlyAdmin() returns(address)
    {
        require(Inventory[_id].issold, "Car has not been sold yet.");
        
        return Inventory[_id].buyer;
    }
    
    // Function to get total sale (admin operation)
    function getTotalSale() external view onlyAdmin() returns(uint)
    {
        uint total_sale;
        for(uint i=0; i < sale_records.length; i++)
        {
            Car memory car = Inventory[sale_records[i]];
            
            // Assert something really wrong.
            assert(car.issold);
            
            total_sale += car.price;
        }
        
        return total_sale;
    }
}