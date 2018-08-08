/**
 *  DickheadCash contract
 */

pragma solidity 0.4.15;


contract ERC20TokenInterface {

    /// @return The total amount of tokens
    function totalSupply() constant returns (uint256 supply);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant public returns (uint256 balance);

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

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant public returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}


contract DickheadCash is ERC20TokenInterface {

    string public constant name = "DickheadCash";
    string public constant symbol = "DICK";
    uint256 public constant decimals = 0;
    uint256 public totalTokens = 1 * (10 ** decimals);
    uint8 public constant MAX_TRANSFERS = 7;

    mapping (address => bool) public received;
    mapping (address => uint8) public transfers;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;


    function DickheadCash() {
        balances[msg.sender] = totalTokens;
        received[msg.sender] = true;
    }

    function totalSupply() constant returns (uint256) {
        return totalTokens;
    }

    function transfersRemaining() returns (uint8) {
        return MAX_TRANSFERS - transfers[msg.sender];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_value > 1) return false;
        if (transfers[msg.sender] >= MAX_TRANSFERS) return false;
        if (received[_to]) return false;
        if (received[msg.sender]) {
            balances[_to] = _value;
            transfers[msg.sender]++;
            if (!received[_to]) received[_to] = true;
            totalTokens += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        return false;
    }

    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return false;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return 0;
    }

}