/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

/* SPDX-License-Identifier: UNLICENSED */

/* Power By TokenSend.APP */

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract TokenSend {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier is_owner(){
        require(msg.sender == owner);
        _;
    }
    
    function tokenSendEther(address[] memory recipients, uint256[] memory values) external payable {
        for (uint256 i = 0; i < recipients.length; i++){
            payable(recipients[i]).transfer(values[i]);
        }
    }

    function tokenSendToken(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++){
            total += values[i];
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++){
            require(token.transfer(recipients[i], values[i]));
        }
    }

    function transferOutToken(IERC20 token,uint256 values) external is_owner{
        require(token.transfer(owner, values));
    }

    function transferOutEther() external payable is_owner{
        payable(owner).transfer(address(this).balance);
    }
}