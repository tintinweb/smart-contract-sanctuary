// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.11;

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


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
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

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract CNYTokenPlus is StandardToken {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    address public founder;               // The address of the founder
    string public name;                   // fancy name: eg Simon Bucks
    uint8 public decimals;                // How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
    string public symbol;                 // An identifier: eg SBX
    string public version = &#39;CNYt+1.0&#39;;     // CNYt+ 1.0 standard. Just an arbitrary versioning scheme.
    

    // The nonce for avoid transfer replay attacks
    mapping(address => uint256) nonces;

    // The last comment for address
    mapping(address => string) lastComment;

    // The comments for transfers per address
    mapping (address => mapping (uint256 => string)) comments;

    function CNYTokenPlus(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol) {
        founder = msg.sender;                                // Save the creator address
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes  
    }

   function transferWithComment(address _to, uint256 _value, string _comment) returns (bool success) {
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            lastComment[msg.sender] = _comment;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFromWithComment(address _from, address _to, uint256 _value, string _comment) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            lastComment[_from] = _comment;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Proxy transfer CNY token. When some users of the ethereum account has no ether,
     * he or she can authorize the agent for broadcast transactions, and agents may charge agency fees
     * @param _from
     * @param _to
     * @param _value
     * @param fee
     * @param _v
     * @param _r
     * @param _s
     * @param _comment
     */
    function transferProxy(address _from, address _to, uint256 _value, uint256 _fee,
        uint8 _v,bytes32 _r, bytes32 _s, string _comment) returns (bool){

        if(balances[_from] < _fee + _value) throw;

        uint256 nonce = nonces[_from];
                
        bytes32 hash = sha3(_from,_to,_value,_fee,nonce);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha3(prefix, hash);
        if(_from != ecrecover(prefixedHash,_v,_r,_s)) throw;

        if(balances[_to] + _value < balances[_to]
            || balances[msg.sender] + _fee < balances[msg.sender]) throw;
        balances[_to] += _value;
        Transfer(_from, _to, _value);

        balances[msg.sender] += _fee;
        Transfer(_from, msg.sender, _fee);

        balances[_from] -= _value + _fee;
        lastComment[_from] = _comment;
        comments[_from][nonce] = _comment;
        nonces[_from] = nonce + 1;
        
        return true;
    }

    /*
     * Proxy approve that some one can authorize the agent for broadcast transaction
     * which call approve method, and agents may charge agency fees
     * @param _from The  address which should tranfer CNY to others
     * @param _spender The spender who allowed by _from
     * @param _value The value that should be tranfered.
     * @param _v
     * @param _r
     * @param _s
     * @param _comment
     */
    function approveProxy(address _from, address _spender, uint256 _value,
        uint8 _v,bytes32 _r, bytes32 _s, string _comment) returns (bool success) {

        if(balances[_from] < _value) throw;
        
        uint256 nonce = nonces[_from];
        
        bytes32 hash = sha3(_from,_spender,_value,nonce);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = sha3(prefix, hash);
        if(_from != ecrecover(prefixedHash,_v,_r,_s)) throw;

        allowed[_from][_spender] = _value;
        Approval(_from, _spender, _value);
        lastComment[_from] = _comment;
        comments[_from][nonce] = _comment;
        nonces[_from] = nonce + 1;
        return true;
    }


    /*
     * Get the nonce
     * @param _addr
     */
    function getNonce(address _addr) constant returns (uint256){
        return nonces[_addr];
    }

    /*
     * Get last comment
     * @param _addr
     */
    function getLastComment(address _addr) constant returns (string){
        return lastComment[_addr];
    }

    /*
     * Get specified comment
     * @param _addr
     */
    function getSpecifiedComment(address _addr, uint256 _nonce) constant returns (string){
        if (nonces[_addr] < _nonce) throw;
        return comments[_addr][_nonce];
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    /* Approves and then calls the contract code*/
    function approveAndCallcode(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //Call the contract code
        if(!_spender.call(_extraData)) { throw; }
        return true;
    }

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) throw;            // Check if the sender has enough
        balances[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        if (balances[_from] < _value) throw;                // Check if the sender has enough
        if (_value > allowed[_from][msg.sender]) throw;    // Check allowance
        balances[_from] -= _value;                          // Subtract from the sender
        totalSupply -= _value;                               // Updates totalSupply
        Burn(_from, _value);
        return true;
    }
}