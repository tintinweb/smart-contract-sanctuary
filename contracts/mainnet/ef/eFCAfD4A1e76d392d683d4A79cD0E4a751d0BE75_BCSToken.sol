pragma solidity ^0.4.18;

// SafeMath for addition and substraction
library SafeMath {

  /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
    }

/**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
    }
  
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract BCSToken {
    // Use SafeMath library for addition and substraction
    using SafeMath for uint;
    // Public variables of the token
    string public name;
    string public symbol;
    uint256 public decimals = 8;
    uint256 public totalSupply;
    address private owner;
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function BCSToken() public {
    	name = "BlockChainStore Token";                          // Set the name for display purposes
        symbol = "BCST";                                         // and symbol
    	uint256 initialSupply = 100000000;			            // 100M	tokens
        totalSupply = initialSupply * (10 ** uint256(decimals));// 8 digits for mantissa , no safeMath needed here
        balanceOf[msg.sender] = totalSupply;                    // Give the creator all initial tokens
        owner = msg.sender;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(SafeMath.add(balanceOf[_to] ,_value) >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = SafeMath.add(balanceOf[_from] , balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from]=SafeMath.sub(balanceOf[_from] , _value);
        // Add the same to the recipient
        balanceOf[_to]=SafeMath.add(balanceOf[_to] , _value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(SafeMath.add(balanceOf[_from] , balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender]=SafeMath.sub(allowance[_from][msg.sender] , _value);
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);                          // Check if the sender has enough
        require(owner==msg.sender);                                        // Check owner only can destroy
        balanceOf[msg.sender]=SafeMath.sub(balanceOf[msg.sender],_value);  // Subtract from the sender
        totalSupply = SafeMath.sub(totalSupply , _value);                  // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

}