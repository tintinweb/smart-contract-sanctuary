/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

pragma solidity ^0.8.6;

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
    uint256 public refPercent;    // 10%
    uint256 public unstakePercent;   // 0.5%
    uint256 [4] public plans = [30 days,60 days,120 days,180 days];
    uint256 [4] public percentages = [20,50,1100,1400];

    struct Stake{
        uint256 time;
        uint256 amount;
        uint256 bonus;
        bool withdrawan;
    }
    
    struct User{
        uint256 totalstakeduser;
        uint256 stakecount;
        mapping(uint256 => Stake) stakerecord;
    }
    
    mapping(address => User) public users;
    
    modifier onlyOwner(){
        require(msg.sender == owner,"Ownable: Not an owner");
        _;
    }
    
    event Staked(address indexed _user, uint256 indexed _amount, uint256 indexed _time);
    
    event UnStaked(address indexed _user, uint256 indexed _amount, uint256 indexed _time);
    
    event Withdrawn(address indexed _user, uint256 indexed _amount, uint256 indexed _time);
    
    constructor(address payable _owner, address _token) {
        owner = _owner;
        token = IBEP20(_token);
        unstakePercent= 10; 
    }
    
    function stake(uint256 amount,uint256 plan) public{
        require(plan >=0 && plan <4 ,"put valid plan details");
        
        token.transferFrom(msg.sender,address(this),(amount));
       
        
        User storage user = users[msg.sender];
        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].time = block.timestamp + plans[plan];
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(1000);
        user.stakecount++;
        
        emit Staked(msg.sender, amount, block.timestamp);
    }
    
    function withdraw(uint256 count) public{
        User storage user = users[msg.sender];
        require(user.stakecount >= count,"Invalid Stake index");
        require(user.stakerecord[count].time  < block.timestamp,"cannot withdraw before time");
        require(!user.stakerecord[count].withdrawan,"withdraw only once");
        uint256 totalTokens = user.stakerecord[count].amount.add(user.stakerecord[count].bonus);
        user.stakerecord[count].withdrawan = true;
        token.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        token.transfer(msg.sender,user.stakerecord[count].amount);
        
        emit Withdrawn(msg.sender, totalTokens, block.timestamp);
    }
    
    function unstake(uint256 count) public{
        User storage user = users[msg.sender];
        require(user.stakecount >= count,"Invalid Stake index");
        require(!user.stakerecord[count].withdrawan,"withdraw only once");
        user.stakerecord[count].withdrawan = true;
        uint256 deduction = user.stakerecord[count].amount.mul(unstakePercent).div(1000);
        uint256 unstakeable = user.stakerecord[count].amount.sub(deduction);
        token.transfer(msg.sender,unstakeable);
        token.transfer(owner,deduction);
        user.stakerecord[user.stakecount].bonus = 0;
        
        emit UnStaked(msg.sender, unstakeable, block.timestamp);
    }
    
    function stakedetails(address add,uint256 count) public view returns(
        uint256 _time,
        uint256 _amount,
        uint256 _bonus,
        bool _withdrawan){
        
        return(
        users[add].stakerecord[count].time,
        users[add].stakerecord[count].amount,
        users[add].stakerecord[count].bonus,
        users[add].stakerecord[count].withdrawan
        );
    }
    
     function changebonuspercent(uint256 _bpercent1,uint256 _bpercent2,uint256 _bpercent3,uint256 _bpercent4) external onlyOwner{
        percentages[0] = _bpercent1;
        percentages[1] = _bpercent2;
        percentages[2] = _bpercent3;
        percentages[3] = _bpercent4;
        
    }
    function changePlans(uint256 _plan1,uint256 _plan2,uint256 _plan3,uint256 _plan4) external onlyOwner{
        plans[0] = _plan1;
        plans[1] = _plan2;
        plans[2] = _plan3;
        plans[3] = _plan4;
    }
    
    
    
    function ChangeUnstakePercent(uint256 _unstakePercent) external onlyOwner{
        unstakePercent = _unstakePercent;
    }

    function ChangeToken(address _token) external onlyOwner{
        token = IBEP20(_token);
    }
    
    function getContractBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function getContractTokenBalance() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getCurrentTime() external view returns(uint256){
        return block.timestamp;
    }
    
    function changeOwner(address payable _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    
    function migrateStuckFunds() external onlyOwner{
        owner.transfer(address(this).balance);
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