pragma solidity ^0.4.15;

contract DecenterHackathon {

    struct Team {
        string name;
        string memberNames;
        uint score;
        uint reward;
        bool rewardEligible;
        bool submittedByAdmin;
        bool disqualified;
        mapping(address => bool) votedForByJuryMember;
    }

    struct JuryMember {
        string name;
        bool hasVoted;
    }

    struct Sponsor {
        string name;
        string siteUrl;
        string logoUrl;
        address ethAddress;
        uint contribution;
    }

    enum Period { Registration, Competition, Voting, Verification, End }

    uint public totalContribution;
    Period public currentPeriod;

    mapping(address => Team) teams;
    mapping(address => JuryMember) juryMembers;

    address administrator;
    address[] teamAddresses;
    address[] juryMemberAddresses;
    Sponsor[] sponsors;

    event PeriodChanged(Period newPeriod);
    event TeamRegistered(string teamName, address teamAddress, string memberNames, bool rewardEligible);
    event JuryMemberAdded(string juryMemberName, address juryMemberAddress);
    event SponsorshipReceived(string sponsorName, string sponsorSite, string sponsorLogoUrl, uint amount);
    event VoteReceived(string juryMemberName, address indexed teamAddress, uint points);
    event PrizePaid(string teamName, uint amount);
    event TeamDisqualified(address teamAddress);

    modifier onlyOwner {
        require(msg.sender == administrator);
        _;
    }

    modifier onlyJury {
        require(bytes(juryMembers[msg.sender].name).length > 0);
        _;
    }

   function DecenterHackathon() {
        administrator = msg.sender;
        currentPeriod = Period.Registration;
    }

    // Administrator is able to switch between periods at any time
    function switchToNextPeriod() onlyOwner {
        if(currentPeriod == Period.Verification || currentPeriod == Period.End) {
            return;
        }

        currentPeriod = Period(uint(currentPeriod) + 1);

        PeriodChanged(currentPeriod);
    }

    // Administrator can add new teams during registration period, with an option to make a team non-eligible for the prize
    function registerTeam(string _name, address _teamAddress, string _memberNames, bool _rewardEligible) onlyOwner {
        require(currentPeriod == Period.Registration);
        require(bytes(teams[_teamAddress].name).length == 0);

        teams[_teamAddress] = Team({
            name: _name,
            memberNames: _memberNames,
            score: 0,
            reward: 0,
            rewardEligible: _rewardEligible,
            submittedByAdmin: false,
            disqualified: false
        });

        teamAddresses.push(_teamAddress);
        TeamRegistered(_name, _teamAddress, _memberNames, _rewardEligible);
    }

    // Administrator can add new jury members during registration period
    function registerJuryMember(string _name, address _ethAddress) onlyOwner {
        require(currentPeriod == Period.Registration);

        juryMemberAddresses.push(_ethAddress);
        juryMembers[_ethAddress] = JuryMember({
            name: _name,
            hasVoted: false
        });

        JuryMemberAdded(_name, _ethAddress);
    }

    // Anyone can contribute to the prize pool (i.e. either sponsor himself or administrator on behalf of the sponsor) during registration period
    function contributeToPrizePool(string _name, string _siteUrl, string _logoUrl) payable {
        require(currentPeriod != Period.End);
        require(msg.value >= 0.1 ether);

        sponsors.push(Sponsor({
            name: _name,
            siteUrl: _siteUrl,
            logoUrl: _logoUrl,
            ethAddress: msg.sender,
            contribution: msg.value
        }));

        totalContribution += msg.value;
        SponsorshipReceived(_name, _siteUrl, _logoUrl, msg.value);
    }

    // Jury members can vote during voting period
    // The _votes parameter should be an array of team addresses, sorted by score from highest to lowest based on jury member&#39;s preferences
    function vote(address[] _votes) onlyJury {
        require(currentPeriod == Period.Voting);
        require(_votes.length == teamAddresses.length);
        require(juryMembers[msg.sender].hasVoted == false);

        uint _points = _votes.length;

        for(uint i = 0; i < _votes.length; i++) {
            address teamAddress = _votes[i];

            // All submitted teams must be registered
            require(bytes(teams[teamAddress].name).length > 0);

            // Judge should not be able to vote for the same team more than once
            require(teams[teamAddress].votedForByJuryMember[msg.sender] == false);

            teams[teamAddress].score += _points;
            teams[teamAddress].votedForByJuryMember[msg.sender] = true;

            VoteReceived(juryMembers[msg.sender].name, teamAddress, _points);
            _points--;
        }

        // This will prevent jury members from voting more than once
        juryMembers[msg.sender].hasVoted = true;
    }

    // Administrator can initiate prize payout during final period
    // The _sortedTeams parameter should be an array of correctly sorted teams by score, from highest to lowest
    function payoutPrizes(address[] _sortedTeams) onlyOwner {
        require(currentPeriod == Period.Verification);
        require(_sortedTeams.length == teamAddresses.length);

        for(uint i = 0; i < _sortedTeams.length; i++) {
            // All submitted teams must be registered
            require(bytes(teams[_sortedTeams[i]].name).length > 0);

            // Teams must be sorted correctly
            require(i == _sortedTeams.length - 1 || teams[_sortedTeams[i + 1]].score <= teams[_sortedTeams[i]].score);

            teams[_sortedTeams[i]].submittedByAdmin = true;
        }

        // Prizes are paid based on logarithmic scale, where first teams receives 1/2 of the prize pool, second 1/4 and so on
        uint prizePoolDivider = 2;

        for(i = 0; i < _sortedTeams.length; i++) {
            // Make sure all teams are included in _sortedTeams array
            // (i.e. the array should contain unique elements)
            require(teams[_sortedTeams[i]].submittedByAdmin);

            uint _prizeAmount = totalContribution / prizePoolDivider;

            if(teams[_sortedTeams[i]].rewardEligible && !teams[_sortedTeams[i]].disqualified) {
                _sortedTeams[i].transfer(_prizeAmount);
                teams[_sortedTeams[i]].reward = _prizeAmount;
                prizePoolDivider *= 2;
                PrizePaid(teams[_sortedTeams[i]].name, _prizeAmount);
            }
        }

        // Some small amount of ETH might remain in the contract after payout, becuase rewards are determened logarithmically
        // This amount is returned to contract owner to cover deployment and transaction costs
        // In case this amount turns out to be significantly larger than these costs, the administrator will distribute it to all teams equally
        administrator.transfer(this.balance);

        currentPeriod = Period.End;
        PeriodChanged(currentPeriod);
    }

    // Administrator can disqualify team
    function disqualifyTeam(address _teamAddress) onlyOwner {
        require(bytes(teams[_teamAddress].name).length > 0);

        teams[_teamAddress].disqualified = true;
        TeamDisqualified(_teamAddress);
    }

    // In case something goes wrong and contract needs to be redeployed, this is a way to return all contributions to the sponsors
    function returnContributionsToTheSponsors() onlyOwner {
        for(uint i = i; i < sponsors.length; i++) {
            sponsors[i].ethAddress.transfer(sponsors[i].contribution);
        }
    }

    // Public function that returns user type for the given address
    function getUserType(address _address) constant returns (string) {
        if(_address == administrator) {
            return "administrator";
        } else if(bytes(juryMembers[_address].name).length > 0) {
            return "jury";
        } else {
            return "other";
        }
    }

    // Check if jury member voted
    function checkJuryVoted(address _juryAddress) constant returns (bool){
        require(bytes(juryMembers[_juryAddress].name).length != 0);

        return juryMembers[_juryAddress].hasVoted;
    }

    // Returns total prize pool size
    function getPrizePoolSize() constant returns (uint) {
        return totalContribution;
    }

    function restartPeriod() onlyOwner {
        currentPeriod = Period.Registration;
    }
}