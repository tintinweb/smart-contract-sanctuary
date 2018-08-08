pragma solidity 0.4.19;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: contracts/BurnableToken.sol

/**
* @title Customized Burnable Token
* @dev Token that can be irreversibly burned (destroyed).
*/
contract BurnableToken is StandardToken, Ownable {

    event Burn(address indexed burner, uint256 amount);

    /**
    * @dev Anybody can burn a specific amount of their tokens.
    * @param _amount The amount of token to be burned.
    */
    function burn(uint256 _amount) public {
        burnInternal(msg.sender, _amount);
    }

    /**
    * @dev Owner can burn a specific amount of tokens of other token holders.
    * @param _from The address of token holder whose tokens to be burned.
    * @param _amount The amount of token to be burned.
    */
    function burnFrom(address _from, uint256 _amount) public onlyOwner {
        burnInternal(_from, _amount);
    }

    /**
    * @dev Burns a specific amount of tokens of a token holder.
    * @param _from The address of token holder whose tokens are to be burned.
    * @param _amount The amount of token to be burned.
    */
    function burnInternal(address _from, uint256 _amount) internal {
        require(_from != address(0));
        require(_amount > 0);
        require(_amount <= balances[_from]);
        // no need to require _amount <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        balances[_from] = balances[_from].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        Transfer(_from, address(0), _amount);
        Burn(_from, _amount);
    }

}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
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

// File: contracts/GiftToken.sol

