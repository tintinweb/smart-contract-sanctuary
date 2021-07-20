/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity ^0.4.18;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


/**
 * @title Basic token with transfer and deposit fees
 * @dev Basic version of StandardToken, with transfer and deposit fees.
 */
contract BasicTokenWithTransferAndDepositFees is ERC20Basic {
  using SafeMath for uint256;
  
  uint256 ONE_DAY_DURATION_IN_SECONDS = 86400;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  bool isLocked;
  
  address fee_address; 
  uint256 fee_base; 
  uint256 fee_rate;
  bool no_transfer_fee;
  
  address deposit_fee_address; 
  uint256 deposit_fee_base; 
  uint256 deposit_fee_rate;
  bool no_deposit_fee;
  
  mapping (address => bool) transfer_fee_exceptions_receiver;
  mapping (address => bool) transfer_fee_exceptions_sender;
  mapping (address => bool) deposit_fee_exceptions;
  
  mapping (address => uint256) last_deposit_fee_timestamps;
  address[] deposit_accounts;
  
  
  
  /**
   * @dev Throws if contract is locked
   */
  modifier notLocked() {
    require(!isLocked);
    _;
  }
  
  
  /**
  * Constructor that initializes default values
  * fee_address: default to the address which created the token
  * fee_base: default to 10000
  * fee_rate: default to 20 which equals 20 / 10000 = 0.20% transfer fee
  * deposit_address: default to the address which created the token
  * deposit_fee_base: default to 10000000
  * deposit_fee_rate: default to 33 which equals 33 / 10000000 = 0.00033% deposit fee
  */
  function BasicTokenWithTransferAndDepositFees() public {
    fee_address = msg.sender;
    fee_base = 10000;
    fee_rate = 20;
    no_transfer_fee = false;
    deposit_fee_address = msg.sender;
    deposit_fee_base = 10000000;
    deposit_fee_rate = 33;
    no_deposit_fee = false;
    transfer_fee_exceptions_receiver[msg.sender] = true;
    transfer_fee_exceptions_sender[msg.sender] = true;
    deposit_fee_exceptions[msg.sender] = true;
    isLocked = false;
  }
  
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  
  /**
  * @dev return the transfer fee configs
  */
  function showTransferFeeConfig() public view returns (address, uint256, uint256, bool) {
    return (fee_address, fee_base, fee_rate, no_transfer_fee);
  }
  
  /**
  * @dev return the deposit fee configs
  */
  function showDepositFeeConfig() public view returns (address, uint256, uint256, bool) {
    return (deposit_fee_address, deposit_fee_base, deposit_fee_rate, no_deposit_fee);
  }
  
  /**
  * @dev executes the deposit fees for the account _account
  */
  function executeDepositFees(address _account) internal {
    if(last_deposit_fee_timestamps[_account] != 0) {
        if(!(no_deposit_fee || deposit_fee_exceptions[_account])) {
            uint256 days_elapsed = (now - last_deposit_fee_timestamps[_account]) / ONE_DAY_DURATION_IN_SECONDS;
            uint256 deposit_fee = days_elapsed * balances[_account] * deposit_fee_rate / deposit_fee_base;
            if(deposit_fee != 0) {
                balances[_account] = balances[_account].sub(deposit_fee);
                balances[deposit_fee_address] = balances[deposit_fee_address].add(deposit_fee);
                Transfer(_account, deposit_fee_address, deposit_fee);
            }
        }
        last_deposit_fee_timestamps[_account] = last_deposit_fee_timestamps[_account].add(days_elapsed * ONE_DAY_DURATION_IN_SECONDS);
    }
  }
  
  /**
  * @dev calculates the deposit fees for the account _account
  */
  function calculateDepositFees(address _account) internal view returns (uint256) {
    if(last_deposit_fee_timestamps[_account] != 0) {
        if(!(no_deposit_fee || deposit_fee_exceptions[_account])) {
            uint256 days_elapsed = (now - last_deposit_fee_timestamps[_account]) / ONE_DAY_DURATION_IN_SECONDS;
            uint256 deposit_fee = days_elapsed * balances[_account] * deposit_fee_rate / deposit_fee_base;
            return deposit_fee;
        }
    }
    return 0;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public notLocked returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(msg.sender));
    
    /** Execution of deposit fees FROM account */
    executeDepositFees(msg.sender);
    
    /** Execution of deposit fees TO account */
    executeDepositFees(_to);
    

    /** Calculation of transfer fees */
    if(!(no_transfer_fee || transfer_fee_exceptions_receiver[_to] || transfer_fee_exceptions_sender[msg.sender])) {
        uint256 transfer_fee = 2 * _value * fee_rate / fee_base;
    }
    
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    if(!(no_transfer_fee || transfer_fee_exceptions_receiver[_to] || transfer_fee_exceptions_sender[msg.sender])) {
        balances[_to] = balances[_to].add(_value - transfer_fee);
        balances[fee_address] = balances[fee_address].add(transfer_fee);
        Transfer(msg.sender, fee_address, transfer_fee);
    } else {
        balances[_to] = balances[_to].add(_value);
    }
    
    if(last_deposit_fee_timestamps[_to] == 0) {
        last_deposit_fee_timestamps[_to] = now;
        deposit_accounts.push(_to);
    }
    
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner] - calculateDepositFees(_owner);
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicTokenWithTransferAndDepositFees {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public notLocked returns (bool) {
    require(_to != address(0));
    require(_value <= balanceOf(_from));
    require(_value <= allowed[_from][msg.sender]);
    
    /** Execution of deposit fees FROM account */
    executeDepositFees(_from);
    
    /** Execution of deposit fees TO account */
    executeDepositFees(_to);
    
    /** Calculation of transfer fees */
    if(!(no_transfer_fee || transfer_fee_exceptions_receiver[_to] || transfer_fee_exceptions_sender[_from])) {
        uint256 transfer_fee = 2 * _value * fee_rate / fee_base;
    }
    
    balances[_from] = balances[_from].sub(_value);
    if(!(no_transfer_fee || transfer_fee_exceptions_receiver[_to] || transfer_fee_exceptions_sender[_from])) {
        balances[_to] = balances[_to].add(_value - transfer_fee);
        balances[fee_address] = balances[fee_address].add(transfer_fee);
        Transfer(_from, fee_address, transfer_fee);
    } else {
        balances[_to] = balances[_to].add(_value);
    }
    
    if(last_deposit_fee_timestamps[_to] == 0) {
        last_deposit_fee_timestamps[_to] = now;
        deposit_accounts.push(_to);
    }
    
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public notLocked returns (bool) {
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
  function increaseApproval(address _spender, uint _addedValue) public notLocked returns (bool) {
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
  function decreaseApproval(address _spender, uint _subtractedValue) public notLocked returns (bool) {
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
 * SCX Token, "Digital Asset Fund"
 * Features:
 *  - ERC20 compliant
 *  - Lock-Up with variable time/amount (owner only)
 *  - Burn with variable amount (anyone)
 */
contract SCX is StandardToken, Ownable { 
    
    event Burn(address indexed burner, uint256 value);
    
    // Public variables of the token
    string public constant symbol = "SCX";
    string public constant name =  "Digital Asset Fund";
    
    uint8 public constant decimals = 8;
    
    // 100.000.000 tokens + 8 DECIMALS = 25 * 10^14 units 
    uint256 public constant INITIAL_SUPPLY = 10000000000000000;

    /**
    * Constructor that gives msg.sender all of existing tokens.
    */
    function SCX() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    
    /**
    * @dev mines new SCX tokens
    */
    function mine(uint256 _amount) public onlyOwner notLocked {
        totalSupply_ = totalSupply_.add(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        Transfer(0x0, msg.sender, _amount);
    }
    
    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint256 _value) public onlyOwner notLocked {
        require(_value <= balanceOf(msg.sender));
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        Burn(burner, _value);
    }
    
    /**
     * @dev executes the deposit fee payment for all accounts 
     */
    function executeDepositFeesForAllAccounts() public onlyOwner notLocked {
        uint arrayLength = deposit_accounts.length;
        for (uint i = 0; i < arrayLength; i++) {
            executeDepositFees(deposit_accounts[i]);
        }
    }
    
    /**
     * @dev executes the deposit fee payment for accounts from index _from to _to where _to index is excluded.
     */
    function executeDepositFeesForAccountsFromTo(uint256 _from, uint256 _to) public onlyOwner notLocked {
        uint arrayLength = deposit_accounts.length;
        require(_from <= _to);
        require(_to <= arrayLength);
        for (uint i = _from; i < _to; i++) {
            executeDepositFees(deposit_accounts[i]);
        }
    }
    
    /**
     * @dev calculate the deposit fee payment for all accounts 
     */
    function calculateDepositFeesForAllAccounts() public onlyOwner view returns (uint) {
        uint arrayLength = deposit_accounts.length;
        uint sum = 0;
        for (uint i = 0; i < arrayLength; i++) {
            sum += calculateDepositFees(deposit_accounts[i]);
        }
        return sum;
    }
    
    /**
     * @dev get all accounts which are registered for deposit fees
     */
    function depositAccounts() public onlyOwner view returns (address[]) {
        return deposit_accounts;
    }
    
    /**
    * @dev set fee base
    */
    function setFeeRate(uint256 _fee_rate) public onlyOwner notLocked {
        fee_rate = _fee_rate;
    }
    
    /**
    * @dev set fee rate
    */
    function setFeeBase(uint256 _fee_base) public onlyOwner notLocked {
        fee_base = _fee_base;
    }
    
    /**
    * @dev set fee address
    */
    function setFeeAddress(address _fee_address) public onlyOwner notLocked {
        fee_address = _fee_address;
    }
    
    /**
    * @dev set boolean for global no transfer fee
    */
    function setNoTransferFee(bool _no_transfer_fee) public onlyOwner notLocked {
        no_transfer_fee = _no_transfer_fee;
    }
    
    /**
    * @dev set fee base
    */
    function setDepositFeeRate(uint256 _deposit_fee_rate) public onlyOwner notLocked {
        deposit_fee_rate = _deposit_fee_rate;
    }
    
    /**
    * @dev set fee rate
    */
    function setDepositFeeBase(uint256 _deposit_fee_base) public onlyOwner notLocked {
        deposit_fee_base = _deposit_fee_base;
    }
    
    /**
    * @dev set fee address
    */
    function setDepositFeeAddress(address _deposit_fee_address) public onlyOwner notLocked {
        deposit_fee_address = _deposit_fee_address;
    }
    
    /**
    * @dev set boolean for global no deposit fee
    *      and possibility to reset the deposit timestamp with range from _from to _to
    */
    function setNoDepositFee(bool _no_deposit_fee, bool _reset_deposit_timestamp, uint256 _from, uint256 _to) public onlyOwner notLocked {
        no_deposit_fee = _no_deposit_fee;
        if(_reset_deposit_timestamp) {
            uint arrayLength = deposit_accounts.length;
            require(_from <= _to);
            require(_to <= arrayLength);
            for (uint i = _from; i < _to; i++) {
                last_deposit_fee_timestamps[deposit_accounts[i]] = now;
            }
        }
    }
    
    /**
    * @dev add transfer fee exception for receiver
    */
    function addTransferFeeExceptionReceiver(address _add_transfer_fee_exception) public onlyOwner notLocked {
        transfer_fee_exceptions_receiver[_add_transfer_fee_exception] = true;
    }
    
    /**
    * @dev remove transfer fee exception for receiver
    */
    function removeTransferFeeExceptionReceiver(address _remove_transfer_fee_exception) public onlyOwner notLocked {
        transfer_fee_exceptions_receiver[_remove_transfer_fee_exception] = false;
    }
    
    /**
    * @dev add transfer fee exception for sender
    */
    function addTransferFeeExceptionSender(address _add_transfer_fee_exception) public onlyOwner notLocked {
        transfer_fee_exceptions_sender[_add_transfer_fee_exception] = true;
    }
    
    /**
    * @dev remove transfer fee exception for receiver
    */
    function removeTransferFeeExceptionSender(address _remove_transfer_fee_exception) public onlyOwner notLocked {
        transfer_fee_exceptions_sender[_remove_transfer_fee_exception] = false;
    }
    
    /**
    * @dev add deposit fee exception
    */
    function addDepositFeeException(address _add_deposit_fee_exception) public onlyOwner notLocked {
        deposit_fee_exceptions[_add_deposit_fee_exception] = true;
    }
    
    /**
    * @dev remove deposit fee exception
    */
    function removeDepositFeeException(address _remove_deposit_fee_exception) public onlyOwner notLocked {
        deposit_fee_exceptions[_remove_deposit_fee_exception] = false;
        if(last_deposit_fee_timestamps[_remove_deposit_fee_exception] != 0) {
            last_deposit_fee_timestamps[_remove_deposit_fee_exception] = now;
        }
    }
    
    /**
    * @dev set isLocked attribute of the smart contract
    */
    function setIsLocked(bool _isLocked) public onlyOwner {
        isLocked = _isLocked;
    }
    
    /**
    * @dev get isLocked attribute of the smart contract
    */
    function getIsLocked() public view returns (bool) {
        return isLocked;
    }
}