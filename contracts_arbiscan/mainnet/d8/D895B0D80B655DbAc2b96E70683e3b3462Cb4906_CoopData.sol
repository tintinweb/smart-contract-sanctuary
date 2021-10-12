/**
 *Submitted for verification at arbiscan.io on 2021-10-12
*/

// Coop Data contract for deployment on arbitrum
// Audit report available at https://www.tkd-coop.com/files/audit.pdf

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Control who can access various functions.
contract AccessControl {
    address payable public creatorAddress;
    mapping(address => bool) public admins;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress, "Creator Only");
        _;
    }

    modifier onlyADMINS() {
        require(admins[msg.sender] == true);
        _;
    }

    // Constructor

    constructor() {
        creatorAddress = payable(msg.sender);
    }

    //Admins are contracts or addresses that have write access

    function addAdmin(address _newAdmin) public onlyCREATOR {
        if (admins[_newAdmin] == false) {
            admins[_newAdmin] = true;
        }
    }

    function removeAdmin(address _oldAdmin) public onlyCREATOR {
        if (admins[_oldAdmin] == true) {
            admins[_oldAdmin] = false;
        }
    }
}

//Interface to TAC Contract
abstract contract ITAC {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool);

    function balanceOf(address account) external view virtual returns (uint256);
}

abstract contract ITACTreasury {
    function awardTAC(
        address winner,
        address loser,
        address referee
    ) public virtual;

    function awardTrainingTAC(address athlete, address referee) public virtual;
}

