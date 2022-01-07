//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract DeFiContract {
    
    IERC20 rewardToken;
    address[] stakeholders;
    mapping(address => uint256)  balances;
    mapping(address => uint256)  availableRewards;
    mapping(address => uint256)  totalRewardAccumulated;
    mapping(address => uint256)  timeTillLastUpdate;
    address public contractx;
    address public counter_addr;
    uint256 public counter_Val;

    uint256 rewardPerEth = 1; // [1000 tokens per 1 minutes (for testing)]/Eth. if user stakes 10 Eth and stakes it for 1 minute ==> user gets 10*1 = 10 Tokens
     constructor() {
        address rewardTokenAddr = 0xDf9365E089bAfa5402B0BB0e3DcA273702c5fdEa;
        rewardToken = IERC20(rewardTokenAddr);
        contractx = address(this);
    }

    function unstake (uint256 _amount ) public updateReward() {
        require(balances[msg.sender]>=_amount,"You cannot withdraw more than your balance ");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function stake() payable public   updateReward(){
        require(msg.value>0);
        balances[msg.sender] += msg.value;
        timeTillLastUpdate[msg.sender] = block.timestamp;
    }

    function viewStakedBal(address sender) public view returns(uint256){
        return (balances[sender]);
    }

    function viewAvailableRewards(address sender) public view returns(uint256){
        return (availableRewards[sender]);
    }

    function viewtotalRewards(address sender) public view returns(uint256){
        return (totalRewardAccumulated[sender]);
    }

    function rewardOnStakedTokens(address account) public view returns(uint256){
        uint Timeoffset = 100; // to avoid issues related to decimals
        uint Ethoffset = 100; // to avoid issues related to decimals
        uint256 totalTimeMins = (((block.timestamp - timeTillLastUpdate[account])*Timeoffset)/60);
        uint OneEth = (1*10**18);
        uint256 totalBalInOneEth = (balances[account]*Ethoffset) / OneEth;
        uint256 rewardIntermsOfEth =  totalBalInOneEth * rewardPerEth*10**18;
        uint256 reward = ((totalTimeMins * rewardIntermsOfEth)/Timeoffset)/Ethoffset;
        return (reward);
    }

    modifier updateReward() {
        uint256 reward = rewardOnStakedTokens( msg.sender);
        timeTillLastUpdate[ msg.sender] = block.timestamp;
        totalRewardAccumulated[ msg.sender] +=reward;
        availableRewards[msg.sender] += reward;
        _;
    }

    function withdrawRewards(uint256 _withdrawAmount) public updateReward() {
        require(availableRewards[msg.sender]>=_withdrawAmount,"You dont have any reward");
        availableRewards[msg.sender] -=_withdrawAmount;
        rewardToken.transfer(msg.sender,_withdrawAmount);
    }


    function updateTheReward() public updateReward(){ }

    function realTimeReward(address sender) public view returns(uint256){
        uint256 reward = availableRewards[sender] + rewardOnStakedTokens(sender);
        return reward;
    }

    function realTimeTotalReward(address sender) public view returns(uint256){
        uint256 reward = totalRewardAccumulated[sender] + rewardOnStakedTokens(sender);
        return reward;
    }



}


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}