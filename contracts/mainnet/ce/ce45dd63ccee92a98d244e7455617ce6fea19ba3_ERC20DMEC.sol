pragma solidity ^0.4.23;

import './erc20interface.sol';
import './owned.sol';

contract ERC20DMEC is ERC20Interface,owned{
     mapping(address => uint256) public balanceOf;
     mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public frozenAccount;
    event AddSupply(uint amount);
    event FrozenFunds(address target,bool frozen);
    event Burn(address target,uint amount);
     
     constructor () public{
             name = "Digital Medical Chain";
             symbol = "DMEC";
             decimals = 18;
             totalSupply = 100000000000000000000000000;
             balanceOf[msg.sender] = totalSupply;
     }
    
    function mine(address target,uint amount) public onlyowner{
        
        totalSupply += amount;
        balanceOf[target] += amount;
        emit AddSupply(amount);
        emit Transfer(0,target,amount);
    }
    function freezeAccount(address target,bool freeze) public onlyowner{
        frozenAccount[target] = freeze;
        emit FrozenFunds(target,freeze);
        
    }
    
    function transfer(address _to,uint256 _value) returns (bool success){
             require(_to != address(0));
             require(!frozenAccount[msg.sender]);
             
             require(balanceOf[msg.sender] >= _value);
             require(balanceOf[_to] + _value >= balanceOf[_to]);
             balanceOf[msg.sender] -= _value;
             balanceOf[_to] += _value;
             emit Transfer(msg.sender,_to,_value);
             return true;
        
    }
    function transferFrom(address _from,address _to,uint256 _value) returns(bool success){
        
             require(_to != address(0));
             
             require(!frozenAccount[_from]);
             
             require(allowed[_from][msg.sender] >= _value);
             require(balanceOf[_from] >= _value);
             require(balanceOf[_to] + _value >= balanceOf[_to]);
             balanceOf[_from] -= _value;
             balanceOf[_to] += _value;
             allowed[_from][msg.sender] -= _value;
             emit Transfer(msg.sender,_to,_value);
             return true;
        
        
    }
    function burn(uint256 _value) public returns(bool success){
             require(balanceOf[msg.sender] >= _value);
             totalSupply -= _value;
             balanceOf[msg.sender] -= _value;
             emit Burn(msg.sender,_value);
             return true;
             
    }
    function burnFrom(address _from,uint256 _value) public returns(bool success){
        
             require(balanceOf[_from] >= _value);
             require(allowed[_from][msg.sender] >= _value);
             
             totalSupply -= _value;
             balanceOf[msg.sender] -= _value;
             allowed[_from][msg.sender] -= _value;
             
             emit Burn(msg.sender,_value);
             return true;
        
    }
    function approve(address _spender,uint256 _value) returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
        
    }
    function allowance(address _owner,address _spender) view returns(uint256 remaining){
        
        return allowed[_owner][_spender];
        
    }
    
}