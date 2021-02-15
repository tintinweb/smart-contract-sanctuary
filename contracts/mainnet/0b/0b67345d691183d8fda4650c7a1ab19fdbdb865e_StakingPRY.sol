/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
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

contract StakingPRY{
    using SafeMath for uint256;
    address public token;
    address public owner;
    bool public staking = true;
    
     uint256 public oneMonthTime = 2592000;
  
 
    uint256 public timeforunstaking;

    mapping(address => uint256) public users;
    uint256 public totaltokenstaked;
    
    constructor(address _token) public{
        token = _token;
        owner = msg.sender;
    }
    
    
    function totalSupplyOfTokens() public view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }
    
    function readtimeleft() public view returns(uint256){
        if(now > timeforunstaking){
            return 0;
        }else{
           return timeforunstaking.sub(now);
        }
     
    }
    
    function lockToken(uint256 _amount) isStakingOn() public{
        require(_amount >= 1000e18,'you are inputting amount less than 1000 tokens');
        require(_amount.add(users[msg.sender]) <= 100000e18,'single user cannot invest more than 300k PRY');
        IERC20(token).transferFrom(msg.sender,address(this),_amount);
        users[msg.sender] = users[msg.sender].add(_amount);
        totaltokenstaked =  totaltokenstaked.add(_amount);
    }    
    
    function unlockTokens() isStakingOff() public returns(uint256){
        address useraddr = msg.sender;
        require(users[useraddr] >= 0);
        
        if(now > timeforunstaking){
        IERC20(token).transfer(msg.sender,users[useraddr].add(users[useraddr].mul(10).div(100)));
        totaltokenstaked = totaltokenstaked.sub(users[useraddr]);
        users[useraddr] = 0;
        return 1;
        }
        if(timeforunstaking.sub(now) > 2*oneMonthTime){
 
        IERC20(token).transfer(msg.sender,users[useraddr]);
        totaltokenstaked = totaltokenstaked.sub(users[useraddr]);
        users[useraddr] = 0;
        return 1;
        }
        if(timeforunstaking.sub(now) > oneMonthTime && timeforunstaking.sub(now) <= 2*oneMonthTime){
        uint amount = users[useraddr].mul(10).mul(25).div(100).div(100);
        IERC20(token).transfer(msg.sender,users[useraddr].add(amount));
        totaltokenstaked = totaltokenstaked.sub(users[useraddr]);
        users[useraddr] = 0;
        return 1;
        }
        if(timeforunstaking.sub(now) <= oneMonthTime && timeforunstaking.sub(now) > 0){
        uint amount = users[useraddr].mul(10).mul(50).div(100).div(100);
        IERC20(token).transfer(msg.sender,users[useraddr].add(amount));
        totaltokenstaked = totaltokenstaked.sub(users[useraddr]);
        users[useraddr] = 0;
        return 1;
        }  
    }
    
    function turnOnStaking() onlyOwner() public{
        require(now > timeforunstaking,'the time of unstaking has not finished');
        staking = true;
        timeforunstaking = 0;
    }
    
    function turnOffStaking() onlyOwner() public{
        require(now > timeforunstaking,'the time of unstaking has not finished');
        staking = false;
        timeforunstaking = now.add(3*oneMonthTime);
    }
    
    modifier isStakingOn(){
        require(staking == true,'staking period is off');
        _;
    }
        
    modifier isStakingOff(){
        require(staking == false,'staking period is on');
        _;
    }
        
    modifier onlyOwner(){
      require(msg.sender == owner,'you are not admin');
      _;
    }
    
    function adminTokenTransfer() external onlyOwner{
        require(totalSupplyOfTokens() > 0,'the contract has no pry tokens');
        IERC20(token).transfer(msg.sender,IERC20(token).balanceOf(address(this)));
    }
}