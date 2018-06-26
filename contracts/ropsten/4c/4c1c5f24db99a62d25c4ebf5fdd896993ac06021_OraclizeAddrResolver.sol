/*
  Copyright (c) 2015-2016 Oraclize SRL
  Copyright (c) 2016 Oraclize LTD
  
  Corrections Adonis Valamontes June 26, 2018 
// ----------------------------------------------------------------------------
// &#39;BBT&#39; &#39;International Blockchain Bank & Trust&#39;  Blockchain SmartTrust - SCMA
//
// (c) by A. Valamontes June 26, 2018. The MIT Licence.
// ----------------------------------------------------------------------------
*/
pragma solidity ^0.4.24;

contract OraclizeAddrResolver {

    address public addr;
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeOwner(address newowner) public {
        if (msg.sender != owner) revert();
        owner = newowner;
    }
    
    function getAddress() internal view returns (address oaddr) {
        return addr;
    }
    
    function setAddr(address newaddr) public {
        if (msg.sender != owner) revert();
        addr = newaddr;
    }
    
}