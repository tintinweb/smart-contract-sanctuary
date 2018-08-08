pragma solidity ^0.4.23;

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
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
    c = a * b;
    assert(c / a == b);
    return c;
	}
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }
  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}
contract StandardToken is ERC20, BurnableToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
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
  function approve(address _spender, uint256 _value) public returns (bool) {
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
    returns (uint256)
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

contract UniDAG is StandardToken{

  string public constant name = "UniDAG";
  string public constant symbol = "UDAG";
  uint8 public constant decimals = 18;
  address public owner;
  address public CrowdsaleContract;

  constructor () public {
   	//Token Distribution
     totalSupply_ = 60600000e18;
	owner = 0x653859383f60741880f377085Ec44Cf75702C373;
	CrowdsaleContract = msg.sender;
    balances[msg.sender] = 30300000e18;
	
	//Airdrop
	balances[0x1b3481e6c425baD0C8C44e563553BADF8Aca9415] = 6060000e18;

	//Partnership
	balances[0x174cc6965Dd694f3BCE8B51434b7972ed8497374] = 7575000e18;

	//Marketing 
	balances[0xF4A966739FF81B09CDb075Bf896B5Bd943C50f52] = 7575000e18;

	//Bounty 
	balances[0x42373a7cE8dBF539e0b39D25C3F5064CFabBE227] = 9090000e18;
  }
  modifier onlyOwner() {
        require(msg.sender == owner);
        _;
	}

  function burnCrowdsale() public onlyOwner {
    _burn(CrowdsaleContract, balances[CrowdsaleContract]);
  }
}

contract UniDAGCrowdsale {
    using SafeMath for uint256;	
    UniDAG public token;
    address public owner;	
    uint256 public rateFirstRound = 4000;
    uint256 public rateSecondRound = 3500;
    uint256 public rateThirdRound = 3000;

	uint256 public openingTime = 1530403200;             
   	//1.07.2018 0:00:00 GMT+0

	uint256 public secondRoundTime = 1539129600;      
 	//10.10.2018 0:00:00 GMT+0

	uint256 public thirdRoundTime = 1547856000;        
  	//19.01.2019 0:00:00 GMT+0

	uint256 public closingTime = 1556582399;               
 	 //29.04.2019 23:59:59 GMT +0
	
	uint256 public weiRaised;
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 timestamp);
	
	modifier onlyWhileOpen {
		require(block.timestamp >= openingTime && block.timestamp <= closingTime);
		_;
	}
    constructor () public {	
        token = new UniDAG();
        owner = msg.sender;
    }
    function () external payable {
        buyTokens(msg.sender);
    }
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens, block.timestamp);
        _forwardFunds();
    }
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal onlyWhileOpen {
        require(_beneficiary != address(0));
   
 //Minimum 0.01 ETH

        require(_weiAmount >= 10e15);
    }
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    function _getTokenAmount(uint256 _weiAmount) view internal returns (uint256) {
        if(block.timestamp < secondRoundTime) return _weiAmount.mul(rateFirstRound);
        if(block.timestamp < thirdRoundTime) return _weiAmount.mul(rateSecondRound);
		return _weiAmount.mul(rateThirdRound);
    }
    function _forwardFunds() internal {
        owner.transfer(msg.value);
    }
}