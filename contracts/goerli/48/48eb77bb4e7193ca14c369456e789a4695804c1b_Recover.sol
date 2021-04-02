/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: GPL-3.0

/* ____/\\\\\\\\\______/\\\\\\\\\\\\\\\________/\\\\\\\\\_______/\\\\\_______/\\\________/\\\__/\\\\\\\\\\\\\\\____/\\\\\\\\\____________ */        
/* __/\\\///////\\\___\/\\\///////////______/\\\////////______/\\\///\\\____\/\\\_______\/\\\_\/\\\///////////___/\\\///////\\\__________ */        
/* __\/\\\_____\/\\\___\/\\\_______________/\\\/_____________/\\\/__\///\\\__\//\\\______/\\\__\/\\\_____________\/\\\_____\/\\\_________ */       
/* ___\/\\\\\\\\\\\/____\/\\\\\\\\\\\______/\\\______________/\\\______\//\\\__\//\\\____/\\\___\/\\\\\\\\\\\_____\/\\\\\\\\\\\/_________ */      
/* ____\/\\\//////\\\____\/\\\///////______\/\\\_____________\/\\\_______\/\\\___\//\\\__/\\\____\/\\\///////______\/\\\//////\\\________ */    
/* _____\/\\\____\//\\\___\/\\\_____________\//\\\____________\//\\\______/\\\_____\//\\\/\\\_____\/\\\_____________\/\\\____\//\\\______ */    
/* ______\/\\\_____\//\\\__\/\\\______________\///\\\___________\///\\\__/\\\________\//\\\\\______\/\\\_____________\/\\\_____\//\\\____ */   
/* _______\/\\\______\//\\\_\/\\\\\\\\\\\\\\\____\////\\\\\\\\\____\///\\\\\/__________\//\\\_______\/\\\\\\\\\\\\\\\_\/\\\______\//\\\__ */  
/* ________\///________\///__\///////////////________\/////////_______\/////_____________\///________\///////////////__\///________\///__ */  

/**
 *  @authors: [@n1c01a5]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: [0x02c86846887faa1d964a838dc50739b49c8329bc]
 */

pragma solidity ^0.8.3;


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

