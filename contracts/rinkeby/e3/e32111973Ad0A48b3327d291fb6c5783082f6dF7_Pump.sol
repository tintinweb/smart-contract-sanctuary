//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./PowerPlant.sol";
import "./CarRegister.sol";
import "./ERC20Accounting.sol";

contract Pump {
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

    //Order structure of charging by the user
    struct Order {
        uint cost;
        uint startAt;
    }

    mapping(address => Order) orders;

    constructor(PowerPlant _powerPlant, CarRegister _carRegister, ERC20Accounting _token, uint _interval){
        owner = msg.sender;
        powerPlant = PowerPlant(_powerPlant);
        carRegister = CarRegister(_carRegister);
        token = _token;
        interval = _interval;
    }

    function getPrice() public view returns (uint){
        return powerPlant.getPrice();
    }

    function getCarAddress(string memory UID) public view returns (address){
        return carRegister.getAccount(UID);
    }

    function placeOrder() public returns (uint){
        //Check if UID matches with parked car owner
        require(getCarAddress(currentUID) == msg.sender, "CAR UID NOT MATCHED");
        //Check if station is occupied
        require(!isOccupied(), "PUMP OCCUPIED");
        //Place order
        orders[msg.sender]=Order(getPrice(), block.timestamp);
        return orders[msg.sender].cost;
    }

    function beginCharging() public {
        //Revert if pump is occupied
        require(!isOccupied(), "PUMP OCCUPIED");
        //Revert if not allowed to transfer
        require(token.allowance(msg.sender,address(this))==orders[msg.sender].cost, "ALLOWED AMOUNT NOT MATCHED");
        //Transfer tokens
        token.transferFrom(msg.sender,address(this),orders[msg.sender].cost);
        //Start charging
        //Trigger consumption power plant
        powerPlant.consume(orders[msg.sender].startAt);
        //Set occupation of pump
        chargingEnd=orders[msg.sender].startAt+interval;
    }

    function setCurrentUID(string memory _uid) public {
        require(msg.sender == owner, "NOT ALLOWED");
        currentUID = _uid;
    }

    function isOccupied() public view returns (bool){
        return chargingEnd > block.timestamp ? true : false;
    }

    function getOrder() public view returns (Order memory){
        return orders[msg.sender];
    }

}