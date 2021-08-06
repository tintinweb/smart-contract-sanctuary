/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.8.0;

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
    uint256 [6] private plans = [7 days,15 days,30 days,60 days,120 days,365 days];
    uint256 [6] private percentages = [25,25,25,25,25,25];
    bool public allow;
    
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
    
    constructor() {
        token = IBEP20(0xE66f5412C2a220B548a2c9E5768751cf884D7454);
        owner = payable(msg.sender);
    }
    
    function stake(uint256 amount,uint256 plan) public{
        require(plan >=0 && plan <6 ,"put valid plan details");
        
        token.transferFrom(msg.sender,address(this),(amount.mul(1e18)));
        
        User storage user = users[msg.sender];
        user.totalstakeduser += amount.mul(1e18);
        user.stakerecord[user.stakecount].time = block.timestamp + plans[plan];
        user.stakerecord[user.stakecount].amount = amount.mul(1e18);
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).mul(1e18).div(1000);
        user.stakecount++;
    }
    
    function withdraw(uint256 count) public{
        User storage user = users[msg.sender];
        require(user.stakecount >= count,"Invalid Stake index");
        require(user.stakerecord[count].time  < block.timestamp,"cannot withdraw before time");
        require(!user.stakerecord[count].withdrawan,"withdraw only once");
        user.stakerecord[count].withdrawan = true;
        token.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        token.transfer(msg.sender,user.stakerecord[count].amount);
    }
    
    function unstake(uint256 count) public{
        User storage user = users[msg.sender];
        require(user.stakecount >= count,"Invalid Stake index");
        require(!user.stakerecord[count].withdrawan,"withdraw only once");
        user.stakerecord[count].withdrawan = true;
        uint256 unstakeable = user.stakerecord[count].amount;
        token.transfer(msg.sender,unstakeable);
        user.stakerecord[user.stakecount].bonus = 0;
        
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