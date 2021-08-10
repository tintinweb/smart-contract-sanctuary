/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.5.0;

contract TstToken {
    string public name = "Test Token";
    string public symbol = "TST";
    string public standard = "TST Token v1.0";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    constructor(uint256 initialSupply) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        if (tokens <= balanceOf[msg.sender]) {
            return false;
        }

        balanceOf[msg.sender] -= tokens;
        balanceOf[to] += tokens;

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        allowance[msg.sender][spender] = tokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool) {
        if (
            tokens <= 0 ||
            tokens <= balanceOf[from] ||
            tokens > allowance[from][msg.sender]
        ) {
            return false;
        }

        balanceOf[from] -= tokens;
        balanceOf[to] += tokens;

        allowance[from][msg.sender] = tokens;

        emit Transfer(from, to, tokens);
        return true;
    }

    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );

    event Transfer(address indexed from, address indexed to, uint256 tokens);
}