/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

pragma solidity ^0.5.0;
contract Token {
    
 uint256 public totalSupply;
 
 function balanceOf(address _owner)public view returns (uint256 balance) {}
 
 function transfer(address _to, uint256 _value)public returns (bool success) {}
 
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {}
 
 function approve(address _spender, uint256 _value) public returns (bool success) {}
 
 function allowance(address _owner, address _spender)public view returns (uint256 remaining) {}
 
 event Transfer(address indexed _from, address indexed _to, uint256 _value);

 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    
 function transfer(address _to, uint256 _value)public returns (bool success) {
    if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    } else { return false; }
 }
 
 
 function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    } else { return false; }
 }
 
 
 function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
 }
 
 
 function approve(address _spender, uint256 _value)public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
 }
 
 
 function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
 }
 
 
 mapping (address => uint256) balances;
 mapping (address => mapping (address => uint256)) allowed;
 //uint256 public totalSupply;
}


contract ERC20Token is StandardToken {
 function ()  external {
    revert();
 }
 
 string public name = "BhaskarToken"; 
 uint8 public decimals = 3; 
 string public symbol ="BHA"; 
 string public version = 'H1.0'; 
 
 constructor () public {
    balances[msg.sender] = 100000; 
    totalSupply = 5000000;
    name = "BhaskarToken"; 
    decimals = 3; 
    symbol = "BT"; 
 }
 
 
//  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
//     allowed[msg.sender][_spender] = _value;
//   emit Approval(msg.sender, _spender, _value);
//     if(!_spender.call(bytes4(bytes32(sha256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert(); }
//         return true;
//     }
}