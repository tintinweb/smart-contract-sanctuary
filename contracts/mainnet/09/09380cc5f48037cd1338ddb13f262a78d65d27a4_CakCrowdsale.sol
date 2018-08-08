pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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



contract CakToken is MintableToken {
    string public constant name = "Cash Account Key";
    string public constant symbol = "CAK";
    uint8 public constant decimals = 0;
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = weiAmount.mul(rate);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }


}


contract CakCrowdsale is Ownable, Crowdsale {
    using SafeMath for uint256;

    enum SaleStages { Crowdsale, Finalized }
    SaleStages public currentStage;

    uint256 public constant TOKEN_CAP = 3e7;
    uint256 public totalTokensMinted;

    // allow managers to whitelist and confirm contributions by manager accounts
    // (managers can be set and altered by owner, multiple manager accounts are possible
    mapping(address => bool) public isManagers;

    // true if address is allowed to invest
    mapping(address => bool) public isWhitelisted;

    // list of events
    event ChangedInvestorWhitelisting(address indexed investor, bool whitelisted);
    event ChangedManager(address indexed manager, bool active);
    event PresaleMinted(address indexed beneficiary, uint256 tokenAmount);
    event CakCalcAmount(uint256 tokenAmount, uint256 weiReceived, uint256 rate);
    event RefundAmount(address indexed beneficiary, uint256 refundAmount);

    // list of modifers
    modifier onlyManager(){
        require(isManagers[msg.sender]);
        _;
    }

    modifier onlyCrowdsaleStage() {
        require(currentStage == SaleStages.Crowdsale);
        _;
    }

    /**
     * @dev Constructor
     * @param _startTime uint256
     * @param _endTime unit256
     * @param _rate uint256
     * @param _wallet address
     */
    function CakCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet)
        Crowdsale(_startTime, _endTime, _rate, _wallet)
        public
    {
        setManager(msg.sender, true);
        currentStage = SaleStages.Crowdsale;
    }

    /**
    * @dev allows contract owner to mint tokens for presale or non-ETH contributions in batches
     * @param _toList address[] array of the beneficiaries to receive tokens
     * @param _tokenList uint256[] array of the token amounts to mint for the corresponding users
    */
    function batchMintPresaleTokens(address[] _toList, uint256[] _tokenList) external onlyOwner onlyCrowdsaleStage {
        require(_toList.length == _tokenList.length);

        for (uint256 i; i < _toList.length; i = i.add(1)) {
            mintPresaleTokens(_toList[i], _tokenList[i]);
        }
    }

    /**
     * @dev mint tokens for presale beneficaries
     * @param _beneficiary address address of the presale buyer
     * @param _amount unit256 amount of CAK tokens they will receieve
     */
    function mintPresaleTokens(address _beneficiary, uint256 _amount) public onlyOwner onlyCrowdsaleStage {
        require(_beneficiary != address(0));
        require(_amount > 0);
        require(totalTokensMinted.add(_amount) <= TOKEN_CAP);
        require(now < startTime);

        token.mint(_beneficiary, _amount);
        totalTokensMinted = totalTokensMinted.add(_amount);
        PresaleMinted(_beneficiary, _amount);
    }

     /**
     * @dev entry point for the buying of CAK tokens. overriding open zeppelins buyTokens()
     * @param _beneficiary address address of the investor, must be whitelested first
     */
    function buyTokens(address _beneficiary) public payable onlyCrowdsaleStage {
        require(_beneficiary != address(0));
        require(isWhitelisted[msg.sender]);
        require(validPurchase());
        require(msg.value >= rate);  //rate == minimum amount in WEI to purchase 1 CAK token

        uint256 weiAmount = msg.value;
        weiRaised = weiRaised.add(weiAmount);

        // Calculate the amount of tokens
        uint256 tokens = calcCakAmount(weiAmount);
        CakCalcAmount(tokens, weiAmount, rate);
        require(totalTokensMinted.add(tokens) <= TOKEN_CAP);

        token.mint(_beneficiary, tokens);
        totalTokensMinted = totalTokensMinted.add(tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        uint256 refundAmount = refundLeftOverWei(weiAmount, tokens);
        if (refundAmount > 0) {
            weiRaised = weiRaised.sub(refundAmount);
            msg.sender.transfer(refundAmount);
            RefundAmount(msg.sender, refundAmount);
        }

        forwardEther(refundAmount);
    }

     /**
     * @dev set manager to true/false to enable/disable manager rights
     * @param _manager address address of the manager to create/alter
     * @param _active bool flag that shows if the manager account is active
     */
    function setManager(address _manager, bool _active) public onlyOwner {
        require(_manager != address(0));
        isManagers[_manager] = _active;
        ChangedManager(_manager, _active);
    }

    /**
     * @dev whitelister "account". This can be done from managers only
     * @param _investor address address of the investor&#39;s wallet
     */
    function whiteListInvestor(address _investor) external onlyManager {
        require(_investor != address(0));
        isWhitelisted[_investor] = true;
        ChangedInvestorWhitelisting(_investor, true);
    }

    /**
     * @dev whitelister "accounts". This can be done from managers only
     * @param _investors address[] addresses of the investors&#39; wallet
     */
    function batchWhiteListInvestors(address[] _investors) external onlyManager {
        address investor;

        for (uint256 c; c < _investors.length; c = c.add(1)) {
            investor = _investors[c]; // gas optimization
            isWhitelisted[investor] = true;
            ChangedInvestorWhitelisting(investor, true);
        }
    }

    /**
     * @dev un-whitelister "account". This can be done from managers only
     * @param _investor address address of the investor&#39;s wallet
     */
    function unWhiteListInvestor(address _investor) external onlyManager {
        require(_investor != address(0));
        isWhitelisted[_investor] = false;
        ChangedInvestorWhitelisting(_investor, false);
    }

    /**
     * @dev ends the crowdsale, callable only by contract owner
     */
    function finalizeSale() public onlyOwner {
         currentStage = SaleStages.Finalized;
         token.finishMinting();
    }

    /**
     * @dev calculate WEI to CAK tokens to mint
     * @param weiReceived uint256 wei received from the investor
     */
    function calcCakAmount(uint256 weiReceived) public view returns (uint256) {
        uint256 tokenAmount = weiReceived.div(rate);
        return tokenAmount;
    }

    /**
     * @dev calculate WEI refund to investor, if any. This handles rounding errors
     * which are important here due to the 0 decimals
     * @param weiReceived uint256 wei received from the investor
     * @param tokenAmount uint256 CAK tokens minted for investor
     */
    function refundLeftOverWei(uint256 weiReceived, uint256 tokenAmount) internal view returns (uint256) {
        uint256 refundAmount = 0;
        uint256 weiInvested = tokenAmount.mul(rate);
        if (weiInvested < weiReceived)
            refundAmount = weiReceived.sub(weiInvested);
        return refundAmount;
    }

    /**
     * Overrides the Crowdsale.createTokenContract to create a CAK token
     * instead of a default MintableToken.
     */
    function createTokenContract() internal returns (MintableToken) {
        return new CakToken();
    }

    /**
     * @dev forward Ether to wallet with proper amount subtracting refund, if refund exists
     * @param refund unint256 the amount refunded to the investor, if > 0 
     */
    function forwardEther(uint256 refund) internal {
        wallet.transfer(msg.value.sub(refund));
    }
}