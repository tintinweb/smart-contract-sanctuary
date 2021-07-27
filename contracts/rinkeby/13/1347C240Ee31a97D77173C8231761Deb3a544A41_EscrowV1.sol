// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./extensions/EscrowContract.sol";
import "./extensions/WithPreSignedMilestones.sol";
import "./extensions/AmendablePreSigned.sol";
import "./interfaces/IAragonCourt.sol";
import "./interfaces/IDisputeManager.sol";
import "./interfaces/IInsurance.sol";
import "./interfaces/IEscrowDisputeManager.sol";

contract EscrowV1 is EscrowContract, AmendablePreSigned, WithPreSignedMilestones {
    string private constant ERROR_NOT_DISPUTER = "Not a disputer";
    string private constant ERROR_IN_DISPUTE = "In dispute";
    string private constant ERROR_NOT_IN_DISPUTE = "Not in dispute";
    string private constant ERROR_ALREADY_RESOLVED = "Resolution applied";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw";
    string private constant ERROR_NOT_APPROVED = "Not signed";
    string private constant ERROR_INVALID_SETTLEMENT = "100% required";
    string private constant ERROR_DISPUTE_PARENT = "Dispute parent";
    string private constant ERROR_PARENT_UNRULED = "Rule parent";

    uint256 private constant RULE_PAYEE_WON = 3;
    uint256 private constant RULE_PAYER_WON = 4;

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);

    struct MilestoneParams {
        address paymentToken;
        address treasury;
        address payeeAccount;
        address refundAccount;
        address escrowDisputeManager;
        uint autoReleasedAt;
        uint amount;
        uint16 parentIndex;
    }

    /**
     * @dev Can only be a contract party, either payer (or his delegate) or payee.
     *
     * @param _cid Contract's IPFS cid.
     */
    modifier isDisputer(bytes32 _cid) {
        require(
            msg.sender == contracts[_cid].payeeDelegate 
            || msg.sender == contracts[_cid].payerDelegate
            || msg.sender == contracts[_cid].payee 
            || msg.sender == contracts[_cid].payer, ERROR_NOT_DISPUTER
        );
        _;
    }

    /**
     * @dev Version of Escrow which uses Aragon Court dispute interfaces.
     *
     * @param _registry Address of universal registry of all contracts.
     */
    constructor(address _registry) EscrowContract(_registry) {
    }

    /**
     * @dev Prepare contract between parties, with initial milestones.
     * Initial milestone term cid, will be the same as contract cid.
     *
     * @param _cid Contract's IPFS cid.
     * @param _payer Party which pays for the contract or on behalf of which the funding was done.
     * @param _payerDelegate Delegate who can release or dispute contract on behalf of payer.
     * @param _payee Party which recieves the payment.
     * @param _payeeDelegate Delegate who can refund or dispute contract on behalf of payee.
     * @param _milestones Delivery amounts and payment tokens.
     */
    function registerContract(
        bytes32 _cid,
        address _payer,
        address _payerDelegate,
        address _payee,
        address _payeeDelegate,
        MilestoneParams[] calldata _milestones
    ) external {
        _registerContract(_cid, _payer, _payerDelegate, _payee, _payeeDelegate);

        bytes32 _mid;
        MilestoneParams calldata _mp;
        uint16 _index;
        uint16 _oldIndex;
        uint16 _subIndex = 1;
        for (uint16 _i=0; _i<_milestones.length; _i++) {
            _mp = _milestones[_i];
            if (_mp.parentIndex > 0) {
                _oldIndex = _index;
                _index = _mp.parentIndex * MILESTONE_INDEX_BASE + _subIndex;
                _subIndex += 1;
            } else {
                _index += 1;
            }

            _mid = _genMid(_cid, _index);
            _registerMilestoneStorage(
                _mid,
                _mp.paymentToken,
                _mp.treasury,
                _mp.payeeAccount,
                _mp.refundAccount,
                _mp.escrowDisputeManager,
                _mp.autoReleasedAt,
                _mp.amount
            );
            emit NewMilestone(_cid, _index, _mid, _mp.paymentToken, _mp.escrowDisputeManager, _mp.autoReleasedAt, _mp.amount);
            if (_mp.parentIndex > 0) {
                emit ChildMilestone(_cid, _index, _mp.parentIndex, _mid);
                _index = _oldIndex;
            }
        }
        lastMilestoneIndex = _index;
    }

    /**
     * @dev Add new milestone for the existing contract with amendment to contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (100 max, higher than 100 are child milestones, calculated by the following formula: parent index * 100 + index of child).
     * @param _paymentToken Payment token for amount.
     * @param _treasury Address where the escrow funds will be stored (farming?).
     * @param _payeeAccount Address where payment should be recieved, should be the same as payee or vesting contract address.
     * @param _refundAccount Address where payment should be refunded, should be the same as payer or sponsor.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Amount to be paid in payment token for the milestone.
     * @param _amendmentCid Should be the same as _cid if no change in contract terms are needed.
     */
    function registerMilestone(
        bytes32 _cid,
        uint16 _index,
        address _paymentToken,
        address _treasury,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint _autoReleasedAt,
        uint _amount,
        bytes32 _amendmentCid
    ) external {
        _registerMilestone(
            _cid,
            _index,
            _paymentToken,
            _treasury,
            _payeeAccount,
            _refundAccount,
            _escrowDisputeManager,
            _autoReleasedAt,
            _amount
        );

        // One amendment can cover terms for several milestones
        if (_cid != _amendmentCid && _amendmentCid != EMPTY_BYTES32 && _amendmentCid != getLatestApprovedContractVersion(_cid)) {
            _proposeAmendment(_cid, _amendmentCid, contracts[_cid].payer, contracts[_cid].payee);
        }

        if (_index < MILESTONE_INDEX_BASE) lastMilestoneIndex = _index;
    }

    /**
     * @dev Fund milestone with payment token, partial funding is possible.
     * To increase the maximum funding amount, just add a new milestone.
     *
     * Anyone can fund milestone, payment token should be approved for this contract.
     *
     * Keep in mind that specific milestone terms can be not the final contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amountToFund amount of payment token to fund the milestone.
     */
    function fundMilestone(bytes32 _cid, uint16 _index, uint _amountToFund) external {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(getLatestApprovedContractVersion(_cid) != EMPTY_BYTES32, ERROR_NOT_APPROVED);
        _fundMilestone(_cid, _mid, _m, _amountToFund);
    }

    /**
     * @dev If payee has signed contract off-chain, allow funding with payee signature as a proof
     * that he has agreed the terms.
     *
     * If contract is not approved by both parties, approve the signed terms cid.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _termsCid Contract IPFS cid signed by payee.
     * @param _amountToFund Amount to fund.
     * @param _payeeSignature Signed digest of terms cid by payee.
     * @param _payerSignature Signed digest of terms cid by payer, can be bytes32(0) if caller is payer.
     */
    function signAndFundMilestone(
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        uint _amountToFund,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) external {
        _signAndFundMilestone(_cid, _index, _termsCid, _amountToFund, _payeeSignature, _payerSignature);

        if (contractVersions[_cid].cid == EMPTY_BYTES32) {
            bytes32 _key = genTermsKey(_cid, _termsCid);
            _approveAmendment(_cid, _termsCid, _key);
        }
    }

    /**
     * @dev Same as signAndProposeContractVersion amendment, but pre-approved with signature of non-sender party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid New version of contract's IPFS cid.
     * @param _payeeSignature Signed digest of amendment cid by payee, can be bytes(0) if payee is msg.sender.
     * @param _payerSignature Signed digest of amendment cid by payer, can be bytes(0) if payer is msg.sender.
     */
    function preApprovedAmendment(
        bytes32 _cid,
        bytes32 _amendmentCid,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) external {
        address _payee = contracts[_cid].payee;
        require(msg.sender == _payee || isPreApprovedAmendment(_cid, _amendmentCid, _payee, _payeeSignature), ERROR_NOT_DISPUTER);
        address _payer = contracts[_cid].payer;
        require(msg.sender == _payer || isPreApprovedAmendment(_cid, _amendmentCid, _payer, _payerSignature), ERROR_NOT_DISPUTER);
        
        bytes32 _key = genTermsKey(_cid, _amendmentCid);
        _approveAmendment(_cid, _amendmentCid, _key);
    }

    /**
     * @dev Initiate a dispute for a milestone and plead to Aragon Court as arbiter.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _ignoreCoverage Don't try to use insurance
     */
    function dispute(bytes32 _cid, uint16 _index, bool _ignoreCoverage) external isDisputer(_cid) {
        require(_index < MILESTONE_INDEX_BASE, ERROR_DISPUTE_PARENT);
        bytes32 _termsCid = getLatestApprovedContractVersion(_cid);
        bytes32 _mid = _genMid(_cid, _index);
        milestones[_mid].escrowDisputeManager.dispute(msg.sender, _cid, _index, _termsCid, _ignoreCoverage);
    }

    /**
     * @dev Submit evidence to help dispute resolution.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Additonal evidence which should help to resolve the dispute.
     */
    function submitEvidence(bytes32 _cid, uint16 _index, bytes calldata _evidence) external {
        Contract memory _c = contracts[_cid];
        string memory _label;
        if (msg.sender == _c.payeeDelegate || msg.sender == _c.payee) {
            _label = "Evidence (Payee)";
        } else if (msg.sender == _c.payerDelegate || msg.sender == _c.payer) {
            _label = "Evidence (Payer)";
        } else {
            revert(ERROR_NOT_DISPUTER);
        }

        bytes32 _mid = _genMid(_cid, _index);
        milestones[_mid].escrowDisputeManager.submitEvidence(msg.sender, _label, _cid, _index, _evidence);
    }

    /**
     * @dev Apply Aragon Court decision to milestone.
     *
     * Can be called by anyone, as ruling is static.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone in dispute.
     */
    function resolveDispute(bytes32 _cid, uint16 _index) external {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        uint _available = _m.fundedAmount - _m.claimedAmount;
        require(_available > 0, ERROR_NO_MONEY);

        IEscrowDisputeManager disputer = _m.escrowDisputeManager;
        uint256 _ruling = disputer.ruleDispute(_cid, _index, _mid);
        if (_ruling == RULE_PAYER_WON) {
            emit CanceledMilestone(_mid, disputer.ARBITER(), _available);
            delete milestones[_mid].releasedAmount;
            delete milestones[_mid].refundedAmount;
            uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.refundAccount, _available);
            emit RefundedMilestone(_mid, _m.refundAccount, _withdrawn); 
        } else if (_ruling == RULE_PAYEE_WON) {
            emit ReleasedMilestone(_mid, disputer.ARBITER(), _available);
            delete milestones[_mid].releasedAmount;
            delete milestones[_mid].refundedAmount;
            uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.payeeAccount, _available);
            emit WithdrawnMilestone(_mid, _m.payeeAccount, _withdrawn); 
        }
    }

    /**
     * @dev Initiate a disputed settlement for a milestone and plead to Aragon Court as arbiter.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _refundedPercent Amount to refund (in percents).
     * @param _releasedPercent Amount to release (in percents).
     */
    function proposeSettlement(
        bytes32 _cid,
        uint16 _index,
        uint256 _refundedPercent,
        uint256 _releasedPercent
    ) external {
        require(_index < MILESTONE_INDEX_BASE, ERROR_DISPUTE_PARENT);
        require(_refundedPercent + _releasedPercent == 100, ERROR_INVALID_SETTLEMENT);

        Contract memory _c = contracts[_cid];
        address _plaintiff;
        if (msg.sender == _c.payeeDelegate || msg.sender == _c.payee) {
            _plaintiff = _c.payee;
        } else if (msg.sender == _c.payerDelegate || msg.sender == _c.payer) {
            _plaintiff = _c.payer;
        } else {
            revert(ERROR_NOT_DISPUTER);
        }
        
        bytes32 _mid = _genMid(_cid, _index);
        milestones[_mid].escrowDisputeManager.proposeSettlement(
            _cid,
            _index,
            _plaintiff,
            _c.payer,
            _c.payee,
            _refundedPercent,
            _releasedPercent
        );
    }

    /**
     * @dev When settlement proposals are gathered, send final proposals to arbiter for resolution.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _ignoreCoverage Don't try to use insurance
     */
    function disputeSettlement(
        bytes32 _cid,
        uint16 _index,
        bool _ignoreCoverage
    ) external isDisputer(_cid) {
        bytes32 _termsCid = getLatestApprovedContractVersion(_cid);
        bytes32 _mid = _genMid(_cid, _index);
        milestones[_mid].escrowDisputeManager.disputeSettlement(msg.sender, _cid, _index, _termsCid, _ignoreCoverage);
    }

    /**
     * @dev Apply Aragon Court decision to milestone.
     *
     * Can be called by anyone, as ruling is static.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone in dispute.
     */
    function executeSettlement(bytes32 _cid, uint16 _index) external {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        uint _available = _m.fundedAmount - _m.claimedAmount;
        require(_available > 0, ERROR_NO_MONEY);

        if (_index > MILESTONE_INDEX_BASE) {
            uint16 _parentIndex = _index / MILESTONE_INDEX_BASE; // Integer division will floor the result
            bytes32 _parentMid = _genMid(_cid, _parentIndex);
            IEscrowDisputeManager disputer = milestones[_parentMid].escrowDisputeManager;
            uint256 _ruling = disputer.resolutions(_parentMid);
            (, uint256 _refundedPercent, uint256 _releasedPercent) = disputer.getSettlementByRuling(_parentMid, _ruling);

            require(_refundedPercent + _releasedPercent == 100, ERROR_PARENT_UNRULED);
            if (_ruling == RULE_PAYER_WON || _ruling == RULE_PAYEE_WON) {
                distributeByProportion(_cid, _mid, disputer.ARBITER(), _available, _refundedPercent, _releasedPercent, _m);
            }
        } else {
            IEscrowDisputeManager disputer = _m.escrowDisputeManager;
            (uint256 _ruling, uint256 _refundedPercent, uint256 _releasedPercent) = disputer.executeSettlement(_cid, _index, _mid);

            if (_ruling == RULE_PAYER_WON || _ruling == RULE_PAYEE_WON) {
                distributeByProportion(_cid, _mid, disputer.ARBITER(), _available, _refundedPercent, _releasedPercent, _m);
            }
        }
    }

    /**
     * @dev Distribute escrow funds for milestone according to supplied proportion in percents.
     *
     * Can be called by anyone, as ruling is static.
     *
     * @param _cid Contract's IPFS cid.
     * @param _mid Milestone uid.
     * @param _arbiter Address of arbiter, who did distribution.
     * @param _available Total amount of funds available for distribution.
     * @param _refundedPercent Amount to refund (in percents).
     * @param _releasedPercent Amount to release (in percents).
     * @param _m Distributed milestone memory structure.
     */
    function distributeByProportion(
        bytes32 _cid,
        bytes32 _mid,
        address _arbiter,
        uint256 _available,
        uint256 _refundedPercent,
        uint256 _releasedPercent,
        Milestone memory _m
    ) internal {
        delete milestones[_mid].releasedAmount;
        delete milestones[_mid].refundedAmount;

        uint256 _refundedAmount = _available / 100 * _refundedPercent;
        uint256 _releasedAmount = _available / 100 * _releasedPercent;

        if (_refundedAmount > 0) {
            emit CanceledMilestone(_mid, _arbiter, _refundedAmount);
            uint _withdrawnToPayer = _withdrawMilestone(_cid, _mid, _m, _m.refundAccount, _refundedAmount);
            _m.claimedAmount += _withdrawnToPayer;
            _m.refundedAmount = 0;
            emit RefundedMilestone(_mid, _m.refundAccount, _withdrawnToPayer);
        }
        if (_releasedAmount > 0) {
            emit ReleasedMilestone(_mid, _arbiter, _releasedAmount);
            uint _withdrawnToPayee = _withdrawMilestone(_cid, _mid, _m, _m.payeeAccount, _releasedAmount);
            emit WithdrawnMilestone(_mid, _m.payeeAccount, _withdrawnToPayee); 
        }
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

contract Utils {
    /**
     * @dev Generate bytes32 uid for contract's milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @return milestone id (mid).
     */
    function _genMid(bytes32 _cid, uint16 _index) internal pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index));
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

