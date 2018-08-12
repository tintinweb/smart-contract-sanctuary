pragma solidity ^0.4.24;

contract INotInitedOwnable {
    
    function init() public;
    
    function transferOwnership(address newOwner) public;
}

contract IOwnableUpgradeableImplementation is INotInitedOwnable {
    
    function transferOwnership(address newOwner) public;
    
    function getOwner() constant public returns(address);
    
    function upgradeImplementation(address _newImpl) public;
    
    function getImplementation() constant public returns(address);
}

contract IHookOperator is IOwnableUpgradeableImplementation {

    event LogSetBalancePercentageLimit(uint256 limit);
    event LogSetOverBalanceLimitHolder(address holderAddress, bool isHolder);
    event LogSetUserManager(address userManagerAddress);
    event LogSetICOToken(address icoTokenAddress);

    event LogOnTransfer(address from, address to, uint tokens);
    event LogOnMint(address to, uint256 amount);
    event LogOnBurn(uint amount);
    event LogOnTaxTransfer(address indexed taxableUser, uint tokensAmount);

    event LogSetKYCVerificationContract(address _kycVerificationContractAddress);
    event LogUpdateUserRatio(uint256 generationRatio, address indexed userContractAddress);

    /**
        Setters
    */
    function setBalancePercentageLimit(uint256 limit) public;
    function getBalancePercentageLimit() public view returns(uint256);
    
    function setOverBalanceLimitHolder(address holderAddress, bool isHolder) public;

    function setUserManager(address userManagerAddress) public;
    function getUserManager() public view returns(address userManagerAddress);
   
    function setICOToken(address icoTokenAddress) public;
    function getICOToken() public view returns(address icoTokenAddress);

    /**
        Main Functions
    */
    function onTransfer(address from, address to, uint256 tokensAmount) public;

    function onMint(address to, uint256 tokensAmount) public;

    function onBurn(uint256 amount) public;

    function onTaxTransfer(address taxableUser, uint256 tokensAmount) public;

    /**
        KYC Verification
    */
    function kycVerification(address from, address to, uint256 tokensAmount) public;

    function setKYCVerificationContract(address _kycVerificationContractAddress) public;

    function getKYCVerificationContractAddress() public view returns(address _kycVerificationContractAddress);
    
    /**
        Helper functions
    */
    function updateUserRatio(uint256 generationRatio, address userContractAddress) public;

    function isOverBalanceLimitHolder(address holderAddress) public view returns(bool);

    function isInBalanceLimit(address userAddress, uint256 tokensAmount) public view returns(bool);
}

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

