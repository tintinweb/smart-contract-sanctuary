/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract vesting {

    struct claimer{
        uint256 total;
        uint256 timestamp;
        uint256 rate;
    }

    mapping(address => claimer) claimers;
    address owner;
    IERC20 token;

    constructor(address _token){
        owner = msg.sender;
        token = IERC20(_token);
    }

    function claim_balance() public {
        require(claimers[msg.sender].total > 0, "0 balance");
        require(claimers[msg.sender].timestamp <= block.timestamp, "time not met yet");

        claimers[msg.sender].total -= claimers[msg.sender].rate;
        claimers[msg.sender].timestamp += 1 weeks;
        token.transfer(msg.sender, claimers[msg.sender].rate);
    }

    function set_payout(uint256 amount, address _wallet, uint256 _rate) public{
        require(msg.sender == owner, "only owner");
        claimers[_wallet] = claimer(amount, block.timestamp + 1 weeks, _rate);
    }
}