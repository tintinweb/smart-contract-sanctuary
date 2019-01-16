pragma solidity ^0.4.24;

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

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

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

contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

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

contract Pozess is ERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) internal balances;

  mapping (address => mapping (address => uint256)) private allowed;
  
  mapping (address => uint) private frozen; //A mapping of all frozen status

  uint256 internal totalSupply_;
  
  event FrozenStatus(address _target,uint _timeStamp);
  
  event Burn(address indexed burner, uint256 value);
  
  string public name = "Pozess"; 
  string public symbol = "PZS"; 
  uint8 public decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 200000000 * 10**18;

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

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
    require(frozen[msg.sender] >= now);

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
    require(frozen[msg.sender] >= now);

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
  function _mint(address _account, uint256 _amount) public onlyOwner {
    require(_account != 0);
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
  function _burn(address _account, uint256 _amount) public onlyOwner {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }
  
  // Freeze account since timestamp is coming
  function setFrozen(address _target, uint _timeStamp) public onlyOwner {
    frozen[_target]=_timeStamp;
    emit FrozenStatus(_target,_timeStamp);
  }


}

contract Crowdsale is Pozess {
    // ICO rounds
    enum IcoStages {preSale, preIco1, preIco2, ico1, ico2, ico3, ico4} 
    IcoStages Stage;
    bool private crowdsaleFinished;
    
    uint private startPreSaleDate;
    uint private endPreSaleDate;
    uint public preSaleGoal;
    uint private preSaleRaised;
    
    uint private startPreIco1Date;
    uint private endPreIco1Date;
    uint public preIco1Goal;
    uint private preIco1Raised;
    
    
    uint private startIco1Date;
    uint private endIco1Date;
    uint public ico1Goal;
    uint private ico1Raised;
    
    uint private startIco2Date;
    uint private endIco2Date;
    uint public ico2Goal;
    uint private ico2Raised;
    
    uint private startIco3Date;
    uint private endIco3Date;
    uint public ico3Goal;
    uint private ico3Raised;
    
    uint private startIco4Date;
    uint private endIco4Date;
    uint public ico4Goal;
    uint private ico4Raised;
    
    uint private softCap;
    uint private hardCap;
    uint private totalCap;
    uint private price;
    uint private reserved;
    
    struct Benefeciary{ // collect all participants of ICO
        address wallet;
        uint amount;
    }
    Benefeciary[] private benefeciary;
    uint private ethersRefund;
    
    constructor() public {
        startPreSaleDate = 1540857600; // 30/10/2018 @ 12:00am (UTC)
        endPreSaleDate = 1548979199; // 31/01/2019 @ 23:59am (UTC)
        preSaleGoal = 45000000; // pre-sale goal
        preSaleRaised = 0; // raised on pre-sale stage
        
        startPreIco1Date = 1548979200; // 01/02/2019 @ 12:00am (UTC)
        endPreIco1Date = 1551398399; // 02/28/2019 @ 23:59am (UTC)
        preIco1Goal = 15000000; // pre ico 1 phase goal 
        preIco1Raised = 0; // raised on pre ico stage 1
        
        startIco1Date = 1551398400; // 01/03/2019 @ 12:00am (UTC)
        endIco1Date = 1553990399; // 30/03/2019 @ 23:59am (UTC)
        ico1Goal = 15000000; // ico phase 1 goal 
        ico1Raised = 0; // raised on ico stage 1
        
        startIco2Date = 1554076800; // 01/04/2019 @ 12:00am (UTC)
        endIco2Date = 1556668799; // 30/04/2019 @ 23:59am (UTC)
        ico2Goal = 10000000; // ico phase 2 goal 
        ico2Raised = 0; // raised on ico stage 2
        
        startIco3Date = 1556668800; // 01/05/2019 @ 12:00am (UTC)
        endIco3Date = 1557878399; // 14/05/2019 @ 23:59am (UTC)
        ico3Goal = 10000000; // ico phase 3 goal 
        ico3Raised = 0; // raised on ico stage 3
        
        startIco4Date = 1557878400; // 15/05/2019 @ 12:00am (UTC)
        endIco4Date = 1559260799; // 30/05/2019 @ 23:59am (UTC)
        ico4Goal = 5000000; // ico phase 4 goal 
        ico4Raised = 0; // raised on ico stage 4
        
        softCap = 25000 * 10**18; // 5 000 000$ (1 ether = 200$) 5000000/200
        hardCap = 200000 * 10**18; // 40 000 000$ (1 ether = 200$) 40000000/200
        totalCap = 0;
        price = 2500000; //gwei per token
        crowdsaleFinished = false;
        reserved = (2*20000000 + 30000000 + 10000000 + 6000000 + 14000000 + 30000000) * 10**18;
    }
  
    function getCrowdsaleInfo() private returns(uint stage, 
                                               uint tokenAvailable, 
                                               uint bonus){
        // Token calculating
        if(now <= endPreSaleDate && preSaleRaised < preSaleGoal){
            Stage = IcoStages.preSale;
            tokenAvailable = preSaleGoal - preSaleRaised;
            bonus = 30;
        } else if(startPreIco1Date <= now && now <= endPreIco1Date && preIco1Raised < preIco1Goal){
            Stage = IcoStages.preIco1;
            tokenAvailable = preIco1Goal - preIco1Raised;
            bonus = 25;
        } else if(startIco1Date <= now && now <= endIco1Date && ico1Raised < ico1Goal){
            Stage = IcoStages.ico1;
            tokenAvailable = ico1Goal - ico1Raised;
            bonus = 20;
        } else if(startIco2Date <= now && now <= endIco2Date && ico2Raised < ico2Goal){
            Stage = IcoStages.ico2;
            tokenAvailable = ico2Goal - ico2Raised;
            bonus = 15;
        } else if(startIco3Date <= now && now <= endIco3Date && ico3Raised < ico3Goal){
            Stage = IcoStages.ico3;
            tokenAvailable = ico3Goal - ico3Raised;
            bonus = 10;
        } else if(startIco4Date <= now && now <= endIco4Date && ico4Raised < ico4Goal){
            Stage = IcoStages.ico4;
            tokenAvailable = ico4Goal - ico4Raised;
            bonus = 5;
        } else {
            // if ICO has not been started
            revert();
        }
        return (uint(Stage), tokenAvailable, bonus);
    }
    
    function evaluateTokens(uint _value, address _sender) private returns(uint tokens){
        ethersRefund = 0;
        uint bonus;
        uint tokenAvailable;
        uint stage;
        (stage,tokenAvailable,bonus) = getCrowdsaleInfo();
        tokens = _value / price / 10**9; 
        if(bonus != 0){
            tokens = tokens + (tokens * bonus / 100); // calculate bonus tokens
        } 
        if(tokenAvailable < tokens){ // if not enough tokens in reserve
            tokens = tokenAvailable;
            ethersRefund = _value - (tokens * price * 10**9); // calculate how many ethers will respond to user
            _sender.transfer(ethersRefund);// payback 
        }
        owner.transfer(_value - ethersRefund);
        // Add token value to raised variable
        if(stage == 0){
            preSaleRaised += tokens;
        } else if(stage == 1){
            preIco1Raised += tokens;
        }  else if(stage == 2){
            ico1Raised += tokens;
        } else if(stage == 3){
            ico2Raised += tokens;
        } else if(stage == 4){
            ico3Raised += tokens;
        } else if(stage == 5){
            ico4Raised += tokens;
        }
        addInvestor(_sender, _value);
        return tokens;
    }
    
    function addInvestor(address _sender, uint _value) private {
        Benefeciary memory ben;
        for(uint i = 0; i < benefeciary.length; i++){
            if(benefeciary[i].wallet == _sender){
                benefeciary[i].amount = benefeciary[i].amount + _value - ethersRefund;
            }
        }
        setFrozen(_sender, 1561939199);// freze tokens until one month after ICO finished
        ben.wallet = msg.sender;
        ben.amount = msg.value - ethersRefund;
        benefeciary.push(ben);
    }
    
    
    function() public payable {
        require(startPreSaleDate <= now && now <= endIco4Date);
        require(msg.value >= 1 ether);
        totalCap += msg.value;
        uint token = evaluateTokens(msg.value, msg.sender);
        // send tokens to buyer
        balances[msg.sender] = balances[msg.sender].add(token * 10**18);
        balances[owner] = balances[owner].sub(token * 10**18);
        emit Transfer(owner, msg.sender, token * 10**18);
    }
    
    function showParticipantWei(address _wallet) public view onlyOwner returns(uint){
        for(uint i = 0; i < benefeciary.length; i++){
            if(benefeciary[i].wallet == _wallet){
                return benefeciary[i].amount;// show in wei
            }
        }
        return 0;
    }
    
    modifier icoHasFinished() {
        require(now >= endIco4Date || crowdsaleFinished);
        _;
    }
    
    function burnUnsoldTokens() public onlyOwner icoHasFinished{
        _burn(owner, balanceOf(owner).sub(reserved));
    }
    
    function endIcoByCap() public onlyOwner{
        require(!crowdsaleFinished);
        require(totalCap >= softCap && totalCap <= hardCap);
        crowdsaleFinished = true;
    }
    
    function crowdSaleStage() public view returns(string){
        string memory result;
        if(uint(Stage) == 0){
            result = "Pre Sale";
        } else if(uint(Stage) == 1){
            result = "Pre-ICO phase 1";
        } else if(uint(Stage) == 2){
            result = "ICO phase 1";
        } else if(uint(Stage) == 3){
            result = "ICO phase 2";
        } else if(uint(Stage) == 4){
            result = "ICO phase 3";
        } else if(uint(Stage) == 5){
            result = "ICO phase 4";
        } 
        return result;
    }
    
    function preSaleRaise() public view returns(uint){
        return preSaleRaised;
    }
    
    function preIco1Raise() public view returns(uint){
        return preIco1Raised;
    }
    
    function ico1Raise() public view returns(uint){
        return ico1Raised;
    }
    
    function ico2Raise() public view returns(uint){
        return ico2Raised;
    }
    
    function ico3Raise() public view returns(uint){
        return ico3Raised;
    }
    
    function ico4Raise() public view returns(uint){
        return ico4Raised;
    }
    
    // Output all funds in wei
    function showAllFunds() public onlyOwner view returns(uint){
        return totalCap;
    }
}