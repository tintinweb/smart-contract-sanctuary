/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.5.0;

contract GfdToken {
    string public name = "GFD Token";
    string public symbol = "GFD";
    string public standard = "GFD Token v1.0";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;

    constructor(uint256 initialSupply) public {
        uint256 toUseSupply = initialSupply * 10**uint256(decimals);

        balanceOf[msg.sender] = toUseSupply;
        totalSupply = toUseSupply;
    }

    function transfer(address to, uint256 tokens) public returns (bool) {
        uint256 toTransferTokens = tokens * 10**uint256(decimals);

        if (toTransferTokens <= balanceOf[msg.sender]) {
            return false;
        }

        balanceOf[msg.sender] -= toTransferTokens;
        balanceOf[to] += toTransferTokens;

        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function approve(address spender, uint256 tokens) public returns (bool) {
        uint256 toApproveTokens = tokens * 10**uint256(decimals);

        allowance[msg.sender][spender] = toApproveTokens;

        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public returns (bool) {
        uint256 toTransferTokens = tokens * 10**uint256(decimals);
        if (
            toTransferTokens <= 0 ||
            toTransferTokens <= balanceOf[from] ||
            toTransferTokens > allowance[from][msg.sender]
        ) {
            return false;
        }

        balanceOf[from] -= toTransferTokens;
        balanceOf[to] += toTransferTokens;

        allowance[from][msg.sender] -= toTransferTokens;

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