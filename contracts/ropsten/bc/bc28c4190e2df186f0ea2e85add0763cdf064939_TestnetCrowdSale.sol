pragma solidity ^0.4.18;

/**
* ------------------------------------------------------------------------------------------
* The following list of contracts was implemented by the OpenZeppelin team.
* https://github.com/OpenZeppelin/openzeppelin-solidity/tree/master/contracts
* 
* ERC20 - Standard coin based on Ether.
* 
* SafeMath - Library for secure mathematical operations.
* 
* StandardToken - Implementation of the ERC20 interface.
* 
* Ownable - Template for access only to the owner.
* 
* BurnableToken - Inherited from StandardToken. Coins can be "burned" by the account holder.
* 
* ------------------------------------------------------------------------------------------
* |                                                            |
* | r1: TrivaToken, TrivaCrowdSale is a custom implementation. |
* |                                                            |
* ------------------------------------------------------------------------------------------
*/



/**
* @title ERC20 interface
* @dev see https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 {
    function totalSupply() public view returns (uint256);
    
    function balanceOf(address _who) public view returns (uint256);
    
    function allowance(address _owner, address _spender) public view returns (uint256);
    
    function transfer(address _to, uint256 _value) public returns (bool);
    
    function approve(address _spender, uint256 _value) public returns (bool);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {
    
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }
        
        uint256 c = _a * _b;
        require(c / _a == _b);
        
        return c;
    }
    
    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
        
        return c;
    }
    
    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;
        
        return c;
    }
    
    /**
    * @dev Adds two numbers, reverts on overflow. 
    */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);
        
        return c;
    }
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;

  mapping (address => mapping (address => uint256)) public allowed;

  uint256 private totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != address(0));
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burn(address _account, uint256 _amount) internal {
    require(_account != address(0));
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
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
    * @notice Renouncing to ownership will leave the contract without an owner.
    * It will not be possible to call the functions with the `onlyOwner`
    * modifier anymore.
    */
    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipRenounced(owner);
    //     owner = address(0);
    // }
    
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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    _burnFrom(_from, _value);
  }

  /**
   * @dev Overrides StandardToken._burn in order for burn and burnFrom to emit
   * an additional Burn event.
   */
  function _burn(address _who, uint256 _value) internal {
    super._burn(_who, _value);
    emit Burn(_who, _value);
  }
}


contract TestnetToken is BurnableToken, Ownable {
    string public constant name = "Test Thirve 2";
    
    string public constant symbol = "TVA2";
    
    uint32 public constant decimals = 18;
    
    uint private totalCap = 1200000000 * 1 ether;
    
    constructor() public {
        // Send "totalCap" to the creator&#39;s address.
        _mint(msg.sender, totalCap);
    }
}


