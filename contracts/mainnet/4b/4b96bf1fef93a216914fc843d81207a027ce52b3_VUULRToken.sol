pragma solidity ^0.4.19;


/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
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
    emit Transfer(msg.sender, _to, _value);
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
    emit Transfer(_from, _to, _value);
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
    emit Approval(msg.sender, _spender, _value);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
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


contract OperatableBasic {
    function setPrimaryOperator (address addr) public;
    function setSecondaryOperator (address addr) public;
    function isPrimaryOperator(address addr) public view returns (bool);
    function isSecondaryOperator(address addr) public view returns (bool);
}

contract Operatable is Ownable, OperatableBasic {
    address public primaryOperator;
    address public secondaryOperator;

    modifier canOperate() {
        require(msg.sender == primaryOperator || msg.sender == secondaryOperator || msg.sender == owner);
        _;
    }

    function Operatable() public {
        primaryOperator = owner;
        secondaryOperator = owner;
    }

    function setPrimaryOperator (address addr) public onlyOwner {
        primaryOperator = addr;
    }

    function setSecondaryOperator (address addr) public onlyOwner {
        secondaryOperator = addr;
    }

    function isPrimaryOperator(address addr) public view returns (bool) {
        return (addr == primaryOperator);
    }

    function isSecondaryOperator(address addr) public view returns (bool) {
        return (addr == secondaryOperator);
    }
}


contract XClaimable is Claimable {

    function cancelOwnershipTransfer() onlyOwner public {
        pendingOwner = owner;
    }

}

contract VUULRTokenConfig {
    string public constant NAME = "Vuulr Token";
    string public constant SYMBOL = "VUU";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}



contract Salvageable is Operatable {
    // Salvage other tokens that are accidentally sent into this token
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public canOperate {
        if (address(oddToken) == address(0)) {
            owner.transfer(amount);
            return;
        }
        oddToken.transfer(owner, amount);
    }
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}


contract VUULRToken is XClaimable, PausableToken, VUULRTokenConfig, Salvageable {
    using SafeMath for uint;

    string public name = NAME;
    string public symbol = SYMBOL;
    uint8 public decimals = DECIMALS;
    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function mint(address _to, uint _amount) canOperate canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) 
    {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

}


