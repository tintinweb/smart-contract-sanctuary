/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT
//sniperProtection: https://bscscan.com/address/0xe3227ab03fb56983e1d916fde1182098e9924e6c#code
//_getAntiDumpMultiplier https://bscscan.com/address/0xa982835c2ad3ed4a7b285912b25d9fbdf1cc7564#code

pragma solidity ^0.8.0;


contract Test2 {

struct TierData {
        string name;
        uint punishDatetime;
        uint priceToken;       
        uint priceFiat;
        uint maxTaxReduction;
        address[] users;
    }
    
   
     address[] userList;
    mapping(uint8 => TierData) private _tiers;
    uint8 private _lengthTiers;
     
     function loadTiers () public{
        _tiers[1] = TierData("beginner", 30 days, 1_000*10**18, 10, 2, userList);
        _tiers[2] = TierData("initiate", 60 days, 10_000*10**18, 100, 2, userList);
        _tiers[3] = TierData("beginner", 90 days, 100_000*10**18, 1_000, 2, userList);
        _tiers[4] = TierData("elite", 120 days, 1_000_000*10**18, 10_000, 2, userList);
        _lengthTiers = 4;
     }
    

    function updateTierPrice() public {
        for (uint8 i=1; i <= _lengthTiers; i++) {
            _tiers[i].priceToken = (_tiers[i].priceFiat * 10 ** 8 / 5) * 10 ** 8;
        }
    }
    
    function getTier(uint8 id) public view returns(TierData memory ) {
        return _tiers[id];
    }
}