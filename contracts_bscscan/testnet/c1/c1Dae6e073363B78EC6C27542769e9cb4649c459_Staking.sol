/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;



interface IBEP20 {
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

contract Staking {
    IBEP20 public rewardsToken;
    IBEP20 public stakingToken;
    uint id = 1;

    struct User {
        uint ID;
        address wallet;
        uint balance;
        uint timeEnd;
        uint stakeTime;
        bool isExist;
    } 


    uint percentage = 12e18;
    uint public totalBalance;

        
    mapping (address => User) public users;

   constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IBEP20(_stakingToken);
        rewardsToken = IBEP20(_rewardsToken);
    }

    function stake(uint _amount) public {
        require(_amount >= 0,"price not valid up 0 ");
        totalBalance += _amount;
        users[msg.sender].ID = id;
        users[msg.sender].wallet =msg.sender;
        users[msg.sender].balance = _amount;
        users[msg.sender].stakeTime = block.timestamp;
        users[msg.sender].timeEnd = block.timestamp + 14 days;
        users[msg.sender].isExist = true;

        // stake
       stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    

    function getReward(address account) public {
      
    //    uint usertoeth = users[account].balance / 1e18 ;
    //    uint calc = ((percentage / 100) * usertoeth) ;
    //    uint reward =  users[account].balance + calc;
    //    require(totalBalance > reward,"Contract not balance");
    //    totalBalance -= reward;
       rewardsToken.transfer(account, users[account].balance );
    }

    function getRewardTest(address account) public view returns(uint) {
        uint usertoeth = users[account].balance / 1e18 ;
        uint calc = ((percentage / 100) * usertoeth) ;


        uint reward =  users[account].balance + calc;
        return reward;

        // rewardsToken.transfer(msg.sender, reward);
    }

    function updateUserBalance() public{
        uint usertoeth = users[msg.sender].balance / 1e18 ;
        uint calc = ((percentage / 100) * usertoeth) ;
        uint reward =  users[msg.sender].balance + calc;
        users[msg.sender].balance= reward;
    } 

    function te(address account) public view returns(uint){
        uint usertoeth = users[account].balance / 1e18 ;
        return usertoeth;

    }

    function te2(address account) public view returns(uint){
        uint usertoeth = users[account].balance / 1e18 ;
        uint calc = ((percentage / 100) * usertoeth) ;

        return calc;
        
    }

    function te3() public  pure returns(uint){
        // uint c = 10 * 0.12;
        // uint s = 12;

        return 12e18 / 100 * 10 ;
        
    }

    
    function withdraw(uint _amount) public {
        require(users[msg.sender].balance >= _amount, "You do not have access to withdraw this amount");
        totalBalance -= _amount;
        if(_amount == users[msg.sender].balance){
            users[msg.sender].balance = 0;
            users[msg.sender].isExist = false;
        }else{
            users[msg.sender].balance = users[msg.sender].balance - _amount;
        }
        // withdraw
        stakingToken.transfer(msg.sender, _amount);
    }

    function balanceOf() public view returns(uint){
        return stakingToken.balanceOf(address(this));
    }

}