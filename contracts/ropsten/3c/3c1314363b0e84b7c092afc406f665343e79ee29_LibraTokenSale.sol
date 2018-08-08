pragma solidity ^0.4.19;

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

// File: contracts/LibraToken.sol

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract LibraToken is StandardToken {

    string public constant name = "LibraToken"; // solium-disable-line uppercase
    string public constant symbol = "LBA"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    uint256 public constant INITIAL_SUPPLY = (10 ** 9) * (10 ** uint256(decimals));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    function LibraToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

}

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

// File: contracts/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
    * @dev Throws if called by any account that&#39;s not whitelisted.
    */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
    * @dev add an address to the whitelist
    * @param addr address
    * @return true if the address was added to the whitelist, false if the address was already in the whitelist 
    */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            WhitelistedAddressAdded(addr);
            success = true; 
        }
    }

    /**
    * @dev add addresses to the whitelist
    * @param addrs addresses
    * @return true if at least one address was added to the whitelist, 
    * false if all addresses were already in the whitelist  
    */
    function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
    * @dev remove an address from the whitelist
    * @param addr address
    * @return true if the address was removed from the whitelist, 
    * false if the address wasn&#39;t in the whitelist in the first place 
    */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
    * @dev remove addresses from the whitelist
    * @param addrs addresses
    * @return true if at least one address was removed from the whitelist, 
    * false if all addresses weren&#39;t in the whitelist in the first place
    */
    function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}

// File: contracts/LibraTokenSale.sol

/**
* @title LibraTokenSale
* @dev LibraTokenSale is a base contract for managing the Libra token sale,
* allowing investors to purchase tokens with ether. This contract implements
* such functionality in its most fundamental form and can be extended to provide additional
* functionality and/or custom behavior.
* The external interface represents the basic interface for purchasing tokens, and conform
* the base architecture for token sales. They are *not* intended to be modified / overriden.
* The internal interface conforms the extensible and modifiable surface of token sales. Override
* the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
* behavior.
*/

