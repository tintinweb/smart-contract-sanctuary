pragma solidity ^0.4.10;


/// @title Abstract token contract - Functions to be implemented by token contracts.
contract Token {
    function transfer(address to, uint256 value) returns (bool success);
    function transferFrom(address from, address to, uint256 value) returns (bool success);
    function approve(address spender, uint256 value) returns (bool success);

    // This is not an abstract function, because solc won&#39;t recognize generated getter functions for public variables as functions.
    function totalSupply() constant returns (uint256) {}
    function balanceOf(address owner) constant returns (uint256 balance);
    function allowance(address owner, address spender) constant returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/// @title Standard token contract - Standard token interface implementation.
contract StandardToken is Token {

    /*
     *  Data structures
     */
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

    /*
     *  Public functions
     */
    /// @dev Transfers sender&#39;s tokens to a given address. Returns success.
    /// @param _to Address of token receiver.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transfer(address _to, uint256 _value)
        public
        returns (bool)
    {
        if (balances[msg.sender] < _value) throw;           // Insufficient funds
        if (balances[_to] + _value < balances[_to]) throw;  // Check for overflows
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Allows allowed third party to transfer tokens from one address to another. Returns success.
    /// @param _from Address from where tokens are withdrawn.
    /// @param _to Address to where tokens are sent.
    /// @param _value Number of tokens to transfer.
    /// @return Returns success of function call.
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool)
    {
        if (balances[_from] < _value || allowed[_from][msg.sender] < _value) {
            // Balance or allowance too low
            throw;
        }
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Sets approved amount of tokens for spender. Returns success.
    /// @param _spender Address of allowed account.
    /// @param _value Number of approved tokens.
    /// @return Returns success of function call.
    function approve(address _spender, uint256 _value)
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
     * Read functions
     */
    /// @dev Returns number of allowed tokens for given address.
    /// @param _owner Address of token owner.
    /// @param _spender Address of token spender.
    /// @return Returns remaining allowance for spender.
    function allowance(address _owner, address _spender)
        constant
        public
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    /// @dev Returns number of tokens owned by given address.
    /// @param _owner Address of token owner.
    /// @return Returns balance of owner.
    function balanceOf(address _owner)
        constant
        public
        returns (uint256)
    {
        return balances[_owner];
    }
}


/// @title DelphiToken contract
/// @author Christopher Grant - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f99a918b908a8d9689919c8bb99d9c95899190d794988b929c8d8a">[email&#160;protected]</a>>
contract DelphiToken is StandardToken {

    /*
     *  Token meta data
     */
    string constant public name = "Delphi";
    string constant public symbol = "DEL";
    uint constant public tokenDecimals = 10**18;

    /*
     *  Public functions
     */

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function DelphiToken() public {
        uint256 initialSupply = 10000000 * tokenDecimals;
        balances[msg.sender] = initialSupply;
    }

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }
}