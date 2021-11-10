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
    mapping(address => uint256) private lastUse;
    bool public active;

    constructor(address _token, uint256 _rate){
        token = _token;
        rate = _rate;
    }
    function activate()external{
        require(active==false,"already active");
        require(lastHarvest==0 || IERC20(token).balanceOf(address(this)) > 0,"balance = 0");
        active = true;
        lastHarvest = block.timestamp;
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
        require(active==true,"inactive");
        require(lastUse[msg.sender] < block.timestamp - 86400);
        uint256 amount = currentReward();
        if(amount == IERC20(token).balanceOf(address(this))){
            active = false;
        }
        IERC20(token).transfer(msg.sender,amount);
        lastHarvest = block.timestamp;
        lastUse[msg.sender] == block.timestamp;
    }
}

contract FaucetMaker{
    event NewFaucet(address indexed Token);
    
    address [] public faucets;
    
    function newFaucet(address token, uint256 rate) external{
        //send tokens to new faucet address after creating faucet
        Faucet f = new Faucet(token,rate);
        faucets.push(address(f));
        emit NewFaucet(token);
    }
}