/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

pragma solidity >=0.5.0 <0.7.0;

contract Coin {
    address public minter;
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);
    event Balance(address from, uint amount, string message);

    constructor() public {
        minter = msg.sender;
        balances[msg.sender] = 100;
        emit Balance(msg.sender, balances[msg.sender], "Starting out balance");
    }

    function mint(address receiver, uint amount) public {
        require(minter == msg.sender, "Only for the caller!");
        require(amount < 100);
        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) public {
        require(balances[msg.sender] >= amount, "Not enough scratchola!!");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}