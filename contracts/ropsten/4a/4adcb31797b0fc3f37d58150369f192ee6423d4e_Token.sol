pragma solidity ^0.4.25;

contract ERC20 {
  /// @return total amount of tokens
    function totalSupply() public view returns (uint256 _supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract Token is ERC20, owned {
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;


    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
        string tokenName,
        string tokenSymbol,
        address initialOwner
        ) public {
        balances[initialOwner] = 10000000000000000000;              // Give the creator all initial tokens
        _totalSupply = 10000000000000000000;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = 18;                            // Amount of decimals for display purposes
        owner = initialOwner;
    }

    /// @return total amount of tokens
    function totalSupply() public view returns (uint256 supply) {
      supply = _totalSupply;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance){
      return balances[_owner];
    }

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value
          && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;                     // Subtract from the sender
            balances[_to] += _value;                            // Add the same to the recipient
            emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
            return true;
        } else {
          return false;
        }
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value // Check if the sender has enough
          && balances[_to] + _value > balances[_to] // Check for overflows
          && allowed[_from][msg.sender] >= _value) { // Check allowance
            balances[_from] -= _value;                          // Subtract from the sender
            balances[_to] += _value;                            // Add the same to the recipient
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }else{
          return false;
        }
    }

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public{
        revert();     // Prevents accidental sending of ether
    }
}