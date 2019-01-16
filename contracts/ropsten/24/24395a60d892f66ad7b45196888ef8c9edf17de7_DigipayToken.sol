pragma solidity 0.4.25;


// @title Ownable
// ----------------------------------------------------------------------------
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

// @title SafeMath
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
    }
    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
    }
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
    }
    function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
    }
}

// @title Simpler Token Standard
// https://github.com/ethereum/EIPs/issues/179
// This ERC describes a simpler version of the ERC20 standard token contract
// With no allowance, approve function
// ----------------------------------------------------------------------------

contract ERC20Basic {
  function totalSupply() public constant returns (uint256);
  // The total token supply

  function balanceOf(address who) public constant returns (uint256); 
  // Get the account balance of another account with address `who`

  function transfer(address to, uint256 value) public returns (bool);
  // Send `value&#39; amount of tokens to address `to&#39;

  event Transfer(address indexed from, address indexed to, uint256 value);
  // Triggered when tokens are transferred.
}


// @title ERC20 Interface
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  // Returns the amount which `spender` is still allowed to withdraw from `owner`.

  function transferFrom(address from, address to, uint256 value) public returns (bool);
  // Send `value` amount of tokens from address `from` to address `to`.

  function approve(address spender, uint256 value) public returns (bool);
  // Allow `spender` to withdraw, multiple times, up to the `value` amount. 
  // If this function is called again it overwrites the current allowance with `value`.

  event Approval(address indexed owner, address indexed spender, uint256 value);
  // Triggered whenever approve(address spender, uint256 value) is called.
}

// @title Basic token
// ----------------------------------------------------------------------------

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
// This creates an array with all balances

// Get the token balance for address `_owner`
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    // Prevent transfer to 0x0 address

    require(balances[msg.sender] >= _value);
    // Check if the sender has enough` is not needed
    // because sub(balances[msg.sender], _value) will `throw` if this condition is not met

    require(balances[_to] + _value >= balances[_to]);
    // `Check for overflows` is not needed
    // because add(_to, _value) will `throw` if this condition is not met

    balances[msg.sender] = balances[msg.sender].sub(_value);
    // Subtract from the sender

    balances[_to] = balances[_to].add(_value);
    // Add the same to the recipient

    Transfer(msg.sender, _to, _value);
    return true;
  }

}


// @title ERC20 Token Standard
// @dev Implementation of the Basic token standard.
// @dev https://github.com/ethereum/EIPs/issues/20
// @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
// ----------------------------------------------------------------------------

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;
  // Owner of address approves the transfer of an amount to another address

  // If owner wants to authorise `_spender` to transfer or withdraw `_value` tokens to `_spender`.
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    require (_value <= _allowance);
    // Check is not needed 
    // because sub(_allowance, _value) will throw if this condition is not met

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  // Function to check the amount of tokens that an owner allowed to a spender.
  // return the amount of tokens is still available for the spender.
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // Increase the amount of tokens that an owner allowed to a spender.
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  
  // Decrease the amount of tokens that an owner allowed to a spender.
  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function pauseContribution() public view returns(bool) {
    return paused;
  }

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
 * @title DigipayToken
 * @dev   accept contributions only within a time frame.
 */
