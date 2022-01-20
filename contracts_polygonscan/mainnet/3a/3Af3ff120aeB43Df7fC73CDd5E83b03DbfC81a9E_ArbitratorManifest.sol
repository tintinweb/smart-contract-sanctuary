/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: GPL-3.0-only

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: contracts/interfaces/IDisputeManagerCore.sol
pragma solidity ^0.8.4;

interface IDisputeManagerCore {
    event NewDispute(
        uint256 indexed disputeId,
        address indexed subject,
        uint64 indexed draftTermId,
        uint64 jurorsNumber,
        bytes metadata
    );
    event EvidenceSubmitted(uint256 indexed disputeId, address indexed submitter, bytes evidence);
    event EvidencePeriodClosed(uint256 indexed disputeId, uint64 indexed termId);
    event RulingComputed(uint256 indexed disputeId, uint8 indexed ruling);
}

// File: contracts/interfaces/IDisputeManager.sol
pragma solidity ^0.8.4;

interface IDisputeManager is IDisputeManagerCore {
    enum DisputeState {
        PreDraft,
        Adjudicating,
        Ruled
    }

    enum AdjudicationState {
        Invalid,
        Committing,
        Revealing,
        Appealing,
        ConfirmingAppeal,
        Ended
    }

    function createDispute(address _subject, uint8 _possibleRulings, bytes calldata _metadata) external returns (uint256);
    function submitEvidence(address _subject, uint256 _disputeId, address _submitter, bytes calldata _evidence) external;
    function closeEvidencePeriod(address _subject, uint256 _disputeId) external;
    function draft(uint256 _disputeId) external;
    function createAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;
    function confirmAppeal(uint256 _disputeId, uint256 _roundId, uint8 _ruling) external;
    function computeRuling(uint256 _disputeId) external returns (address subject, uint8 finalRuling);
    function settlePenalties(uint256 _disputeId, uint256 _roundId, uint256 _jurorsToSettle) external;
    function settleReward(uint256 _disputeId, uint256 _roundId, address _juror) external;
    function settleAppealDeposit(uint256 _disputeId, uint256 _roundId) external;
    function getDisputeFees() external view returns (IERC20 feeToken, uint256 feeAmount);
    function getDispute(uint256 _disputeId)
        external view returns (
            address subject,
            uint8 possibleRulings,
            DisputeState state,
            uint8 finalRuling,
            uint256 lastRoundId,
            uint64 createTermId
        );
    function getRound(uint256 _disputeId, uint256 _roundId)
        external view returns (
            uint64 draftTerm,
            uint64 delayedTerms,
            uint64 jurorsNumber,
            uint64 selectedJurors,
            uint256 jurorFees,
            bool settledPenalties,
            uint256 collectedTokens,
            uint64 coherentJurors,
            AdjudicationState state
        );
    function getAppeal(uint256 _disputeId, uint256 _roundId)
        external view returns (
            address maker,
            uint64 appealedRuling,
            address taker,
            uint64 opposedRuling
        );
    function getNextRoundDetails(uint256 _disputeId, uint256 _roundId)
        external view returns (
            uint64 nextRoundStartTerm,
            uint64 nextRoundJurorsNumber,
            DisputeState newDisputeState,
            IERC20 feeToken,
            uint256 totalFees,
            uint256 jurorFees,
            uint256 appealDeposit,
            uint256 confirmAppealDeposit
        );
    function getJuror(uint256 _disputeId, uint256 _roundId, address _juror)
        external view returns (
            uint64 weight,
            bool rewarded
        );


    event DisputeStateChanged(uint256 indexed disputeId, DisputeState indexed state);
    event JurorDrafted(uint256 indexed disputeId, uint256 indexed roundId, address indexed juror);
    event RulingAppealed(uint256 indexed disputeId, uint256 indexed roundId, uint8 ruling);
    event RulingAppealConfirmed(uint256 indexed disputeId, uint256 indexed roundId, uint64 indexed draftTermId, uint256 jurorsNumber);
    event PenaltiesSettled(uint256 indexed disputeId, uint256 indexed roundId, uint256 collectedTokens);
    event RewardSettled(uint256 indexed disputeId, uint256 indexed roundId, address juror, uint256 tokens, uint256 fees);
    event AppealDepositSettled(uint256 indexed disputeId, uint256 indexed roundId);
    event MaxJurorsPerDraftBatchChanged(uint64 previousMaxJurorsPerDraftBatch, uint64 currentMaxJurorsPerDraftBatch);
}