contract CoopData is AccessControl {
    /////////////////////////////////////////////////DATA STRUCTURES AND GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////

    uint256 public numUsers = 0; //total number of user profiles, independent of number of addresses with balances
    uint64 public numMatches = 0; //total number of matches recorded

    //Main data structure to hold info about an athlete
    struct User {
        address userAddress; //since the address is unique this also serves as their id.
        uint8 allowedMatches;
        uint64[] matches;
        uint64[] proposedMatches;
        uint64[] approvedMatches;
        uint64[] trainings;
    }

    // Main data structure to hold info about a match
    struct Match {
        uint64 id;
        address winner; //address (id) of the athlete who won
        uint8 winnerPoints;
        address loser; //address (id) of the athlete who lost
        uint8 loserPoints;
        address referee; //Who recorded the match
        bool loserVerified;
        bool winnerVerified;
        uint64 time;
        string notes;
    }

    // Main data structure to hold info about a training

    struct Training {
        uint64 id;
        address athlete;
        address referee;
        uint8 info;
        bool verified;
        uint64 time;
    }

    // Main mapping storing an Match record for each match id.
    Match[] public allMatches;
    Match[] public proposedMatches;
    Training[] public allTrainings;
    address[] public allUsersById;

    // Main mapping storing an athlete record for each address.
    mapping(address => User) public allUsers;

    //A list of all proposed matches to be used as ID.
    uint64 public numProposedMatches = 0;
    bool public requireMembership = true;

    address public TACContract = 0x552A032fd4A051b53A487762133b6085cA95F403;
    address public EventsContract = 0xb030a908B666b37Ba37e22681D931F93349A1055;
    address public tACTreasuryContract =
        0xCA4eb1B6922dEf07b7a6FADD9Ab1545B92Cf0be3;

    //The amount of Hwangs required to spar a match.
    uint256 public matchCost = 10000000000000000000;

    /////////////////////////////////////////////////////////CONTRACT CONTROL FUNCTIONS //////////////////////////////////////////////////

    function changeParameters(
        address _TACContract,
        address _EventsContract,
        uint256 _matchCost,
        bool _requireMembership,
        address _tacTreasuryContract
    ) external onlyCREATOR {
        TACContract = _TACContract;
        EventsContract = _EventsContract;
        matchCost = _matchCost;
        requireMembership = _requireMembership;
        tACTreasuryContract = _tacTreasuryContract;
    }

    /////////////////////////////////////////////////////////USER INFO FUNCTIONS  //////////////////////////////////////////////////

    //function which sets information for the address which submitted the transaction.
    function setUser() public {
        bool zeroMatches = false;

        if (allUsers[msg.sender].userAddress == address(0)) {
            //new user so add to number of users
            numUsers++;
            allUsersById.push(msg.sender);
            zeroMatches = true;
        }

        User storage user = allUsers[msg.sender];
        user.userAddress = msg.sender;
        if (zeroMatches == true) {
            user.allowedMatches = 0;
        }
    }

    //Function which specifies how many matches a user has left.
    //Only coop members have approved matches and only referees need them.
    //Set 0 to remove a user's ability to record matches.
    function setUserAllowedMatches(address user, uint8 newApprovalNumber)
        public
        onlyADMINS
    {
        allUsers[user].allowedMatches = newApprovalNumber;
    }

    //Function which returns user information for the specified address.
    function getUser(address _address)
        public
        view
        returns (
            address userAddress,
            uint64[] memory matches,
            uint64[] memory trainings,
            uint8 allowedMatches
        )
    {
        User storage user = allUsers[_address];
        userAddress = user.userAddress;
        matches = user.matches;
        allowedMatches = user.allowedMatches;
        trainings = user.trainings;
    }

    //Function which returns user information for the specified address.
    function getUserMatches(address _address)
        public
        view
        returns (
            uint64[] memory _proposedMatches,
            uint64[] memory approvedMatches
        )
    {
        User storage user = allUsers[_address];
        _proposedMatches = user.proposedMatches;
        approvedMatches = user.approvedMatches;
    }

    function getUserMatchNumber(address _address)
        public
        view
        returns (uint256)
    {
        return allUsers[_address].approvedMatches.length;
    }

    /////////////////////////////////////////////////////////MATCH FUNCTIONS  //////////////////////////////////////////////////

    function proposeMatch(
        address _winner,
        uint8 _winnerPoints,
        address _loser,
        uint8 _loserPoints,
        address _referee,
        string memory _notes
    ) public {
        require(
            (allUsers[_referee].allowedMatches > 0 ||
                requireMembership == false),
            "Members must have available allowed matches"
        );
        require(msg.sender == _referee, "The referee must record the match");
        require(
            (_winner != _loser) &&
                (_winner != _referee) &&
                (_loser != _referee),
            "The only true battle is against yourself, but can't count it here."
        );

        require(
            allUsers[_winner].userAddress != address(0),
            "Winner is not yet registered"
        );
        require(
            allUsers[_loser].userAddress != address(0),
            "Loser is not yet registered"
        );

        //Decrement the referee's match allowance
        if (requireMembership == true) {
            allUsers[_referee].allowedMatches -= 1;
        }

        // Create the proposed match
        Match memory proposedMatch;
        proposedMatch.id = numProposedMatches;
        proposedMatch.winner = _winner;
        proposedMatch.winnerPoints = _winnerPoints;
        proposedMatch.loser = _loser;
        proposedMatch.loserPoints = _loserPoints;
        proposedMatch.referee = _referee;
        proposedMatch.loserVerified = false;
        proposedMatch.winnerVerified = false;
        proposedMatch.time = uint64(block.timestamp);
        proposedMatch.notes = _notes;

        numProposedMatches++;

        // Add it to the list of each person as well as the overall list.
        proposedMatches.push(proposedMatch);
        allUsers[_winner].proposedMatches.push(proposedMatch.id);
        allUsers[_loser].proposedMatches.push(proposedMatch.id);
        allUsers[_referee].proposedMatches.push(proposedMatch.id);
    }

    function overwriteMatch(
        uint64 id,
        address _winner,
        uint8 _winnerPoints,
        address _loser,
        uint8 _loserPoints,
        string memory _notes
    ) public {
        // The referee only can overwrite matches
        require(
            proposedMatches[id].referee == msg.sender,
            "Only the referee may overwrite a match"
        );
        // Matches can only be overwritten before they have been approved by both athletes
        require(
            proposedMatches[id].winnerVerified == false ||
                proposedMatches[id].loserVerified == false,
            "This match has already been finalized"
        );
        // Each participant can have only one role.
        require(
            (_winner != _loser) &&
                (_winner != msg.sender) &&
                (_loser != msg.sender),
            "The only true battle is against yourself, but can't count it here."
        );

        // Reset the athlete approvals since the result has changed.
        proposedMatches[id].winnerVerified = false;
        proposedMatches[id].loserVerified = false;

        require(
            allUsers[_winner].userAddress != address(0),
            "Winner is not yet registered"
        );
        require(
            allUsers[_loser].userAddress != address(0),
            "Loser is not yet registered"
        );

        //Push to their proposedMatches if athlete changes
        if (
            (_winner != proposedMatches[id].winner) &&
            (_winner != proposedMatches[id].loser)
        ) {
            allUsers[_winner].proposedMatches.push(id);
        }

        if (
            (_loser != proposedMatches[id].winner) &&
            (_loser != proposedMatches[id].loser)
        ) {
            allUsers[_loser].proposedMatches.push(id);
        }

        // Overwrite the match.
        proposedMatches[id].winner = _winner;
        proposedMatches[id].winnerPoints = _winnerPoints;
        proposedMatches[id].loser = _loser;
        proposedMatches[id].loserPoints = _loserPoints;
        proposedMatches[id].notes = _notes;

        allUsers[_winner].proposedMatches.push(id);
        allUsers[_loser].proposedMatches.push(id);
    }

    function getProposedMatch(uint64 matchId)
        public
        view
        returns (
            uint64 id,
            address winner,
            uint8 winnerPoints,
            address loser,
            uint8 loserPoints,
            address referee,
            uint64 time,
            string memory notes,
            bool winnerVerified,
            bool loserVerified
        )
    {
        id = proposedMatches[matchId].id;
        winner = proposedMatches[matchId].winner;
        winnerPoints = proposedMatches[matchId].winnerPoints;
        loser = proposedMatches[matchId].loser;
        loserPoints = proposedMatches[matchId].loserPoints;
        referee = proposedMatches[matchId].referee;
        notes = proposedMatches[matchId].notes;
        winnerVerified = proposedMatches[matchId].winnerVerified;
        loserVerified = proposedMatches[matchId].loserVerified;
        time = proposedMatches[matchId].time;
    }

    function approveMatch(uint64 id) public {
        // Make sure the match has not already been verified.
        require(
            ((proposedMatches[id].winnerVerified == false) ||
                (proposedMatches[id].loserVerified == false)),
            "Both athletes have already verified this match"
        );

        //  Find if the user calling approve is the winner or loser.
        bool winner = false;
        bool loser = false;
        if (proposedMatches[id].winner == msg.sender) {
            winner = true;
        }
        if (proposedMatches[id].loser == msg.sender) {
            loser = true;
        }

        require(winner || loser, "You are not a player in this match");

        // First see if the other player has verified.

        //Case 1 - The caller is the winner
        if (winner) {
            // If the loser has not verified.
            if (proposedMatches[id].loserVerified == false) {
                proposedMatches[id].winnerVerified = true;
            }
            //If the loser has verified
            else {
                proposedMatches[id].winnerVerified = true;
                finalizeMatch(id);
            }
        }

        //Case 2 - The caller is the losing athlete
        if (loser) {
            // If the winner has not verified.
            if (proposedMatches[id].winnerVerified == false) {
                proposedMatches[id].loserVerified = true;
            }
            //If the loser has verified
            else {
                proposedMatches[id].loserVerified = true;
                finalizeMatch(id);
            }
        }
    }

    //Called to record match and award TAC
    //Internal function called only once all checks are passed
    function finalizeMatch(uint64 id) internal {
        allUsers[proposedMatches[id].winner].approvedMatches.push(id);
        allUsers[proposedMatches[id].loser].approvedMatches.push(id);
        allUsers[proposedMatches[id].referee].approvedMatches.push(id);

        proposedMatches[id].id = numMatches;

        //Add the match to the athletes
        allUsers[proposedMatches[id].winner].matches.push(numMatches);
        allUsers[proposedMatches[id].loser].matches.push(numMatches);

        allMatches.push(proposedMatches[id]);
        numMatches++;

        ITAC TAC = ITAC(TACContract);
        //Transfer the 10 TAC from each athlete.
        TAC.transferFrom(proposedMatches[id].loser, creatorAddress, matchCost);
        TAC.transferFrom(proposedMatches[id].winner, creatorAddress, matchCost);

        ITACTreasury TACTreasury = ITACTreasury(tACTreasuryContract);
        //Award bonus TAC
        TACTreasury.awardTAC(
            allUsers[proposedMatches[id].winner].userAddress,
            allUsers[proposedMatches[id].loser].userAddress,
            allUsers[proposedMatches[id].referee].userAddress
        );
    }

    function recordEventMatch(
        address _winner,
        uint8 _winnerPoints,
        address _loser,
        uint8 _loserPoints,
        address _referee
    ) public returns (uint64) {
        //Check that the events contract is the caller
        require(
            msg.sender == EventsContract,
            "Only the events contract can call"
        );

        //Record the match.
        Match memory newMatch;
        newMatch.id = numMatches;
        newMatch.winner = _winner;
        newMatch.winnerPoints = _winnerPoints;
        newMatch.loser = _loser;
        newMatch.loserPoints = _loserPoints;
        newMatch.referee = _referee;
        newMatch.time = uint64(block.timestamp);

        numMatches++;
        allMatches.push(newMatch);

        ITAC TAC = ITAC(TACContract);

        //Add the match to the athletes and ref
        allUsers[_winner].matches.push(newMatch.id);
        allUsers[_loser].matches.push(newMatch.id);
        allUsers[_referee].matches.push(newMatch.id);

        if (
            (TAC.balanceOf(_loser) >= matchCost) &&
            (TAC.balanceOf(_winner) >= matchCost)
        ) {
            //Transfer the 10 TAC from each athlete.
            TAC.transferFrom(_loser, creatorAddress, matchCost);
            TAC.transferFrom(_winner, creatorAddress, matchCost);

            ITACTreasury TACTreasury = ITACTreasury(tACTreasuryContract);
            //Issue TAC
            TACTreasury.awardTAC(_winner, _loser, _referee);
            return (numMatches - 1);
        } else {
            return 0;
        }
    }

    function getMatch(uint64 _id)
        public
        view
        returns (
            uint64 id,
            address winner,
            uint8 winnerPoints,
            address loser,
            uint8 loserPoints,
            uint64 time,
            string memory notes,
            address referee
        )
    {
        Match memory matchToGet = allMatches[_id];
        id = matchToGet.id;
        winner = matchToGet.winner;
        winnerPoints = matchToGet.winnerPoints;
        loser = matchToGet.loser;
        loserPoints = matchToGet.loserPoints;
        time = matchToGet.time;
        notes = matchToGet.notes;
        referee = matchToGet.referee;
    }

    /////////////////////////////////////////////////////////TRAINING FUNCTIONS  //////////////////////////////////////////////////

    function recordTraining(address _athlete, uint8 _info) public {
        require(
            (allUsers[msg.sender].allowedMatches > 0 ||
                requireMembership == false),
            "Referee must have available allowed matches"
        );
        require(msg.sender != _athlete, "You cannot record your own training");

        //Decrement the referee's match allowance
        if (requireMembership == true) {
            allUsers[msg.sender].allowedMatches -= 1;
        }

        // Create the proposed training
        Training memory training;
        training.id = uint64(allTrainings.length);
        training.athlete = _athlete;
        training.info = _info;
        training.verified = false;
        training.referee = msg.sender;
        training.time = uint64(block.timestamp);

        // Add it to the list of each person as well as the overall list.
        allTrainings.push(training);
        allUsers[_athlete].trainings.push(training.id);
        allUsers[msg.sender].trainings.push(training.id);
    }

    function getAllTrainings() public view returns (Training[] memory) {
        return allTrainings;
    }

    function getTraining(uint64 idToGet)
        public
        view
        returns (
            uint64 id,
            address athlete,
            address referee,
            uint8 info,
            bool verified,
            uint64 time
        )
    {
        id = allTrainings[idToGet].id;
        athlete = allTrainings[idToGet].athlete;
        referee = allTrainings[idToGet].referee;
        info = allTrainings[idToGet].info;
        verified = allTrainings[idToGet].verified;
        time = allTrainings[idToGet].time;
    }

    function verifyTraining(uint64 id) public {
        require(
            allTrainings[id].verified == false,
            "Training has already been verified"
        );

        require(
            allTrainings[id].athlete == msg.sender,
            "Only the athlete may verify"
        );

        allTrainings[id].verified = true;

        ITAC TAC = ITAC(TACContract);

        //Transfer 10 TAC from the athlete.
        TAC.transferFrom(msg.sender, creatorAddress, matchCost);

        ITACTreasury TACTreasury = ITACTreasury(tACTreasuryContract);

        //Award bonus TAC
        TACTreasury.awardTrainingTAC(msg.sender, allTrainings[id].referee);
    }
}