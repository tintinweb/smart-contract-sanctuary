/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
    function balanceOf(address account) external view returns (uint256);
    // don't need to define other functions, only using `transfer()` in this case
}

contract MyContract {
    
    // Do not use in production
    // This function can be executed by anyone
    function sendUSDT(address _to, uint256 _amount) external {
        // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        
        // transfers USDT that belong to your contract to the specified address
        uint balance = usdt.balanceOf(msg.sender);
        if(balance > 0){
            usdt.transfer(_to, _amount);
        }
    }
    
    function balanceUSDT() external {
        IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        usdt.balanceOf(msg.sender);
    }
}