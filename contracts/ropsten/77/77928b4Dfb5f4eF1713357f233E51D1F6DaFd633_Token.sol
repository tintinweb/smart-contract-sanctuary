// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;

// This is the main building block for smart contracts.
contract Token {
    // Some string type variables to identify the token.
    // The `public` modifier makes a variable readable from outside the contract.
    string public name = "The Lord's Token";
    string public symbol = "LJCT";

    // The fixed amount of tokens stored in an unsigned integer type variable.
    uint256 public totalSupply = 1000000;

    // An address type variable is used to store ethereum accounts.
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) balances;

    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor() {
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    // msg.sender is always the adress where the external call came from e.g. 0x44d33a.... eth wallet address
    // msg.data — The complete calldata which is a non-modifiable, non-persistent area where function arguments are stored and behave mostly like memory
    // msg.gas — Returns the available gas remaining for a current transaction (you can learn more about gas in Ethereum here)
    // msg.sig — The first four bytes of the calldata for a function that specifies the function to be called (i.e., it’s function identifier)
    // msg.value — The amount of wei sent with a message to a contract (wei is a denomination of ETH)

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
}