contract GiftToken is BurnableToken, Pausable {

    string public name = "Giftcoin";
    string public symbol = "GIFT";
    uint8 public decimals = 18;
  
    uint256 public initialTotalSupply = uint256(1e8) * (uint256(10) ** decimals);

    address private addressIco;

    modifier onlyIco() {
        require(msg.sender == addressIco);
        _;
    }

    /**
    * @dev Create GiftToken contract and set pause
    * @param _ico The address of ICO contract.
    */
    function GiftToken(address _ico) public {
        pause();
        setIcoAddress(_ico);

        totalSupply_ = initialTotalSupply;
        balances[_ico] = balances[_ico].add(initialTotalSupply);
        Transfer(address(0), _ico, initialTotalSupply);
    }

    function setIcoAddress(address _ico) public onlyOwner {
        require(_ico != address(0));
        // to change the ICO address firstly transfer the tokens to the new ICO
        require(balanceOf(addressIco) == 0);

        addressIco = _ico;
  
        // the ownership of the token needs to be transferred to the crowdsale contract
        // but it can be reclaimed using transferTokenOwnership() function
        // or along withdrawal of the funds
        transferOwnership(_ico);
    }

    /**
    * @dev Transfer token for a specified address with pause feature for owner.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another with pause feature for owner.
    * @dev Only applies when the transfer is allowed by the owner.
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    /**
    * @dev Transfer tokens from ICO address to another address.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transferFromIco(address _to, uint256 _value) public onlyIco returns (bool) {
        return super.transfer(_to, _value);
    }
}

// File: contracts/Whitelist.sol

/**
 * @title Whitelist contract
 * @dev Whitelist for wallets, with additional data for every wallet.
*/
contract Whitelist is Ownable {
    struct WalletInfo {
        string data;
        bool whitelisted;
        uint256 createdTimestamp;
    }

    address public backendAddress;

    mapping(address => WalletInfo) public whitelist;

    uint256 public whitelistLength = 0;

    /**
    * @dev Sets the backend address for automated operations.
    * @param _backendAddress The backend address to allow.
    */
    function setBackendAddress(address _backendAddress) public onlyOwner {
        require(_backendAddress != address(0));
        backendAddress = _backendAddress;
    }

    /**
    * @dev Allows the function to be called only by the owner and backend.
    */
    modifier onlyPrivilegedAddresses() {
        require(msg.sender == owner || msg.sender == backendAddress);
        _;
    }

    /**
    * @dev Add wallet to whitelist.
    * @dev Accept request from privilege adresses only.
    * @param _wallet The address of wallet to add.
    * @param _data The checksum of additional wallet data.
    */  
    function addWallet(address _wallet, string _data) public onlyPrivilegedAddresses {
        require(_wallet != address(0));
        require(!isWhitelisted(_wallet));
        whitelist[_wallet].data = _data;
        whitelist[_wallet].whitelisted = true;
        whitelist[_wallet].createdTimestamp = now;
        whitelistLength++;
    }

    /**
    * @dev Update additional data for whitelisted wallet.
    * @dev Accept request from privilege adresses only.
    * @param _wallet The address of whitelisted wallet to update.
    * @param _data The checksum of new additional wallet data.
    */      
    function updateWallet(address _wallet, string _data) public onlyPrivilegedAddresses {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        whitelist[_wallet].data = _data;
    }

    /**
    * @dev Remove wallet from whitelist.
    * @dev Accept request from privilege adresses only.
    * @param _wallet The address of whitelisted wallet to remove.
    */  
    function removeWallet(address _wallet) public onlyPrivilegedAddresses {
        require(_wallet != address(0));
        require(isWhitelisted(_wallet));
        delete whitelist[_wallet];
        whitelistLength--;
    }

    /**
    * @dev Check the specified wallet whether it is in the whitelist.
    * @param _wallet The address of wallet to check.
    */ 
    function isWhitelisted(address _wallet) public view returns (bool) {
        return whitelist[_wallet].whitelisted;
    }

    /**
    * @dev Get the checksum of additional data for the specified whitelisted wallet.
    * @param _wallet The address of wallet to get.
    */ 
    function walletData(address _wallet) public view returns (string) {
        return whitelist[_wallet].data;
    }

    /**
    * @dev Get the creation timestamp for the specified whitelisted wallet.
    * @param _wallet The address of wallet to get.
    */
    function walletCreatedTimestamp(address _wallet) public view returns (uint256) {
        return whitelist[_wallet].createdTimestamp;
    }
}

// File: contracts/GiftCrowdsale.sol

contract GiftCrowdsale is Pausable {
    using SafeMath for uint256;

    uint256 public startTimestamp = 0;

    uint256 public endTimestamp = 0;

    uint256 public exchangeRate = 0;

    uint256 public tokensSold = 0;

    uint256 constant public minimumInvestment = 25e16; // 0.25 ETH

    uint256 public minCap = 0;

    uint256 public endFirstPeriodTimestamp = 0;
    uint256 public endSecondPeriodTimestamp = 0;
    uint256 public endThirdPeriodTimestamp = 0;

    GiftToken public token;
    Whitelist public whitelist;

    mapping(address => uint256) public investments;

    modifier beforeSaleOpens() {
        require(now < startTimestamp);
        _;
    }

    modifier whenSaleIsOpen() {
        require(now >= startTimestamp && now < endTimestamp);
        _;
    }

    modifier whenSaleHasEnded() {
        require(now >= endTimestamp);
        _;
    }

    /**
    * @dev Constructor for GiftCrowdsale contract.
    * @dev Set first owner who can manage whitelist.
    * @param _startTimestamp uint256 The start time ico.
    * @param _endTimestamp uint256 The end time ico.
    * @param _exchangeRate uint256 The price of the Gift token.
    * @param _minCap The minimum amount of tokens sold required for the ICO to be considered successful.
    */
    function GiftCrowdsale (
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _exchangeRate,
        uint256 _minCap
    )
        public
    {
        require(_startTimestamp >= now && _endTimestamp > _startTimestamp);
        require(_exchangeRate > 0);

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;

        exchangeRate = _exchangeRate;

        endFirstPeriodTimestamp = _startTimestamp.add(1 days);
        endSecondPeriodTimestamp = _startTimestamp.add(1 weeks);
        endThirdPeriodTimestamp = _startTimestamp.add(2 weeks);

        minCap = _minCap;

        pause();
    }

    function discount() public view returns (uint256) {
        if (now > endThirdPeriodTimestamp)
            return 0;
        if (now > endSecondPeriodTimestamp)
            return 5;
        if (now > endFirstPeriodTimestamp)
            return 15;
        return 25;
    }

    function bonus(address _wallet) public view returns (uint256) {
        uint256 _created = whitelist.walletCreatedTimestamp(_wallet);
        if (_created > 0 && _created < startTimestamp) {
            return 10;
        }
        return 0;
    }

    /**
    * @dev Function for sell tokens.
    * @dev Sells tokens only for wallets from Whitelist while ICO lasts
    */
    function sellTokens() public payable whenSaleIsOpen whenWhitelisted(msg.sender) whenNotPaused {
        require(msg.value > minimumInvestment);
        uint256 _bonus = bonus(msg.sender);
        uint256 _discount = discount();
        uint256 tokensAmount = (msg.value).mul(exchangeRate).mul(_bonus.add(100)).div((100 - _discount));

        token.transferFromIco(msg.sender, tokensAmount);

        tokensSold = tokensSold.add(tokensAmount);

        addInvestment(msg.sender, msg.value);
    }

    /**
    * @dev Fallback function allowing the contract to receive funds
    */
    function() public payable {
        sellTokens();
    }

    /**
    * @dev Function for funds withdrawal
    * @dev transfers funds to specified wallet once ICO is ended
    * @param _wallet address wallet address, to  which funds  will be transferred
    */
    function withdrawal(address _wallet) external onlyOwner whenSaleHasEnded {
        require(_wallet != address(0));
        _wallet.transfer(this.balance);

        token.transferOwnership(msg.sender);
    }

    /**
    * @dev Function for manual token assignment (token transfer from ICO to requested wallet)
    * @param _to address The address which you want transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function assignTokens(address _to, uint256 _value) external onlyOwner {
        token.transferFromIco(_to, _value);

        tokensSold = tokensSold.add(_value);
    }

    /**
    * @dev Add new investment to the ICO investments storage.
    * @param _from The address of a ICO investor.
    * @param _value The investment received from a ICO investor.
    */
    function addInvestment(address _from, uint256 _value) internal {
        investments[_from] = investments[_from].add(_value);
    }

    /**
    * @dev Function to return money to one customer, if mincap has not been reached
    */
    function refundPayment() external whenWhitelisted(msg.sender) whenSaleHasEnded {
        require(tokensSold < minCap);
        require(investments[msg.sender] > 0);

        token.burnFrom(msg.sender, token.balanceOf(msg.sender));

        uint256 investment = investments[msg.sender];
        investments[msg.sender] = 0;
        (msg.sender).transfer(investment);
    }

    /**
    * @dev Allows the current owner to transfer control of the token contract from ICO to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        token.transferOwnership(_newOwner);
    }

    function updateIcoEnding(uint256 _endTimestamp) public onlyOwner {
        endTimestamp = _endTimestamp;
    }

    modifier whenWhitelisted(address _wallet) {
        require(whitelist.isWhitelisted(_wallet));
        _;
    }

    function init(address _token, address _whitelist) public onlyOwner {
        require(_token != address(0) && _whitelist != address(0));
        // function callable only once
        require(token == address(0) && whitelist == address(0));
        // required for refund purposes (token.burnFrom())
        require(Ownable(_token).owner() == address(this));

        token = GiftToken(_token);
        whitelist = Whitelist(_whitelist);

        unpause();
    }

    /**
    * @dev Owner can&#39;t unpause the crowdsale before calling init().
    */
    function unpause() public onlyOwner whenPaused {
        require(token != address(0) && whitelist != address(0));
        super.unpause();
    }

    /**
    * @dev Owner can change the exchange rate before ICO begins
    * @param _exchangeRate new exchange rate
    */
    function setExchangeRate(uint256 _exchangeRate) public onlyOwner beforeSaleOpens {
        require(_exchangeRate > 0);

        exchangeRate = _exchangeRate;
    }
}