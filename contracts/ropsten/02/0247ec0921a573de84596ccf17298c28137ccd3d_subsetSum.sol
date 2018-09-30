pragma solidity ^0.4.25;

contract subsetSum {
    
    struct Number {
        bool exists;
        bool isUsed;
    }
    struct Leader {
        address id;
        uint256 difference;
        uint256[] negativeSet;
        uint256[] positiveSet;
    }
    
    uint256[] numbers;
    mapping (uint256 => Number) numberCheck;
    Leader leader;
    
    constructor (uint256[] memory setElements) public {
        numbers = setElements;
        for (uint256 i = 0; i<setElements.length; i++) {
            numberCheck[setElements[i]].exists=true;
        }
    }
    
    function getNumbers() public view returns(uint256[] numberSet) {
        return numbers;
    }
    
    function submitAnswer(uint256[] negativeSetSubmission, uint256[] positiveSetSubmission) public returns (string response) {
        uint256 sumNegative = 0;
        uint256 sumPositive = 0;
        // Add everything up
        for (uint256 i = 0; i<negativeSetSubmission.length; i++) {
            require(numberCheck[negativeSetSubmission[i]].exists && !numberCheck[negativeSetSubmission[i]].isUsed, &#39;Invalid submission.&#39;);
            sumNegative+=negativeSetSubmission[i];
            numberCheck[negativeSetSubmission[i]].isUsed = true;
        }
        for (i = 0; i<positiveSetSubmission.length; i++) {
            require(numberCheck[positiveSetSubmission[i]].exists && !numberCheck[positiveSetSubmission[i]].isUsed, &#39;Invalid submission.&#39;);
            sumPositive+=positiveSetSubmission[i];
            numberCheck[positiveSetSubmission[i]].isUsed = true;
        }
        // Input looks valid, now set everything back to normal
        for (i = 0; i<negativeSetSubmission.length; i++) {
            numberCheck[negativeSetSubmission[i]].isUsed = false;
        }
        for (i = 0; i<positiveSetSubmission.length; i++) {
            numberCheck[positiveSetSubmission[i]].isUsed = false;
        }
        // Check the new result, if it&#39;s a new record, record it
        uint256 difference = diff(sumNegative, sumPositive);
        if (leader.id==address(0) || difference<leader.difference) {
            leader.id = msg.sender;
            leader.difference = difference;
            leader.negativeSet=negativeSetSubmission;
            leader.positiveSet=positiveSetSubmission;
            return "Congratulations, you are now on the top of the leaderboard.";
        } else {
            return "Sorry, you haven&#39;t beaten the record.";
        }
    }
    
    function diff(uint256 a, uint256 b) private pure returns (uint256 difference) {
        if (a>b) return a-b;
        else return b-a;
    }
    
}