abstract contract ContractContext {
    struct Contract {
        address payer;
        address payerDelegate;
        address payee;
        address payeeDelegate;
    }

    mapping (bytes32 => Contract) public contracts;

    event ApprovedContractVersion(
        bytes32 indexed cid,
        bytes32 indexed approvedCid,
        bytes32 indexed key
    );
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "../interfaces/IEscrowDisputeManager.sol";

abstract contract MilestoneContext is Utils {
    struct Milestone {
        IERC20 paymentToken;
        address treasury;
        address payeeAccount;
        address refundAccount;
        IEscrowDisputeManager escrowDisputeManager;
        uint256 autoReleasedAt;
        uint256 amount;
        uint256 fundedAmount;
        uint256 refundedAmount;
        uint256 releasedAmount;
        uint256 claimedAmount;
        uint8 revision;
    }

    mapping (bytes32 => Milestone) public milestones;
    uint16 public lastMilestoneIndex;

    event NewMilestone(
        bytes32 indexed cid,
        uint16 indexed index,
        bytes32 mid,
        address indexed paymentToken,
        address escrowDisputeManager,
        uint256 autoReleasedAt,
        uint256 amount
    );

    event ChildMilestone(
        bytes32 indexed cid,
        uint16 indexed index,
        uint16 indexed parentIndex,
        bytes32 mid
    );

    event FundedMilestone(
        bytes32 indexed mid,
        address indexed funder,
        uint256 indexed amount
    );

    event ReleasedMilestone(
        bytes32 indexed mid,
        address indexed releaser,
        uint256 indexed amount
    );

    event CanceledMilestone(
        bytes32 indexed mid,
        address indexed releaser,
        uint256 indexed amount
    );

    event WithdrawnMilestone(
        bytes32 indexed mid,
        address indexed recipient,
        uint256 indexed amount
    );

    event RefundedMilestone(
        bytes32 indexed mid,
        address indexed recipient,
        uint256 indexed amount
    );
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../contexts/ContractContext.sol";
import "../contexts/MilestoneContext.sol";
import "../interfaces/IEscrowDisputeManager.sol";

abstract contract Amendable is ContractContext, MilestoneContext {
    string private constant ERROR_TERM_NOT_APPROVED = "Approve terms first";
    string private constant ERROR_NOT_PARTY = "Not a payer or payee";
    string private constant ERROR_EMPTY = "Empty amendment";
    string private constant ERROR_AMENDMENT_EXIST = "Amendment exist";
    string private constant ERROR_SETTLEMENT_NOT_EXIST = "Settlement doesn't exist";
    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_EARLIER_AMENDMENT = "Not final amendment";
    string private constant ERROR_OVERFUNDED = "Refund / release overfunded amount";

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);
    address private constant EMPTY_ADDRESS = address(0);

    struct Amendment{
        bytes32 cid;
        uint256 timestamp;
    }

    struct AmendmentProposal {
        bytes32 termsCid;
        address validator;
        uint256 timestamp;
    }

    struct SettlementParams {
        bytes32 termsCid;
        address payeeAccount;
        address refundAccount;
        address escrowDisputeManager;
        uint autoReleasedAt;
        uint amount;
        uint refundedAmount;
        uint releasedAmount;
    }

    struct SettlementProposal {
        bytes32 termsCid;
        address payeeAccount;
        address refundAccount;
        address escrowDisputeManager;
        uint autoReleasedAt;
        uint amount;
        uint refundedAmount;
        uint releasedAmount;
        address validator;
        uint256 timestamp;
    }

    mapping (bytes32 => Amendment) public contractVersions;
    mapping (bytes32 => bool) public contractVersionApprovals;
    mapping (bytes32 => AmendmentProposal) public contractVersionProposals;
    mapping (bytes32 => SettlementProposal) public settlementProposals;

    event NewContractVersion(
        bytes32 indexed cid,
        bytes32 indexed amendmentCid,
        address indexed validator,
        bytes32 key
    );

    event NewSettlement(
        bytes32 indexed cid,
        uint16 indexed index,
        uint8 revision,
        address indexed validator,
        bytes32 key,
        SettlementParams data
    );

    event ApprovedSettlement(
        bytes32 indexed cid,
        uint16 indexed index,
        uint8 revision,
        bytes32 indexed key,
        address validator
    );

    /**
     * @dev Return IPFS cid of a latest approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @return IPFS cid in hex form for a final approved version of a contract or
     * bytes32(0) if no version was approved by both parties.
     */
    function getLatestApprovedContractVersion(bytes32 _cid) public view returns (bytes32) {
        return contractVersions[_cid].cid;
    }

    /**
     * @dev Check if specific contract version was approved by both parties.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid cid of suggested contract version.
     * @return approval by both parties.
     */
    function isApprovedContractVersion(bytes32 _cid, bytes32 _termsCid) public view returns (bool) {
        bytes32 _key = genTermsKey(_cid, _termsCid);
        return contractVersionApprovals[_key];
    }

    /**
     * @dev Generate unique terms key in scope of a contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid cid of suggested contract version.
     * @return unique storage key for amendment.
     */
    function genTermsKey(bytes32 _cid, bytes32 _termsCid) public pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _termsCid));
    }

    /**
     * @dev Generate unique settlement key in scope of a contract milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone index.
     * @param _revision Current version of milestone extended terms.
     * @return unique storage key for amendment.
     */
    function genSettlementKey(bytes32 _cid, uint16 _index, uint8 _revision) public pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index, _revision));
    }

    /**
     * @dev Propose change for the current contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid New version of contract's IPFS cid.
     */
    function signAndProposeContractVersion(bytes32 _cid, bytes32 _termsCid) external {
        address payer = contracts[_cid].payer;
        address payee = contracts[_cid].payee;
        require(msg.sender == payee || msg.sender == payer, ERROR_NOT_PARTY);
        _proposeAmendment(_cid, _termsCid, payee, payer);
    }

    /**
     * @dev Validate contract version by the opposite party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid Amendment IPFS cid for approval.
     */
    function signAndApproveContractVersion(bytes32 _cid, bytes32 _termsCid) public {
        bytes32 _key = genTermsKey(_cid, _termsCid);
        require(_termsCid != EMPTY_BYTES32, ERROR_EMPTY);
        require(!contractVersionApprovals[_key], ERROR_AMENDMENT_EXIST);
        require(contractVersionProposals[_key].validator == msg.sender, ERROR_NOT_VALIDATOR);
        require(contractVersionProposals[_key].timestamp > contractVersions[_cid].timestamp, ERROR_EARLIER_AMENDMENT);

        _approveAmendment(_cid, contractVersionProposals[_key].termsCid, _key);
        
        // Gas refund
        delete contractVersionProposals[_key];
    }

    /**
     * @dev Propose change to milestone on-chain data.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _termsCid New version of contract's IPFS cid, pass bytes32(0) to leave old terms.
     * @param _payeeAccount Change address for withdrawals, pass address(0) to leave the old one.
     * @param _refundAccount Change address for refunds, pass address(0) to leave the old one.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow, pass address(0) to leave the old one.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Change total size of milestone, may require refund or release.
     * @param _refundedAmount Amount to refund, should't be more than current fundedAmount - claimedAmount - releasedAmount.
     * @param _releasedAmount Amount to release, should't be more than current fundedAmount - claimedAmount - refundedAmount.
     */
    function signAndProposeMilestoneSettlement(
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint _autoReleasedAt,
        uint _amount,
        uint _refundedAmount,
        uint _releasedAmount
    ) external returns (bytes32) {
        address payer = contracts[_cid].payer;
        address payee = contracts[_cid].payee;
        require(msg.sender == payee || msg.sender == payer, ERROR_NOT_PARTY);

        SettlementParams memory _sp = SettlementParams({
            termsCid: _termsCid,
            payeeAccount: _payeeAccount,
            refundAccount: _refundAccount,
            escrowDisputeManager: _escrowDisputeManager,
            autoReleasedAt: _autoReleasedAt,
            amount: _amount,
            refundedAmount: _refundedAmount,
            releasedAmount: _releasedAmount
        });
        
        return _proposeMilestoneSettlement(
            _cid,
            _index,
            _sp,
            payer,
            payee
        );
    }

    /**
     * @dev Save new approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone index.
     * @param _revision Current version of milestone extended terms.
     */
    function signApproveAndExecuteMilestoneSettlement(bytes32 _cid, uint16 _index, uint8 _revision) public {
        bytes32 _key = genSettlementKey(_cid, _index, _revision);
        require(settlementProposals[_key].validator == msg.sender, ERROR_NOT_VALIDATOR);
        _approveAndExecuteMilestoneSettlement(_cid, _index, _revision);
        
        // Gas refund
        delete settlementProposals[_key];
    }

    /**
     * @dev Proposals are saved in a temporary dictionary until they are approved to contractVersions mapping.
     *
     * It's possible to override existing proposal with a same key, for instance to increase timestamp.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid New version of contract's IPFS cid, pass bytes32(0) to leave old terms.
     * @param _party1 Address of first party (e.g. payer).
     * @param _party2 Address of second party (e.g. payee).
     * @return key for amendment.
     */
    function _proposeAmendment(
        bytes32 _cid,
        bytes32 _termsCid,
        address _party1,
        address _party2
    ) internal returns (bytes32) {
        bytes32 _key = genTermsKey(_cid, _termsCid);
        require(_termsCid != EMPTY_BYTES32, ERROR_EMPTY);

        address _validator = _party1;
        if (msg.sender == _party1) _validator = _party2;
        contractVersionProposals[_key] = AmendmentProposal({
            termsCid: _termsCid,
            validator: _validator,
            timestamp: block.timestamp
        });
        emit NewContractVersion(_cid, _termsCid, _validator, _key);
        return _key;
    }

    /**
     * @dev Save new approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid New version of contract's IPFS cid.
     */
    function _approveAmendment(bytes32 _cid, bytes32 _termsCid, bytes32 _key) internal {
        contractVersionApprovals[_key] = true;
        contractVersions[_cid] = Amendment({ cid: _termsCid, timestamp: block.timestamp });
        emit ApprovedContractVersion(_cid, _termsCid, _key);
    }

    /**
     * @dev Proposals are saved in a temporary dictionary until they are approved to contractVersions mapping.
     *
     * It's possible to override unapproved settlement proposal with a new one.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _settlementParams Settlement data, see signAndProposeMilestoneSettlement.
     * @param _party1 Address of first party (e.g. payer).
     * @param _party2 Address of second party (e.g. payee).
     * @return key for settlement.
     */
    function _proposeMilestoneSettlement(
        bytes32 _cid,
        uint16 _index,
        SettlementParams memory _settlementParams,
        address _party1,
        address _party2
    ) internal returns (bytes32) {
        uint8 _revision = milestones[_genMid(_cid, _index)].revision + 1;
        bytes32 _key = genSettlementKey(_cid, _index, _revision);

        address _validator = _party1;
        if (msg.sender == _party1) _validator = _party2;
        settlementProposals[_key] = SettlementProposal({
            termsCid: _settlementParams.termsCid,
            payeeAccount: _settlementParams.payeeAccount,
            refundAccount: _settlementParams.refundAccount,
            escrowDisputeManager: _settlementParams.escrowDisputeManager,
            autoReleasedAt: _settlementParams.autoReleasedAt,
            amount: _settlementParams.amount,
            refundedAmount: _settlementParams.refundedAmount,
            releasedAmount: _settlementParams.releasedAmount,
            validator: _validator,
            timestamp: block.timestamp
        });
        emit NewSettlement(
            _cid,
            _index,
            _revision,
            _validator,
            _key,
            _settlementParams
        );
        return _key;
    }

    /**
     * @dev Save new approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone index.
     * @param _revision Current version of milestone extended terms.
     */
    function _approveAndExecuteMilestoneSettlement(bytes32 _cid, uint16 _index, uint8 _revision) internal {
        bytes32 _key = genSettlementKey(_cid, _index, _revision);
        SettlementProposal memory _sp = settlementProposals[_key];
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_revision > _m.revision, ERROR_EARLIER_AMENDMENT);

        uint _leftAmount = _m.fundedAmount - _m.claimedAmount;
        if (_sp.amount < _leftAmount) {
            uint _overfundedAmount = _leftAmount - _sp.amount;
            require(_sp.refundedAmount + _sp.releasedAmount >= _overfundedAmount, ERROR_OVERFUNDED);
        }
        milestones[_mid].revision += 1;
        milestones[_mid].amount = _sp.amount;

        if (_sp.refundedAmount != _m.refundedAmount) {
            milestones[_mid].refundedAmount = _sp.refundedAmount;
        }
        if (_sp.releasedAmount != _m.releasedAmount) {
            milestones[_mid].releasedAmount = _sp.releasedAmount;
        }

        if (_sp.payeeAccount != EMPTY_ADDRESS) milestones[_mid].payeeAccount = _sp.payeeAccount;
        if (_sp.refundAccount != EMPTY_ADDRESS) milestones[_mid].refundAccount = _sp.refundAccount;
        if (_sp.escrowDisputeManager != EMPTY_ADDRESS) milestones[_mid].escrowDisputeManager = IEscrowDisputeManager(_sp.escrowDisputeManager);
        if (_sp.autoReleasedAt != _m.autoReleasedAt) milestones[_mid].autoReleasedAt = _sp.autoReleasedAt;

        // Maybe approve new milestone terms
        if (_sp.termsCid != EMPTY_BYTES32) {
            require(_sp.timestamp > contractVersions[_cid].timestamp, ERROR_EARLIER_AMENDMENT);
            bytes32 _termsKey = genTermsKey(_cid, _sp.termsCid);
            // Can be double approval, but will override the current contract version
            _approveAmendment(_cid, _sp.termsCid, _termsKey);
        }

        emit ApprovedSettlement(_cid, _index, _revision, _key, msg.sender);
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./Amendable.sol";
import "../libs/EIP712.sol";

