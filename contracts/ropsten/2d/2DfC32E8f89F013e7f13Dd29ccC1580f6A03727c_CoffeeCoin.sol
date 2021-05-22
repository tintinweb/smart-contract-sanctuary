/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED

contract CoffeeCoin {
    string private _token_name;
    string private _token_symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _minter;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() {
        _token_name = "CoffeeWarCoin";
        _token_symbol = "CWC";
        _decimals = 18;
        _totalSupply = 8 * 10 ** (8 + 18);
        _minter = msg.sender;

        balances[_minter] = _totalSupply;
        emit Transfer(address(0), _minter, _totalSupply);
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory){
        return _token_name;
    }
    function symbol() public  view returns (string memory) {
        return _token_symbol;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens, "Check balance");
        require(tokens > 0, "tokens should be > 0");
        require(spender != msg.sender, "You can't approve coins to your account");

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens, "Check balance");
        require(to != msg.sender, "You can't transfer coins to your account");
        require(tokens > 0, "tokens should be > 0");

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(msg.sender != from, "Use Transfer for this");
        require(balances[from] >= tokens, "balances[from]>= tokens");
        require(allowed[from][msg.sender] >=  tokens, "allowed[from][msg.sender] >=  tokens");
        require(tokens > 0, "tokens > 0");

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == _minter, "ERC20: only the creator of the smart contract can add new tokens to the balance");
        require(amount > 0, "amount > 0");


         _totalSupply = safeAdd(_totalSupply, amount);
        balances[receiver] += amount;
        emit Transfer(address(0), receiver, amount);
    }


    function burn(uint256 amount) public {
        require(balances[msg.sender] >= amount, "ERC20: balance[msg.sender] >= amount");
        require(amount > 0, "ERC20: amount > 0");

        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        _totalSupply = safeSub(_totalSupply, amount);
        emit Transfer(msg.sender, address(0), amount);

    }

    function safeAdd(uint a, uint b) private pure returns (uint c) {
        c = a + b;
//        require(c >= a);
    }
    function safeSub(uint a, uint b) private pure returns (uint c) {
//        require(b <= a);
        c = a - b; }


}