contract ExchangeOracle is Ownable, Pausable {

    using SafeMath for uint;

    bool public isIrisOracle = true;

    uint public rate = 0;
    uint public minWeiAmount = 1000; 

    event LogRateChanged(uint oldRate, uint newRate, address changer);
    event LogMinWeiAmountChanged(uint oldMinWeiAmount, uint newMinWeiAmount, address changer);

    constructor(uint initialRate) public {
        require(initialRate > 0);
        rate = initialRate;
    }

    function rate() external view whenNotPaused returns(uint) {
        return rate;
    }

    /*
        The new rate has to be passed in format:
            100 rate = 100 000 passed rate ( 1 ether = 100 tokens )
            1 rate = 1 000 passed rate ( 1 ether = 1 token )
            0.01 rate = 10 passed rate ( 100 ethers = 1 token )
    **/
    function setRate(uint newRate) external onlyOwner whenNotPaused returns(bool) {
        require(newRate > 0);
        
        uint oldRate = rate;
        rate = newRate;

        emit LogRateChanged(oldRate, newRate, msg.sender);

        return true;
    }

    /*
        By default minWeiAmount = 1000
        With min wei amount we can set the rate to be a float number

        We use it as a multiplier because we can not pass float numbers in ethereum
        If the token price becomes bigger than ether one, for example -> 1 token = 10 ethers
        We will pass 100 as rate and this will be relevant to 0.1 token = 1 ether
    **/
    function setMinWeiAmount(uint newMinWeiAmount) external onlyOwner whenNotPaused returns(bool) {
        require(newMinWeiAmount > 0);
        require(newMinWeiAmount % 10 == 0); 

        uint oldMinWeiAmount = minWeiAmount;
        minWeiAmount = newMinWeiAmount;

        emit LogMinWeiAmountChanged(oldMinWeiAmount, minWeiAmount, msg.sender);

        return true;
    }

    function convertTokensAmountInWeiAtRate(uint tokensAmount, uint convertRate) external whenNotPaused view returns(uint) {

        uint weiAmount = tokensAmount.mul(minWeiAmount);
        weiAmount = weiAmount.div(convertRate);

        if ((tokensAmount % convertRate) != 0) {
            weiAmount++;
        } 

        return weiAmount;
    }

    function calcWeiForTokensAmount(uint tokensAmount) external view whenNotPaused returns(uint) {
        
        uint weiAmount = tokensAmount.mul(minWeiAmount);
        weiAmount = weiAmount.div(rate);

        if ((tokensAmount % rate) != 0) {
            weiAmount++;
        } 

        return weiAmount;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
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
    totalSupply = totalSupply.add(_amount);
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

contract ICOToken is BurnableToken, MintableToken, PausableToken {

    string public constant name = "AIUR Token";
    string public constant symbol = "AIUR";
    uint8 public constant decimals = 18;
}

contract ICOTokenExtended is ICOToken {

    address public refunder;

    IHookOperator public hookOperator;
    ExchangeOracle public aiurExchangeOracle;

    mapping(address => bool) public minters;

    uint256 public constant MIN_REFUND_RATE_DELIMITER = 2; // Refund rate has to be minimum 50% of the AIUR ExchangeOracle rate

    event LogRefunderSet(address refunderAddress);
    event LogTransferOverFunds(address from, address to, uint ethersAmount, uint tokensAmount);
    event LogTaxTransfer(address from, address to, uint amount);
    event LogMinterAdd(address addedMinter);
    event LogMinterRemove(address removedMinter);

    modifier onlyMinter(){
        require(minters[msg.sender]);
        
        _;
    }

    modifier onlyCurrentHookOperator() {
        require(msg.sender == address(hookOperator));

        _;
    }

    modifier nonZeroAddress(address inputAddress) {
        require(inputAddress != address(0));

        _;
    }

    modifier onlyRefunder() {
        require(msg.sender == refunder);

        _;
    }

    constructor() public {
        minters[msg.sender] = true;
    }

    function setRefunder(address refunderAddress) external onlyOwner nonZeroAddress(refunderAddress) {
        refunder = refunderAddress;

        emit LogRefunderSet(refunderAddress);
    }

    // Set the exchange oracle after crowdsale 
    function setExchangeOracle(address exchangeOracleAddress) external onlyOwner nonZeroAddress(exchangeOracleAddress) {
        aiurExchangeOracle = ExchangeOracle(exchangeOracleAddress);
    }

    function setHookOperator(address hookOperatorAddress) external onlyOwner nonZeroAddress(hookOperatorAddress) {
        hookOperator = IHookOperator(hookOperatorAddress);
    }

    function addMinter(address minterAddress) external onlyOwner nonZeroAddress(minterAddress) {
        minters[minterAddress] = true;    

        emit LogMinterAdd(minterAddress);
    }

    function removeMinter(address minterAddress) external onlyOwner nonZeroAddress(minterAddress) {
        minters[minterAddress] = false;    

        emit LogMinterRemove(minterAddress);
    }

    function mint(address to, uint256 tokensAmount) public onlyMinter canMint nonZeroAddress(to) returns(bool) {
        hookOperator.onMint(to, tokensAmount);

        totalSupply = totalSupply.add(tokensAmount);
        balances[to] = balances[to].add(tokensAmount);

        emit Mint(to, tokensAmount);
        emit Transfer(address(0), to, tokensAmount);
        return true;
    } 

    function burn(uint tokensAmount) public {
        hookOperator.onBurn(tokensAmount);       

        super.burn(tokensAmount);  
    } 

    function transfer(address to, uint tokensAmount) public nonZeroAddress(to) returns(bool) {
        hookOperator.onTransfer(msg.sender, to, tokensAmount);

        return super.transfer(to, tokensAmount);
    }
    
    function transferFrom(address from, address to, uint tokensAmount) public nonZeroAddress(from) nonZeroAddress(to) returns(bool) {
        hookOperator.onTransfer(from, to, tokensAmount);
        
        return super.transferFrom(from, to, tokensAmount);
    }

    /*
        This function is used for taxation purposes and will be used after pre-defined requirement are met
    */
    function taxTransfer(address from, address to, uint tokensAmount) external onlyCurrentHookOperator nonZeroAddress(from) nonZeroAddress(to) returns(bool) {  
        require(balances[from] >= tokensAmount);

        transferDirectly(from, to, tokensAmount);

        hookOperator.onTaxTransfer(from, tokensAmount);
        emit LogTaxTransfer(from, to, tokensAmount);

        return true;
    }

    function transferOverBalanceFunds(address from, address to, uint rate) external payable onlyRefunder nonZeroAddress(from) nonZeroAddress(to) returns(bool) {
        require(!hookOperator.isOverBalanceLimitHolder(from));

        uint256 oracleRate = aiurExchangeOracle.rate();
        require(rate <= oracleRate.add(oracleRate.div(MIN_REFUND_RATE_DELIMITER)));

        uint256 fromBalance = balanceOf(from);
        
        // Calculate percentage limit in tokens
        uint256 maxTokensBalance = totalSupply.mul(hookOperator.getBalancePercentageLimit()).div(100);

        require(fromBalance > maxTokensBalance);

        uint256 tokensToTake = fromBalance.sub(maxTokensBalance);
        uint256 weiToRefund = aiurExchangeOracle.convertTokensAmountInWeiAtRate(tokensToTake, rate);

        require(hookOperator.isInBalanceLimit(to, tokensToTake));
        require(msg.value == weiToRefund);

        transferDirectly(from, to, tokensToTake);
        from.transfer(msg.value);

        emit LogTransferOverFunds(from, to, weiToRefund, tokensToTake);

        return true;
    }

    function transferDirectly(address from, address to, uint tokensAmount) private {
        balances[from] = balances[from].sub(tokensAmount);
        balances[to] = balances[to].add(tokensAmount);
    }
}