abstract contract AmendablePreSigned is Amendable {
    using EIP712 for address;
    
    string private constant ERROR_INVALID_SIGNATURE = "Invalid signature";

    /// @dev Value returned by a call to `_isPreApprovedAmendment` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("_isPreApprovedAmendment(address,bytes)"))
    bytes4 private constant MAGICVALUE = 0xe3f756de;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    bytes32 internal constant AMENDMENT_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 internal constant AMENDMENT_DOMAIN_NAME = keccak256("ApprovedAmendment");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 internal constant AMENDMENT_DOMAIN_VERSION = keccak256("v1");

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// contracts.
    bytes32 public immutable AMENDMENT_DOMAIN_SEPARATOR;

    constructor() {
        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        AMENDMENT_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                AMENDMENT_DOMAIN_TYPE_HASH,
                AMENDMENT_DOMAIN_NAME,
                AMENDMENT_DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getAmendmentDomainSeparator() public virtual view returns(bytes32) {
        return AMENDMENT_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Check if amendment was pre-approved.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid New version of contract's IPFS cid.
     * @param _validator Address of opposite party which approval is needed.
     * @param _signature Digest of amendment cid.
     * @return true or false.
     */
    function isPreApprovedAmendment(
        bytes32 _cid,
        bytes32 _amendmentCid,
        address _validator,
        bytes calldata _signature
    ) internal view returns (bool) {
        bytes32 _currentCid = getLatestApprovedContractVersion(_cid);
        return _isPreApprovedAmendment(
            _cid,
            _currentCid,
            _amendmentCid,
            _validator,
            getAmendmentDomainSeparator(),
            _signature
        ) == MAGICVALUE;
    }

    /**
     * @dev Check if amendment was pre-approved, EIP-712
     *
     * @param _cid Contract's IPFS cid.
     * @param _currentCid Cid of last proposed contract version.
     * @param _amendmentCid New version of contract's IPFS cid.
     * @param _validator Address of opposite party which approval is needed.
     * @param _domain EIP-712 domain.
     * @param _callData Digest of amendment cid.
     * @return 0xe3f756de for success 0x00000000 for failure.
     */
    function _isPreApprovedAmendment(
        bytes32 _cid,
        bytes32 _currentCid,
        bytes32 _amendmentCid,
        address _validator,
        bytes32 _domain,
        bytes calldata _callData
    ) internal pure returns (bytes4) {
        return EIP712._isValidEIP712Signature(
            _validator,
            MAGICVALUE,
            abi.encode(_domain, _cid, _currentCid, _amendmentCid),
            _callData
        );
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../interfaces/IRegistry.sol";
import "../contexts/ContractContext.sol";

abstract contract EscrowContract is ContractContext {
    string private constant ERROR_CONTRACT_EXITS = "Contract exists";
    string private constant ERROR_EMPTY_DELEGATE = "Invalid delegate";

    address private constant EMPTY_ADDRESS = address(0);

    IRegistry public immutable TRUSTED_REGISTRY;

    event NewContractPayer(
        bytes32 indexed cid,
        address indexed payer,
        address indexed delegate
    );

    event NewContractPayee(
        bytes32 indexed cid,
        address indexed payee,
        address indexed delegate
    );

    /**
     * @dev Single registry is used to store contract data from different versions of escrow contracts.
     *
     * @param _registry Address of universal registry of all contracts.
     */
    constructor(address _registry) {
        TRUSTED_REGISTRY = IRegistry(_registry);
    }

    /**
     * @dev Prepare contract between parties.
     *
     * @param _cid Contract's IPFS cid.
     * @param _payer Party which pays for the contract or on behalf of which the funding was done.
     * @param _payerDelegate Delegate who can release or dispute contract on behalf of payer.
     * @param _payee Party which recieves the payment.
     * @param _payeeDelegate Delegate who can refund or dispute contract on behalf of payee.
     */
    function _registerContract(
        bytes32 _cid,
        address _payer,
        address _payerDelegate,
        address _payee,
        address _payeeDelegate
    ) internal {
        require(contracts[_cid].payer == EMPTY_ADDRESS, ERROR_CONTRACT_EXITS);

        if (_payerDelegate == EMPTY_ADDRESS) _payerDelegate = _payer;
        if (_payerDelegate == EMPTY_ADDRESS) _payeeDelegate = _payee;
        contracts[_cid] = Contract({
            payer: _payer,
            payerDelegate: _payerDelegate,
            payee: _payee,
            payeeDelegate: _payeeDelegate
        });
        emit NewContractPayer(_cid, _payer, _payerDelegate);
        emit NewContractPayee(_cid, _payee, _payeeDelegate);

        TRUSTED_REGISTRY.registerNewContract(_cid, _payer, _payee);
    }

    /**
     * @dev Change delegate for one party of a deal.
     * Caller should be either payer or payee.
     *
     * @param _cid Contract's IPFS cid.
     * @param _newDelegate Address for a new delegate.
     */
    function changeDelegate(bytes32 _cid, address _newDelegate) external {
        require(_newDelegate != EMPTY_ADDRESS, ERROR_EMPTY_DELEGATE);
        Contract memory _c = contracts[_cid];
        if (_c.payer == msg.sender) {
            contracts[_cid].payerDelegate = _newDelegate;
        } else if (_c.payee == msg.sender) {
            contracts[_cid].payeeDelegate = _newDelegate;
        } else {
            revert();
        }
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contexts/ContractContext.sol";
import "../contexts/MilestoneContext.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IEscrowDisputeManager.sol";

abstract contract WithMilestones is ContractContext, MilestoneContext {
    string private constant ERROR_MILESTONE_EXITS = "Milestone exists";
    string private constant ERROR_FUNDING = "Funding failed";
    string private constant ERROR_FUNDED = "Funding not needed";
    string private constant ERROR_RELEASED = "Invalid release amount";
    string private constant ERROR_NOT_APPROVED = "Funding not approved";
    string private constant ERROR_NOT_DISPUTER = "Not a party";
    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw";

    uint16 internal constant MILESTONE_INDEX_BASE = 100;

    uint256 private constant EMPTY_INT = 0;
    bytes32 private constant EMPTY_BYTES32 = bytes32(0);
    address private constant EMPTY_ADDRESS = address(0);

    /**
     * @dev As payer or delegater allow payee to claim released amount of payment token.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amountToRelease amount of payment token to release from the milestone.
     */
    function releaseMilestone(bytes32 _cid, uint16 _index, uint _amountToRelease) public {
        Contract memory _c = contracts[_cid];
        require(msg.sender == _c.payerDelegate, ERROR_NOT_VALIDATOR);

        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        uint _releasedAmount = _m.releasedAmount + _amountToRelease;
        // Can pontentially pre-release the full amount before funding, so we check full amount instead of fundedAmount
        require(_amountToRelease > 0 && _m.amount >= _releasedAmount, ERROR_RELEASED);

        _releaseMilestone(_mid, _releasedAmount, _amountToRelease, msg.sender);
    }

    /**
     * @dev As payee allow payer or delegate to claim refunded amount from funded payment token.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amountToRefund amount of payment token to refund from funded milestone.
     */
    function cancelMilestone(bytes32 _cid, uint16 _index, uint _amountToRefund) public {
        Contract memory _c = contracts[_cid];
        require(msg.sender == _c.payeeDelegate, ERROR_NOT_VALIDATOR);

        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_amountToRefund > 0 && _m.fundedAmount >= _m.claimedAmount + _amountToRefund, ERROR_RELEASED);

        // Check gas usage
        uint _refundedAmount = _m.refundedAmount + _amountToRefund;
        _cancelMilestone(_mid, _refundedAmount, _amountToRefund, msg.sender);
    }

    /**
     * @dev Withdraw payment token amount released by payer or arbiter.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * If milestone supports automatic releases by autoReleasedAt,
     * it will allow to withdraw funded amount without explicit release
     * from another party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     */
    function withdrawMilestone(bytes32 _cid, uint16 _index) public {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        milestones[_mid].releasedAmount = 0;

        uint _withdrawn;
        uint _toWithdraw;
        uint _inEscrow = _m.fundedAmount - _m.claimedAmount;
        if (_m.releasedAmount == 0 && _inEscrow > 0 && isAutoReleaseAvailable(_mid, _m.escrowDisputeManager, _m.autoReleasedAt)) {
            _toWithdraw = _inEscrow;
            _releaseMilestone(_mid, _toWithdraw, _toWithdraw, msg.sender);
        } else {
            _toWithdraw = _m.releasedAmount;
        }
        _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.payeeAccount, _toWithdraw);
        emit WithdrawnMilestone(_mid, _m.payeeAccount, _withdrawn); 
    }

    /**
     * @dev Refund payment token amount released by payee or arbiter.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payee.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     */
    function refundMilestone(bytes32 _cid, uint16 _index) public {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        milestones[_mid].refundedAmount = 0;
        uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.refundAccount, _m.refundedAmount);
        emit RefundedMilestone(_mid, _m.refundAccount, _withdrawn); 
    }

    /**
     * @dev Add new milestone for the existing contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @param _paymentToken Payment token for amount.
     * @param _treasury Address where the escrow funds will be stored (farming?).
     * @param _payeeAccount Address where payment should be recieved, should be the same as payee or vesting contract address.
     * @param _refundAccount Address where payment should be refunded, should be the same as payer or sponsor.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Amount to be paid in payment token for the milestone.
     */
    function _registerMilestone(
        bytes32 _cid,
        uint16 _index,
        address _paymentToken,
        address _treasury,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint256 _autoReleasedAt,
        uint256 _amount
    ) internal {
        Contract memory _c = contracts[_cid];
        bool _isPayer = msg.sender == _c.payer;
        require(msg.sender == _c.payee || _isPayer, ERROR_NOT_DISPUTER);

        bytes32 _mid = _genMid(_cid, _index);
        require(milestones[_mid].amount == 0, ERROR_MILESTONE_EXITS);
        _registerMilestoneStorage(
            _mid,
            _paymentToken,
            _treasury,
            _payeeAccount,
            _refundAccount,
            _escrowDisputeManager,
            _autoReleasedAt,
            _amount
        );
        emit NewMilestone(_cid, _index, _mid, _paymentToken, _escrowDisputeManager, _autoReleasedAt, _amount);
        if (_index > MILESTONE_INDEX_BASE) {
            emit ChildMilestone(_cid, _index, _index / MILESTONE_INDEX_BASE, _mid);
        }
    }

    /**
     * @dev Add new milestone for the existing contract.
     *
     * @param _mid UID of contract's milestone.
     * @param _paymentToken Address of ERC20 token to be used as payment currency in this escrow.
     * @param _treasury Address where milestone funds are kept in escrow.
     * @param _payeeAccount Address where payment should be recieved, should be the same as payer or vesting contract address.
     * @param _refundAccount Address where payment should be refunded, should be the same as payer or sponsor.
     * @param _escrowDisputeManager Smart contract which implements disputes for the escrow.
     * @param _autoReleasedAt UNIX timestamp for delivery deadline, pass 0 if none.
     * @param _amount Amount to be paid in payment token for the milestone.
     */
    function _registerMilestoneStorage(
        bytes32 _mid,
        address _paymentToken,
        address _treasury,
        address _payeeAccount,
        address _refundAccount,
        address _escrowDisputeManager,
        uint256 _autoReleasedAt,
        uint256 _amount
    ) internal {
        milestones[_mid] = Milestone({
            paymentToken: IERC20(_paymentToken),
            treasury: _treasury,
            payeeAccount: _payeeAccount,
            escrowDisputeManager: IEscrowDisputeManager(_escrowDisputeManager),
            refundAccount: _refundAccount,
            autoReleasedAt: _autoReleasedAt,
            amount: _amount,
            fundedAmount: 0,
            releasedAmount: 0,
            refundedAmount: 0,
            claimedAmount: 0,
            revision: 0
        });
    }

    /**
     * @dev Fund milestone with payment token, partial funding is possible.
     * To increase the maximum funding amount, just add a new milestone.
     *
     * Anyone can fund milestone, payment token should be approved for this contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _mid UID of contract's milestone.
     * @param _m Milestone structure for the _mid.
     * @param _amountToFund amount of payment token to fund the milestone.
     */
    function _fundMilestone(bytes32 _cid, bytes32 _mid, Milestone memory _m, uint _amountToFund) internal {
        uint _fundedAmount = _m.fundedAmount;
        require(_amountToFund > 0 && _m.amount >= (_fundedAmount + _amountToFund), ERROR_FUNDED);
        require(_m.paymentToken.transferFrom(msg.sender, _m.treasury, _amountToFund), ERROR_FUNDING);
        if (_m.treasury != address(this)) {
            require(ITreasury(_m.treasury).registerClaim(
                _cid,
                _m.refundAccount,
                _m.payeeAccount,
                address(_m.paymentToken),
                _amountToFund
            ), ERROR_FUNDING);
        }
        milestones[_mid].fundedAmount += _amountToFund;
        emit FundedMilestone(_mid, msg.sender, _amountToFund);
    }

    /**
     * @dev Release payment for withdrawal by payee.
     *
     * @param _mid UID of contract's milestone.
     * @param _totalReleased Total amount of released payment token.
     * @param _amountToRelease Amount of payment token to release.
     * @param _releaser Address which released (payer or arbiter).
     */
    function _releaseMilestone(bytes32 _mid, uint _totalReleased, uint _amountToRelease, address _releaser) internal {
        milestones[_mid].releasedAmount = _totalReleased;
        emit ReleasedMilestone(_mid, _releaser, _amountToRelease);
    }

    /**
     * @dev Release payment for refund by payer.
     *
     * @param _mid UID of contract's milestone.
     * @param _totalRefunded Total amount of refunded payment token.
     * @param _amountToRefund Amount of payment token to refund.
     * @param _refunder Address which refunded (payee or arbiter).
     */
    function _cancelMilestone(bytes32 _mid, uint _totalRefunded, uint _amountToRefund, address _refunder) internal {
        milestones[_mid].refundedAmount = _totalRefunded;
        emit CanceledMilestone(_mid, _refunder, _amountToRefund);
    }

    /**
     * @dev Transfer released funds to payee or refund account.
     *
     * Make sure to reduce milestone releasedAmount or refundAmount
     * by _withdrawAmount before calling this low-level method.
     *
     * @param _cid Contract's IPFS cid.
     * @param _mid UID of contract's milestone.
     * @param _m Milestone data.
     * @param _account Address where payment is withdrawn.
     * @param _withdrawAmount Amount of released or refunded payment token.
     * @return withdrawn amount
     */
    function _withdrawMilestone(bytes32 _cid, bytes32 _mid, Milestone memory _m, address _account, uint _withdrawAmount) internal returns(uint) {
        uint _leftAmount = _m.fundedAmount - _m.claimedAmount;
        if (_leftAmount < _withdrawAmount) _withdrawAmount = _leftAmount;
        require(_withdrawAmount > 0, ERROR_NO_MONEY);

        milestones[_mid].claimedAmount = _m.claimedAmount + _withdrawAmount;
        if (_m.treasury == address(this)) {
            require(_m.paymentToken.transfer(_account, _withdrawAmount), ERROR_FUNDING);
        } else {
            require(ITreasury(_m.treasury).requestWithdraw(
                _cid,
                _account,
                address(_m.paymentToken),
                _withdrawAmount
            ), ERROR_FUNDING);
        }
        return _withdrawAmount;
    }

    /**
     * @dev Check if auto release of milestone funds is available
     * and maturity date has been reached.
     *
     * Also checks if there were no active or past disputes for this milestone.
     *
     * @param _mid UID of contract's milestone.
     * @param _escrowDisputeManager Smart contract which manages the disputes.
     * @param _autoReleasedAt UNIX timestamp for maturity date.
     * @return true if funds can be withdrawn.
     */
    function isAutoReleaseAvailable(
        bytes32 _mid,
        IEscrowDisputeManager _escrowDisputeManager,
        uint _autoReleasedAt
    ) public virtual returns (bool) {
        return _autoReleasedAt > 0 && block.timestamp > _autoReleasedAt &&
            !_escrowDisputeManager.hasSettlementDispute(_mid) &&
            _escrowDisputeManager.disputes(_mid) == EMPTY_INT &&
            _escrowDisputeManager.resolutions(_mid) == EMPTY_INT;
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./WithMilestones.sol";
import "../libs/EIP712.sol";

abstract contract WithPreSignedMilestones is WithMilestones {
    using EIP712 for address;

    string private constant ERROR_INVALID_SIGNATURE = "Invalid signature";
    string private constant ERROR_RELEASED = "Invalid release amount";
    string private constant ERROR_INVALID_TERMS = "Invalid terms for milestone";

    /// @dev Value returned by a call to `_isPreApprovedMilestoneRelease` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("_isPreApprovedMilestoneRelease(bytes32,uint16,uint256,address,bytes32,bytes)"))
    bytes4 private constant MAGICVALUE = 0x8a9db909;
    /// bytes4(keccak256("_isSignedContractTerms(bytes32,bytes32,address,bytes32,bytes)"))
    bytes4 private constant SIGNED_CONTRACT_MAGICVALUE = 0xda041b1b;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    /// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 internal constant MILESTONE_DOMAIN_TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev The EIP-712 domain name used for computing the domain separator.
    /// keccak256("ReleasedMilestone");
    bytes32 internal constant MILESTONE_RELEASE_DOMAIN_NAME = 0xf7a7a250652776e79083ebf7548d7f678c46dd027033d24129ec9e00e571ea9b;
    /// keccak256("RefundedMilestone");
    bytes32 internal constant MILESTONE_REFUND_DOMAIN_NAME = 0x5dac513728b4cea6b6904b8f3b5f9c178f0cf83a3ecf4e94ad498e7cc75192ec;
    /// keccak256("SignedContract");
    bytes32 internal constant SIGNED_CONTRACT_DOMAIN_NAME = 0x288d28d1a9a71cba45c3234f023dd66e1f027ac6e031e2d93e302aea3277fb64;

    /// @dev The EIP-712 domain version used for computing the domain separator.
    /// keccak256("v1");
    bytes32 internal constant MILESTONE_RELEASE_DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 internal constant MILESTONE_REFUND_DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;
    bytes32 internal constant SIGNED_CONTRACT_DOMAIN_VERSION = 0x0984d5efd47d99151ae1be065a709e56c602102f24c1abc4008eb3f815a8d217;

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// contracts.
    bytes32 public immutable MILESTONE_RELEASE_DOMAIN_SEPARATOR;
    bytes32 public immutable MILESTONE_REFUND_DOMAIN_SEPARATOR;
    bytes32 public immutable SIGNED_CONTRACT_DOMAIN_SEPARATOR;

    // solhint-ignore-contructors
    constructor() {
        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        MILESTONE_RELEASE_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                MILESTONE_DOMAIN_TYPE_HASH,
                MILESTONE_RELEASE_DOMAIN_NAME,
                MILESTONE_RELEASE_DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );

        MILESTONE_REFUND_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                MILESTONE_DOMAIN_TYPE_HASH,
                MILESTONE_REFUND_DOMAIN_NAME,
                MILESTONE_REFUND_DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );

        SIGNED_CONTRACT_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                MILESTONE_DOMAIN_TYPE_HASH,
                SIGNED_CONTRACT_DOMAIN_NAME,
                SIGNED_CONTRACT_DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getMilestoneReleaseDomainSeparator() public virtual view returns(bytes32) {
        return MILESTONE_RELEASE_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getMilestoneRefundDomainSeparator() public virtual view returns(bytes32) {
        return MILESTONE_REFUND_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getSignedContractDomainSeparator() public virtual view returns(bytes32) {
        return SIGNED_CONTRACT_DOMAIN_SEPARATOR;
    }

    /**
     * @dev Withdraw payment token amount released by payer.
     *
     * Works only for the full milestone amount,
     * partial withdrawals with off-chain signatures are currently not supported.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amount Amount to withdraw.
     * @param _payerDelegateSignature Signed digest for release of amount.
     */
    function withdrawPreApprovedMilestone(bytes32 _cid, uint16 _index, uint _amount, bytes calldata _payerDelegateSignature) public {
        address _payerDelegate = contracts[_cid].payerDelegate;
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_m.amount == _amount, ERROR_RELEASED);
        require(_amount > 0 && _m.fundedAmount >= _m.claimedAmount + _amount, ERROR_RELEASED);
        require(_isPreApprovedMilestoneRelease(
            _cid,
            _index,
            _amount,
            _payerDelegate,
            getMilestoneReleaseDomainSeparator(),
            _payerDelegateSignature
        ) == MAGICVALUE, ERROR_INVALID_SIGNATURE);
        
        _m.releasedAmount += _amount;
        _releaseMilestone(_mid, _m.releasedAmount, _amount, _payerDelegate);

        milestones[_mid].releasedAmount = 0;
        uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.payeeAccount, _m.releasedAmount);
        emit WithdrawnMilestone(_mid, _m.payeeAccount, _withdrawn); 
    }

    /**
     * @dev Withdraw payment token amount refunded by payee.
     *
     * Works only for the full milestone amount,
     * partial withdrawals with off-chain signatures are currently not supported.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amount Amount to refund.
     * @param _payeeDelegateSignature Signed digest for release of amount.
     */
    function refundPreApprovedMilestone(bytes32 _cid, uint16 _index, uint _amount, bytes calldata _payeeDelegateSignature) public {
        address _payeeDelegate = contracts[_cid].payeeDelegate;
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_m.amount == _amount, ERROR_RELEASED);
        require(_amount > 0 && _m.fundedAmount >= _m.claimedAmount + _amount, ERROR_RELEASED);
        require(_isPreApprovedMilestoneRelease(
            _cid,
            _index,
            _amount,
            _payeeDelegate,
            getMilestoneRefundDomainSeparator(),
            _payeeDelegateSignature
        ) == MAGICVALUE, ERROR_INVALID_SIGNATURE);
        
        _m.refundedAmount += _amount;
        _cancelMilestone(_mid, _m.refundedAmount, _amount, _payeeDelegate);

        milestones[_mid].refundedAmount = 0;
        uint _withdrawn = _withdrawMilestone(_cid, _mid, _m, _m.refundAccount, _m.refundedAmount);
        emit RefundedMilestone(_mid, _m.refundAccount, _withdrawn);
    }

    /**
     * @dev If payee has signed contract off-chain, allow funding with payee signature as a proof
     * that he has agreed the terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _termsCid Contract IPFS cid signed by payee.
     * @param _amountToFund Amount to fund.
     * @param _payeeSignature Signed digest of terms cid by payee.
     * @param _payerSignature Signed digest of terms cid by payer, can be bytes32(0) if caller is payer.
     */
    function _signAndFundMilestone(
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        uint _amountToFund,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) internal {
        address _payer = contracts[_cid].payer;
        require(msg.sender == _payer || _isSignedContractTerms(
            _cid,
            _termsCid,
            _payer,
            getSignedContractDomainSeparator(),
            _payerSignature
        ) == SIGNED_CONTRACT_MAGICVALUE, ERROR_INVALID_SIGNATURE);
        require(_isSignedContractTerms(
            _cid,
            _termsCid,
            contracts[_cid].payee,
            getSignedContractDomainSeparator(),
            _payeeSignature
        ) == SIGNED_CONTRACT_MAGICVALUE, ERROR_INVALID_SIGNATURE);

        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        _fundMilestone(_cid, _mid, _m, _amountToFund);
    }

    /**
     * @dev Check if milestone release was pre-approved.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Index of milestone in scope of contract.
     * @param _amount Amount of payment token to release.
     * @param _validator Address of opposite party which approval is needed.
     * @param _domain EIP-712 domain.
     * @param _callData Digest of milestone data.
     * @return MAGICVALUE for success 0x00000000 for failure.
     */
    function _isPreApprovedMilestoneRelease(
        bytes32 _cid,
        uint16 _index,
        uint256 _amount,
        address _validator,
        bytes32 _domain,
        bytes calldata _callData
    ) internal pure returns (bytes4) {
        return EIP712._isValidEIP712Signature(
            _validator,
            MAGICVALUE,
            abi.encode(_domain, _cid, _index, _amount),
            _callData
        );
    }

    /**
     * @dev Check if contract terms were signed by all parties.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid Specific version of contract cid which was signed, can be the same as _cid
     * @param _validator Address of opposite party which approval is needed.
     * @param _domain EIP-712 domain.
     * @param _callData Digest of contract data in scope of milestone.
     * @return SIGNED_CONTRACT_MAGICVALUE for success 0x00000000 for failure.
     */
    function _isSignedContractTerms(
        bytes32 _cid,
        bytes32 _termsCid,
        address _validator,
        bytes32 _domain,
        bytes calldata _callData
    ) internal pure returns (bytes4) {
        return EIP712._isValidEIP712Signature(
            _validator,
            SIGNED_CONTRACT_MAGICVALUE,
            abi.encode(_domain, _cid, _termsCid),
            _callData
        );
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAragonCourt {
    function createDispute(uint256 _possibleRulings, bytes calldata _metadata) external returns (uint256);
    function submitEvidence(uint256 _disputeId, address _submitter, bytes calldata _evidence) external;
    function rule(uint256 _disputeId) external returns (address subject, uint256 ruling);
    function getDisputeFees() external view returns (address recipient, IERC20 feeToken, uint256 feeAmount);
    function closeEvidencePeriod(uint256 _disputeId) external;
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDisputeManager {
    enum DisputeState {
        PreDraft,
        Adjudicating,
        Ruled
    }

    /**
    * @dev Appeal round of a dispute in favor of a certain ruling
    * @param _disputeId Identification number of the dispute being appealed
    * @param _roundId Identification number of the dispute round being appealed
    * @param _ruling Ruling appealing a dispute round in favor of
    */
    function createAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;

    /**
    * @dev Confirm appeal for a round of a dispute in favor of a ruling
    * @param _disputeId Identification number of the dispute confirming an appeal of
    * @param _roundId Identification number of the dispute round confirming an appeal of
    * @param _ruling Ruling being confirmed against a dispute round appeal
    */
    function confirmAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;

    /**
    * @dev Tell information of a certain dispute
    * @param _disputeId Identification number of the dispute being queried
    * @return subject Arbitrable subject being disputed
    * @return possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute
    * @return state Current state of the dispute being queried: pre-draft, adjudicating, or ruled
    * @return finalRuling The winning ruling in case the dispute is finished
    * @return lastRoundId Identification number of the last round created for the dispute
    * @return createTermId Identification number of the term when the dispute was created
    */
    function getDispute(uint256 _disputeId) external view
        returns (address subject, uint8 possibleRulings, DisputeState state, uint8 finalRuling, uint256 lastRoundId, uint64 createTermId);

    /**
    * @dev Tell appeal-related information of a certain adjudication round
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round being queried
    * @return maker Address of the account appealing the given round
    * @return appealedRuling Ruling confirmed by the appealer of the given round
    * @return taker Address of the account confirming the appeal of the given round
    * @return opposedRuling Ruling confirmed by the appeal taker of the given round
    */
    function getAppeal(uint256 _disputeId, uint256 _roundId) external view
        returns (address maker, uint64 appealedRuling, address taker, uint64 opposedRuling);

    /**
    * @dev Tell information related to the next round due to an appeal of a certain round given.
    * @param _disputeId Identification number of the dispute being queried
    * @param _roundId Identification number of the round requesting the appeal details of
    * @return nextRoundStartTerm Term ID from which the next round will start
    * @return nextRoundGuardiansNumber Guardians number for the next round
    * @return newDisputeState New state for the dispute associated to the given round after the appeal
    * @return feeToken ERC20 token used for the next round fees
    * @return totalFees  Total amount of fees for a regular round at the given term
    * @return guardianFees Total amount of fees to be distributed between the winning guardians of the next round
    * @return appealDeposit Amount to be deposit of fees for a regular round at the given term
    * @return confirmAppealDeposit Total amount of fees for a regular round at the given term
    */
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId) external view
        returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundGuardiansNumber,
            DisputeState newDisputeState,
            IERC20 feeToken,
            uint256 totalFees,
            uint256 guardianFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        );
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEscrowDisputeManager {
    function proposeSettlement(
        bytes32 _cid,
        uint16 _index,
        address _plaintiff,
        address _payer,
        address _payee,
        uint _refundedPercent,
        uint _releasedPercent
    ) external;

    function disputeSettlement(address _feePayer, bytes32 _cid, uint16 _index, bytes32 _termsCid, bool _ignoreCoverage) external;
    function executeSettlement(bytes32 _cid, uint16 _index, bytes32 _mid) external returns(uint256, uint256, uint256);
    function getSettlementByRuling(bytes32 _mid, uint256 _ruling) external returns(uint256, uint256, uint256); 

    function dispute(address _feePayer, bytes32 _cid, uint16 _index, bytes32 _termsCid, bool _ignoreCoverage) external;
    function submitEvidence(address _from, string memory _label, bytes32 _cid, uint16 _index, bytes calldata _evidence) external;
    function ruleDispute(bytes32 _cid, uint16 _index, bytes32 _mid) external returns(uint256);
    
    function disputes(bytes32 _mid) external view returns(uint256);
    function resolutions(bytes32 _mid) external view returns(uint256);
    function hasSettlementDispute(bytes32 _mid) external view returns(bool);
    function ARBITER() external view returns(address);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

interface IInsurance {
    function getCoverage(bytes32 _cid, address _token, uint256 _feeAmount) external view returns (uint256, uint256);
    function useCoverage(bytes32 _cid, address _token, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

interface IRegistry {
    function registerNewContract(bytes32 _cid, address _payer, address _payee) external;
    function escrowContracts(address _addr) external returns (bool);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

interface ITreasury {
    function registerClaim(bytes32 _termsCid, address _fromAccount, address _toAccount, address _token, uint _amount) external returns(bool);
    function requestWithdraw(bytes32 _termsCid, address _toAccount, address _token, uint _amount) external returns(bool);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

library EIP712 {
    /**
     * @dev Check if milestone release was pre-approved.
     *
     * @param _validator Address of opposite party which approval is needed.
     * @param _success bytes4 hash of called function, returned as success result.
     * @param _encodedChallenge abi encoded string of variables to proof.
     * @param _signature Digest of challenge.
     * @return _success for success 0x00000000 for failure.
     */
    function _isValidEIP712Signature(
        address _validator,
        bytes4 _success,
        bytes memory _encodedChallenge,
        bytes calldata _signature
    ) internal pure returns (bytes4) {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
        (_v, _r, _s) = abi.decode(_signature, (uint8, bytes32, bytes32));
        bytes32 _hash = keccak256(_encodedChallenge);
        address _signer =
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ),
                _v,
                _r,
                _s
            );

        if (_validator == _signer) {
            return _success;
        } else {
            return bytes4(0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}