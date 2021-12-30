pragma solidity >=0.7.3;

contract Proposal {
   string public question;
   address public askee;
   string public answer;
   bool public proposalAccepted;

   event QuestionUpdated(string oldQuestion, string newQuestion);
   event AskeeUpdated(address oldAskee, address newAskee);

   constructor(string memory initQuestion, address initAskee) {
       question = initQuestion;
       askee = initAskee;
    }

   function updateQuestion(string memory newQuestion) public {
       string memory oldQuestion = question;
       question = newQuestion;
       emit QuestionUpdated(oldQuestion, newQuestion);
    }

    function updateAskee(address newAskee) public {
       address oldAskee = askee;
       askee = newAskee;
       emit AskeeUpdated(oldAskee, newAskee);
    }

    function answerQuestion(string memory theAnswer, address theAskee) public {
        if (askee == theAskee) {
            answer = theAnswer;
            proposalAccepted = true;
        }
    }
}