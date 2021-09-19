/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

pragma solidity ^0.5.0;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a / b;
        require(b > 0);
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(a == 0 || c / a == b);
        c = a * b;
    }
}

contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner) public view returns (uint256);

    function transfer(address to, uint256 tokens) public returns (bool success);



    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
}

contract TokenTest3 is ERC20, SafeMath {
    address public sender;
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => mapping(address => uint256)) public deposits;

    constructor() public {
        name = "TokenTotalMint";
        symbol = "TTK";
        decimals = 18;
        _totalSupply = 1000000000000000000000;

        balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }



}