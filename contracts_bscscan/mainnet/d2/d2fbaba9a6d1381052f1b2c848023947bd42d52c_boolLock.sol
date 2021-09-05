/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.7.0;

contract boolLock{
    bool public isOpen;
    
    
    function openBool()public returns (bool){
        isOpen = true;
        return isOpen;
        }
    
    function closeBool()public returns(bool){
        isOpen = false;
        return isOpen;
    }
    
}