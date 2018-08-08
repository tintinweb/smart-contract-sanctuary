pragma solidity ^0.4.20;
 
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
  address public owner;
  

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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));      
    owner = newOwner;
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  address public saleAgent;
  address public partner;

  modifier onlyAdmin() {
    require(msg.sender == owner || msg.sender == saleAgent || msg.sender == partner);
    _;
  }

  function setSaleAgent(address newSaleAgent) onlyOwner public {
    require(newSaleAgent != address(0)); 
    saleAgent = newSaleAgent;
  }

  function setPartner(address newPartner) onlyOwner public {
    require(newPartner != address(0)); 
    partner = newPartner;
  }

  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic, Pausable {
    
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 public storageTime = 1522749600; // 04/03/2018 @ 10:00am (UTC)

  modifier checkStorageTime() {
    require(now >= storageTime);
    _;
  }

  modifier onlyPayloadSize(uint256 numwords) {
    assert(msg.data.length >= numwords * 32 + 4);
    _;
  }

  function setStorageTime(uint256 _time) public onlyOwner {
    storageTime = _time;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public
  onlyPayloadSize(2) whenNotPaused checkStorageTime returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */

  function transferFrom(address _from, address _to, uint256 _value) public 
  onlyPayloadSize(3) whenNotPaused checkStorageTime returns (bool) {
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
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public 
  onlyPayloadSize(2) whenNotPaused returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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
  function increaseApproval(address _spender, uint _addedValue) public 
  onlyPayloadSize(2)
  returns (bool) {
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
  function decreaseApproval(address _spender, uint _subtractedValue) public 
  onlyPayloadSize(2)
  returns (bool) {
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken{
    
  event Mint(address indexed to, uint256 amount);
  
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) public onlyAdmin whenNotPaused canMint returns  (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(this), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is MintableToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public onlyPayloadSize(1) {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }

  function burnFrom(address _from, uint256 _value) public 
  onlyPayloadSize(2)
  returns (bool success) {
    require(balances[_from] >= _value);// Check if the targeted balance is enough
    require(_value <= allowed[_from][msg.sender]);// Check allowance
    balances[_from] = balances[_from].sub(_value); // Subtract from the targeted balance
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); // Subtract from the sender&#39;s allowance
    totalSupply = totalSupply.sub(_value);
    Burn(_from, _value);
    return true;
    }
}

contract AlttexToken is BurnableToken {
    string public constant name = "Alttex";
    string public constant symbol = "ALTX";
    uint8 public constant decimals = 8;
}

contract Crowdsale is Ownable {
    
    using SafeMath for uint;
    uint256 public startTimeRound1;
    uint256 public endTimeRound1;

    uint256 public startTimeRound2;
    uint256 public endTimeRound2;

    // one token per one rate
    uint256 public rateRound1 = 1200;
    uint256 public rateRound2;

    uint256 constant dec = 10 ** 8;
    uint256 public supply = 50000000 * 10 ** 8;
    uint256 public percentTokensToSale = 60;
    uint256 public tokensToSale = supply.mul(percentTokensToSale).div(100);
    // address where funds are collected
    address public wallet;

    AlttexToken public token;
    // Amount of raised money in wei
    uint256 public weiRaised = 17472 * 10 ** 16; // 174.72 ETH
    uint256 public minTokensToSale = 45 * dec;
    // Company addresses
    address public TeamAndAdvisors;
    address public Investors;

    uint256 timeBonus1 = 20;
    uint256 timeBonus2 = 10;

    // Round bonuses
    uint256 bonus1 = 10;
    uint256 bonus2 = 15;
    uint256 bonus3 = 20;
    uint256 bonus4 = 30;

    // Amount bonuses
    uint256 amount1 = 500 * dec;
    uint256 amount2 = 1000 * dec;
    uint256 amount3 = 5000 * dec;
    uint256 amount4 = 10000 * dec;

    bool initalMinted = false;
    bool checkBonus = false;

    function Crowdsale(
        address _token,
        uint256 _startTimeRound1, // 1520121600 - 03/04/2018 @ 12:00am (UTC)
        uint256 _startTimeRound2, // 1521417600 - 03/19/2018 @ 12:00am (UTC)
        uint256 _endTimeRound1, // 1521417600 - 03/19/2018 @ 12:00am (UTC)
        uint256 _endTimeRound2, // 1525305600 - 05/03/2018 @ 12:00am (UTC)
        address _wallet,
        address _TeamAndAdvisors,
        address _Investors) public {
        require(_token != address(0));
        require(_endTimeRound1 > _startTimeRound1);
        require(_endTimeRound2 > _startTimeRound2);
        require(_wallet != address(0));
        require(_TeamAndAdvisors != address(0));
        require(_Investors != address(0));
        token = AlttexToken(_token);
        startTimeRound1 = _startTimeRound1;
        startTimeRound2 = _startTimeRound2;
        endTimeRound1 = _endTimeRound1;
        endTimeRound2 = _endTimeRound2;
        wallet = _wallet;
        TeamAndAdvisors = _TeamAndAdvisors;
        Investors = _Investors;
    }

    function initialMint() onlyOwner public {
        require(!initalMinted);
        uint256 _initialRaised = 17472 * 10 ** 16;
        uint256 _tokens = _initialRaised.mul(1500).div(10 ** 10);
        token.mint(Investors, _tokens.add(_tokens.mul(40).div(100)));
        initalMinted = true;
    }

    modifier saleIsOn() {
        uint tokenSupply = token.totalSupply();
        require(now > startTimeRound1 && now < endTimeRound2);
        require(tokenSupply <= tokensToSale);
        _;
    }

    function setPercentTokensToSale(
        uint256 _newPercentTokensToSale) onlyOwner public {
        percentTokensToSale = _newPercentTokensToSale;
    }

    function setMinTokensToSale(
        uint256 _newMinTokensToSale) onlyOwner public {
        minTokensToSale = _newMinTokensToSale;
    }

    function setCheckBonus(
        bool _newCheckBonus) onlyOwner public {
        checkBonus = _newCheckBonus;
    }

    function setAmount(
        uint256 _newAmount1,
        uint256 _newAmount2,
        uint256 _newAmount3,
        uint256 _newAmount4) onlyOwner public {
        amount1 = _newAmount1;
        amount2 = _newAmount2;
        amount3 = _newAmount3;
        amount4 = _newAmount4;
    }

    function setBonuses(
        uint256 _newBonus1,
        uint256 _newBonus2,
        uint256 _newBonus3,
        uint256 _newBonus4) onlyOwner public {
        bonus1 = _newBonus1;
        bonus2 = _newBonus2;
        bonus3 = _newBonus3;
        bonus4 = _newBonus4;
    }

    function setRoundTime(
      uint256 _newStartTimeRound2,
      uint256 _newEndTimeRound2) onlyOwner public {
      require(_newEndTimeRound2 > _newStartTimeRound2);
        startTimeRound2 = _newStartTimeRound2;
        endTimeRound2 = _newEndTimeRound2;
    }

    function setRate(uint256 _newRateRound2) public onlyOwner {
        rateRound2 = _newRateRound2;
    }

    function setTimeBonus(uint256 _newTimeBonus) public onlyOwner {
        timeBonus2 = _newTimeBonus;
    }
 
    function setTeamAddress(
        address _newTeamAndAdvisors,
        address _newInvestors,
        address _newWallet) onlyOwner public {
        require(_newTeamAndAdvisors != address(0));
        require(_newInvestors != address(0));
        require(_newWallet != address(0));
        TeamAndAdvisors = _newTeamAndAdvisors;
        Investors = _newInvestors;
        wallet = _newWallet;
    }


    function getAmount(uint256 _value) internal view returns (uint256) {
        uint256 amount = 0;
        uint256 all = 100;
        uint256 tokenSupply = token.totalSupply();
        if(now >= startTimeRound1 && now < endTimeRound1) { // Round 1
            amount = _value.mul(rateRound1);
            amount = amount.add(amount.mul(timeBonus1).div(all));
        } else if(now >= startTimeRound2 && now < endTimeRound2) { // Round 2
            amount = _value.mul(rateRound2);
            amount = amount.add(amount.mul(timeBonus2).div(all));
        } 
        require(amount >= minTokensToSale);
        require(amount != 0 && amount.add(tokenSupply) < tokensToSale);
        return amount;
    }

    function getBonus(uint256 _value) internal view returns (uint256) {
        if(_value >= amount1 && _value < amount2) { 
            return bonus1;
        } else if(_value >= amount2 && _value < amount3) {
            return bonus2;
        } else if(_value >= amount3 && _value < amount4) {
            return bonus3;
        } else if(_value >= amount4) {
            return bonus4;
        }
    }

    /**
    * events for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event TokenPartners(address indexed purchaser, address indexed beneficiary, uint256 amount);

    function buyTokens(address beneficiary) saleIsOn public payable {
        require(beneficiary != address(0));
        uint256 weiAmount = (msg.value).div(10 ** 10);

        // calculate token amount to be created
        uint256 tokens = getAmount(weiAmount);

        if(checkBonus) {
          uint256 bonusNow = getBonus(tokens);
          tokens = tokens.add(tokens.mul(bonusNow).div(100));
        }
        
        weiRaised = weiRaised.add(msg.value);
        token.mint(beneficiary, tokens);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        wallet.transfer(msg.value);

        uint256 taaTokens = tokens.mul(20).div(100);
        token.mint(TeamAndAdvisors, taaTokens);
        TokenPartners(msg.sender, TeamAndAdvisors, taaTokens);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // @return true if tokensale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTimeRound2;
    }

    function kill() onlyOwner public { selfdestruct(owner); }
    
}