//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20Accounting.sol";
import "./Libraries.sol";

contract PowerPlant {
    //time settings in seconds
    uint public accountingInterval;
    //number of intervals in one cycle
    uint public cycleIntervals;

    //production settings
    uint[] public productionProfile;

    //price variables
    uint public priceMax;
    uint public priceMin;

    //current consumption
    uint[] public consumptionTimestamps;

    ERC20Accounting public token;

    //Order structure of charging by the user
    struct Order{
        uint cost;
        uint startAt;
    }

    mapping(address => Accounting.Order) public orders;

    constructor(uint _accountingInterval, uint _cycleIntervals, uint[] memory _productionProfile, uint _priceMax, uint _priceMin, ERC20Accounting _token) {
        accountingInterval = _accountingInterval;
        cycleIntervals = _cycleIntervals;
        productionProfile = _productionProfile;
        priceMax = _priceMax;
        priceMin = _priceMin;
        token = _token;
    }

    //Return consumptionTimestamps
    function getConsumptionTimestamps() public view returns (uint[] memory){
        return consumptionTimestamps;
    }

    //Calculate current consumption
    function getConsumption() public view returns (uint){
        uint consumption = 0;
        for (uint i = 0; i < consumptionTimestamps.length; i++) {
            if (consumptionTimestamps[i] > block.timestamp) {
                consumption++;
            }
        }
        return consumption;
    }

    //Calculate current production
    function getProduction() public view returns (uint){
        uint k = block.timestamp % (cycleIntervals* accountingInterval);
        return productionProfile[k/60];
    }

    //Calculate price
    function getPrice() public view returns (uint){
        uint c = getConsumption();
        uint p = getProduction();
        if (c > p) c = p;
        uint d = p - c;
        if (d > priceMax) d = priceMax;
        if (d < priceMin) d = priceMin;
        uint price = priceMax - d + 1;
        return price;
    }

    //Activate consumption for one interval. Write end of consumption
    function consume(address user, uint margin) public {
        //Revert if not allowed to transfer
        uint amount=orders[user].cost;
        amount+=margin;
        uint allowance=token.allowance(user,address(this));
        require(allowance >= amount, "ALLOWED AMOUNT NOT MATCHED");
        //Transfer tokens to power plant
        token.transferFrom(user,address(this),orders[user].cost);
        //Transfer tokens to pump
        token.transferFrom(user,msg.sender,margin);
        consumptionTimestamps.push(orders[user].startAt+accountingInterval);
    }

    function placeOrder(address user) public{
        //Place order
        orders[user]=Accounting.Order(getPrice(), block.timestamp);
    }

    function getOrder(address user) public view returns (Accounting.Order memory){
        return orders[user];
    }
}