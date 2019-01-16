pragma solidity ^0.4.25;

////設定管理者
contract owned {
    address public owner;
    address public owner2;

    constructor()public{
        owner = msg.sender;
    }
    modifier onlyOwner{
        require(msg.sender == owner || msg.sender == owner2);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function transferOwnership2(address newOwner) public onlyOwner {
        owner2 = newOwner;
    }
    
}

// erc20 interface
contract erc20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract inquire is owned{
    
    event Pay(address indexed payer, uint value);
    event Withdraw_token(address indexed withdrawer,uint value);
    event Withdraw_eth(address indexed withdrawer,uint value);
    
    constructor() public{
        
    }
    
    function() payable public{
        
        emit Pay(msg.sender, msg.value);
        
    }
    
    function withdraw_token(address contract_address, uint _amount)
    onlyOwner public{
        require(erc20Interface(contract_address).transfer(owner, _amount));
    }
    
    function withdraw_all_token(address contract_address)
    onlyOwner public{
        uint all_token = erc20Interface(contract_address).balanceOf(this);
        require(erc20Interface(contract_address).transfer(owner, all_token));
    }

    function withdraw_eth(uint _amount)onlyOwner public{
        owner.transfer(_amount);
        emit Withdraw_eth(owner,_amount);
    }
    
    function withdraw_all_eth()onlyOwner public{
        owner.transfer(address(this).balance);
        emit Withdraw_eth(owner,address(this).balance);
    }
    
}