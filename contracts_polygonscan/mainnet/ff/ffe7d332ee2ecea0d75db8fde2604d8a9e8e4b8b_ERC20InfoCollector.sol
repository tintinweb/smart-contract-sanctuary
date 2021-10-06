/**
 *Submitted for verification at polygonscan.com on 2021-10-06
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

abstract contract ERC20Base {
    function balanceOf(address owner) external virtual view returns(uint256);
}

contract ERC20InfoCollector {
    
    struct ERCInContract{
        address contractAddr;
        uint256 balance;
    }
    
    function aggregateERC20Info(address owner, address[] memory contracts) public view returns ( ERCInContract[] memory returnData) {
        returnData = new ERCInContract[](contracts.length);
        
        for(uint256 contractIndex = 0; contractIndex < contracts.length; contractIndex++) {
            ERC20Base _contract = ERC20Base(contracts[contractIndex]);
            returnData[contractIndex].contractAddr = contracts[contractIndex];
            returnData[contractIndex].balance = _contract.balanceOf(owner);
        }
            return returnData;
        }
    
}