pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
  
}

contract Token {

    /// @return total amount of tokens
    function totalSupply() public view returns (uint256);

    /// @param owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address owner) public view returns (uint256);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address to, uint256 value) public returns (bool);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address spender, uint256 value) public returns (bool);

    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract StandardToken is Token {
    using SafeMath for uint256;
    
    mapping (address => uint256) balances;
    
    mapping (address => mapping (address => uint256)) allowed;
    
    uint256 public totalSupply;
    
    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender]);
        require(to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);
        require(to != address(0));
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
    
    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) public view returns (uint256 remaining) {
      return allowed[owner][spender];
    }
    
    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool success) {
        require(spender != address(0));
        
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}

contract Ownable {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

contract NNBToken is StandardToken, Ownable {
    string public constant name = "NNB Token";    //fancy name: eg Simon Bucks
    string public constant symbol = "NNB";           //An identifier: eg SBX
    uint8 public constant decimals = 18;            //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public constant version = "H1.0";        //human 0.1 standard. Just an arbitrary versioning scheme.
    
    mapping (address => uint256) lockedBalance;
    mapping (address => uint256) releasedBalance;
    mapping (address => TimeLock[]) public allocations;
    
    struct TimeLock {
        uint time;
        uint256 balance;
    }
    
    uint256 public constant BASE_SUPPLY = 10 ** uint256(decimals);
    uint256 public constant INITIAL_SUPPLY = 6 * (10 ** 9) * BASE_SUPPLY;    //initial total supply for six billion
    
    uint256 public constant noLockedOperatorSupply = INITIAL_SUPPLY / 100 * 2;  // no locked operator 2%
    
    uint256 public constant lockedOperatorSupply = INITIAL_SUPPLY / 100 * 18;  // locked operator 18%
    uint256 public constant lockedInvestorSupply = INITIAL_SUPPLY / 100 * 10;  // locked investor 10%
    uint256 public constant lockedTeamSupply = INITIAL_SUPPLY / 100 * 10;  // locked team 10%

    uint256 public constant lockedPrivatorForBaseSupply = INITIAL_SUPPLY / 100 * 11;  // locked privator base 11%
    uint256 public constant lockedPrivatorForEcologyPartOneSupply = INITIAL_SUPPLY / 100 * 8;  // locked privator ecology part one for 8%
    uint256 public constant lockedPrivatorForEcologyPartTwoSupply = INITIAL_SUPPLY / 100 * 4;  // locked privator ecology part one for 4%
    
    uint256 public constant lockedPrivatorForFaithSupply = INITIAL_SUPPLY / 1000 * 11;  // locked privator faith 1.1%
    uint256 public constant lockedPrivatorForDevelopSupply = INITIAL_SUPPLY / 1000 * 19;  // locked privator develop 1.9%
    
    uint256 public constant lockedLabSupply = INITIAL_SUPPLY / 100 * 10;  // locked lab 10%
    
    uint public constant operatorUnlockTimes = 24;  // operator unlock times
    uint public constant investorUnlockTimes = 3;   // investor unlock times
    uint public constant teamUnlockTimes = 24;      // team unlock times
    uint public constant privatorForBaseUnlockTimes = 6;   // privator base unlock times
    uint public constant privatorForEcologyUnlockTimes = 9;  // privator ecology unlock times
    uint public constant privatorForFaithUnlockTimes = 6;   // privator faith unlock times
    uint public constant privatorForDevelopUnlockTimes = 3;  // privator develop unlock times
    uint public constant labUnlockTimes = 12;       // lab unlock times
    
    event Lock(address indexed locker, uint256 value, uint releaseTime);
    event UnLock(address indexed unlocker, uint256 value);
    
    constructor(address operator, address investor, address team, address privatorBase,
                address privatorEcology, address privatorFaith, address privatorDevelop, address lab) public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
        
        initialLockedValues(operator, investor, team, privatorBase, privatorEcology, privatorFaith, privatorDevelop, lab);
    }
    
    /**
     * init the locked total value, and the first release time
     */ 
    function initialLockedValues(address operator, address investor, address team, address privatorBase,
                                 address privatorEcology, address privatorFaith, address privatorDevelop, address lab) internal onlyOwner returns (bool success) {
        
        // init operator address value and locked value. every month can unlock operator value for 1/24 since next month
        uint unlockTime = now + 30 days;
        lockedValuesAndTime(operator, lockedOperatorSupply, operatorUnlockTimes, unlockTime);
        
        //init investor address value and locked value. unlocked investor value, at six month for 30%, nine month for 30%, twelve month for the others ,40%
        require(0x0 != investor);
        lockedBalance[investor] = lockedInvestorSupply;
        releasedBalance[investor] = 0;
        
        unlockTime = now;
        allocations[investor].push(TimeLock(unlockTime + 180 days, lockedInvestorSupply.div(10).mul(3)));
        allocations[investor].push(TimeLock(unlockTime + 270 days, lockedInvestorSupply.div(10).mul(3)));
        allocations[investor].push(TimeLock(unlockTime + 360 days, lockedInvestorSupply.div(10).mul(4)));
        
        //init team address value and locked value. every month can unlock team value for 1/24 since next 6 months
        unlockTime = now + 180 days;
        lockedValuesAndTime(team, lockedTeamSupply, teamUnlockTimes, unlockTime);
        
        //init privator base address value and locked value
        unlockTime = now;
        lockedValuesAndTime(privatorBase, lockedPrivatorForBaseSupply, privatorForBaseUnlockTimes, unlockTime);
        
        //init privator ecology address value and locked value
        //this values will divide into two parts, part one for 8% of all inital supply, part two for 4% of all inital supply
        //the part one will unlock for 9 times, part two will unlock for 6 times
        //so, from 1 to 6 unlock times, the unlock values = part one / 9 + part two / 6,  from 7 to 9, the unlock values = part one / 9
        require(0x0 != privatorEcology);
        releasedBalance[privatorEcology] = 0;
        lockedBalance[privatorEcology] = lockedPrivatorForEcologyPartOneSupply.add(lockedPrivatorForEcologyPartTwoSupply);

        unlockTime = now;
        for (uint i = 0; i < privatorForEcologyUnlockTimes; i++) {
            if (i > 0) {
                unlockTime = unlockTime + 30 days;
            }
            
            uint256 lockedValue = lockedPrivatorForEcologyPartOneSupply.div(privatorForEcologyUnlockTimes);
            if (i == privatorForEcologyUnlockTimes - 1) {  // the last unlock time
                lockedValue = lockedPrivatorForEcologyPartOneSupply.div(privatorForEcologyUnlockTimes).add(lockedPrivatorForEcologyPartOneSupply.mod(privatorForEcologyUnlockTimes));
            }
            if (i < 6) {
                uint256 partTwoValue = lockedPrivatorForEcologyPartTwoSupply.div(6);
                if (i == 5) {  //the last unlock time
                    partTwoValue = lockedPrivatorForEcologyPartTwoSupply.div(6).add(lockedPrivatorForEcologyPartTwoSupply.mod(6));
                }
                lockedValue = lockedValue.add(partTwoValue);
            }
            
            allocations[privatorEcology].push(TimeLock(unlockTime, lockedValue));
        }
        
        //init privator faith address value and locked value
        unlockTime = now;
        lockedValuesAndTime(privatorFaith, lockedPrivatorForFaithSupply, privatorForFaithUnlockTimes, unlockTime);
        
        //init privator develop address value and locked value
        unlockTime = now;
        lockedValuesAndTime(privatorDevelop, lockedPrivatorForDevelopSupply, privatorForDevelopUnlockTimes, unlockTime);
        
        //init lab address value and locked value. every month can unlock lab value for 1/12 since next year
        unlockTime = now + 365 days;
        lockedValuesAndTime(lab, lockedLabSupply, labUnlockTimes, unlockTime);
        
        return true;
    }
    
    /**
     * lock the address value, set the unlock time
     */ 
    function lockedValuesAndTime(address target, uint256 lockedSupply, uint lockedTimes, uint unlockTime) internal onlyOwner returns (bool success) {
        require(0x0 != target);
        releasedBalance[target] = 0;
        lockedBalance[target] = lockedSupply;
        
        for (uint i = 0; i < lockedTimes; i++) {
            if (i > 0) {
                unlockTime = unlockTime + 30 days;
            }
            uint256 lockedValue = lockedSupply.div(lockedTimes);
            if (i == lockedTimes - 1) {  //the last unlock time
                lockedValue = lockedSupply.div(lockedTimes).add(lockedSupply.mod(lockedTimes));
            }
            allocations[target].push(TimeLock(unlockTime, lockedValue));
        }
        
        return true;
    }
    
    /**
     * unlock the address values
     */ 
    function unlock(address target) public onlyOwner returns(bool success) {
        require(0x0 != target);
        
        uint256 value = 0;
        for(uint i = 0; i < allocations[target].length; i++) {
            if(now >= allocations[target][i].time) {
                value = value.add(allocations[target][i].balance);
                allocations[target][i].balance = 0;
            }
        }
        lockedBalance[target] = lockedBalance[target].sub(value);
        releasedBalance[target] = releasedBalance[target].add(value);
        
        transfer(target, value);
        emit UnLock(target, value);
        
        return true;
    }
    
    /**
     * operator address has 2% for no locked.
     */ 
    function initialOperatorValue(address operator) public onlyOwner {
        transfer(operator, noLockedOperatorSupply);
    }
    
    /**
     * this function can get the locked value
     */
    function lockedOf(address owner) public constant returns (uint256 balance) {
        return lockedBalance[owner];
    }
    
    /**
     * get the next unlock time
     */ 
    function unlockTimeOf(address owner) public constant returns (uint time) {
        for(uint i = 0; i < allocations[owner].length; i++) {
            if(allocations[owner][i].time >= now) {
                return allocations[owner][i].time;
            }
        }
    }
    
    /**
     * get the next unlock value
     */ 
    function unlockValueOf(address owner) public constant returns (uint256 balance) {
        for(uint i = 0; i < allocations[owner].length; i++) {
            if(allocations[owner][i].time >= now) {
                return allocations[owner][i].balance;
            }
        }
    }
    
    /**
     * this function can get the released value
     */
    function releasedOf(address owner) public constant returns (uint256 balance) {
        return releasedBalance[owner];
    }
    
    /**
     * this function can be used when you want to send same number of tokens to all the recipients
     */
    function batchTransferForSingleValue(address[] dests, uint256 value) public onlyOwner {
        uint256 i = 0;
        uint256 sendValue = value * BASE_SUPPLY;
        while (i < dests.length) {
            transfer(dests[i], sendValue);
            i++;
        }
    }
    
    /**
     * this function can be used when you want to send every recipeint with different number of tokens
     */
    function batchTransferForDifferentValues(address[] dests, uint256[] values) public onlyOwner {
        if(dests.length != values.length) return;
        uint256 i = 0;
        while (i < dests.length) {
            uint256 sendValue = values[i] * BASE_SUPPLY;
            transfer(dests[i], sendValue);
            i++;
        }
    }
    
}