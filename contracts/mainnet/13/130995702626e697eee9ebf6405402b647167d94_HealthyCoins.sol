pragma solidity ^0.4.11;

contract Owned {

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _newOwner) onlyOwner {
	 if(_newOwner == 0x0)revert();
        owner = _newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}


// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract Token {
 
    function totalSupply() public  returns (uint256 supply);
	 
    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);
  
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
    function burn( uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  
    event Burn(address indexed from, uint256 value);
}



contract HealthyCoins is Token, Owned {
    using SafeMath for uint256;
  
    uint public  _totalSupply;
  
    string public   name;         //The Token&#39;s name
  
    uint8 public constant decimals = 4;    //Number of decimals of the smallest unit
  
    string public  symbol;    //The Token&#39;s symbol 
  
    uint256 public mintCount;
  
    uint256 public deleteToken;
  
    uint256 public soldToken;

   
    mapping (address => uint256) public balanceOf;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping(address => uint256)) allowed;

  

    // Constructor
    function HealthyCoins(string coinName,string coinSymbol,uint initialSupply) {
        _totalSupply = initialSupply *10**uint256(decimals);                        // Update total supply
        balanceOf[msg.sender] = _totalSupply; 
        name = coinName;                                   // Set the name for display purposes
        symbol =coinSymbol;   
        
    }

   function totalSupply()  public  returns (uint256 totalSupply) {
        return _totalSupply;
    }
	
    // Send back ether sent to me
    function () {
        revert();
    }

    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _amount) returns (bool success) {
        // according to AssetToken&#39;s total supply, never overflow here
        if (balanceOf[msg.sender] >= _amount
            && _amount > 0) {            
            balanceOf[msg.sender] -= uint112(_amount);
            balanceOf[_to] = _amount.add(balanceOf[_to]).toUINT112();
            soldToken = _amount.add(soldToken).toUINT112();
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

   
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        // according to AssetToken&#39;s total supply, never overflow here
        if (balanceOf[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0) {
            balanceOf[_from] = balanceOf[_from].sub(_amount).toUINT112();
            allowed[_from][msg.sender] -= _amount;
            balanceOf[_to] = _amount.add(balanceOf[_to]).toUINT112();
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

   
    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }



    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //Mint tokens and assign to some one
    function mint(address _owner, uint256 _amount) onlyOwner{
     
            balanceOf[_owner] = _amount.add(balanceOf[_owner]).toUINT112();
            mintCount =  _amount.add(mintCount).toUINT112();
            _totalSupply = _totalSupply.add(_amount).toUINT112();
    }
  //Burn tokens from owner account
  function burn(uint256 _count) public returns (bool success)
  {
          balanceOf[msg.sender] -=uint112( _count);
          deleteToken = _count.add(deleteToken).toUINT112();
         _totalSupply = _totalSupply.sub(_count).toUINT112();
          Burn(msg.sender, _count);
		  return true;
    }
    
  }