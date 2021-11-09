/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: Unlicensed
//Created By Solidty Works
//Based on Frictionless Faucet Rewards (lubed faucet lol)
pragma solidity >=0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    /*function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);*/
}
contract Faucet{
    address immutable token;
    uint256 immutable rate;
    uint256 private lastHarvest;
    
    constructor(address _token, uint256 _rate){
        token = _token;
        rate = _rate;
    }
    function currentReward() public view returns(uint256){
        uint256 amount = (block.timestamp - lastHarvest) * rate;
        uint256 balance = IERC20(token).balanceOf(address(this));
        if(amount > balance){
            return balance;
        }
        return amount;
    }
    function harvestReward() external{
        IERC20(token).transfer(msg.sender,currentReward());
        lastHarvest = block.timestamp;
    }
}

contract FaucetMaker{
    event NewFaucet(address indexed Token);
    function newFaucet(address token, uint256 rate) external{
        new Faucet(token,rate);
        emit NewFaucet(token);
    }
}