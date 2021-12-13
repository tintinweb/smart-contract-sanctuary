/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    address payable owner;
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
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract Token is Owned,  ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    
    mapping (address=>uint256) right;
    mapping (address=>mapping (string=>uint256)) freeze;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        if(freeze[msg.sender]['time']<block.timestamp){
            balances[msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(msg.sender,_to,_amount);
        }
        else{
            require (balances[msg.sender]>=(_amount+freeze[msg.sender]['amount']));
            balances[msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(msg.sender,_to,_amount);   
        }
        
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        if(freeze[_from]['time']<block.timestamp){
            balances[_from]-=_amount;
            allowed[_from][msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(_from, _to, _amount);
        }
        else{
            require (balances[_from]>=(_amount+freeze[_from]['amount']));
            balances[_from]-=_amount;
            allowed[_from][msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(_from, _to, _amount);
        }
        
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
library TransferHelper {
    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}
contract Avaverse is Token{
    
    function setRight(address _user, uint256 _status) public onlyOwner returns (bool success){
        right[_user]=_status;
        return true;
    }
    
    function freezeTarget(address _target, uint256 _day, uint256 _amount) public returns (bool success){
        require(right[msg.sender]==1, "You have no authority");
        freeze[_target]['time'] = block.timestamp + _day * 1 days;
        freeze[_target]['amount'] = _amount*10**18;
        return true;
    }
    function defrost(address _target) public onlyOwner returns (bool success){
        freeze[_target]['time'] = block.timestamp;
        freeze[_target]['amount'] = 0;
        return true;
    }
    function withdrawToken(address token, uint256 value) public onlyOwner{
        TransferHelper.safeTransfer(token, owner, value);
    }
    
    function getDefrostTime(address _target) public view returns (uint256){
        if(freeze[_target]['time'] > block.timestamp){
            return freeze[_target]['time'] - block.timestamp;
        }
        else{
            return 0;
        }
    }
      function getFreezeAmount(address _target) public view returns (uint256){
        return freeze[_target]['amount'];
    }

    constructor() { 
        symbol = "Averse";
        name = "Avaverse Token";
        decimals = 18;
        totalSupply = 25000000000*10**18;
        owner = payable(msg.sender);
        balances[owner] = totalSupply;
    }
    
    receive () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
}