/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface USDT {
    function transfer(address _to, uint256 _value) external returns (bool);
    
}

contract MyContract {
  
    function sendUSDT(address _to, uint256 _amount) external {
       
        USDT usdt = USDT(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        
        usdt.transfer(_to, _amount);
    }
}