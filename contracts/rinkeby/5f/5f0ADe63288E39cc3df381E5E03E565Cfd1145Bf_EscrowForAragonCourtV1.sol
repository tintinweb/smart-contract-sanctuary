// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./extensions/EscrowContract.sol";
import "./extensions/WithPreSignedMilestones.sol";
import "./extensions/AmendablePreSigned.sol";
import "./interfaces/IAragonCourt.sol";

contract EscrowForAragonCourtV1 is EscrowContract, AmendablePreSigned, WithPreSignedMilestones {
    string private constant ERROR_NOT_DISPUTER = "Not a disputer";
    string private constant ERROR_IN_DISPUTE = "In dispute";
    string private constant ERROR_NOT_IN_DISPUTE = "Not in dispute";
    string private constant ERROR_ALREADY_RESOLVED = "Resolution applied";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw / refund";
    string private constant ERROR_NOT_APPROVED = "Not signed by another party";
    string private constant ERROR_DISPUTE_PAY_FAILED = "Failed to pay dispute fee";

    uint256 private constant EMPTY_INT = 0;
    uint256 private constant RULE_PAYEE_WON = 3;
    uint256 private constant RULE_PAYER_WON = 4;

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);

    IAragonCourt public immutable ARBITER;

    struct MilestoneParams {
        address paymentToken;
        address treasury;
        uint amount;
    }

    mapping (bytes32 => uint256) disputes;
    mapping (bytes32 => uint256) resolutions;

    /**
     * @dev Can only be a contract party, either payer (or his delegate) or payee.
     *
     * @param _cid Contract's IPFS cid.
     */
    modifier isDisputer(bytes32 _cid) {
        Contract memory _c = contracts[_cid];
        require(msg.sender == _c.payee || msg.sender == _c.payerDelegate, ERROR_NOT_DISPUTER);
        _;
    }

    /**
     * @dev Version of Escrow which uses Aragon Court dispute interfaces.
     *
     * @param _registry Address of universal registry of all contracts.
     * @param _arbiter Address of Aragon Court subjective oracle.
     */
    constructor(address _registry, address _arbiter) EscrowContract(_registry) {
        ARBITER = IAragonCourt(_arbiter);
    }

    /**
     * @dev Prepare contract between parties, with initial milestones.
     * Initial milestone term cid, will be the same as contract cid.
     *
     * @param _cid Contract's IPFS cid.
     * @param _payer Party which pays for the contract or on behalf of which the funding was done.
     * @param _payerDelegate Delegate who can release or dispute contract on behalf of payer.
     * @param _payee Party which recieves the payment.
     * @param _payeeAccount Address where payment should be delivered, mainly useful for vesting contracts.
     * @param _milestones Delivery amounts and payment tokens.
     */
    function registerContract(
        bytes32 _cid,
        address _payer,
        address _payerDelegate,
        address _payee,
        address _payeeAccount,
        MilestoneParams[] calldata _milestones
    ) external {
        _registerContract(_cid, _payer, _payerDelegate, _payee, _payeeAccount);

        bytes32 _mid;
        address _paymentToken;
        address _treasury;
        uint _amount;
        uint8 _index;
        for (uint8 _i=0; _i<_milestones.length; _i++) {
            _index = _i + 1;
            _amount = _milestones[_i].amount;
            _paymentToken = _milestones[_i].paymentToken;
            _treasury = _milestones[_i].treasury;
            _mid = _genMid(_cid, _index);
            _registerMilestoneStorage(_cid, _mid, _paymentToken, _treasury, _amount);
            emit NewMilestone(_cid, _mid, _paymentToken, _amount, _index);
        }
    }

    /**
     * @dev Add new milestone for the existing contract with amendment to contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @param _paymentToken Payment token for amount.
     * @param _treasury Address where the escrow funds will be stored (farming?).
     * @param _amount Amount to be paid in payment token for the milestone.
     * @param _amendmentCid Should be the same as _cid if no change in contract terms are needed.
     */
    function registerMilestone(
        bytes32 _cid,
        uint8 _index,
        address _paymentToken,
        address _treasury,
        uint _amount,
        bytes32 _amendmentCid
    ) external {
        _registerMilestone(_cid, _index, _paymentToken, _treasury, _amount, _amendmentCid);

        // One amendment can cover terms for several milestones
        if (_cid != _amendmentCid && _amendmentCid != EMPTY_BYTES32 && _amendmentCid != getLatestApprovedContractVersion(_cid)) {
            _proposeAmendment(_cid, _amendmentCid, contracts[_cid].payer, contracts[_cid].payee);
        }
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
    function fundMilestone(bytes32 _cid, uint8 _index, uint _amountToFund) external {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(isApprovedContractVersion(_cid, _m.termsCid), ERROR_NOT_APPROVED);
        _fundMilestone(_mid, _m, _amountToFund);
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
        uint8 _index,
        bytes32 _termsCid,
        uint _amountToFund,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) external {
        _signAndFundMilestone(_cid, _index, _termsCid, _amountToFund, _payeeSignature, _payerSignature);

        if (amendments[_cid].cid == EMPTY_BYTES32) _approveAmendment(_cid, _termsCid);
    }

    /**
     * @dev Propose change for the current contract terms.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid New version of contract's IPFS cid.
     */
    function signAndProposeContractVersion(bytes32 _cid, bytes32 _amendmentCid) external {
        Contract memory _c = contracts[_cid];
        require(msg.sender == _c.payee || msg.sender == _c.payer, ERROR_NOT_DISPUTER);
        _proposeAmendment(_cid, _amendmentCid, _c.payee, _c.payer);
    }

    /**
     * @dev Same as proposeAmendment amendment, but pre-approved with signature of non-sender party.
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
        _approveAmendment(_cid, _amendmentCid);
    }

    /**
     * @dev Initiate a dispute for a milestone and plead to Aragon Court as arbiter.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Comment from dispute initiator.
     */
    function dispute(bytes32 _cid, uint8 _index, bytes calldata _evidence) external isDisputer(_cid) {
        bytes32 _mid = _genMid(_cid, _index);
        require(disputes[_mid] == EMPTY_INT, ERROR_IN_DISPUTE);

        (address _recipient, IERC20 _feeToken, uint256 _feeAmount) = ARBITER.getDisputeFees();
        require(_feeToken.transferFrom(msg.sender, address(this), _feeAmount), ERROR_DISPUTE_PAY_FAILED);
        require(_feeToken.approve(_recipient, _feeAmount), ERROR_DISPUTE_PAY_FAILED);

        uint256 _did = ARBITER.createDispute(2, abi.encodePacked(milestones[_mid].termsCid));
        disputes[_mid] = _did;

        ARBITER.submitEvidence(_did, msg.sender, _evidence);
    }

    /**
     * @dev Submit evidence to help dispute resolution.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     * @param _evidence Additonal evidence which should help to resolve the dispute.
     */
    function submitEvidence(bytes32 _cid, uint8 _index, bytes calldata _evidence) external isDisputer(_cid) {
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);
        ARBITER.submitEvidence(_did, msg.sender, _evidence);
    }

    /**
     * @dev Summon jurors for case resolution.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone to dispute.
     */
    function closeEvidencePeriod(bytes32 _cid, uint8 _index) external isDisputer(_cid) {
        bytes32 _mid = _genMid(_cid, _index);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);
        ARBITER.closeEvidencePeriod(_did);
    }

    /**
     * @dev Apply Aragon Court descision to milestone.
     *
     * Can be called by anyone, as ruling is static.
     *
     * @param _mid Contract milestone uid (see _genMid).
     */
    function resolveDispute(bytes32 _mid) external {
        require(resolutions[_mid] == EMPTY_INT, ERROR_ALREADY_RESOLVED);
        uint256 _did = disputes[_mid];
        require(_did != EMPTY_INT, ERROR_NOT_IN_DISPUTE);
        // solhint-unused-local-variable
        (, uint256 _ruling) = ARBITER.rule(_did);
        resolutions[_mid] = _ruling;

        Milestone memory _m = milestones[_mid];
        uint _available = _m.fundedAmount - _m.claimedAmount;
        require(_available > 0, ERROR_NO_MONEY);

        if (_ruling == RULE_PAYER_WON) {
            _cancelMilestone(_mid, _available, _available - _m.refundedAmount, address(ARBITER));
        } else if (_ruling == RULE_PAYEE_WON) {
            _releaseMilestone(_mid, _available, _available - _m.releasedAmount, address(ARBITER));
        } else {
            revert();
        }
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

abstract contract ContractContext {
    struct Contract {
        address payer;
        address payerDelegate;
        address payee;
        address payeeAccount;
    }

    mapping (bytes32 => Contract) public contracts;

    event ApprovedContractVersion(
        bytes32 indexed cid,
        bytes32 indexed approvedCid
    );
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

abstract contract EIP712{
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

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../contexts/ContractContext.sol";

abstract contract Amendable is ContractContext {
    string private constant ERROR_EMPTY = "Empty amendment";
    string private constant ERROR_AMENDMENT_EXIST = "Amendment exist";
    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_EARLIER_AMENDMENT = "Not final amendment";

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);

    struct Amendment{
        bytes32 cid;
        uint256 timestamp;
    }

    struct AmendmentProposal {
        bytes32 cid;
        address validator;
        uint256 timestamp;
    }

    mapping (bytes32 => Amendment) public amendments;
    mapping (bytes32 => bool) public amendmentApprovals;
    mapping (bytes32 => AmendmentProposal) public amendmentProposals;

    event NewAmendment(
        bytes32 indexed cid,
        bytes32 indexed amendmentCid,
        bytes32 key,
        address indexed validator
    );

    /**
     * @dev Return IPFS cid of a latest approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @return IPFS cid in hex form for a final approved version of a contract or
     * bytes32(0) if no version was approved by both parties.
     */
    function getLatestApprovedContractVersion(bytes32 _cid) public view returns (bytes32) {
        return amendments[_cid].cid;
    }

    /**
     * @dev Check if specific contract version was approved by both parties.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid cid of suggested contract version.
     * @return approval by both parties.
     */
    function isApprovedContractVersion(bytes32 _cid, bytes32 _amendmentCid) public view returns (bool) {
        bytes32 _key = genAmendmentKey(_cid, _amendmentCid);
        return amendmentApprovals[_key];
    }

    /**
     * @dev Generate unique amendment key in scope of a contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid cid of suggested contract version.
     * @return unique storage key for amendment.
     */
    function genAmendmentKey(bytes32 _cid, bytes32 _amendmentCid) public pure returns(bytes32) {
        return keccak256(abi.encode(_cid, _amendmentCid));
    }

    /**
     * @dev Validate amendment by the opposite party.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid Amendment IPFS cid for approval.
     */
    function signAndApproveContractVersion(bytes32 _cid, bytes32 _amendmentCid) public {
        bytes32 _key = genAmendmentKey(_cid, _amendmentCid);
        AmendmentProposal memory _amendment = amendmentProposals[_key];
        require(_amendment.validator == msg.sender, ERROR_NOT_VALIDATOR);
        require(_amendment.timestamp > amendments[_cid].timestamp, ERROR_EARLIER_AMENDMENT);
        _approveAmendment(_cid, _amendmentCid);
        
        // Gas refund
        delete amendmentProposals[_key];
    }

    /**
     * @dev Proposals are saved in a temporary dictionary until they are approved to amendments mapping.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid New version of contract's IPFS cid.
     * @param _party1 Address of first party (e.g. payer).
     * @param _party2 Address of second party (e.g. payee).
     * @return key for amendment.
     */
    function _proposeAmendment(
        bytes32 _cid,
        bytes32 _amendmentCid,
        address _party1,
        address _party2
    ) internal returns (bytes32) {
        bytes32 _key = genAmendmentKey(_cid, _amendmentCid);
        require(_amendmentCid != EMPTY_BYTES32, ERROR_EMPTY);
        require(amendmentProposals[_key].cid == EMPTY_BYTES32, ERROR_AMENDMENT_EXIST);

        address _validator = _party1;
        if (msg.sender == _party1) _validator = _party2;
        amendmentProposals[_key] = AmendmentProposal({ cid: _amendmentCid, validator: _validator, timestamp: block.timestamp });
        emit NewAmendment(_cid, _amendmentCid, _key, _validator);
        return _key;
    }

    /**
     * @dev Save new approved contract version.
     *
     * @param _cid Contract's IPFS cid.
     * @param _amendmentCid New version of contract's IPFS cid.
     */
    function _approveAmendment(bytes32 _cid, bytes32 _amendmentCid) internal {
        bytes32 _key = genAmendmentKey(_cid, _amendmentCid);
        amendmentApprovals[_key] = true;
        amendments[_cid] = Amendment({ cid: _amendmentCid, timestamp: block.timestamp });
        emit ApprovedContractVersion(_cid, _amendmentCid);
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "./Amendable.sol";
import "../contexts/EIP712.sol";

abstract contract AmendablePreSigned is EIP712, Amendable {
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
        return _isValidEIP712Signature(
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

    address private constant EMPTY_ADDRESS = address(0);

    IRegistry public immutable TRUSTED_REGISTRY;

    event NewContract(
        bytes32 cid,
        address indexed payer,
        address indexed payerDelegate,
        address indexed payee,
        address payeeAccount
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
     * @param _payeeAccount Address where payment should be delivered, mainly useful for vesting contracts.
     */
    function _registerContract(
        bytes32 _cid,
        address _payer,
        address _payerDelegate,
        address _payee,
        address _payeeAccount
    ) internal {
        require(contracts[_cid].payer == EMPTY_ADDRESS, ERROR_CONTRACT_EXITS);

        if (_payerDelegate == EMPTY_ADDRESS) _payerDelegate = _payer;
        if (_payeeAccount == EMPTY_ADDRESS) _payeeAccount = _payee;
        contracts[_cid] = Contract({
            payer: _payer,
            payerDelegate: _payerDelegate,
            payee: _payee,
            payeeAccount: _payeeAccount
        });
        emit NewContract(_cid, _payer, _payerDelegate, _payee, _payeeAccount);

        TRUSTED_REGISTRY.registerNewContract(_cid, _payer, _payee);
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contexts/ContractContext.sol";

abstract contract WithMilestones is ContractContext {
    string private constant ERROR_MILESTONE_EXITS = "Milestone exists";
    string private constant ERROR_FUNDING = "Funding failed";
    string private constant ERROR_FUNDED = "Funding not needed";
    string private constant ERROR_RELEASED = "Invalid release amount";
    string private constant ERROR_NOT_APPROVED = "Funding not approved";
    string private constant ERROR_NOT_DISPUTER = "Not a party";
    string private constant ERROR_NOT_VALIDATOR = "Not a validator";
    string private constant ERROR_NO_MONEY = "Nothing to withdraw / refund";

    bytes32 private constant EMPTY_BYTES32 = bytes32(0);
    address private constant EMPTY_ADDRESS = address(0);
    
    struct Milestone {
        bytes32 termsCid;
        IERC20 paymentToken;
        address treasury;
        uint amount;
        uint fundedAmount;
        uint refundedAmount;
        uint releasedAmount;
        uint claimedAmount;
    }

    mapping (bytes32 => Milestone) public milestones;

    event NewMilestone(
        bytes32 indexed cid,
        bytes32 mid,
        address paymentToken,
        uint indexed amount,
        uint8 indexed index
    );

    event FundedMilestone(
        bytes32 indexed mid,
        address indexed funder,
        uint indexed amount
    );

    event ReleasedMilestone(
        bytes32 indexed mid,
        address indexed releaser,
        uint indexed amount
    );

    event CanceledMilestone(
        bytes32 indexed mid,
        address indexed releaser,
        uint indexed amount
    );

    event WithdrawnMilestone(
        bytes32 indexed mid,
        address indexed recipient,
        uint indexed amount
    );

    event RefundedMilestone(
        bytes32 indexed mid,
        address indexed recipient,
        uint indexed amount
    );

    /**
     * @dev As payer or delegater allow payee to claim released amount of payment token.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amountToRelease amount of payment token to release from the milestone.
     */
    function releaseMilestone(bytes32 _cid, uint8 _index, uint _amountToRelease) public {
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
    function cancelMilestone(bytes32 _cid, uint8 _index, uint _amountToRefund) public {
        Contract memory _c = contracts[_cid];
        require(msg.sender == _c.payee, ERROR_NOT_VALIDATOR);

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
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     */
    function withdrawMilestone(bytes32 _cid, uint8 _index) public {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        _withdrawMilestone(_mid, contracts[_cid].payeeAccount, _m);
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
    function refundMilestone(bytes32 _cid, uint8 _index) public {
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        _refundMilestone(_mid, contracts[_cid].payer, _m);
    }

    /**
     * @dev Add new milestone for the existing contract.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone (255 max).
     * @param _paymentToken Payment token for amount.
     * @param _treasury Address where the escrow funds will be stored (farming?).
     * @param _amount Amount to be paid in payment token for the milestone.
     * @param _termsCid Contract's IPFS cid related to this milestone.
     */
    function _registerMilestone(
        bytes32 _cid,
        uint8 _index,
        address _paymentToken,
        address _treasury,
        uint _amount,
        bytes32 _termsCid
    ) internal {
        Contract memory _c = contracts[_cid];
        bool _isPayer = msg.sender == _c.payer;
        require(msg.sender == _c.payee || _isPayer, ERROR_NOT_DISPUTER);

        bytes32 _mid = _genMid(_cid, _index);
        require(milestones[_mid].amount == 0, ERROR_MILESTONE_EXITS);
        _registerMilestoneStorage(_termsCid, _mid, _paymentToken, _treasury, _amount);
        emit NewMilestone(_cid, _mid, _paymentToken, _amount, _index);
    }

    /**
     * @dev Add new milestone for the existing contract.
     *
     * @param _termsCid Terms cid related to this milestone.
     * @param _mid UID of contract's milestone.
     * @param _paymentToken Address of ERC20 token to be used as payment currency in this escrow.
     * @param _treasury Address where milestone funds are kept in escrow.
     * @param _amount Amount to be paid in payment token for the milestone.
     */
    function _registerMilestoneStorage(
        bytes32 _termsCid,
        bytes32 _mid,
        address _paymentToken,
        address _treasury,
        uint _amount
    ) internal {
        milestones[_mid] = Milestone({
            termsCid: _termsCid,
            paymentToken: IERC20(_paymentToken),
            treasury: _treasury,
            amount: _amount,
            fundedAmount: 0,
            releasedAmount: 0,
            refundedAmount: 0,
            claimedAmount: 0
        });
    }

    /**
     * @dev Fund milestone with payment token, partial funding is possible.
     * To increase the maximum funding amount, just add a new milestone.
     *
     * Anyone can fund milestone, payment token should be approved for this contract.
     *
     * @param _mid UID of contract's milestone.
     * @param _m Milestone structure for the _mid.
     * @param _amountToFund amount of payment token to fund the milestone.
     */
    function _fundMilestone(bytes32 _mid, Milestone memory _m, uint _amountToFund) internal {
        uint _fundedAmount = _m.fundedAmount;
        require(_amountToFund > 0 && _m.amount >= (_fundedAmount + _amountToFund), ERROR_FUNDED);
        require(_m.paymentToken.transferFrom(msg.sender, _m.treasury, _amountToFund), ERROR_FUNDING);
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
     * @dev Transfer released funds to payee.
     *
     * @param _mid UID of contract's milestone.
     * @param _payeeAccount Address where funds should be transfered.
     * @param _m Milestone data.
     */
    function _withdrawMilestone(bytes32 _mid, address _payeeAccount, Milestone memory _m) internal {
        uint _leftAmount = _m.fundedAmount - _m.claimedAmount;
        uint _released = _m.releasedAmount;
        if (_leftAmount < _released) _released = _leftAmount;
        require(_released > 0, ERROR_NO_MONEY);

        milestones[_mid].claimedAmount = _m.claimedAmount + _released;
        milestones[_mid].releasedAmount = 0;
        if (_m.treasury == address(this)) {
            require(_m.paymentToken.transfer(_payeeAccount, _released), ERROR_FUNDING);
        } else {
            require(_m.paymentToken.transferFrom(_m.treasury, _payeeAccount, _released), ERROR_FUNDING);
        }
        emit WithdrawnMilestone(_mid, _payeeAccount, _released);
    }

    /**
     * @dev Transfer released funds to payer.
     *
     * @param _mid UID of contract's milestone.
     * @param _payer Address where funds should be refunded.
     * @param _m Milestone data.
     */
    function _refundMilestone(bytes32 _mid, address _payer, Milestone memory _m) internal {
        uint _leftAmount = _m.fundedAmount - _m.claimedAmount;
        uint _refundable = _m.refundedAmount;
        if (_leftAmount < _refundable) _refundable = _leftAmount;
        require(_refundable > 0, ERROR_NO_MONEY);

        milestones[_mid].claimedAmount = _m.claimedAmount + _refundable;
        milestones[_mid].refundedAmount = 0;
        if (_m.treasury == address(this)) {
            require(_m.paymentToken.transfer(_payer, _refundable), ERROR_FUNDING);
        } else {
            require(_m.paymentToken.transferFrom(_m.treasury, _payer, _refundable), ERROR_FUNDING);
        }
        emit RefundedMilestone(_mid, _payer, _refundable);
    }

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

import "./WithMilestones.sol";
import "../contexts/EIP712.sol";

abstract contract WithPreSignedMilestones is EIP712, WithMilestones {
    string private constant ERROR_INVALID_SIGNATURE = "Invalid signature";
    string private constant ERROR_RELEASED = "Invalid release amount";
    string private constant ERROR_INVALID_TERMS = "Invalid terms for milestone";

    /// @dev Value returned by a call to `_isPreApprovedMilestoneRelease` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("_isPreApprovedMilestoneRelease(bytes32,uint8,uint256,address,bytes32,bytes)"))
    bytes4 private constant MAGICVALUE = 0xe7a051d0;
    /// bytes4(keccak256("_isSignedContractTerms(bytes32,bytes32,address,bytes32,bytes)"))
    bytes4 private constant SIGNED_CONTRACT_MAGICVALUE = 0xda041b1b;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    bytes32 internal constant MILESTONE_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 internal constant MILESTONE_RELEASE_DOMAIN_NAME = keccak256("ReleasedMilestone");
    bytes32 internal constant MILESTONE_REFUND_DOMAIN_NAME = keccak256("RefundedMilestone");
    bytes32 internal constant SIGNED_CONTRACT_DOMAIN_NAME = keccak256("SignedContract");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 internal constant MILESTONE_RELEASE_DOMAIN_VERSION = keccak256("v1");
    bytes32 internal constant MILESTONE_REFUND_DOMAIN_VERSION = keccak256("v1");
    bytes32 internal constant SIGNED_CONTRACT_DOMAIN_VERSION = keccak256("v1");

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
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amount Amount to withdraw.
     * @param _payerDelegateSignature Signed digest for release of amount.
     */
    function withdrawPreApprovedMilestone(bytes32 _cid, uint8 _index, uint _amount, bytes calldata _payerDelegateSignature) public {
        Contract memory _c = contracts[_cid];
        address _payerDelegate = _c.payerDelegate;
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
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
        _withdrawMilestone(_mid, _c.payeeAccount, _m);
    }

    /**
     * @dev Withdraw payment token amount refunded by payee.
     *
     * Can be called by anyone, as recipient is static,
     * can be potenatially used to sponsor gas fees by payer.
     *
     * @param _cid Contract's IPFS cid.
     * @param _index Number of milestone.
     * @param _amount Amount to refund.
     * @param _payeeSignature Signed digest for release of amount.
     */
    function refundPreApprovedMilestone(bytes32 _cid, uint8 _index, uint _amount, bytes calldata _payeeSignature) public {
        Contract memory _c = contracts[_cid];
        address _payee = _c.payee;
        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_amount > 0 && _m.fundedAmount >= _m.claimedAmount + _amount, ERROR_RELEASED);
        require(_isPreApprovedMilestoneRelease(
            _cid,
            _index,
            _amount,
            _payee,
            getMilestoneRefundDomainSeparator(),
            _payeeSignature
        ) == MAGICVALUE, ERROR_INVALID_SIGNATURE);
        
        _m.refundedAmount += _amount;
        _cancelMilestone(_mid, _m.refundedAmount, _amount, _payee);
        _refundMilestone(_mid, _c.payer, _m);
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
        uint8 _index,
        bytes32 _termsCid,
        uint _amountToFund,
        bytes calldata _payeeSignature,
        bytes calldata _payerSignature
    ) internal {
        Contract memory _c = contracts[_cid];
        address _payer = _c.payer;
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
            _c.payee,
            getSignedContractDomainSeparator(),
            _payeeSignature
        ) == SIGNED_CONTRACT_MAGICVALUE, ERROR_INVALID_SIGNATURE);

        bytes32 _mid = _genMid(_cid, _index);
        Milestone memory _m = milestones[_mid];
        require(_m.termsCid == _termsCid, ERROR_INVALID_TERMS);
        _fundMilestone(_mid, _m, _amountToFund);
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
        uint8 _index,
        uint256 _amount,
        address _validator,
        bytes32 _domain,
        bytes calldata _callData
    ) internal pure returns (bytes4) {
        return _isValidEIP712Signature(
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
        return _isValidEIP712Signature(
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

interface IRegistry {
    function registerNewContract(bytes32 _cid, address _payer, address _payee) external;
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