pragma solidity ^0.4.18;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  mapping(address => uint256) balances;


  modifier onlyPayloadSize(uint size) {
      if (msg.data.length < size + 4) {
      revert();
      }
      _;
  }


  function transfer(address _to, uint256 _value) public onlyPayloadSize(2 * 32) returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /*
  */
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


/*
*/
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /*
   */
  function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
    require(_to != address(0));
    require(allowed[_from][msg.sender] >= _value);
    require(balances[_from] >= _value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /*
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /*
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  /*
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


/*
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /*
   */
  function Ownable() internal {
    owner = msg.sender;
  }


  /*
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /*
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/*
 */
contract Pausable is Ownable  {
    event Pause();
    event Unpause();
    event Freeze ();
    event LogFreeze();

    bool public paused = false;

    address public founder;
    
    /*
    */
    modifier whenNotPaused() {
        require(!paused || msg.sender == founder);
        _;
    }

    /*
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /*
    */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    

    /*
    */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused onlyPayloadSize(3 * 32) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  //The functions below surve no real purpose. Even if one were to approve another to spend
  //tokens on their behalf, those tokens will still only be transferable when the token contract
  //is not paused.

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract MintableToken is PausableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract TokenBank is MintableToken {

  string public name;
  string public symbol;
  uint8 public decimals;

  event TokensBurned(address initiatior, address indexed _partner, uint256 _tokens);
 

  /*
   */
    function TokenBank() public {
        name = "Token Bank";
        symbol = "TKB";
        decimals = 8;
        totalSupply = 1000000000e8;
        founder = 0xd606c83Bc9C740cBf39a42eB4c338828e90F451a;
        balances[founder] = totalSupply;
        emit Transfer(0x0, founder, totalSupply);
        pause();
    }

    modifier onlyFounder {
      require(msg.sender == founder);
      _;
    }

    event NewFounderAddress(address indexed from, address indexed to);

    function changeFounderAddress(address _newFounder) public onlyFounder {
        require(_newFounder != 0x0);
        emit NewFounderAddress(founder, _newFounder);
        founder = _newFounder;
    }

    /*
    */
    function burnTokens(address _partner, uint256 _tokens) public onlyFounder {
        require(balances[_partner] >= _tokens);
        balances[_partner] = balances[_partner].sub(_tokens);
        totalSupply = totalSupply.sub(_tokens);
        emit TokensBurned(msg.sender, _partner, _tokens);
    }
}


contract TokenBankICO is Ownable {

    using SafeMath for uint256;

    TokenBank public token;

    uint256 public TokenBankFirstStage;
    uint256 public TokenBankSecondStage;
    uint256 public TokenBankThirdStage;
    uint256 public TokenBankFourthStage;
	uint256 public TokenBankFifthStage;
    uint256 public TokenBankForSale;
    uint256 public startTime;
    uint256 public endTime;
    address public wallet;
    uint256 public rate;
    uint256 public weiRaised;
    bool public ICOpaused;

    uint256[4] public TokenBankBonusStage;

    uint256 public TokenBankSold;

    /*
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event ICOSaleExtended(uint256 newEndTime);

    function ICO() public {
        token = new TokenBank();  
        startTime = 1525478400; 
        rate = 400000;
        wallet = 0xd606c83Bc9C740cBf39a42eB4c338828e90F451a;
        TokenBankForSale = 500000000e8;
        TokenBankSold = 0;

        TokenBankFirstStage = 100000000e8;
        TokenBankSecondStage = 200000000e8;  
        TokenBankThirdStage = 300000000e8;  
        TokenBankFourthStage = 400000000e8;
		TokenBankFifthStage = 500000000e8;		
    
        TokenBankBonusStage[0] = now.add(5 days);
        for (uint y = 1; y < TokenBankBonusStage.length; y++) {
            TokenBankBonusStage[y] = TokenBankBonusStage[y - 1].add(5 days);
        }
        
        endTime = TokenBankBonusStage[3];
        
        ICOpaused = false;
    }
    
    modifier whenNotPaused {
        require(!ICOpaused);
        _;
    }

    function() external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _addr) public payable whenNotPaused {
        require(validPurchase() && TokenBankSold < TokenBankForSale);
        require(_addr != 0x0 && msg.value >= 100 finney);  
        uint256 toMint;
        toMint = msg.value.mul(getRateWithBonus());
        TokenBankSold = TokenBankSold.add(toMint);
        token.mint(_addr, toMint);
        forwardFunds();
    }

    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function processOfflinePurchase(address _to, uint256 _toMint) public onlyOwner {
        require(TokenBankSold.add(_toMint) <= TokenBankForSale);
        require(_toMint > 0 && _to != 0x0);
        TokenBankSold = TokenBankSold.add(_toMint);
        token.mint(_to, _toMint);
    }
    
    
    /*
     */
    function airDrop(address[] _addrs, uint256[] _values) public onlyOwner {
        //require(_addrs.length > 0);
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0 && _values[i] > 0) {
                token.mint(_addrs[i], _values[i]);
            }
        }
    }


    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime; 
        bool nonZeroPurchase = msg.value != 0; 
        return withinPeriod && nonZeroPurchase;
    }

    
    function finishMinting() public onlyOwner {
        token.finishMinting();
    }
    
    function getRateWithBonus() internal view returns (uint256 rateWithDiscount) {
        if (TokenBankSold < TokenBankForSale) {
            return rate.mul(getCurrentBonus()).div(100).add(rate);
            return rateWithDiscount;
        }
        return rate;
    }

    /*
    */
    function getCurrentBonus() internal view returns (uint256 discount) {
        require(TokenBankSold < TokenBankFifthStage);
        uint256 timeStamp = now;
        uint256 stage;

        for (uint i = 0; i < TokenBankBonusStage.length; i++) {
            if (timeStamp <= TokenBankBonusStage[i]) {
                stage = i + 1;
                break;
            } 
        } 

        if(stage == 1 && TokenBankSold < TokenBankFirstStage) { discount = 20; }
        if(stage == 1 && TokenBankSold >= TokenBankSecondStage) { discount = 15; }
        if(stage == 1 && TokenBankSold >= TokenBankThirdStage) { discount = 10; }
        if(stage == 1 && TokenBankSold >= TokenBankFourthStage) { discount = 5; }
		if(stage == 1 && TokenBankSold >= TokenBankFifthStage) { discount = 0; }
		
        if(stage == 2 && TokenBankSold < TokenBankSecondStage) { discount = 15; }
        if(stage == 2 && TokenBankSold >= TokenBankThirdStage) { discount = 10; }
        if(stage == 2 && TokenBankSold >= TokenBankFourthStage) { discount = 5; }
		if(stage == 2 && TokenBankSold >= TokenBankFifthStage) { discount = 0; }

        if(stage == 3 && TokenBankSold < TokenBankThirdStage) { discount = 10; }
        if(stage == 3 && TokenBankSold >= TokenBankFourthStage) { discount = 5; }
		if(stage == 3 && TokenBankSold >= TokenBankFifthStage) { discount = 0; }
		
		if(stage == 4 && TokenBankSold < TokenBankFourthStage) { discount = 5; }
        if(stage == 4 && TokenBankSold >= TokenBankFifthStage) { discount = 0; }

        if(stage == 5) { discount = 0; }

        return discount;
    }



    function extendDuration(uint256 _newEndTime) public onlyOwner {
        require(endTime < _newEndTime);
        endTime = _newEndTime;
        emit ICOSaleExtended(_newEndTime);
    }


    function hasEnded() public view returns (bool) { 
        return now > endTime;
    }

    /**
    * Allows the owner of the ICO contract to unpause the token contract. This function is needed
    * because the ICO contract deploys a new instance of the token contract, and by default the 
    * ETH address which deploys a contract which is Ownable is assigned ownership of the contract,
    * so the ICO contract is the owner of the token contract. Since unpause is a function which can
    * only be executed by the owner, by adding this function here, then the owner of the ICO contract
    * can call this and then the ICO contract will invoke the unpause function of the token contract
    * and thus the token contract will successfully unpause as its owner the ICO contract invokend
    * the the function. 
    */
    function unpauseToken() public onlyOwner {
        token.unpause();
    }
    
    function pauseUnpauseICO() public onlyOwner {
        if (ICOpaused) {
            ICOpaused = false;
        } else {
            ICOpaused = true;
        }
    }
}