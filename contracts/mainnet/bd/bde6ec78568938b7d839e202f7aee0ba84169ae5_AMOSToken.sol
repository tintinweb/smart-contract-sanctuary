pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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
 * @title tokenRecipient
 * @dev An interface capable of calling `receiveApproval`, which is used by `approveAndCall` to notify the contract from this interface
 */
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


/**
 * @title TokenERC20
 * @dev A simple ERC20 standard token with burnable function
 */
contract TokenERC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;

    // This creates an array with all balances
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address _owner) view public returns(uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) view public returns(uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Basic transfer of all transfer-related functions
     * @param _from The address of sender
     * @param _to The address of recipient
     * @param _value The amount sender want to transfer to recipient
     */
    function _transfer(address _from, address _to, uint _value) internal {
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer( _from, _to, _value);
    }

    /**
     * @notice Transfer tokens
     * @dev Send `_value` tokens to `_to` from your account
     * @param _to The address of the recipient
     * @param _value The amount to send
     * @return True if the transfer is done without error
     */
    function transfer(address _to, uint256 _value) public returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Transfer tokens from other address
     * @dev Send `_value` tokens to `_to` on behalf of `_from`
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount to send
     * @return True if the transfer is done without error
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @notice Set allowance for other address
     * @dev Allows `_spender` to spend no more than `_value` tokens on your behalf
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @return True if the approval is done without error
     */
    function approve(address _spender, uint256 _value) public returns(bool) {
        // Avoid the front-running attack
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Set allowance for other address and notify
     * @dev Allows contract `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     * @param _spender The contract address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     * @return True if it is done without error
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

    /**
     * @notice Destroy tokens
     * @dev Remove `_value` tokens from the system irreversibly
     * @param _value The amount of money will be burned
     * @return True if `_value` is burned successfully
     */
    function burn(uint256 _value) public returns(bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * @notice Destroy tokens from other account
     * @dev Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     * @param _from The address of the sender
     * @param _value The amount of money will be burned
     * @return True if `_value` is burned successfully
     */
    function burnFrom(address _from, uint256 _value) public returns(bool) {
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
        return true;
    }
}


/**
 * @title AMOSToken
 */
contract AMOSToken is TokenERC20 {
    using SafeMath for uint256;

    // Token Info.
    string public constant name = "AMOS Token";
    string public constant symbol = "AMOS";
    uint8 public constant decimals = 18;

    /**
     * @dev Constructor of AMOS Token
     */
    constructor() public {
        totalSupply = 5000000000 * 10 ** 18;
        balances[msg.sender] = totalSupply;
    }

    function transferMultiple(address[] _to, uint256[] _value) public returns(bool) {
        require(_to.length == _value.length);
        uint256 i = 0;
        while (i < _to.length) {
           _transfer(msg.sender, _to[i], _value[i]);
           i += 1;
        }
        return true;
    }
}