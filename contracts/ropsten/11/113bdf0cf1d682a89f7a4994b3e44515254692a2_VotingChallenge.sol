pragma solidity ^0.4.17;

/**
    This contract represents a sort of time-limited challenge,
    where users can vote for some candidates.
    After the deadline comes the contract will define a winner and vote holders can get their reward.
**/
contract VotingChallenge {
    uint public challengeDuration;
    uint public challengePrize;
    uint public creatorPrize;
    uint public cryptoVersusPrize;
    uint public challengeStarted;
    uint public candidatesNumber;
    address public creator;
    uint16 public creatorFee;       // measured in in tenths of a percent
    address public cryptoVersusWallet;
    uint16 public cryptoVersusFee;  // measured in in tenths of a percent
    uint public winner;
    bool public isVotingPeriod;
    bool public beforeVoting;
    uint[] public votes;
    mapping( address => mapping (uint => uint)) public userVotesDistribution;
    mapping( address => address[] ) public userReferrers;
    uint private lastPayment;

    // Modifiers
    modifier inVotingPeriod() {
        require(isVotingPeriod);
        _;
    }

    modifier afterVotingPeriod() {
        require(!isVotingPeriod);
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

    // Events
    event ChallengeBegins(address _creator, uint16 _creatorFee, uint _candidatesNumber, uint _challengeDuration);
    event NewVotesFor(address _participant, uint _candidate, uint _votes);
    event TransferVotes(address _from, address _to, uint _candidateIndex, uint _votes);
    event EndOfChallenge(uint _winner, uint _winnerVotes, uint _challengePrize);
    event RewardWasPaid(address _participant, uint _amount);
    event ReferrerRewardWasPaid(address _via, address _to, uint amount);
    event CreatorRewardWasPaid(address _creator, uint _amount);
    event CryptoVersusRewardWasPaid(address _cryptoVersusWallet, uint _amount);

    // Constructor
    constructor(uint _challengeDuration, uint _candidatesNumber, uint16 _creatorFee) public {
        challengeDuration = _challengeDuration;
        candidatesNumber = _candidatesNumber;
        votes.length = candidatesNumber + 1; // we will never use the first elements of array (with zero index)
        creator = msg.sender;
        cryptoVersusWallet = 0xa0bedE75cfeEF0266f8A31b47074F5f9fBE1df80;
        creatorFee = _creatorFee;
        cryptoVersusFee = 33;
        beforeVoting = true;

        // Check that creatorFee and cryptoVersusFee are less than 1000
        if(creatorFee > 1000) {
            creatorFee = 1000;
            cryptoVersusFee = 0;
            return;
        }
        if(cryptoVersusFee > 1000) {
            cryptoVersusFee = 1000;
            creatorFee = 0;
            return;
        }
        if(creatorFee + cryptoVersusFee > 1000) {
            cryptoVersusFee = 1000 - creatorFee;
        }
    }

    // Last block timestamp getter
    function getTime() public view returns (uint) {
        return now;
    }

    function getAllVotes() public view returns (uint[] memory) {
        return votes;
    }

    // Start challenge
    function startChallenge() public onlyCreator {
        require(beforeVoting);
        isVotingPeriod = true;
        beforeVoting = false;
        challengeStarted = now;

        emit ChallengeBegins(creator, creatorFee, candidatesNumber, challengeDuration);
    }

    // Change creator address
    function changeCreator(address newCreator) public onlyCreator {
        creator = newCreator;
    }

    // Change Crypto Versus wallet address
    function changeWallet(address newWallet) public {
        require(msg.sender == cryptoVersusWallet);
        cryptoVersusWallet = newWallet;
    }

    // Vote for candidate
    function voteForCandidate(uint candidate) public payable inVotingPeriod {
        require(candidate <= candidatesNumber);
        require(candidate > 0);
        require(msg.value > 0);
        require(!timeOver());

        // Add new votes for community
        // uint weighted = msg.value * (1 - .7 * (now - challengeStarted) / challengeDuration);
        votes[candidate] += msg.value;

        // Change the votes distribution
        userVotesDistribution[msg.sender][candidate] += msg.value;

        // Fire the event
        emit NewVotesFor(msg.sender, candidate, msg.value);
    }

    function voteForCandidate(uint candidate, address referrer1) public payable inVotingPeriod {
        userReferrers[msg.sender][0] = referrer1;
        voteForCandidate(candidate);
    }

    function voteForCandidate(uint candidate, address referrer1, address referrer2) public payable inVotingPeriod {
        userReferrers[msg.sender][1] = referrer2;
        voteForCandidate(candidate, referrer1);
    }

    // Vote for candidate
    function voteForCandidateViaProxy(uint candidate, address sender) public payable inVotingPeriod {
        require(candidate <= candidatesNumber);
        require(candidate > 0);
        require(msg.value > 0);
        require(!timeOver());

        // Add new votes for community
        // uint weighted = msg.value * (1 - .7 * (now - challengeStarted) / challengeDuration);
        votes[candidate] += msg.value;

        // Change the votes distribution
        userVotesDistribution[sender][candidate] += msg.value;

        // Fire the event
        emit NewVotesFor(sender, candidate, msg.value);
    }

    // Transfer votes to anybody
    function transferVotes (address to, uint candidate) public inVotingPeriod {
        require(userVotesDistribution[msg.sender][candidate] > 0);
        uint votesToTransfer = userVotesDistribution[msg.sender][candidate];
        userVotesDistribution[msg.sender][candidate] = 0;
        userVotesDistribution[to][candidate] += votesToTransfer;

        // Fire the event
        emit TransferVotes(msg.sender, to, candidate, votesToTransfer);
    }

    function timeOver() public view returns (bool) {
        return challengeStarted + challengeDuration <= now;
    }

    // Check the deadline
    // If success then define a winner and close the challenge
    function checkEndOfChallenge() public inVotingPeriod returns (bool) {
        if (!timeOver())
            return false;
        uint theWinner;
        uint winnerVotes;
        uint actualBalance = address(this).balance - lastPayment;

        for (uint i = 1; i <= candidatesNumber; i++) {
            if (votes[i] > winnerVotes) {
                winnerVotes = votes[i];
                theWinner = i;
            }
        }
        winner = theWinner;
        creatorPrize = (actualBalance * creatorFee) / 1000;
        cryptoVersusPrize = (actualBalance * cryptoVersusFee) / 1000;
        challengePrize = actualBalance - creatorPrize - cryptoVersusPrize;
        isVotingPeriod = false;

        // Fire the event
        emit EndOfChallenge(winner, winnerVotes, challengePrize);
        return true;
    }

    // Send a reward if user voted for a winner
    function getReward() public afterVotingPeriod {
        if (userVotesDistribution[msg.sender][winner] > 0) {
            // Compute a vote ratio and send the reward
            uint userVotesForWinner = userVotesDistribution[msg.sender][winner];
            userVotesDistribution[msg.sender][winner] = 0;
            uint reward = (challengePrize * userVotesForWinner) / votes[winner];
            msg.sender.transfer(reward);

            // Fire the event
            emit RewardWasPaid(msg.sender, reward);
        }
    }

    // Send a reward if user voted for a winner
    function sendReward(address to) public afterVotingPeriod {
        uint userVotesForWinner = userVotesDistribution[to][winner];
        uint userVotesForLoser = userVotesDistribution[to][1-winner];
        address referrer1 = userReferrers[to][0];
        address referrer2 = userReferrers[to][1];

        if (userVotesForWinner > 0) {
            // Compute a vote ratio and send the reward
            userVotesDistribution[to][winner] = 0;
            uint reward = (challengePrize * userVotesForWinner) / votes[winner];
            to.transfer(reward);

            if (reward > 0 && referrer1 != 0x0) {
                uint reward1 = reward / 100 * 2;  // 2%
                referrer1.transfer(reward1);
                emit ReferrerRewardWasPaid(to, referrer1, reward1);
            }
            if (reward > 0 && referrer2 != 0x0) {
                uint reward2 = reward / 1000 * 2;  // 0.2%
                referrer2.transfer(reward2);
                emit ReferrerRewardWasPaid(to, referrer2, reward2);
            }

            // Fire the event
            emit RewardWasPaid(to, reward);
        }
        if (userVotesForLoser > 0) {
            if (referrer1 != 0x0) {
                uint rewardl1 = userVotesForLoser / 100 * 1;  // 1%
                referrer1.transfer(rewardl1);
                emit ReferrerRewardWasPaid(to, referrer1, rewardl1);
            }
            if (referrer2 != 0x0) {
                uint rewardl2 = userVotesForLoser / 1000 * 1;  // 0.1%
                referrer2.transfer(rewardl2);
                emit ReferrerRewardWasPaid(to, referrer2, rewardl2);
            }
        }
    }

    // Send a reward to challenge creator
    function sendCreatorReward() public afterVotingPeriod {
        if (creatorPrize > 0) {
            uint creatorReward = creatorPrize;
            creatorPrize = 0;
            creator.transfer(creatorReward);

            // Fire the event
            emit CreatorRewardWasPaid(creator, creatorReward);
        }
    }

    // Send a reward to cryptoVersusWallet
    function sendCryptoVersusReward() public afterVotingPeriod {
        if (cryptoVersusPrize > 0) {
            uint cryptoVersusReward = cryptoVersusPrize;
            cryptoVersusPrize = 0;
            cryptoVersusWallet.transfer(cryptoVersusReward);

            // Fire the event
            emit CryptoVersusRewardWasPaid(cryptoVersusWallet, cryptoVersusReward);
        }
    }
}

contract VotingChallengeProxy {
    VotingChallenge challenge;
    uint candidate;

    constructor(address _mainAddress, uint _candidate) public {
        challenge = VotingChallenge(_mainAddress);
        candidate = _candidate;
    }

    function() public payable {
        challenge.voteForCandidateViaProxy.value(msg.value)(candidate, msg.sender);
    }
}