contract VUULRVesting is XClaimable, Salvageable {
    using SafeMath for uint;

    struct VestingSchedule {
        uint lockPeriod;        // Amount of time in seconds between withdrawal periods. (EG. 6 months or 1 month)
        uint numPeriods;        // number of periods until done.
        uint tokens;       // Total amount of tokens to be vested.
        uint amountWithdrawn;   // The amount that has been withdrawn.
        uint startTime;
    }

    bool public started;
    

    VUULRToken public vestingToken;
    address public vestingWallet;
    uint public vestingOwing;
    uint public decimals;


    // Vesting schedule attached to a specific address.
    mapping (address => VestingSchedule) public vestingSchedules;

    event VestingScheduleRegistered(address registeredAddress, address theWallet, uint lockPeriod,  uint tokens);
    event Started(uint start);
    event Withdraw(address registeredAddress, uint amountWithdrawn);
    event VestingRevoked(address revokedAddress, uint amountWithdrawn, uint amountRefunded);
    event VestingAddressChanged(address oldAddress, address newAddress);

    function VUULRVesting(VUULRToken _vestingToken, address _vestingWallet ) public {
        require(_vestingToken != address(0));
        require(_vestingWallet != address(0));
        vestingToken = _vestingToken;
        vestingWallet = _vestingWallet;
        decimals = uint(vestingToken.decimals());
    }

    // Start vesting, Vesting starts now !!!
    // as long as TOKEN IS NOT PAUSED
    function start() public onlyOwner {
        require(!started);
        require(!vestingToken.paused());
        started = true;
        emit Started(now);

        // catch up on owing transfers
        if (vestingOwing > 0) {
            require(vestingToken.transferFrom(vestingWallet, address(this), vestingOwing));
            vestingOwing = 0;
        }
    }

    // Register a vesting schedule to transfer SENC from a group SENC wallet to an individual
    // wallet. For instance, from pre-sale wallet to individual presale contributor address.
    function registerVestingSchedule(address _newAddress, uint _numDays,
        uint _numPeriods, uint _tokens, uint startFrom) 
        public 
        canOperate 
    {

        uint _lockPeriod;
        
        // Let&#39;s not allow the common mistake....
        require(_newAddress != address(0));
        // Check that beneficiary is not already registered
        require(vestingSchedules[_newAddress].tokens == 0);

        // Some lock period sanity checks.
        require(_numDays > 0); 
        require(_numPeriods > 0);

        _lockPeriod = _numDays * 1 days;

        vestingSchedules[_newAddress] = VestingSchedule({
            lockPeriod : _lockPeriod,
            numPeriods : _numPeriods,
            tokens : _tokens,
            amountWithdrawn : 0,
            startTime : startFrom
        });
        if (started) {
            require(vestingToken.transferFrom(vestingWallet, address(this), _tokens));
        } else {
            vestingOwing = vestingOwing.add(_tokens);
        }

        emit VestingScheduleRegistered(_newAddress, vestingWallet, _lockPeriod, _tokens);
    }

    // whichPeriod returns the vesting period we are in 
    // 0 - before start or not eligible
    // 1 - n : the timeperiod we are in
    function whichPeriod(address whom, uint time) public view returns (uint period) {
        VestingSchedule memory v = vestingSchedules[whom];
        if (started && (v.tokens > 0) && (time >= v.startTime)) {
            period = Math.min256(1 + (time - v.startTime) / v.lockPeriod,v.numPeriods);
        }
    }

    // Returns the amount of tokens you can withdraw
    function vested(address beneficiary) public view returns (uint _amountVested) {
        VestingSchedule memory _vestingSchedule = vestingSchedules[beneficiary];
        // If it&#39;s past the end time, the whole amount is available.
        if ((_vestingSchedule.tokens == 0) || (_vestingSchedule.numPeriods == 0) || (now < _vestingSchedule.startTime)){
            return 0;
        }
        uint _end = _vestingSchedule.lockPeriod.mul(_vestingSchedule.numPeriods);
        if (now >= _vestingSchedule.startTime.add(_end)) {
            return _vestingSchedule.tokens;
        }
        uint period = now.sub(_vestingSchedule.startTime).div(_vestingSchedule.lockPeriod)+1;
        if (period >= _vestingSchedule.numPeriods) {
            return _vestingSchedule.tokens;
        }
        uint _lockAmount = _vestingSchedule.tokens.div(_vestingSchedule.numPeriods);

        uint vestedAmount = period.mul(_lockAmount);
        return vestedAmount;
    }


    function withdrawable(address beneficiary) public view returns (uint amount) {
        return vested(beneficiary).sub(vestingSchedules[beneficiary].amountWithdrawn);
    }

    function withdrawVestedTokens() public {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        if (vestingSchedule.tokens == 0)
            return;

        uint _vested = vested(msg.sender);
        uint _withdrawable = withdrawable(msg.sender);
        vestingSchedule.amountWithdrawn = _vested;

        if (_withdrawable > 0) {
            require(vestingToken.transfer(msg.sender, _withdrawable));
            emit Withdraw(msg.sender, _withdrawable);
        }
    }

    function revokeSchedule(address _addressToRevoke, address _addressToRefund) public onlyOwner {
        require(_addressToRefund != 0x0);

        uint _withdrawable = withdrawable(_addressToRevoke);
        uint _refundable = vestingSchedules[_addressToRevoke].tokens.sub(vested(_addressToRevoke));

        delete vestingSchedules[_addressToRevoke];
        if (_withdrawable > 0)
            require(vestingToken.transfer(_addressToRevoke, _withdrawable));
        if (_refundable > 0)
            require(vestingToken.transfer(_addressToRefund, _refundable));
        emit VestingRevoked(_addressToRevoke, _withdrawable, _refundable);
    }

    function changeVestingAddress(address _oldAddress, address _newAddress) public onlyOwner {
        VestingSchedule memory vestingSchedule = vestingSchedules[_oldAddress];
        require(vestingSchedule.tokens > 0);
        require(_newAddress != 0x0);
        require(vestingSchedules[_newAddress].tokens == 0x0);

        VestingSchedule memory newVestingSchedule = vestingSchedule;
        delete vestingSchedules[_oldAddress];
        vestingSchedules[_newAddress] = newVestingSchedule;

        emit VestingAddressChanged(_oldAddress, _newAddress);
    }

    function emergencyERC20Drain( ERC20 oddToken, uint amount ) public canOperate {
        // Cannot withdraw VUULRToken if vesting started
        require(!started || address(oddToken) != address(vestingToken));
        super.emergencyERC20Drain(oddToken,amount);
    }
}