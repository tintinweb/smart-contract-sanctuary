/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity ^0.5.0;

contract Plasticbottle{

    //Creating the reference data for bottle upload
    struct Bottle {
        string qrCode;
        string title;
        string status;
        uint bottleSize;
        string sizeUnit;
        address user;
    }
   
   //Bottle event indexed by ID
    event registeredBottleEvent (
        uint indexed _bottleID
   );

    //Array of all bottles produced by manufacturers
    Bottle[] public BottleArray;

    //Registering a bottle instance
    function registerBottle(string calldata _qrCode, string calldata _title, string calldata _status,  uint _bottleSize, string calldata _sizeUnit)
    external returns(uint){
        uint index = BottleArray.push(Bottle(_qrCode, _title, _status, _bottleSize, _sizeUnit, msg.sender))-1;

        
        // trigger registeredBottle event
       emit registeredBottleEvent(index);

        return index;
    }


    //Checks the number of bottles in the BottleArray
    function numberofBottles() public view returns (uint){
        return BottleArray.length;
    }
}