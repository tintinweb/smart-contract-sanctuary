/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.8.5;

contract ImperiumERC20
{
    /* Core ERC20 Requirements */
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    /* Balances - Allowances */
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /* Constants */
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    /* Ownership Attributes */
    address _master;

    /* constructor */
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_)
    {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;

        //Master Controls
        _master = msg.sender;
        _balances[_master] = totalSupply_;
    }

    /* Core Attributes Getters */
    function name() public view returns(string memory)
    {
        return _name;
    }

    function symbol() public view returns(string memory)
    {
        return _symbol;
    }

    function decimals() public view returns (uint8)
    {
        return _decimals;
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    /* Core Attributes Getters - Remote Accounts */
    function balanceOf(address _owner) public view returns (uint256)
    {
        return _balances[_owner];
    }

    /* Events */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    /* Transfer Methods */
    function transfer(address _to, uint256 _value) public returns (bool)
    {
        require(_balances[msg.sender] >= _value);
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool)
    {
        uint256 allowance = _allowances[_from][msg.sender];
        require(_balances[_from] >= _value && allowance >= _value);
        _balances[_to] += _value;
        _balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            _allowances[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool)
    {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function mint(uint256 _value) public returns(bool)
    {
        require(msg.sender == _master, "Not authorized to mint");
        _balances[_master] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), _master, _value);
        return true;
    }

    function burn(uint256 _value) public returns(bool)
    {
        require(msg.sender == _master, "Not authorized to burn");
        require(_balances[msg.sender] >= _value, "Insufficient amount to burn");
        _balances[msg.sender] -= _value;
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }

    function mintFor(address _for, uint256 _value) public returns(bool)
    {
        require(msg.sender == _master, "Not authorized to mintFor");
        _balances[_for] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), _for, _value);
        return true;
    }

    function destroySmartContract(address payable _to) public {
        require(msg.sender == _master, "You are not the owner");
        selfdestruct(_to);
    }
}