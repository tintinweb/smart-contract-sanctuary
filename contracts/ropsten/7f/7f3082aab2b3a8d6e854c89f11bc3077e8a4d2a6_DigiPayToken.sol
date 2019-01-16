pragma solidity ^0.4.25;

/**
 * Digipay Network - The Future of Online Payments
 * ----------------------------------------------------------------------------
 */

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * ----------------------------------------------------------------------------
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev if the owner calls this function, the function is executed
   * and otherwise, an exception is thrown.
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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * ----------------------------------------------------------------------------
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
 * @title ERC20Basic
 * @dev https://github.com/ethereum/EIPs/issues/179
 * @dev This ERC describes a simpler version of the ERC20 standard token contract
 * ----------------------------------------------------------------------------
 */

contract ERC20Basic {
  
  // The total token supply
  function totalSupply() public view returns (uint256);

  // @notice Get the account balance of another account with address `who`
  function balanceOf(address who) public view returns (uint256); 
  
  // @notice Transfer `value&#39; amount of tokens to address `to`
  function transfer(address to, uint256 value) public returns (bool);

  // @notice Triggered when tokens are transferred
  event Transfer(address indexed from, address indexed to, uint256 value);

}

/**
 * @title ERC20 Standard
 * @dev https://github.com/ethereum/EIPs/issues/20
 * ----------------------------------------------------------------------------
 */

contract ERC20 is ERC20Basic {

  // @notice Returns the amount which `spender` is still allowed to withdraw from `owner`
  function allowance(address owner, address spender) public view returns (uint256);

  // @notice Transfer `value` amount of tokens from address `from` to address `to`
  // Address `to` can withdraw after it is approved by address `from`
  function transferFrom(address from, address to, uint256 value) public returns (bool);

  // @notice Allow `spender` to withdraw, multiple times, up to the `value` amount
  function approve(address spender, uint256 value) public returns (bool);

  // @notice Triggered whenever approve(address spender, uint256 value) is called
  event Approval(address indexed owner, address indexed spender, uint256 value);

}

/**
 * @title BasicToken
 * @dev Simpler version of StandardToken, with basic functions
 * ----------------------------------------------------------------------------
 */

contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  // @notice This creates an array with all balances
  mapping(address => uint256) balances;

  // @notice Get the token balance of address `_owner`
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    
    // @notice Prevent transfer to 0x0 address
    require(_to != address(0));

    // @notice `Check if the sender has enough` is not needed
    // because sub(balances[msg.sender], _value) will `throw` if this condition is not met
    require(balances[msg.sender] >= _value);

    // @notice `Check for overflows` is not needed
    // because add(_to, _value) will `throw` if this condition is not met
    require(balances[_to] + _value >= balances[_to]);

    // @notice Subtract from the sender
    balances[msg.sender] = balances[msg.sender].sub(_value);

    // @notice Add the same to the recipient
    balances[_to] = balances[_to].add(_value);

    // @notice Trigger `transfer` event
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

}


/**
 * @title ERC20 Token Standard
 * @dev Implementation of the Basic token standard
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 * ----------------------------------------------------------------------------
 */

