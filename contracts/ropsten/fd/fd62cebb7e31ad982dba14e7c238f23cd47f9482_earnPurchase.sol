pragma solidity ^0.4.2;

library SafeMath {
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
    
  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract Token is Ownable {
  uint256 public totalSupply;
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  
  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  function transfer(address _to, uint256 _value) public returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  
}

 contract EthereumAutoReturnNeighbours is Token {
    
    string public constant name = "Ethereum Auto Return from Neighbours";
    string public constant symbol = "EARN";
    uint32 public constant decimals = 18;
    
}

contract earnPurchase is Ownable {
    using SafeMath for uint256;

    EthereumAutoReturnNeighbours public token = new EthereumAutoReturnNeighbours();
  
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    
    address ownerCoinWallet;
    
    address ethWallet;
    
    uint256 public rate;
    
    uint public allWeiRaised;
    uint public countReferers;
    uint public countReferrals;
    uint public countMembers;
	
	struct dateReferals {
		uint date;
		address referral;
	}
	
	struct memberResults {
		uint spentETH;
        uint earnedETH;
        uint earnedEARN;
        uint countRef;
    }
    
    mapping (address => memberResults) public membersResults;
    mapping (address => dateReferals[]) public membersReferrals;
    
    uint public coinPercent;
    uint public ethPercent;
	
	mapping (address => address[]) referrals;
    mapping (address => address) referer;
    mapping (address => uint) turnover;
    
    address public lastBuyer;
	
	uint public tokenMint;
    
    constructor() public {
        coinPercent = 50;
        ethPercent = 50;
        allWeiRaised = 0;
        countReferers = 0;
        countReferrals = 0;
        countMembers = 0;
        ownerCoinWallet = 0x8CfB902A0CEc76b56465f30F3D2C48a87f990819;
        ethWallet = 0x4350a60F397F56421f0c584B595C67F44D79f394;
        tokenMint = 1000000 * 1 ether;
        token.mint(ownerCoinWallet, tokenMint);
        
        rate = 1000 * 1 ether;
    }
    
    modifier noReferer() {
        require(getReferer(msg.sender) == address(0)); _;
    }
    
    function setRate(uint256 _rate) public onlyOwner {
        if (_rate <= 0) return;
        if (_rate <= rate) return;
        rate=_rate;
    }
    
    function setCoinPercent(uint256 _coinPercent) public onlyOwner {
        if (_coinPercent < 10) return;
        coinPercent = _coinPercent;
    }
    
    function setEthPercent(uint256 _ethPercent) public onlyOwner {
        if (_ethPercent < 25) return;
        ethPercent = _ethPercent;
    }
    
    function () external payable {
		if(msg.data.length == 20) {
			address _referer = bytesToAddress(bytes(msg.data));
			if(_referer == msg.sender) {_referer = address(0);}
		} else {
			_referer = address(0);
		}
        buyTokens(msg.sender, _referer);
    }
    
    function getTurnover(address _sender) public constant returns (uint256) {
        return turnover[_sender];
    }
    
    function setTurnover(uint _sumToTurnover) private {
        require(_sumToTurnover != 0);
        turnover[msg.sender] = turnover[msg.sender].add(_sumToTurnover.div(1 ether));
    }
    
    function setTurnoverTo(address _referer, uint _sumToTurnover) private {
        require(_sumToTurnover != 0);
        turnover[_referer] = turnover[_referer].add(_sumToTurnover.div(1 ether));
    }
    
    function getReferer(address _referral) public constant returns (address) {
        return referer[_referral];
    }
    
    function setReferer(address _referer) private noReferer {
        referer[msg.sender] = _referer;
		if (referrals[_referer].length == 1) {
			countReferers = countReferers.add(1);
		}
    }
    
    function setReferral(address _referer) private noReferer {
        require(_referer != msg.sender);
        referrals[_referer].push(msg.sender);
        setReferer(_referer);
        membersResults[_referer].countRef = membersResults[_referer].countRef.add(1);
        membersReferrals[_referer].push(dateReferals(now,msg.sender));
		countReferrals = countReferrals.add(1);
    }
    
    function getReferrals(address _referer) public constant returns (address[]) {
        return referrals[_referer];
    }
	
	function getLastBuyer() public constant returns (address) {
        return lastBuyer;
    }
    
    function setLastBuyer(address _lastBuyer) private {
        lastBuyer = _lastBuyer;
    }
    
    function buyTokens(address beneficiary, address _referer) public payable {
        require(beneficiary != address(0));
        require(validPurchase());
    
        uint256 weiAmount = msg.value;
		if (isMember(beneficiary)) {
			membersResults[beneficiary].spentETH = membersResults[beneficiary].spentETH.add(weiAmount);
		} else {
		    countMembers = countMembers.add(1);
		    membersResults[beneficiary] = memberResults(weiAmount,0,0,0);
		}
        
        uint256 _tokens = getTokenAmount(weiAmount);
        
        allWeiRaised = allWeiRaised.add(weiAmount);
        setTurnover(_tokens);
        
        token.mint(msg.sender, _tokens);
        
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, _tokens);
        
        forwardFunds(_referer);
        
        address firstReferer = getReferer(msg.sender);
        if (firstReferer != address(0)) {
            uint percentCoinToReferer = weiAmount.mul(coinPercent).div(100);
            token.mint(firstReferer, percentCoinToReferer);
            membersResults[firstReferer].earnedEARN = membersResults[firstReferer].earnedEARN.add(percentCoinToReferer);
            setTurnoverTo(firstReferer, percentCoinToReferer);
        }
    
        setLastBuyer(msg.sender);
		countMembers = countMembers.add(1);
    }
    
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return rate.mul(weiAmount).div(1 ether);
    }
    
    function bytesToAddress(bytes source) internal pure returns(address) {
        uint result;
        uint mul = 1;
        for(uint i = 20; i > 0; i--) {
            result += uint8(source[i-1])*mul;
            mul = mul*256;
        }
        return address(result);
    }
    
    function forwardFunds(address _referer) internal {
        uint256 weiAmount = msg.value;
        uint256 ownerWeiAmount = msg.value;
        
        address _lastBuyer = getLastBuyer();
        if (getReferer(msg.sender) == address(0)) {
            if(_referer != address(0)) {
                if (getTurnover(_referer) > membersResults[_referer].countRef) {
                    setReferral(_referer);
                } else {
                    if (_lastBuyer != address(0)) {
                        if (getTurnover(_lastBuyer) > membersResults[_lastBuyer].countRef) {
                            setReferral(_lastBuyer);
                        }
                    }
                }
            } else {
                if (_lastBuyer != address(0)) {
                    if (getTurnover(_lastBuyer) > membersResults[_lastBuyer].countRef) {
                        setReferral(_lastBuyer);
                    }
                }
            }
        }
        
        address curReferer = getReferer(msg.sender);
        if (curReferer != address(0)) {
            uint refWeiAmount = weiAmount.mul(ethPercent).div(100);
            ownerWeiAmount = ownerWeiAmount.sub(refWeiAmount);
            curReferer.transfer(refWeiAmount);
            membersResults[curReferer].earnedETH = membersResults[curReferer].earnedETH.add(refWeiAmount);
        }
        
        ethWallet.transfer(ownerWeiAmount);
    }
    
    function validPurchase() internal view returns (bool) {
        bool nonZeroPurchase = msg.value != 0;
        return nonZeroPurchase;
    }
	
	function isMember(address _address) public returns (bool) {
	    return membersResults[_address].spentETH > 0;
	}
}