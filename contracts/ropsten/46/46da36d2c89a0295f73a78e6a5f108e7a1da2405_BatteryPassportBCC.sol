/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

// SPDX-License-Identifier: GNU AGPLv3.
// Author: Elmar Eckstein.
pragma solidity ^0.8.4;

contract BatteryPassportBCC {
    struct Parent {
        string name;
        uint dateOfProduction;
    }
    struct PartList {
        string cobalt;
        string BMS;
        bool initialized;
    }
    struct StateOfHealth {
        uint remainingCapacity;
        uint maxCapacity;
        uint averageTemp;
    }
    struct BatteryInfo {
        Parent parent;
        PartList partList;
        StateOfHealth stateOfHealth;
    }
    
    modifier onlyAuthorizedModifier() {
        require(authorizedModifiers[msg.sender] == true, "Account not authorized.");
        _;
    }
    
    event AutorizedModifierChanged(bool isAuthorized);
    event ChangedBatteryPassport(uint serialNumber, BatteryInfo info);
    
    mapping (address => bool) public authorizedModifiers;
    mapping (uint => BatteryInfo) public batteryMapping;

    constructor() {
        authorizedModifiers[msg.sender] = true;
    }
    
    function toggleAuthorizedModifier(address _modifier) public onlyAuthorizedModifier {
        require(_modifier != msg.sender, "Cannot deauthorize yourself.");
        authorizedModifiers[_modifier] = !authorizedModifiers[_modifier];
        emit AutorizedModifierChanged(authorizedModifiers[_modifier]);
    }
    
    function setBatteryParent(uint serialNumber, string calldata parentName, uint parentDoP) public onlyAuthorizedModifier {
        Parent storage current = batteryMapping[serialNumber].parent;
        current.name = parentName;
        current.dateOfProduction = parentDoP;
        emit ChangedBatteryPassport(serialNumber, batteryMapping[serialNumber]);
    }
    
    function setBatteryPartList(uint serialNumber, string calldata cobaltName, string calldata bmsName) public onlyAuthorizedModifier {
        PartList storage current = batteryMapping[serialNumber].partList;
        // Ensure that the part list can never be changed after it has been initialized.
        require(current.initialized == false, "The part list cannot be changed.");
        current.cobalt = cobaltName;
        current.BMS = bmsName;
        current.initialized = true;
        emit ChangedBatteryPassport(serialNumber, batteryMapping[serialNumber]);
    }
    
    function setBatteryStateOfHealth(uint serialNumber, uint remainingCapacity, uint maxCapacity, uint averageTemp) public onlyAuthorizedModifier {
        StateOfHealth storage current = batteryMapping[serialNumber].stateOfHealth;
        current.remainingCapacity = remainingCapacity;
        current.maxCapacity = maxCapacity;
        current.averageTemp = averageTemp;
        emit ChangedBatteryPassport(serialNumber, batteryMapping[serialNumber]);
    }
}