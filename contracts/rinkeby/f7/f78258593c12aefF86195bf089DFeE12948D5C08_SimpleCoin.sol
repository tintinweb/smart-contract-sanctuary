pragma solidity ^0.8.4;

contract SimpleCoin  {
    mapping(address => uint256) public balances;
    address public minter;

    event Sent(address from, address to, uint amount);

    constructor() {
        minter = msg.sender;
    }

    function mint(address receiver, uint256 amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    error InsufficientBalance(uint requested, uint available);

    function send(address receiver, uint256 amount) public {
        if (amount > balances[msg.sender])
           revert InsufficientBalance({
                   requested: amount,
                   available: balances[msg.sender]
               });
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}