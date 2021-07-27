/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: GNU AGPLv3.
// Author: Elmar Eckstein.
pragma solidity ^0.8.4;

contract BatteryPassportBCC {
    struct Parent {
        string name;
        int dateOfProduction;
    }
    struct PartList {
        string cobalt;
        string BMS;
    }
    struct StateOfHealth {
        int remainingCapacity;
        int maxCapacity;
        int averageTemp;
    }
    struct BatteryInfo {
        Parent parent;
        PartList partList;
        StateOfHealth stateOfHealth;
    }
    
    event AutorizedModifierChanged(bool isAuthorized);
    
    mapping (address => bool) public authorizedModifiers;
    mapping (int => BatteryInfo) public batteryMapping;

    constructor() {
        authorizedModifiers[msg.sender] = true;
    }
    
    function toggleAuthorizedModifier(address _modifier) public {
        // TODO: Safeguard for no authorized modifier left?
        require(authorizedModifiers[msg.sender] == true, "Account not authorized.");
        authorizedModifiers[_modifier] = !authorizedModifiers[_modifier];
        emit AutorizedModifierChanged(authorizedModifiers[_modifier]);
    }

    function test() public {
        Parent memory parent = Parent("Tesla Model X", 1231312312);
        PartList memory pl = PartList("Cobalt & Co Eindhoven", "Elmbar BV Helmond");
        StateOfHealth memory soh = StateOfHealth(5, 5, 35);
        batteryMapping[12341234534] = BatteryInfo(parent, pl, soh);
    }
    
    function test2() public returns(BatteryInfo memory) {
        return batteryMapping[12341234534];
    }
}