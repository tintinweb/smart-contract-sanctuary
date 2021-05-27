/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

pragma solidity ^0.4.19;

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
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
}


contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract ERC20 {
  function balanceOf(address _owner) public view returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) external returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {}
  function approve(address _spender, uint256 _value) external returns (bool success) {}
  function allowance(address _owner, address _spender) external returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Vote is Ownable,ERC20 {
    using SafeMath for uint256;

    string public name = 'V';
    string public symbol = 'v';
    uint public decimals = 18;
    
    uint public topicid;
    uint public totalSupply;
    mapping (address => uint) public balances;
    mapping (address => string) public nameAddress;
    mapping (address => uint[]) public topicIdVoted; 
    
    
    function getBalances() public view returns(uint){
        return balances[msg.sender];
    }
    
    function FnAdd(uint _value) public {
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
    }
      
    function FnSub(uint _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
    }
  
}