pragma solidity ^0.4.16;

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

  function toUINT112(uint256 a) internal constant returns(uint112) {
    assert(uint112(a) == a);
    return uint112(a);
  }

  function toUINT120(uint256 a) internal constant returns(uint120) {
    assert(uint120(a) == a);
    return uint120(a);
  }

  function toUINT128(uint256 a) internal constant returns(uint128) {
    assert(uint128(a) == a);
    return uint128(a);
  }
}

contract HelloToken {
    using SafeMath for uint256;
    // Public variables of the token
    string public constant name    = "Hello Token";  //The Token&#39;s name
    uint8 public constant decimals = 18;               //Number of decimals of the smallest unit
    string public constant symbol  = "HelloT";            //An identifier    
    // 18 decimals is the strongly suggested default, avoid changing it
    
    // packed to 256bit to save gas usage.
    struct Supplies {
        // uint128&#39;s max value is about 3e38.
        // it&#39;s enough to present amount of tokens
        uint128 totalSupply;
    }
    
    Supplies supplies;
    
    // Packed to 256bit to save gas usage.    
    struct Account {
        // uint112&#39;s max value is about 5e33.
        // it&#39;s enough to present amount of tokens
        uint112 balance;
    }
    

    // This creates an array with all balances
    mapping (address => Account) public balanceOf;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function HelloToken() public {
        supplies.totalSupply = 1*(10**10) * (10 ** 18);  // Update total supply with the decimal amount
        balanceOf[msg.sender].balance = uint112(supplies.totalSupply);                // Give the creator all initial tokens
    }
    
    // Send back ether sent to me
    function () {
        revert();
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from].balance >= _value);
        // Check for overflows
        require(balanceOf[_to].balance + _value >= balanceOf[_to].balance);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].balance + balanceOf[_to].balance;
        // Subtract from the sender
        balanceOf[_from].balance -= uint112(_value);
        // Add the same to the recipient
        balanceOf[_to].balance = _value.add(balanceOf[_to].balance).toUINT112();
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].balance + balanceOf[_to].balance == previousBalances);
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
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender].balance >= _value);   // Check if the sender has enough
        balanceOf[msg.sender].balance -= uint112(_value);            // Subtract from the sender
        supplies.totalSupply -= uint128(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    /**
     * Total Supply
     *
     * View Total Supply
     *
     * Return Total Supply
     * 
     */
    function totalSupply() public constant returns (uint256 supply){
        return supplies.totalSupply;
    }
}