pragma solidity ^0.4.18;


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
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
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
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}









contract TokenWithOwner {
    address public owner;
}

/**
 * @title PeriodicalReleaseLock
 * @dev PeriodicalReleaseLock is a token holder contract that will allow a group of
 * beneficiaries to release the tokens evenly and periodically after the frozen age
 */
contract PeriodicReleaseLock {
    using SafeERC20 for ERC20Basic;
    using SafeMath for uint256;

    struct FrozenStatus {
        uint256 frozenTimestamp;        // the frozen time
        uint256 frozenAmount;           // the remain frozen amount
        uint256 releaseAmount;          // release amount each time
        uint256 lastReleaseTimestamp;   // last release time
    }

    // Fired when token contract successfully calls freeze
    event FreezeTokens(address indexed _target, uint256 _frozenAmount);
    // Fired when token holder successfully calls release
    event ReleaseTokens(address indexed _target, uint256 _releaseAmount);

    event Test(uint256 balance, uint256 frozen);

    // ERC20 basic token contract being held
    ERC20Basic public token;

    modifier byToken {
        require(msg.sender == address(token));
        _;
    }

    uint256 public totalFrozen;
    mapping (address => FrozenStatus) public frozenStatuses;

    // time period between frozen and first release
    uint256 public firstReleasePeriod;
    // time period between last release and next release
    uint256 public regularReleasePeriod;

    function PeriodicReleaseLock(ERC20Basic _token, uint256 _firstReleasePeriod, uint256 _regularReleasePeriod) public {
        require(_firstReleasePeriod >= 1 seconds);
        require(_regularReleasePeriod >= 1 seconds);

        token = _token;
        firstReleasePeriod = _firstReleasePeriod;
        regularReleasePeriod = _regularReleasePeriod;
    }

    function frozenStatusOf(address _target) public view returns (uint256, uint256, uint256, uint256) {
        FrozenStatus storage frozenStatus = frozenStatuses[_target];
        return (
            frozenStatus.frozenTimestamp,
            frozenStatus.frozenAmount,
            frozenStatus.releaseAmount,
            frozenStatus.lastReleaseTimestamp
        );
    }

    /**
     * @notice Freeze _frozenAmount of tokens held by _target with PeriodicReleaseLock.
     */
    function freeze(address _target, uint256 _frozenAmount, uint256 _releaseAmount) byToken public returns (bool) {
        require(_target != 0x0);
        require(_frozenAmount > 0);
        require(_releaseAmount < _frozenAmount);

        totalFrozen = totalFrozen.add(_frozenAmount);

        FrozenStatus storage frozenStatus = frozenStatuses[_target];
        require(frozenStatus.frozenAmount == 0); // each address can only be locked in a contract once

        frozenStatus.frozenTimestamp = now;
        frozenStatus.frozenAmount = _frozenAmount;
        frozenStatus.releaseAmount = _releaseAmount;

        FreezeTokens(_target, _frozenAmount);
        return true;
    }

    /**
     * @notice Transfers tokens held by PeriodicReleaseLock to beneficiary.
     */
    function release() public returns (bool) {
        address target = msg.sender;

        FrozenStatus storage frozenStatus = frozenStatuses[target];
        require(frozenStatus.frozenAmount > 0);

        uint256 actualLastReleaseTimestamp;

        if (frozenStatus.lastReleaseTimestamp == 0) {
            actualLastReleaseTimestamp = frozenStatus.frozenTimestamp + firstReleasePeriod;
        } else {
            actualLastReleaseTimestamp = frozenStatus.lastReleaseTimestamp + regularReleasePeriod;
        }

        require(now >= actualLastReleaseTimestamp);
        frozenStatus.lastReleaseTimestamp = actualLastReleaseTimestamp;

        uint256 actualReleaseAmount = Math.min256(frozenStatus.frozenAmount, frozenStatus.releaseAmount);

        token.safeTransfer(target, actualReleaseAmount);

        frozenStatus.frozenAmount = frozenStatus.frozenAmount.sub(actualReleaseAmount);
        totalFrozen = totalFrozen.sub(actualReleaseAmount);

        ReleaseTokens(target, actualReleaseAmount);

        return true;
    }

    /**
    * @notice Transfers tokens of unknown holders to token contract owner.
    */
    function missingTokensFallback() public {
        uint256 missingTokens = token.balanceOf(this).sub(totalFrozen);
        require(missingTokens > 0);

        TokenWithOwner tokenWithOwner = TokenWithOwner(token);

        token.safeTransfer(tokenWithOwner.owner(), missingTokens);
    }
}

contract Tutoreum is Ownable, StandardToken, BurnableToken {
    string public constant name = "Ecotopia";
    string public constant symbol = "ECO";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 20000000000 * (10 ** uint256(decimals));

    function Tutoreum() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    function transferAndFreeze(address _to, PeriodicReleaseLock _lock, uint256 _transferAmount, uint256 _frozenAmount, uint256 _releaseAmount) public {
        require(_lock.token() == this);

        if (_transferAmount > 0) {
            assert(transfer(_to, _transferAmount));
        }

        if (_frozenAmount > 0) {
            assert(transfer(_lock, _frozenAmount));
            assert(_lock.freeze(_to, _frozenAmount, _releaseAmount));

            assert(balances[_lock] >= _lock.totalFrozen());
        }
    }
}