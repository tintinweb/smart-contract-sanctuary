/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StakeContract {

    using SafeMath for uint256;
    
    IBEP20 public token;
    address payable public owner;
    
    uint256 [6] public plans = [7 minutes,15 minutes,30 minutes,60 minutes,120 minutes,365 minutes];
    uint256 [6] public StakePercentages = [175,375,750,1500,3000,9125];
    uint256 public minAmount;
    uint256 public maxAmount;

    struct Stake{
        uint256 time;
        uint256 amount;
        uint256 bonus;
        bool withdrawan;
    }
    
    struct User{
        uint256 totalstakeduser;
        uint256 stakeIndex;
        mapping(uint256 => Stake) stakeDetails;
    }
    
    mapping(address => User) public users;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"Ownable: Not an owner");
        _;
    }
    
    constructor(address _owner, IBEP20 _token) {
        owner = payable(_owner);
        token = _token;
        minAmount = 100e18;
        maxAmount = 100000e18;
    }
    
    function stake(uint256 amount,uint256 plan) public{
        require(plan >=0 && plan <6 ,"put valid plan details");
        require(amount >= minAmount && amount <= maxAmount,"Invalid amount");

        token.transferFrom(msg.sender,address(this),amount);
        
        User storage user = users[msg.sender];
        user.totalstakeduser += amount;
        user.stakeDetails[user.stakeIndex].time = block.timestamp + plans[plan];
        user.stakeDetails[user.stakeIndex].amount = amount;
        user.stakeDetails[user.stakeIndex].bonus = amount.mul(StakePercentages[plan]).div(1000);
        user.stakeIndex++;
    }
    
    function withdraw(uint256 index) public{
        User storage user = users[msg.sender];
        require(user.stakeIndex >= index,"Invalid Stake index");
        require(user.stakeDetails[index].time  < block.timestamp,"cannot withdraw before time");
        require(!user.stakeDetails[index].withdrawan,"withdraw only once");
        
        user.stakeDetails[index].withdrawan = true;
        token.transferFrom(owner,msg.sender,user.stakeDetails[index].bonus);
        token.transfer(msg.sender,user.stakeDetails[index].amount);
    }
    
    function unstake(uint256 index) public{
        User storage user = users[msg.sender];
        require(user.stakeIndex >= index,"Invalid Stake index");
        require(!user.stakeDetails[index].withdrawan,"withdraw only once");
        user.stakeDetails[index].withdrawan = true;
        uint256 unstakeable = user.stakeDetails[index].amount;
        token.transfer(msg.sender,unstakeable);
        user.stakeDetails[user.stakeIndex].bonus = 0;
        
    }
    
    function stakedetails(address add,uint256 index) public view
    returns(
        uint256 _time,
        uint256 _amount,
        uint256 _bonus,
        bool _withdrawan
        ){
        
        return(
            users[add].stakeDetails[index].time,
            users[add].stakeDetails[index].amount,
            users[add].stakeDetails[index].bonus,
            users[add].stakeDetails[index].withdrawan
        );
    }

    function setStakingLimit(uint256 _minAmount, uint256 _maxAmount) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    function setStakePercent(
        uint256 _percent1,
        uint256 _percent2,
        uint256 _percent3,
        uint256 _percent4,
        uint256 _percent5,
        uint256 _percent6
    ) external onlyOwner {
        StakePercentages[0] = _percent1;
        StakePercentages[1] = _percent2;
        StakePercentages[2] = _percent3;
        StakePercentages[3] = _percent4;
        StakePercentages[4] = _percent5;
        StakePercentages[5] = _percent6;
    }

    function changeOwner(address payable _owner) external onlyOwner {
        owner = _owner;
    } 
    
    function getContractTokenBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getCurrentTime() public view returns(uint256){
        return block.timestamp;
    }
    
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}