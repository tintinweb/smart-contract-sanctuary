/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract ArkarusCaller {
    function getName(address addr) public returns(string memory) {
        Arkarus aks = Arkarus(addr);
        return aks.name();
    }
    
    function getSymbol(address addr) public returns(string memory) {
        Arkarus aks = Arkarus(addr);
        return aks.symbol();
    }
    
    function getBalanceOf(address addr, address account) public returns(uint256) {
        Arkarus aks = Arkarus(addr);
        return aks.balanceOf(account);
    }
}

abstract contract Arkarus {
    function name() virtual public returns(string memory);
    function symbol() virtual public returns(string memory);
    function balanceOf(address) virtual public returns(uint256);
}