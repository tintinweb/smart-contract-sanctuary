/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


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

    constructor(uint _accountingInterval, uint _cycleIntervals, uint[] memory _productionProfile, uint _priceMax, uint _priceMin) {
        accountingInterval = _accountingInterval;
        cycleIntervals = _cycleIntervals;
        productionProfile = _productionProfile;
        priceMax = _priceMax;
        priceMin = _priceMin;
    }

    //Return consumptionTimestamps
    function getConsumptionTimestamps() public view returns (uint[] memory){
        return consumptionTimestamps;
    }

    //Calculate current consumption
    function getConsumption() public view returns (uint){
        uint consumption = 0;
        for (uint i = 0; i < consumptionTimestamps.length; i++) {
            if (consumptionTimestamps[i] < block.timestamp && (consumptionTimestamps[i] + accountingInterval) > block.timestamp) {
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

    //Activate consumption for one interval
    function consume() public {
        consumptionTimestamps.push(block.timestamp);
    }
}