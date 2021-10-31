/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

pragma solidity ^0.4.0;

contract Lottery{
    // varibale to store managers address
    address public manager;

    //we are storing the address of the participants
    address[] public participants;

    constructor () public {
        manager = msg.sender;
    }

    // Function to enter the lottery, we are going to make each users
    // pay a small amount to enter the lottery
    function enterLottery() public payable {
        require(msg.value > 0.01 ether);
        participants.push(msg.sender);
    }

    function pickWinner() public{
        // check only that the manager can call the pick winner function
        require(msg.sender == manager);
        // select a random participant
        uint index = random() % participants.length;
        // transfer the contract balance to the participants
        participants[index].transfer(this.balance);
        // empty the address array
        participants = new address[](0);
    }

    function random() private view returns(uint256){
        return uint(keccak256(block.difficulty, now, participants));
    }
}