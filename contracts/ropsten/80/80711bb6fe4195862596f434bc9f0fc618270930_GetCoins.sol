/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GetCoins {
    mapping (address => uint256) private last_request;
    address private _cryptol_address = 0xB0DD74bc7Dc6278ed1CFf32bd76A9FcBc2EDA67d;
    function contractBalance() external view returns(uint) {
        return IERC20(_cryptol_address).balanceOf(address(this));
    }
    function getCoins() external {
        require(
            last_request[msg.sender] + 20 hours < block.timestamp,
            "You are allowed to get coins only once per day."
        );
        address caller = msg.sender;
        uint256 amount = 10000000000000000000000; //10 000 CRYPTOL
        IERC20 cryptol_token = IERC20(_cryptol_address);
        cryptol_token.transfer(caller, amount);
        last_request[msg.sender] = block.timestamp;
    }
    function getCurrentTime() external view returns(uint) {
        return block.timestamp;
    }
    function getLastRequestTime() external view returns(uint) {
        address caller = msg.sender;
        return last_request[caller];
    }
    function isAllowedToGetCoins() external view returns(bool) {
        return (last_request[msg.sender] + 20 hours < block.timestamp);
    }
    
}