/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// File: @openzeppelin/contracts/GSN/Context.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
     function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    // don't need to define other functions, only using `transfer()` in this case
}

contract MyContract {
    IERC20 public token = IERC20(address(0xbBEf343f724b57470116586b46A76f72595f0782));
    // Do not use in production
    // This function can be executed by anyone
    function sendUSDT(uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
         
        // transfers USDT that belong to your contract to the specified address
        token.transferFrom(msg.sender,address(this), _amount);
    }
}