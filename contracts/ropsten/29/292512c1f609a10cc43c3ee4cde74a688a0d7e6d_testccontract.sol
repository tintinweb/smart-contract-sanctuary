/**
 *Submitted for verification at Etherscan.io on 2021-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

contract testccontract{
    
    
    string private name;
    
   function getstring() public view returns (string) {
       return name;
    }

    function setstring(string newname) public  {
      name = newname;
   
    }
}