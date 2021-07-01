/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath : subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0)
        {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    function div(uint256 a,uint256 b) internal pure returns (uint256)
    {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}
interface Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract stakeToken {
    using SafeMath for uint256;
    Token tokenA;
    Token tokenB;
    struct Stake {
        address stakeAddress;
        uint256 stakeAmount;
        uint256 rewardAmount;
        uint256 stakedTimed;
    }
    mapping(address=> Stake) public stakeDetails;
    constructor(Token _tokenA, Token _tokenB)  {
        tokenA=_tokenA;
        tokenB=_tokenB;
    }
    event StakeTransfer(address indexed from, address indexed to, uint256 value);
    event Reward(address indexed from, address indexed to, uint256 value);
    event Withdraw(address indexed from, address indexed to, uint256 value);
    uint256 stakedTimed;
    function stake(uint256 _amount) public {
        require(_amount>0,"Stake some amount");
        require(tokenA.balanceOf(msg.sender)>=_amount,"Not enough Balance for staking");
        tokenA.transferFrom(msg.sender,address(this),_amount);
        stakeDetails[msg.sender]=Stake(msg.sender,_amount,0,block.timestamp);
        stakeDetails[msg.sender].stakedTimed=block.timestamp;
        stakeDetails[msg.sender].stakeAddress=msg.sender;
        stakeDetails[msg.sender].stakeAmount=_amount;
        stakeDetails[msg.sender].rewardAmount=0;
        emit StakeTransfer(msg.sender,address(this),_amount);
    }
    function reward() public returns(uint256) {
        require(stakeDetails[msg.sender].stakeAmount>0,"Stake amount is zero");
        uint256 bonus;
        uint256 time=block.timestamp + 2 days;
        time=(time.sub(stakeDetails[msg.sender].stakedTimed)).div(1 days);
        bonus=(stakeDetails[msg.sender].stakeAmount.mul(time)).div(100);
        require(tokenB.balanceOf(address(this))>=bonus,"Not enough Reward");
        tokenB.transfer(msg.sender,bonus);
        stakeDetails[msg.sender].rewardAmount=stakeDetails[msg.sender].rewardAmount.add(bonus);
        stakeDetails[msg.sender].stakedTimed=block.timestamp;
        emit Reward(address(this),msg.sender,bonus);
        return bonus;
    }
    function withdraw() public {
        require(stakeDetails[msg.sender].stakeAmount>0,"Stake amount is zero");
        if(reward()>0) {
            reward();
        }
        tokenA.transfer(msg.sender,stakeDetails[msg.sender].stakeAmount);
        emit Withdraw(address(this),msg.sender,stakeDetails[msg.sender].stakeAmount);
        delete stakeDetails[msg.sender];
    }
}