contract TestnetCrowdSale is Ownable {
    using SafeMath for uint;
    
    TestnetToken public Token; // `3VA` token.
    
    // Stages of the `Presale` and `ICO`.
    enum Stage {
        Pouse,
        Init,
        Running,
        Stoped
    }
    
    // Types of sale.
    enum Type {
        Presale,
        Ico
    }

    
    Stage public currentStage = Stage.Pouse; // Init the default value for the current stage.
    Type public currentType = Type.Presale; // Init the default value for the current type.
    
    // Setting a constant time for `Presale` and `ICO` in UTC format.
    uint public constant startPresaleTime = 1535427000; // 28.08.2018 09:30:00 GMT+06:00 - start time of Presale.
    uint public constant endPresaleTime = 1535430600;   // 28.08.2018 10:30:00 GMT+06:00 - end time of Presale.
    
    uint public constant startIcoTime = 1535432400;     // 28.08.2018 11:00:00 GMT+06:00 - start time of ICO.
    uint public constant endIcoTime = 1535436000;       // 28.08.2018 12:00:00 GMT+06:00 - end time of ICO.

    // 1,200,000,000 * 10^18
    // Total amount of `3VA` tokens, 
    // that will be emitted.
    uint public totalCap = 1200000000 * 1 ether;
    
    
    // We need sale 400 000 000  * 10^18 3VA to get hardcap.
    // 30% = 120,000,000 * 10^18 
    // + 50% bonus for the price, 
    // + maximim +80% of the bonus for the day of the week.
    // Total Presale cap
    uint public presaleCap = 324000000 * 1 ether;
    
    // 70% = 280,000,000 * 10^18 + maximum 55% of the bonus per volume.
    // Total ICO cap
    uint public icoCap = 434000000 * 1 ether;
    
    // 15% of sold tokens for Advisors.
    // The percentage of sold coins `3VA`,
    // which will be emitted for the `Advisors`.
    uint public constant advisorsPercentage = 15;
    
    // 5% of sold tokens for Bounty supporters.
    // The percentage of sold coins `3VA`,
    // which will be emitted for the `Bounty supporters`.
    uint public constant bountyPercentage = 5;
    
    
    // 15% of sold tokens for Founders.
    // The percentage of sold coins `3VA`,
    // which will be emitted for the `Founders`.
    uint public constant foundersPercentage = 15;
    
    uint public constant salePercantage = 65;
    
    // TODO: The cold wallet of the advisors,
    // for which the `3VA` funds will be transferred to the `Advisors`
    address public constant advisor = 0x53926a2CC9920CbE05A1Eb9B10dcC14E048c3995;
    
    // TODO: The cold wallet of the founders,
    // for which the `3VA` funds will be transferred to the `Bounty supporters`
    address public constant supporter = 0x4Cf06620f06CB9293f8912646214C38C5088aa54;
    
    // TODO: The cold wallet of the founders, 
    // for which the `3VA` funds will be transferred to the `Team`.
    address public constant founder = 0xae5A146E7303ec4f17a5eB07319903E6224A7b45;
    
    // TODO:
    // An address of the wallet 
    // to which the funds raised 
    // from crowdsale (ETH) will be transferred.
    address public constant coldWallet = 0x67d54A616bBF7b72046A710f71a83e25f580eA32;
    
    // 1 3VA = 0.00003 ETH
    // 1 ETH = 30,000 3VA on `Presale`.
    uint public constant PRESALE_PRICE = 30000;
    
    // 1 3VA = 0.00005 ETH
    // 1 ETH = 20,000 3VA on `ICO`.
    uint public constant ICO_PRICE = 20000;
    
    uint public totalSoldTokens = 0;    // The Number of `3VA` tokens sold at `Presale` and `ICO`.
    uint public totalSoldOnPresale = 0; // The number of `3VA` tokens sold at `Presale`.
    uint public totalSoldOnIco = 0;     // The number of `3VA` tokens sold at `ICO`.
    
    bool public isCoinSentToFounder = false; // `3VA` coins sent to the founders?
    
    // The amount of received `Ether`.
    uint public weiRaised = 0;
    
    uint public constant softcap =  150 ether; // The amount of ETH the crowdsale must receive to be considered successful.
    uint public constant hardcap = 20000 ether; // The maximum amount of ETH that the crowdsale can get.
    uint public constant presaleEtherCap = 6000 ether;
    
    bool public isHardCapCollected = false; // Is hardcap collected?
    bool public isCrowdsaleInitialized = false; // Is crowdsale initialized?
    bool public isWithdrawn = false; // Ether was withdrawn?
    
    // During the investment we will save the investor&#39;s 
    // address and how much he invested for the refund.
    mapping(address=>uint) public balances; 
    
    event HardcapReached(
        address indexed _where,
        uint256 hardcap,
        uint collected
    );
    
    constructor(TestnetToken _token) public {
        Token = _token;
    }
    
    
    /**
     * @dev Throws if isCrowdsaleInitialized == true.
    */
    modifier isCrowdsaleOff() {
        require(!isCrowdsaleInitialized);
        _;
    }
    
    /**
     * Throws if `Presale` end time longer than the current time.
    */
    modifier isPresaleFinished() {
        require(now > endPresaleTime);
        _;
    }
    
    /**
     * Throws if `ICO` end time longer than the current time. 
    */ 
    modifier isIcoFinished() {
        require(now > endIcoTime);
        _;
    }

    /**
     * Checks if the current time is in the gap between the `Presale` and the `ICO`.
    */
    modifier saleIsOn() {
        if (currentType == Type.Presale)
            require(
                now > startPresaleTime && 
                now < endPresaleTime && 
                address(this).balance <= presaleEtherCap
            );
            
        else if (currentType == Type.Ico)
            require(now > startIcoTime && now < endIcoTime);
        
        _;
    }
    
    /**
     * Checks whether the `hardcap` is collected.
    */
    modifier isUnderHadrCap() {
        require(address(this).balance <= hardcap);
        
        if (address(this).balance == hardcap && !isHardCapCollected) {
            isHardCapCollected = true;
            
            emit HardcapReached(
                address(this), 
                hardcap, 
                address(this).balance
            );
        }
        
        _;
    }
    
    // Check stages.
    modifier isPouse() {
        require(currentStage == Stage.Pouse);
        _;
    }
    
    modifier whenNotPouse() {
        require(currentStage != Stage.Pouse);
        _;
    }
    
    modifier isInit() {
        require(currentStage == Stage.Init);
        _;
    }
    
    modifier isRunning() {
        require(currentStage == Stage.Running);
        _;
    }
    
    modifier whenNotRunning() {
        require(currentStage != Stage.Running);
        _;
    }
    
    modifier isStoped() {
        require(
            currentStage == Stage.Stoped, 
            "isStoped: Before running `safeWithdrawal` function, make sure the you run the `finishCrowdsale` function."
        );
        
        _;
    }
    
    // Check types.
    modifier isPresale() {
        require(currentType == Type.Presale);
        _;
    }
    
    modifier isIco() {
        require(currentType == Type.Ico);
        _;
    }
    
    modifier whenNotWithdrawn() {
        require(!isWithdrawn);
        _;
    }
    
    /**
     * @dev Subtracts currentDate and startDate to find difference 
     * then divides difference to 1 weeks to find current week.
    */
    function getCurrentWeek(uint256 startDate, uint256 currentDate) internal pure returns (uint256) {
        uint256 diff = currentDate.sub( startDate );
        
        // Ex: The result can be {3.6, 3.1, 3.9} 
        // in solidtity it will be 3
        uint256 diffWeeks = diff.div( 1 weeks ); 
        
        // and we need to add 1 to get 4 days.
        return diffWeeks.add(1);
    }
    
    /**
     * @dev Calculation of bonus percentage per valume of ETH for `Presale` and `ICO`.
     * @param etherValue the amount of ETH received.
    */
    function getVolumeBonus(uint etherValue) private pure returns (uint) {
             if (etherValue >= 10000 ether) return 55;  // +55% tokens
        else if (etherValue >=  5000 ether) return 50;  // +50% tokens
        else if (etherValue >=  1000 ether) return 45;  // +45% tokens
        else if (etherValue >=   200 ether) return 40;  // +40% tokens
        else if (etherValue >=   100 ether) return 35;  // +35% tokens
        else if (etherValue >=    50 ether) return 30;  // +30% tokens
        else if (etherValue >=    30 ether) return 25;  // +25% tokens
        else if (etherValue >=    20 ether) return 20;  // +20% tokens
        else if (etherValue >=    10 ether) return 15;  // +15% tokens
        else if (etherValue >=     5 ether) return 10;  // +10% tokens
        else if (etherValue >=     1 ether) return 5;   // +5%  tokens
        
        return 0;
    }
    
    
    /**
     * @dev Calculation of bunus persentages per day for `Persale` or `ICO`.
     * @param fixedTime is the time in milliseconds from `block.timestamp` or  `now`.
     * fixedTime comes from a payable fallback function for fixing time.
    */
    function getWeekBonus(uint fixedTime) private view returns (uint) {
        // If the type of crowdsale is `Presale`.
        if (currentType == Type.Presale) {
            uint currentWeek = getCurrentWeek(startPresaleTime, fixedTime); 
            
                 if (currentWeek == 1)  return 80;  // +80% tokens
            else if (currentWeek == 2)  return 70;  // +70% tokens
            else if (currentWeek == 3)  return 60;  // +60% tokens
            else if (currentWeek == 4)  return 50;  // +50% tokens
            else if (currentWeek == 5)  return 40;  // +40% tokens
            else if (currentWeek == 6)  return 30;  // +30% tokens
            else if (currentWeek == 7)  return 20;  // +20% tokens
            else if (currentWeek == 8)  return 10;  // +10% tokens
            else if (currentWeek == 9)  return 1;   // +1%  tokens
        }
        
        // Default: No bonus.
        return 0;
    }
    
    // Initialize crowdsale.
    function initialize() public onlyOwner isCrowdsaleOff isPouse isPresale {
        require(
            founder != address(0), 
            "Address of the &#39;Founders&#39; is 0x0, please set the address of the &#39;founder&#39;."
        );
        
        require(
            advisor != address(0), 
            "Address of the &#39;Advisors&#39; is 0x0, please set the address of the &#39;advisors&#39;."
        );
        
        require(
            supporter != address(0), 
            "Address of the &#39;Bounty supporters&#39; is 0x0, please set the address of the &#39;supporter&#39;."
        );
        
        require(
            coldWallet != address(0),
            "&#39;coldWallet&#39; is 0x0, please set the address &#39;coldWallet&#39; to continue."
        );
        
        require(startPresaleTime < endPresaleTime, "startPresaleTime >= endPresaleTime");
        require(endPresaleTime <= startIcoTime, "endPresaleTime > startIcoTime");
        require(startIcoTime < endIcoTime, "startIcoTime >= endIcoTime");
        
        currentStage = Stage.Init;
        isCrowdsaleInitialized = true;
    }
    
    // Turn on `Presale`.
    function turnOnPresale() public onlyOwner isInit {
        currentStage = Stage.Running;
        currentType = Type.Presale;
    }
    
    // Turn on `ICO`.
    function turnOnIco() public onlyOwner isPresaleFinished {
        currentStage = Stage.Running;
        currentType = Type.Ico;
    }
    
    // ||
    function pouseCrowdsale() external onlyOwner isRunning whenNotPouse {
        currentStage = Stage.Pouse;
    }
    
    // |>
    function runCrowdsale() external onlyOwner isPouse whenNotRunning {
        currentStage = Stage.Running;
    }
    
    /**
     * @dev Calculation of bonus tokens.
     * @param _fixedTime is the time in milliseconds from `now` or `block.timestamp`.
     * @param _etherValue amount of ETH received.
     * @param tokensForSale how many tokens will be sold.
     * 
     * ex: To calculate 40% of bonus tokens we use this
     * formula: x = ( y * 40% ) / 100%
     * 
     * where `y` is how many tokens will be sold.
    */
    function getBonusTokens(uint _fixedTime, uint _etherValue, uint tokensForSale) private view returns (uint) {
        uint bonusPercentage = 0;
        
        if (currentType == Type.Presale)
            bonusPercentage = getWeekBonus(_fixedTime);
            
        else if (currentType == Type.Ico)
            bonusPercentage = getVolumeBonus(_etherValue);
        
        uint totalBonusToken = tokensForSale.mul(bonusPercentage).div(100);
        
        return totalBonusToken;
    }
    
    // Buy tokens.
    function buyTokens(uint _fixedTime) private {
        uint tokensForSale;
        
        // Calculation of tokens for sale.
        if (currentType == Type.Presale)
            tokensForSale = PRESALE_PRICE.mul(msg.value);
        
        else if (currentType == Type.Ico)
            tokensForSale = ICO_PRICE.mul(msg.value);
        
        // Getting bonus tokens.
        uint bonusTokens = getBonusTokens(_fixedTime, msg.value, tokensForSale);
        
        // Calculation of final tokens for sale with a bonus.
        uint totalTokensForSale = tokensForSale.add(bonusTokens);
        
        // Emit the tokens.
        Token.transfer(msg.sender, totalTokensForSale);
        
        // We keep the amount of investor&#39;s ETH for refund.
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        weiRaised = weiRaised.add(msg.value);
        
        // Increase `totalSoldOnPresale`
        if (currentType == Type.Presale)
            totalSoldOnPresale = totalSoldOnPresale.add(totalTokensForSale);
        
        // Increase `totalSoldOnIco`
        else if (currentType == Type.Ico)
            totalSoldOnIco = totalSoldOnIco.add(totalTokensForSale);
        
        // Increase `totalSoldTokens`
        totalSoldTokens = totalSoldTokens.add(totalTokensForSale);
    }
    
    // Safe withdrawal
    function safeWithdrawal() public onlyOwner isIcoFinished isStoped {
        require(
            address(this).balance > 0, 
            "safeWithdrawal: Balance is 0."
        );
        
        require(
            address(this).balance >= softcap,
            "safeWithdrawal: You can not withdrow `Ether`, because softcap is not compiled."
        );
        
        coldWallet.transfer(address(this).balance);
        isWithdrawn = true;
    } 
    
    // Refund if the softcap isn&#39;t compiled.
    function refund() public isIcoFinished whenNotWithdrawn {
        require(
            address(this).balance > 0, 
            "Refund: address(this).balance <= 0"
        );
        
        require(
            address(this).balance < softcap, 
            "Refund: You can not refund your `Ether`, because softcap is compiled."
        );
        
        require(
            balances[msg.sender] > 0, 
            "Refund: You don&#39;t have enough `ETH` to refund."
        );
        
        // Refund.
        uint balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.transfer(balance);
        
        weiRaised = weiRaised.sub(balance);
        
    }
    
    // Finish crowdsale.
    function finishCrowdsale() public onlyOwner isPresaleFinished isIcoFinished {
        // Stop selling.
        currentStage = Stage.Stoped;
        
        // Sending tokens for the {advisors, supporters, founders}.
        if (
            totalSoldTokens > 0 && 
            totalSoldTokens == totalSoldOnPresale.add(totalSoldOnIco)
        ) {
            
            // Calculating 100 % of tokens from `totalSoldTokens`;
            // formula: x = (totalSoldTokens * 100) / (salePercantage)
            totalSoldTokens = totalSoldTokens.mul(100).div(salePercantage);
            
            
            // Send tokens for Bounty advisors.
            uint tokensForAdvisorss = totalSoldTokens.mul(advisorsPercentage).div(100);
            Token.transfer(advisor, tokensForAdvisorss);
            
            // Send tokens for Bounty supporters.
            uint tokensForSupporters = totalSoldTokens.mul(bountyPercentage).div(100);
            Token.transfer(supporter, tokensForSupporters);
            
            // Send tokens for founders.
            uint tokensForFouders = totalSoldTokens.mul(foundersPercentage).div(100);
            Token.transfer(founder, tokensForFouders);
            isCoinSentToFounder = true;
            
            // Burning not sold tokens.
            Token.burn(Token.balanceOf(address(this)));
            
        }
    }
    
    // Fallback function. Receives the ether.
    function () external payable saleIsOn isRunning isUnderHadrCap {
        buyTokens(now);
    }
}