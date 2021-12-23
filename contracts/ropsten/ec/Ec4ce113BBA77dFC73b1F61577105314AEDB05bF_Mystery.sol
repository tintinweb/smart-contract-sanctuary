/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7 <0.9.0;



contract setUpMystery {

    string public mystery = "Welcome... Please get the first quest.";
    Quest[] private quest;


    address private addr; // only the person who deploys the contract is allowed to add a Quest;


    // Only the person who deploys the contract can add Quests
    constructor() {
        addr = msg.sender;
    }



    struct Quest {
        string mystery;             // Gives Mistery
        bytes32 sealedMessage;      // Seal answer into a hash
    }


    function createHashFromAnswer(string memory secret) private pure returns (bytes32 _sealedMessage){
        _sealedMessage = keccak256(abi.encodePacked(secret));
    }


    function addQuest(string memory _mystery, string memory _answer) external {   // Note: all answers have to be unique

        // Require an entry for the mystery and an answer
        require(addr==msg.sender, "You do not have permission to add a Quest");
        require(bytes(_answer).length > 0, "Mystery is empty");
        require(bytes(_answer).length > 0, "Answer is empty");

        bytes32 sealedMessage = createHashFromAnswer(_answer);
        for(uint i=0; i<quest.length; i++){
                require(sealedMessage != quest[i].sealedMessage,"Answer already exists.");
            }


        // Add mystery and hash of answer to Quest
        quest.push(Quest(_mystery,sealedMessage));
    }


    function removeLastQuest() external {   // Note: all answers have to be unique

        require(addr==msg.sender, "You do not have permission to add a Quest");
        require(quest.length>0, "There is no Quest available");

        // Add mystery and hash of answer to Quest
        quest.pop();
    }



    function getQuest(string memory _answer) external returns (string memory) {

        require(quest.length>0,"No Quests available");
        bytes32 sealedMessage = createHashFromAnswer(_answer);
        // Empty answer or 0 gives first quest
        if (bytes(_answer).length==0 || createHashFromAnswer("0")==sealedMessage){
            mystery = quest[0].mystery;
        } else {
            // checke if answer is valid for one of the mistery
            uint correctAnswerPosition = quest.length; 
            for(uint i=0; i<quest.length; i++){
                if (quest[i].sealedMessage == sealedMessage) {
                    correctAnswerPosition = i;
                }
            }
            if (correctAnswerPosition == quest.length){ // No answer was found
                mystery = "You failed.... Try again.";
            } else if (correctAnswerPosition == quest.length-1){ // Found the answer to the last question
                mystery = "Congratulation, you finished all the Quests!";
            } else {
                mystery = quest[correctAnswerPosition+1].mystery;
            }


        }

        return mystery;

    }



}



contract Mystery {

    setUpMystery  _mystery;
    mapping(address => string) public mystery;

    constructor(address _contractAddress) { //Use contract address from the quests
        _mystery = setUpMystery(_contractAddress);
    }

    function getQuest(string memory _answer) external returns (string memory) {
        mystery[msg.sender] = _mystery.getQuest(_answer);
        return mystery[msg.sender];
    }

}