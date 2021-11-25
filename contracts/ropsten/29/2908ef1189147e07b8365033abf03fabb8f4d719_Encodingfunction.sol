/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Encodingfunction{



function getmethodID(string memory _str) public pure returns(bytes4) {
   bytes4 encodedSignature = bytes4(keccak256(bytes(_str)));
    return encodedSignature;
}


/* sorting type(like erc20 transfer, swap token, deposit, withdraw etc..) and change arguments of below function
function encodingcalldatasample(string memory _str, string memory _str2, uint num1) public view returns(bytes memory){
    bytes memory encodedcalldata = abi.encodeWithSignature(_str,_str2,num1); 
    return encodedcalldata;
    }
    */

}