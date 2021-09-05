/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

//"SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.5.0;

contract boolLock{
    bool isOpen;
    event opened(bool isOpen);
    event closed(bool isOpen);
    
    function getBool()public view returns (bool) {
        return isOpen;
    }
    
    function openBool()public returns (bool){
        isOpen = true;
        return isOpen;
        emit opened(isOpen);
        }
    
    function closeBool()public returns(bool){
        isOpen = false;
        return isOpen;
        emit closed(isOpen);
    }
    
}