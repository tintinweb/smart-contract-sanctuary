/**
 *Submitted for verification at BscScan.com on 2021-12-16
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


    mapping (address => User) public users;

   constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IBEP20(_stakingToken);
        rewardsToken = IBEP20(_rewardsToken);
    }

    function stake(uint _amount) public {
        require(_amount >= 0,"price not valid up 0 ");
        users[msg.sender].ID = id;
        users[msg.sender].wallet =msg.sender;
        users[msg.sender].balance = _amount;
        users[msg.sender].stakeTime = block.timestamp;
        users[msg.sender].timeEnd = block.timestamp + 10 days;
        users[msg.sender].isExist = true;

        // stake
       stakingToken.transferFrom(msg.sender, address(this), _amount);
    }


    function withdraw(uint _amount) public {
        require(users[msg.sender].balance >= _amount, "You do not have access to withdraw this amount");
        
        if(_amount == users[msg.sender].balance){
            users[msg.sender].balance = 0;
            users[msg.sender].isExist = false;
        }else{
            users[msg.sender].balance = users[msg.sender].balance - _amount;
        }
        // withdraw
        stakingToken.transfer(msg.sender, _amount);
    }

    function balanceOf(address _address) public returns(uint){
        return stakingToken.balanceOf(_address);
    }

}