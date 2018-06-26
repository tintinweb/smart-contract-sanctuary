pragma solidity ^0.4.24;

/////設定管理者/////

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}    

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/////空投合約/////

contract airdrop is owned{
    
//初始設定
    address public tokenAddress = 0x5d5Cd6aCc5Ec2485Bc52517B144081634aBA9B41;
    
    mapping (address => uint) public readyTime;
    uint public amount;
    uint public cooldown = 300;

//管理權限
    function set_amount(uint new_amount){
        amount = new_amount;
    }
    
    function set_address(address new_address){
        tokenAddress = new_address;
    }
    
    function set_cooldown(uint new_cooldown){
        cooldown = new_cooldown;
    }
    
    function withdraw(uint _amount) onlyOwner{
        ERC20Basic(tokenAddress).transfer(owner, amount);
    }
    
//領空投幣啦!!! 
    function (){
        get_token();
    }
    
    function get_token(){
        require(readyTime[msg.sender] < now);
        readyTime[msg.sender] = now + cooldown;
        ERC20Basic(tokenAddress).transfer(msg.sender, amount);
    }
    function view_readyTime() view public returns(uint _readyTime){
        return readyTime[msg.sender];
    }
    
}