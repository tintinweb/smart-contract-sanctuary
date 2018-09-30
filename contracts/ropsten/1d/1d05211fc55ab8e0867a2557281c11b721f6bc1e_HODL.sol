//LAB 2 HODL contract

//This contract allows the user to save ethereum without being able to spend it or withdraw until a block height that is set by the user.

pragma solidity ^0.4.25;

contract HODL {
    uint public blockheight;
    address public owner;
    
    //Sets the 2 fields to their appropriate values.
    constructor(uint _blockheight) public payable{
        owner=msg.sender;
        blockheight=_blockheight;
    }

    //This function allows the owner of the contract to withdraw the initial deposit ONLY if the current block number is greater than the _blockheight set in the constructor.
    function withdraw() public{
        if(msg.sender==owner && block.number > blockheight )
            owner.transfer(address(this).balance);
    }
//To submit the lab deploy the contract to ropsten, upload the source code to private gist, send link and address of contract to instructor.
}