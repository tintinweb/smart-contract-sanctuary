/**
 *Submitted for verification at polygonscan.com on 2021-06-29
*/

// Specifies that the source code is for a version
// of Solidity greater than 0.5.0
pragma solidity >=0.5.0 <0.7.0;

// A contract is a collection of functions and data (its state)
// that resides at a specific address on the Ethereum blockchain.
contract Coin {
    // The keyword "public" makes variables accessible from outside a contract
    // and creates a function that other contracts or SDKs can call to access the value

    string public name = "Coin";                   //fancy name: eg Simon Bucks
    uint256 public decimals = 18;                //How many decimals to show.
    string public symbol = "COIN";                 //An identifier: eg SBX

    // Returns balance of an address
    function balanceOf(address addr) public view returns (uint) {
        return balances[addr];
    }

    // An address stores addresses of contracts or external (user) accounts
    address public minter;

    // A mapping lets you create complex custom data types.
    // This mapping assigns an unsigned integer to an address
    // and is also a public variable.
    mapping (address => uint) public balances;

    // Events allow Ethereum clients to react to specific
    // contract changes you declare.
    // This defines the event and it is sent later
    event Sent(address from, address to, uint amount);

    // A special function only run during the creation of the contract
    constructor() public {
        // Uses the special msg global variable to store the
        // address of the contract creator
        minter = msg.sender;
    }

    // Sends an amount of newly created coins to an address
    function mint(address receiver, uint amount) public {
        // require statements define conditions that must pass
        // before state is changed.
        // If it fails (equals false), an exception is triggered
        // and reverts all modifications to state from the current call

        // Can only be called by the contract creator
        require(msg.sender == minter);

        // Ensures a maximum amount of tokens
        require(amount < 1e60);
        balances[receiver] += amount;
    }

    // Sends an amount of existing coins
    // from any caller to an address
    function transfer(address receiver, uint amount) public {
        // The sender must have enough coins to send
        require(amount <= balances[msg.sender], "Insufficient balance.");
        // Adjust balances
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        // Emit event defined earlier
        emit Sent(msg.sender, receiver, amount);
    }
}