pragma solidity ^0.4.21;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


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


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  function Ownable() public {
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


contract TokenOffering is StandardToken, Ownable, BurnableToken {
  
    bool public offeringEnabled;

   
    uint256 public currentTotalTokenOffering;

   
    uint256 public currentTokenOfferingRaised;

   
    uint256 public bonusRateOneEth;

   
    uint256 public startTime;
    uint256 public endTime;

    bool public isBurnInClose = false;

    bool public isOfferingStarted = false;

    event OfferingOpens(uint256 startTime, uint256 endTime, uint256 totalTokenOffering, uint256 bonusRateOneEth);
    event OfferingCloses(uint256 endTime, uint256 tokenOfferingRaised);

    
    function setBonusRate(uint256 _bonusRateOneEth) public onlyOwner {
        bonusRateOneEth = _bonusRateOneEth;
    }

    
   
   
   
   

    
    function preValidatePurchase(uint256 _amount) internal {
        require(_amount > 0);
        require(isOfferingStarted);
        require(offeringEnabled);
        require(currentTokenOfferingRaised.add(_amount) <= currentTotalTokenOffering);
        require(block.timestamp >= startTime && block.timestamp <= endTime);
    }
    
    
    function stopOffering() public onlyOwner {
        offeringEnabled = false;
    }
    
    
    function resumeOffering() public onlyOwner {
        offeringEnabled = true;
    }

    
    function startOffering(
        uint256 _tokenOffering, 
        uint256 _bonusRateOneEth, 
        uint256 _startTime, 
        uint256 _endTime,
        bool _isBurnInClose
    ) public onlyOwner returns (bool) {
        require(_tokenOffering <= balances[owner]);
        require(_startTime <= _endTime);
        require(_startTime >= block.timestamp);

       
        require(!isOfferingStarted);

        isOfferingStarted = true;

       
        startTime = _startTime;
        endTime = _endTime;

       
        isBurnInClose = _isBurnInClose;

       
        currentTokenOfferingRaised = 0;
        currentTotalTokenOffering = _tokenOffering;
        offeringEnabled = true;
        setBonusRate(_bonusRateOneEth);

        emit OfferingOpens(startTime, endTime, currentTotalTokenOffering, bonusRateOneEth);
        return true;
    }

    
    function updateStartTime(uint256 _startTime) public onlyOwner {
        require(isOfferingStarted);
        require(_startTime <= endTime);
        require(_startTime >= block.timestamp);
        startTime = _startTime;
    }

    
    function updateEndTime(uint256 _endTime) public onlyOwner {
        require(isOfferingStarted);
        require(_endTime >= startTime);
        endTime = _endTime;
    }

    
    function updateBurnableStatus(bool _isBurnInClose) public onlyOwner {
        require(isOfferingStarted);
        isBurnInClose = _isBurnInClose;
    }

    
    function endOffering() public onlyOwner {
        if (isBurnInClose) {
            burnRemainTokenOffering();
        }
        emit OfferingCloses(endTime, currentTokenOfferingRaised);
        resetOfferingStatus();
    }

    
    function burnRemainTokenOffering() internal {
        if (currentTokenOfferingRaised < currentTotalTokenOffering) {
            uint256 remainTokenOffering = currentTotalTokenOffering.sub(currentTokenOfferingRaised);
            _burn(owner, remainTokenOffering);
        }
    }

    
    function resetOfferingStatus() internal {
        isOfferingStarted = false;        
        startTime = 0;
        endTime = 0;
        currentTotalTokenOffering = 0;
        currentTokenOfferingRaised = 0;
        bonusRateOneEth = 0;
        offeringEnabled = false;
        isBurnInClose = false;
    }
}





contract WithdrawTrack is StandardToken, Ownable {

	struct TrackInfo {
		address to;
		uint256 amountToken;
		string withdrawId;
	}

	mapping(string => TrackInfo) withdrawTracks;

	function withdrawToken(address _to, uint256 _amountToken, string _withdrawId) public onlyOwner returns (bool) {
		bool result = transfer(_to, _amountToken);
		if (result) {
			withdrawTracks[_withdrawId] = TrackInfo(_to, _amountToken, _withdrawId);
		}
		return result;
	}

	function withdrawTrackOf(string _withdrawId) public view returns (address to, uint256 amountToken) {
		TrackInfo track = withdrawTracks[_withdrawId];
		return (track.to, track.amountToken);
	}

}


contract ContractSpendToken is StandardToken, Ownable {
  mapping (address => address) private contractToReceiver;

  function addContract(address _contractAdd, address _to) external onlyOwner returns (bool) {
    require(_contractAdd != address(0x0));
    require(_to != address(0x0));

    contractToReceiver[_contractAdd] = _to;
    return true;
  }

  function removeContract(address _contractAdd) external onlyOwner returns (bool) {
    contractToReceiver[_contractAdd] = address(0x0);
    return true;
  }

  function contractSpend(address _from, uint256 _value) public returns (bool) {
    address _to = contractToReceiver[msg.sender];
    require(_to != address(0x0));
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function getContractReceiver(address _contractAdd) public view onlyOwner returns (address) {
    return contractToReceiver[_contractAdd];
  }
}

contract ContractiumToken is TokenOffering, WithdrawTrack, ContractSpendToken {

    string public constant name = "Contractium";
    string public constant symbol = "CTU";
    uint8 public constant decimals = 18;
  
    uint256 public constant INITIAL_SUPPLY = 3000000000 * (10 ** uint256(decimals));
  
    uint256 public unitsOneEthCanBuy = 15000;

   
    uint256 internal totalWeiRaised;

    event BuyToken(address from, uint256 weiAmount, uint256 tokenAmount);

    function ContractiumToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function() public payable {

        require(msg.sender != owner);

       
        uint256 amount = msg.value.mul(unitsOneEthCanBuy);

       
        uint256 amountBonus = msg.value.mul(bonusRateOneEth);
        
       
        amount = amount.add(amountBonus);

       
        preValidatePurchase(amount);
        require(balances[owner] >= amount);
        
        totalWeiRaised = totalWeiRaised.add(msg.value);
    
       
        currentTokenOfferingRaised = currentTokenOfferingRaised.add(amount); 
        
        balances[owner] = balances[owner].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(amount);

        emit Transfer(owner, msg.sender, amount);
        emit BuyToken(msg.sender, msg.value, amount);
       
        owner.transfer(msg.value);  
                              
    }

    function batchTransfer(address[] _receivers, uint256[] _amounts) public returns(bool) {
        uint256 cnt = _receivers.length;
        require(cnt > 0 && cnt <= 20);
        require(cnt == _amounts.length);

        cnt = (uint8)(cnt);

        uint256 totalAmount = 0;
        for (uint8 i = 0; i < cnt; i++) {
            totalAmount = totalAmount.add(_amounts[i]);
        }

        require(totalAmount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(totalAmount);
        for (i = 0; i < cnt; i++) {
            balances[_receivers[i]] = balances[_receivers[i]].add(_amounts[i]);            
            emit Transfer(msg.sender, _receivers[i], _amounts[i]);
        }

        return true;
    }


}