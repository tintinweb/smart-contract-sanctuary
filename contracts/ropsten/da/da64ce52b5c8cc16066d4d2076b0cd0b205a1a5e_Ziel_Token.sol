/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.4.23;


contract Ziel_Token {
    address public minter;
    string  public name;
    string  public symbol;
    uint256 public decimals;
    uint256 public totalSupply_;
    uint256 public constant RATE = 3000; // Number of tokens per Ether
    uint256 public constant CAP = 5350; // Cap in Ether
    uint256 public constant initialTokens = 6000000 * 10**18; // Initial number of tokens available
    
    mapping(address => uint256) balances;

    constructor() public {
        name = "Ziel Token (ZIEL)";
        symbol = "ZIEL";
        decimals = 18;
        totalSupply_ = 100 ether;
        balances[msg.sender] = totalSupply_;
    }

    function mint(address receiver, uint amount) public {
        if (msg.sender != minter) return;
        balances[receiver] += amount;
    }
/*
    function name() public view returns (string) {
        if (msg.sender != minter) return;
        return name;
    }
*/
}