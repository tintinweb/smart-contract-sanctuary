pragma solidity ^0.4.19;

// Name your new coin. Make sure the constructor has the same name.
contract Serum {

    // This will be you, the minter. It is set in the constructor.
    address public minter;

    // This mapping stores everyone&#39;s balances.
    mapping (address => uint) public balances;

    // This event will track when someone sends some tokens.
    event Sent(address from, address to, uint amount);
    event Mint(uint amount);

    // This is the constructor. It runs only once, when the contract is created.
    function MyCoin() public {
        minter = msg.sender;
    }

    // Function to create some new coins for someone.
    // As the minter, only you will have access to this.
    function mint(address receiver, uint amount) public {
        if (msg.sender != minter) return;
        balances[receiver] += amount;
        Mint(amount);
    }

    // Function to send some coins. Anyone with coins can do this.
    function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Sent(msg.sender, receiver, amount);
    }
}