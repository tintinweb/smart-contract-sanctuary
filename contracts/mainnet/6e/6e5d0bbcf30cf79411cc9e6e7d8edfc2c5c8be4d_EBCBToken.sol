pragma solidity ^0.4.21;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
	require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract EBCBToken is StandardToken {
    string public name = &#39;EBCBToken&#39;;
	string public symbol = &#39;EBCB&#39;;
	uint8 public decimals = 2;
	uint public INITIAL_SUPPLY = 100000000;
	address public ceoAddress;
	address public cooAddress = 0xD22adC4115e896485aB9C755Cd2972f297Aa24B8;
	uint256 public sellPrice = 0.0002 ether;
    uint256 public buyPrice = 0.0002 ether;
	
	function EBCBToken() public {
	    totalSupply_ = INITIAL_SUPPLY;
	    balances[msg.sender] = INITIAL_SUPPLY.sub(2000000);
	    balances[cooAddress] = 2000000;
	    ceoAddress = msg.sender;
	}
	
	modifier onlyCEOorCOO() {
        require(msg.sender == ceoAddress || msg.sender == cooAddress);
        _;
    }

    function mintToken(uint256 mintedAmount) public onlyCEOorCOO {
       totalSupply_ = totalSupply_.add(mintedAmount);
       balances[msg.sender] = balances[msg.sender].add(mintedAmount);
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyCEOorCOO {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function getBonusPool() public view returns (uint256) {
        return this.balance;
    }
	
    function buy() payable public returns (uint amount){
        amount = msg.value.div(buyPrice);
        require(balances[ceoAddress] >= amount);
        balances[msg.sender] = balances[msg.sender].add(amount);
        balances[ceoAddress] = balances[ceoAddress].sub(amount);
        Transfer(ceoAddress, msg.sender, amount);
        return amount;
    }
	
    function sell(uint amount) public returns (uint revenue){
        require(balances[msg.sender] >= amount);
        balances[ceoAddress] = balances[ceoAddress].add(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        revenue = amount.mul(sellPrice);
        msg.sender.transfer(revenue);
        Transfer(msg.sender, ceoAddress, amount);
        return revenue;
    }
	
	function batchTransfer(address[] _tos, uint256 _value) public {
	  for(uint i = 0; i < _tos.length; i++) {
        transfer( _tos[i], _value);
      }
	}
}