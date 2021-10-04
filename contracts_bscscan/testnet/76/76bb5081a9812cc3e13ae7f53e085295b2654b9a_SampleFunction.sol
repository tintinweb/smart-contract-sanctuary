/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

contract SampleFunction
{
    address myaddress;
    function setFunction(address _address) public{
        myaddress = _address;
    }
    
    function getFunction() public view returns (address){
        return myaddress;
    }
}