pragma solidity ^0.4.18;

// File: contracts/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

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


}

// File: contracts/ISStop.sol

contract ISStop is Ownable {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() public onlyOwner {
        stopped = true;
    }
    function start() public onlyOwner {
        stopped = false;
    }

}

// File: contracts/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/SafeMath.sol

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
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/BasicToken.sol

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

// File: contracts/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken {

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

// File: contracts/InseeCoin.sol

contract InseeCoin is ISStop, StandardToken{
    string public name = "Insee Coin";
    uint8 public decimals = 18;
    string public symbol = "SEE";
    string public version = "v0.1";
     /// initial amount of InseeCoin
    uint256 public initialAmount = (10 ** 10) * (10 ** 18);
   

    event Destroy(address from, uint value);

    function InseeCoin() public {
        balances[msg.sender] = initialAmount;   // Give the creator all initial balances is defined in StandardToken.sol
        totalSupply_ = initialAmount;              // Update total supply, totalSupply is defined in Tocken.sol
    }

    function transfer(address dst, uint wad) public stoppable  returns (bool) {
        return super.transfer(dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public stoppable  returns (bool) {
        return super.transferFrom(src, dst, wad);
    }
    
    function approve(address guy, uint wad) public stoppable  returns (bool) {
        return super.approve(guy, wad);
    }

    function destroy(uint256 _amount) external onlyOwner stoppable  returns (bool success){
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Destroy(msg.sender, _amount);
        return true;
    }

     function setName(string name_) public onlyOwner{
        name = name_;
    }

}

// File: contracts/TokenLock.sol

contract TokenLock {
    using SafeMath for uint256;
	InseeCoin  public  ISC;     // The InSeeCoin token itself

    /**
     * Next time lock ID to be used.
     */
    uint256 private nextLockID = 0;

    /**
     * Maps time lock ID to TokenTimeLockInfo structure encapsulating time lock
     * information.
     */
    mapping (uint256 => TokenTimeLockInfo) public locks;

    /**
     * Encapsulates information abount time lock.
     */
    struct TokenTimeLockInfo {

        /**
         * Beneficiary to receive tokens once they are unlocked.
         */
        address beneficiary;

        /**
         * Amount of locked tokens.
         */
        uint256 amount;

        /**
         * Unlock time.
         */
        uint256 unlockTime;
    }

    /**
     * Logged when tokens were time locked.
     *
     * @param id time lock ID
     * @param beneficiary beneficiary to receive tokens once they are unlocked
     * @param amount amount of locked tokens
     * @param lockTime unlock time
     */
    event Lock (uint256 indexed id, address indexed beneficiary,uint256 amount, uint256 lockTime);
      /**
     * Logged when tokens were unlocked and sent to beneficiary.
     *
     * @param id time lock ID
     * @param beneficiary beneficiary to receive tokens once they are unlocked
     * @param amount amount of locked tokens
     * @param unlockTime unlock time
     */
    event Unlock (uint256 indexed id, address indexed beneficiary,uint256 amount, uint256 unlockTime);

	function TokenLock(InseeCoin isc) public {
        assert(address(isc) != address(0));

        ISC = isc;
	}

	/**
     * Lock given amount of given EIP-20 tokens until given time arrives, after
     * this time allow the tokens to be transferred to given beneficiary.  This
     * contract should be allowed to transfer at least given amount of tokens
     * from msg.sender.
     *
     * @param _beneficiary beneficiary to receive tokens after unlock time
     * @param _amount amount of tokens to be locked
     * @param _lockTime unlock time
     *
     * @return time lock ID
     */
    function lock (
      address _beneficiary, uint256 _amount,
        uint256 _lockTime) public returns (uint256) {
        require (_amount > 0);
        require (_lockTime > 0);

        nextLockID = nextLockID.add(1);
        uint256 id = nextLockID;

        TokenTimeLockInfo storage lockInfo = locks [id];
        require (lockInfo.beneficiary == 0x0);
        require (lockInfo.amount == 0);
        require (lockInfo.unlockTime == 0);

        lockInfo.beneficiary = _beneficiary;
        lockInfo.amount = _amount;
        lockInfo.unlockTime =  now.add(_lockTime);

        emit Lock (id, _beneficiary, _amount, _lockTime);

        require (ISC.transferFrom (msg.sender, this, _amount));

        return id;
    }


    /**
     * Unlock tokens locked under time lock with given ID and transfer them to
     * corresponding beneficiary.
     *
     * @param _id time lock ID to unlock tokens locked under
     */
    function unlock (uint256 _id) public {
        TokenTimeLockInfo memory lockInfo = locks [_id];
        delete locks [_id];

        require (lockInfo.amount > 0);
        require (lockInfo.unlockTime <= block.timestamp);

        emit Unlock (_id, lockInfo.beneficiary, lockInfo.amount, lockInfo.unlockTime);

        require (
            ISC.transfer (
                lockInfo.beneficiary, lockInfo.amount));
    }


}