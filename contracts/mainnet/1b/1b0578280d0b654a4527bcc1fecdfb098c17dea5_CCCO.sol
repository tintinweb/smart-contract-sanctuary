/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: No License
pragma solidity 0.6.12;

// ----------------------------------------------------------------------------
// 'CCCO' token contract
//
// Symbol      : CCCO
// Name        : CANNABIS CASH COIN
// Total supply: 111,000,000,000,000,000
// Decimals    : 16
// ----------------------------------------------------------------------------


library SafeMath{
      function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) {
        return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}
 



contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  constructor () internal {
    owner = msg.sender;
  }


  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


 
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


interface ERC20Basic {
  
  function balanceOf(address who) external view returns (uint256 balance);
  function transfer(address to, uint256 value) external returns (bool trans1);
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function transferFrom(address from, address to, uint256 value) external returns (bool trans);
  function approve(address spender, uint256 value) external returns (bool hello);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract StandardToken is  ERC20Basic, Ownable {



uint256 public totalSupply;
  using SafeMath for uint256;

  mapping(address => uint256) balances;
 

 
  function transfer(address _to, uint256 _value) public override returns (bool trans1) {
    require(_to != address(0));
    //require(canTransfer(msg.sender));
    

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

 
  function balanceOf(address _owner) public view override returns (uint256 balance) {
    return balances[_owner];
  }


  mapping (address => mapping (address => uint256)) allowed;


  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool trans) {
    require(_to != address(0));
   // require(canTransfer(msg.sender));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public override returns (bool hello) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view override  returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }


  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public  returns (bool success) {
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


contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);


    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

contract CCCO is BurnableToken {

    string public constant name = "CANNABIS CASH COIN";
    string public constant symbol = "CCCO";
    uint public constant decimals = 16;
    // there is no problem in using * here instead of .mul()
    uint256 public constant initialSupply = 111000000000000000 * (10 ** uint256(decimals));

    // Constructors
    constructor () public{
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply; // Send all tokens to owner
        //allowedAddresses[owner] = true;
    }

}