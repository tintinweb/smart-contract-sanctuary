/**********


 */
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

contract SimpleToken{
    string public _name = "ERC20Basic";
    string public _symbol = "BSC";
    uint8 public constant _decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    uint256 _totalSupply;

    using SafeMath for uint256;

    constructor(
        string memory _name_,
        string memory _symbol_,
        uint256 total
    ) {
        _name = _name_;
        _symbol = _symbol_;
        _totalSupply = total;
        balances[msg.sender] = _totalSupply;
    }

    function init(
        string memory _name_,
        string memory _symbol_,
        uint256 total
    ) public  {
        _name = _name_;
        _symbol = _symbol_;
        _totalSupply = total;
        balances[msg.sender] = _totalSupply;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender], "Not enough tokens to make a transfer");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function increaseApproval(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = allowed[msg.sender][delegate] + numTokens;
        emit Approval(msg.sender, delegate, allowed[msg.sender][delegate]);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint256) {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balances[owner], "Balance is too small");
        require(numTokens <= allowed[owner][msg.sender], "Approval is too small");

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}