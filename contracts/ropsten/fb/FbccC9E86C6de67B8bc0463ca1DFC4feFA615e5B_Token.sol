/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.8.0;

/*
CS188 Project 2
Matthew Wang
504984273
function name()
function symbol()
function decimals() function totalSupply() function balanceOf(...) function transfer(...) function transferFrom(...) function approve(...) function allowance(...)
event Transfer(...) event Approval(...)
For the name() function, have the contract return your UID. For the symbol() function, have the contract return CS188.
For the decimals() function, we recommend setting it to 18, as is com- mon amongst popular ERC20s.
In the constructor of the smart contract, give the deployer of the contract (msg.sender) some tokens so that they can be sent later.
*/

contract Token {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;
    uint8 private _decimals;

    constructor() {
        _decimals = 18;
        _totalSupply = 5 * 10**(5 + 18); // Start with 500,000 tokens
        _balances[msg.sender] = _totalSupply;
    }

    function name() public view returns (string memory) {
        return "504984273";
    }

    function symbol() public view returns (string memory) {
        return "CS188";
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(_balances[msg.sender] >= _value);

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        bool isAllowed = _allowed[_from][_to] >= _value;
        bool enoughTokens = _balances[_from] >= _value;
        require(isAllowed && enoughTokens);

        _allowed[_from][msg.sender] -= _value;
        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowed[_owner][_spender];
    }
}