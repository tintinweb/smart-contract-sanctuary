pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function multiply(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function division(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function subtract(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function plus(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns(uint256);

    function balanceOf(address who) public view returns(uint256);

    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns(uint256);

    function transferFrom(address from, address to, uint256 value) public returns(bool);

    function approve(address spender, uint256 value) public returns(bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath
    for uint256;

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    /**
     * @dev total number of tokens in existence
     */
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }


    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    /*
    function _transfer(address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].subtract(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    */


    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {

        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to].plus(_value) > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from].plus(balances[_to]);
        // Subtract from the sender
        balances[_from] = balances[_from].subtract(_value);
        // Add the same to the recipient
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from].plus(balances[_to]) == previousBalances);

    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns(bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }


    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns(uint256 balance) {
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

    mapping(address => mapping(address => uint256)) internal allowed;

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].subtract(_value);
        balances[_to] = balances[_to].plus(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].subtract(_value);
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
    function approve(address _spender, uint256 _value) public returns(bool) {
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
    function allowance(address _owner, address _spender) public view returns(uint256) {
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
    function increaseApproval(address _spender, uint _addedValue) public returns(bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].plus(_addedValue);
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
    function decreaseApproval(address _spender, uint _subtractedValue) public returns(bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.subtract(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract LBCoinJ is owned, StandardToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public sellPrice;
    uint256 public buyPrice;

    bool public emergencyStop;

    mapping(address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    event Emergency(bool stop);
    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);


    
    /// @dev Constructor that gives msg.sender all of existing tokens.
    function LBCoinJ(string tokenName, string tokenSymbol, uint256 initialSupply) public {
        name = tokenName;
        symbol = tokenSymbol;
        totalSupply_ = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, totalSupply_);
    }
    
    
    /*
    function LBCoinJ() public {
        name = "LBCoinTest2";
        symbol = "LBCTS";
        totalSupply_ = 10000 * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply_;
        emit Transfer(0x0, msg.sender, totalSupply_);
    }
    */
    


    /// Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); // Prevent transfer to 0x0 address. Use burn() instead
        require(balances[_from] >= _value); // Check if the sender has enough
        require(balances[_to].plus(_value) >= balances[_to]); // Check for overflows
        require(!frozenAccount[_from]); // Check if sender is frozen
        require(!frozenAccount[_to]); // Check if recipient is frozen
        require(!emergencyStop); // Check Emergency

        // SafeMath.sub will throw if there is not enough balance.
        balances[_from] = balances[_from].subtract(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balances[target] = balances[target].plus(mintedAmount);
        totalSupply_ = totalSupply_.plus(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    /// @notice Destroy tokens
    /// @notice Remove `_value` tokens from the system irreversibly
    /// @param _value the amount of money to burn
    function burn(uint256 _value) public returns(bool success) {
        require(balances[msg.sender] >= _value); // Check if the sender has enough
        balances[msg.sender] = balances[msg.sender].subtract(_value); // Subtract from the sender
        totalSupply_ = totalSupply_.subtract(_value); // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    // setting emergency stop !!
    function emergency(bool stop) onlyOwner public {
        emergencyStop = stop;
        emit Emergency(emergencyStop);
    }
}