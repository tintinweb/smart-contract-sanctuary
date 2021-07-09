/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity ^0.8.2;

contract SAFEFREEBRITNEY {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000 * 10 ** 18; 
    string public name = "SAFEFREEBRITNEY";
    string public symbol = "SFB";
    uint public decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
        function balanceOf(address owner) public view returns(uint) {
            return balances[owner];
        }
        
        function transfer(address to, uint value) public returns(bool) {
            require(balanceOf(msg.sender) >= value, 'balance too low');
            balances[to] += value;
            balances[msg.sender] -= value;
            emit Transfer (msg.sender, to, value);
            return true;
        }
        
     function transferFrom(address from, address to, uint value) public returns(bool) {
         require(balanceOf(from) >= value, 'balance too low');
         require(allowance[from][msg.sender] >= value, 'allowance too low');
         balances[to] += value;
         balances[from] -= value;
         emit Transfer(from, to, value);
         return true;
     }
     
function approve(address _spender, uint256 _value) public returns (bool) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
        }