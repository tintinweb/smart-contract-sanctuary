pragma solidity  ^0.5.0;

contract Entekhabat {
    uint public rohani;//1
    uint public trump;//2
    
    function vote(uint candidateID) public {
        if(candidateID==1)
            rohani++;
        else if(candidateID==2)
            trump++;
    }
}