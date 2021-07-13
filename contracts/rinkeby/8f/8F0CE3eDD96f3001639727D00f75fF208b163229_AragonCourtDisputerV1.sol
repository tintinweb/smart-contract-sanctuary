// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";
import "./interfaces/IAragonCourt.sol";
import "./interfaces/IDisputeManager.sol";
import "./interfaces/IInsurance.sol";
import "./Utils.sol";

contract AragonCourtDisputerV1 is Utils {
    string private constant ERROR_NOT_DISPUTER = "Not a disputer";
    string private constant ERROR_IN_DISPUTE = "In dispute";
    string private constant ERROR_NOT_IN_DISPUTE = "Not in dispute";
    string private constant ERROR_ALREADY_RESOLVED = "Resolution applied";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw / refund";
    string private constant ERROR_NOT_APPROVED = "Not signed by another party";
    string private constant ERROR_DISPUTE_PAY_FAILED = "Failed to pay dispute fee";
    string private constant ERROR_APPEAL_PAY_FAILED = "Failed to pay appeal fee";
    string private constant ERROR_COVERAGE_PAY_FAILED = "Failed to pay insurance fee";

    IRegistry public immutable TRUSTED_REGISTRY;
    IInsurance public immutable INSURANCE_MANAGER;
    IAragonCourt public immutable ARBITER;
    IDisputeManager public immutable DISPUTE_MANAGER;

    uint256 private constant EMPTY_INT = 0;
    uint256 private constant RULE_LEAKED = 1;
    uint256 private constant RULE_IGNORED = 2;
    uint256 private constant RULE_PAYEE_WON = 3;
    uint256 private constant RULE_PAYER_WON = 4;
    bytes2 private constant IPFS_V1_PREFIX = 0x1220;

    mapping (bytes32 => uint256) public disputes;
    mapping (bytes32 => uint256) public resolutions;

    event UsedInsurance(
        bytes32 indexed cid,
        uint8 indexed index,
        address indexed feeToken,
        uint256 covered,
        uint256 notCovered
    );

    event DisputeStarted(
        bytes32 indexed cid,
        uint8 indexed index,
        uint256 did
    );

    event DisputeAppealed(
        bytes32 indexed cid,
        uint8 indexed index,
        uint256 did,
        uint256 disputedRound,
        uint8 suggestedRuling,
        address paymentToken,
        uint256 appealFee
    );

    event DisputeAppealConfirmed(
        bytes32 indexed cid,
        uint8 indexed index,
        uint256 did,
        uint256 disputedRound,
        uint8 suggestedRuling,
        address paymentToken,
        uint256 appealFee
    );

    event DisputeWitnessed(
        bytes32 indexed cid,
        uint8 indexed index,
        address indexed witness,
        bytes evidence
    );

    event DisputeConcluded(
        bytes32 indexed cid,
        uint8 indexed index,
        uint256 rule
    );

    /**
     * @dev Dispute manager for Aragon Court.
     *
     * @param _registry Address of universal registry of all contracts.
     * @param _insuranceManager Address which can register and withdraw insurances.
     * @param _arbiter Address of Aragon Court subjective oracle.
     * @param _disputeManager Address of Aragon Court dispute manager.
     */
    constructor(address _registry, address _insuranceManager, address _arbiter, address _disputeManager) {
        TRUSTED_REGISTRY = IRegistry(_registry);
        INSURANCE_MANAGER = IInsurance(_insuranceManager);
        ARBITER = IAragonCourt(_arbiter);
        DISPUTE_MANAGER = IDisputeManager(_disputeManager);
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
        uint8 _index,
        bytes32 _termsCid,
        bool _ignoreCoverage
    ) external {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);

        bytes32 _mid = _genMid(_cid, _index);
        require(disputes[_mid] == EMPTY_INT, ERROR_IN_DISPUTE);

        (address _recipient, IERC20 _feeToken, uint256 _feeAmount) = ARBITER.getDisputeFees();
        uint256 _toPay = _feeAmount;
        if (!_ignoreCoverage) {
            (uint256 _notCovered, uint256 _covered) = INSURANCE_MANAGER.getCoverage(_cid, address(_feeToken), _feeAmount);
            if (_covered > 0) require(INSURANCE_MANAGER.useCoverage(_cid, address(_feeToken), _feeAmount));
            _toPay = _notCovered;
            emit UsedInsurance(_cid, _index, address(_feeToken), _covered, _notCovered);
        }
        if (_toPay > 0) require(_feeToken.transferFrom(_feePayer, address(this), _feeAmount), ERROR_DISPUTE_PAY_FAILED);
        require(_feeToken.approve(_recipient, _feeAmount), ERROR_DISPUTE_PAY_FAILED);

        uint256 _did = ARBITER.createDispute(2, abi.encodePacked(_termsCid));
        disputes[_mid] = _did;
        emit DisputeStarted(_cid, _index, _did);

        bytes memory _evidence = abi.encodePacked(IPFS_V1_PREFIX, _termsCid);
        ARBITER.submitEvidence(_did, _feePayer, _evidence);
        emit DisputeWitnessed(_cid, _index, _feePayer, _evidence);
    }

    /**
     * @dev Submit evidence to help dispute resolution.
     *
     * @param _from Addross which submits evidence.
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Additonal evidence which should help to resolve the dispute.
     */
    function submitEvidence(address _from, bytes32 _cid, uint8 _index, bytes calldata _evidence) external {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);
        ARBITER.submitEvidence(_did, _from, _evidence);
        emit DisputeWitnessed(_cid, _index, _from, _evidence);
    }

    /**
     * @dev Summon jurors for case resolution.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     */
    function closeEvidencePeriod(bytes32 _cid, uint8 _index) external {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);
        ARBITER.closeEvidencePeriod(_did);
    }

    /**
     * @dev Apply Aragon Court descision to milestone.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _mid Milestone key.
     * @return ruling of Aragon Court.
     */
    function ruleDispute(bytes32 _cid, uint8 _index, bytes32 _mid) external returns(uint256) {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        uint256 _resolved = resolutions[_mid];
        if (_resolved != EMPTY_INT) return _resolved;

        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        (, uint256 _ruling) = ARBITER.rule(_did);
        if (_ruling == RULE_PAYER_WON) {
            resolutions[_mid] = _ruling;
        } else if (_ruling == RULE_PAYEE_WON) {
            resolutions[_mid] = _ruling;
        } else if (_ruling == RULE_IGNORED || _ruling == RULE_LEAKED) {
            // Allow to send the same case again
            disputes[_mid] = EMPTY_INT;
        } else {
            revert();
        }
        emit DisputeConcluded(_cid, _index, _ruling);
        return _ruling;
    }

    /**
     * @dev Get information about dispute for specific milestone
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone disputed.
     * @return subject Arbitrable subject being disputed.
     * @return possibleRulings Number of possible rulings allowed for the drafted guardians to vote on the dispute.
     * @return state Current state of the dispute being queried: pre-draft, adjudicating, or ruled.
     * @return finalRuling The winning ruling in case the dispute is finished.
     * @return lastRoundId Identification number of the last round created for the dispute.
     * @return createTermId Identification number of the term when the dispute was created.
     */
    function getDispute(bytes32 _cid, uint8 _index) external view returns(
        address subject,
        uint8 possibleRulings,
        IDisputeManager.DisputeState state,
        uint8 finalRuling,
        uint256 lastRoundId,
        uint64 createTermId
    ) {
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        return DISPUTE_MANAGER.getDispute(_did);
    }

    /**
     * @dev Get information about dispute next round.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone disputed.
     * @return nextRoundStartTerm Term ID from which the next round will start
     * @return nextRoundGuardiansNumber Guardians number for the next round
     * @return newDisputeState New state for the dispute associated to the given round after the appeal
     * @return feeToken ERC20 token used for the next round fees
     * @return totalFees  Total amount of fees for a regular round at the given term
     * @return guardianFees Total amount of fees to be distributed between the winning guardians of the next round
     * @return appealDeposit Amount to be deposit of fees for a regular round at the given term
     * @return confirmAppealDeposit Total amount of fees for a regular round at the given term
     */
    function getDisputeNextRoundDetails(bytes32 _cid, uint8 _index, uint256 _lastRoundId) external view returns(
        uint64 nextRoundStartTerm,
        uint64 nextRoundGuardiansNumber,
        IDisputeManager.DisputeState newDisputeState,
        IERC20 feeToken,
        uint256 totalFees,
        uint256 guardianFees,
        uint256 appealDeposit,
        uint256 confirmAppealDeposit
    ) {
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        return DISPUTE_MANAGER.getNextRoundDetails(_did, _lastRoundId);
    }

    /**
     * @dev Appeal dispute, by paying extra collateral.
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _lastRoundId Get round for appeal, obtainable by calling `DISPUTE_MANAGER.getDispute(_cid, _index)`.
     * @param _ruling Ruling which is suggested by appealer.
     * @param _feeToken ERC20 token used for collateral, obtainable by calling `DISPUTE_MANAGER.getNextRoundDetails(_did, _lastRoundId)`.
     * @param _appealFee Appeal collateral, obtainable by calling `DISPUTE_MANAGER.getNextRoundDetails(_did, _lastRoundId)`.
     */
    function appealDispute(
        address _feePayer,
        bytes32 _cid,
        uint8 _index,
        uint256 _lastRoundId,
        uint8 _ruling,
        IERC20 _feeToken,
        uint256 _appealFee
    ) external {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        require(_feeToken.transferFrom(_feePayer, address(this), _appealFee), ERROR_APPEAL_PAY_FAILED);
        require(_feeToken.approve(address(DISPUTE_MANAGER), _appealFee), ERROR_APPEAL_PAY_FAILED);
        
        DISPUTE_MANAGER.createAppeal(_did, _lastRoundId, _ruling);
        emit DisputeAppealed(_cid, _index, _did, _lastRoundId, _ruling, address(_feeToken), _appealFee);
    }

    /**
     * @dev Confirm appeal, by paying extra collateral.
     *
     * @param _feePayer Address which will pay a dispute fee (should approve this contract).
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _lastRoundId Get round for appeal, obtainable by calling `DISPUTE_MANAGER.getDispute(_did)`.
     * @param _ruling Ruling which is suggested by the opponent of appealer.
     * @param _feeToken ERC20 token used for collateral, obtainable by calling `DISPUTE_MANAGER.getNextRoundDetails(_did, _lastRoundId)`.
     * @param _confirmAppealFee Appeal collateral, obtainable by calling `DISPUTE_MANAGER.getNextRoundDetails(_did, _lastRoundId)`.
     */
    function confirmAppealDispute(
        address _feePayer,
        bytes32 _cid,
        uint8 _index,
        uint256 _lastRoundId,
        uint8 _ruling,
        IERC20 _feeToken,
        uint256 _confirmAppealFee
    ) external {
        require(TRUSTED_REGISTRY.escrowContracts(msg.sender), ERROR_NOT_DISPUTER);
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);

        require(_feeToken.transferFrom(_feePayer, address(this), _confirmAppealFee), ERROR_APPEAL_PAY_FAILED);
        require(_feeToken.approve(address(DISPUTE_MANAGER), _confirmAppealFee), ERROR_APPEAL_PAY_FAILED);

        DISPUTE_MANAGER.confirmAppeal(_did, _lastRoundId, _ruling);
        emit DisputeAppealConfirmed(_cid, _index, _did, _lastRoundId, _ruling, address(_feeToken), _confirmAppealFee);
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
    function _genMid(bytes32 _cid, uint8 _index) internal pure returns(bytes32) {
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