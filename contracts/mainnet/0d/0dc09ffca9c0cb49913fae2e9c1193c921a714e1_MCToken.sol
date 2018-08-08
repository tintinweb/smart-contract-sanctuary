pragma solidity ^0.4.4;

/**
*
* ERC20 token
*
* doc https://github.com/ethereum/EIPs/issues/20
*
*/
contract ERC20Token {

    function totalSupply() constant returns (uint256 supply) {}

    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/**
*
* Master Coin Token
*
* author luc
* date 2018/6/14
*
*/
contract MCToken is ERC20Token {

    string private _name = "Master Coin";
    string private _symbol = "MC";
    uint8 private _decimals = 18;

    uint256 private _totalSupply = 210000000 * (10 ** uint256(_decimals));

    mapping(address=>uint256) private _balances;
    mapping(address=>mapping(address=>uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function MCToken() {
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view returns (string name){
        name = _name;
    }

    function symbol() public view returns (string symbol){
        symbol = _symbol;
    }

    function decimals() public view returns (uint8 decimals){
        decimals = _decimals;
    }

    function totalSupply() public view returns (uint256 totalSupply){
        totalSupply = _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        balance = _balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_balances[msg.sender] >= _value);
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        success = true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_balances[_from] >= _value);
        require(_allowances[_from][msg.sender] >= _value);

        uint256 previousBalances = _balances[_from] + _balances[_to];

        _balances[_from] -= _value;
        _allowances[_from][msg.sender] -= _value;
        _balances[_to] += _value;
        Transfer(_from, _to, _value);

        assert(_balances[_from] + _balances[_to] == previousBalances);

        success = true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        _allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        success = true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        remaining = _allowances[_owner][_spender];
    }
}