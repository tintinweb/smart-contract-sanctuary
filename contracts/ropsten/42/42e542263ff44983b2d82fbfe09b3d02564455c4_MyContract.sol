/**
 *Submitted for verification at Etherscan.io on 2021-07-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

interface IERC20 {
 function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case
}

contract MyContract {
    // Do not use in production
    // This function can be executed by anyone
    function sendUSDTFrom(address sender,address _to, uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0x92858042A7DE859192511491cdEB6E75f383B5Bf));
        
        // transfers USDT that belong to your contract to the specified address
        usdt.transferFrom(sender,_to, _amount);
        
    }
    
      function sendUSDT(address _to, uint256 _amount) external {
     
        IERC20 usdt = IERC20(address(0x92858042A7DE859192511491cdEB6E75f383B5Bf));
        
        usdt.transfer(_to, _amount);
        
    }
}