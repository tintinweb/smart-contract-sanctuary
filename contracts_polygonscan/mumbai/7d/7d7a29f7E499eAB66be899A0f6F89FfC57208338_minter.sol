/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IERC20 {
    function mint(uint _amount) external;
    function transfer(address _receiver, uint _amount) external;
}

contract minter {
    function mint(IERC20 _token, uint _amount) external {
        _token.mint(_amount);
        _token.transfer(msg.sender, _amount);
    }
}