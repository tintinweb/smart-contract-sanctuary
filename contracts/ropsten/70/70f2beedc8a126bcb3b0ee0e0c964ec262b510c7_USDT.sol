pragma solidity ^0.4.24;

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

contract USDT is ERC20Basic {
    // Public variables of the token
    uint8 public decimals = 6;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply_;
    string public symbol = "USDT";


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf_;

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor (uint256 initialSupply) public {
        totalSupply_ = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf_[msg.sender] = totalSupply_;                // Give the creator all initial tokens
    }

    /**
      * @dev total number of tokens in existence
      */
    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
      return balanceOf_[_owner];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf_[_from] >= _value);
        // Check for overflows
        require(balanceOf_[_to] + _value >= balanceOf_[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf_[_from] + balanceOf_[_to];
        // Subtract from the sender
        balanceOf_[_from] -= _value;
        // Add the same to the recipient
        balanceOf_[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf_[_from] + balanceOf_[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

}