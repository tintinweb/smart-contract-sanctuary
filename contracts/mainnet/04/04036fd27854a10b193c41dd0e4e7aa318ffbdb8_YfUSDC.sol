/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

pragma solidity ^0.6.7;

   // Telegram: https://t.me/YfUSDC
   // Website : https://YfUSDC.com
   
contract Owned {
    address payable  internal owner = msg.sender;
    

    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
   
}

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 );
    function transfer(address _to, uint256 _value) public virtual returns (bool );
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool );
    function approve(address _spender, uint256 _value) public virtual returns (bool );
    function allowance(address _owner, address _spender) view public virtual returns (uint256 );
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Owned,  ERC20 {

    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    

    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract YfUSDC is Token{
        
        string public symbol = "UDC";
        string public name = "YfUSDC";
        uint8 public decimals = 18;
        
 
      
    constructor() public{
        totalSupply = 51000000000000000000000;  
        owner = msg.sender;
        balances[owner] = totalSupply;
        emit Transfer(address(0),owner, totalSupply);
    }


    receive () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
}