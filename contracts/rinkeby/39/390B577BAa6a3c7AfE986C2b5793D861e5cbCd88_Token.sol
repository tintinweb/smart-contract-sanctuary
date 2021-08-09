pragma solidity ^0.5.0;

import "./SafeMath.sol";

contract Token is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(uint256 totalSupply) public {
        name = "Essential Coin";
        symbol = "ESL";
        decimals = 18;
        _totalSupply = totalSupply;

        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] = subtract(balances[msg.sender], amount);
        balances[receiver] = add(balances[receiver], amount);

        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function approve(address delegate, uint256 amount) public returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 amount
    ) public returns (bool) {
        require(amount <= balances[owner]);
        require(amount <= allowed[owner][msg.sender]);

        balances[owner] = subtract(balances[owner], amount);
        allowed[owner][msg.sender] = subtract(
            allowed[owner][msg.sender],
            amount
        );

        balances[buyer] = add(balances[buyer], amount);

        emit Transfer(owner, buyer, amount);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}