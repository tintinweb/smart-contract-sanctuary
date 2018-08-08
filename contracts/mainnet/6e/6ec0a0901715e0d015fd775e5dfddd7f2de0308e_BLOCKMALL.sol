pragma solidity ^0.4.18;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract Token {

    /// total amount of tokens
    uint256 public totalSupply;

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

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/*
You should inherit from StandardToken or, for a token like you would want to
deploy in something like Mist, see HumanStandardToken.sol.
(This implements ONLY the standard functions and NOTHING else.
If you deploy this, you won&#39;t have anything useful.)

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Prevent transfer to 0x0 address.
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[msg.sender] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);

        uint previousBalances = balances[msg.sender] + balances[_to];
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[msg.sender] + balances[_to] == previousBalances);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        /// same as above
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);

        uint previousBalances = balances[_from] + balances[_to];
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        assert(balances[_from] + balances[_to] == previousBalances);

        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances; /// balance amount of tokens for address
    mapping (address => mapping (address => uint256)) allowed;
}

contract BLOCKMALL is StandardToken {

    function () payable public {
        //if ether is sent to this address, send it back.
        //throw;
        require(false);
    }

    string public constant name = "BLOCKMALL";   
    string public constant symbol = "BXM";
    uint256 private constant _INITIAL_SUPPLY = 100000000*10**uint256(decimals);
    uint8 public decimals = 18;         
    uint256 public totalSupply;            
    //string public version = &#39;H0.1&#39;;

    function BLOCKMALL(
    ) public {
        // init
        balances[msg.sender] = _INITIAL_SUPPLY;
        totalSupply = _INITIAL_SUPPLY;
       
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}