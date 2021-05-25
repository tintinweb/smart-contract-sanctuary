/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.4.21;

contract Forg {
    
    address public minter;
    
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);

    function Forg() public {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        if (msg.sender != minter) return;
        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}