/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

contract HalbornCTF {

     /* Bytes32 Array */
     bytes32 private website;
     bytes32[] private Lists;
     bytes32 internal flag1;
     
     
     constructor(bytes32 _flag1){

     flag1 = _flag1;
         
     }
    function submitApplicant(bytes32 _flag,bytes32 _applicant) public {
        if (flag1 == _flag) {
        Lists.push(_applicant);
        }
    }
     
    function Applicants(bytes32 _flag, uint index) public view returns(bytes32) {
        if (flag1 == _flag) {
            return(Lists[index]);
        }
    }
 }