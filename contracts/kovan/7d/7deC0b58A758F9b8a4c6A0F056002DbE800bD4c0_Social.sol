pragma solidity 0.7.6;

import "@kleros/erc-792/contracts/IArbitrable.sol";
import "@kleros/erc-792/contracts/erc-1497/IEvidence.sol";
import "@kleros/erc-792/contracts/IArbitrator.sol";
import "@kleros/ethereum-libraries/contracts/CappedMath.sol";
import "./IPOH.sol";
import "./ICurate.sol";

contract Social is IArbitrable, IEvidence {
        
    using CappedMath for uint256;

    uint256 public constant AMOUNT_OF_CHOICES = 2;
    uint256 public constant MULTIPLIER_DIVISOR = 10000; // Divisor parameter for multipliers.
    uint256 public constant sharedStakeMultiplier = 5000; // Multiplier for calculating the appeal fee that must be paid by the submitter in the case where there is no winner or loser (e.g. when the arbitrator ruled "refuse to arbitrate").
    uint256 public constant winnerStakeMultiplier = 3000; // Multiplier for calculating the appeal fee of the party that won the previous round.
    uint256 public constant loserStakeMultiplier = 7000; // Multiplier for calculating the appeal fee of the party that lost the previous round.
    uint256 public constant POST_MAX_LENGTH = 280;

    /** Enums */
    
    enum Party {
       None,
       Author,
       Snitch
    }

    /* Structs */

    struct Round {
        uint256[3] paidFees; // Tracks the fees paid by each side in this round.
        Party sideFunded; // If the round is appealed, i.e. this is not the last round, Party.None means that both sides have paid.
        uint256 feeRewards; // Sum of reimbursable fees and stake rewards available to the parties that made contributions to the side that ultimately wins a dispute.
        mapping(address => uint256[3]) contributions; // Maps contributors to their contributions for each side.
    }

    struct PostData {
        address payable author; // Address that challenged the request.
        address threadAuthor; // The root author.
        uint64 rulesID;
        bool disputed; // The ID of the dispute. A post can only be disputed once.
        Party ruling;
        uint256 disputeID; // 
        uint256 repliedPostID;
        Moderation[] moderations;
    }

    struct Moderation {
        mapping(uint => Round) rounds;
        uint64 lastRoundID;
        bool closed;
        Party currentWinner;
        uint64 bondDeadline;
    }

    /* Storage */

    mapping(uint256 => bool) public isPolicyRegistered;
    PostData[] public postsList;
    mapping(address => mapping(address => bool)) public following;
    mapping(uint256 => uint256) public disputeIDtoPostID; // One-to-one relationship between the dispute and the transaction.
    mapping(uint256 => bool) public wasEvidenceEmitted;

    bytes public arbitratorExtraData; // Extra data to set up the arbitration.
    IArbitrator public immutable arbitrator;
    IPOH public immutable poh;
    ICurate public immutable curate; // Curated policies.
    ICurate public immutable evidenceCurate; // Curated policies.
    uint256 public immutable bondTimeout;
    
    /* Events */

    event Post(address indexed _author, uint256 indexed _postID, uint256 indexed _groupID, string _post);

    event FollowerUpdate(address indexed _follower, address indexed _followed, bool _following);

    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as losing.
     *  @param _postID The index of the transaction.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(uint256 indexed _postID, Party _party);

    /** @dev To be emitted when the appeal fees of one of the parties are fully funded.
     *  @param _postID The ID of the respective transaction.
     *  @param _party The party that is fully funded.
     */
    event HasPaidAppealFee(uint256 indexed _postID, Party _party);

    /**
     * @dev To be emitted when someone contributes to the appeal process.
     * @param _postID The ID of the respective transaction.
     * @param _party The party which received the contribution.
     * @param _contributor The address of the contributor.
     * @param _amount The amount contributed.
     */
    event AppealContribution(uint256 indexed _postID, Party _party, address _contributor, uint256 _amount);
    
    constructor(
        IArbitrator _arbitrator,
        IPOH _poh,
        ICurate _curate,
        ICurate _evidenceCurate
    ) {
        arbitrator = _arbitrator;
        poh = _poh;
        curate = _curate;
        evidenceCurate = _evidenceCurate;

        bondTimeout = 24 hours;
    }

    function registerNewPolicy(uint256 _index) public returns(bool success) {
        require(!isPolicyRegistered[_index], "Policy already registered.");
        bytes32 policyID = curate.itemList(_index);
        (bytes memory _contentRules, ICurate.Status status) = curate.items(policyID);

        if (status == ICurate.Status.Registered) {
            isPolicyRegistered[_index] = true;
            emit MetaEvidence(_index, string(_contentRules));
            success = true;
        }
    }

    function removePolicy(uint256 _index) internal returns(bool success) {
        require(isPolicyRegistered[_index], "Policy is not registered.");
        bytes32 policyID = curate.itemList(_index);
        (bytes memory _contentRules, ICurate.Status status) = curate.items(policyID);

        if (status == ICurate.Status.Absent) {
            isPolicyRegistered[_index] = false;
            success = true;
        }
    }

    function follow(address[] calldata _accounts, bool[] calldata _follows) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(msg.sender != _accounts[i], "Can't follow themself."); // Is this really needed?
            following[msg.sender][_accounts[i]] = _follows[i];
            emit FollowerUpdate(msg.sender, _accounts[i], _follows[i]);
        }
    }

    // This is also used for replies. Group ID is used to identify replies.
    function post(string calldata _message, uint256 _rulesID) external {
        require(bytes(_message).length <= POST_MAX_LENGTH, "Post is too long.");
        if (!isPolicyRegistered[_rulesID]) {
            require(registerNewPolicy(_rulesID), "Could not register policy.");
        } else {
            // Inneficient, but do we care about efficiency on sidechains?
            require(!removePolicy(_rulesID), "Policy has been removed.");
        }

        PostData storage postData = postsList.push();
        postData.author = msg.sender;
        postData.threadAuthor = msg.sender;
        postData.rulesID = uint64(_rulesID);

        emit Post(msg.sender, postsList.length, 0, _message);
    }

    function commentPost(uint256 _postID, string calldata _message) external payable {
        require(bytes(_message).length <= POST_MAX_LENGTH, "Post is too long.");

        PostData storage postData = postsList[_postID - 1];
        PostData storage commentData = postsList.push();
        commentData.author = msg.sender;
        commentData.threadAuthor = postData.threadAuthor;
        commentData.rulesID = postData.rulesID;
        commentData.repliedPostID = _postID;
        require(!removePolicy(postData.rulesID), "Policy governing the thread has been removed.");

        if (!following[postData.threadAuthor][msg.sender] && postData.threadAuthor != msg.sender) {
            // The author of the post is not following the commentator and the commentator is not the author
            // the originated the thread, therefore a deposit is required.
            Moderation storage moderation = commentData.moderations.push();
            Round storage round = moderation.rounds[0];
            moderation.lastRoundID++;

            uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
            uint256 totalCost = arbitrationCost * 3 / 2; // In case of dispute, the reward is 50% of the arbitration cost.
            
            uint256 depositRequired;
            if (poh.isRegistered(msg.sender)) {
                depositRequired = totalCost / 16;
            } else {
                depositRequired = totalCost / 2;
            }

            // Overpaying is allowed.
            contribute(round, Party.Author, msg.sender, msg.value, totalCost);
            require(round.paidFees[uint256(Party.Author)] >= depositRequired, "Insufficient funding.");
            moderation.bondDeadline = uint64(block.timestamp + bondTimeout);
            moderation.currentWinner = Party.Author;
        }

        emit Post(msg.sender, postsList.length, _postID, _message);
    }

    function moderatePost(uint256 _postID, Party _side) external payable {
        PostData storage postData = postsList[_postID - 1];
        require(!postData.disputed, "Post already disputed.");
        require(_side != Party.None, "Invalid side.");

        if (postData.moderations.length == 0) {
            postData.moderations.push();
            postData.moderations[postData.moderations.length - 1].lastRoundID++;
        }
        Moderation storage moderation = postData.moderations[postData.moderations.length - 1];
        if (moderation.closed) {
            // Start another round of moderation.
            moderation = postData.moderations.push();
            moderation.lastRoundID++;
        }
        require(_side != moderation.currentWinner, "Only the current loser can fund.");
        require(block.timestamp < moderation.bondDeadline || moderation.bondDeadline == 0, "Moderation market is closed.");

        Round storage round = moderation.rounds[0];

        uint256 arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);
        uint256 totalCost = arbitrationCost * 3 / 2; // In case of dispute, the reward is 50% of the arbitration cost.

        uint256 opposition = 3 - uint256(_side);
        uint256 depositRequired = round.paidFees[opposition] * 2;
        if (depositRequired == 0) {
            depositRequired = totalCost / 16;
        } else if (depositRequired > totalCost) {
            depositRequired = totalCost;
        }

        // Overpaying is allowed.
        contribute(round, _side, msg.sender, msg.value, totalCost);
        require(round.paidFees[uint256(_side)] >= depositRequired, "Insufficient funding.");
        
        if (
            round.paidFees[uint256(_side)] >= totalCost && 
            round.paidFees[opposition] >= totalCost
        ) {
            round.feeRewards = round.feeRewards - arbitrationCost;

            postData.disputeID = arbitrator.createDispute{value: arbitrationCost}(AMOUNT_OF_CHOICES, arbitratorExtraData);
            disputeIDtoPostID[postData.disputeID] = _postID;

            emit Dispute(arbitrator, postData.disputeID, uint256(postData.rulesID), _postID);
            postData.disputed = true;
            moderation.bondDeadline = 0;
            moderation.currentWinner = Party.None;
            moderation.lastRoundID++;
        } else {
            moderation.bondDeadline = uint64(block.timestamp + bondTimeout);
            moderation.currentWinner = _side;
        }
    }

    function resolveModerationMarket(uint256 _postID) external {
        // Moderation maket resolutions are not final. Posts can be reported again in the future.
        // Only arbitrator's rulings after a dispute is final.
        PostData storage postData = postsList[_postID - 1];
        Moderation storage moderation = postData.moderations[postData.moderations.length - 1];

        require(!postData.disputed, "Post already disputed.");
        require(block.timestamp > moderation.bondDeadline, "Market still ongoing.");

        moderation.closed = true;
        postData.ruling = moderation.currentWinner;
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _index A link to an evidence using its URI.
     */
    function submitEvidence(uint256 _index) external {
        bytes32 evidenceID = evidenceCurate.itemList(_index);
        (
            bytes memory evidenceSubmission, 
            ICurate.Status status,
            uint256 numberOfRequests
        ) = evidenceCurate.getItemInfo(evidenceID);
        
        require(
            status == ICurate.Status.Registered || 
            status == ICurate.Status.RegistrationRequested,
            "Invalid submission state."
        );

        bytes memory evidence = new bytes(evidenceSubmission.length - 32);
        for (uint256 i = 0; i < evidenceSubmission.length - 32; i++) {
            evidence[i] = evidenceSubmission[i + 32];
        }

        uint256 postID;
        assembly {
            postID := mload(add(evidenceSubmission, add(0x20, 0)))
        }

        (
            ,,,,
            address payable[3] memory parties,
            ,,,,
        ) = evidenceCurate.getRequestInfo(evidenceID, numberOfRequests - 1);

        require(!wasEvidenceEmitted[_index], "Evidence already emitted.");
        wasEvidenceEmitted[_index] = true;
        emit Evidence(arbitrator, postID, parties[1], string(evidence));
    }

    /** @dev Takes up to the total amount required to fund a side of an appeal. Reimburses the rest. Creates an appeal if both sides are fully funded.
     *  @param _postID The ID of the disputed transaction.
     *  @param _side The party that pays the appeal fee.
     */
    function fundAppeal(uint256 _postID, Party _side) external payable {
        PostData storage postData = postsList[_postID - 1];
        require(_side != Party.None, "Wrong party.");
        require(postData.disputed, "No dispute to appeal.");

        Moderation storage moderation = postData.moderations[postData.moderations.length - 1];
        uint256 currentRound = uint256(moderation.lastRoundID - 1);
        Round storage round = moderation.rounds[currentRound];
        require(_side != round.sideFunded, "Appeal fee has already been paid.");

        (uint256 appealCost, uint256 totalCost) = getAppealFeeComponents(postData.disputeID, uint256(_side));
        uint256 contribution = contribute(round, _side, msg.sender, msg.value, totalCost);

        emit AppealContribution(_postID, _side, msg.sender, contribution);
        
        if (round.paidFees[uint256(_side)] >= totalCost) {
            if (round.sideFunded == Party.None) {
                round.sideFunded = _side;
            } else {
                // Both sides are fully funded. Create an appeal.
                arbitrator.appeal{value: appealCost}(postData.disputeID, arbitratorExtraData);
                round.feeRewards = round.feeRewards - appealCost;
                moderation.lastRoundID++;
                round.sideFunded = Party.None;
            }
            emit HasPaidAppealFee(_postID, _side);
        }
    } 

    function getAppealFeeComponents(
        uint256 _disputeID,
        uint256 _side
    ) internal view returns (uint256 appealCost, uint256 totalCost) {
        (uint256 appealPeriodStart, uint256 appealPeriodEnd) = arbitrator.appealPeriod(_disputeID);
        require(block.timestamp >= appealPeriodStart && block.timestamp < appealPeriodEnd, "Not in appeal period.");

        uint256 multiplier;
        uint256 winner = arbitrator.currentRuling(_disputeID);
        if (winner == _side){
            multiplier = winnerStakeMultiplier;
        } else if (winner == 0){
            multiplier = sharedStakeMultiplier;
        } else {
            require(block.timestamp < (appealPeriodEnd + appealPeriodStart)/2, "Not in loser's appeal period.");
            multiplier = loserStakeMultiplier;
        }

        appealCost = arbitrator.appealCost(_disputeID, arbitratorExtraData);
        totalCost = appealCost.addCap(appealCost.mulCap(multiplier) / MULTIPLIER_DIVISOR);
    }

    /** @dev Make a fee contribution.
     *  @param _round The round to contribute to.
     *  @param _side The side to contribute to.
     *  @param _contributor The contributor.
     *  @param _amount The amount contributed.
     *  @param _totalRequired The total amount required for this side.
     *  @return The amount of fees contributed.
     */
    function contribute(Round storage _round, Party _side, address payable _contributor, uint256 _amount, uint256 _totalRequired) internal returns (uint) {
        uint256 contribution;
        uint256 remainingETH;
        (contribution, remainingETH) = calculateContribution(_amount, _totalRequired.subCap(_round.paidFees[uint256(_side)]));
        _round.contributions[_contributor][uint256(_side)] += contribution;
        _round.paidFees[uint256(_side)] += contribution;
        _round.feeRewards += contribution;

        if (remainingETH != 0)
            _contributor.send(remainingETH);

        return contribution;
    }
    
    /** @dev Returns the contribution value and remainder from available ETH and required amount.
     *  @param _available The amount of ETH available for the contribution.
     *  @param _requiredAmount The amount of ETH required for the contribution.
     *  @return taken The amount of ETH taken.
     *  @return remainder The amount of ETH left from the contribution.
     */
    function calculateContribution(uint256 _available, uint256 _requiredAmount)
        internal
        pure
        returns(uint256 taken, uint256 remainder)
    {
        if (_requiredAmount > _available)
            return (_available, 0); // Take whatever is available, return 0 as leftover ETH.

        remainder = _available - _requiredAmount;
        return (_requiredAmount, remainder);
    }
    
    /** @dev Witdraws contributions of appeal rounds. Reimburses contributions if the appeal was not fully funded. 
     *  If the appeal was fully funded, sends the fee stake rewards and reimbursements proportional to the contributions made to the winner of a dispute.
     *  @param _beneficiary The address that made contributions.
     *  @param _postID The ID of the associated transaction.
     *  @param _moderationID The ID of the moderatino occurence.
     *  @param _round The round from which to withdraw.
     */
    function withdrawFeesAndRewards(address payable _beneficiary, uint256 _postID, uint256 _moderationID, uint256 _round) external returns(uint256 reward) {
        PostData storage postData = postsList[_postID - 1];
        Moderation storage moderation = postData.moderations[_moderationID];
        require(moderation.closed, "Moderation must be closed.");

        Round storage round = moderation.rounds[_round];
        uint256[3] storage contributionTo = round.contributions[_beneficiary];
        uint256 lastRound = moderation.lastRoundID - 1;

        if (_round == lastRound && _round != 0) {
            // Allow to reimburse if funding was unsuccessful.
            reward = contributionTo[uint256(Party.Author)] + contributionTo[uint256(Party.Snitch)];
        } else if (postData.ruling == Party.None) {
            // Reimburse unspent fees proportionally if there is no winner and loser.
            uint256 totalFeesPaid = round.paidFees[uint256(Party.Author)] + round.paidFees[uint256(Party.Snitch)];
            uint256 totalBeneficiaryContributions = contributionTo[uint256(Party.Author)] + contributionTo[uint256(Party.Snitch)];
            reward = totalFeesPaid > 0 ? (totalBeneficiaryContributions * round.feeRewards) / totalFeesPaid : 0;
        } else {
            // Reward the winner.
            uint256 paidFees = round.paidFees[uint256(postData.ruling)];
            reward = paidFees > 0
                ? (contributionTo[uint256(postData.ruling)] * round.feeRewards) / paidFees
                : 0;
        }
        contributionTo[uint256(Party.Author)] = 0;
        contributionTo[uint256(Party.Snitch)] = 0;

        _beneficiary.send(reward); // It is the user responsibility to accept ETH.
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator to enforce the final ruling.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) public override {
        uint256 postID = disputeIDtoPostID[_disputeID];
        PostData storage postData = postsList[postID - 1];
        require(
            postData.disputed &&
            msg.sender == address(arbitrator) &&
            _ruling <= AMOUNT_OF_CHOICES, 
            "Ruling can't be processed."
        );
        
        Moderation storage moderation = postData.moderations[postData.moderations.length - 1];
        Round storage lastRound = moderation.rounds[uint256(moderation.lastRoundID - 1)];

        // If only one side paid its fees we assume the ruling to be in its favor.
        Party finalRuling;
        if (lastRound.sideFunded == Party.None)
            finalRuling = Party(_ruling);
        else
            finalRuling = lastRound.sideFunded;
        postData.ruling = finalRuling;
        moderation.closed = true;

        emit Ruling(arbitrator, _disputeID, uint256(finalRuling));
    }

    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    function getTotalPosts() external view returns(uint256) {
        return postsList.length;
    }

    /** @dev Gets the number of moderation events of the specific post.
     *  @param _postID The ID of the transaction.
     *  @return The number of rounds.
     */
    function getNumberOfModerations(uint256 _postID) external view returns (uint256) {
        return postsList[_postID - 1].moderations.length;
    }

    /** @dev Gets the number of rounds of the specific transaction.
     *  @param _postID The ID of the transaction.
     *  @return The number of rounds.
     */
    function getNumberOfRounds(uint256 _postID) external view returns (uint256) {
        PostData storage postData = postsList[_postID - 1];
        Moderation storage moderation = postData.moderations[postData.moderations.length - 1];
        return uint256(moderation.lastRoundID);
    }

    /** @dev Gets the contributions made by a party for a given round of the appeal.
     *  @param _postID The ID of the transaction.
     *  @param _moderationID The ID of the moderatino occurence.
     *  @param _round The position of the round.
     *  @param _contributor The address of the contributor.
     *  @return contributions The contributions.
     */
    function getContributions(
        uint256 _postID,
        uint256 _moderationID,
        uint256 _round,
        address _contributor
    ) external view returns(uint256[3] memory contributions) {
        PostData storage postData = postsList[_postID - 1];
        Moderation storage moderation = postData.moderations[_moderationID];
        Round storage round = moderation.rounds[_round];
        contributions = round.contributions[_contributor];
    }

    /** @dev Gets the information on a round of a transaction.
     *  @param _postID The ID of the transaction.
     *  @param _moderationID The ID of the moderatino occurence.
     *  @param _round The round to query.
     *  @return paidFees sideFunded feeRewards appealed The round information.
     */
    function getRoundInfo(uint256 _postID, uint256 _moderationID, uint256 _round)
        external
        view
        returns (
            uint256[3] memory paidFees,
            Party sideFunded,
            uint256 feeRewards,
            bool appealed
        )
    {
        PostData storage postData = postsList[_postID - 1];
        Moderation storage moderation = postData.moderations[_moderationID];
        Round storage round = moderation.rounds[_round];
        return (
            round.paidFees,
            round.sideFunded,
            round.feeRewards,
            _round != moderation.lastRoundID - 1
        );
    }
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity >=0.7;

import "../IArbitrator.sol";

/** @title IEvidence
 *  ERC-1497: Evidence Standard
 */
interface IEvidence {
    /**
     * @dev To be emitted when meta-evidence is submitted.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/metaevidence.json'
     */
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /**
     * @dev To be raised when evidence is submitted. Should point to the resource (evidences are not to be stored on chain due to gas considerations).
     * @param _arbitrator The arbitrator of the contract.
     * @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     * @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     * @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9RuzDEJNnarT3WZ7kem5bk8DZAzx78acJjMFH/evidence.json'
     */
    event Evidence(
        IArbitrator indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /**
     * @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
     * @param _arbitrator The arbitrator of the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _metaEvidenceID Unique identifier of meta-evidence.
     * @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(
        IArbitrator indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity >=0.7;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {Waiting, Appealable, Solved}

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

// SPDX-License-Identifier: MIT

/**
 * @authors: [@mtsalenc, @hbarcelos]
 * @reviewers: [@clesaege*, @ferittuncer]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.7.6;


/**
 * @title CappedMath
 * @dev Math operations with caps for under and overflow.
 */
library CappedMath {
    uint constant private UINT_MAX = 2**256 - 1;

    /**
     * @dev Adds two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function addCap(uint _a, uint _b) internal pure returns (uint) {
        uint c = _a + _b;
        return c >= _a ? c : UINT_MAX;
    }

    /**
     * @dev Subtracts two integers, returns 0 on underflow.
     */
    function subCap(uint _a, uint _b) internal pure returns (uint) {
        if (_b > _a)
            return 0;
        else
            return _a - _b;
    }

    /**
     * @dev Multiplies two unsigned integers, returns 2^256 - 1 on overflow.
     */
    function mulCap(uint _a, uint _b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring '_a' not being zero, but the
        // benefit is lost if '_b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0)
            return 0;

        uint c = _a * _b;
        return c / _a == _b ? c : UINT_MAX;
    }
}

pragma solidity 0.7.6;

interface IPOH {
    function isRegistered(address _submissionID) external view returns (bool);
}

pragma solidity 0.7.6;

interface ICurate {
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    function itemList(uint256 _index) external returns (bytes32);
    function items(bytes32 _itemID) external view returns (bytes memory data, Status status);
    function getItemInfo(bytes32 _itemID)
        external
        view
        returns (
            bytes memory data,
            Status status,
            uint numberOfRequests
        );
    function getRequestInfo(bytes32 _itemID, uint _request)
        external
        view
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address payable[3] memory parties,
            uint numberOfRounds,
            uint256 ruling,
            address arbitrator,
            bytes memory arbitratorExtraData,
            uint metaEvidenceID
        );
}

