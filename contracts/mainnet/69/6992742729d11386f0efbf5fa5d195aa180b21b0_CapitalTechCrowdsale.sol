pragma solidity 0.4.24;
/*
Capital Technologies & Research - Capital (CALL) & CapitalGAS (CALLG) - Crowdsale Smart Contract
https://www.mycapitalco.in
*/

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
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    emit Transfer(msg.sender, _to, _value);
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

/**
 * @title CAPITAL GAS (CALLG) Token
 * @dev Token representing CALLG.
 */
contract CALLGToken is MintableToken {
	string public name = "CAPITAL GAS";
	string public symbol = "CALLG";
	uint8 public decimals = 18;
}

/**
 * @title CAPITAL (CALL) Token
 * @dev Token representing CALL.
 */
contract CALLToken is MintableToken {
	string public name = "CAPITAL";
	string public symbol = "CALL";
	uint8 public decimals = 18;
}

contract TeamVault is Ownable {
    using SafeMath for uint256;
    ERC20 public token_call;
    ERC20 public token_callg;
    event TeamWithdrawn(address indexed teamWallet, uint256 token_call, uint256 token_callg);
    constructor (ERC20 _token_call, ERC20 _token_callg) public {
        require(_token_call != address(0));
        require(_token_callg != address(0));
        token_call = _token_call;
        token_callg = _token_callg;
    }
    function () public payable {
    }
    function withdrawTeam(address teamWallet) public onlyOwner {
        require(teamWallet != address(0));
        uint call_balance = token_call.balanceOf(this);
        uint callg_balance = token_callg.balanceOf(this);
        token_call.transfer(teamWallet, call_balance);
        token_callg.transfer(teamWallet, callg_balance);
        emit TeamWithdrawn(teamWallet, call_balance, callg_balance);
    }
}

