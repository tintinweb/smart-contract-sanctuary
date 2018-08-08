pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
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
  function balanceOf(address _owner) public view returns (uint256 balance) {
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
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
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

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

/*
  HardcapToken is PausableToken and on the creation it is paused.
  It is made so because you don&#39;t want token to be transferable etc,
  while your ico is not over.
*/
contract HardcapToken is CappedToken, PausableToken, BurnableToken {

  uint256 private constant TOKEN_CAP = 100 * 10**24;

  string public constant name = "Welltrado token";
  string public constant symbol = "WTL";
  uint8 public constant decimals = 18;

  function HardcapToken() public CappedToken(TOKEN_CAP) {
    paused = true;
  }
}

contract HardcapCrowdsale is Ownable {
  using SafeMath for uint256;

  struct Phase {
    uint256 capTo;
    uint256 rate;
  }

  uint256 private constant TEAM_PERCENTAGE = 10;
  uint256 private constant PLATFORM_PERCENTAGE = 25;
  uint256 private constant CROWDSALE_PERCENTAGE = 65;

  uint256 private constant MIN_TOKENS_TO_PURCHASE = 100 * 10**18;

  uint256 private constant ICO_TOKENS_CAP = 65 * 10**24;

  uint256 private constant FINAL_CLOSING_TIME = 1529928000;

  uint256 private constant INITIAL_START_DATE = 1524484800;

  uint256 public phase = 0;

  HardcapToken public token;

  address public wallet;
  address public platform;
  address public assigner;
  address public teamTokenHolder;

  uint256 public weiRaised;

  bool public isFinalized = false;

  uint256 public openingTime = 1524484800;
  uint256 public closingTime = 1525089600;
  uint256 public finalizedTime;

  mapping (uint256 => Phase) private phases;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenAssigned(address indexed purchaser, address indexed beneficiary, uint256 amount);


  event Finalized();

  modifier onlyAssginer() {
    require(msg.sender == assigner);
    _;
  }

  function HardcapCrowdsale(address _wallet, address _platform, address _assigner, HardcapToken _token) public {
      require(_wallet != address(0));
      require(_assigner != address(0));
      require(_platform != address(0));
      require(_token != address(0));

      wallet = _wallet;
      platform = _platform;
      assigner = _assigner;
      token = _token;

      // phases capTo means that totalSupply must reach it to change the phase
      phases[0] = Phase(15 * 10**23, 1250);
      phases[1] = Phase(10 * 10**24, 1200);
      phases[2] = Phase(17 * 10**24, 1150);
      phases[3] = Phase(24 * 10**24, 1100);
      phases[4] = Phase(31 * 10**24, 1070);
      phases[5] = Phase(38 * 10**24, 1050);
      phases[6] = Phase(47 * 10**24, 1030);
      phases[7] = Phase(56 * 10**24, 1000);
      phases[8] = Phase(65 * 10**24, 1000);
  }

  function () external payable {
    buyTokens(msg.sender);
  }

  /*
    contract for teams tokens lockup
  */
  function setTeamTokenHolder(address _teamTokenHolder) onlyOwner public {
    require(_teamTokenHolder != address(0));
    // should allow set only once
    require(teamTokenHolder == address(0));
    teamTokenHolder = _teamTokenHolder;
  }

  function buyTokens(address _beneficiary) public payable {
    _processTokensPurchase(_beneficiary, msg.value);
  }

  /*
    It may be needed to assign tokens in batches if multiple clients invested
    in any other crypto currency.
    NOTE: this will fail if there are not enough tokens left for at least one investor.
        for this to work all investors must get all their tokens.
  */
  function assignTokensToMultipleInvestors(address[] _beneficiaries, uint256[] _tokensAmount) onlyAssginer public {
    require(_beneficiaries.length == _tokensAmount.length);
    for (uint i = 0; i < _tokensAmount.length; i++) {
      _processTokensAssgin(_beneficiaries[i], _tokensAmount[i]);
    }
  }

  /*
    If investmend was made in bitcoins etc. owner can assign apropriate amount of
    tokens to the investor.
  */
  function assignTokens(address _beneficiary, uint256 _tokensAmount) onlyAssginer public {
    _processTokensAssgin(_beneficiary, _tokensAmount);
  }

  function finalize() onlyOwner public {
    require(teamTokenHolder != address(0));
    require(!isFinalized);
    require(_hasClosed());
    require(finalizedTime == 0);

    HardcapToken _token = HardcapToken(token);

    // assign each counterparty their share
    uint256 _tokenCap = _token.totalSupply().mul(100).div(CROWDSALE_PERCENTAGE);
    require(_token.mint(teamTokenHolder, _tokenCap.mul(TEAM_PERCENTAGE).div(100)));
    require(_token.mint(platform, _tokenCap.mul(PLATFORM_PERCENTAGE).div(100)));

    // mint and burn all leftovers
    uint256 _tokensToBurn = _token.cap().sub(_token.totalSupply());
    require(_token.mint(address(this), _tokensToBurn));
    _token.burn(_tokensToBurn);

    require(_token.finishMinting());
    _token.transferOwnership(wallet);

    Finalized();

    finalizedTime = _getTime();
    isFinalized = true;
  }

  function _hasClosed() internal view returns (bool) {
    return _getTime() > FINAL_CLOSING_TIME || token.totalSupply() >= ICO_TOKENS_CAP;
  }

  function _processTokensAssgin(address _beneficiary, uint256 _tokenAmount) internal {
    _preValidateAssign(_beneficiary, _tokenAmount);

    // calculate token amount to be created
    uint256 _leftowers = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    bool _phaseChanged = false;
    Phase memory _phase = phases[phase];

    while (_tokenAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      // check if it is possible to assign more than there is available in this phase
      if (_leftowers < _tokenAmount) {
         _tokens = _tokens.add(_leftowers);
         _tokenAmount = _tokenAmount.sub(_leftowers);
         phase = phase + 1;
         _phaseChanged = true;
      } else {
         _tokens = _tokens.add(_tokenAmount);
         _tokenAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = phases[phase];
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE || _currentSupply == ICO_TOKENS_CAP);

    // if phase changes forward the date of the next phase change by 7 days
    if (_phaseChanged) {
      _changeClosingTime();
    }

    require(HardcapToken(token).mint(_beneficiary, _tokens));
    TokenAssigned(msg.sender, _beneficiary, _tokens);
  }

  function _processTokensPurchase(address _beneficiary, uint256 _weiAmount) internal {
    _preValidatePurchase(_beneficiary, _weiAmount);

    // calculate token amount to be created
    uint256 _leftowers = 0;
    uint256 _weiReq = 0;
    uint256 _weiSpent = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    bool _phaseChanged = false;
    Phase memory _phase = phases[phase];

    while (_weiAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      _weiReq = _leftowers.div(_phase.rate);
      // check if it is possible to purchase more than there is available in this phase
      if (_weiReq < _weiAmount) {
         _tokens = _tokens.add(_leftowers);
         _weiAmount = _weiAmount.sub(_weiReq);
         _weiSpent = _weiSpent.add(_weiReq);
         phase = phase + 1;
         _phaseChanged = true;
      } else {
         _tokens = _tokens.add(_weiAmount.mul(_phase.rate));
         _weiSpent = _weiSpent.add(_weiAmount);
         _weiAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = phases[phase];
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE || _currentSupply == ICO_TOKENS_CAP);

    // if phase changes forward the date of the next phase change by 7 days
    if (_phaseChanged) {
      _changeClosingTime();
    }

    // return leftovers to investor if tokens are over but he sent more ehters.
    if (msg.value > _weiSpent) {
      uint256 _overflowAmount = msg.value.sub(_weiSpent);
      _beneficiary.transfer(_overflowAmount);
    }

    weiRaised = weiRaised.add(_weiSpent);

    require(HardcapToken(token).mint(_beneficiary, _tokens));
    TokenPurchase(msg.sender, _beneficiary, _weiSpent, _tokens);

    // You can access this method either buying tokens or assigning tokens to
    // someone. In the previous case you won&#39;t be sending any ehter to contract
    // so no need to forward any funds to wallet.
    if (msg.value > 0) {
      wallet.transfer(_weiSpent);
    }
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // if the phase time ended calculate next phase end time and set new phase
    if (closingTime < _getTime() && closingTime < FINAL_CLOSING_TIME && phase < 8) {
      phase = phase.add(_calcPhasesPassed());
      _changeClosingTime();

    }
    require(_getTime() > INITIAL_START_DATE);
    require(_getTime() >= openingTime && _getTime() <= closingTime);
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(phase <= 8);

    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);
  }

  function _preValidateAssign(address _beneficiary, uint256 _tokenAmount) internal {
    // if the phase time ended calculate next phase end time and set new phase
    if (closingTime < _getTime() && closingTime < FINAL_CLOSING_TIME && phase < 8) {
      phase = phase.add(_calcPhasesPassed());
      _changeClosingTime();

    }
    // should not allow to assign tokens to team members
    require(_beneficiary != assigner);
    require(_beneficiary != platform);
    require(_beneficiary != wallet);
    require(_beneficiary != teamTokenHolder);

    require(_getTime() >= openingTime && _getTime() <= closingTime);
    require(_beneficiary != address(0));
    require(_tokenAmount > 0);
    require(phase <= 8);

    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);
  }

  function _changeClosingTime() internal {
    closingTime = _getTime() + 7 days;
    if (closingTime > FINAL_CLOSING_TIME) {
      closingTime = FINAL_CLOSING_TIME;
    }
  }

  function _calcPhasesPassed() internal view returns(uint256) {
    return  _getTime().sub(closingTime).div(7 days).add(1);
  }

 function _getTime() internal view returns (uint256) {
   return now;
 }

}

contract TeamTokenHolder is Ownable {
  using SafeMath for uint256;

  uint256 private LOCKUP_TIME = 24; // in months

  HardcapCrowdsale crowdsale;
  HardcapToken token;
  uint256 public collectedTokens;

  function TeamTokenHolder(address _owner, address _crowdsale, address _token) public {
    owner = _owner;
    crowdsale = HardcapCrowdsale(_crowdsale);
    token = HardcapToken(_token);
  }

  /*
    @notice The Dev (Owner) will call this method to extract the tokens
  */
  function collectTokens() public onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    uint256 total = collectedTokens.add(balance);

    uint256 finalizedTime = crowdsale.finalizedTime();

    require(finalizedTime > 0 && getTime() >= finalizedTime.add(months(3)));

    uint256 canExtract = total.mul(getTime().sub(finalizedTime)).div(months(LOCKUP_TIME));

    canExtract = canExtract.sub(collectedTokens);

    if (canExtract > balance) {
      canExtract = balance;
    }

    collectedTokens = collectedTokens.add(canExtract);
    assert(token.transfer(owner, canExtract));

    TokensWithdrawn(owner, canExtract);
  }

  function months(uint256 m) internal pure returns (uint256) {
      return m.mul(30 days);
  }

  function getTime() internal view returns (uint256) {
    return now;
  }

  /*
     Safety Methods
  */

  /*
     @notice This method can be used by the controller to extract mistakenly
     sent tokens to this contract.
     @param _token The address of the token contract that you want to recover
     set to 0 in case you want to extract ether.
  */
  function claimTokens(address _token) public onlyOwner {
    require(_token != address(token));
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    HardcapToken _hardcapToken = HardcapToken(_token);
    uint256 balance = _hardcapToken.balanceOf(this);
    _hardcapToken.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event TokensWithdrawn(address indexed _holder, uint256 _amount);
}