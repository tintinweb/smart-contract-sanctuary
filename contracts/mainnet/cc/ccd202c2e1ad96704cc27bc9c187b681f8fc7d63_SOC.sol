pragma solidity ^0.4.11;
//Math operations with safety checks
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

//creator
contract owned{
    address public Admin;
    function owned() public {
        Admin = msg.sender;
    }
    modifier onlyAdmin{
        require(msg.sender == Admin);
        _;
    }
    function transferAdmin(address NewAdmin) onlyAdmin public {
        Admin = NewAdmin;
    }
}

//public
contract Erc{
    using SafeMath for uint;
    uint public totalSupply;
    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    mapping (address => bool) public frozenAccount;
    
    uint256 public sellPrice;
    uint256 public buyPrice;
    
    function balanceOf(address _in) constant returns (uint);
    function disqualified(address _from,uint value);
    function transfer(address _to , uint value);
    function allowance(address owner, address spender) constant returns (uint);
    function transferFrom(address from,address to ,uint value);
    function approve(address spender, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from , address indexed to , uint value);
    event FrozenFunds(address target, bool frozen);
    event Disqualified(address targetAD, uint value);
     
    modifier onlyPayloadSize(uint size) {
    if(msg.data.length < size + 4) {throw;}_;
    }
    
    function _transfer(address _from ,address _to, uint _value) onlyPayloadSize(2 * 32) internal {
    require(!frozenAccount[_from]);                     
    require(!frozenAccount[_to]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    }
}

//function
contract StandardToken is Erc,owned{
    //check if user illicit activity,freezeAccount and back to totalSupply
    function disqualified(address targetAD, uint _value) onlyAdmin public {
        require(balances[targetAD] >= _value);  
        balances[targetAD] -= _value;           
        totalSupply -= _value;                    
        Disqualified(msg.sender, _value);
    }
    
    function freezeAccount(address target, bool freeze) onlyAdmin public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public {
    _transfer(msg.sender, _to, _value);
    }
  
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint _value) {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyAdmin public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }
    
    function buy() payable public {
        uint amount = msg.value / buyPrice;              // calculates the amount
        Transfer(this, msg.sender, amount);              // makes the transfers
    }
    
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);     // checks if the contract has enough ether to buy
        Transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice);         // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
    }
}

//contract
contract SOC is StandardToken {
    string public name = "CADT Token";
    string public symbol = "CADT";
    uint public decimals = 8;
    uint public INITIAL_SUPPLY = 50000000000000000; // Initial supply is 500,000,000 SOC

    function SOC(){
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
}