pragma solidity ^0.4.0;



library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
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

contract iHOME {
 
  event Transfer(address indexed from,address indexed to,uint256 _tokenId);
  event Approval(address indexed owner,address indexed approved,uint256 _tokenId);
  event ApprovalForAll(address indexed owner,address indexed operator,bool _approved);

  address public owner = 0x3491542173Afe5cAc3e69934B17BDC26AD5073ee;
  string public constant symbol = "IHK";
  string public constant name = "iHOME Key";
  // uint8 public constant decimals = 18;
  uint256 public totalSupply = 8000000000;
  uint256 public totalSold = 0;
  uint256 public maxSupply = 2000000000;
  uint256 public rate = 5 * 10 * 15 wei;


  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

  modifier onlyOwner {
    require(msg.sender == owner);
      _;
  }


  function ihomekey() public {
    owner = msg.sender;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  } 
 

  function totalTokenSold() public constant returns (uint256 balance) {
    return totalSold;
  }

  function balanceMaxSupply() public constant returns (uint256 balance) {
    return maxSupply;
  }
  
  function balanceEth(address _owner) public constant returns (uint256 balance) {
    return _owner.balance;
  }

  function collect(uint256 amount) onlyOwner public{
  msg.sender.transfer(amount);
  }

  function rate_change(uint256 value) onlyOwner public{
  rate = value;
  }

  

   function approve(address _spender, uint256 _amount) public returns (bool success) {
       allowed[msg.sender][_spender] = _amount;
      Approval(msg.sender, _spender, _amount);
      return true;
   }

  


  function transfer(address _to, uint256 _value) public returns (bool) {
   
    require(_to != address(0));
    
    require(_value <= balances[msg.sender]);
   
    
    balances[msg.sender] = balances[msg.sender] - _value;
   
    balances[_to] = balances[_to] + _value;
   
   
    Transfer(msg.sender, _to, _value);
   
    
    return true;
  }


  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
   
    require(_from == msg.sender);
    require(_to != address(0));
    require(balances[_from] >= _amount && balances[_to] + _amount >= balances[_to]);

    if (_amount > 0 && balances[_from] >= _amount) {
        balances[_from] -= _amount;
        balances[_to] += _amount;
        Transfer(_from, _to, _amount);
        return true;
    } else {
        return false;
    }
}
}