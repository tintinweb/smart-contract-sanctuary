/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.4.24;


// interface Aion 
contract Aion { 
    uint256 public serviceFee;
    function ScheduleCall(uint256 blocknumber, address to, uint256 value, uint256 gaslimit, uint256 gasprice, bytes data, bool schedType) public payable returns (uint,address);
}

// Main contract
contract MyContract{
uint256 public sqrtValue;
Aion aion;
uint256 public myData;

constructor(uint256 number) public payable{
    scheduleMyfucntion(number);
    myData = 1;
}

function scheduleMyfucntion(uint256 number) public {
    aion = Aion(0xFcFB45679539667f7ed55FA59A15c8Cad73d9a4E);
    bytes memory data = abi.encodeWithSelector(bytes4(keccak256('myfucntion(uint256)')),number); 
    uint callCost = 200000*1e9 + aion.serviceFee();
    aion.ScheduleCall.value(callCost)( block.timestamp + 10 minutes, address(this), 0, 200000, 1e9, data, true);
}

function myfucntion(uint256 number) public {
    // do your task here and call again the function to schedule
    myData = myData+1;
    scheduleMyfucntion(number);
} 

function getMyData() view public returns (uint256) {
    return myData;
}
function () public payable {}
}