// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";
import "./interfaces/IAragonCourt.sol";
import "./interfaces/IInsurance.sol";
import "./libs/AragonCourtMetadataLib.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AragonCourtDisputerV1 {
    using SafeERC20 for IERC20;

    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_NOT_DISPUTER = "Not a disputer";
    string private constant ERROR_IN_DISPUTE = "In dispute";
    string private constant ERROR_NOT_IN_DISPUTE = "Not in dispute";
    string private constant ERROR_NOT_READY = "Not ready for dispute";
    string private constant ERROR_ALREADY_RESOLVED = "Resolution applied";
    string private constant ERROR_INVALID_RULING = "Invalid ruling";

    IRegistry public immutable TRUSTED_REGISTRY;
    IAragonCourt public immutable ARBITER;

    uint256 public immutable SETTLEMENT_DELAY;

    uint256 private constant EMPTY_INT = 0;
    uint256 private constant RULE_LEAKED = 1;
    uint256 private constant RULE_IGNORED = 2;
    uint256 private constant RULE_PAYEE_WON = 3;
    uint256 private constant RULE_PAYER_WON = 4;

    string private constant PAYER_STATEMENT_LABEL = "Statement (Payer)";
    string private constant PAYEE_STATEMENT_LABEL = "Statement (Payee)";

    using AragonCourtMetadataLib for AragonCourtMetadataLib.EnforceableSettlement;

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
        address indexed plaintiff,
        uint256 refundedPercent,
        uint256 releasedPercent,
        uint256 fillingStartsAt,
        bytes32 statement
    );

    event DisputeStarted(
        bytes32 indexed cid,
        uint16 indexed index,
        uint256 did
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
     * @dev Can only be an escrow contract registered in Greet registry.
     */
    modifier isEscrow() {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        _;
    }

    /**
     * @dev Dispute manager for Aragon Court.
     *
     * @param _registry Address of universal registry of all contracts.
     * @param _arbiter Address of Aragon Court subjective oracle.
     * @param _settlementDelay Seconds for second party to customise dispute proposal.
     */
    constructor(address _registry, address _arbiter, uint256 _settlementDelay) {
        TRUSTED_REGISTRY = IRegistry(_registry);
        ARBITER = IAragonCourt(_arbiter);
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
     * @return ruling, refunded percent, released percent.
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
     * @param _statement IPFS cid for statement.
     */
    function proposeSettlement(
        bytes32 _cid,
        uint16 _index,
        address _plaintiff,
        address _payer,
        address _payee,
        uint _refundedPercent,
        uint _releasedPercent,
        bytes32 _statement
    ) external isEscrow {
        bytes32 _mid = _genMid(_cid, _index);
        require(enforceableSettlements[_mid].did == EMPTY_INT, ERROR_IN_DISPUTE);
        uint256 _resolution = resolutions[_mid];
        require(_resolution != RULE_PAYEE_WON && _resolution != RULE_PAYER_WON, ERROR_ALREADY_RESOLVED);

        AragonCourtMetadataLib.Claim memory _proposal = AragonCourtMetadataLib.Claim({
            refundedPercent: _refundedPercent,
            releasedPercent: _releasedPercent,
            statement: _statement
        });

        uint256 _fillingStartsAt = enforceableSettlements[_mid].fillingStartsAt; 
        if (_plaintiff == _payer) {
            enforceableSettlements[_mid].payerClaim = _proposal;
            if (_fillingStartsAt == 0) {
                _fillingStartsAt = block.timestamp + SETTLEMENT_DELAY;
                enforceableSettlements[_mid].fillingStartsAt = _fillingStartsAt;
                enforceableSettlements[_mid].payeeClaim = AragonCourtMetadataLib.defaultPayeeClaim();
                enforceableSettlements[_mid].escrowContract = msg.sender;
            }
        } else if (_plaintiff == _payee) {
            enforceableSettlements[_mid].payeeClaim = _proposal;
            if (_fillingStartsAt == 0) {
                _fillingStartsAt = block.timestamp + SETTLEMENT_DELAY;
                enforceableSettlements[_mid].fillingStartsAt = _fillingStartsAt;
                enforceableSettlements[_mid].payerClaim = AragonCourtMetadataLib.defaultPayerClaim();
                enforceableSettlements[_mid].escrowContract = msg.sender;
            }
        } else {
            revert();
        }
        emit SettlementProposed(_cid, _index, _plaintiff, _refundedPercent, _releasedPercent, _fillingStartsAt, _statement);
    }

    /**
     * @dev Payee accepts Payer settlement without going to Aragon court.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone challenged.
     */
    function acceptSettlement(
        bytes32 _cid,
        uint16 _index,
        uint256 _ruling
    ) external {
        bytes32 _mid = _genMid(_cid, _index);
        require(msg.sender == enforceableSettlements[_mid].escrowContract, ERROR_NOT_VALIDATOR);
        require(_ruling == RULE_PAYER_WON || _ruling == RULE_PAYEE_WON, ERROR_INVALID_RULING);
        resolutions[_mid] = _ruling;
        emit DisputeConcluded(_cid, _index, _ruling);
    }

    /**
     * @dev Send collected proposals for settlement to Aragon Court as arbiter.
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Milestone to amend.
     * @param _termsCid Latest approved contract's IPFS cid.
     * @param _ignoreCoverage Don't try to use insurance.
     * @param _multiMilestone More than one milestone in contract?
     */
    function disputeSettlement(
        address _feePayer,
        bytes32 _cid,
        uint16 _index,
        bytes32 _termsCid,
        bool _ignoreCoverage,
        bool _multiMilestone
    ) external returns (uint256) {
        bytes32 _mid = _genMid(_cid, _index);
        require(msg.sender == enforceableSettlements[_mid].escrowContract, ERROR_NOT_VALIDATOR);
        require(enforceableSettlements[_mid].did == EMPTY_INT, ERROR_IN_DISPUTE);
        uint256 _fillingStartsAt = enforceableSettlements[_mid].fillingStartsAt;
        require(_fillingStartsAt > 0 && _fillingStartsAt < block.timestamp, ERROR_NOT_READY);
        uint256 _resolution = resolutions[_mid];
        require(_resolution != RULE_PAYEE_WON && _resolution != RULE_PAYER_WON, ERROR_ALREADY_RESOLVED);

        _payDisputeFees(_feePayer, _cid, _index, _ignoreCoverage);

        AragonCourtMetadataLib.EnforceableSettlement memory _enforceableSettlement = enforceableSettlements[_mid];
        bytes memory _metadata = _enforceableSettlement.generatePayload(_termsCid, _feePayer, _index, _multiMilestone);
        uint256 _did = ARBITER.createDispute(2, _metadata);
        enforceableSettlements[_mid].did = _did;

        bytes memory _payerStatement = AragonCourtMetadataLib.toIpfsCid(enforceableSettlements[_mid].payerClaim.statement);
        ARBITER.submitEvidence(_did, address(this), abi.encode(_payerStatement, PAYER_STATEMENT_LABEL));

        bytes memory _payeeStatement = AragonCourtMetadataLib.toIpfsCid(enforceableSettlements[_mid].payeeClaim.statement);
        ARBITER.submitEvidence(_did, address(this), abi.encode(_payeeStatement, PAYEE_STATEMENT_LABEL));

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
     * @dev Submit evidence to help dispute resolution.
     *
     * @param _from Address which submits evidence.
     * @param _label Label for address.
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Additonal evidence which should help to resolve the dispute.
     */
    function submitEvidence(address _from, string memory _label, bytes32 _cid, uint16 _index, bytes calldata _evidence) external isEscrow {
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = enforceableSettlements[_mid].did;
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
        uint256 _resolved = resolutions[_mid];
        require(msg.sender == enforceableSettlements[_mid].escrowContract, ERROR_NOT_VALIDATOR);
        if (_resolved != EMPTY_INT && _resolved != RULE_IGNORED && _resolved != RULE_LEAKED) return _resolved;

        uint256 _did = enforceableSettlements[_mid].did;
        require(_did != EMPTY_INT || enforceableSettlements[_mid].did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        (, uint256 _ruling) = ARBITER.rule(_did);
        resolutions[_mid] = _ruling;
        if (_ruling == RULE_IGNORED || _ruling == RULE_LEAKED) {
            // Allow to send the same case again
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
            IInsurance _insuranceManager = IInsurance(TRUSTED_REGISTRY.insuranceManager());
            (uint256 _notCovered, uint256 _covered) = _insuranceManager.getCoverage(_cid, address(_feeToken), _feeAmount);
            if (_notCovered > 0) _feeToken.safeTransferFrom(_feePayer, address(this), _notCovered);
            if (_covered > 0) require(_insuranceManager.useCoverage(_cid, address(_feeToken), _covered));
            emit UsedInsurance(_cid, _index, address(_feeToken), _covered, _notCovered);
        } else {
            _feeToken.safeTransferFrom(_feePayer, address(this), _feeAmount);
        }
        _feeToken.safeApprove(_recipient, _feeAmount);
    }

    /**
     * @dev Generate bytes32 uid for contract's milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @return milestone id (mid).
     */
    function _genMid(bytes32 _cid, uint16 _index) public pure returns(bytes32) {
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

interface IInsurance {
    function getCoverage(bytes32 _cid, address _token, uint256 _feeAmount) external view returns (uint256, uint256);
    function useCoverage(bytes32 _cid, address _token, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

interface IRegistry {
    function registerNewContract(bytes32 _cid, address _payer, address _payee) external;
    function escrowContracts(address _addr) external returns (bool);
    function insuranceManager() external returns (address);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./EscrowUtilsLib.sol";

library AragonCourtMetadataLib {
    bytes2 private constant IPFS_V1_PREFIX = 0x1220;
    bytes32 private constant AC_GREET_PREFIX = 0x4752454554000000000000000000000000000000000000000000000000000000; // GREET
    bytes32 private constant PAYEE_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    bytes32 private constant PAYER_BUTTON_COLOR = 0xffb46d0000000000000000000000000000000000000000000000000000000000; // Orange
    bytes32 private constant DEFAULT_STATEMENT_PAYER = 0xbcdd5c0f6298bb7bc8f9c3f7888d641f4ed56bc64003f5376cbb5069c6a010b6;
    bytes32 private constant DEFAULT_STATEMENT_PAYEE = 0xbcdd5c0f6298bb7bc8f9c3f7888d641f4ed56bc64003f5376cbb5069c6a010b6;
    string private constant PAYER_BUTTON = "Payer";
    string private constant PAYEE_BUTTON = "Payee";
    string private constant PAYEE_SETTLEMENT = " % released to Payee";
    string private constant PAYER_SETTLEMENT = " % refunded to Payer";
    string private constant SEPARATOR = ", ";
    string private constant NEW_LINE = "\n";
    string private constant DESC_PREFIX = "Should the escrow funds associated with ";
    string private constant DESC_SUFFIX = "the contract be distributed according to the claim of Payer or Payee?";
    string private constant DESC_MILESTONE_PREFIX = "Milestone ";
    string private constant DESC_MILESTONE_SUFFIX = " of ";
    string private constant PAYER_CLAIM_PREFIX = "Payer claim: ";
    string private constant PAYEE_CLAIM_PREFIX = "Payee claim: ";

    struct Claim {
        uint refundedPercent;
        uint releasedPercent;
        bytes32 statement;
    }

    struct EnforceableSettlement {
        address escrowContract;
        Claim payerClaim;
        Claim payeeClaim;
        uint256 fillingStartsAt;
        uint256 did;
        uint256 ruling;
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
            releasedPercent: 100,
            statement: DEFAULT_STATEMENT_PAYEE
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
            releasedPercent: 0,
            statement: DEFAULT_STATEMENT_PAYER
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

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

library EscrowUtilsLib {
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
    
    struct Contract {
        address payer;
        address payerDelegate;
        address payee;
        address payeeDelegate;
    }

    /**
     * @dev Generate bytes32 uid for contract's milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @return milestone id (mid).
     */
    function genMid(bytes32 _cid, uint16 _index) internal pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index));
    }

    /**
     * @dev Generate unique terms key in scope of a contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _termsCid cid of suggested contract version.
     * @return unique storage key for amendment.
     */
    function genTermsKey(bytes32 _cid, bytes32 _termsCid) internal pure returns(bytes32) {
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
    function genSettlementKey(bytes32 _cid, uint16 _index, uint8 _revision) internal pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _index, _revision));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1
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