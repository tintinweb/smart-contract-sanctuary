pragma solidity ^0.4.24;

// ERC20 token contract

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}

contract MeerkatToken is ERC20Interface {
    address public owner;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public initSupply;

    mapping(address => uint) balances;

    constructor() public {
        owner = msg.sender;
        symbol = "MCT";
        name = "Meerkat Token";
        decimals = 18;
        initSupply = 10000000000 * 10**uint(decimals);
        balances[owner] = initSupply;
        
        emit Transfer(address(0), owner, initSupply);
    }

    function totalSupply() public constant returns (uint) {
        return initSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        uint previousBalances = balances[msg.sender] + balances[_to];

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        assert(balances[msg.sender] + balances[_to] == previousBalances);
        
        return true;
    }

    function () public payable {
        revert();
    }

}