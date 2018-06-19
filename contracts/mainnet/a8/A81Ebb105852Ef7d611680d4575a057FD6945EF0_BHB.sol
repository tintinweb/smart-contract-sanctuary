pragma solidity ^0.4.16;

interface TokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract BHB {
    string public name;
    string public symbol;
    uint8  public decimals = 6;
    uint256 public totalSupply;

    // Balances
    mapping (address => uint256) balances;
    // Allowances
    mapping (address => mapping (address => uint256)) allowances;

    // ----- Events -----
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    /**
     * Constructor function
     */
    function BHB(uint256 _initialSupply, string _tokenName, string _tokenSymbol, uint8 _decimals) public {
        name = _tokenName;                                   // Set the name for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
        decimals = _decimals;

        totalSupply = _initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;                // Give the creator all initial tokens
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal returns(bool) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balances[_from] >= _value);
        // Check for overflows
        require(balances[_to] + _value > balances[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balances[_from] + balances[_to];
        // Subtract from the sender
        balances[_from] -= _value;
        // Add the same to the recipient
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balances[_from] + balances[_to] == previousBalances);

        return true;
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns(bool) {
        return _transfer(msg.sender, _to, _value);
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
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        require(_value <= allowances[_from][msg.sender]);     // Check allowance
        allowances[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public returns(bool) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool) {
        if (approve(_spender, _value)) {
            TokenRecipient spender = TokenRecipient(_spender);
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
        return false;
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        // Check for overflows
        require(allowances[msg.sender][_spender] + _addedValue > allowances[msg.sender][_spender]);

        allowances[msg.sender][_spender] += _addedValue;
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue - _subtractedValue;
        }
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
}