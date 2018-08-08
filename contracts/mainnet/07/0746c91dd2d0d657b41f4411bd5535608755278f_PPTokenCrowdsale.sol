pragma solidity ^0.4.21;

//-----------------------------------------
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

    // SafeMath.sub will throw if there is not enough balance.
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
contract BurnableToken is MintableToken {

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
    emit Burn(burner, _value);
    emit Transfer(burner, address(0), _value);
  }
}

contract PPToken is BurnableToken{
    using SafeMath for uint256;
    
    string public constant name = "PayPortalToken";
    
    string public constant symbol = "PPTL";
    
    uint32 public constant decimals = 18;
    
    uint256 public freezTime;
    
    address internal saleAgent;
    
    
    function PPToken(uint256 initialSupply, uint256 _freezTime) public{
        require(initialSupply > 0 && now <= _freezTime);
        totalSupply_ = initialSupply * 10 ** uint256(decimals);
        balances[owner] = totalSupply_;
        emit Mint(owner, totalSupply_);
        emit Transfer(0x0, owner, totalSupply_);
        freezTime = _freezTime;
        saleAgent = owner;
    }

    modifier onlySaleAgent() {
        require(msg.sender == saleAgent);
        _;
    }
    
    function burnRemain() public onlySaleAgent {
        uint256 _remSupply = balances[owner];
        balances[owner] = 0;
        totalSupply_ = totalSupply_.sub(_remSupply);

        emit Burn(owner, _remSupply);
        emit Transfer(owner, address(0), _remSupply);
        
        mintingFinished = true;
        emit MintFinished();
    }
    
    function setSaleAgent(address _saleAgent) public onlyOwner{
        require(_saleAgent != address(0));
        saleAgent = _saleAgent;
    }
    
    function setFreezTime(uint256 _freezTime) public onlyOwner{
        require(_freezTime <= 1531699200);//16 july 2018
        freezTime = _freezTime;
    }
    
    function saleTokens(address _to, uint256 _value) public onlySaleAgent returns (bool){
        require(_to != address(0));
        require(_value <= balances[owner]);
    
        // SafeMath.sub will throw if there is not enough balance.
        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(owner, _to, _value);
        
        return true;
    }
    function hasPastFreezTime() public view returns(bool){
        return now >= freezTime;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(hasPastFreezTime());
        return super.transferFrom(_from, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(hasPastFreezTime());
        return super.transfer(_to, _value);
    }
}
//-----------------------------------------

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  PPToken public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, PPToken _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 totalTokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, totalTokens);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, totalTokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal
  {}
  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal
  {}

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal
  {}

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal returns (uint256)
  {
      uint256 tokens = _weiAmount.mul(rate);
      return tokens;
  }
  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}
contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;

  address public tokenWallet;

  /**
   * @dev Constructor, takes token wallet address. 
   * @param _tokenWallet Address holding the tokens, which has approved allowance to the crowdsale
   */
  function AllowanceCrowdsale(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

  /**
   * @dev Checks the amount of tokens left in the allowance.
   * @return Amount of tokens left in the allowance
   */
  function remainingTokens() public view returns (uint256) {
    return token.balanceOf(tokenWallet);
  }

  /**
   * @dev Overrides parent behavior by transferring tokens from wallet.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Amount of tokens purchased
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.saleTokens(_beneficiary, _tokenAmount);
  }
}
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;
  

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached. 
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    //require(!capReached());
    require(weiRaised.add(_weiAmount) <= cap);
  }

}
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range. 
   */
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }
  
  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal
  {
      
  }
}
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
  function RefundVault(address _wallet) public {
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
  function depositAdvisor(address _advWallet, uint256 _amount) onlyOwner public{
      require(state == State.Active);
      _advWallet.transfer(_amount);
  }
  function depositOf(address investor) public view returns(uint256){
      return deposited[investor];
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    wallet.transfer(this.balance);
    emit Closed();
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

contract StagebleCrowdsale is FinalizableCrowdsale{
    using SafeMath for uint256;
    
    mapping (uint256 => mapping (string => uint256)) internal stage;
    uint256 internal countStages;
    
    function StagebleCrowdsale() public {
        stage[0]["bonus"] = 30;
        stage[0]["cap"] = (rate * (6000 ether)); // rate * (6000 ether)
        stage[0]["tranmin"] = (1 ether);
        stage[0]["closeTime"] = 1529280000;//18.06.2018 - 1529280000
        
        stage[1]["bonus"] = 20;
        stage[1]["cap"] = (rate * (6000 ether)); // rate * (6000 ether)
        stage[1]["tranmin"] = (1 ether)/10;
        stage[1]["closeTime"] = 1529884800;//25.06.2018 - 1529884800
        
        stage[2]["bonus"] = 10;
        stage[2]["cap"] = (rate * (6000 ether));// rate * (6000 ether)
        stage[2]["tranmin"] = (1 ether)/10;
        stage[2]["closeTime"] = 1531094400;//09.07.2018 - 1531094400
        
        stage[3]["bonus"] = 0;
        stage[3]["cap"] = token.totalSupply();
        stage[3]["tranmin"] = 0;
        stage[3]["closeTime"] = closingTime;
        
        countStages = 4;
    }

    function getStageBonus(uint256 _index) public view returns(uint256){
        return stage[_index]["bonus"];
    }
    function getStageAvailableTokens(uint256 _index) public view returns(uint256){
        return stage[_index]["cap"];
    }
    function getStageMinWeiAmount(uint256 _index) public view returns(uint256){
        return stage[_index]["tranmin"];
    }
    function getStageClosingTime(uint256 _index) public view returns(uint256){
        return stage[_index]["closeTime"];
    }
    function getCurrentStageIndex() public view returns(uint256){
        return _getInStageIndex();
    }
    function getCountStages() public view returns(uint256){
        return countStages;
    }

    function _getBonus(uint256 _stageIndex, uint256 _leftcap) internal returns(uint256){
        uint256 bonuses = 0;
        if(_stageIndex < countStages)
        {
            if(stage[_stageIndex]["cap"] >= _leftcap)
            {
                if(stage[_stageIndex]["bonus"] > 0)
                {
                    bonuses = bonuses.add(_leftcap.mul(stage[_stageIndex]["bonus"]).div(100));
                }
                stage[_stageIndex]["cap"] = stage[_stageIndex]["cap"].sub(_leftcap);
            }
            else
            {
                _leftcap = _leftcap.sub(stage[_stageIndex]["cap"]);
                if(stage[_stageIndex]["cap"] > 0)
                {
                    if(stage[_stageIndex]["bonus"] > 0)
                    {
                        bonuses = bonuses.add(stage[_stageIndex]["cap"].mul(stage[_stageIndex]["bonus"]).div(100));
                    }
                    stage[_stageIndex]["cap"] = 0;
                }
                bonuses = bonuses.add(_getBonus(_stageIndex.add(1), _leftcap));
            }
        }
        return bonuses;
    }
    function _isInStage(uint256 _stageIndex) internal view returns (bool){
        return now < stage[_stageIndex]["closeTime"] && stage[_stageIndex]["cap"] > 0;
    }
    function _getInStageIndex () internal view returns(uint256){
        uint256 _index = 0;
        while(_index < countStages)
        {
            if(_isInStage(_index))
                return _index;
            _index = _index.add(1);
        }
        return countStages.sub(1);
    }
    
    function _getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
        uint256 tokens = super._getTokenAmount(_weiAmount);
        tokens = tokens.add(_getBonus(_getInStageIndex(), tokens));
        return tokens;
    }
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        uint256 _index = _getInStageIndex();
        if(stage[_index]["tranmin"] > 0)
            require(stage[_index]["tranmin"] <= _weiAmount);
    }

}

