pragma solidity 0.4.13;
contract Burnable {

    event LogBurned(address indexed burner, uint256 indexed amount);

    function burn(uint256 amount) returns (bool burned);
}
contract Mintable {

    function mint(address to, uint256 amount) returns (bool minted);

    function mintLocked(address to, uint256 amount) returns (bool minted);
}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
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
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) {
        //require(_token != address(0));
        //require(_beneficiary != address(0));
        require(_releaseTime > now);

        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
    * @notice Transfers tokens held by timelock to beneficiary.
    */
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
/**
* @title TokenVesting
* @dev A token holder contract that can release its token balance gradually like a typical vesting
* scheme, with a cliff and vesting period. Optionally revocable by the owner.
*/
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event LogVestingCreated(address indexed beneficiary, uint256 startTime, uint256 indexed cliff,
        uint256 indexed duration, bool revocable);
    event LogVestedTokensReleased(address indexed token, uint256 indexed released);
    event LogVestingRevoked(address indexed token, uint256 indexed refunded);

    // Beneficiary of tokens after they are released
    address public beneficiary;

    // The duration in seconds of the cliff in which tokens will begin to vest
    uint256 public cliff;
    
    // When the vesting starts as timestamp in seconds from Unix epoch
    uint256 public startTime;
    
    // The duration in seconds of the period in which the tokens will vest
    uint256 public duration;

    // Flag indicating whether the vesting is revocable or not
    bool public revocable;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;

    /**
    * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    * _beneficiary, gradually in a linear fashion until _startTime + _duration. By then all
    * of the balance will have vested.
    * @param _beneficiary The address of the beneficiary to whom vested tokens are transferred
    * @param _startTime When the vesting starts as timestamp in seconds from Unix epoch
    * @param _cliff The duration in seconds of the cliff in which tokens will begin to vest
    * @param _duration The duration in seconds of the period in which the tokens will vest
    * @param _revocable Flag indicating whether the vesting is revocable or not
    */
    function TokenVesting(address _beneficiary, uint256 _startTime, uint256 _cliff, uint256 _duration, bool _revocable) public {
        require(_beneficiary != address(0));
        require(_startTime >= now);
        require(_duration > 0);
        require(_cliff <= _duration);

        beneficiary = _beneficiary;
        startTime = _startTime;
        cliff = _startTime.add(_cliff);
        duration = _duration;
        revocable = _revocable;

        LogVestingCreated(beneficiary, startTime, cliff, duration, revocable);
    }

    /**
    * @notice Transfers vested tokens to beneficiary.
    * @param token ERC20 token which is being vested
    */
    function release(ERC20Basic token) public {
        uint256 unreleased = releasableAmount(token);
        require(unreleased > 0);

        released[token] = released[token].add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        LogVestedTokensReleased(address(token), unreleased);
    }

    /**
    * @notice Allows the owner to revoke the vesting. Tokens already vested
    * remain in the contract, the rest are returned to the owner.
    * @param token ERC20 token which is being vested
    */
    function revoke(ERC20Basic token) public onlyOwner {
        require(revocable);
        require(!revoked[token]);

        uint256 balance = token.balanceOf(this);

        uint256 unreleased = releasableAmount(token);
        uint256 refundable = balance.sub(unreleased);

        revoked[token] = true;

        token.safeTransfer(owner, refundable);

        LogVestingRevoked(address(token), refundable);
    }

    /**
    * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
    * @param token ERC20 token which is being vested
    */
    function releasableAmount(ERC20Basic token) public constant returns (uint256) {
        return vestedAmount(token).sub(released[token]);
    }

    /**
    * @dev Calculates the amount that has already vested.
    * @param token ERC20 token which is being vested
    */
    function vestedAmount(ERC20Basic token) public constant returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (now < cliff) {
            return 0;
        } else if (now >= startTime.add(duration) || revoked[token]) {
            return totalBalance;
        } else {
            return totalBalance.mul(now.sub(startTime)).div(duration);
        }
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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
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

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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
 * @title Pausable token
 *
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
contract AdaptableToken is Burnable, Mintable, PausableToken {

    uint256 public transferableFromBlock;

    uint256 public lockEndBlock;
    
    mapping (address => uint256) public initiallyLockedAmount;
    
    function AdaptableToken(uint256 _transferableFromBlock, uint256 _lockEndBlock) internal {
        require(_lockEndBlock > _transferableFromBlock);
        transferableFromBlock = _transferableFromBlock;
        lockEndBlock = _lockEndBlock;
    }

    modifier canTransfer(address _from, uint _value) {
        require(block.number >= transferableFromBlock);

        if (block.number < lockEndBlock) {
            uint256 locked = lockedBalanceOf(_from);
            if (locked > 0) {
                uint256 newBalance = balanceOf(_from).sub(_value);
                require(newBalance >= locked);
            }
        }
        _;
    }

    function lockedBalanceOf(address _to) public constant returns(uint256) {
        uint256 locked = initiallyLockedAmount[_to];
        if (block.number >= lockEndBlock) return 0;
        else if (block.number <= transferableFromBlock) return locked;

        uint256 releaseForBlock = locked.div(lockEndBlock.sub(transferableFromBlock));
        uint256 released = block.number.sub(transferableFromBlock).mul(releaseForBlock);
        return locked.sub(released);
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    modifier canMint() {
        require(!mintingFinished());
        _;
    }

    function mintingFinished() public constant returns(bool finished) {
        return block.number >= transferableFromBlock;
    }

    /**
    * @dev Mint new tokens.
    * @param _to The address that will receieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool minted) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Mint new locked tokens, which will unlock progressively.
    * @param _to The address that will receieve the minted locked tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mintLocked(address _to, uint256 _amount) public onlyOwner canMint returns (bool minted) {
        initiallyLockedAmount[_to] = initiallyLockedAmount[_to].add(_amount);
        return mint(_to, _amount);
    }

    /**
     * @dev Mint timelocked tokens.
     * @param _to The address that will receieve the minted locked tokens.
     * @param _amount The amount of tokens to mint.
     * @param _releaseTime The token release time as timestamp from Unix epoch.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintTimelocked(address _to, uint256 _amount, uint256 _releaseTime) public
        onlyOwner canMint returns (TokenTimelock tokenTimelock) {

        TokenTimelock timelock = new TokenTimelock(this, _to, _releaseTime);
        mint(timelock, _amount);

        return timelock;
    }

    /**
    * @dev Mint vested tokens.
    * @param _to The address that will receieve the minted vested tokens.
    * @param _amount The amount of tokens to mint.
    * @param _startTime When the vesting starts as timestamp in seconds from Unix epoch.
    * @param _duration The duration in seconds of the period in which the tokens will vest.
    * @return A boolean that indicates if the operation was successful.
    */
    function mintVested(address _to, uint256 _amount, uint256 _startTime, uint256 _duration) public
        onlyOwner canMint returns (TokenVesting tokenVesting) {

        TokenVesting vesting = new TokenVesting(_to, _startTime, 0, _duration, true);
        mint(vesting, _amount);

        return vesting;
    }

    /**
    * @dev Burn tokens.
    * @param _amount The amount of tokens to burn.
    * @return A boolean that indicates if the operation was successful.
    */
    function burn(uint256 _amount) public returns (bool burned) {
        //require(0 < _amount && _amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        Transfer(msg.sender, address(0), _amount);
        
        return true;
    }

    /**
     * @dev Release vested tokens to beneficiary.
     * @param _vesting The token vesting to release.
     */
    function releaseVested(TokenVesting _vesting) public {
        require(_vesting != address(0));

        _vesting.release(this);
    }

    /**
     * @dev Revoke vested tokens. Just the token can revoke because it is the vesting owner.
     * @param _vesting The token vesting to revoke.
     */
    function revokeVested(TokenVesting _vesting) public onlyOwner {
        require(_vesting != address(0));

        _vesting.revoke(this);
    }
}
contract NokuMasterToken is AdaptableToken {
    string public constant name = "NOKU";
    string public constant symbol = "NOKU";
    uint8 public constant decimals = 18;

    function NokuMasterToken(uint256 _transferableFromBlock, uint256 _lockEndBlock)
        AdaptableToken(_transferableFromBlock, _lockEndBlock) public {
    }
}