contract LibraTokenSale is Whitelist {
    using SafeMath for uint256;

    // Phase blocktimes
    uint256 depositPhaseStartTime;
    uint256 depositPhaseEndTime;
    uint256 excessPhaseStartTime;

    // The token being sold
    LibraToken public token;

    // How many LBA tokens being sold: 40,000,000 LBA
    uint256 constant public tokenSaleSupply = (4 * (10 ** 7));

    // How many LBA units being sold: 40,000,000 LBA * (10 ** 18) decimals
    uint256 constant public tokenSaleSupplyUnits = tokenSaleSupply * (10 ** 18);

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei or LBA tokens per ETH
    // LBA units per wei = LBA tokens per ETH
    uint256 public rate;

    // Amount of wei raised
    uint256 public totalWeiRaised;

    // Amount of wei deposited
    uint256 public totalWeiDeposited;

    // Value of public sale token supply in wei: tokenSaleSupplyUnits / rate
    uint256 public weiCap;

    // Wei cap for each whitelisted address
    uint256 public weiCapPerAddress;

    // Check if the ETH cap is set
    bool public individualWeiCapSet = false;

    // Amount of wei deposited by an address
    mapping(address => uint256) depositAmount;

    // Number of investors
    uint256 public numInvestors = 0;

    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * Event for deposit logging
    * @param _depositor who deposited the ETH
    * @param _amount amount of ETH deposited
    */
    event Deposit(address indexed _depositor, uint256 _amount);

    /**
    * Event for withdraw logging
    * @param _depositor who withdrew the ETH
    * @param _amount amount of ETH withdrawn
    */
    event Withdraw(address indexed _depositor, uint256 _amount);

    /**
    * Event for returning excess wei
    * @param _from who receives return
    * @param _value amount of wei returned
    */
    event ReturnExcessETH(address indexed _from, uint256 _value);

    /*
    * @dev Reverts if not in deposit time range or if the token sale contract does not have the appropriate token balance.
    */
    modifier onlyWhileDepositPhaseOpen {
        require(block.timestamp >= depositPhaseStartTime && block.timestamp <= depositPhaseEndTime);
        require(token.balanceOf(this) >= tokenSaleSupplyUnits);
        _;
    }

    /**
    * @dev Reverts if not in processing time range.
    */
    modifier onlyWhileProcessingPhaseOpen {
        require(block.timestamp > depositPhaseEndTime && block.timestamp < excessPhaseStartTime);
        _;
    }

    /**
    * @dev Reverts if there are unprocessed tokens
    */
    modifier onlyWhileExcessPhaseOpen {
        require(block.timestamp > excessPhaseStartTime);
        _;
    }

    /**
    * @dev Reverts if the individual cap is not set
    */
    modifier OnlyIfIndividualWeiCapSet {
        require(individualWeiCapSet == true);
        _;
    }

    /**
    * @param _rate Number of token units a buyer gets per ETH
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    * @param _depositPhaseStartTime unix timestamp of start time for deposit phase
    * @param _depositPhaseEndTime unix timestamp of end time for deposit phase
    */
    function LibraTokenSale(
        uint256 _rate,
        address _wallet,
        ERC20 _token,
        uint256 _depositPhaseStartTime,
        uint256 _depositPhaseEndTime,
        uint256 _excessPhaseStartTime
        ) public {

        require(_rate > 0);
        require(_wallet != address(0));
        require(_token != address(0));

        rate = _rate;
        wallet = _wallet;
        token = LibraToken(_token);

        depositPhaseStartTime = _depositPhaseStartTime;
        depositPhaseEndTime = _depositPhaseEndTime;
        excessPhaseStartTime = _excessPhaseStartTime;

        weiCap = tokenSaleSupplyUnits.div(rate); // total tokens / token units per wei
    }

    // -----------------------------------------
    // Token sale external interface
    // -----------------------------------------

    /**
    * @dev Remove from whitelist, added refund functionality
    */
    function removeAddressFromWhitelist(address _addr) onlyOwner onlyWhileDepositPhaseOpen public returns(bool success) {
        if (super.removeAddressFromWhitelist(_addr)) {
            uint256 refundAmount = depositAmount[_addr];
            depositAmount[_addr] = 0;
            if (refundAmount > 0) {
                numInvestors = numInvestors.sub(1);
                _addr.transfer(refundAmount);
            }
            return true;
        } else {
            return false;
        }
    }

    /**
    * @dev Update the rate for token purchase and consequently the weiCap
    */
    function updateRate(uint256 _newRate) onlyOwner onlyWhileDepositPhaseOpen public returns(bool success) {
        rate = _newRate;
        weiCap = tokenSaleSupplyUnits.div(rate);
        return true;
    }

    /**
    * @dev Update the weiCapPerAddress for deposits
    */
    function setWeiCapPerAddress(uint256 _newWeiCapPerAddress) onlyOwner onlyWhileProcessingPhaseOpen public returns(bool success) {
        require(_newWeiCapPerAddress > 0);
        weiCapPerAddress = _newWeiCapPerAddress;
        individualWeiCapSet = true;
        return true;
    }

    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        deposit();
    }

    /**
    * @dev Handles user deposit internally
    */
    function deposit() public payable onlyWhileDepositPhaseOpen onlyWhitelisted {
        address user = msg.sender;
        if (depositAmount[user] == 0) {
            numInvestors = numInvestors.add(1);
        }
        depositAmount[user] = depositAmount[user].add(msg.value);
        totalWeiDeposited = totalWeiDeposited.add(msg.value);
        Deposit(user, msg.value);
    }

    /**
    * @dev Handle user withdrawal
    */
    function withdraw() external onlyWhileDepositPhaseOpen {
        address user = msg.sender;
        uint256 withdrawAmount = depositAmount[user];
        require(withdrawAmount > 0);
        depositAmount[user] = 0;
        totalWeiDeposited = totalWeiDeposited.sub(withdrawAmount);
        numInvestors = numInvestors.sub(1);
        Withdraw(user, withdrawAmount);
        user.transfer(withdrawAmount);
    }

    /**
    * @dev Return excess tokens and ETH
    */
    function returnExcess(address _addr) public onlyOwner onlyWhileExcessPhaseOpen OnlyIfIndividualWeiCapSet {
        uint256 totalExcessTokens = token.balanceOf(this);
        require(token.transfer(_addr, totalExcessTokens));
        wallet.transfer(address(this).balance);
    }

    /**
    * @dev low level process ***DO NOT OVERRIDE***
    * Note: Buyers can collect tokens after depositing, even after Libra Team has revoked the buyer from whitelist (after buyer&#39;s deposit)
    */
    function collectTokens() public onlyWhileProcessingPhaseOpen OnlyIfIndividualWeiCapSet {
        address user = msg.sender;
        uint256 weiAmount = depositAmount[user];
        _preValidatePurchase(user, weiAmount);

        totalWeiDeposited = totalWeiDeposited.sub(weiAmount);

        uint256 refund = 0;
        if(weiAmount > weiCapPerAddress){
            refund = weiAmount.sub(weiCapPerAddress);
            weiAmount = weiCapPerAddress;
        }

        // Calculate tokens purchased
        uint256 tokens = weiAmount.mul(rate);

        // Update state
        totalWeiRaised = totalWeiRaised.add(weiAmount);

        _processPurchase(user, tokens, refund);
        TokenPurchase(user, user, weiAmount, tokens);

        _forwardFunds(weiAmount);
    }

    /**
    * @dev low level process ***DO NOT OVERRIDE***
    * Note: Owner can collect manually distribute tokens to investors, even after Libra Team has revoked the buyer from whitelist (after buyer&#39;s deposit)
    */
    function distributeTokens(address addr) public onlyOwner onlyWhileProcessingPhaseOpen OnlyIfIndividualWeiCapSet {
        address user = addr;
        uint256 weiAmount = depositAmount[user];
        _preValidatePurchase(user, weiAmount);

        totalWeiDeposited = totalWeiDeposited.sub(weiAmount);

        uint256 refund = 0;
        if(weiAmount > weiCapPerAddress){
            refund = weiAmount.sub(weiCapPerAddress);
            weiAmount = weiCapPerAddress;
        }

        // Calculate tokens purchased
        uint256 tokens = weiAmount.mul(rate);

        // Update state
        totalWeiRaised = totalWeiRaised.add(weiAmount);

        _processPurchase(user, tokens, refund);
        TokenPurchase(user, user, weiAmount, tokens);

        _forwardFunds(weiAmount);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param user Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    * Note: This function also prevents people who haven&#39;t deposited from collecting tokens
    */
    function _preValidatePurchase(address user, uint256 _weiAmount) pure internal {
        require(user != address(0));
        require(_weiAmount > 0);
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the token sale ultimately gets and sends its tokens.
    * @param user Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address user, uint256 _tokenAmount) internal {
        require(depositAmount[user] > 0);
        depositAmount[user] = 0; // Reentrancy protection
        require(token.transfer(user, _tokenAmount));
    }

    /**
    * @dev Refunds excess ether when processing purchase
    * @param user Address performing the token purchase
    * @param _refundAmount Amount of wei to be refunded
    */
    function _refundExcess(address user, uint256 _refundAmount) internal {
        user.transfer(_refundAmount);
        ReturnExcessETH(user, _refundAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param user Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    * @param _refundAmount Wei to be refunded
    */
    function _processPurchase(address user, uint256 _tokenAmount, uint256 _refundAmount) internal {
        _deliverTokens(user, _tokenAmount);
        if (_refundAmount > 0) {
            _refundExcess(user, _refundAmount);
        }
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    * @param value amount of wei to forward
    */
    function _forwardFunds(uint256 value) internal {
        wallet.transfer(value);
    }

    // -----------------------------------------
    // Constant functions
    // -----------------------------------------

    /**
    * @dev Checks whether the phase in which the deposits are accepted has already elapsed.
    * @return Whether deposit phase has elapsed
    */
    function depositsClosed() public view returns (bool) {
        return block.timestamp > depositPhaseEndTime;
    }

    function depositsOpen() public view returns (bool) {
        return  block.timestamp >= depositPhaseStartTime &&
            block.timestamp <= depositPhaseEndTime &&
            token.balanceOf(this) >= tokenSaleSupplyUnits;
    }

    /**
    * @dev Returns the amount of wei a user has deposited
    * @return Whether deposit phase has elapsed
    */
    function getDepositAmount() public view returns (uint256) {
        return depositAmount[msg.sender];
    }
}