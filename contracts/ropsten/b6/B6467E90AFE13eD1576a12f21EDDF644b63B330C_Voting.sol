/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

pragma solidity =0.7.0;

contract Voting {
    uint public yesVotes;
    uint public noVotes;
    address payable owner;

    constructor() {
        owner = msg.sender;
    }    
    
    function vote(bool yes) payable public {

        require((msg.value > 1), "You need to pay ether to vote.");
        owner.transfer(msg.value);

        if(yes) {
            yesVotes ++;
        } else {
            noVotes ++;
        } 
    }

    function destroy() public{
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}