//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./PowerPlant.sol";
import "./CarRegister.sol";
import "./ERC20Accounting.sol";
import "./PowerPlant.sol";
import "./Libraries.sol";
import "./IPump.sol";

contract Pump  is IPump{
    PowerPlant public powerPlant;
    CarRegister public carRegister;
    ERC20Accounting public token;
    //Interval of charging in seconds
    uint public interval;
    //Charging state
    uint public chargingEnd;
    //Current car UID
    string public currentUID;
    //Owner
    address public owner;
    //margin of charging
    mapping(address=>uint) public margins;
    //margin
    uint public margin=1;

    constructor(PowerPlant _powerPlant, CarRegister _carRegister, ERC20Accounting _token, uint _interval){
        owner = msg.sender;
        powerPlant = PowerPlant(_powerPlant);
        carRegister = CarRegister(_carRegister);
        token = _token;
        interval = _interval;
    }

    function getPrice() override public view  returns (uint){
        return powerPlant.getPrice()+margin;
    }

    function getCarAddress(string memory UID) public view returns (address){
        return carRegister.getAccount(UID);
    }

    function placeOrder() override public returns (uint){
        //Check if UID matches with parked car owner
        //require(getCarAddress(currentUID) == msg.sender, "CAR UID NOT MATCHED");
        //Check if station is occupied
        require(!isOccupied(), "PUMP OCCUPIED");
        //Place order
        powerPlant.placeOrder(msg.sender);
        margins[msg.sender]=margin;
        //Set occupation of pump
        chargingEnd=getOrder().startAt+interval;
        return getOrder().cost;
    }

    function beginCharging() override public {
        //Revert if pump is occupied
        //require(!isOccupied(), "PUMP OCCUPIED");
        //Trigger consumption power plant
        powerPlant.consume(msg.sender, margin);
    }

    function setCurrentUID(string memory _uid) public {
        require(msg.sender == owner, "NOT ALLOWED");
        currentUID = _uid;
    }

    function isOccupied() override public view returns (bool){
        return chargingEnd > block.timestamp ? true : false;
    }

    function getOrder() override public view returns (Accounting.Order memory){
        Accounting.Order memory order=powerPlant.getOrder(msg.sender);
        order.cost+=margins[msg.sender];
        return order;
    }

}