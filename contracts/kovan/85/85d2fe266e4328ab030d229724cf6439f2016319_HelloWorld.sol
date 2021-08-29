/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.8.0;
contract HelloWorld {
    string namesender = 'Pittaya Kunnawat';
    string nameReceiver = 'P Neung';
    uint256 age = 35;
    bool sendx;

address public owner;
constructor(){
    owner = msg.sender;
}



function NewnameS(string memory newx) public{
    //  require(owner == mag.sender,"sender is not owner")
     namesender = newx;
}

function NewnameR(string memory newx) public{
    //  require(owner == mag.sender,"sender is not owner")
    
    nameReceiver = newx;
}

function agenew(uint256 agex) public{
      age = agex;
}

function homework(bool homeworksend) public{
      sendx = homeworksend;
}

}