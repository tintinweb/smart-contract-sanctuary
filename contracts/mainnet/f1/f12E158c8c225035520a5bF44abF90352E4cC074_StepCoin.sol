// Solydity version
pragma solidity ^0.4.11;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    address public owner;
    address public icoOwner;
    address public burnerOwner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == icoOwner);
        _;
    }

    modifier onlyBurner() {
      require(msg.sender == owner || msg.sender == burnerOwner);
      _;
    }

}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// initialization contract
contract StepCoin is ERC20Interface, Ownable{

    using SafeMath for uint256;

    string public constant name = "StepCoin";

    string public constant symbol = "STEP";

    uint8 public constant decimals = 3;

    uint256 totalSupply_;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
     
    event Burn(address indexed burner, uint256 value);

    // Function initialization of contract
    function StepCoin() {

        totalSupply_ = 100000000 * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public {
        require(_value <= allowed[_from][msg.sender]);
        
        allowed[_from][_to] = allowed[_from][msg.sender].sub(_value);
        
        _transfer(_from, _to, _value);
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool){
        require(_to != 0x0);
        require(_value <= balances[_from]);
        require(balances[_to].add(_value) >= balances[_to]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);

        Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferOwner(address _from, address _to, uint256 _value) onlyOwner public {
        _transfer(_from, _to, _value);
    }

    function setIcoOwner(address _addressIcoOwner) onlyOwner external {
        icoOwner = _addressIcoOwner;
    }

    function burn(uint256 _value) onlyOwner onlyBurner public {
      _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) onlyOwner onlyBurner internal {
      require(_value <= balances[_who]);

      balances[_who] = balances[_who].sub(_value);
      totalSupply_ = totalSupply_.sub(_value);
      Burn(_who, _value);
      Transfer(_who, address(0), _value);
  }

    function setBurnerOwner(address _addressBurnerOwner) onlyOwner external {
        burnerOwner = _addressBurnerOwner;
    }
}