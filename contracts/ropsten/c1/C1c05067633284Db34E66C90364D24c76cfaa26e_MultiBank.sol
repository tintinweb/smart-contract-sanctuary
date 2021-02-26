/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title MultiBank
 * This contract was inspired by the 3_Ballot.sol provided by remix (default implementation)
 * This was a collaboration between Carson Wood, Kavin Shah, and Scott Driggers
 * We also referenced solidity-by-example.org for syntax related to sending funds
 *
 * We know that there are race conditions in our code, but this is beyond the scope of this problem.
 */
contract MultiBank {

    struct Proposal {
        // If you can limit the length to a certain number of bytes,
        // always use one of bytes1 to bytes32 because they are much cheaper
        address author; // person delegated to
        address payable receiver;   // short name (up to 32 bytes)
        uint256 amount; // number of accumulated votes
    }
    address public user1;
    address public user2;
    address public user3;

    Proposal[] public proposals;
   
    constructor(address u1, address u2, address u3) {
        user1 = u1;
        user2 = u2;
        user3 = u3;
    }
   
    function deposit() public payable {
    }
   
    function removeProposal(address r, uint256 a) public {
        require(msg.sender == user1 || msg.sender == user2 || msg.sender == user3, "Has no right to propose");
       
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].receiver == r && proposals[i].amount == a) {
                require(proposals[i].author == msg.sender, "Cannot remove other authors proposal");
               
                remove(i);
            }
        }
    }

    function addProposal(address payable r, uint256 a) public {
        require(msg.sender == user1 || msg.sender == user2 || msg.sender == user3, "Has no right to propose");
       
        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].receiver == r && proposals[i].amount == a) {
                require(proposals[i].author != msg.sender, "Already submitted this proposal");
                require(a <= address(this).balance, "Insufficient funds");
                (bool success,) = r.call{value: a}("");
                require(success, "Failed to send Ether");
               
                remove(i);
               
                return;
            }
        }
        proposals.push(
            Proposal ({
                author: msg.sender,
                receiver: r,
                amount:a
            })
        );
    }
   
    function remove(uint i) internal {
        proposals[i] = proposals[proposals.length - 1];
        proposals.pop();
    }
}