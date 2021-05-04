/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function faucet(uint256 _amount) external returns (bool);
    function decimals() external returns (uint8);
}


contract FaucetAndSend {
    function faucetAndSend(IERC20 token, address[] memory recipients, uint256 _amount) external returns (bool) {
        uint8 _decimals = token.decimals();
        uint256 _amountPer = 10**_decimals * _amount;
        uint256 _amountToFaucet = _amountPer * recipients.length;
        
        token.faucet(_amountToFaucet);
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transfer(recipients[i], _amountPer);
        }
        
        return true;
    }
    
    
}