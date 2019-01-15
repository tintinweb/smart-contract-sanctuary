pragma solidity ^0.5.1;

contract VotingChallenge {
    struct Team {
        uint fullVotes;
        uint weightedVotes;
    }

    struct Voter {
        uint[2] fullVotes;
        uint[2] weightedVotes;
        address payable[2] referrers;
    }

    VotingChallengeForwarder forwarder;

    uint public challengeDuration;
    uint public challengeStarted;
    address payable public creator;
    uint16 public creatorFee = 17;       // measured in in tenths of a percent
    address payable public cryptoVersusWallet = 0xa0bedE75cfeEF0266f8A31b47074F5f9fBE1df80;
    uint16 public cryptoVersusFee = 53;  // measured in in tenths of a percent
    uint public cryptoVersusPrize;
    uint public challengePrize;
    uint public winner;
    bool public isVotingPeriod = false;
    bool public beforeVoting = true;
    Team[2] public teams;
    mapping( address => Voter ) private voters;

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

    event ChallengeBegins(address _creator, uint _challengeDuration);
    event NewVotesFor(address _participant, uint _candidate, uint _votes, uint _coefficient);
    event TransferVotes(address _from, address _to, uint _candidateIndex, uint _votes);
    event EndOfChallenge(uint _winner, uint _winnerVotes, uint _challengePrize);
    event RewardWasPaid(address _participant, uint _amount);
    event ReferrerRewardWasPaid(address _via, address _to, uint amount);
    event CreatorRewardWasPaid(address _creator, uint _amount);
    event CryptoVersusRewardWasPaid(address _cryptoVersusWallet, uint _amount);

    constructor(uint _challengeDuration, address _forwarder) public {
        forwarder = VotingChallengeForwarder(_forwarder);
        challengeDuration = _challengeDuration;
        creator = msg.sender;
    }

    function getAllVotes() public view returns (uint[2] memory) {
        return [ teams[0].fullVotes, teams[1].fullVotes ];
    }

    function currentCoefficient() public view returns (uint) {  // in 1/1000000
        return 1000000 - 900000 * (now - challengeStarted) / challengeDuration;
    }

    function timeOver() public view returns (bool) {
        return challengeStarted + challengeDuration <= now;
    }

    function startChallenge() public onlyCreator {
        require(beforeVoting);
        isVotingPeriod = true;
        beforeVoting = false;
        challengeStarted = now;

        emit ChallengeBegins(creator, challengeDuration);
    }

    function voteForCandidate(uint candidate) public payable inVotingPeriod {
        require(0 <= candidate && candidate < 2);
        require(msg.value > 0);
        require(!timeOver());

        uint coefficient = currentCoefficient();
        uint weightedVotes = msg.value * coefficient / 1000000;
        teams[candidate].fullVotes += msg.value;
        teams[candidate].weightedVotes += weightedVotes;
        voters[msg.sender].fullVotes[candidate] += msg.value;
        voters[msg.sender].weightedVotes[candidate] += weightedVotes;

        emit NewVotesFor(msg.sender, candidate, msg.value, coefficient);
    }

    function voteForCandidate(uint candidate, address payable referrer1) public payable inVotingPeriod {
        voters[msg.sender].referrers[0] = referrer1;
        voteForCandidate(candidate);
    }

    function voteForCandidate(uint candidate, address payable referrer1, address payable referrer2) public payable inVotingPeriod {
        voters[msg.sender].referrers[1] = referrer2;
        voteForCandidate(candidate, referrer1);
    }

    function checkEndOfChallenge() public inVotingPeriod returns (bool) {
        if (!timeOver())
            return false;

        if (teams[0].fullVotes > teams[1].fullVotes)
            winner = 0;
        else
            winner = 1;

        uint loser = 1 - winner;
        creator.transfer((teams[loser].fullVotes * creatorFee) / 1000);
        cryptoVersusPrize = (teams[loser].fullVotes * cryptoVersusFee) / 1000;
        challengePrize = teams[loser].fullVotes * (1000 - creatorFee - cryptoVersusFee) / 1000;
        isVotingPeriod = false;

        emit EndOfChallenge(winner, teams[winner].fullVotes, challengePrize);
        return true;
    }

    function sendReward(address payable to) public afterVotingPeriod {
        uint winnerVotes = voters[to].weightedVotes[winner];
        uint loserVotes = voters[to].fullVotes[1-winner];
        address payable referrer1 = voters[to].referrers[0];
        address payable referrer2 = voters[to].referrers[1];
        uint sum;

        if (winnerVotes > 0) {
            uint reward = challengePrize * winnerVotes / teams[winner].weightedVotes;
            to.transfer(reward + voters[to].fullVotes[winner]);
            if (referrer1 != address(0)) {
                sum = reward / 100 * 2;  // 2%
                forwarder.forward.value(sum)(referrer1, to);
                cryptoVersusPrize -= sum;
                emit ReferrerRewardWasPaid(to, referrer1, sum);
            }
            if (referrer2 != address(0)) {
                sum = reward / 1000 * 2;  // 0.2%
                forwarder.forward.value(sum)(referrer2, to);
                cryptoVersusPrize -= sum;
                emit ReferrerRewardWasPaid(to, referrer2, sum);
            }
            voters[to].fullVotes[winner] = 0;
            voters[to].weightedVotes[winner] = 0;
            emit RewardWasPaid(to, reward);
        }
        if (loserVotes > 0) {
            if (referrer1 != address(0)) {
                sum = loserVotes / 100 * 1;  // 1%
                forwarder.forward.value(sum)(referrer1, to);
                cryptoVersusPrize -= sum;
                emit ReferrerRewardWasPaid(to, referrer1, sum);
            }
            if (referrer2 != address(0)) {
                sum = loserVotes / 1000 * 1;  // 0.1%
                forwarder.forward.value(sum)(referrer2, to);
                cryptoVersusPrize -= sum;
                emit ReferrerRewardWasPaid(to, referrer2, sum);
            }
            voters[to].fullVotes[1-winner] = 0;
            voters[to].weightedVotes[1-winner] = 0;
        }
    }

    function sendCryptoVersusReward() public afterVotingPeriod {
        if (cryptoVersusPrize > 0) {
            uint cryptoVersusReward = cryptoVersusPrize;
            cryptoVersusPrize = 0;
            cryptoVersusWallet.transfer(cryptoVersusReward);

            emit CryptoVersusRewardWasPaid(cryptoVersusWallet, cryptoVersusReward);
        }
    }
}

contract VotingChallengeForwarder {
    mapping ( address => address[] ) public sendersHash;
    mapping ( address => uint[] ) public sumsHash;

    function forward(address payable to, address sender) public payable {
        to.transfer(msg.value);
        sendersHash[to].push(sender);
        sumsHash[to].push(msg.value);
    }

    function getSendersHash(address user) public view returns (address[] memory) {
        return sendersHash[user];
    }

    function getSumsHash(address user) public view returns (uint[] memory) {
        return sumsHash[user];
    }
}