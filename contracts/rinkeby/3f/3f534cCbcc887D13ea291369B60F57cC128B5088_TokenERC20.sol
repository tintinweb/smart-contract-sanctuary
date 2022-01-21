//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    // Getter functions
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    // Functions
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract TokenERC20 is ERC20 {
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint256 public _totalSupply;
    address public owner;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    constructor() {
        _name = "Kazakhstan tenge";
        _symbol = "KZT";
        _decimals = 18;
        _totalSupply = 10**_decimals;

        owner = msg.sender;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function"
        );
        _; // body of function will be there :3
    }

    // Getter functions
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    // Functions
    function transfer(address _to, uint256 _value) public override returns (bool success){
        require(balances[msg.sender] >= _value, "Value more than your balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(
            balances[_from] >= _value,
            "Cannot transfer such value of tokens, check balance"
        );
        require(
            allowed[_from][msg.sender] >= _value,
            "Cannot transfer such value of tokens, check allowance"
        );

        balances[_from] -= _value;
        balances[_to] += _value;

        allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success){
        require(
            balanceOf(msg.sender) >= _value,
            "Your balance less, than value"
        );

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function increaseAllowance(address _from, uint256 _value) public returns (bool success){
        allowed[msg.sender][_from] += _value;
        return true;
    }

    function decreaseAllowance(address _from, uint256 _value) public returns (bool success){
        require(
            allowed[msg.sender][_from] >= _value,
            "Allowed much less than could be decreased"
        );

        allowed[msg.sender][_from] -= _value;
        return true;
    }

    function mint(uint256 _value) public onlyOwner returns (bool success) {
        balances[owner] += _value;
        _totalSupply += _value;

        emit Transfer(address(0), owner, _value);
        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(
            balanceOf(owner) >= _value,
            "You haven't such amount of tokens"
        );

        balances[owner] -= _value;
        _totalSupply -= _value;

        emit Transfer(owner, address(0), _value);
        return true;
    }
}