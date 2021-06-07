pragma solidity ^0.5.0;

import "./erc20token.sol";

contract stakingFriends{
    FriendsCoin public _coin;
    address public owner;
    address[] public stakers;
    mapping (address => uint) staked_amount;
    mapping (address => bool) has_staked_value;
    mapping (address => bool) already_seen;
    uint public rewards_remaining;
    uint256 public allowance;
    
    constructor(FriendsCoin _FriendsCoin) public{
        _coin = _FriendsCoin;
        owner = msg.sender;
    }
    
    function stake (uint _amount) public{
        allowance = _coin.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
         _coin.transferFrom(msg.sender,address(this), _amount);
        
        if(has_staked_value[msg.sender]){
            staked_amount[msg.sender]+=_amount;
        }
        else if(!already_seen[msg.sender]){
            stakers.push(msg.sender);
            already_seen[msg.sender] = true;
        }
        
        has_staked_value[msg.sender] = true;
        staked_amount[msg.sender] = _amount;
        
    }
    
    function feed(uint _amount)public{
        allowance = _coin.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        _coin.transferFrom(msg.sender,address(this), _amount);
        rewards_remaining+=_amount;
    }

    function endstake() public{
        _coin.transfer(msg.sender, staked_amount[msg.sender]);
        staked_amount[msg.sender]=0;
        has_staked_value[msg.sender]=false;
    }
    
    function payrewards () public{
        require (msg.sender == owner, "Only Owner can pay Rewards!");
        for(uint i = 0; i<stakers.length;i++){
            address stakers_adress = stakers[i];
            staked_amount[stakers_adress]= staked_amount[stakers_adress]+staked_amount[stakers_adress]/10;
        }
    }
}