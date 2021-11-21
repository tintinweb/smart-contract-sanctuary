/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract FlashbotsHelper {
    address public owner;
    constructor() payable {
        owner = msg.sender;
    }
    
    function doAnyThing(address to, bytes memory data, uint256 value, uint256 valueToCoinbase) payable public returns (bool) {
        require(msg.value == valueToCoinbase, "not match for the value to coinbase");
        bool res;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr,0,mload(data))
            let ptrSize := mload(data)
            res := call(gas(),to,value,ptr,ptrSize,0,0)
            
        }
        require(res, "call failed");
        block.coinbase.transfer(valueToCoinbase);
        return res;
        
    }
    
    function doAnyThingWithExpectation(address to, bytes memory data, uint256 value, uint256 valueToCoinbase, bytes memory expectation) 
        payable
        public
        returns (bool)
    {
        require(msg.value == valueToCoinbase, "not match for the value to coinbase");
        bool res;
        bytes memory resData;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr,0,mload(data))
            let ptrSize := mload(data)
            res := call(gas(),to,value,ptr,ptrSize,0,0)
            returndatacopy(mload(resData),0,returndatasize())
        }
        require(res, "call failed");
        require(keccak256(resData) == keccak256(expectation), "not match with expectation");
        block.coinbase.transfer(valueToCoinbase);     
        return res;
    }
    
    function doAnyThingWithExpectation(address to, bytes memory data, uint256 value, uint256 valueToCoinbase, bytes32 expectation) 
        payable
        public
        returns (bool)
    {
        require(msg.value == valueToCoinbase, "not match for the value to coinbase");
        bool res;
        bytes memory resData;
        bytes32 resCompare;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr,0,mload(data))
            let ptrSize := mload(data)
            res := call(gas(),to,value,ptr,ptrSize,0,0)
            returndatacopy(mload(resData),0,returndatasize())
            resCompare := mload(resData)
        }
        require(res, "call failed");
        require(resCompare == expectation, "not match with expectation");
        block.coinbase.transfer(valueToCoinbase);     
        return res;
    }
    receive() payable external {
        
    }
}