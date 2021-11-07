// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./SafeMath.sol";

contract DATToken {
    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokens);
    event Approval(
        address indexed _tokenOwner,
        address indexed spender,
        uint256 _tokens
    );

    string public name = "DAT Token";
    string public symbol = "DAT";
    uint256 public totalSupply = 2000000000000000000000000;
    uint8 public constant decimals = 18;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public owner;

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address addr) public view returns (uint256) {
        return balances[addr];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(balances[msg.sender] >= numTokens, "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);

        emit Transfer(msg.sender, receiver, numTokens);

        return true;
    }

    function approve(address spender, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][spender] = numTokens;

        emit Approval(msg.sender, spender, numTokens);

        return true;
    }

    function allowance(address _owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][delegate];
    }

    function transferFrom(
        address from,
        address to,
        uint256 numTokens
    ) public returns (bool) {
        require(
            allowed[from][msg.sender] >= numTokens,
            "Insufficient allowed's owner"
        );
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);

        require(balances[from] >= numTokens, "Insufficient balance's owner");
        balances[from] = balances[from].sub(numTokens);

        balances[to] = balances[to].add(numTokens);

        emit Transfer(from, to, numTokens);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

library SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b);
        return a - b;
    }

    function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
    }

    function div(uint256 a, uint256 b) public pure returns (uint256) {
        require(b != 0);
        return a / b;
    }
}