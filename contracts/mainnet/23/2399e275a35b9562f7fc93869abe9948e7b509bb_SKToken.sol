pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256 c) {
        c = a + b;
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract SKToken is Pausable {
    using SafeMath for uint256;

    string public version = "1.0.0";
    string public name;
    string public symbol;

    uint8 public decimals = 18;
    uint256 public totalSupply;
    bool public mintingFinished = false;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
    event FrozenFunds(address indexed target, bool frozen);

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function SKToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        name = tokenName;
        symbol = tokenSymbol;
        // Update total supply with the decimal amount
        totalSupply = initialSupply.mul(10 ** uint256(decimals));
        // Give the creator all initial tokens
        balanceOf[msg.sender] = totalSupply;
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if sender is frozen
        require(!frozenAccount[_from]);
        // Check if recipient is frozen
        require(!frozenAccount[_to]);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] = balanceOf[_to].add(_value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) whenNotPaused onlyPayloadSize(2*32) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused onlyPayloadSize(3*32) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) whenNotPaused onlyPayloadSize(2*32) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
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
    function increaseApproval(address _spender, uint _addedValue) whenNotPaused onlyPayloadSize(2*32) public returns (bool) {
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
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
    function decreaseApproval(address _spender, uint _subtractedValue) whenNotPaused onlyPayloadSize(2*32) public returns (bool) {
        uint oldValue = allowance[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowance[msg.sender][_spender] = 0;
        } else {
            allowance[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) whenNotPaused onlyPayloadSize(32) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(balanceOf[msg.sender] >= _value);      // Check if the sender has enough
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value); // Subtract from the sender
        totalSupply = totalSupply.sub(_value);   // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) whenNotPaused onlyPayloadSize(2*32) public returns (bool success) {
        require(!frozenAccount[msg.sender]);
        require(!frozenAccount[_from]);
        require(balanceOf[_from] >= _value);              // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);  // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);  // Subtract from the targeted balance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); // Subtract from the sender&#39;s allowance
        totalSupply = totalSupply.sub(_value);        // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param target The address that will receive the minted tokens.
     * @param mintedAmount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address target, uint256 mintedAmount) onlyOwner canMint onlyPayloadSize(2*32) public returns (bool) {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    /**
     * @dev Function to freeze account
     * @param target Address to be frozen.
     * @param freeze either to freeze it or not.
     * @return A boolean that indicates if the operation was successful.
     */
    function freezeAccount(address target, bool freeze) onlyOwner public returns (bool) {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
        return true;
    }
}