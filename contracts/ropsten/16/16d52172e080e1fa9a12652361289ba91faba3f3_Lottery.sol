/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

// linkdin,twitter,github username: @imHukam

/*
smart contract program for lottery application on solidity.

1. manager to select winner,balance check,lottery control.
2. participants: all participants have to send 2 ether into contract address, contract will 
select random participants as a winner... and whole amount will be sent to that winner.
3. condition: 
 amount should be equal to 2 ether.
 total participants should be greater then of equal to 3.
 only manager have authority to check balance and draw lottery.
 conract should be reset once a round is completed.

*/
 
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Lottery{

    address public manager;
    address payable[] public participants;

    constructor(){
        manager=msg.sender; //deployer addresss to managers
    }

    // for receive eth from participats.
    receive() external payable{
        require(msg.value== 100000000000000000 wei); 
        participants.push(payable(msg.sender));
    }

    // for balance check,only for manager.
    function getBalance() public view returns(uint){
        require(msg.sender== manager);
        return address(this).balance;
    }

    //for random lottery draw.

    function random() public view returns(uint){
       return uint(keccak256(abi.encodePacked(block.difficulty,block.timestamp,participants.length)));
    }

    //for select winner.
    function selectWinner() public{
        require(msg.sender == manager,"only manager have right to call this function");
        require(participants.length >= 3, "less then 3 participants");

        uint r= random();
        uint index= r % participants.length;
        address payable winner= participants[index];

        //transfer amount to winner;
        winner.transfer(getBalance());

        //for reset lottery draw.
        participants= new address payable[](0);
    }
}