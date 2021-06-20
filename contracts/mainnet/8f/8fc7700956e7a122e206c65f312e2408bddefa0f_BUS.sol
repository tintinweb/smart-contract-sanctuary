/**
 *Submitted for verification at Etherscan.io on 2021-06-20
*/

pragma solidity ^0.4.18;

contract ERC20 {
  uint256 public totalSupply;
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  event Transfer(address indexed _from, address indexed _to, uint _value);
  /* This notifies clients about the amount burnt */
  event Burn(address indexed from, uint256 value);
  /* This notifies clients about the amount frozen */
  event Freeze(address indexed from, uint256 value);
  /* This notifies clients about the amount unfrozen */
  event Unfreeze(address indexed from, uint256 value);
}

contract Owned{
    address public owner;
    function Owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner{
        if(msg.sender != owner){
            revert();
        }else{
            _;
        }
    }
	
    function transferOwner(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

/* Math operations with safety checks */

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}
contract BUS is ERC20, Owned, SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function BUS(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) public{
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_to != 0x0);
		require(_value > 0); 
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
		return true;
    }
    
	/* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
		require(_value > 0); 
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }
	
	
	/* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(address _target, uint256 _value) onlyOwner public returns (bool success) {
        require(_value > 0); 
		require(_target != 0x0); 
        require(balanceOf[_target] >= _value);
        balanceOf[_target] = SafeMath.safeSub(balanceOf[_target], _value);
        totalSupply = SafeMath.safeSub(totalSupply,_value);
        Burn(_target, _value);
        return true;
    }
	
	function freeze(address _target, uint256 _value) onlyOwner public returns (bool success) {
        require(_value > 0); 
		require(_target != 0x0); 
        require(balanceOf[_target] >= _value);
        balanceOf[_target] = SafeMath.safeSub(balanceOf[_target], _value);
        freezeOf[_target] = SafeMath.safeAdd(freezeOf[_target], _value);
        Freeze(_target, _value);
        return true;
    }
	
	function unfreeze(address _target, uint256 _value) onlyOwner public returns (bool success) {
        require(_value > 0); 
		require(_target != 0x0); 
        require(freezeOf[_target] >= _value);
        freezeOf[_target] = SafeMath.safeSub(freezeOf[_target], _value);
		balanceOf[_target] = SafeMath.safeAdd(balanceOf[_target], _value);
        Unfreeze(_target, _value);
        return true;
    }
	
	function withdrawEther(uint256 amount) onlyOwner public{
		owner.transfer(amount);
	}
	
	function() payable public{
    }
}