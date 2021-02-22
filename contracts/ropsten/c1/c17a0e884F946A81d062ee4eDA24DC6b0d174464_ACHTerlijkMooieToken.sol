// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./SafeMath.sol";

contract ACHTerlijkMooieToken {
    using SafeMath for uint256;

    string public constant name = "ACHTerlijk Mooie Token";
    string public constant symbol = "ACHT";
    uint8 public constant decimals = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 totalSupply_;

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    constructor() {
        totalSupply_ = 8888888;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens % 8 == 0, "You can only send multiples of 8 tokens.");
        require(numTokens <= balances[msg.sender], "You are too poor man");

        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);

        emit Transfer(msg.sender, receiver, numTokens);

        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        require(
            numTokens % 8 == 0,
            "You can only approve multiples of 8 tokens"
        );

        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
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
        uint256 numTokens
    ) public returns (bool) {
        require(
            numTokens % 8 == 0,
            "You can only transfer multiples of 8 tokens"
        );
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);

        Transfer(owner, buyer, numTokens);

        return true;
    }
}