pragma solidity 0.4.19;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }


  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}




/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }


  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}




/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    
  event Pause();
  event Unpause();

  bool public paused = true;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused
   * or when the owner is invoking the function.
   */
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }
  

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }


  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }
  

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}




/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
  

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




contract LMDA is PausableToken {
    
    string public  name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


    /**
     * Constructor initializes the name, symbol, decimals and total 
     * supply of the token. The owner of the contract which is initially 
     * the ICO contract will receive the entire total supply. 
     * */
    function LMDA() public {
        name = "LaMonedaCoin";
        symbol = "LMDA";
        decimals = 18;
        totalSupply = 500000000e18;
        
        balances[owner] = totalSupply;
        Transfer(address(this), owner, totalSupply);
    }
}




contract ICO is Ownable {
    
    using SafeMath for uint256;
    
    event AidropInvoked();
    event MainSaleActivated();
    event TokenPurchased(address recipient, uint256 tokens);
    event DeadlineExtended(uint256 daysExtended);
    event DeadlineShortened(uint256 daysShortenedBy);
    event OffChainPurchaseMade(address recipient, uint256 tokensBought);
    event TokenPriceChanged(string stage, uint256 newTokenPrice);
    event ExchangeRateChanged(string stage, uint256 newRate);
    event BonusChanged(string stage, uint256 newBonus);
    event TokensWithdrawn(address to, uint256 LMDA); 
    event TokensUnpaused();
    event ICOPaused(uint256 timeStamp);
    event ICOUnpaused(uint256 timeStamp);  
    
    address public receiverOne;
    address public receiverTwo;
    address public receiverThree;
    address public reserveAddress;
    address public teamAddress;
    
    uint256 public endTime;
    uint256 public tokenPriceForPreICO;
    uint256 public rateForPreICO;
    uint256 public tokenPriceForMainICO;
    uint256 public rateForMainICO;
    uint256 public tokenCapForPreICO;
    uint256 public tokenCapForMainICO;
    uint256 public bonusForPreICO;
    uint256 public bonusForMainICO;
    uint256 public tokensSold;
    uint256 public timePaused;
    bool public icoPaused;
    
    
    enum StateOfICO {
        PRE,
        MAIN
    }
    
    StateOfICO public stateOfICO;
    
    LMDA public lmda;

    mapping (address => uint256) public investmentOf;
    
    
    /**
     * Functions with this modifier can only be called when the ICO 
     * is not paused.
     * */
    modifier whenNotPaused {
        require(!icoPaused);
        _;
    }
    
    
    /**
     * Constructor functions creates a new instance of the LMDA token 
     * and automatically distributes tokens to the reserve and team 
     * addresses. The constructor also initializes all of the state 
     * variables of the ICO contract. 
     * */
    function ICO() public {
        lmda = new LMDA();
        receiverOne = 0x43adebFC525FEcf9b2E91a4931E4a003a1F0d959;   //Pre ICO
        receiverTwo = 0xB447292181296B8c7F421F1182be20640dc8Bb05;   //Pre ICO
        receiverThree = 0x3f68b06E7C0E87828647Dbba0b5beAef3822b7Db; //Main ICO
        reserveAddress = 0x7d05F660124B641b74b146E9aDA60D7D836dcCf5;
        teamAddress = 0xAD942E5085Af6a7A4C31f17ac687F8d5d7C0225C;
        lmda.transfer(reserveAddress, 90000000e18);
        lmda.transfer(teamAddress, 35500000e18);
        stateOfICO = StateOfICO.PRE;
        endTime = now.add(21 days);
        tokenPriceForPreICO = 0.00005 ether;
        rateForPreICO = 20000;
        tokenPriceForMainICO = 0.00007 ether;
        rateForMainICO = 14285; // should be 14,285.7143 
        tokenCapForPreICO = 144000000e18;
        tokenCapForMainICO = 374500000e18; 
        bonusForPreICO = 20;
        bonusForMainICO = 15;
        tokensSold = 0;
        icoPaused= false;
    }
    
    
    /**
     * This function allows the owner of the contract to airdrop LMDA tokens 
     * to a list of addresses, so long as a list of values is also provided.
     * 
     * @param _addrs The list of recipient addresses
     * @param _values The number of tokens each address will receive 
     * */
    function airdrop(address[] _addrs, uint256[] _values) public onlyOwner {
        require(lmda.balanceOf(address(this)) >= getSumOfValues(_values));
        require(_addrs.length <= 100 && _addrs.length == _values.length);
        for(uint i = 0; i < _addrs.length; i++) {
            lmda.transfer(_addrs[i], _values[i]);
        }
        AidropInvoked();
    }
    
    
    /**
     * Function is called internally by the airdrop() function to ensure that 
     * there are enough tokens remaining to execute the airdrop. 
     * 
     * @param _values The list of values representing the tokens to be sent
     * @return Returns the sum of all the values
     * */
    function getSumOfValues(uint256[] _values) internal pure returns(uint256 sum) {
        sum = 0;
        for(uint i = 0; i < _values.length; i++) {
            sum = sum.add(_values[i]);
        }
    }
    
    
    /**
     * Function allows the owner to activate the main sale.
     * */
    function activateMainSale() public onlyOwner whenNotPaused {
        require(now >= endTime || tokensSold >= tokenCapForPreICO);
        stateOfICO = StateOfICO.MAIN;
        endTime = now.add(49 days);
        MainSaleActivated();
    }


    /**
     * Fallback function invokes the buyToknes() method when ETH is recieved 
     * to enable the automatic distribution of tokens to investors.
     * */
    function() public payable {
        buyTokens(msg.sender);
    }
    
    
    /**
     * Allows investors to buy tokens for themselves or others by explicitly 
     * invoking the function using the ABI / JSON Interface of the contract.
     * 
     * @param _addr The address of the recipient
     * */
    function buyTokens(address _addr) public payable whenNotPaused {
        require(now <= endTime && _addr != 0x0);
        require(lmda.balanceOf(address(this)) > 0);
        if(stateOfICO == StateOfICO.PRE && tokensSold >= tokenCapForPreICO) {
            revert();
        } else if(stateOfICO == StateOfICO.MAIN && tokensSold >= tokenCapForMainICO) {
            revert();
        }
        uint256 toTransfer = msg.value.mul(getRate().mul(getBonus())).div(100).add(getRate());
        lmda.transfer(_addr, toTransfer);
        tokensSold = tokensSold.add(toTransfer);
        investmentOf[msg.sender] = investmentOf[msg.sender].add(msg.value);
        TokenPurchased(_addr, toTransfer);
        forwardFunds();
    }
    
    
    /**
     * Allows the owner to send tokens to investors who paid with other currencies.
     * 
     * @param _recipient The address of the receiver 
     * @param _value The total amount of tokens to be sent
     * */
    function processOffChainPurchase(address _recipient, uint256 _value) public onlyOwner {
        require(lmda.balanceOf(address(this)) >= _value);
        require(_value > 0 && _recipient != 0x0);
        lmda.transfer(_recipient, _value);
        tokensSold = tokensSold.add(_value);
        OffChainPurchaseMade(_recipient, _value);
    }
    
    
    /**
     * Function is called internally by the buyTokens() function in order to send 
     * ETH to owners of the ICO automatically. 
     * */
    function forwardFunds() internal {
        if(stateOfICO == StateOfICO.PRE) {
            receiverOne.transfer(msg.value.div(2));
            receiverTwo.transfer(msg.value.div(2));
        } else {
            receiverThree.transfer(msg.value);
        }
    }
    
    
    /**
     * Allows the owner to extend the deadline of the current ICO phase.
     * 
     * @param _daysToExtend The number of days to extend the deadline by.
     * */
    function extendDeadline(uint256 _daysToExtend) public onlyOwner {
        endTime = endTime.add(_daysToExtend.mul(1 days));
        DeadlineExtended(_daysToExtend);
    }
    
    
    /**
     * Allows the owner to shorten the deadline of the current ICO phase.
     * 
     * @param _daysToShortenBy The number of days to shorten the deadline by.
     * */
    function shortenDeadline(uint256 _daysToShortenBy) public onlyOwner {
        if(now.sub(_daysToShortenBy.mul(1 days)) < endTime) {
            endTime = now;
        }
        endTime = endTime.sub(_daysToShortenBy.mul(1 days));
        DeadlineShortened(_daysToShortenBy);
    }
    
    
    /**
     * Allows the owner to change the token price of the current phase. 
     * This function will automatically calculate the new exchange rate. 
     * 
     * @param _newTokenPrice The new price of the token.
     * */
    function changeTokenPrice(uint256 _newTokenPrice) public onlyOwner {
        require(_newTokenPrice > 0);
        if(stateOfICO == StateOfICO.PRE) {
            if(tokenPriceForPreICO == _newTokenPrice) { revert(); } 
            tokenPriceForPreICO = _newTokenPrice;
            rateForPreICO = uint256(1e18).div(tokenPriceForPreICO);
            TokenPriceChanged("Pre ICO", _newTokenPrice);
        } else {
            if(tokenPriceForMainICO == _newTokenPrice) { revert(); } 
            tokenPriceForMainICO = _newTokenPrice;
            rateForMainICO = uint256(1e18).div(tokenPriceForMainICO);
            TokenPriceChanged("Main ICO", _newTokenPrice);
        }
    }
    
    
    /**
     * Allows the owner to change the exchange rate of the current phase.
     * This function will automatically calculate the new token price. 
     * 
     * @param _newRate The new exchange rate.
     * */
    function changeRateOfToken(uint256 _newRate) public onlyOwner {
        require(_newRate > 0);
        if(stateOfICO == StateOfICO.PRE) {
            if(rateForPreICO == _newRate) { revert(); }
            rateForPreICO = _newRate;
            tokenPriceForPreICO = uint256(1e18).div(rateForPreICO);
            ExchangeRateChanged("Pre ICO", _newRate);
        } else {
            if(rateForMainICO == _newRate) { revert(); }
            rateForMainICO = _newRate;
            rateForMainICO = uint256(1e18).div(rateForMainICO);
            ExchangeRateChanged("Main ICO", _newRate);
        }
    }
    
    
    /**
     * Allows the owner to change the bonus of the current phase.
     * 
     * @param _newBonus The new bonus percentage.
     * */
    function changeBonus(uint256 _newBonus) public onlyOwner {
        if(stateOfICO == StateOfICO.PRE) {
            if(bonusForPreICO == _newBonus) { revert(); }
            bonusForPreICO = _newBonus;
            BonusChanged("Pre ICO", _newBonus);
        } else {
            if(bonusForMainICO == _newBonus) { revert(); }
            bonusForMainICO = _newBonus;
            BonusChanged("Main ICO", _newBonus);
        }
    }
    
    
    /**
     * Allows the owner to withdraw all unsold tokens to his wallet. 
     * */
    function withdrawUnsoldTokens() public onlyOwner {
        TokensWithdrawn(owner, lmda.balanceOf(address(this)));
        lmda.transfer(owner, lmda.balanceOf(address(this)));
    }
    
    
    /**
     * Allows the owner to unpause the LMDA token.
     * */
    function unpauseToken() public onlyOwner {
        TokensUnpaused();
        lmda.unpause();
    }
    
    
    /**
     * Allows the owner to claim back ownership of the LMDA token contract.
     * */
    function transferTokenOwnership() public onlyOwner {
        lmda.transferOwnership(owner);
    }
    
    
    /**
     * Allows the owner to pause the ICO.
     * */
    function pauseICO() public onlyOwner whenNotPaused {
        require(now < endTime);
        timePaused = now;
        icoPaused = true;
        ICOPaused(now);
    }
    
  
    /**
     * Allows the owner to unpause the ICO.
     * */
    function unpauseICO() public onlyOwner {
        endTime = endTime.add(now.sub(timePaused));
        timePaused = 0;
        ICOUnpaused(now);
    }
    
    
    /**
     * @return The total amount of tokens that have been sold.
     * */
    function getTokensSold() public view returns(uint256 _tokensSold) {
        _tokensSold = tokensSold;
    }
    
    
    /**
     * @return The current bonuse percentage.
     * */
    function getBonus() public view returns(uint256 _bonus) {
        if(stateOfICO == StateOfICO.PRE) { 
            _bonus = bonusForPreICO;
        } else {
            _bonus = bonusForMainICO;
        }
    }
    
    
    /**
     * @return The current exchange rate.
     * */
    function getRate() public view returns(uint256 _exchangeRate) {
        if(stateOfICO == StateOfICO.PRE) {
            _exchangeRate = rateForPreICO;
        } else {
            _exchangeRate = rateForMainICO;
        }
    }
    
    
    /**
     * @return The current token price. 
     * */
    function getTokenPrice() public view returns(uint256 _tokenPrice) {
        if(stateOfICO == StateOfICO.PRE) {
            _tokenPrice = tokenPriceForPreICO;
        } else {
            _tokenPrice = tokenPriceForMainICO;
        }
    }
}