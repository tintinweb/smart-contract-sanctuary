pragma solidity 0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of user permissions.
 */

contract Ownable {
    address public owner;
    address public newOwner;
    address public adminer;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
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
   * @dev Throws if called by any account other than the adminer.
   */
    modifier onlyAdminer {
        require(msg.sender == owner || msg.sender == adminer);
        _;
    }
    
  /**
   * @dev Allows the current owner to transfer control of the contract to a new owner.
   * @param _owner The address to transfer ownership to.
   */
    function transferOwnership(address _owner) public onlyOwner {
        newOwner = _owner;
    }
    
  /**
   * @dev New owner accept control of the contract.
   */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }
    
  /**
   * @dev change the control of the contract to a new adminer.
   * @param _adminer The address to transfer adminer to.
   */
    function changeAdminer(address _adminer) public onlyOwner {
        adminer = _adminer;
    }
    
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title ERC20 interface
 */
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


  /**
  * @dev transfer token for a specified address
  * @param _to The address to tran sfer to.
  * @param _value The amount to be transferred.
  */
    function transfer(address _to, uint256 _value) public returns (bool) {
        return BasicToken.transfer(_to, _value);
    }

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

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
 * @title Mintable token
 */

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);


  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _to, uint256 _amount) onlyAdminer public returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}

/**
 * @title Additioal token
 * @dev Mintable token with a token can be increased with proportion.
 */
 
contract AdditionalToken is MintableToken {

    uint256 public maxProportion;
    uint256 public lockedYears;
    uint256 public initTime;

    mapping(uint256 => uint256) public records;
    mapping(uint256 => uint256) public maxAmountPer;
    
    event MintRequest(uint256 _curTimes, uint256 _maxAmountPer, uint256 _curAmount);


    constructor(uint256 _maxProportion, uint256 _lockedYears) public {
        require(_maxProportion >= 0);
        require(_lockedYears >= 0);
        
        maxProportion = _maxProportion;
        lockedYears = _lockedYears;
        initTime = block.timestamp;
    }

  /**
   * @dev Function to Increase tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of the minted tokens.
   * @return A boolean that indicates if the operation was successful.
   */
    function mint(address _to, uint256 _amount) onlyAdminer public returns (bool) {
        uint256 curTime = block.timestamp;
        uint256 curTimes = curTime.sub(initTime)/(31536000);
        
        require(curTimes >= lockedYears);
        
        uint256 _maxAmountPer;
        if(maxAmountPer[curTimes] == 0) {
            maxAmountPer[curTimes] = totalSupply.mul(maxProportion).div(100);
        }
        _maxAmountPer = maxAmountPer[curTimes];
        require(records[curTimes].add(_amount) <= _maxAmountPer);
        records[curTimes] = records[curTimes].add(_amount);
        emit MintRequest(curTimes, _maxAmountPer, records[curTimes]);        
        return(super.mint(_to, _amount));
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
    function pause() onlyAdminer whenNotPaused public {
        paused = true;
        emit Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyAdminer whenPaused public {
        paused = false;
        emit Unpause();
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

/**
 * @title Token contract
 */
 
contract Token is AdditionalToken, PausableToken {

    using SafeMath for uint256;
    
    string public  name;
    string public symbol;
    uint256 public decimals;

    mapping(address => bool) public singleLockFinished;
    
    struct lockToken {
        uint256 amount;
        uint256 validity;
    }

    mapping(address => lockToken[]) public locked;
    
    
    event Lock(
        address indexed _of,
        uint256 _amount,
        uint256 _validity
    );
    
    function () payable public  {
        revert();
    }
    
    constructor (string _symbol, string _name, uint256 _decimals, uint256 _initSupply, 
                    uint256 _maxProportion, uint256 _lockedYears) AdditionalToken(_maxProportion, _lockedYears) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = totalSupply.add(_initSupply * (10 ** decimals));
        balances[msg.sender] = totalSupply.div(2);
        balances[address(this)] = totalSupply - balances[msg.sender];
    }

    /**
     * @dev Lock the special address 
     *
     * @param _time The array of released timestamp 
     * @param _amountWithoutDecimal The array of amount of released tokens
     * NOTICE: the amount in this function not include decimals. 
     */
    
    function lock(address _address, uint256[] _time, uint256[] _amountWithoutDecimal) onlyAdminer public returns(bool) {
        require(!singleLockFinished[_address]);
        require(_time.length == _amountWithoutDecimal.length);
        if(locked[_address].length != 0) {
            locked[_address].length = 0;
        }
        uint256 len = _time.length;
        uint256 totalAmount = 0;
        uint256 i = 0;
        for(i = 0; i<len; i++) {
            totalAmount = totalAmount.add(_amountWithoutDecimal[i]*(10 ** decimals));
        }
        require(balances[_address] >= totalAmount);
        for(i = 0; i < len; i++) {
            locked[_address].push(lockToken(_amountWithoutDecimal[i]*(10 ** decimals), block.timestamp.add(_time[i])));
            emit Lock(_address, _amountWithoutDecimal[i]*(10 ** decimals), block.timestamp.add(_time[i]));
        }
        return true;
    }
    
    function finishSingleLock(address _address) onlyAdminer public {
        singleLockFinished[_address] = true;
    }
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified purpose at a specified time
     *
     * @param _of The address whose tokens are locked
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLocked(address _of, uint256 _time)
        public
        view
        returns (uint256 amount)
    {
        for(uint256 i = 0;i < locked[_of].length;i++)
        {
            if(locked[_of][i].validity>_time)
                amount += locked[_of][i].amount;
        }
    }

    /**
     * @dev Returns tokens available for transfer for a specified address
     * @param _of The address to query the the lock tokens of
     */
    function transferableBalanceOf(address _of)
        public
        view
        returns (uint256 amount)
    {
        uint256 lockedAmount = 0;
        lockedAmount += tokensLocked(_of, block.timestamp);
        amount = balances[_of].sub(lockedAmount);
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool) {
        require(_value <= transferableBalanceOf(msg.sender));
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool) {
        require(_value <= transferableBalanceOf(_from));
        return super.transferFrom(_from, _to, _value);
    }
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyAdminer returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}