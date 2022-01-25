/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

pragma solidity ^0.8.10;

library SafeMath {
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract OrangebeamToken {
    using SafeMath for uint256;
    address public owner;
    string public name = "Orangebeam Token";
    string public symbol = "ORB";
    uint256 public decimals = 18;
    uint256 public totalSupply = 21000000000000000000000000; // 1,000,000 x 10^18
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    constructor() {
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}