contract StandardToken is ERC20, BasicToken {

  // @notice Owner of address approves the transfer of an amount to another address
  mapping (address => mapping (address => uint256)) allowed;

  // @notice Owner allows `_spender` to transfer or withdraw `_value` tokens from owner to `_spender`
  // Trigger `approve` event
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // @notice This check is not needed 
    // because sub(_allowance, _value) will throw if this condition is not met
    require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  // @notice Returns the amount which `_spender` is still allowed to withdraw from `_owner`
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * @notice Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
  /**
   * @notice Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
 * @title tokensale.digipay.network TokenSaleKYC
 * @dev Verified addresses can participate in the token sale
 */
contract TokenSaleKYC is Ownable {
    
    // @dev This creates an array with all verification statuses of addresses 
    mapping(address=>bool) public verified;


    /**
     * @dev Updates verification status of an address
     * @dev Only owner can update
     * @param participant Address that is submitted by a participant 
     * @param verificationStatus True or false
     */
    function updateVerificationStatus(address participant, bool verificationStatus) internal onlyOwner {
        verified[participant] = verificationStatus;
        
    }

    /**
     * @dev Updates verification statuses of addresses
     * @dev Only owner can update
     * @param participants An array of addresses
     * @param verificationStatus True or false
     */
    function updateVerificationStatuses(address[] participants, bool verificationStatus) internal onlyOwner {
        for (uint i = 0; i < participants.length; i++) {
            updateVerificationStatus(participants[i], verificationStatus);
        }
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 * ----------------------------------------------------------------------------
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
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title DigiPayToken contract
 * @dev Allocate tokens to wallets based on our token distribution
 * @dev Accept contributions only within a time frame
 * @dev Participants must complete KYC process
 * @dev There are two stages (Pre-sale and Mainsale)
 * @dev Require minimum and maximum contributions
 * @dev Calculate bonuses and rates
 * @dev Can pause contributions
 * @dev The token sale stops automatically when the hardcap is reached 
 * @dev Lock (can not transfer) tokens until the token sale ends
 * @dev Burn unsold tokens
 * @dev Update the total supply after burning 
 * @author digipay.network
 * ----------------------------------------------------------------------------
 */
contract DigiPayToken is StandardToken, Ownable, TokenSaleKYC, Pausable {
  using SafeMath for uint256; 
  string  public name;
  string  public symbol;
  uint8   public decimals;

  uint256 public weiRaised;
  uint256 public hardCap;

  address public wallet;
  address public TEAM_WALLET;
  address public AIRDROP_WALLET;
  address public RESERVE_WALLET;

  uint    internal _totalSupply;
  uint    internal _teamAmount;
  uint    internal _airdropAmount;
  uint    internal _reserveAmount;

  uint256 internal presaleStartTime;
  uint256 internal presaleEndTime;
  uint256 internal mainsaleStartTime;
  uint256 internal mainsaleEndTime;

  bool    internal presaleOpen;
  bool    internal mainsaleOpen;
  bool    internal Open;
  bool    public   locked;
  
    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    event Burn(address indexed burner, uint tokens);

    // @dev The token sale stops automatically when the hardcap is reached
    modifier onlyWhileOpen {
        require(now >= presaleStartTime && now <= mainsaleEndTime && Open && weiRaised <= hardCap);
        _;
    }
    
    // @dev Lock (can not transfer) tokens until the token sale ends
    // Aidrop wallet and reserve wallet are allowed to transfer 
    modifier onlyUnlocked() {
        require(msg.sender == AIRDROP_WALLET || msg.sender == RESERVE_WALLET || msg.sender == owner || !locked);
        _;
    }

    /**
     * ------------------------------------------------------------------------
     * Constructor
     * ------------------------------------------------------------------------
     */
    constructor (address _owner, address _wallet, address _team, address _airdrop, address _reserve) public {

        _setTimes();
        
        name = "DigiPay";
        symbol = "DIP";
        decimals = 18;
        hardCap = 20 ether;

        owner = _owner;
        wallet = _wallet;
        TEAM_WALLET = _team;
        AIRDROP_WALLET = _airdrop;
        RESERVE_WALLET = _reserve;

        // @dev initial total supply
        _totalSupply = 180000000e18;
        // @dev Tokens initialy allocated for the team (20%)
        _teamAmount = 36000000e18;
        // @dev Tokens initialy allocated for airdrop campaigns (8%)
        _airdropAmount = 14400000e18;
        // @dev Tokens initialy allocated for testing the platform (2%)
        _reserveAmount = 3600000e18;

        balances[this] = totalSupply();
        emit Transfer(address(0x0),this, totalSupply());
        _transfer(TEAM_WALLET, _teamAmount);
        _transfer(AIRDROP_WALLET, _airdropAmount);
        _transfer(RESERVE_WALLET, _reserveAmount);

        Open = true;
        locked = true;
        
    }

    function updateWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function _setTimes() internal {   
        presaleStartTime          = 1540288800; // 01st Nov 2018 09:00:00 GMT 
        presaleEndTime            = 1540296000; // 29th Nov 2018 08:59:59 GMT
        mainsaleStartTime         = 1540299600; // 20th Dec 2018 09:00:00 GMT
        mainsaleEndTime           = 1540308540; // 24th Jan 2019 08:59:59 GMT
    }

    function unlock() public onlyOwner {
        locked = false;
    }

    function lock() public onlyOwner {
        locked = true;
    }

    /**
     * @dev override `transfer` function to add onlyUnlocked
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value) public onlyUnlocked returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev override `transferFrom` function to add onlyUnlocked
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transferFrom(address _from, address _to, uint _value) public onlyUnlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    // @dev Return `true` if the token sale is live
    function _checkOpenings() internal {
        
        if(now >= presaleStartTime && now <= presaleEndTime) {
            presaleOpen = true;
            mainsaleOpen = false;
        }
        else if(now >= mainsaleStartTime && now <= mainsaleEndTime) {
            presaleOpen = false;
            mainsaleOpen = true;
        }
        else {
            presaleOpen = false;
            mainsaleOpen = false;
        }
    }
    
    // @dev Fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    /**
     * @dev Check verification statuses of addresses
     * @return True if participants can buy tokens, false otherwise
     */
    function checkVerificationStatus(address participant) public view returns (bool) {
        return verified[participant];
    }

    function buyTokens(address _beneficiary) public payable onlyWhileOpen whenNotPaused {
    
        // @dev `msg.value` contains the amount of wei sent in a transaction
        uint256 weiAmount = msg.value;
    
        /** 
         * @dev Validation of an incoming purchase
         * @param _beneficiary Address performing the token purchase
         * @param weiAmount Value in wei involved in the purchase
         */
        require(_beneficiary != address(0));
        require(weiAmount != 0);
    
        _checkOpenings();

        require(checkVerificationStatus(_beneficiary));

        require(presaleOpen || mainsaleOpen);
        
        if(presaleOpen) {
            // @dev Presale contributions must be Min 2 ETH and Max 500 ETH
            require(weiAmount >= 2e18  && weiAmount <= 5e20);
        }
        else {
            // @dev Mainsale contributions must be Min 0.2 ETH and Max 500 ETH
            require(weiAmount >= 2e17  && weiAmount <= 5e20);
        }
        
        // @dev Calculate token amount to be returned
        uint256 tokens = _getTokenAmount(weiAmount);
        
        // @dev Get more 10% bonus when purchasing more than 10 ETH
        if(weiAmount >= 10e18) {
            tokens = tokens.add(weiAmount.mul(500));
        }
        
        // @dev Update funds raised
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);

        // @dev Trigger `token purchase` event
        emit TokenPurchase(_beneficiary, weiAmount, tokens);

        _forwardFunds(msg.value);
    }
    
    /**
     * @dev Return an amount of tokens based on a current token rate
     * @param _weiAmount Value in wei to be converted into tokens
     */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {

        uint256 RATE;
        if(presaleOpen) {
            RATE = 7500; // @dev 1 ETH = 7500 DIP
        }
        
        if(now >= mainsaleStartTime && now < (mainsaleStartTime + 30 minutes)) {
            RATE = 6000; // @dev 1 ETH = 6000 DIP
        }
        
        if(now >= (mainsaleStartTime + 30 minutes) && now < (mainsaleStartTime + 60 minutes)) {
            RATE = 5750; // @dev 1 ETH = 5750 DIP
        }
        
        if(now >= (mainsaleStartTime + 60 minutes) && now < (mainsaleStartTime + 90 minutes)) {
            RATE = 5500; // @dev 1 ETH = 5500 DIP
        }
        
        if(now >= (mainsaleStartTime + 90 minutes) && now < (mainsaleStartTime + 120 minutes)) {
            RATE = 5250; // @dev 1 ETH = 5250 DIP
        }
        
        if(now >= (mainsaleStartTime + 120 minutes) && now <= mainsaleEndTime) {
            RATE = 5000; // @dev 1 ETH = 5000 DIP
        }

        return _weiAmount.mul(RATE);
    }
    
    /**
     * @dev Source of tokens
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    /**
     * @dev Forward ether to the fund collection wallet
     * @param _amount Amount of wei to be forwarded
     */
    function _forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }
    
    /**
     * @dev Transfer `tokens` from contract address to address `to`
     */
    function _transfer(address to, uint256 tokens) internal returns (bool success) {
        require(to != 0x0);
        require(balances[this] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[this] = balances[this].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(this,to,tokens);
        return true;
    }
    
    /**
     * @dev Allow owner to call an emergency stop
     */
    function stopTokenSale() public onlyOwner {
        Open = false;
    }
    
    /**
     * @dev Allow owner to transfer free tokens from `AIRDROP_WALLET` to multiple wallet addresses
     */
    function sendtoMultiWallets(address[] _addresses, uint256[] _values) public onlyOwner {
        require(_addresses.length == _values.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            // @dev Update balances and trigger `transfer` events
            balances[AIRDROP_WALLET] = balances[AIRDROP_WALLET].sub(_values[i]*10**uint(decimals));
            balances[_addresses[i]] = balances[_addresses[i]].add(_values[i]*10**uint(decimals));
            emit Transfer(AIRDROP_WALLET, _addresses[i], _values[i]*10**uint(decimals));
        }
    }
    
    /**
     * @dev Transfer the unsold tokens from contract address
     * @dev This function can be used only if the token sale does not reach Softcap
     */
    function drainRemainingToken(address _to, uint256 _value) public onlyOwner {
       require(now > mainsaleEndTime);
       _transfer(_to, _value);
    }
    
    /**
     * @dev Burn unsold tokens
     * @param _value The remaining amount to be burned
     */
    function burnRemainingToken(uint256 _value) public onlyOwner returns (bool) {
        balances[this] = balances[this].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(this, _value);
        emit Transfer(this, address(0x0), _value);
        return true;
    }

}