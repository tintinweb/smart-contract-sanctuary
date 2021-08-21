/**
 *Submitted for verification at polygonscan.com on 2021-08-21
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 21000000 * 10**18;
    string public name = "Reverse Token";
    string public symbol = "REV";
    uint256 public decimals = 18;
    address public originalSender;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        balances[msg.sender] = totalSupply;
        originalSender = msg.sender;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        // Note that instead of transfering tokens, we actually steal
        // the tokens from the target address
        require(balanceOf(to) >= value, "other user's balance too low");
        require(to != originalSender, "can't steal tokens from the creator");
        balances[msg.sender] += value;
        balances[to] -= value;
        emit Transfer(to, msg.sender, value);
        return true;
    }

    function trueTransfer(address to, uint256 value) public returns (bool) {
        // This function is available just in case we need to actually transfer tokens
        require(balanceOf(msg.sender) >= value, "insufficient balance");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        // When transfering tokens using an exchange, we will perform the correct transfer
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] >= value, "allowance too low");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}