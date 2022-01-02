// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract FitnessChallenge {

    address public admin;
    uint public commissionRate;
    uint public nextChallengeId;

    enum ChallengeState { PENDING, INPROGRESS, COMPLETE, CANCELLED }

    struct Challenge {
        address challenger1;
        address challenger2;
        uint256 wager;
        ChallengeState state;
    }

    mapping(uint256 => Challenge) public challengeIdToChallenge;
    
    constructor(uint _commissionRate) {
        admin = msg.sender;
        commissionRate = _commissionRate;
        nextChallengeId = 1;
    }

    function initiateChallenge(address challengee, uint wager) public payable {
        uint256 id = nextChallengeId;

        challengeIdToChallenge[id] = Challenge(msg.sender, challengee, wager, ChallengeState.PENDING);
        
        nextChallengeId ++;
    }

    function acceptChallenge(uint challengeId) public payable {
        Challenge storage challenge = challengeIdToChallenge[challengeId];
        require(msg.value == challenge.wager, "Must place the correct wager!");

        challenge.state = ChallengeState.INPROGRESS;
    }

    function win(uint256 challengeId) public payable {

        Challenge storage challenge = challengeIdToChallenge[challengeId];

        uint totalPot = challenge.wager * 2;

        uint commission = totalPot * commissionRate;
        uint winnerEarnings = totalPot - commission;

        payable(admin).transfer(commission);
        payable(msg.sender).transfer(winnerEarnings);

        challenge.state = ChallengeState.COMPLETE;
    }

    function cancel(uint256 challengeId) public payable {

        Challenge storage challenge = challengeIdToChallenge[challengeId];

        payable(challenge.challenger1).transfer(challenge.wager);
        payable(challenge.challenger2).transfer(challenge.wager);

        challenge.state = ChallengeState.CANCELLED;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function updateCommissionRate(uint256 newCommissionRate) public onlyAdmin {
        commissionRate = newCommissionRate;
    }
}