/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: []
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.9;


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


pragma solidity ^0.8.0;


/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

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


contract SimpleEscrow is IArbitrable {
    address payable public payer = payable(msg.sender);
    address payable public payee;
    uint256 public value;
    IArbitrator public arbitrator;
    string public agreement;
    uint256 public createdAt;
    uint256 public constant reclamationPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.
    uint256 public constant arbitrationFeeDepositPeriod = 3 minutes; // Timeframe is short on purpose to be able to test it quickly. Not for production use.

    error InvalidStatus();
    error ReleasedTooEarly();
    error NotPayer();
    error NotArbitrator();
    error PayeeDepositStillPending();
    error ReclaimedTooLate();
    error InsufficientPayment(uint256 _available, uint256 _required);
    error InvalidRuling(uint256 _ruling, uint256 _numberOfChoices);

    enum Status {
        Initial,
        Reclaimed,
        Disputed,
        Resolved
    }
    Status public status;

    uint256 public reclaimedAt;

    enum RulingOptions {
        RefusedToArbitrate,
        PayerWins,
        PayeeWins
    }
    uint256 constant numberOfRulingOptions = 2; // Notice that option 0 is reserved for RefusedToArbitrate.

    constructor(
        address payable _payee,
        IArbitrator _arbitrator,
        string memory _agreement
    ) payable {
        value = msg.value;
        payee = _payee;
        arbitrator = _arbitrator;
        agreement = _agreement;
        createdAt = block.timestamp;
    }

    function releaseFunds() public {
        if (status != Status.Initial) {
            revert InvalidStatus();
        }

        if (msg.sender != payer && block.timestamp - createdAt <= reclamationPeriod) {
            revert ReleasedTooEarly();
        }

        status = Status.Resolved;
        payee.send(value);
    }

    function reclaimFunds() public payable {
        if (status != Status.Initial && status != Status.Reclaimed) {
            revert InvalidStatus();
        }

        if (msg.sender != payer) {
            revert NotPayer();
        }

        if (status == Status.Reclaimed) {
            if (block.timestamp - reclaimedAt <= arbitrationFeeDepositPeriod) {
                revert PayeeDepositStillPending();
            }
            payer.send(address(this).balance);
            status = Status.Resolved;
        } else {
            if (block.timestamp - createdAt > reclamationPeriod) {
                revert ReclaimedTooLate();
            }
            uint256 requiredAmount = arbitrator.arbitrationCost("");
            if (msg.value < requiredAmount) {
                revert InsufficientPayment(msg.value, requiredAmount);
            }
            reclaimedAt = block.timestamp;
            status = Status.Reclaimed;
        }
    }

    function depositArbitrationFeeForPayee() public payable {
        if (status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        arbitrator.createDispute{value: msg.value}(numberOfRulingOptions, "");
        status = Status.Disputed;
    }

    function rule(uint256 _disputeID, uint256 _ruling) public override {
        if (msg.sender != address(arbitrator)) {
            revert NotArbitrator();
        }
        if (status != Status.Disputed) {
            revert InvalidStatus();
        }
        if (_ruling > numberOfRulingOptions) {
            revert InvalidRuling(_ruling, numberOfRulingOptions);
        }

        status = Status.Resolved;
        if (_ruling == uint256(RulingOptions.PayerWins)) payer.send(address(this).balance);
        else if (_ruling == uint256(RulingOptions.PayeeWins)) payee.send(address(this).balance);
        emit Ruling(arbitrator, _disputeID, _ruling);
    }

    function remainingTimeToReclaim() public view returns (uint256) {
        if (status != Status.Initial) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - createdAt) > reclamationPeriod ? 0 : (createdAt + reclamationPeriod - block.timestamp);
    }

    function remainingTimeToDepositArbitrationFee() public view returns (uint256) {
        if (status != Status.Reclaimed) {
            revert InvalidStatus();
        }
        return
            (block.timestamp - reclaimedAt) > arbitrationFeeDepositPeriod
                ? 0
                : (reclaimedAt + arbitrationFeeDepositPeriod - block.timestamp);
    }
}