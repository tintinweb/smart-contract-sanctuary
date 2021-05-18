// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "IERC20.sol";
import "SafeMath.sol";

contract FourTBank is IERC20 {

    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;
    
    address _owner;
    uint256 _totalSupply;
    
    uint8 public constant decimals = 4;
    string public constant name = "4TB Coin";
    string public constant symbol = "4TB";

    using SafeMath for uint256;

    constructor(uint256 total) {
        _owner = msg.sender;
        _totalSupply = total;
        balances[msg.sender] = _totalSupply;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function burn(uint256 amount) public {
        require(amount <= balances[msg.sender]);
        _totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function mint(uint256 amount) public {
        require(msg.sender == _owner);
        _totalSupply += amount;
        balances[_owner] += amount;
        emit Transfer(address(0), _owner, amount);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}