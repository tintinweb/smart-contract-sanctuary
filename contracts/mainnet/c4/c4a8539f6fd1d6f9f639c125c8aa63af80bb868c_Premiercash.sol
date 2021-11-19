/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.4.26;


library Cogni{
  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  
  
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


contract Premier {
    
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public  returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract Premiercash is Premier {
    
    string public constant name = "Premiercash";
    string public constant symbol = "PMC";
    uint8 public constant decimals = 0;
  uint256 public constant totalSupply = 750000000000;

  using Cogni for uint256;
  mapping(address => uint256) balances;
  
 constructor() public {
         balances[0xCdaB3FFD06225D5FF099230bF03f5B3177FE28Be] = totalSupply;
        emit Transfer(address(0), 0xCdaB3FFD06225D5FF099230bF03f5B3177FE28Be, totalSupply);
    }

 
  function transfer(address _to, uint256 _value) public returns (bool) {
    //Safemath fnctions will throw if value is invalid
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  
  function balanceOf(address _owner) public constant returns (uint256 bal) {
    return balances[_owner];
  }
}


contract ERC20 is Premier {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Token is ERC20, Premiercash {
  mapping (address => mapping (address => uint256)) allowed;
  
 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    // Safe math functions will throw if value invalid
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public returns (bool) {
     assert((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}