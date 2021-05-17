/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.4.23;

contract JTestLotto2 {
    address[4] participants;
    address[2] gamblers;
    address[1] g2;
    uint8 senderCount = 0;
    uint8 participantsCount = 0;
    uint randNonce = 0;

    function join() public payable {
        require(msg.value == 0.1 ether, "Must send 0.1 ether");
        require(participantsCount < 4, "User limit reached");
        require(joinedAlready(msg.sender) == false, "User already joined");
        participants[participantsCount] = msg.sender;
        participantsCount++;
        g2[senderCount] = msg.sender;
        senderCount++;
        if (participantsCount == 4) {
            selectWinner();
        }
    }



    function gamble() public payable {
        require(msg.value == 1 ether, "Must send 1 ether");
        require(participantsCount < 2, "Executing Gamble");
        require(joinedAlready(msg.sender) == false, "User already joined");
        gamblers[participantsCount] = msg.sender;
        participantsCount++;
        if (participantsCount == 2) {
            select2Winner();
        }
    }



    function sendETH() public payable {
        require(msg.value == 1 ether, "Must send 1 ether");
        require(participantsCount < 1, "A bigger Gamble");
        require(joinedAlready(msg.sender) == false, "Error Sending ETH");
        gamblers[participantsCount] = msg.sender;
        participantsCount++;
        if (participantsCount == 2) {
            select2Winner();
        }
    }

    

    
    function joinedAlready(address _participant) private view returns(bool) {
        bool containsParticipant = false;
        for(uint i = 0; i < 4; i++) {
            if (participants[i] == _participant) {
                containsParticipant = true;
            }
        }
        return containsParticipant;
    }
    
    function selectWinner() private returns(address) {
        require(participantsCount == 4, "Waiting for more users");
        address winner = participants[randomNumber()];
        winner.transfer(address(this).balance);
        delete participants;
        participantsCount = 0;
        return winner;
    }
    
    function select1Winner() private returns(address) {
        require(senderCount == 1, "Error Sending ETH");
        address winner = g2[randomNumber()];
        winner.transfer(address(this).balance);
        delete senderCount;
        senderCount = 0;
        return winner;
    }
            
    function select2Winner() private returns(address) {
        require(participantsCount == 2, "Executes at 2 ETH");
        address winner = participants[randomNumber()];
        winner.transfer(address(this).balance);
        delete participants;
        participantsCount = 0;
        return winner;
    }
    
    function randomNumber() private returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 4;
        randNonce++;
        return rand;
    }
        
}