contract BountyVault is Ownable {
    using SafeMath for uint256;
    ERC20 public token_call;
    ERC20 public token_callg;
    event BountyWithdrawn(address indexed bountyWallet, uint256 token_call, uint256 token_callg);
    constructor (ERC20 _token_call, ERC20 _token_callg) public {
        require(_token_call != address(0));
        require(_token_callg != address(0));
        token_call = _token_call;
        token_callg = _token_callg;
    }
    function () public payable {
    }
    function withdrawBounty(address bountyWallet) public onlyOwner {
        require(bountyWallet != address(0));
        uint call_balance = token_call.balanceOf(this);
        uint callg_balance = token_callg.balanceOf(this);
        token_call.transfer(bountyWallet, call_balance);
        token_callg.transfer(bountyWallet, callg_balance);
        emit BountyWithdrawn(bountyWallet, call_balance, callg_balance);
    }
}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  /**
   * @param _wallet Vault address
   */
  constructor(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  /**
   * @param investor Investor address
   */
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    wallet.transfer(address(this).balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  /**
   * @param investor Investor address
   */
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}
contract FiatContract {
  function USD(uint _id) constant returns (uint256);
}
contract CapitalTechCrowdsale is Ownable {
  using SafeMath for uint256;
  ERC20 public token_call;
  ERC20 public token_callg;
  FiatContract public fiat_contract;
  RefundVault public vault;
  TeamVault public teamVault;
  BountyVault public bountyVault;
  enum stages { PRIVATE_SALE, PRE_SALE, MAIN_SALE_1, MAIN_SALE_2, MAIN_SALE_3, MAIN_SALE_4, FINALIZED }
  address public wallet;
  uint256 public maxContributionPerAddress;
  uint256 public stageStartTime;
  uint256 public weiRaised;
  uint256 public minInvestment;
  stages public stage;
  bool public is_finalized;
  bool public powered_up;
  bool public distributed_team;
  bool public distributed_bounty;
  mapping(address => uint256) public contributions;
  mapping(address => uint256) public userHistory;
  mapping(uint256 => uint256) public stages_duration;
  uint256 public callSoftCap;
  uint256 public callgSoftCap;
  uint256 public callDistributed;
  uint256 public callgDistributed;
  uint256 public constant decimals = 18;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount_call, uint256 amount_callg);
  event TokenTransfer(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount_call, uint256 amount_callg);
  event StageChanged(stages stage, stages next_stage, uint256 stageStartTime);
  event GoalReached(uint256 callSoftCap, uint256 callgSoftCap);
  event Finalized(uint256 callDistributed, uint256 callgDistributed);
  function () external payable {
    buyTokens(msg.sender);
  }
  constructor(address _wallet, address _fiatcontract, ERC20 _token_call, ERC20 _token_callg) public {
    require(_token_call != address(0));
    require(_token_callg != address(0));
    require(_wallet != address(0));
    require(_fiatcontract != address(0));
    token_call = _token_call;
    token_callg = _token_callg;
    wallet = _wallet;
    fiat_contract = FiatContract(_fiatcontract);
    vault = new RefundVault(_wallet);
    bountyVault = new BountyVault(_token_call, _token_callg);
    teamVault = new TeamVault(_token_call, _token_callg);
  }
  function powerUpContract() public onlyOwner {
    require(!powered_up);
    require(!is_finalized);
    stageStartTime = block.timestamp;
    stage = stages.PRIVATE_SALE;
    weiRaised = 0;
  	distributeTeam();
  	distributeBounty();
	  callDistributed = 7875000 * 10 ** decimals;
    callgDistributed = 1575000000 * 10 ** decimals;
    callSoftCap = 18049500 * 10 ** decimals;
    callgSoftCap = 3609900000 * 10 ** decimals;
    maxContributionPerAddress = 1500 ether;
    minInvestment = 0.01 ether;
    is_finalized = false;
    powered_up = true;
    stages_duration[uint256(stages.PRIVATE_SALE)] = 30 days;
    stages_duration[uint256(stages.PRE_SALE)] = 30 days;
    stages_duration[uint256(stages.MAIN_SALE_1)] = 7 days;
    stages_duration[uint256(stages.MAIN_SALE_2)] = 7 days;
    stages_duration[uint256(stages.MAIN_SALE_3)] = 7 days;
    stages_duration[uint256(stages.MAIN_SALE_4)] = 7 days;
  }
  function distributeTeam() public onlyOwner {
    require(!distributed_team);
    uint256 _amount = 5250000 * 10 ** decimals;
    distributed_team = true;
    MintableToken(token_call).mint(teamVault, _amount);
    MintableToken(token_callg).mint(teamVault, _amount.mul(200));
    emit TokenTransfer(msg.sender, teamVault, _amount, _amount, _amount.mul(200));
  }
  function distributeBounty() public onlyOwner {
    require(!distributed_bounty);
    uint256 _amount = 2625000 * 10 ** decimals;
    distributed_bounty = true;
    MintableToken(token_call).mint(bountyVault, _amount);
    MintableToken(token_callg).mint(bountyVault, _amount.mul(200));
    emit TokenTransfer(msg.sender, bountyVault, _amount, _amount, _amount.mul(200));
  }
  function withdrawBounty(address _beneficiary) public onlyOwner {
    require(distributed_bounty);
    bountyVault.withdrawBounty(_beneficiary);
  }
  function withdrawTeam(address _beneficiary) public onlyOwner {
    require(distributed_team);
    teamVault.withdrawTeam(_beneficiary);
  }
  function getUserContribution(address _beneficiary) public view returns (uint256) {
    return contributions[_beneficiary];
  }
  function getUserHistory(address _beneficiary) public view returns (uint256) {
    return userHistory[_beneficiary];
  }
  function getReferrals(address[] _beneficiaries) public view returns (address[], uint256[]) {
  	address[] memory addrs = new address[](_beneficiaries.length);
  	uint256[] memory funds = new uint256[](_beneficiaries.length);
  	for (uint256 i = 0; i < _beneficiaries.length; i++) {
  		addrs[i] = _beneficiaries[i];
  		funds[i] = getUserHistory(_beneficiaries[i]);
  	}
    return (addrs, funds);
  }
  function getAmountForCurrentStage(uint256 _amount) public view returns(uint256) {
    uint256 tokenPrice = fiat_contract.USD(0);
    if(stage == stages.PRIVATE_SALE) {
      tokenPrice = tokenPrice.mul(35).div(10 ** 8);
    } else if(stage == stages.PRE_SALE) {
      tokenPrice = tokenPrice.mul(50).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_1) {
      tokenPrice = tokenPrice.mul(70).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_2) {
      tokenPrice = tokenPrice.mul(80).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_3) {
      tokenPrice = tokenPrice.mul(90).div(10 ** 8);
    } else if(stage == stages.MAIN_SALE_4) {
      tokenPrice = tokenPrice.mul(100).div(10 ** 8);
    }
    return _amount.div(tokenPrice).mul(10 ** 10);
  }
  function _getNextStage() internal view returns (stages) {
    stages next_stage;
    if (stage == stages.PRIVATE_SALE) {
      next_stage = stages.PRE_SALE;
    } else if (stage == stages.PRE_SALE) {
      next_stage = stages.MAIN_SALE_1;
    } else if (stage == stages.MAIN_SALE_1) {
      next_stage = stages.MAIN_SALE_2;
    } else if (stage == stages.MAIN_SALE_2) {
      next_stage = stages.MAIN_SALE_3;
    } else if (stage == stages.MAIN_SALE_3) {
      next_stage = stages.MAIN_SALE_4;
    } else {
      next_stage = stages.FINALIZED;
    }
    return next_stage;
  }
  function getHardCap() public view returns (uint256, uint256) {
    uint256 hardcap_call;
    uint256 hardcap_callg;
    if (stage == stages.PRIVATE_SALE) {
      hardcap_call = 10842563;
      hardcap_callg = 2168512500;
    } else if (stage == stages.PRE_SALE) {
      hardcap_call = 18049500;
      hardcap_callg = 3609900000;
    } else if (stage == stages.MAIN_SALE_1) {
      hardcap_call = 30937200;
      hardcap_callg = 6187440000;
    } else if (stage == stages.MAIN_SALE_2) {
      hardcap_call = 40602975;
      hardcap_callg = 8120595000;
    } else if (stage == stages.MAIN_SALE_3) {
      hardcap_call = 47046825;
      hardcap_callg = 9409365000;
    } else {
      hardcap_call = 52500000;
      hardcap_callg = 10500000000;
    }
    return (hardcap_call.mul(10 ** decimals), hardcap_callg.mul(10 ** decimals));
  }
  function updateStage() public {
    _updateStage(0, 0);
  }
  function _updateStage(uint256 weiAmount, uint256 callAmount) internal {
    uint256 _duration = stages_duration[uint256(stage)];
    uint256 call_tokens = 0;
    if (weiAmount != 0) {
      call_tokens = getAmountForCurrentStage(weiAmount);
    } else {
      call_tokens = callAmount;
    }
    uint256 callg_tokens = call_tokens.mul(200);
    (uint256 _hardcapCall, uint256 _hardcapCallg) = getHardCap();
    if(stageStartTime.add(_duration) <= block.timestamp || callDistributed.add(call_tokens) >= _hardcapCall || callgDistributed.add(callg_tokens) >= _hardcapCallg) {
      stages next_stage = _getNextStage();
      emit StageChanged(stage, next_stage, stageStartTime);
      stage = next_stage;
      if (next_stage != stages.FINALIZED) {
        stageStartTime = block.timestamp;
      } else {
        finalization();
      }
    }
  }
  function buyTokens(address _beneficiary) public payable {
    require(!is_finalized);
    if (_beneficiary == address(0)) {
      _beneficiary = msg.sender;
    }
    (uint256 _hardcapCall, uint256 _hardcapCallg) = getHardCap();
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);
    require(_beneficiary != address(0));
    require(weiAmount >= minInvestment);
    require(contributions[_beneficiary].add(weiAmount) <= maxContributionPerAddress);
    _updateStage(weiAmount, 0);
    uint256 call_tokens = getAmountForCurrentStage(weiAmount);
    uint256 callg_tokens = call_tokens.mul(200);
    weiRaised = weiRaised.add(weiAmount);
    callDistributed = callDistributed.add(call_tokens);
    callgDistributed = callgDistributed.add(callg_tokens);
    MintableToken(token_call).mint(_beneficiary, call_tokens);
    MintableToken(token_callg).mint(_beneficiary, callg_tokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, call_tokens, callg_tokens);
    contributions[_beneficiary] = contributions[_beneficiary].add(weiAmount);
    userHistory[_beneficiary] = userHistory[_beneficiary].add(call_tokens);
    vault.deposit.value(msg.value)(msg.sender);
  }
  function finalize() onlyOwner public {
    stage = stages.FINALIZED;
    finalization();
  }
  function extendPeriod(uint256 date) public onlyOwner {
    stages_duration[uint256(stage)] = stages_duration[uint256(stage)].add(date);
  }
  function transferTokens(address _to, uint256 _amount) public onlyOwner {
    require(!is_finalized);
    require(_to != address(0));
    require(_amount > 0);
    _updateStage(0, _amount);
    callDistributed = callDistributed.add(_amount);
    callgDistributed = callgDistributed.add(_amount.mul(200));
    if (stage == stages.FINALIZED) {
      (uint256 _hardcapCall, uint256 _hardcapCallg) = getHardCap();
      require(callDistributed.add(callDistributed) <= _hardcapCall);
      require(callgDistributed.add(callgDistributed) <= _hardcapCallg);
    }
    MintableToken(token_call).mint(_to, _amount);
    MintableToken(token_callg).mint(_to, _amount.mul(200));
    userHistory[_to] = userHistory[_to].add(_amount);
    emit TokenTransfer(msg.sender, _to, _amount, _amount, _amount.mul(200));
  }
  function claimRefund() public {
	  address _beneficiary = msg.sender;
    require(is_finalized);
    require(!goalReached());
    userHistory[_beneficiary] = 0;
    vault.refund(_beneficiary);
  }
  function goalReached() public view returns (bool) {
    if (callDistributed >= callSoftCap && callgDistributed >= callgSoftCap) {
      return true;
    } else {
      return false;
    }
  }
  function finishMinting() public onlyOwner {
    MintableToken(token_call).finishMinting();
    MintableToken(token_callg).finishMinting();
  }
  function finalization() internal {
    require(!is_finalized);
    is_finalized = true;
    finishMinting();
    emit Finalized(callDistributed, callgDistributed);
    if (goalReached()) {
      emit GoalReached(callSoftCap, callgSoftCap);
      vault.close();
    } else {
      vault.enableRefunds();
    }
  }
}