// File: contracts/interfaces/IArbitratorManifest.sol
pragma solidity ^0.8.4;

interface IArbitratorManifest {
    event PartiesSet(
        uint256 indexed disputeId,
        address indexed defendant,
        address indexed challenger
    );
    event RepStateSet(
        address indexed client,
        address indexed rep,
        bool isActive
    );
    event AllowRepresentation(
        address indexed rep,
        address indexed client,
        bool allowed
    );

    function setPartiesOf(uint256 _disputeId, address _defendant, address _challenger) external;
    function setRepStatus(address _rep, bool _isActive) external;
    function allowRepresentation(address _client, bool _allow) external;
    function isRepOf(address _account, address _rep) external view returns (bool isRep);
    function defendantOf(uint256 _disputeId) external view returns (address defendant);
    function challengerOf(uint256 _disputeId) external view returns (address challenger);
    function canRepresent(address _rep, address _client) external view returns (bool allowed);
    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        external view returns (bool canSubmit, address submittingFor);
}

// File: contracts/manifest/ArbitratorManifestCore.sol
pragma solidity ^0.8.4;

abstract contract ArbitratorManifestCore is IArbitratorManifest {
    mapping(address => mapping(address => bool)) public override isRepOf;
    mapping(address => mapping(address => bool)) public override canRepresent;
    mapping(uint256 => address) public override defendantOf;
    mapping(uint256 => address) public override challengerOf;

    function setPartiesOf(
        uint256 _disputeId,
        address _defendant,
        address _challenger
    )
        external override
    {
        require(msg.sender == _getSubjectOf(_disputeId), "ArbManifest: not subject");
        require(_defendant != _challenger, "ArbManifest: party conflict");
        defendantOf[_disputeId] = _defendant;
        challengerOf[_disputeId] = _challenger;
        emit PartiesSet(_disputeId, _defendant, _challenger);
    }

    /**
      Sets whether the `_client` is allowed to set the `msg.sender` as their
      representative. Potentially also resets the representative status to false

      @param _client the potential `_client` of the `msg.sender` for which to
      set the approval
      @param _allow whether the `msg.sender` is allowing the `_client` to set
      them as a representative
      @dev fires `AllowRepresentation` event
      @dev fires a `RepStateSet` if `_allow = false`
      @dev sets rep status to `false` if `_allow = false`
    */
    function allowRepresentation(address _client, bool _allow) external override {
        if (!_allow) {
            _setRepStatus(_client, msg.sender, false);
        }
        canRepresent[msg.sender][_client] = _allow;
        emit AllowRepresentation(msg.sender, _client, _allow);
    }

    /**
      Sets whether the `_rep` is to be a representative of the `msg.sender`

      @param _rep address of the representative for which to change the status
      @param _isActive whether `_rep` is to be a representative of `msg.sender`
      @dev fires a `RepStateSet` event
      @dev reverts if `canRepresent[_rep][msg.sender] = false`
    */
    function setRepStatus(address _rep, bool _isActive) external override {
        _setRepStatus(msg.sender, _rep, _isActive);
    }

    /**
      @dev will also return `false` if `_submitter` is a representative of both
      the defendant and challenger
    */
    function canSubmitEvidenceFor(address _submitter, uint256 _disputeId)
        public view override returns (bool, address)
    {
        address defendant = defendantOf[_disputeId];
        bool isDefendant = defendant == _submitter || isRepOf[defendant][_submitter];
        address challenger = challengerOf[_disputeId];
        bool isChallenger = challenger == _submitter || isRepOf[challenger][_submitter];
        if (isDefendant != isChallenger) {
            return (true, isDefendant ? defendant : challenger);
        }
        return (false, address(0));
    }

    function _setRepStatus(address _client, address _rep, bool _isActive) internal {
        require(!_isActive || canRepresent[_rep][_client], "ArbManifest: cannot rep");
        isRepOf[_client][_rep] = _isActive;
        emit RepStateSet(_client, _rep, _isActive);
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view virtual returns (address subject);
}

// File: contracts/manifest/ArbitratorManifest.sol
pragma solidity ^0.8.4;

contract ArbitratorManifest is ArbitratorManifestCore {
    IDisputeManager public immutable disputeManager;

    constructor(IDisputeManager _disputeManager) {
        disputeManager = _disputeManager;
    }

    function _getSubjectOf(uint256 _disputeId)
        internal view override returns (address subject)
    {
        (subject,,,,,) = disputeManager.getDispute(_disputeId);
    }
}