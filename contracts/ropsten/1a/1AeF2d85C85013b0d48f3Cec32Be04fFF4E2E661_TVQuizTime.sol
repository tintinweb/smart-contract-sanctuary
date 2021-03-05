/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

pragma solidity ^0.6.4;

contract TVQuizTime {
    
    address payable[] private participantAddresses;
    address payable[] private winnerAddresses;
    mapping(address => uint256) private wonAmount;
    mapping(address => uint8) private responseSubmitted;
    bool private isContractInFailure;
    bool public isCompetitionOpen;
    address private contractOwner;
    uint256 public amountToWon;
    uint256 public numberOfWinners;
    uint256 private nextTransaction;
    uint256 public creationTimestamp;
    uint8 private competitionAnswer;
    
    constructor() public payable {
        contractOwner = msg.sender;
        amountToWon = msg.value/2;
        isContractInFailure = false;
        creationTimestamp = now;
        isCompetitionOpen = true;
        competitionAnswer = 12;
    }
    
    function tryYourLuck(uint8 submittedAnswer) public {
        require(now < creationTimestamp + 15 minutes);
        participantAddresses.push(msg.sender);
        responseSubmitted[msg.sender] = submittedAnswer;
    }
    
    function numberOfParticipants() public view returns (uint) {
        return participantAddresses.length;
    }
    
    function checkWinners() internal {
        uint256 i = 0;
        numberOfWinners = 0;
        while(i < participantAddresses.length) {
            if(responseSubmitted[participantAddresses[i]] == competitionAnswer) {
                numberOfWinners++;
            }
            i++;
        }
    }
    
    function fillInTheAccounts() internal {
        uint256 i = 0;
        delete winnerAddresses;
        while(i < participantAddresses.length) {
            if(responseSubmitted[participantAddresses[i]] == competitionAnswer) {
                wonAmount[participantAddresses[i]] = amountToWon/numberOfWinners;
                winnerAddresses.push(participantAddresses[i]);
            }
            i++;
        }
    }

    function payWinnersProcess() internal returns(bool) {
        uint256 i = nextTransaction;
        while(i < winnerAddresses.length) {
            if(!winnerAddresses[i].send(wonAmount[winnerAddresses[i]])) return false;
            i++;
        }
        nextTransaction = i;
        return true;
    }
  
    function terminateTheContest() public {
        require(isCompetitionOpen == true);
        checkWinners();
        fillInTheAccounts();
        if(payWinnersProcess()){
            isCompetitionOpen = false;
        } else {
            isContractInFailure = true;
        }
    }
  
  function inCaseOfEmergency() external {
      require(isContractInFailure == true);
      require(msg.sender.send(address(this).balance) == true);
  }
}