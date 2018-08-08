pragma solidity ^0.4.17;

contract ETHTest01Token{
    mapping (address => uint256) balances;
    address public owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    // total amount of tokens
    uint256 public totalSupply;
    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;
    constructor() public {
        owner = 0xF48be01754b8FC91a48D193D0194bBd4f8e2DB6b;          // Set owner of contract
        name = "ETHTest01";                                   // Set the name for display purposes
        symbol = "ETHTest01";                                           // Set the symbol for display purposes
        decimals = 18;                                            // Amount of decimals for display purposes
        totalSupply = 10000000000000000000000000000;               // Total supply
        balances[owner] = totalSupply;
    }

    /// @return The totalSupply
    function totalSupply() public constant returns (uint256) {
        return totalSupply;
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);                 // Check if the sender has enough
        require(balances[_to] + _value >= balances[_to]);   // Check for overflows
        require(_value <= allowed[_from][msg.sender]);      // Check allowance
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () private {
        revert();     // Prevents accidental sending of ether
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}