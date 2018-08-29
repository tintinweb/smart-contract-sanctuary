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


contract TrivaToken is BurnableToken {
    string public constant name = "Triva";
    
    string public constant symbol = "TRA";
    
    uint32 public constant decimals = 18;
    
    
    constructor(uint _totalCap) public {
        // Mint totalCap to Crowdsale (address(this)).
        _mint(msg.sender, _totalCap);
    }
}


contract TrivaCrowdSale is Ownable {
    using SafeMath for uint;
    
    TrivaToken public Token; // `TRA` token.
    
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
    
    uint public constant startPresaleTime = 1534291200; // TODO: 15.08.2018 00:00:00 - start time of Presale.
    uint public constant endPresaleTime = 1534896000 + 1 weeks;   // TODO: 22.08.2018 00:00:00 - end time of Presale.
    
    uint public constant startIcoTime = 1534982400 + 1 weeks;     // TODO: 23.08.2018 00:00:00 - start time of ICO.
    uint public constant endIcoTime = 1535500800 + 1 weeks;       // TODO: 29.08.2018 00:00:00 - end time of ICO.
    
    // TODO: The cold wallet of the founders, 
    // for which the `TRA` funds will be transferred to the `Team`.
    address public constant founder = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    
    // TODO: The cold wallet of the founders,
    // for witch the `TRA` funds will be transferred to the `Bounty supporters`
    address public constant supporter = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    

    // TODO:
    // 100,000,000 * 10^18 
    // Total amount of `TRA` tokens, 
    // that will be emitted.
    uint public totalCap = 100000000 * 1 ether;
    
    // TODO:
    // 15% for Presale.
    // 15,000,000 * 10^18 
    // Total Presale cap
    uint public presaleCap = 15000000 * 1 ether;
    
    // TODO:
    // 50% for ICO.
    // 50,000,000 * 10^18 
    // Total ICO cap
    uint public icoCap = 50000000 * 1 ether;
    
    // TODO:
    // 10% of sold tokens for Bounty supporters.
    // The percentage of sold coind `TRA`,
    // witch will be emitted for the `Bounty supporters`.
    uint public constant bountyPercentage = 10;
    
    // TODO:
    // 25% of sold tokens for Founders.
    // The percentage of sold coind `TRA`,
    // witch will be emitted for the `Founders`.
    uint public constant foundersPercentage = 25;
    
    // TODO:
    // An address of the wallet 
    // to witch the funds raised 
    // from crowdsale (ETH) will be transferred.
    address public constant coldWallet = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    
    uint public constant PRESALE_PRICE = 5000; // TODO: 1 ETH = 5000 `TRA` on `Presale`.
    uint public constant ICO_PRICE = 2500;     // TODO: 1 ETH = 2500 `TRA` on `ICO`.
    
    uint public totalSoldTokens = 0;    // The Number of `TRA` tokens sold at `Presale` and `ICO`.
    uint public totalSoldOnPresale = 0; // The number of `TRA` tokens sold at `Presale`.
    uint public totalSoldOnIco = 0;     // The number of `TRA` tokens sold at `ICO`.
    
    bool public isCoinSentToFounder = false; // `TRA` coins sent to the founders?
    
    uint public totalEther = 0; // The amount of received `Ether`.
    
    uint public constant softcap =  100 ether; // TODO: The amount of ETH the crowdsale must receive to be considered successful.
    uint public constant hardcap = 200 ether; // TODO: The maximum amount of ETH that the crowdsale can get.
    
    bool public isHardCapCollected = false; // is hardcap collected?
    
    bool public isCrowdsaleInitialized = false; // Is crowdsale initialized?
    
    bool public isWithdrawn = false; // Ether was withdrawn?
    
    // During the investment we will save the investor&#39;s 
    // address and how much he invested for the refund.
    mapping(address=>uint) balances; 
    
    event HardcapReached(
        address indexed _where,
        uint256 hardcap,
        uint collected
    );
    
    constructor() public {
        Token = new TrivaToken(totalCap);
    }
    
    
    /**
     * @dev Throws if isCrowdsaleInitialized == true.
    */
    modifier isCrowdsaleOff() {
        require(!isCrowdsaleInitialized);
        _;
    }
    
    /**
     * Throws if called not during the crowdsale time frame. 
    */
    modifier presaleIsOn() {
        require(now > startPresaleTime && now < endPresaleTime);
        _;
    }
    
    /**
     * Throws if `Presale` end time longer than the current time.
    */
    modifier isPresaleFinished() {
        // require(now > endPresaleTime);
        _;
    }
    
    /**
     * Throws if colled not during the crowdsale time frame.
    */
    modifier icoIsOn() {
        require(now > startIcoTime && now < endIcoTime);
        _;
    }
    
    /**
     * Throws if `ICO` end time longer than the current time. 
    */ 
    modifier isIcoFinished() {
        // require(now > endIcoTime);
        _;
    }

    /**
     * Checks if the current time is in the gap between the `Presale` and the `ICO`.
    */
    modifier saleIsOn() {
        if (currentType == Type.Presale) 
            require(now > startPresaleTime && now < endPresaleTime);
        else if (currentType == Type.Ico)
            require(now > startIcoTime && now < endIcoTime);
        
        _;
    }
    
    /**
     * Checks whether the `hardcap` is collected.
    */
    modifier isUnderHadrCap() {
        if (isHardCapCollected)
            revert();
        
        if (address(this).balance >= hardcap) {
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
        require(currentStage == Stage.Stoped);
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
     * then divides difference to 1 days to find current day.
    */
    function getCurrentDay(uint256 startDate, uint256 currentDate) internal pure returns (uint256) {
        uint256 diff = currentDate.sub( startDate );
        
        // Ex: The result can be {3.6, 3.1, 3.9} 
        // in solidtity it will be 3
        uint256 diffDays = diff.div( 1 days ); 
        
        // and we need to add 1 to get 4 days.
        return diffDays.add(1);
    }
    
    /**
     * @dev Calculation of bonus percentage per valume of ETH for `Presale` and `ICO`.
     * @param etherValue the amount of ETH received.
    */
    function volumeBonus(uint etherValue) private pure returns (uint) {
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
    function dateBonus(uint fixedTime) private view returns (uint) {
        
        // If the type of crouwsale is `ICO`.
        if (currentType == Type.Ico) {
            // Days from ICO start.
            uint daysFromStart = getCurrentDay(startIcoTime, fixedTime); 
            
                 if (daysFromStart == 1)  return 60; // +60% tokens
            else if (daysFromStart == 2)  return 58; // +58% tokens
            else if (daysFromStart == 3)  return 56; // +56% tokens
            else if (daysFromStart == 4)  return 54; // +54% tokens
            else if (daysFromStart == 5)  return 52; // +52% tokens
            else if (daysFromStart == 6)  return 50; // +50% tokens
            else if (daysFromStart == 7)  return 48; // +48% tokens
            else if (daysFromStart == 8)  return 46; // +46% tokens
            else if (daysFromStart == 9)  return 44; // +44% tokens
            else if (daysFromStart == 10) return 42; // +42% tokens
            else if (daysFromStart == 11) return 40; // +40% tokens
            else if (daysFromStart == 12) return 38; // +38% tokens
            else if (daysFromStart == 13) return 36; // +36% tokens
            else if (daysFromStart == 14) return 34; // +34% tokens
            else if (daysFromStart == 15) return 32; // +32% tokens
            else if (daysFromStart == 16) return 30; // +30% tokens
            else if (daysFromStart == 17) return 28; // +28% tokens
            else if (daysFromStart == 18) return 26; // +26% tokens
            else if (daysFromStart == 19) return 24; // +24% tokens
            else if (daysFromStart == 20) return 22; // +22% tokens
            else if (daysFromStart == 21) return 20; // +20% tokens
            else if (daysFromStart == 22) return 18; // +18% tokens
            else if (daysFromStart == 23) return 16; // +16% tokens
            else if (daysFromStart == 24) return 14; // +14% tokens
            else if (daysFromStart == 25) return 12; // +12% tokens
            else if (daysFromStart == 26) return 10; // +10% tokens
            else if (daysFromStart == 27) return 8;  // +8%  tokens
            else if (daysFromStart == 28) return 6;  // +6%  tokens
            else if (daysFromStart == 29) return 4;  // +4%  tokens
            else if (daysFromStart == 30) return 2;  // +2%  tokens
            else if (daysFromStart == 31) return 1;  // +1%  tokens
            else if (daysFromStart == 32) return 0;  // +0%  tokens
            
            // Default: No bonus.
            return 0;
        } 
        
        // If the type of crowdsale is `Presale`.
        else if (currentType == Type.Presale) {
            // Days from Presale start.
            uint daysFromPresaleStart = getCurrentDay(startPresaleTime, fixedTime); 
            
                 if (daysFromPresaleStart == 1)  return 60;  // +60% tokens
            else if (daysFromPresaleStart == 2)  return 58;  // +58% tokens
            else if (daysFromPresaleStart == 3)  return 56;  // +56% tokens
            else if (daysFromPresaleStart == 4)  return 54;  // +54% tokens
            else if (daysFromPresaleStart == 5)  return 52;  // +52% tokens
            else if (daysFromPresaleStart == 6)  return 50;  // +50% tokens
            else if (daysFromPresaleStart == 7)  return 48;  // +48% tokens
            else if (daysFromPresaleStart == 8)  return 46;  // +46% tokens
            else if (daysFromPresaleStart == 9)  return 44;  // +44% tokens
            else if (daysFromPresaleStart == 10) return 42;  // +42% tokens
            else if (daysFromPresaleStart == 11) return 40;  // +40% tokens
            else if (daysFromPresaleStart == 12) return 38;  // +38% tokens
            else if (daysFromPresaleStart == 13) return 36;  // +36% tokens
            else if (daysFromPresaleStart == 14) return 34;  // +34% tokens
            else if (daysFromPresaleStart == 15) return 32;  // +32% tokens
            else if (daysFromPresaleStart == 16) return 30;  // +30% tokens
            else if (daysFromPresaleStart == 17) return 28;  // +28% tokens
            else if (daysFromPresaleStart == 18) return 26;  // +26% tokens
            else if (daysFromPresaleStart == 19) return 24;  // +24% tokens
            else if (daysFromPresaleStart == 20) return 22;  // +22% tokens
            else if (daysFromPresaleStart == 21) return 20;  // +20% tokens
            else if (daysFromPresaleStart == 22) return 18;  // +18% tokens
            else if (daysFromPresaleStart == 23) return 16;  // +16% tokens
            else if (daysFromPresaleStart == 24) return 14;  // +14% tokens
            else if (daysFromPresaleStart == 25) return 12;  // +12% tokens
            else if (daysFromPresaleStart == 26) return 10;  // +10% tokens
            else if (daysFromPresaleStart == 27) return 8;   // +8%  tokens
            else if (daysFromPresaleStart == 28) return 6;   // +6%  tokens
            else if (daysFromPresaleStart == 29) return 4;   // +4%  tokens
            else if (daysFromPresaleStart == 30) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 31) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 32) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 33) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 34) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 35) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 36) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 37) return 2;   // +2%  tokens
            else if (daysFromPresaleStart == 38) return 2;   // +2%  tokens
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
    
    function startPresale() public onlyOwner presaleIsOn whenNotRunning {
        currentStage = Stage.Running;
        currentType = Type.Presale;
    }
    
    function startIco() public onlyOwner isPresaleFinished icoIsOn {
        currentType = Type.Ico;
    }
    
    function pouseCrowdsale() external onlyOwner isRunning whenNotPouse {
        currentStage = Stage.Pouse;
    }
    
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
        uint bonusPercentForEther = volumeBonus(_etherValue);
        uint bonusPercentForDate = dateBonus(_fixedTime);
        
        uint totalBonusPercentage = bonusPercentForEther.add(bonusPercentForDate);
        
        uint totalBonusToken = tokensForSale.mul(totalBonusPercentage).div(100);
        
        return totalBonusToken;
    }
    
    // TODO: write comment
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
        balances[msg.sender] = msg.value;
        totalEther = totalEther.add(msg.value);
        
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
    function safeWithdrawal() public onlyOwner isStoped isIcoFinished {
        require(address(this).balance > 0, "Balance is 0.");
        require(
            address(this).balance >= softcap,
            "You can not withdrow `Ether`, because softcap is not compiled."
        );
        
        coldWallet.transfer(address(this).balance);
        isWithdrawn = true;
    } 
    
    // TODO: write comment
    function refund() public isIcoFinished whenNotWithdrawn {
        require(balances[msg.sender] > 0, "You don&#39;t have enough `ETH` to refund.");
        require(address(this).balance > 0);
        require(
            address(this).balance < softcap, 
            "You can not refund your `Ether`, because softcap is compiled."
        );
        
        
        balances[msg.sender] = 0;
        msg.sender.transfer(balances[msg.sender]);
    }
    
    // Finish crowdsale.
    function finishCrowdsale() public onlyOwner isPresaleFinished isIcoFinished {
        
        // Stop selling.
        currentStage = Stage.Stoped;
        
        // We Emit tokens for the founders.
        if (
            totalSoldTokens > 0 && 
            totalSoldTokens == totalSoldOnPresale.add(totalSoldOnIco) &&
            address(this).balance >= softcap
        ) {
            uint totalPercentage = foundersPercentage.add(bountyPercentage);
            
            // Calculation totalSoldTokens
            // formula: x = (totalSoldTokens * 100) / (100 - totalPercentage)
            uint hundred = 100;
            totalSoldTokens = totalSoldTokens.mul(hundred).div(hundred.sub(totalPercentage));
            
            // Emit tokens for Bounty supporters.
            uint tokensForSupporters = totalSoldTokens.mul(bountyPercentage).div(100);
            Token.transfer(supporter, tokensForSupporters);
            
            // Emit tokens for founders.
            uint tokensForFouders = totalSoldTokens.mul(foundersPercentage).div(100);
            Token.transfer(founder, tokensForFouders);
            isCoinSentToFounder = true;
            
            // Burning not sold tokens,
            // from crowdsale address = address(this).
            // not sold tokens = totalCap - totalSoldTokens.
            Token.burn(totalCap.sub(totalSoldTokens));
        }
    }
    
    
    function () external payable saleIsOn isRunning isUnderHadrCap {
        buyTokens(now);
    }
    
}