/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

pragma solidity ^0.7.0;



contract Token {
    string public name = "Web Test Token";
    string public symbol = "WTT";
    uint256 public totalSupply = 1000000;

    address public owner;
    mapping(address => uint256) balances;


    constructor() {

        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    /**
     * A function to transfer tokens.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external {

        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    /**
     * Read only function to retrieve the token balance of a given account.
     *
     * The `view` modifier indicates that it doesn't modify the contract's
     * state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * Test function for minting of tokens
     */
    function mint(uint256 amount) external{
        balances[msg.sender] += amount;
        totalSupply += amount;
    }
}