contract RefundableCrowdsale is StagebleCrowdsale {
  using SafeMath for uint256;

  // minimum amount of funds to be raised in weis
  uint256 public goal;

  // refund vault used to hold funds while crowdsale is running
  RefundVault public vault;
  
  address advWallet;
  uint256 advPercent;
  bool advIsCalc = false;

  /**
   * @dev Constructor, creates RefundVault. 
   * @param _goal Funding goal
   */
  function RefundableCrowdsale(uint256 _goal, uint256 _advPercent) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
    advPercent = _advPercent;
  }

  /**
   * @dev Investors can claim refunds here if crowdsale is unsuccessful
   */
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

  /**
   * @dev Checks whether funding goal was reached. 
   * @return Whether funding goal was reached
   */
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }

  /**
   * @dev vault finalization task, called when owner calls finalize()
   */
  function finalization() internal {
    if (goalReached()) {
        vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  /**
   * @dev Overrides Crowdsale fund forwarding, sending funds to vault.
   */
  function _forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
    if(!advIsCalc &&_getInStageIndex () > 0 && goalReached() && advWallet != address(0))
    {
        //Send ETH to advisor, after to stage 1
        uint256 advAmount = 0;
        advIsCalc = true;
        advAmount = weiRaised.mul(advPercent).div(100);
        vault.depositAdvisor(advWallet, advAmount);
    }
  }
  
  function onlyOwnerSetAdvWallet(address _advWallet) public onlyOwner{
      require(_advWallet != address(0));
      advWallet = _advWallet;
  }
  function onlyOwnerGetAdvWallet() onlyOwner public view returns(address){
          return advWallet;
    }

}



contract PPTokenCrowdsale is CappedCrowdsale, RefundableCrowdsale, AllowanceCrowdsale{
    using SafeMath for uint256;
    
    address bountyWallet;
    uint256 bountyPercent;
    
    address teamWallet;
    uint256 teamPercent;
    
    address companyWallet;
    uint256 companyPercent;
    
    function PPTokenCrowdsale( PPToken _token) public
        Crowdsale(500, msg.sender, _token)//(_rate, _wallet, _token)
        CappedCrowdsale((24000 ether))//(_cap)24000 ether
        TimedCrowdsale(1526860800, 1531699200)//(1526860800, 1531699200)
        RefundableCrowdsale((3000 ether), 5)//3000 ether, 5%
        AllowanceCrowdsale(msg.sender)
      {
        bountyPercent = 5;
        teamPercent = 15;
        companyPercent = 10;
      }
      
      
      function finalize() onlyOwner public {
          require(bountyWallet != address(0));
          require(teamWallet != address(0));
          require(companyWallet != address(0));
          super.finalize();
          uint256 _totalSupplyRem = token.totalSupply().sub(token.balanceOf(msg.sender));
          
          uint256 _bountyTokens = _totalSupplyRem.mul(bountyPercent).div(100);
          require(token.saleTokens(bountyWallet, _bountyTokens));
          
          uint256 _teamTokens = _totalSupplyRem.mul(teamPercent).div(100);
          require(token.saleTokens(teamWallet, _teamTokens));
          
          uint256 _companyTokens = _totalSupplyRem.mul(companyPercent).div(100);
          require(token.saleTokens(companyWallet, _companyTokens));
          
          token.burnRemain();
      }
      
      function onlyOwnerSetBountyWallet(address _wallet) onlyOwner public{
          bountyWallet = _wallet;
      }
      function onlyOwnerGetBountyWallet() onlyOwner public view returns(address){
          return bountyWallet;
      }
      function onlyOwnerSetTeamWallet(address _wallet) onlyOwner public{
          teamWallet = _wallet;
      }
      function onlyOwnerGetTeamWallet() onlyOwner public view returns(address){
          return teamWallet;
      }
      function onlyOwnerSetCompanyWallet(address _wallet) onlyOwner public{
          companyWallet = _wallet;
      }
      function onlyOwnerGetCompanyWallet() onlyOwner public view returns(address){
          return companyWallet;
      }
}