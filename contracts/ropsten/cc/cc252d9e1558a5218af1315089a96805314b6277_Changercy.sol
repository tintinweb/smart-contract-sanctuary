pragma solidity ^0.4.24;

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

contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
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

  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  function mint(address _to, uint256 _amount) hasMintPermission canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
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

contract CappedToken is MintableToken {
  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);
    return super.mint(_to, _amount);
  }
}

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

contract Changercy is CappedToken, PausableToken, BurnableToken {

  uint256 private constant TOKEN_CAP = 114 * 10**24;
  string public constant name = "Changercy";
  string public constant symbol = "XCY";
  uint8 public constant decimals = 18;

  constructor() public CappedToken(TOKEN_CAP) {
    paused = true;
  }
}

contract ChangercyCrowdsale is Ownable {
  using SafeMath for uint256;

  struct Phase {
    uint256 capTo;
    uint256 rate;
  }

  uint256 private constant TEAM_PERCENTAGE = 10;
  uint256 private constant PLATFORM_PERCENTAGE = 25;
  uint256 private constant CROWDSALE_PERCENTAGE = 65;

  uint256 private constant MIN_TOKENS_TO_PURCHASE = 6236 * 10**17;

  uint256 private constant ICO_TOKENS_CAP = 741 * 10**23;

  uint256 private constant FINAL_CLOSING_TIME = 1536339600;

  uint256 private constant INITIAL_START_DATE = 1530984600;

  uint256 public phase = 0;

  Changercy public token;

  address public wallet;
  address public platform;
  address public assigner;
  address public teamTokenHolder;

  uint256 public weiRaised;

  bool public isFinalized = false;

  uint256 public openingTime = 1530984600;
  uint256 public closingTime = 1531587600;
  uint256 public finalizedTime;

  mapping (uint256 => Phase) private phases;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenAssigned(address indexed purchaser, address indexed beneficiary, uint256 amount);


  event Finalized();

  modifier onlyAssginer() {
    require(msg.sender == assigner);
    _;
  }

  constructor(address _wallet, address _platform, address _assigner, Changercy _token) public {
      require(_wallet != address(0));
      require(_assigner != address(0));
      require(_platform != address(0));
      require(_token != address(0));

      wallet = _wallet;
      platform = _platform;
      assigner = _assigner;
      token = _token;

      // phases capTo means that totalSupply must reach it to change the phase
      phases[0] = Phase(171 * 10**22, 8107);
      phases[1] = Phase(114 * 10**23, 7795);
      phases[2] = Phase(1938 * 10**22, 7483);
      phases[3] = Phase(2736 * 10**22, 7171);
      phases[4] = Phase(3534 * 10**22, 6860);
      phases[5] = Phase(4332 * 10**22, 6673);
      phases[6] = Phase(5358 * 10**22, 6548);
      phases[7] = Phase(6384 * 10**22, 6423);
      phases[8] = Phase(741 * 10**23, 6236);
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
    If investment was made in bitcoins etc. owner can assign apropriate amount of
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

    Changercy _token = Changercy(token);

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

    emit Finalized();

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

    require(Changercy(token).mint(_beneficiary, _tokens));
    emit TokenAssigned(msg.sender, _beneficiary, _tokens);
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

    require(Changercy(token).mint(_beneficiary, _tokens));
    emit TokenPurchase(msg.sender, _beneficiary, _weiSpent, _tokens);

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

  ChangercyCrowdsale crowdsale;
  Changercy token;
  uint256 public collectedTokens;

  constructor(address _owner, address _crowdsale, address _token) public {
    owner = _owner;
    crowdsale = ChangercyCrowdsale(_crowdsale);
    token = Changercy(_token);
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

    emit TokensWithdrawn(owner, canExtract);
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
      _changercy.transfer(owner, balance);
      return;
    }

    Changercy _changercy = Changercy(_token);
    uint256 balance = _changercy.balanceOf(this);
    _changercy.transfer(owner, balance);
    emit ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event TokensWithdrawn(address indexed _holder, uint256 _amount);
}