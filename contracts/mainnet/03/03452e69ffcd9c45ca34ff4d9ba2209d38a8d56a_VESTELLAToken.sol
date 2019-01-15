pragma solidity 0.5.1; 


library SafeMath {

    uint256 constant internal MAX_UINT = 2 ** 256 - 1; // max uint256

    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
        if (_a == 0) {
            return 0;
        }
        require(MAX_UINT / _a >= _b);
        return _a * _b;
    }

    /**
     * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b != 0);
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(MAX_UINT - _a >= _b);
        return _a + _b;
    }

}


contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


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
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


contract StandardToken {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    uint256 internal totalSupply_;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns(uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns(bool) {
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
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns(bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}


contract BurnableToken is StandardToken {
    event Burn(address indexed account, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        require(balances[msg.sender] >= value);
        totalSupply_ = totalSupply_.sub(value);
        balances[msg.sender] = balances[msg.sender].sub(value);
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

    /**
     * @dev Burns a specific amount of tokens which belong to appointed address of account.
     * @param account The address of appointed account.
     * @param value The amount of token to be burned.
     */
    function burnFrom(address account, uint256 value) public {
        require(account != address(0)); 
        require(balances[account] >= value);
        require(allowed[account][msg.sender] >= value);
        totalSupply_ = totalSupply_.sub(value);
        balances[account] = balances[account].sub(value);
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
        emit Burn(account, value);
        emit Transfer(account, address(0), value);
    }
}


/**
 * @dev Rewrite the key functions, add the modifier &#39;whenNotPaused&#39;,owner can stop the transaction.
 */
contract PausableToken is StandardToken, Pausable {
    function transfer(
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns(bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    whenNotPaused
    returns(bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(
        address _spender,
        uint256 _value
    )
    public
    whenNotPaused
    returns(bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(
        address _spender,
        uint _addedValue
    )
    public
    whenNotPaused
    returns(bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
    public
    whenNotPaused
    returns(bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}


/**
 * @title VESTELLAToken token contract
 * @dev Initialize the basic information of VESTELLAToken.
 */
contract VESTELLAToken is PausableToken, BurnableToken {
    using SafeMath for uint256;

    string public constant name = "VESTELLA"; // name of Token
    string public constant symbol = "VES"; // symbol of Token
    uint8 public constant decimals = 18; // decimals of Token
    uint256 constant _INIT_TOTALSUPPLY = 15000000000; 

    mapping (address => uint256[]) internal locktime;
    mapping (address => uint256[]) internal lockamount;

    event AddLockPosition(address indexed account, uint256 amount, uint256 time);

    /**
     * @dev constructor Initialize the basic information.
     */
    constructor() public {
        totalSupply_ = _INIT_TOTALSUPPLY * 10 ** uint256(decimals); 
        owner = 0x0F1b590cD3155571C8680B363867e20b8E4303bE;
        balances[owner] = totalSupply_;
    }

    /**
     * @dev addLockPosition function that only owner can add lock position for appointed address of account.
     * one address can participate more than one lock position plan.
     * @param account The address of account will participate lock position plan.
     * @param amount The array of token amount that will be locked.
     * @param time The timestamp of token will be released.
     */
    function addLockPosition(address account, uint256[] memory amount, uint256[] memory time) public onlyOwner returns(bool) { 
        require(account != address(0));
        require(amount.length == time.length);
        uint256 _lockamount = 0;
        for(uint i = 0; i < amount.length; i++) {
            uint256 _amount = amount[i] * 10 ** uint256(decimals);
            require(time[i] > now);
            locktime[account].push(time[i]);
            lockamount[account].push(_amount);
            emit AddLockPosition(account, _amount, time[i]);
            _lockamount = _lockamount.add(_amount);
        }
        require(balances[msg.sender] >= _lockamount);
        balances[account] = balances[account].add(_lockamount);
        balances[msg.sender] = balances[msg.sender].sub(_lockamount);
        emit Transfer(msg.sender, account, _lockamount);
        return true;
    }

    /**
     * @dev getLockPosition function get the detail information of an appointed account.
     * @param account The address of appointed account.
     */
    function getLockPosition(address account) public view returns(uint256[] memory _locktime, uint256[] memory _lockamount) {
        return (locktime[account], lockamount[account]);
    }

    /**
     * @dev getLockedAmount function get the amount of locked token which belong to appointed address at the current time.
     * @param account The address of appointed account.
     */
    function getLockedAmount(address account) public view returns(uint256 _lockedAmount) {
        uint256 _Amount = 0;
        uint256 _lockAmount = 0;
        for(uint i = 0; i < locktime[account].length; i++) {
            if(now < locktime[account][i]) {
                _Amount = lockamount[account][i]; 
                _lockAmount = _lockAmount.add(_Amount);
            }
        }
        return _lockAmount;   
    }

    /**
     * @dev Rewrite the transfer functions, call the getLockedAmount to validate the balances after transaction is more than lock-amount.
     */
    function transfer(
        address _to,
        uint256 _value
    )
    public
    returns(bool) {
        require(balances[msg.sender].sub(_value) >= getLockedAmount(msg.sender));
        return super.transfer(_to, _value);
    }

    /**
     * @dev Rewrite the transferFrom functions, call the getLockedAmount to validate the balances after transaction is more than lock-amount.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns(bool) {
        require(balances[_from].sub(_value) >= getLockedAmount(_from));
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Rewrite the burn functions, call the getLockedAmount to validate the balances after burning is more than lock-amount.
     */
    function burn(uint256 value) public {
        require(balances[msg.sender].sub(value) >= getLockedAmount(msg.sender));
        super.burn(value);
    }  

    /**
     * @dev Rewrite the burnFrom functions, call the getLockedAmount to validate the balances after burning is more than lock-amount.
     */
    function burnFrom(address account, uint256 value) public {
        require(balances[account].sub(value) >= getLockedAmount(account));
        super.burnFrom(account, value);
    } 

    /**
     * @dev _batchTransfer internal function for airdropping candy to target address.
     * @param _to target address
     * @param _amount amount of token
     */
    function _batchTransfer(address[] memory _to, uint256[] memory _amount) internal whenNotPaused {
        require(_to.length == _amount.length);
        uint256 sum = 0; 
        for(uint i = 0;i < _to.length;i += 1){
            require(_to[i] != address(0));  
            sum = sum.add(_amount[i]);
            require(sum <= balances[msg.sender]);  
            balances[_to[i]] = balances[_to[i]].add(_amount[i]); 
            emit Transfer(msg.sender, _to[i], _amount[i]);
        } 
        balances[msg.sender] = balances[msg.sender].sub(sum); 
    }

    /**
     * @dev airdrop function for airdropping candy to target address.
     * @param _to target address
     * @param _amount amount of token
     */
    function airdrop(address[] memory _to, uint256[] memory _amount) public onlyOwner returns(bool){
        _batchTransfer(_to, _amount);
        return true;
    }
}