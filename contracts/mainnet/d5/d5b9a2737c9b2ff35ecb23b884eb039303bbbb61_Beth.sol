/**
 *  Beth token contract, ERC20 compliant (see https://github.com/ethereum/EIPs/issues/20)
 *
 *  Code is based on multiple sources:
 *  https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/token/ERC20.sol
 *  https://github.com/ConsenSys/Tokens/blob/master/Token_Contracts/contracts/Token.sol
 */

pragma solidity ^0.4.8;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Beth is Token {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }
     
    address public owner;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public frozenAccount;

    //// Events ////
    event MigrationInfoSet(string newMigrationInfo);
    event FrozenFunds(address target, bool frozen);
    
    // This is to be used when migration to a new contract starts.
    // This string can be used for any authorative information re the migration
    // (e.g. address to use for migration, or URL to explain where to find more info)
    string public migrationInfo = "";

    modifier onlyOwner{ if (msg.sender != owner) throw; _; }

    /* Public variables of the token */
    string public name = "Beth";
    uint8 public decimals = 18;
    string public symbol = "BTH";
    string public version = "1.0";

    bool private stopped = false;
    modifier stopInEmergency { if (!stopped) _; }

    function Beth() {
        owner = 0xa62dFc3a5bf6ceE820B916d5eF054A29826642e8;
        balances[0xa62dFc3a5bf6ceE820B916d5eF054A29826642e8] = 2832955 * 1 ether;
        totalSupply = 2832955* 1 ether;
    }


    function transfer(address _to, uint256 _value) stopInEmergency returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                // Check if frozen
        if (balances[msg.sender] < _value) throw;
        if (_value <= 0) throw;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) stopInEmergency  returns (bool success) {
        if (frozenAccount[msg.sender]) throw;                // Check if frozen
        if (balances[_from] < _value) throw;
        if (allowed[_from][msg.sender] < _value) throw;
        if (_value <= 0) throw;
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            throw; 
        }
        return true;
    }

    // Allows setting a descriptive string, which will aid any users in migrating their token
    // to a newer version of the contract. This field provides a kind of &#39;double-layer&#39; of
    // authentication for any migration announcement, as it can only be set by WeTrust.
    /// @param _migrationInfo The information string to be stored on the contract
    function setMigrationInfo(string _migrationInfo) onlyOwner public {
        migrationInfo = _migrationInfo;
        MigrationInfoSet(_migrationInfo);
    }

    // Owner can set any account into freeze state. It is helpful in case if account holder has 
    // lost his key and he want administrator to freeze account until account key is recovered
    // @param target The account address
    // @param freeze The state of account
    function freezeAccount(address target, bool freeze) onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    // It is called Circuit Breakers (Pause contract functionality), it stop execution if certain conditions are met, 
    // and can be useful when new errors are discovered. For example, most actions may be suspended in a contract if a 
    // bug is discovered, so the most feasible option to stop and updated migration message about launching an updated version of contract. 
    // @param _stop Switch the circuite breaker on or off
    function emergencyStop(bool _stop) onlyOwner {
        stopped = _stop;
    }

    // changeOwner is used to change the administrator of the contract. This can be useful if owner account is suspected to be compromised
    // and you have luck to update owner.
    // @param _newOwner Address of new owner
    function changeOwner(address _newOwner) onlyOwner {
        balances[_newOwner] = balances[owner];
        balances[owner] = 0;
        owner = _newOwner;
        Transfer(owner, _newOwner,balances[_newOwner]);
    }

}