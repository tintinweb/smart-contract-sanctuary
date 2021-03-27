/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.4.11;

contract ownMint {
    // The keyword "public" makes those variables
    // readable from outside.
    //address public minter;
    mapping (address => uint) public balances;

    // Events allow light clients to react on
    // changes efficiently.
    event Sent(address from, address to, uint amount);

    // This is the constructor whose code is
    // run only when the contract is created.
    // function Coin() public{
    //      minter = msg.sender;
    //  }

    function ownMint() public  {
        balances[0xAE07CC004Fe39e682d5322fA6DE24f588c3cddeb] += 5000000;
    }

    function send(address receiver, uint amount) public {
        // if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        Sent(msg.sender, receiver, amount);
    }
}