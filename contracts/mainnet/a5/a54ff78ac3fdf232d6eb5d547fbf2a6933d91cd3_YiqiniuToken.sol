pragma solidity ^0.4.18;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);  _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

library SafeMath {
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

contract ERC20Basic {
  uint256 public totalSupply;
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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;

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

contract TokenTimelock {
  using SafeERC20 for ERC20Basic;
  ERC20Basic public token;
  address public beneficiary;
  uint256 public releaseTime;

  constructor(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    require(_releaseTime > now);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract YiqiniuToken is MintableToken {
    string public constant name		= &#39;Yiqiniu&#39;;
    string public constant symbol	= &#39;KEY&#39;;
    uint256 public constant decimals	= 18;
    event Burned(address indexed burner, uint256 value);
    
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burned(burner, _value);
    }
}

contract CrowdsaleConfig {
    uint256 public constant TOKEN_DECIMALS	    = 18;
    uint256 public constant MIN_TOKEN_UNIT	    = 10 ** uint256(TOKEN_DECIMALS);
    uint256 public constant TOTAL_SUPPLY_CAP        = 100000000 * MIN_TOKEN_UNIT;
    uint256 public constant PUBLIC_SALE_TOKEN_CAP   = TOTAL_SUPPLY_CAP / 100 * 30;
    uint256 public constant AGENCY_TOKEN_CAP        = TOTAL_SUPPLY_CAP / 100 * 20;
    uint256 public constant TEAM_TOKEN_CAP          = TOTAL_SUPPLY_CAP / 100 * 50;
    address public constant TEAM_ADDR		    = 0xd589737E4CbeC49E862D3A54c75aF16e27dD8fC1;
    address public constant AGENCY_ADDR	            = 0xc849e7225fF088e187136A670662e36adE5A89FC;
    address public constant WALLET_ADDR	            = 0xd589737E4CbeC49E862D3A54c75aF16e27dD8fC1;
}

contract YiqiniuCrowdsale is Ownable, CrowdsaleConfig{
    using SafeMath for uint256;
    using SafeERC20 for YiqiniuToken;

    // Token contract
    YiqiniuToken public token;

    uint64 public startTime;
    uint64 public endTime;
    uint256 public rate = 10000;
    uint256 public goalSale;
    uint256 public totalPurchased = 0;
    bool public CrowdsaleEnabled = false;
    mapping(address => bool) public isVerified;
    mapping(address => uint256) public tokensPurchased;
    uint256 public maxTokenPurchase = 100000 * MIN_TOKEN_UNIT;
    uint256 public minTokenPurchase = 1 * MIN_TOKEN_UNIT;
    TokenTimelock public AgencyLock1;
    TokenTimelock public AgencyLock2;
    
    event NewYiqiniuToken(address _add);

    constructor() public {
        startTime = uint64(now);
        endTime = uint64(now + 3600*24*4);
        goalSale = PUBLIC_SALE_TOKEN_CAP / 100 * 50;
        
        token = new YiqiniuToken();
        emit NewYiqiniuToken(address(token));
        
        token.mint(address(this), TOTAL_SUPPLY_CAP);
        token.finishMinting();

        uint64 TimeLock1 = uint64(now + 3600*24*5);
        uint64 TimeLock2 = uint64(now + 3600*24*6);

        AgencyLock1 = new TokenTimelock(token, AGENCY_ADDR, TimeLock1);
        AgencyLock2 = new TokenTimelock(token, AGENCY_ADDR, TimeLock2);

        token.safeTransfer(AgencyLock1, AGENCY_TOKEN_CAP/2);
        token.safeTransfer(AgencyLock2, AGENCY_TOKEN_CAP/2);

        token.safeTransfer(TEAM_ADDR,TEAM_TOKEN_CAP);
    }

    function releaseLockAgencyLock1() public {
        AgencyLock1.release();
    }
    function releaseLockAgencyLock2() public {
        AgencyLock2.release();
    }

    function () external payable {   
        buyTokens(msg.sender);
    }
    
    modifier canCrowdsale() {
        require(CrowdsaleEnabled);
        _;
    }
    
    function enableCrowdsale() public onlyOwner {
        CrowdsaleEnabled = true;
    }
    
    function closeCrowdsale() public onlyOwner {
        CrowdsaleEnabled = false;
    }
    
    function buyTokens(address participant) internal canCrowdsale {
        require(now >= startTime);
        require(now < endTime);
        require(msg.value != 0);
        require(isVerified[participant]);
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(rate);
        
        tokensPurchased[participant] = tokensPurchased[participant].add(tokens);
        require(tokensPurchased[participant] >= minTokenPurchase);
        require(tokensPurchased[participant] <= maxTokenPurchase);
        
        totalPurchased = totalPurchased.add(tokens);
        token.safeTransfer(participant, tokens);
    }
    
    function setTokenPrice(uint256 _tokenRate) public onlyOwner {
        require(now > startTime);
        require(_tokenRate > 0);
        rate = _tokenRate;
    }
    
    function setLimitTokenPurchase(uint256 _minToken, uint256 _maxToken) public onlyOwner {
        require(goalSale >= maxTokenPurchase);
        minTokenPurchase = _minToken;
        maxTokenPurchase = _maxToken;
    }

    function addVerified (address[] _ads) public onlyOwner {
        for(uint i = 0; i < _ads.length; i++){
            isVerified[_ads[i]] = true;
        }
    }

    function removeVerified (address _address) public onlyOwner {
        isVerified[_address] = false;
    }
    
    function close() onlyOwner public {
        require(now >= endTime || totalPurchased >= goalSale);
        token.burn(token.balanceOf(this));
        WALLET_ADDR.transfer(address(this).balance);
   }
}