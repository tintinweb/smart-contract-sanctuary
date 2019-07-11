pragma solidity ^0.4.20;

import &#39;./owned.sol&#39;;
import &#39;./erc20.sol&#39;;

contract BorToken is ERC20,Owned {
    
    mapping(address => bool) public frozenAccount;
    
    event AddSupply(uint amount);
    event FrozenFunds(address target,bool frozen);
    event Burn(address target,uint amount);
    
    
    function mine(address _target,uint _amount) public onlyOwner {
        require(_amount > 0);
        totalSupply += _amount;
        balanceOf[_target] += _amount;
        
        emit AddSupply(_amount);
        emit Transfer(0,_target,_amount);
    }
    
    
    function freezeAccount(address _target,bool _freeze) public onlyOwner {
        frozenAccount[_target]=_freeze;
        emit FrozenFunds(_target,_freeze);
    }
    
    function burn(address _from,uint256 _value) public onlyOwner returns (bool success) {
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        
        totalSupply -= _value;
        balanceOf[_from] -= _value;
        
        emit Burn(_from,_value);
        return true;
    }
    
    
    function transfer(address _to,uint256 _value) public returns (bool success){
        success= _transfer(msg.sender,_to,_value);
    }
    
    function transferFrom(address _from,address _to,uint256 _value) public returns (bool success){
        require(allowed[_from][msg.sender] >= _value);
        success= _transfer(_from,_to,_value);
        allowed[_from][msg.sender] -= _value;
    }
    
    function _transfer(address _from,address _to,uint256 _value) internal returns (bool success){
        require(_value > 0);
        require(_to!=address(0));
        require(!frozenAccount[_from]);
        
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from,_to,_value);
        
        return true;
    }
    
    
}