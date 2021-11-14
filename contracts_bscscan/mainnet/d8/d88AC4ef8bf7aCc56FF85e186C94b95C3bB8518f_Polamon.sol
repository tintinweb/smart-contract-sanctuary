/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.23;

contract BEP20Basic {
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}


contract BEP20 is BEP20Basic {
  function allowance(address owner, address spender)
    public view returns (uint);

  function transferFrom(address from, address to, uint value)
    public returns (bool);

  function approve(address spender, uint value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint value
  );
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint a, uint b) internal pure returns (uint c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }


  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}





contract BasicToken is BEP20Basic, Ownable {
  using SafeMath for uint;

  mapping(address => uint) balances;

  uint totalSupply_;

  function totalSupply() public view returns (uint) {
    return totalSupply_;
  }


  function transfer(address _to, uint _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint) {
    return balances[_owner];
  }

}



contract StandardToken is BEP20, BasicToken {

  mapping (address => mapping (address => uint)) internal allowed;


  function transferFrom(
    address _from,
    address _to,
    uint _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint)
  {
    return allowed[_owner][_spender];
  }


  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract Polamon is StandardToken {
  string public constant name = "Polamon";
  string public constant symbol = "POLAMON";
  uint32 public constant decimals = 9 ;
  uint public _tokenSupply = 1*10**12 * 10**9;


  constructor() public {
    totalSupply_ = _tokenSupply;
    balances[msg.sender] = _tokenSupply;
    emit Transfer(0x0, msg.sender, _tokenSupply);
  }
}