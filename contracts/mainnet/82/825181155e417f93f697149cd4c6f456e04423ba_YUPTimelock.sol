pragma solidity 0.4.18;

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

contract YUPTimelock is Ownable {
    using SafeERC20 for StandardToken;
    using SafeMath for uint256;
    
    /** Contract events **/
    event IsLocked(uint256 _time);
    event IsClaiming(uint256 _time);
    event IsFinalized(uint256 _time);
    event Claimed(address indexed _to, uint256 _value);
    event ClaimedFutureUse(address indexed _to, uint256 _value);
    
    /** State variables **/
    enum ContractState { Locked, Claiming, Finalized }
    ContractState public state;
    uint256 constant D160 = 0x0010000000000000000000000000000000000000000;
    StandardToken public token;
    mapping(address => uint256) public allocations;
    mapping(address => bool) public claimed;                //indicates whether beneficiary has claimed tokens
    uint256 public expectedAmount = 193991920 * (10**18);   //should hold 193,991,920 x 10^18 (43.59% of total supply)
    uint256 public amountLocked;
    uint256 public amountClaimed;
    uint256 public releaseTime;     //investor claim starting time
    uint256 public claimEndTime;    //investor claim expiration time
    uint256 public fUseAmount;  //amount of tokens for future use
    address fUseBeneficiary;    //address of future use tokens beneficiary
    uint256 fUseReleaseTime;    //release time of locked future use tokens
    
    /** Modifiers **/
    modifier isLocked() {
        require(state == ContractState.Locked);
        _;
    }
    
    modifier isClaiming() {
        require(state == ContractState.Claiming);
        _;
    }
    
    modifier isFinalized() {
        require(state == ContractState.Finalized);
        _;
    }
    
    /** Constructor **/
    function YUPTimelock(
        uint256 _releaseTime,
        uint256 _amountLocked,
        address _fUseBeneficiary,
        uint256 _fUseReleaseTime
    ) public {
        require(_releaseTime > now);
        
        releaseTime = _releaseTime;
        amountLocked = _amountLocked;
        fUseAmount = 84550000 * 10**18;     //84,550,000 tokens (with 18 decimals)
        claimEndTime = now + 60*60*24*275;  //9 months (in seconds) from time of lock
        fUseBeneficiary = _fUseBeneficiary;
        fUseReleaseTime = _fUseReleaseTime;
        
        if (amountLocked != expectedAmount)
            revert();
    }
    
    /** Allows the owner to set the token contract address **/
    function setTokenAddr(StandardToken tokAddr) public onlyOwner {
        require(token == address(0x0)); //initialize only once
        
        token = tokAddr;
        
        state = ContractState.Locked; //switch contract to locked state
        IsLocked(now);
    }
    
    /** Retrieves individual investor token balance **/
    function getUserBalance(address _owner) public view returns (uint256) {
        if (claimed[_owner] == false && allocations[_owner] > 0)
            return allocations[_owner];
        else
            return 0;
    }
    
    /** Allows owner to initiate the claiming phase **/
    function startClaim() public isLocked onlyOwner {
        state = ContractState.Claiming;
        IsClaiming(now);
    }
    
    /** Allows owner to finalize contract (only after investor claimEnd time) **/
    function finalize() public isClaiming onlyOwner {
        require(now >= claimEndTime);
        
        state = ContractState.Finalized;
        IsFinalized(now);
    }
    
    /** Allows the owner to claim all unclaimed investor tokens **/
    function ownerClaim() public isFinalized onlyOwner {
        uint256 remaining = token.balanceOf(this);
        amountClaimed = amountClaimed.add(remaining);
        amountLocked = amountLocked.sub(remaining);
        
        token.safeTransfer(owner, remaining);
        Claimed(owner, remaining);
    }
    
    /** Facilitates the assignment of investor addresses and amounts (only before claiming phase starts) **/
    function loadBalances(uint256[] data) public isLocked onlyOwner {
        require(token != address(0x0));  //Fail if token is not set
        
        for (uint256 i = 0; i < data.length; i++) {
            address addr = address(data[i] & (D160 - 1));
            uint256 amount = data[i] / D160;
            
            allocations[addr] = amount;
            claimed[addr] = false;
        }
    }
    
    /** Allows owner to claim future use tokens in favor of fUseBeneficiary account **/
    function claimFutureUse() public onlyOwner {
        require(now >= fUseReleaseTime);
        
        amountClaimed = amountClaimed.add(fUseAmount);
        amountLocked = amountLocked.sub(fUseAmount);
        
        token.safeTransfer(fUseBeneficiary, fUseAmount);
        ClaimedFutureUse(fUseBeneficiary, fUseAmount);
    }
    
    /** Allows presale investors to claim tokens **/
    function claim() external isClaiming {
        require(token != address(0x0)); //Fail if token is not set
        require(now >= releaseTime);
        require(allocations[msg.sender] > 0);
        
        uint256 amount = allocations[msg.sender];
        allocations[msg.sender] = 0;
        claimed[msg.sender] = true;
        amountClaimed = amountClaimed.add(amount);
        amountLocked = amountLocked.sub(amount);
        
        token.safeTransfer(msg.sender, amount);
        Claimed(msg.sender, amount);
    }
}