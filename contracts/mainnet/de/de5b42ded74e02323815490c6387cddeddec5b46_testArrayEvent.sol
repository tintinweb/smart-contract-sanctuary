/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-11
*/

pragma solidity 0.5.17;


contract testArrayEvent {
    
    uint256[] growableUintsArray;
    bool[] growableBoolArray;
    address[] growableAddressArray;
    event arraysFixed(uint256[3] numbers, address[2] addresses, bool[4] bools);
    event arraysDynamic(uint256[] numbers, address[] addresses, bool[] bools);
    
    constructor () public {}    
    
    function emitEventFixedArray() public {

        uint256 one = 1;
        uint256 two = 2;
        uint256 threehundredand4 = 304;
        uint256[3] memory  uints = [one,two,threehundredand4];
        bool[4] memory bools = [true,false,true,false];
        address[2] memory addresses = [address(this), msg.sender];

        emit arraysFixed(uints,  addresses,  bools);
    }
    
    function emitEventDynamicArray(uint slots) public {

        uint256 count = 1;
        bool current = true;
        while (count <= slots){
            growableUintsArray.push(count);
            growableBoolArray.push(current);
            current = !current;
            growableAddressArray.push(block.coinbase);
            count++;
        }

        emit arraysDynamic(growableUintsArray,  growableAddressArray,  growableBoolArray);
    }
    
    
    
}