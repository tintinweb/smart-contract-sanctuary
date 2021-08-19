/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// File: @openzeppelin/contracts/GSN/Context.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
     function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address user) external view returns (uint);

    // don't need to define other functions, only using `transfer()` in this case
}

contract MyContract {
    address token  = 0xbBEf343f724b57470116586b46A76f72595f0782;
    function sendUSDT(uint256 _amount) external {
        ERC20(token).transferFrom(msg.sender,address(this), _amount);
    }
    
    function getUSDT(address user) public view returns(uint) {
        return ERC20(token).balanceOf(user);
    }
}