/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

contract CarShop{
    

    // structure to model car entity
    struct Car{
        uint256 price;
        address carSeller;
    }
    
    //mapping to map car address to specific car
    mapping(address => Car) public cars;
    
    //mapping to map car id to car
    mapping(uint256 => mapping(address => Car)) public myCars;
    
    
    //function to add new car to inventory
    function addNewCarIntoInventory(address _address, uint256 _price, address _carSeller) public {
        cars[_address] = Car(_price,_carSeller);


    }
    
    //function to record car sale with ID
    function recordCarSaleWithID(uint _id, uint _price, address _address) public {
        myCars[_id][_address] = Car(_price,_address);

    }
}