contract DigipayToken is StandardToken, Ownable, Pausable {
  using SafeMath for uint256;
  string  public symbol; 
  string  public name;
  uint8   public decimals;
  uint256 public fundsRaised;
  uint256 public preSaleTokens;
  uint256 public saleTokens;
  uint256 public teamAdvTokens;
  uint256 public bountyTokens;
  uint256 public hardCap;
  string  internal minTxSize;
  string  internal maxTxSize;
  string  public TokenPrice;
  uint    internal _totalSupply;
  uint    internal _teamamount;
  uint    internal _airdropamount;
  address public wallet;
  address public team;
  address public airdrop;
  uint256 internal presaleopeningTime;
  uint256 internal presaleclosingTime;
  uint256 internal saleopeningTime;
  uint256 internal saleclosingTime;
  bool    internal presaleOpen;
  bool    internal saleOpen;
  bool    internal Open;
  bool    public   locked;
  
  
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event Burned(address burner, uint burnedAmount);

    modifier onlyWhileOpen {
        require(now >= presaleopeningTime && now <= saleclosingTime && Open && fundsRaised <= hardCap);
        _;
    }
    
    // tokens are locked during the ICO. Allow transfer of tokens after ICO. 
    modifier onlyUnlocked() {
        require(msg.sender == wallet || !locked);
        _;
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor (address _owner, address _wallet, address _team, address _airdrop) public {
        _allocateTokens();
        _setTimes();
        
        locked = true;  // Lock the Crowdsale function during the crowdsale
        symbol = "DIP";
        name = "Digipay Token";
        decimals = 18;
        hardCap = 5 ether;
        owner = _owner;
        wallet = _wallet;
        team = _team;
        airdrop = _airdrop;
        _totalSupply = 180000000e18;
        _teamamount = 36000000e18;
        _airdropamount = 18000000e18;
        Open = true;
        balances[this] = totalSupply();
        emit Transfer(address(0x0),this, totalSupply());
        _transfer(team, _teamamount);
        _transfer(airdrop, _airdropamount);
        
    }

    

    function updatewallet(address _wallet) public onlyOwner() {
        wallet = _wallet;
    }

    
    function unlock() public onlyOwner {
        locked = false;
    }

    function lock() public onlyOwner {
        locked = true;
    }

    
    function _setTimes() internal{   
        presaleopeningTime        = 1540116000; // 06th Nov 2018 00:00:00 GMT 
        presaleclosingTime        = 1540117800; // 30th Dec 2018 23:59:59 GMT
        saleopeningTime           = 1540119600; // 31st Dec 2018 00:00:00 GMT
        saleclosingTime           = 1540121400; // 30th Mar 2019 23:59:59 GMT
    }
  
    function _allocateTokens() internal{
        
        preSaleTokens         = 36000000;   // 20%
        saleTokens            = 90000000;   // 50%
        teamAdvTokens         = 36000000;   // 20%
        bountyTokens          = 18000000;   // 10%
        hardCap               = 20000;      // 20000 eths or 20000*10^18 weis 
        minTxSize             = "0,5 ETH"; // (0,5 ETH)
        maxTxSize             = "1000 ETH"; // (1000 ETH)
        TokenPrice            = "$0.05";
        presaleOpen           = true;
    }

    function totalSupply() public constant returns (uint256){
        return _totalSupply;
    }

    /**
     * @dev override transfer token for a specified address to add onlyUnlocked
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value) public onlyUnlocked returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * @dev override transferFrom token for a specified address to add onlyUnlocked
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transferFrom(address _from, address _to, uint _value) public onlyUnlocked returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    
    function _checkOpenings() internal{
        
        if(now >= presaleopeningTime && now <= presaleclosingTime){
          presaleOpen = true;
          saleOpen = false;
        }
        else if(now >= saleopeningTime && now <= saleclosingTime){
            presaleOpen = false;
            saleOpen = true;
        }
        else{
          presaleOpen = false;
          saleOpen = false;
        }
    }
    
    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable onlyWhileOpen whenNotPaused {
    
        uint256 weiAmount = msg.value;
    
        _preValidatePurchase(_beneficiary, weiAmount);
    
        _checkOpenings();

        require(presaleOpen || saleOpen);
        
        if(presaleOpen){
            require(weiAmount >= 2e18  && weiAmount <= 2e20 ,"FUNDS should be MIN 2 ETH and Max 200 ETH");
        }
        else {
            require(weiAmount >= 2e17  && weiAmount <= 5e20 ,"FUNDS should be MIN 0,2 ETH and Max 500 ETH");
        }
        
        uint256 tokens = _getTokenAmount(weiAmount);
        
        if(weiAmount >= 10e18){ // greater than 50 eths
            // 10% extra discount
            tokens = tokens.add((tokens.mul(10)).div(100));
        }
        
        // update state
        fundsRaised = fundsRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(this, _beneficiary, weiAmount, tokens);

        _forwardFunds(msg.value);
    }
    
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal{
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        // require(_weiAmount >= 2e18  && _weiAmount <= 2e20 ,"FUNDS should be MIN 2 ETH and Max 200 ETH");
    }
  
    function _getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
        uint256 rate;
        if(presaleOpen){
            rate = 7500; //per wei
        }
        else if(saleOpen){
            rate = 5000; //per wei
        }
        
        return _weiAmount.mul(rate);
    }
    
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        _transfer(_beneficiary, _tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
    
    function _forwardFunds(uint256 _amount) internal {
        wallet.transfer(_amount);
    }
    
    function _transfer(address to, uint256 tokens) internal returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(to != 0x0);
        require(balances[this] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[this] = balances[this].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(this,to,tokens);
        return true;
    }
    
    function freeTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner{
       _transfer(_beneficiary, _tokenAmount);
    }
    
    function stopICO() public onlyOwner{
        Open = false;
    }
    
    function multipleTokensSend (address[] _addresses, uint256[] _values) public onlyOwner{
        for (uint256 i = 0; i < _addresses.length; i++){
            _transfer(_addresses[i], _values[i]*10**uint(decimals));
        }
    }


    event Burn(address indexed burner, uint tokens);

    /**
     * @dev burn tokens
     * @param tokens The amount to be burned.
     * @return always true (necessary in case of override)
     */
    function burn(address burner, uint256 tokens) public onlyOwner returns (bool){
        balances[burner] = balances[burner].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        Burn(burner, tokens);
        Transfer(burner, address(0x0), tokens);
        return true;
    }

    /**
     * @dev burn tokens in the behalf of someone
     * @param from The address of the owner of the token.
     * @param tokens The amount to be burned.
     * @return always true (necessary in case of override)
     */
    function burnFrom(address from, uint256 tokens) public onlyOwner returns(bool){
        assert(transferFrom(from, msg.sender, tokens));
        return burn(from, tokens);
    }
    
    /**
    * function burnRemainingTokens() public onlyOwner{
    *     balances[this] = 0;
    * }
    */
}