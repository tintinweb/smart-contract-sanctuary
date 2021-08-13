/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.0;

contract PriceFeed{
    struct Price{
        uint256 price;
        uint256 timestamp;
    }
    
    mapping(address=>bool)public whitelist;
    address public owner;
    Price public priceDetails;
    
    event updateRequest(address from, uint256 date);
    event priceUpdated(uint256 price,uint256 date);
    
    modifier onlyWhitelisted(){
        require(whitelist[msg.sender]==true,"Calling address is not whitelisted");
        _;
    }
    
    modifier onlyOwner(){
         require(msg.sender==owner,"Calling address is not the owner");
        _;
    }
    constructor(){
        owner=msg.sender;
    }
    
    function callback()public onlyWhitelisted{
        emit updateRequest(msg.sender,block.timestamp);
    }
    
    function updatePrice(uint256 _price)public onlyOwner{
        priceDetails.price=_price;
        priceDetails.timestamp=block.timestamp;
        emit priceUpdated(_price,block.timestamp);
    }
    
    function whitelistAddress(address _user)public onlyOwner{
        require(whitelist[_user]==false,"The given address is already whietlisted");
        whitelist[_user]=true;
    }
    
    function removeWhitelistAddress(address _user) public onlyOwner{
        require(whitelist[_user]==true,"The given address is not whietlisted");
        whitelist[_user]=false;
    }
    
    function getPrice()public view returns(uint256){
        return priceDetails.price;
    }
}