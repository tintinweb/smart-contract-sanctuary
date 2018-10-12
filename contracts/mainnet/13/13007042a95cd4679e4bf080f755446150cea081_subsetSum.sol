pragma solidity ^0.4.25;

contract subsetSum {
    // Written by Ciar&#225;n &#211; hAol&#225;in, Maynooth University 2018

    // Data types that we need
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

    // Things that we need to store
    uint256[] numbers;
    mapping (uint256 => Number) numberCheck;
    mapping (address => bool) authorisedEntrants;
    uint256 expiryTime;
    address admin;
    Leader leader;

    // Initial set up
    constructor (uint256[] memory setElements, uint256 expiry) public {
        require(setElements.length>0 && expiry > now, &#39;Invalid parameters&#39;);
        numbers = setElements;
        for (uint256 i = 0; i<setElements.length; i++) {
            numberCheck[setElements[i]].exists=true;
        }
        expiryTime = expiry;
        admin = msg.sender;
    }

    // Record an event on the blockchain whenever a new record is recorded
    event RunnerUpSubmission(address indexed submitter, uint256 submitterSolutionDifference);
    event NewRecord(address indexed newRecordHolder, uint256 newRecordDifference);

    // Only for the competition administrator
    modifier adminOnly {
        require(msg.sender==admin, &#39;This requires admin privileges&#39;);
        _;
    }

    // Only for authorised entrants
    modifier restrictedAccess {
        require(now<expiryTime && authorisedEntrants[msg.sender], &#39;Unauthorised entrant&#39;);
        _;
    }

    // Withdrawal of prize pot is only allowed after the competition is over, if and only if
    // the withdrawer is currently on top of the leaderboard OR
    // there is no leader, so admin requests withdrawal OR
    // a month has passed after the deadline and the winner hasn&#39;t withdrawn the prize pot, so admin requests withdrawal.
    modifier winnerOnly {
        require(now>expiryTime && (msg.sender==leader.id || ((address(0)==leader.id || now>expiryTime+2629746) && msg.sender==admin)), "You don&#39;t have permission to withdraw the prize");
        _;
    }

    // Get the numbers in the problem set
    function getNumbers() public view returns(uint256[] numberSet) {
        return numbers;
    }

    // Get the details of the current leader on the leaderboard
    function getRecord() public view returns (address winningAddress, uint256 difference, uint256[] negativeSet, uint256[] positiveSet) {
        return (leader.id, leader.difference, leader.negativeSet, leader.positiveSet);
    }

    // Get the current amount of money in the prize pot guaranteed to the person at the top of the leaderboard when the competition concludes.
    function getPrizePot() public view returns (uint256 prizeFundAmount) {
        return address(this).balance;
    }

    // Get the expiry timestamp of the contract
    function getExpiryDate() public view returns (uint256 expiryTimestamp) {
        return expiryTime;
    }
    
    // Get all the important Data
    function getData() public view returns(uint256[] numberSet, address winningAddress, uint256 prizeFundAmount, uint256 expiryTimestamp) {
        return (numbers, leader.id, address(this).balance, expiryTime);
    }

    // This (fallback) function allows anybody to add to the prize pot by simply sending ETH to the contract&#39;s address
    function () public payable {    }

    // For the sake of vanity...
    function getAuthor() public pure returns (string authorName) {
      return "Written by Ciar&#225;n &#211; hAol&#225;in, Maynooth University 2018";
    }

    // This functions allows the admin to authorise ETH addresses to enter the competition
    function authoriseEntrants(address[] addressesToAuthorise) public adminOnly {
        for (uint256 i = 0; i<addressesToAuthorise.length; i++) authorisedEntrants[addressesToAuthorise[i]]=true;
    }

    // Allows people to submit a new answer to the leaderboard. If it beats the current record, the new attempt will be recorded on the leaderboard.
    function submitAnswer(uint256[] negativeSetSubmission, uint256[] positiveSetSubmission) public restrictedAccess returns (string response) {
        require(negativeSetSubmission.length+positiveSetSubmission.length>0, &#39;Invalid submission.&#39;);
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
        for (i = 0; i<negativeSetSubmission.length; i++) numberCheck[negativeSetSubmission[i]].isUsed = false;
        for (i = 0; i<positiveSetSubmission.length; i++) numberCheck[positiveSetSubmission[i]].isUsed = false;
        // Check the new result, if it&#39;s a new record, record it
        uint256 difference = _diff(sumNegative, sumPositive);
        if (leader.id==address(0) || difference<leader.difference) {
            leader.id = msg.sender;
            leader.difference=difference;
            leader.negativeSet=negativeSetSubmission;
            leader.positiveSet=positiveSetSubmission;
            emit NewRecord(msg.sender, difference);
            return "Congratulations, you are now on the top of the leaderboard.";
        } else {
            emit RunnerUpSubmission(msg.sender, difference);
            return "Sorry, you haven&#39;t beaten the record.";
        }
    }

    // Allows the winner to withdraw the prize pot
    function withdrawPrize(address prizeRecipient) public winnerOnly {
        prizeRecipient.transfer(address(this).balance);
    }

    // Internal function to check results
    function _diff(uint256 a, uint256 b) private pure returns (uint256 difference) {
        if (a>b) return a-b;
        else return b-a;
    }

}