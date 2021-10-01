/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

contract ArkarusCaller {
    function getName(address contractAddress) public returns(string memory) {
        Arkarus aks = Arkarus(contractAddress);
        return aks.name();
    }
    
    function getSymbol(address contractAddress) public returns(string memory) {
        Arkarus aks = Arkarus(contractAddress);
        return aks.symbol();
    }
    
    function getBalanceOf(address contractAddress, address account) public returns(uint256) {
        Arkarus aks = Arkarus(contractAddress);
        return aks.balanceOf(account);
    }
    
    function transferAKS(address contractAddress, address recipient, uint256 amount) external returns (bool) {
        Arkarus aks = Arkarus(contractAddress);
        aks.transfer(recipient, amount);
        return true;
    }
}

abstract contract Arkarus {
    function name() virtual public returns(string memory);
    function symbol() virtual public returns(string memory);
    function balanceOf(address) virtual public returns(uint256);
    function transfer(address, uint256) virtual external returns(bool);
}