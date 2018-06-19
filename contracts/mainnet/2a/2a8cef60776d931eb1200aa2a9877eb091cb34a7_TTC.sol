pragma solidity ^0.4.0;


contract TTC {
    
    
    // function balanceOf(address _owner) public view returns (uint256 balance);
    // function transfer(address _to, uint256 _value) public returns (bool success);
    // function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    // function approve(address _spender, uint256 _value) public returns (bool success);
    // function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public name;                   //fancy name: eg Simon Bucks
    string public symbol;                 //An identifier: eg SBX
    uint8 public decimals;                //How many decimals to show.
    
    uint256 public totalSupply;
    
    address admin;
    mapping (address => bool) admin_list;

    function TTC(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        admin = msg.sender;
        admin_list[admin] = true;
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
    
    function admin_setAdmin(address _target,bool _isAdmin) public returns (bool success) {
        require(msg.sender == admin);
        admin_list[_target] = _isAdmin;
        return true;
    }
    
    function admin_transfer(address _from, address _to, uint256 _value) public returns (bool success) {
        require(admin_list[msg.sender]);
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
}