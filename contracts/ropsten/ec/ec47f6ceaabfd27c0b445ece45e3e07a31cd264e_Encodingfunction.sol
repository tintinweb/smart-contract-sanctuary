/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Encodingfunction{


//change variables directly
string str = "aFunction(string,uint256)";        
string str2 = "helloworld";
string str3;
string str4;
uint num1 = 45;
uint num2;
uint num3;


function encodingfunctionSignature() public pure returns(bytes4){
    bytes4 encodedSignature = bytes4(keccak256("aFunction(string,uint256)")); // change arguments directly
    return encodedSignature;
    }


function encodingfunctionSignature2() public view returns(bytes memory){
    bytes memory encodedSignature2 = abi.encode(str);                        // change arguments directly   
    return encodedSignature2;
    }

function encodingfunctionSignature3() public view returns(bytes memory){
    bytes memory encodedSignature3 = abi.encodeWithSignature(str,str2,num1); // change arguments directly
    return encodedSignature3;
    }
}