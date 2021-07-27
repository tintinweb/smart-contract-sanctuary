// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";
import "./interfaces/IAragonCourt.sol";
import "./interfaces/IDisputeManager.sol";
import "./interfaces/IInsurance.sol";
import "./Utils.sol";
import "./libs/AragonCourtMetadataLib.sol";

contract AragonCourtDisputerV1 is Utils {
    string private constant ERROR_NOT_DISPUTER = "Not a disputer";
    string private constant ERROR_IN_DISPUTE = "In dispute";
    string private constant ERROR_NOT_IN_DISPUTE = "Not in dispute";
    string private constant ERROR_IN_SETTLEMENT = "In disputed settlement";
    string private constant ERROR_NOT_READY = "Not ready for dispute";
    string private constant ERROR_ALREADY_RESOLVED = "Resolution applied";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw";
    string private constant ERROR_NOT_APPROVED = "Not signed";
    string private constant ERROR_DISPUTE_PAY_FAILED = "Failed to pay dispute fee";
    string private constant ERROR_APPEAL_PAY_FAILED = "Failed to pay appeal fee";
    string private constant ERROR_COVERAGE_PAY_FAILED = "Failed to pay insurance fee";

    IRegistry public immutable TRUSTED_REGISTRY;
    IInsurance public immutable INSURANCE_MANAGER;
    IAragonCourt public immutable ARBITER;
    IDisputeManager public immutable DISPUTE_MANAGER;

    uint256 public immutable SETTLEMENT_DELAY;

    uint256 private constant EMPTY_INT = 0;
    uint256 private constant RULE_LEAKED = 1;
    uint256 private constant RULE_IGNORED = 2;
    uint256 private constant RULE_PAYEE_WON = 3;
    uint256 private constant RULE_PAYER_WON = 4;
    bytes2 private constant IPFS_V1_PREFIX = 0x1220;
    bytes32 private constant AC_GREET_PREFIX = 0x4752454554000000000000000000000000000000000000000000000000000000; // GREET
    bytes32 private constant PAYEE_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    bytes32 private constant PAYER_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    string private constant PAYEE_WON = "Release to Payee";
    string private constant PAYER_WON = "Refund to Payer";
    bytes private constant DESCRIPTION = abi.encodePacked(IPFS_V1_PREFIX, bytes32(0xdb54ce611d177d3496a28f8fb4027ced7ed3f392f6152efce6dad11eb9d356a3));

    using AragonCourtMetadataLib for AragonCourtMetadataLib.EnforceableSettlement;

    mapping (bytes32 => uint256) public disputes;
    mapping (bytes32 => uint256) public resolutions;
    mapping (bytes32 => AragonCourtMetadataLib.EnforceableSettlement) public enforceableSettlements;

    event UsedInsurance(
        bytes32 indexed cid,
        uint16 indexed index,
        address indexed feeToken,
        uint256 covered,
        uint256 notCovered
    );

    event SettlementProposed(
        bytes32 indexed cid,
        uint16 indexed index,
        address indexed _plaintiff,
        uint256 _refundedPercent,
        uint256 _releasedPercent,
        uint256 _fillingStartsAt
    );

    event DisputeStarted(
        bytes32 indexed cid,
        uint16 indexed index,
        uint256 did
    );

    event DisputeAppealed(
        bytes32 indexed cid,
        uint16 indexed index,
        uint256 did,
        uint256 disputedRound,
        uint8 suggestedRuling,
        address paymentToken,
        uint256 appealFee
    );

    event DisputeAppealConfirmed(
        bytes32 indexed cid,
        uint16 indexed index,
        uint256 did,
        uint256 disputedRound,
        uint8 suggestedRuling,
        address paymentToken,
        uint256 appealFee
    );

    event DisputeWitnessed(
        bytes32 indexed cid,
        uint16 indexed index,
        address indexed witness,
        bytes evidence
    );

    event DisputeConcluded(
        bytes32 indexed cid,
        uint16 indexed index,
        uint256 indexed rule
    );

    /**
     * @dev Dispute manager for Aragon Court.
     *
     * @param _registry Address of universal registry of all contracts.
     * @param _insuranceManager Address which can register and withdraw insurances.
     * @param _arbiter Address of Aragon Court subjective oracle.
     * @param _disputeManager Address of Aragon Court dispute manager.
     */
    constructor(address _registry, address _insuranceManager, address _arbiter, address _disputeManager, uint256 _settlementDelay) {
        TRUSTED_REGISTRY = IRegistry(_registry);
        INSURANCE_MANAGER = IInsurance(_insuranceManager);
        ARBITER = IAragonCourt(_arbiter);
        DISPUTE_MANAGER = IDisputeManager(_disputeManager);
        SETTLEMENT_DELAY = _settlementDelay;
    }

    /**
     * @dev Checks if milestone has ongoing settlement dispute.
     *
     * @param _mid Milestone uid.
     * @return true if there is ongoing settlement process.
     */
    function hasSettlementDispute(bytes32 _mid) public view returns (bool) {
        return enforceableSettlements[_mid].fillingStartsAt > 0;
    }

    /**
     * @dev Checks if milestone has ongoing settlement dispute.
     *
     * @param _mid Milestone uid.
     * @param _ruling Aragon Court dispute resolution.
     * @return true if there is ongoing settlement process.
     */
    function getSettlementByRuling(bytes32 _mid, uint256 _ruling) public view returns (uint256, uint256, uint256) {
        if (_ruling == RULE_PAYEE_WON) {
            AragonCourtMetadataLib.Claim memory _claim = enforceableSettlements[_mid].payeeClaim;
            return (_ruling, _claim.refundedPercent, _claim.releasedPercent);
        } else if (_ruling == RULE_PAYER_WON) {
            AragonCourtMetadataLib.Claim memory _claim = enforceableSettlements[_mid].payerClaim;
            return (_ruling, _claim.refundedPercent, _claim.releasedPercent);
        } else {
            return (_ruling, 0, 0);
        }
    }

    /**
     * @dev Propose settlement enforceable in court.
     * We automatically fill the best outcome for opponent's proposal,
     * he has 1 week time to propose alternative distribution which he considers fair.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _plaintiff Payer or Payee address who sends settlement for enforcement.
     * @param _payer Payer address.
     * @param _payee Payee address.
     * @param _refundedPercent Amount to refund (in percents).
     * @param _releasedPercent Amount to release (in percents).
     */
    function proposeSettlement(
        bytes32 _cid,
        uint16 _index,
        address _plaintiff,
        address _payer,
        address _payee,
        uint _refundedPercent,
        uint _releasedPercent
    ) external {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);

        bytes32 _mid = _genMid(_cid, _index);
        require(enforceableSettlements[_mid].did == EMPTY_INT && disputes[_mid] == EMPTY_INT, ERROR_IN_DISPUTE);

        AragonCourtMetadataLib.Claim memory _proposal = AragonCourtMetadataLib.Claim({
            refundedPercent: _refundedPercent,
            releasedPercent: _releasedPercent
        });

        uint256 _fillingStartsAt = enforceableSettlements[_mid].fillingStartsAt; 
        if (_plaintiff == _payer) {
            enforceableSettlements[_mid].payerClaim = _proposal;
            if (_fillingStartsAt == 0) {
                _fillingStartsAt = block.timestamp + SETTLEMENT_DELAY;
                enforceableSettlements[_mid].fillingStartsAt = _fillingStartsAt;
                enforceableSettlements[_mid].payeeClaim = AragonCourtMetadataLib.defaultPayeeClaim();
            }
        } else if (_plaintiff == _payee) {
            enforceableSettlements[_mid].payeeClaim = _proposal;
            if (_fillingStartsAt == 0) {
                _fillingStartsAt = block.timestamp + SETTLEMENT_DELAY;
                enforceableSettlements[_mid].fillingStartsAt = _fillingStartsAt;
                enforceableSettlements[_mid].payerClaim = AragonCourtMetadataLib.defaultPayerClaim();
            }
        } else {
            revert();
        }
        emit SettlementProposed(_cid, _index, _plaintiff, _refundedPercent, _releasedPercent, _fillingStartsAt);
    }

    /**
     * @dev Send collected proposals for settlement to Aragon Court as arbiter.
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _termsCid Latest approved contract's IPFS cid.
     * @param _ignoreCoverage Don't try to use insurance.
     */
    function disputeSettlement(
        address _feePayer,
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        bool _ignoreCoverage
    ) external returns (uint256) {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);

        bytes32 _mid = _genMid(_cid, _index);
        require(enforceableSettlements[_mid].did == EMPTY_INT && disputes[_mid] == EMPTY_INT, ERROR_IN_DISPUTE);
        require(enforceableSettlements[_mid].fillingStartsAt < block.timestamp, ERROR_NOT_READY);

        _payDisputeFees(_feePayer, _cid, _index, _ignoreCoverage);

        AragonCourtMetadataLib.EnforceableSettlement memory _enforceableSettlement = enforceableSettlements[_mid];
        bytes memory _metadata = _enforceableSettlement.generatePayload(_termsCid, _feePayer, _index, true);
        uint256 _did = ARBITER.createDispute(2, _metadata);
        disputes[_mid] = _did;
        enforceableSettlements[_mid].did = _did;
        emit DisputeStarted(_cid, _index, _did);
        return _did;
    }

    /**
     * @dev Execute settlement favored by Aragon Court as arbiter.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _mid Milestone key.
     * @return Ruling, refundedPercent, releasedPercent
     */
    function executeSettlement(bytes32 _cid, uint16 _index, bytes32 _mid) public returns(uint256, uint256, uint256) {
        uint256 _ruling = ruleDispute(_cid, _index, _mid);
        return getSettlementByRuling(_mid, _ruling);
    }

    /**
     * @dev Initiate a dispute for a milestone and plead to Aragon Court as arbiter.
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _termsCid Specific terms version guardians will review, can be the same as _cid
     * @param _ignoreCoverage Don't try to use insurance
     */
    function dispute(
        address _feePayer,
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        bool _ignoreCoverage
    ) public {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);

        bytes32 _mid = _genMid(_cid, _index);
        require(disputes[_mid] == EMPTY_INT && enforceableSettlements[_mid].did == EMPTY_INT, ERROR_IN_DISPUTE);

        _payDisputeFees(_feePayer, _cid, _index, _ignoreCoverage);

        bytes memory _metadata = AragonCourtMetadataLib.generateDefaultPayload(_termsCid, _feePayer, _index, true);
        uint256 _did = ARBITER.createDispute(2, _metadata);
        disputes[_mid] = _did;
        emit DisputeStarted(_cid, _index, _did);
    }

    /**
     * @dev Submit evidence to help dispute resolution.
     *
     * @param _from Address which submits evidence.
     * @param _label Label for address.
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Additonal evidence which should help to resolve the dispute.
     */
    function submitEvidence(address _from, string memory _label, bytes32 _cid, uint16 _index, bytes calldata _evidence) external {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);
        ARBITER.submitEvidence(_did, _from, abi.encode(_evidence, _label));
        emit DisputeWitnessed(_cid, _index, _from, _evidence);
    }

    /**
     * @dev Apply Aragon Court descision to milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _mid Milestone key.
     * @return ruling of Aragon Court.
     */
    function ruleDispute(bytes32 _cid, uint16 _index, bytes32 _mid) public returns(uint256) {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        uint256 _resolved = resolutions[_mid];
        if (_resolved != EMPTY_INT && _resolved != RULE_IGNORED && _resolved != RULE_LEAKED) return _resolved;

        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT || enforceableSettlements[_mid].did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        (, uint256 _ruling) = ARBITER.rule(_did);
        resolutions[_mid] = _ruling;
        if (_ruling == RULE_IGNORED || _ruling == RULE_LEAKED) {
            // Allow to send the same case again
            delete disputes[_mid];
            delete enforceableSettlements[_mid].did;
        } else {
            if (_ruling != RULE_PAYER_WON && _ruling != RULE_PAYEE_WON) revert();
        }
        
        emit DisputeConcluded(_cid, _index, _ruling);
        return _ruling;
    }

    /**
     * @dev Charge standard fees for dispute
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _ignoreCoverage Don't try to use insurance
     */
    function _payDisputeFees(address _feePayer, bytes32 _cid, uint16 _index, bool _ignoreCoverage) private {
        (address _recipient, IERC20 _feeToken, uint256 _feeAmount) = ARBITER.getDisputeFees();
        if (!_ignoreCoverage) {
            (uint256 _notCovered, uint256 _covered) = INSURANCE_MANAGER.getCoverage(_cid, address(_feeToken), _feeAmount);
            if (_notCovered > 0) require(_feeToken.transferFrom(_feePayer, address(INSURANCE_MANAGER), _notCovered), ERROR_DISPUTE_PAY_FAILED);
            if (_covered > 0) require(INSURANCE_MANAGER.useCoverage(_cid, address(_feeToken), _feeAmount));
            emit UsedInsurance(_cid, _index, address(_feeToken), _covered, _notCovered);
        } else {
            require(_feeToken.transferFrom(_feePayer, address(this), _feeAmount), ERROR_DISPUTE_PAY_FAILED);
        }
        require(_feeToken.approve(_recipient, _feeAmount), ERROR_DISPUTE_PAY_FAILED);
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

library AragonCourtMetadataLib {
    bytes2 private constant IPFS_V1_PREFIX = 0x1220;
    bytes32 private constant AC_GREET_PREFIX = 0x4752454554000000000000000000000000000000000000000000000000000000; // GREET
    bytes32 private constant PAYEE_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    bytes32 private constant PAYER_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    string private constant PAYER_BUTTON = "Payer";
    string private constant PAYEE_BUTTON = "Payee";
    string private constant PAYEE_SETTLEMENT = " % released to Payee";
    string private constant PAYER_SETTLEMENT = " % refunded to Payer";
    string private constant SEPARATOR = ", ";
    string private constant NEW_LINE = "\n";
    string private constant DESC_PREFIX = "Should the escrow funds associated with ";
    string private constant DESC_SUFFIX = "the contract be distributed according to the claim of Payer or Payee?";
    string private constant DESC_MILESTONE_PREFIX = "(Milestone ";
    string private constant DESC_MILESTONE_SUFFIX = " of) ";
    string private constant PAYER_CLAIM_PREFIX = "Payer claim: ";
    string private constant PAYEE_CLAIM_PREFIX = "Payee claim: ";

    struct Claim {
        uint refundedPercent;
        uint releasedPercent;
    }

    struct EnforceableSettlement {
        Claim payerClaim;
        Claim payeeClaim;
        uint256 fillingStartsAt;
        uint256 did;
        uint256 ruling;
    }

    /**
     * @dev ABI encoded payload for Aragon Court dispute metadata, with a default 0,100 and 100,0 claims.
     *
     * @param _termsCid Latest approved version of IPFS cid for contract in dispute.
     * @param  _plaintiff Address of disputer.
     * @param _index Milestone index to dispute.
     * @param _multi Does contract has many milestones?
     * @return description text
     */
    function generateDefaultPayload(
        bytes32 _termsCid,
        address _plaintiff,
        uint16 _index,
        bool _multi
    ) internal pure returns (bytes memory) {
        return abi.encode(
            AC_GREET_PREFIX,
            toIpfsCid(_termsCid),
            _plaintiff,
            PAYER_BUTTON,
            PAYER_BUTTON_COLOR,
            PAYEE_BUTTON,
            PAYER_BUTTON_COLOR,
            textForDescription(_index, _multi, defaultPayeeClaim(), defaultPayerClaim())
        );
    }

    /**
     * @dev ABI encoded payload for Aragon Court dispute metadata.
     *
     * @param _enforceableSettlement EnforceableSettlement suggested by both parties.
     * @param _termsCid Latest approved version of IPFS cid for contract in dispute.
     * @param  _plaintiff Address of disputer.
     * @param _index Milestone index to dispute.
     * @param _multi Does contract has many milestones?
     * @return description text
     */
    function generatePayload(
        EnforceableSettlement memory _enforceableSettlement,
        bytes32 _termsCid,
        address _plaintiff,
        uint16 _index,
        bool _multi
    ) internal pure returns (bytes memory) {
        bytes memory _desc = textForDescription(
            _index,
            _multi,
            _enforceableSettlement.payeeClaim,
            _enforceableSettlement.payerClaim
        );
        
        return abi.encode(
            AC_GREET_PREFIX,
            toIpfsCid(_termsCid),
            _plaintiff,
            PAYER_BUTTON,
            PAYER_BUTTON_COLOR,
            PAYEE_BUTTON,
            PAYER_BUTTON_COLOR,
            _desc
        );
    }

    /**
     * @dev By default Payee asks for a full release of escrow funds.
     *
     * @return structured claim.
     */
    function defaultPayeeClaim() internal pure returns (Claim memory) {
        return Claim({
            refundedPercent: 0,
            releasedPercent: 100
        });
    }

    /**
     * @dev By default Payer asks for a full refund of escrow funds.
     *
     * @return structured claim.
     */
    function defaultPayerClaim() internal pure returns (Claim memory) {
        return Claim({
            refundedPercent: 100,
            releasedPercent: 0
        });
    }

    /**
     * @dev Adds prefix to produce compliant hex encoded IPFS cid.
     *
     * @param _chunkedCid Bytes32 chunked cid version.
     * @return full IPFS cid
     */
    function toIpfsCid(bytes32 _chunkedCid) internal pure returns (bytes memory) {
        return abi.encodePacked(IPFS_V1_PREFIX, _chunkedCid);
    }

    /**
     * @dev Produces different texts based on milestone to be disputed.
     * e.g. "Should the funds in the escrow associated with (Milestone X of)
     * the contract be released/refunded according to Payer or Payee's claim?" or
     * "Should the funds in the escrow associated with the contract ..."  in case
     * of single milestone.
     *
     * @param _index Milestone index to dispute.
     * @param _multi Does contract has many milestones?
     * @param _payeeClaim Suggested claim from Payee.
     * @param _payerClaim Suggested claim from Payer.
     * @return description text
     */
    function textForDescription(
        uint256 _index,
        bool _multi,
        Claim memory _payeeClaim,
        Claim memory _payerClaim
    ) internal pure returns (bytes memory) {
        bytes memory _claims = abi.encodePacked(
            NEW_LINE,
            NEW_LINE,
            PAYER_CLAIM_PREFIX,
            textForClaim(_payerClaim.refundedPercent, _payerClaim.releasedPercent),
            NEW_LINE,
            NEW_LINE,
            PAYEE_CLAIM_PREFIX,
            textForClaim(_payeeClaim.refundedPercent, _payeeClaim.releasedPercent)
        );

        if (_multi) {
            return abi.encodePacked(
                DESC_PREFIX,
                DESC_MILESTONE_PREFIX,
                uint2str(_index),
                DESC_MILESTONE_SUFFIX,
                DESC_SUFFIX,
                _claims
            );
        } else {
            return abi.encodePacked(
                DESC_PREFIX,
                DESC_SUFFIX,
                _claims
            );
        }
    }

    /**
     * @dev Produces different texts for buttons in context of refunded and released percents.
     * e.g. "90 % released to Payee, 10 % refunded to Payer" or "100 % released to Payee" etc
     *
     * @param _refundedPercent Percent to refund 0-100.
     * @param _releasedPercent Percent to release 0-100.
     * @return button text
     */
    function textForClaim(uint256 _refundedPercent, uint256 _releasedPercent) internal pure returns (string memory) {
        if (_refundedPercent == 0) {
            return string(abi.encodePacked(uint2str(_releasedPercent), PAYEE_SETTLEMENT));
        } else if (_releasedPercent == 0) {
            return string(abi.encodePacked(uint2str(_refundedPercent), PAYER_SETTLEMENT));
        } else {
            return string(abi.encodePacked(
                uint2str(_releasedPercent),
                PAYEE_SETTLEMENT,
                SEPARATOR,
                uint2str(_refundedPercent),
                PAYER_SETTLEMENT
            ));
        }
    }

    /**
     * @dev oraclizeAPI function to convert uint256 to memory string.
     *
     * @param _i Number to convert.
     * @return number in string encoding.
     */
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        
        unchecked {
            while (_i != 0) {
                bstr[k--] = bytes1(uint8(48 + _i % 10));
                _i /= 10;
            }
        }
        return string(bstr);
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