/** @title Arbitrable
 *  Arbitrable abstract contract.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
abstract contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes storage _arbitratorExtraData) {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public override onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(_disputeID,_ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) virtual internal;
}

/** @title Arbitrator
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
abstract contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes calldata _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }

    modifier requireAppealFee(uint _disputeID, bytes calldata _extraData) {
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
    function createDispute(uint _choices, bytes calldata _extraData) public requireArbitrationFee(_extraData) payable returns(uint disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) public view virtual returns(uint fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint _disputeID, bytes calldata _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint _disputeID, bytes calldata _extraData) public view virtual returns(uint fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint _disputeID) public view virtual returns(uint start, uint end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint _disputeID) public view virtual returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint _disputeID) public view virtual returns(uint ruling);
}


contract Recover is IArbitrable {

    // **************************** //
    // *    Contract variables    * //
    // **************************** //

    // Amount of choices to solve the dispute if needed.
    uint8 constant AMOUNT_OF_CHOICES = 2;

    // Enum relative to different periods in the case of a negotiation or dispute.
    enum Status {NoDispute, WaitingFinder, WaitingOwner, DisputeCreated, Resolved}
    // The different parties of the dispute.
    enum Party {Owner, Finder}
    // The different ruling for the dispute resolution.
    enum RulingOptions {NoRuling, OwnerWins, FinderWins}

    struct Item {
        address owner; // Owner of the item.
        uint rewardAmount; // Amount of the reward in ETH.
        address addressForEncryption; // Address used to encrypt the link of description and to make a claim.
        string descriptionEncryptedLink; // Description encrypted link to chat/find the owner of the item (ex: IPFS URL with the encrypted description).
        uint[] claimIDs; // Collection of the claim to give back the item and get the reward.
        uint timeoutLocked; // Timeout after which the finder can call the function `executePayment`.
        uint ownerFee; // Total fees paid by the owner of the item.
        bool exists; // Boolean to check if the item exists or not in the collection.
    }

    struct Owner {
        string description; // (optionnal) Public description of the owner (ENS, Twitter, Telegram...)
        bytes32[] itemIDs; // Owner collection of the items.
    }

    struct Claim {
        bytes32 itemID; // Relation one-to-one with the item.
        address finder; // Address of the item finder.
        string descriptionLink; // Public link description to proof we found the item (ex: IPFS URL with the content).
        uint amountLocked; // Amount locked while a claim is accepted.
        uint lastInteraction; // Last interaction for the dispute procedure.
        uint finderFee; // Total fees paid by the finder.
        uint disputeID; // If dispute exists, the ID of the claim.
        bool isAccepted; // True if the claim is accepted.
        Status status; // Status of the claim relative to a dispute.
    }

    mapping(address => Owner) public owners; // Collection of the owners.

    mapping(bytes32 => Item) public items; // Collection of the items.

    mapping(uint => uint) public disputeIDtoClaimAcceptedID; // One-to-one relationship between the dispute and the claim accepted.

    Claim[] public claims; // Collection of the claims.
    Arbitrator public arbitrator; // Address of the arbitrator contract.
    bytes public arbitratorExtraData; // Extra data to set up the arbitration.
    uint public feeTimeout; // Time in seconds a party can take to pay arbitration fees before being considered unresponding and lose the dispute.

    // **************************** //
    // *          Events          * //
    // **************************** //

    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as losing.
     *  @param _claimID The index of the claim.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(uint indexed _claimID, Party _party);
    
    /** @dev To be emitted when a party pays or reimburses the other.
     *  @param _claimID The index of the claim.
     *  @param _party The party that paid.
     *  @param _amount The amount paid.
     */
    event Fund(uint indexed _claimID, Party _party, uint _amount);

    /** @dev To be emitted when the finder claims an item.
     *  @param _itemID The index of the item.
     *  @param _finder The address of the finder.
     *  @param _claimID The index of the claim.
     */
    event ItemClaimed(bytes32 indexed _itemID, address indexed _finder, uint _claimID);

    // **************************** //
    // *    Contract functions    * //
    // *    Modifying the state   * //
    // **************************** //

    /** @dev Constructor.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _feeTimeout Arbitration fee timeout for the parties.
     */
    constructor (
        Arbitrator _arbitrator,
        bytes memory _arbitratorExtraData,
        uint _feeTimeout
    ) {
        arbitrator = Arbitrator(_arbitrator);
        arbitratorExtraData = _arbitratorExtraData;
        feeTimeout = _feeTimeout;

        claims.push(Claim({  // To avoid to have a claim with 0 as index.
            itemID: 0, // The index of the item.
            finder: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // The finder of the item.
            descriptionLink: '',  // The claim description.
            amountLocked: 0, // Amount locked is 0. This variable is setting when there an accepting claim.
            lastInteraction: 0, // The last ineraction in the dispute flow.
            finderFee: 0, // The arbitration fee paid by the finder.
            disputeID: 0, // The index of the dispute if any.
            isAccepted: false, // True is the claim is accepted.
            status: Status.NoDispute // Status of the dispute.
        }));
    }

    /** @dev Add item.
     *  @param _itemID The index of the item.
     *  @param _addressForEncryption Link to the meta-evidence.
     *  @param _descriptionEncryptedLink Time after which a party can automatically execute the arbitrable transaction.
     *  @param _rewardAmount The recipient of the transaction.
     *  @param _timeoutLocked Timeout after which the finder can call the function `executePayment`.
     */
    function addItem(
        bytes32 _itemID,
        address payable _addressForEncryption,
        string memory _descriptionEncryptedLink,
        uint _rewardAmount,
        uint _timeoutLocked
    ) public payable {
        require(items[_itemID].exists == false, "The id must be not registered.");

        // Add the item in the collection.
        items[_itemID] = Item({
            owner: msg.sender, // The owner of the item.
            rewardAmount: _rewardAmount, // The reward to find the item.
            addressForEncryption: _addressForEncryption, // Address used to encrypt the link descritpion.
            descriptionEncryptedLink: _descriptionEncryptedLink, // Description encrypted link to chat/find the owner of the item.
            claimIDs: new uint[](0), // Empty array. There is no claims at this moment.
            timeoutLocked: _timeoutLocked, // If the a claim is accepted, time while the amount is locked.
            ownerFee: 0, // Arbitration fee is 0.
            exists: true // The item exists now.
        });

        // Add the item in the owner item collection.
        owners[msg.sender].itemIDs.push(_itemID);
        
        _addressForEncryption.transfer(msg.value); // Prefund the finder address to ba able to claim without ETH.

        // Store the encrypted link in the meta-evidence.
        emit MetaEvidence(uint(_itemID), _descriptionEncryptedLink);
    }

    /** @dev Change the general contact fallback information.
     *  @param _description The contact information.
     */
    function changeDescription(string memory _description) public {
        owners[msg.sender].description = _description;
    }

    /** @dev Change the address used to encrypt the description link and the description.
     *  @param _itemID The index of the item.
     *  @param _addressForEncryption Time after which a party can automatically execute the arbitrable transaction.
     *  @param _descriptionEncryptedLink The recipient of the transaction.
     */
    function changeAddressAndDescriptionEncrypted(
        bytes32 _itemID,
        address _addressForEncryption,
        string memory _descriptionEncryptedLink
    ) public {
        Item storage item = items[_itemID];

        require(msg.sender == item.owner, "Must be the owner of the item.");

        item.addressForEncryption = _addressForEncryption;
        item.descriptionEncryptedLink = _descriptionEncryptedLink;
    }

    /** @dev Change the reward amount of the item.
     *  @param _itemID The index of the item.
     *  @param _rewardAmount The amount of the reward for the item.
     */
    function changeRewardAmount(bytes32 _itemID, uint _rewardAmount) public {
        Item storage item = items[_itemID];

        require(msg.sender == item.owner, "Must be the owner of the item.");

        item.rewardAmount = _rewardAmount;
    }

    /** @dev Change the reward amount of the item.
     *  @param _itemID The index of the item.
     *  @param _timeoutLocked Timeout after which the finder can call the function `executePayment`.
     */
    function changeTimeoutLocked(bytes32 _itemID, uint _timeoutLocked) public {
        Item storage item = items[_itemID];

        require(msg.sender == item.owner, "Must be the owner of the item.");
        require(item.timeoutLocked < _timeoutLocked, "Must be higher than the actual locked time.");

        item.timeoutLocked = _timeoutLocked;
    }

    /** @dev Claim an item.
     *  @param _itemID The index of the item.
     *  @param _finder The address of the finder.
     *  @param _descriptionLink The link to the description of the item (optionnal).
     */
    function claim (
        bytes32 _itemID,
        address payable _finder,
        string memory _descriptionLink
    ) public {
        Item storage item = items[_itemID];

        require(
            msg.sender == item.addressForEncryption,
            "Must be the same sender of the transaction than the address used to encrypt the message."
        );

        claims.push(Claim({
            itemID: _itemID, // The index of the item.
            finder: _finder, // The finder of the item.
            descriptionLink: _descriptionLink,  // The claim description.
            amountLocked: 0, // Amount locked is 0. This variable is setting when there an accepting claim.
            lastInteraction: block.timestamp, // The last ineraction in the dispute flow.
            finderFee: 0, // The arbitration fee paid by the finder.
            disputeID: 0, // The index of the dispute if any.
            isAccepted: false, // True is the claim is accepted.
            status: Status.NoDispute // Status of the dispute.
        }));

        uint claimID = claims.length - 1;
        item.claimIDs.push(claimID); // Adds the claim in the collection of the claim ids for this item.

        emit ItemClaimed(_itemID, _finder, claimID);
    }

    /** @dev Accept a claim an item.
     *  @param _claimID The index of the claim.
     */
    function acceptClaim(uint _claimID) payable public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(item.owner == msg.sender, "The sender of the transaction must be the owner of the item.");
        require(item.rewardAmount <= msg.value, "The ETH amount must be equal or higher than the reward");

        itemClaim.amountLocked += msg.value; // Locked the fund in this contract.
        itemClaim.isAccepted = true; // Set the claim as accepted.
    }

    /** @dev Pay finder. To be called if the item has been returned.
     *  @param _claimID The index of the claim.
     *  @param _amount Amount to pay in wei.
     */
    function pay(uint _claimID, uint _amount) payable public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(item.owner == msg.sender, "The caller must be the owner of the item.");
        require(itemClaim.status == Status.NoDispute, "The transaction of the item can't be disputed.");
        require(
            _amount <= itemClaim.amountLocked,
            "The amount paid has to be less than or equal to the amount locked."
        );
        
        address payable finder = payable(itemClaim.finder);

        finder.transfer(_amount); // Transfer the fund to the finder.
        itemClaim.amountLocked -= _amount; // The value sent is subtracted from the locked funds.
        
        emit Fund(_claimID, Party.Owner, _amount);
    }

    /** @dev Reimburse owner of the item. To be called if the item can't be fully returned.
     *  @param _claimID The index of the claim.
     *  @param _amountReimbursed Amount to reimburse in wei.
     */
    function reimburse(uint _claimID, uint _amountReimbursed) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(itemClaim.finder == msg.sender, "The caller must be the finder of the item.");
        require(itemClaim.status == Status.NoDispute, "The transaction item can't be disputed.");
        require(
            _amountReimbursed <= itemClaim.amountLocked,
            "The amount paid has to be less than or equal to the amount locked."
        );
        
        address payable owner = payable(item.owner);

        owner.transfer(_amountReimbursed); // Transfer the fund to the owner.

        itemClaim.amountLocked -= _amountReimbursed; // The value reimbursed is subtracted from the locked funds.
        
        emit Fund(_claimID, Party.Finder, _amountReimbursed);
    }

    /** @dev Transfer the transaction's amount to the finder if the timeout has passed.
     *  @param _claimID The index of the claim.
     */
    function executeTransaction(uint _claimID) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(block.timestamp - itemClaim.lastInteraction >= item.timeoutLocked, "The timeout has not passed yet.");
        require(itemClaim.status == Status.NoDispute, "The transaction of the claim item can't be disputed.");
        
        address payable finder = payable(itemClaim.finder);

        finder.transfer(itemClaim.amountLocked);

        itemClaim.amountLocked = 0;
        itemClaim.status = Status.Resolved;
        
        emit Fund(_claimID, Party.Owner, itemClaim.amountLocked);
    }


    /* Section of Negociation or Dispute Resolution */

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the owner. UNTRUSTED.
     *  Note that the arbitrator can have createDispute throw,
     *  which will make this function throw and therefore lead to a party being timed-out.
     *  This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     *  @param _claimID The index of the claim.
     */
    function payArbitrationFeeByOwner(uint _claimID) public payable {
        Claim storage itemClaim = claims[_claimID];
         Item storage item = items[itemClaim.itemID];

        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(
            itemClaim.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction of the item has been executed."
        );
        require(item.owner == msg.sender, "The caller must be the owner of the item.");
        require(true == itemClaim.isAccepted, "The claim of the item must be accepted.");

        item.ownerFee += msg.value;
        // Require that the total paid to be at least the arbitration cost.
        require(item.ownerFee >= arbitrationCost, "The owner fee must cover arbitration costs.");

        itemClaim.lastInteraction = block.timestamp;

        // The finder still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (itemClaim.finderFee < arbitrationCost) {
            itemClaim.status = Status.WaitingFinder;
            emit HasToPayFee(_claimID, Party.Finder);
        } else { // The finder has also paid the fee. We create the dispute
            raiseDispute(_claimID, arbitrationCost);
        }
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the finder. UNTRUSTED.
     *  Note that this function mirrors payArbitrationFeeByFinder.
     *  @param _claimID The index of the claim.
     */
    function payArbitrationFeeByFinder(uint _claimID) public payable {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(
            itemClaim.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction has been executed."
        );
        require(itemClaim.finder == msg.sender, "The caller must be the sender.");
        require(true == itemClaim.isAccepted, "The claim of the item must be accepted.");

        itemClaim.finderFee += msg.value;
        // Require that the total pay at least the arbitration cost.
        require(itemClaim.finderFee >= arbitrationCost, "The finder fee must cover arbitration costs.");

        itemClaim.lastInteraction = block.timestamp;

        // The owner still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (item.ownerFee < arbitrationCost) {
            itemClaim.status = Status.WaitingOwner;
            emit HasToPayFee(_claimID, Party.Owner);
        } else { // The owner has also paid the fee. We create the dispute
            raiseDispute(_claimID, arbitrationCost);
        }
    }

    /** @dev Reimburse owner of the item if the finder fails to pay the fee.
     *  @param _claimID The index of the claim.
     */
    function timeOutByOwner(uint _claimID) public {
        Claim storage itemClaim = claims[_claimID];

        require(
            itemClaim.status == Status.WaitingFinder,
            "The transaction of the item must waiting on the finder."
        );
        require(block.timestamp - itemClaim.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");

        if (itemClaim.finderFee != 0) {
            address payable finder = payable(itemClaim.finder);

            finder.send(itemClaim.finderFee);
            itemClaim.finderFee = 0;
        }

        executeRuling(_claimID, uint(RulingOptions.OwnerWins));
    }

    /** @dev Pay finder if the owner of the item fails to pay the fee.
     *  @param _claimID The index of the claim.
     */
    function timeOutByFinder(uint _claimID) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(
            itemClaim.status == Status.WaitingOwner,
            "The transaction of the item must waiting on the owner of the item."
        );
        require(block.timestamp - itemClaim.lastInteraction >= feeTimeout, "Timeout time has not passed yet.");

        if (item.ownerFee != 0) {
            address payable owner = payable(item.owner);

            owner.send(item.ownerFee);
            item.ownerFee = 0;
        }

        executeRuling(_claimID, uint(RulingOptions.FinderWins));
    }

    /** @dev Create a dispute. UNTRUSTED.
     *  @param _claimID The index of the claim.
     *  @param _arbitrationCost Amount to pay the arbitrator.
     */
    function raiseDispute(uint _claimID, uint _arbitrationCost) internal {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        itemClaim.status = Status.DisputeCreated;
        uint disputeID = arbitrator.createDispute{value: _arbitrationCost}(AMOUNT_OF_CHOICES, arbitratorExtraData);
        disputeIDtoClaimAcceptedID[disputeID] = _claimID;
        itemClaim.disputeID = disputeID;
        emit Dispute(arbitrator, itemClaim.disputeID, _claimID, _claimID);

        // Refund finder if it overpaid.
        if (itemClaim.finderFee > _arbitrationCost) {
            uint extraFeeFinder = itemClaim.finderFee - _arbitrationCost;
            itemClaim.finderFee = _arbitrationCost;

            address payable finder = payable(itemClaim.finder);

            finder.send(extraFeeFinder);
        }

        // Refund owner if it overpaid.
        if (item.ownerFee > _arbitrationCost) {
            uint extraFeeOwner = item.ownerFee - _arbitrationCost;
            item.ownerFee = _arbitrationCost;

            address payable owner = payable(item.owner);

            owner.send(extraFeeOwner);
        }
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _claimID The index of the claim.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(uint _claimID, string memory _evidence) public {
        Claim storage itemClaim = claims[_claimID];
        Item storage item = items[itemClaim.itemID];

        require(
            msg.sender == item.owner || msg.sender == itemClaim.finder,
            "The caller must be the owner of the item or the finder."
        );

        require(itemClaim.status >= Status.DisputeCreated, "The dispute has not been created yet.");
        emit Evidence(arbitrator, _claimID, msg.sender, _evidence);
    }

    /** @dev Appeal an appealable ruling.
     *  Transfer the funds to the arbitrator.
     *  Note that no checks are required as the checks are done by the arbitrator.
     *  @param _claimID The index of the claim.
     */
    function appeal(uint _claimID) public payable {
        Claim storage itemClaim = claims[_claimID];

        require(
            msg.sender == items[itemClaim.itemID].owner || msg.sender == itemClaim.finder,
            "The caller must be the owner of the item or the finder."
        );

        arbitrator.appeal{value: msg.value}(itemClaim.disputeID, arbitratorExtraData);
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) override external {
        require(msg.sender == address(arbitrator), "The sender of the transaction must be the arbitrator.");

        Claim storage itemClaim = claims[disputeIDtoClaimAcceptedID[_disputeID]]; // Get the claim by the dispute id.

        require(Status.DisputeCreated == itemClaim.status, "The dispute has already been resolved.");

        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(disputeIDtoClaimAcceptedID[_disputeID], _ruling);
    }

    /** @dev Execute a ruling of a dispute. It reimburses the fee to the winning party.
     *  @param _claimID The index of the claim.
     *  @param _ruling Ruling given by the arbitrator. 1 : Reimburse the owner of the item. 2 : Pay the finder.
     */
    function executeRuling(uint _claimID, uint _ruling) internal {
        require(_ruling <= AMOUNT_OF_CHOICES, "Invalid ruling.");
        Claim storage itemClaim = claims[disputeIDtoClaimAcceptedID[_claimID]];
        Item storage item = items[itemClaim.itemID];

        address payable owner = payable(item.owner);
        address payable finder = payable(itemClaim.finder);

        // Give the arbitration fee back.
        // Note that we use send to prevent a party from blocking the execution.
        if (_ruling == uint(RulingOptions.OwnerWins)) {
            owner.send(item.ownerFee + itemClaim.amountLocked);
        } else if (_ruling == uint(RulingOptions.FinderWins)) {
            finder.send(itemClaim.finderFee + itemClaim.amountLocked);
        } else {
            uint split_amount = (item.ownerFee + itemClaim.amountLocked) / 2;
            owner.send(split_amount);
            finder.send(split_amount);
        }

        itemClaim.amountLocked = 0;
        item.ownerFee = 0;
        itemClaim.finderFee = 0;
        itemClaim.status = Status.Resolved;
    }

    // **************************** //
    // *     View functions       * //
    // **************************** //

    /** @dev Get the existence of an item.
     *  @param _itemID The index of the item.
     *  @return True if the item exists else false.
     */
    function isItemExist(bytes32 _itemID) public view returns (bool) {
        return items[_itemID].exists;
    }
    
    /** @dev Get IDs for items where the specified address is the owner.
     *  @param _owner The specified address.
     *  @return itemIDs The items IDs.
     */
    function getItemIDsByOwner(address _owner) public view returns (bytes32[] memory) {
        return owners[_owner].itemIDs;
    }

    /** @dev Get claims of an item.
     *  @param _itemID The index of the item.
     *  @return The claim IDs.
     */
    function getClaimsByItemID(bytes32 _itemID) public view returns(uint[] memory) {
       return items[_itemID].claimIDs;
    }

    /** @dev Get IDs for claims where the specified address is the finder.
     *  Note that the complexity is O(c), where c is the number of claims.
     *  @param _finder The specified address.
     *  @return claimIDs The claim IDs.
     */
    function getClaimIDsByAddress(address _finder) public view returns (uint[] memory claimIDs) {
        uint count = 0;
        for (uint i = 0; i < claims.length; i++) {
            if (claims[i].finder == _finder)
                count++;
        }

        claimIDs = new uint[](count);

        count = 0;

        for (uint j = 0; j < claims.length; j++) {
            if (claims[j].finder == _finder)
                claimIDs[count++] = j;
        }
    }
}