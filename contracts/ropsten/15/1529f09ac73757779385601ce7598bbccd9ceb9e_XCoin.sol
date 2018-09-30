pragma solidity ^0.4.25;

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
 * @title ERC827 interface, an extension of ERC20 token standard
 *
 * @dev Interface of a ERC827 token, following the ERC20 standard with extra
 * @dev methods to transfer value and data and execute calls in transfers and
 * @dev approvals.
 */
contract ERC827 is ERC20 {
    function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool);

    function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool);

    function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) public payable returns (bool);
}

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        uint256 c = a / b;
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


/**
 * @title Standard ERC20 token
 *
 */
contract ERC20Token is ERC20 {
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) internal allowed;
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
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
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
 * @title ERC827, an extension of ERC20 token standard
 *
 * @dev Implementation the ERC827, following the ERC20 standard with extra
 * @dev methods to transfer value and data and execute calls in transfers and
 * @dev approvals.
 *
 * @dev Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is ERC827, ERC20Token {
    /**
     * @dev Addition to ERC20 token methods. It allows to
     * @dev approve the transfer of value and execute a call with the sent data.
     *
     * @dev Beware that changing an allowance with this method brings the risk that
     * @dev someone may use both the old and the new allowance by unfortunate
     * @dev transaction ordering. One possible solution to mitigate this race condition
     * @dev is to first reduce the spender&#39;s allowance to 0 and set the desired value
     * @dev afterwards:
     * @dev https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @param _spender The address that will spend the funds.
     * @param _value The amount of tokens to be spent.
     * @param _data ABI-encoded contract call to call `_to` address.
     *
     * @return true if the call function was executed successfully
     */
    function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool) {
        require(_spender != address(this));
        super.approve(_spender, _value);
        // solium-disable-next-line security/no-call-value
        require(_spender.call.value(msg.value)(_data));
        return true;
    }
    /**
     * @dev Addition to ERC20 token methods. Transfer tokens to a specified
     * @dev address and execute a call with the sent data on the same transaction
     *
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     * @param _data ABI-encoded contract call to call `_to` address.
     *
     * @return true if the call function was executed successfully
     */
    function transferAndCall(address _to, uint256 _value, bytes _data) public payable returns (bool) {
        require(_to != address(this));
        super.transfer(_to, _value);
        require(_to.call.value(msg.value)(_data));
        return true;
    }
    /**
     * @dev Addition to ERC20 token methods. Transfer tokens from one address to
     * @dev another and make a contract call on the same transaction
     *
     * @param _from The address which you want to send tokens from
     * @param _to The address which you want to transfer to
     * @param _value The amout of tokens to be transferred
     * @param _data ABI-encoded contract call to call `_to` address.
     *
     * @return true if the call function was executed successfully
     */
    function transferFromAndCall(address _from, address _to, uint256 _value, bytes _data) public payable returns (bool) {
        require(_to != address(this));
        super.transferFrom(_from, _to, _value);
        require(_to.call.value(msg.value)(_data));
        return true;
    }
    /**
     * @dev Addition to StandardToken methods. Increase the amount of tokens that
     * @dev an owner allowed to a spender and execute a call with the sent data.
     *
     * @dev approve should be called when allowed[_spender] == 0. To increment
     * @dev allowed value is better to use this function to avoid 2 calls (and wait until
     * @dev the first transaction is mined)
     * @dev From MonolithDAO Token.sol
     *
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     * @param _data ABI-encoded contract call to call `_spender` address.
     */
    function increaseApprovalAndCall(address _spender, uint _addedValue, bytes _data) public payable returns (bool) {
        require(_spender != address(this));
        super.increaseApproval(_spender, _addedValue);
        require(_spender.call.value(msg.value)(_data));
        return true;
    }
    /**
     * @dev Addition to StandardToken methods. Decrease the amount of tokens that
     * @dev an owner allowed to a spender and execute a call with the sent data.
     *
     * @dev approve should be called when allowed[_spender] == 0. To decrement
     * @dev allowed value is better to use this function to avoid 2 calls (and wait until
     * @dev the first transaction is mined)
     * @dev From MonolithDAO Token.sol
     *
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     * @param _data ABI-encoded contract call to call `_spender` address.
     */
    function decreaseApprovalAndCall(address _spender, uint _subtractedValue, bytes _data) public payable returns (bool) {
        require(_spender != address(this));
        super.decreaseApproval(_spender, _subtractedValue);
        require(_spender.call.value(msg.value)(_data));
        return true;
    }
}

/**
 * @title  Burnable and Pause Token
 * @dev    StandardToken modified with pausable transfers.
 */
contract PauseBurnableERC827Token is ERC827Token, Ownable {
    using SafeMath for uint256;
    event Pause();
    event Unpause();
    event PauseOperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event Burn(address indexed burner, uint256 value);

    bool public paused = false;
    address public pauseOperator;
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyPauseOperator() {
        require(msg.sender == pauseOperator || msg.sender == owner);
        _;
    }
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
     * @dev The constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        pauseOperator = msg.sender;
    }
    /**
     * @dev called by the operator to set the new operator to pause the token
     */
    function transferPauseOperator(address newPauseOperator) onlyPauseOperator public {
        require(newPauseOperator != address(0));
        emit PauseOperatorTransferred(pauseOperator, newPauseOperator);
        pauseOperator = newPauseOperator;
    }
    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyPauseOperator whenNotPaused public {
        paused = true;
        emit Pause();
    }
    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyPauseOperator whenPaused public {
        paused = false;
        emit Unpause();
    }

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
    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public whenNotPaused {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure
        balances[_who] = balances[_who].sub(_value);
        // Subtract from the sender
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param _from address The address which you want to send tokens from
     * @param _value uint256 The amount of token to be burned
     */
    function burnFrom(address _from, uint256 _value) public whenNotPaused {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _burn(_from, _value);
    }
}

contract XCoin is PauseBurnableERC827Token {
    string  public  name;
    string  public  symbol;
    uint8   public constant decimals = 18;

    constructor(string _name, string _symbol, uint256 _totalSupply, address _owner) public {
        if (_owner != address(0x0)) {
            pauseOperator = _owner;
            owner = _owner;
        }
        totalSupply_ = _totalSupply;
        name = _name;
        symbol = _symbol;
        balances[msg.sender] = _totalSupply;
        emit Transfer(0x0, msg.sender, _totalSupply);
    }
    function batchTransfer(address[] _tos, uint256 _value) public whenNotPaused returns (bool) {
        uint256 all = _value.mul(_tos.length);
        require(balances[msg.sender] >= all);
        for (uint i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            require(_tos[i] != msg.sender);
            balances[_tos[i]] = balances[_tos[i]].add(_value);
            emit Transfer(msg.sender, _tos[i], _value);
        }
        balances[msg.sender] = balances[msg.sender].sub(all);
        return true;
    }

    function multiTransfer(address[] _tos, uint256[] _values) public whenNotPaused returns (bool) {
        require(_tos.length == _values.length);
        uint256 all = 0;
        for (uint i = 0; i < _tos.length; i++) {
            require(_tos[i] != address(0));
            require(_tos[i] != msg.sender);
            all = all.add(_values[i]);
            balances[_tos[i]] = balances[_tos[i]].add(_values[i]);
            emit Transfer(msg.sender, _tos[i], _values[i]);
        }
        balances[msg.sender] = balances[msg.sender].sub(all);
        return true;
    }
}