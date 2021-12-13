/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract MeatPlace {
    string public name;

    struct Meat {
        uint id;
        string meatName;
        uint price;
        address payable meatOwner;
        bool purchased;
    }

    mapping(uint => Meat) public meats;

    uint public meatCount = 0;


    event MeatCreated (
        uint id,
        string meatName,
        uint price,
        address payable meatOwner,
        bool purchased
    );

     event MeatPurchased (
        uint id,
        string meatName,
        uint price,
        address payable meatOwner,
        bool purchased
    );


    constructor() {
        name = "The Meat Place";
    }   

    function sellMeat(string memory _meatName, uint _price) public returns(bool) {
        require(bytes(_meatName).length > 0, "Meat name can not be empty");
        require(_price > 0, "Meat price can not be zero");
        
        //Increment the meat count
        meatCount++;
        
        //create a meat sale
        meats[meatCount] = Meat(meatCount, _meatName, _price, payable(msg.sender), false);
        
        //emit an the sell meat
        emit MeatCreated(meatCount, _meatName, _price, payable(msg.sender), false);
        return true;
    }

    function buyMeat(uint _id) public payable returns(bool) {

        //Fetch the meat
        Meat memory _meat = meats[_id];
        
        //Fetch the seller
        address payable _seller = _meat.meatOwner;

        //Make sure the meat exists, checks for price,... 
        //...not purchased yet, and can't buy your own meat
        require(_meat.id > 0 && _meat.id <= meatCount, "Product does not exist!");
        require(msg.value >= _meat.price, "Insufficient amount to purchase");
        require(!_meat.purchased, "Product already purchased");
        require(_seller != msg.sender, "You can not buy your own meat");
        
        //Transfer Ownership
        _meat.meatOwner = payable(msg.sender);
        //Update purchased status
        _meat.purchased = true;
        //Update the meat
        meats[_id] = _meat;

        //Pay the Seller by transfering some ether.
        _seller.transfer(msg.value);

        //emit an event
        emit MeatPurchased(_meat.id, _meat.meatName, _meat.price, payable(msg.sender), _meat.purchased);

        return true;

    }        

}