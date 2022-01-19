/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

/**
 *  @authors: [@mtsalenc]
 *  @reviewers: [@clesaege]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.4.26;


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

/**
 *  @title Arbitrator
 *  @author Clément Lesaege - <[email protected]>
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */



/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint _disputeID, bytes _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     */
    event AppealPossible(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling);
}

/**
 *  @title IArbitrable
 *  @author Enrique Piqueras - <[email protected]>
 *  Bug Bounties: This code hasn't undertaken a bug bounty program yet.
 */



/** @title IArbitrable
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emmited when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external;
}

contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData) public {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) internal;
}



contract AutoAppealableArbitrator is Arbitrator {
    using CappedMath for uint; // Operations bounded between 0 and 2**256 - 1.
    
    address public owner = msg.sender;
    uint arbitrationPrice; // Not public because arbitrationCost already acts as an accessor.
    uint constant NOT_PAYABLE_VALUE = (2**256 - 2) / 2; // High value to be sure that the appeal is too expensive.

    struct Dispute {
        Arbitrable arbitrated;  // The contract requiring arbitration.
        uint choices;           // The amount of possible choices, 0 excluded.
        uint fees;              // The total amount of fees collected by the arbitrator.
        uint ruling;            // The current ruling.
        DisputeStatus status;   // The status of the dispute.
        uint appealCost;        // The cost to appeal. 0 before it is appealable.
        uint appealPeriodStart; // The start of the appeal period. 0 before it is appealable.
        uint appealPeriodEnd;   // The end of the appeal Period. 0 before it is appealable.
    }

    modifier onlyOwner {require(msg.sender==owner, "Can only be called by the owner."); _;}

    Dispute[] public disputes;

    /** @dev Constructor. Set the initial arbitration price.
     *  @param _arbitrationPrice Amount to be paid for arbitration.
     */
    constructor(uint _arbitrationPrice) public {
        arbitrationPrice = _arbitrationPrice;
    }

    /** @dev Set the arbitration price. Only callable by the owner.
     *  @param _arbitrationPrice Amount to be paid for arbitration.
     */
    function setArbitrationPrice(uint _arbitrationPrice) external onlyOwner {
        arbitrationPrice = _arbitrationPrice;
    }

    /** @dev Cost of arbitration. Accessor to arbitrationPrice.
     *  @param _extraData Not used by this contract.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes _extraData) public view returns(uint fee) {
        return arbitrationPrice;
    }

    /** @dev Cost of appeal. If appeal is not possible, it's a high value which can never be paid.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Not used by this contract.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes _extraData) public view returns(uint fee) {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.status == DisputeStatus.Appealable)
            return dispute.appealCost;
        else
            return NOT_PAYABLE_VALUE;
    }

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost().
     *  @param _choices Amount of choices the arbitrator can make in this dispute. When ruling <= choices.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint _choices, bytes _extraData) public payable returns(uint disputeID) {
        super.createDispute(_choices, _extraData);
        disputeID = disputes.push(Dispute({
            arbitrated: Arbitrable(msg.sender),
            choices: _choices,
            fees: msg.value,
            ruling: 0,
            status: DisputeStatus.Waiting,
            appealCost: 0,
            appealPeriodStart: 0,
            appealPeriodEnd: 0
            })) - 1; // Create the dispute and return its number.
        emit DisputeCreation(disputeID, Arbitrable(msg.sender));
    }
    
    /** @dev Give a ruling. UNTRUSTED.
     *  @param _disputeID ID of the dispute to rule.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 means "Not able/wanting to make a decision".
     */
    function giveRuling(uint _disputeID, uint _ruling) external onlyOwner {
        Dispute storage dispute = disputes[_disputeID];
        require(_ruling <= dispute.choices, "Invalid ruling.");
        require(dispute.status == DisputeStatus.Waiting, "The dispute must be waiting for arbitration.");

        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;

        msg.sender.send(dispute.fees); // Avoid blocking.
        dispute.arbitrated.rule(_disputeID, _ruling);
    }
    
    /** @dev Give an appealable ruling.
     *  @param _disputeID ID of the dispute to rule.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 means "Not able/wanting to make a decision".
     *  @param _appealCost The cost of appeal.
     *  @param _timeToAppeal The time to appeal the ruling.
     */
    function giveAppealableRuling(uint _disputeID, uint _ruling, uint _appealCost, uint _timeToAppeal) external onlyOwner {
        Dispute storage dispute = disputes[_disputeID];
        require(_ruling <= dispute.choices, "Invalid ruling.");
        require(dispute.status == DisputeStatus.Waiting, "The dispute must be waiting for arbitration.");
        
        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Appealable;
        dispute.appealCost = _appealCost;
        dispute.appealPeriodStart = now;
        dispute.appealPeriodEnd = now.addCap(_timeToAppeal);
        
        emit AppealPossible(_disputeID, dispute.arbitrated);
    }
    
    
    /** @dev Change the appeal fee of a dispute.
     *  @param _disputeID The ID of the dispute to update.
     *  @param _appealCost The new cost to appeal this ruling.
     */
    function changeAppealFee(uint _disputeID, uint _appealCost) external onlyOwner {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
        
        dispute.appealCost = _appealCost;
    }
    
    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes _extraData) public requireAppealFee(_disputeID, _extraData) payable {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
        require(now < dispute.appealPeriodEnd, "The appeal must occur before the end of the appeal period.");
        
        dispute.fees += msg.value;
        dispute.status = DisputeStatus.Waiting;
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }
    
    /** @dev Execute the ruling of a dispute after the appeal period has passed. UNTRUSTED.
     *  @param _disputeID ID of the dispute to execute.
     */
    function executeRuling(uint _disputeID) external {
        Dispute storage dispute = disputes[_disputeID];
        require(dispute.status == DisputeStatus.Appealable, "The dispute must be appealable.");
        require(now >= dispute.appealPeriodEnd, "The dispute must be executed after its appeal period has ended.");
        
        dispute.status = DisputeStatus.Solved;
        msg.sender.send(dispute.fees); // Avoid blocking.
        dispute.arbitrated.rule(_disputeID, dispute.ruling);
    }

    /** @dev Return the status of a dispute (in the sense of ERC792, not the Dispute property).
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view returns(DisputeStatus status) {
        Dispute storage dispute = disputes[_disputeID];
        if (disputes[_disputeID].status==DisputeStatus.Appealable && now>=dispute.appealPeriodEnd) // If the appeal period is over, consider it solved even if rule has not been called yet.
            return DisputeStatus.Solved;
        else
            return disputes[_disputeID].status;
    }

    /** @dev Return the ruling of a dispute.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which have been given or which would be given if no appeals are raised.
     */
    function currentRuling(uint _disputeID) public view returns(uint ruling) {
        return disputes[_disputeID].ruling;
    }
    
    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return The start and end of the period.
     */
    function appealPeriod(uint _disputeID) public view returns(uint start, uint end) {
        Dispute storage dispute = disputes[_disputeID];
        return (dispute.appealPeriodStart, dispute.appealPeriodEnd);
    }

}