// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/INodeOperatorRegistry.sol";
import "./interfaces/IValidatorFactory.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/IStMATIC.sol";

/// @title NodeOperatorRegistry
/// @author 2021 ShardLabs.
/// @notice NodeOperatorRegistry is the main contract that manage validators
/// @dev NodeOperatorRegistry is the main contract that manage operators.
contract NodeOperatorRegistry is
    INodeOperatorRegistry,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    enum NodeOperatorStatus {
        INACTIVE,
        ACTIVE,
        STOPPED,
        UNSTAKED,
        CLAIMED,
        WAIT,
        EXIT
    }
    /// @notice The node operator struct
    /// @param status node operator status(INACTIVE, ACTIVE, STOPPED, CLAIMED, UNSTAKED, WAIT, EXIT).
    /// @param name node operator name.
    /// @param rewardAddress Validator public key used for access control and receive rewards.
    /// @param validatorId validator id of this node operator on the polygon stake manager.
    /// @param signerPubkey public key used on heimdall.
    /// @param validatorShare validator share contract used to delegate for on polygon.
    /// @param validatorProxy the validator proxy, the owner of the validator.
    /// @param commissionRate the commission rate applied by the operator on polygon.
    /// @param slashed the number of times this operator was slashed, will be decreased after the slashedTimestamp + slashingDelay < block.timestamp.
    /// @param slashedTimestamp the timestamp when the operator was slashed.
    /// @param statusUpdatedTimestamp the timestamp when the operator updated the status (ex: INACTIVE -> ACTIVE)
    /// @param maxDelegateLimit max delegation limit that StMatic contract will delegate to this operator each time delegate function is called.
    struct NodeOperator {
        NodeOperatorStatus status;
        string name;
        address rewardAddress;
        bytes signerPubkey;
        address validatorShare;
        address validatorProxy;
        uint256 validatorId;
        uint256 commissionRate;
        uint256 slashed;
        uint256 slashedTimestamp;
        uint256 statusUpdatedTimestamp;
        uint256 maxDelegateLimit;
        uint256 amountStaked;
    }

    /// @notice all the roles.
    bytes32 public constant REMOVE_OPERATOR_ROLE =
        keccak256("LIDO_REMOVE_OPERATOR");
    bytes32 public constant PAUSE_OPERATOR_ROLE =
        keccak256("LIDO_PAUSE_OPERATOR");
    bytes32 public constant DAO_ROLE = keccak256("LIDO_DAO");

    /// @notice contract version.
    string public version;
    /// @notice total node operators.
    uint256 private totalNodeOperator;
    /// @notice total inactive node operators.
    uint256 private totalInactiveNodeOperator;
    /// @notice total active node operators.
    uint256 private totalActiveNodeOperator;
    /// @notice total stopped node operators.
    uint256 private totalStoppedNodeOperator;
    /// @notice total unstaked node operators.
    uint256 private totalUnstakedNodeOperator;
    /// @notice total claimed node operators.
    uint256 private totalClaimedNodeOperator;
    /// @notice total wait node operators.
    uint256 private totalWaitNodeOperator;
    /// @notice total exited node operators.
    uint256 private totalExitNodeOperator;

    /// @notice validatorFactory address.
    address private validatorFactory;
    /// @notice stakeManager address.
    address private stakeManager;
    /// @notice polygonERC20 token (Matic) address.
    address private polygonERC20;
    /// @notice stMATIC address.
    address private stMATIC;

    /// @notice min amount allowed to stake per validator.
    uint256 public minAmountStake;

    /// @notice min HeimdallFees allowed to stake per validator.
    uint256 public minHeimdallFees;

    /// @notice commision rate applied to all the operators.
    uint256 public commissionRate;

    /// @notice allows restake.
    bool public allowsRestake;

    /// @notice allows unjail a validator.
    bool public allowsUnjail;

    /// @notice the default period where an operator will marked as "was slashed".
    uint256 public slashingDelay;

    /// @notice default max delgation limit.
    uint256 public defaultMaxDelegateLimit;

    /// @notice This stores the operators ids.
    uint256[] private operatorIds;

    /// @notice Mapping of all owners with node operator id. Mapping is used to be able to
    /// extend the struct.
    mapping(address => uint256) private operatorOwners;

    /// @notice Mapping of all validatorShare with operatorId
    mapping(address => uint256) private validatorShare2OperatorId;

    /// @notice Mapping of all node operators. Mapping is used to be able to extend the struct.
    mapping(uint256 => NodeOperator) private operators;

    /// --------------------------- Modifiers-----------------------------------

    /// @notice Check if the msg.sender has permission.
    /// @param _role role needed to call function.
    modifier userHasRole(bytes32 _role) {
        checkCondition(hasRole(_role, msg.sender), "unauthorized");
        _;
    }

    /// @notice Check if the amount is inbound.
    /// @param _amount amount to stake.
    modifier checkStakeAmount(uint256 _amount) {
        checkCondition(_amount >= minAmountStake, "Invalid amount");
        _;
    }

    /// @notice Check if the heimdall fee is inbound.
    /// @param _heimdallFee heimdall fee.
    modifier checkHeimdallFees(uint256 _heimdallFee) {
        checkCondition(_heimdallFee >= minHeimdallFees, "Invalid fees");
        _;
    }

    /// @notice Check if the maxDelegateLimit is less or equal to 10 Billion.
    /// @param _maxDelegateLimit max delegate limit.
    modifier checkMaxDelegationLimit(uint256 _maxDelegateLimit) {
        checkCondition(
            _maxDelegateLimit <= 10000000000 ether,
            "Max amount <= 10B"
        );
        _;
    }

    /// @notice Check if the rewardAddress is already used.
    /// @param _rewardAddress new reward address.
    modifier checkIfRewardAddressIsUsed(address _rewardAddress) {
        checkCondition(
            operatorOwners[_rewardAddress] == 0 && _rewardAddress != address(0),
            "Address used"
        );
        _;
    }

    /// -------------------------- initialize ----------------------------------

    /// @notice Initialize the NodeOperator contract.
    function initialize(
        address _validatorFactory,
        address _stakeManager,
        address _polygonERC20
    ) external initializer {
        __Pausable_init();
        __AccessControl_init();

        validatorFactory = _validatorFactory;
        stakeManager = _stakeManager;
        polygonERC20 = _polygonERC20;

        minAmountStake = 10 * 10**18;
        minHeimdallFees = 20 * 10**18;
        slashingDelay = 2**13;
        defaultMaxDelegateLimit = 10 ether;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REMOVE_OPERATOR_ROLE, msg.sender);
        _setupRole(PAUSE_OPERATOR_ROLE, msg.sender);
        _setupRole(DAO_ROLE, msg.sender);
    }

    /// ----------------------------- API --------------------------------------

    /// @notice Add a new node operator to the system.
    /// @dev The operator life cycle starts when we call the addOperator
    /// func allows adding a new operator. During this call, a new validatorProxy is
    /// deployed by the ValidatorFactory which we can use later to interact with the
    /// Polygon StakeManager. At the end of this call, the status of the operator
    /// will be INACTIVE.
    /// @param _name the node operator name.
    /// @param _rewardAddress address used for ACL and receive rewards.
    /// @param _signerPubkey public key used on heimdall len 64 bytes.
    function addOperator(
        string memory _name,
        address _rewardAddress,
        bytes memory _signerPubkey
    )
        external
        override
        whenNotPaused
        userHasRole(DAO_ROLE)
        checkIfRewardAddressIsUsed(_rewardAddress)
    {
        uint256 operatorId = totalNodeOperator + 1;
        address validatorProxy = IValidatorFactory(validatorFactory).create();

        operators[operatorId] = NodeOperator({
            status: NodeOperatorStatus.INACTIVE,
            name: _name,
            rewardAddress: _rewardAddress,
            validatorId: 0,
            signerPubkey: _signerPubkey,
            validatorShare: address(0),
            validatorProxy: validatorProxy,
            commissionRate: commissionRate,
            slashed: 0,
            slashedTimestamp: 0,
            statusUpdatedTimestamp: block.timestamp,
            maxDelegateLimit: defaultMaxDelegateLimit,
            amountStaked: 0
        });
        operatorIds.push(operatorId);
        totalNodeOperator++;
        totalInactiveNodeOperator++;

        operatorOwners[_rewardAddress] = operatorId;

        emit AddOperator(operatorId);
    }

    /// @notice Allows to stop an operator from the system.
    /// @param _operatorId the node operator id.
    function stopOperator(uint256 _operatorId)
        external
        override
        userHasRole(DAO_ROLE)
    {
        (, NodeOperator storage no) = getOperator(_operatorId);
        NodeOperatorStatus status = no.status;
        checkCondition(
            no.rewardAddress != address(0) &&
                status <= NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );

        if (status == NodeOperatorStatus.INACTIVE) {
            no.status = NodeOperatorStatus.EXIT;
            totalInactiveNodeOperator--;
            totalExitNodeOperator++;
        } else if (status == NodeOperatorStatus.ACTIVE) {
            IStMATIC(stMATIC).withdrawTotalDelegated(no.validatorShare);
            no.status = NodeOperatorStatus.STOPPED;
            totalActiveNodeOperator--;
            totalStoppedNodeOperator++;
        }

        emit StopOperator(_operatorId);
    }

    /// @notice Allows to switch an operator status from WAIT to EXIT.
    /// this function should only be called by the StMatic contract inside claimTokens2StMatic.
    function exitOperator(address _validatorShare) external override {
        checkCondition(msg.sender == stMATIC, "Caller is not stMATIC contract");

        uint256 operatorId = validatorShare2OperatorId[_validatorShare];
        checkCondition(operatorId != 0, "Operator not found");

        NodeOperator storage no = operators[operatorId];
        NodeOperatorStatus status = no.status;

        delete validatorShare2OperatorId[no.validatorShare];

        if (
            status == NodeOperatorStatus.UNSTAKED ||
            status == NodeOperatorStatus.CLAIMED
        ) {
            return;
        }

        checkCondition(status == NodeOperatorStatus.WAIT, "Invalid status");
        no.status = NodeOperatorStatus.EXIT;

        totalWaitNodeOperator--;
        totalExitNodeOperator++;
    }

    /// @notice Allows to remove an operator from the system.when the operator status is
    /// set to EXIT the GOVERNANCE can call the removeOperator func to delete the operator,
    /// and the validatorProxy used to interact with the Polygon stakeManager.
    /// @param _operatorId the node operator id.
    function removeOperator(uint256 _operatorId)
        external
        override
        whenNotPaused
        userHasRole(REMOVE_OPERATOR_ROLE)
    {
        (, NodeOperator storage no) = getOperator(_operatorId);
        checkCondition(no.status == NodeOperatorStatus.EXIT, "Invalid status");

        // update the operatorIds array by removing the operator id.
        for (uint256 idx = 0; idx < operatorIds.length - 1; idx++) {
            if (_operatorId == operatorIds[idx]) {
                operatorIds[idx] = operatorIds[operatorIds.length - 1];
                break;
            }
        }
        operatorIds.pop();

        totalNodeOperator--;
        totalExitNodeOperator--;
        IValidatorFactory(validatorFactory).remove(no.validatorProxy);
        delete operatorOwners[no.rewardAddress];
        delete operators[_operatorId];

        emit RemoveOperator(_operatorId);
    }

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    function joinOperator() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.INACTIVE,
            "Invalid status"
        );

        IStakeManager sm = IStakeManager(stakeManager);
        uint256 validatorId = sm.getValidatorId(msg.sender);

        checkCondition(validatorId != 0, "ValidatorId=0");

        IStakeManager.Validator memory poValidator = sm.validators(validatorId);
        checkCondition(
            poValidator.status == IStakeManager.Status.Active,
            "Validator isn't ACTIVE"
        );

        checkCondition(
            poValidator.signer ==
                address(uint160(uint256(keccak256(no.signerPubkey)))),
            "Invalid Signer"
        );

        IValidator(no.validatorProxy).join(
            validatorId,
            sm.NFTContract(),
            msg.sender,
            no.commissionRate,
            stakeManager
        );

        no.amountStaked = sm.validatorStake(no.validatorId);
        no.status = NodeOperatorStatus.ACTIVE;
        no.validatorId = validatorId;
        no.statusUpdatedTimestamp = block.timestamp;

        address validatorShare = sm.getValidatorContract(validatorId);
        no.validatorShare = validatorShare;
        validatorShare2OperatorId[validatorShare] = operatorId;

        totalActiveNodeOperator++;
        totalInactiveNodeOperator--;

        emit JoinOperator(operatorId);
    }

    /// ------------------------Stake Manager API-------------------------------

    /// @notice Allows to stake a validator on the Polygon stakeManager contract.
    /// @dev The stake func allows each operator's owner to stake, but before that,
    /// the owner has to approve the amount + Heimdall fees to the ValidatorProxy.
    /// At the end of this call, the status of the operator is set to ACTIVE.
    /// @param _amount amount to stake.
    /// @param _heimdallFee herimdall fees.
    function stake(uint256 _amount, uint256 _heimdallFee)
        external
        override
        whenNotPaused
        checkStakeAmount(_amount)
        checkHeimdallFees(_heimdallFee)
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.INACTIVE,
            "Invalid status"
        );
        (uint256 validatorId, address validatorShare) = IValidator(
            no.validatorProxy
        ).stake(
                msg.sender,
                _amount,
                _heimdallFee,
                true,
                no.signerPubkey,
                no.commissionRate,
                stakeManager,
                polygonERC20
            );

        no.validatorId = validatorId;
        no.validatorShare = validatorShare;
        no.amountStaked += _amount;
        no.status = NodeOperatorStatus.ACTIVE;
        no.statusUpdatedTimestamp = block.timestamp;

        totalInactiveNodeOperator--;
        totalActiveNodeOperator++;
        validatorShare2OperatorId[validatorShare] = operatorId;

        emit StakeOperator(operatorId, _amount, _heimdallFee);
    }

    /// @notice Allows to restake Matics to Polygon stakeManager
    /// @dev restake allows an operator's owner to increase the total staked amount
    /// on Polygon. The owner has to approve the amount to the ValidatorProxy then make
    /// a call. The owner can restake the rewards accumulated by setting the "_restakeRewards"
    /// to true
    /// @param _amount amount to stake.
    /// @param _restakeRewards bool to restake rewards.
    function restake(uint256 _amount, bool _restakeRewards)
        external
        override
        whenNotPaused
    {
        checkCondition(allowsRestake, "Restake is disabled");
        if (_amount == 0 && !_restakeRewards) {
            revert("Amount is ZERO");
        }

        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        (bool ok, uint256 newAmount) = IValidator(no.validatorProxy).restake(
            msg.sender,
            no.validatorId,
            _amount,
            false,
            no.amountStaked,
            stakeManager,
            polygonERC20
        );

        checkCondition(ok, "Could not restake, try later");
        no.amountStaked = newAmount;

        emit RestakeOperator(operatorId, _amount, _restakeRewards);
    }

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @dev when the operators's owner wants to quite the PoLido protocol he can call
    /// the unstake func, in this case, the operator status is set to UNSTAKED.
    function unstake() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        IValidator(no.validatorProxy).unstake(no.validatorId, stakeManager);
        IStMATIC(stMATIC).withdrawTotalDelegated(no.validatorShare);

        no.status = NodeOperatorStatus.UNSTAKED;
        no.statusUpdatedTimestamp = block.timestamp;
        totalActiveNodeOperator--;
        totalUnstakedNodeOperator++;

        emit UnstakeOperator(operatorId);
    }

    /// @notice Allows the operator's owner to migrate the validator ownership to rewardAddress.
    /// This can be done only in the case where this operator was stopped by the DAO.
    function migrate() external override {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.STOPPED,
            "Invalid status"
        );
        IValidator(no.validatorProxy).migrate(
            no.validatorId,
            IStakeManager(stakeManager).NFTContract(),
            no.rewardAddress
        );

        totalStoppedNodeOperator--;
        totalWaitNodeOperator++;
        no.status = NodeOperatorStatus.WAIT;

        emit MigrateOperator(operatorId);
    }

    /// @notice Allows to unjail the validator and turn his status from UNSTAKED to ACTIVE.
    /// @dev when an operator is UNSTAKED the owner can switch back and stake the
    /// operator by calling the unjail func, in this case, the operator status is set
    /// to back ACTIVE.
    function unjail() external override whenNotPaused {
        checkCondition(allowsUnjail, "Unjail is disabled");

        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.UNSTAKED,
            "Invalid status"
        );
        IValidator(no.validatorProxy).unjail(no.validatorId, stakeManager);

        no.status = NodeOperatorStatus.ACTIVE;
        no.statusUpdatedTimestamp = block.timestamp;

        totalActiveNodeOperator++;
        totalUnstakedNodeOperator--;

        emit Unjail(operatorId);
    }

    /// @notice Allows to top up heimdall fees.
    /// @dev the operator's owner can topUp the heimdall fees by calling the
    /// topUpForFee, but before that node operator needs to approve the amount of heimdall
    /// fees to his validatorProxy.
    /// @param _heimdallFee amount
    function topUpForFee(uint256 _heimdallFee)
        external
        override
        whenNotPaused
        checkHeimdallFees(_heimdallFee)
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        IValidator(no.validatorProxy).topUpForFee(
            msg.sender,
            _heimdallFee,
            stakeManager,
            polygonERC20
        );

        emit TopUpHeimdallFees(operatorId, _heimdallFee);
    }

    /// @notice Allows to unstake staked tokens after withdraw delay.
    /// @dev after the unstake the operator and waiting for the Polygon withdraw_delay
    /// the owner can transfer back his staked balance by calling
    /// unstakeClaim, after that the operator status is set to CLAIMED
    function unstakeClaim() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.UNSTAKED,
            "Invalid status"
        );
        uint256 amount = IValidator(no.validatorProxy).unstakeClaim(
            no.validatorId,
            msg.sender,
            stakeManager,
            polygonERC20
        );

        no.status = NodeOperatorStatus.CLAIMED;
        no.statusUpdatedTimestamp = block.timestamp;
        no.amountStaked = 0;

        totalUnstakedNodeOperator--;
        totalClaimedNodeOperator++;

        emit UnstakeClaim(operatorId, amount);
    }

    /// @notice Allows withdraw heimdall fees
    /// @dev the operator's owner can claim the heimdall fees.
    /// func, after that the operator status is set to EXIT.
    /// @param _accumFeeAmount accumulated heimdall fees
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.CLAIMED,
            "Invalid status"
        );
        IValidator(no.validatorProxy).claimFee(
            _accumFeeAmount,
            _index,
            _proof,
            no.rewardAddress,
            stakeManager,
            polygonERC20
        );

        totalClaimedNodeOperator--;

        if (validatorShare2OperatorId[no.validatorShare] != 0) {
            no.status = NodeOperatorStatus.WAIT;
            totalWaitNodeOperator++;
        } else {
            no.status = NodeOperatorStatus.EXIT;
            totalExitNodeOperator++;
            delete validatorShare2OperatorId[no.validatorShare];
        }
        no.statusUpdatedTimestamp = block.timestamp;

        emit ClaimFee(operatorId);
    }

    /// @notice Allows the operator's owner to withdraw rewards.
    function withdrawRewards() external override whenNotPaused {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        address rewardAddress = no.rewardAddress;
        uint256 rewards = IValidator(no.validatorProxy).withdrawRewards(
            no.validatorId,
            rewardAddress,
            stakeManager,
            polygonERC20
        );

        emit WithdrawRewards(operatorId, rewardAddress, rewards);
    }

    /// @notice Allows the operator's owner to update signer publickey.
    /// @param _signerPubkey new signer publickey
    function updateSigner(bytes memory _signerPubkey)
        external
        override
        whenNotPaused
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status <= NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        if (no.status == NodeOperatorStatus.ACTIVE) {
            IValidator(no.validatorProxy).updateSigner(
                no.validatorId,
                _signerPubkey,
                stakeManager
            );
        }

        no.signerPubkey = _signerPubkey;

        emit UpdateSignerPubkey(operatorId);
    }

    /// @notice Allows the operator owner to update the name.
    /// @param _name new operator name.
    function setOperatorName(string memory _name)
        external
        override
        whenNotPaused
    {
        // uint256 operatorId = getOperatorId(msg.sender);
        // NodeOperator storage no = operators[operatorId];
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(
            no.status <= NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );
        no.name = _name;

        emit NewName(operatorId, _name);
    }

    /// @notice Allows the operator owner to update the rewardAddress.
    /// @param _rewardAddress new reward address.
    function setOperatorRewardAddress(address _rewardAddress)
        external
        override
        whenNotPaused
        checkIfRewardAddressIsUsed(_rewardAddress)
    {
        (uint256 operatorId, NodeOperator storage no) = getOperator(0);
        checkCondition(no.rewardAddress != address(0), "Invalid status");
        no.rewardAddress = _rewardAddress;

        operatorOwners[_rewardAddress] = operatorId;
        delete operatorOwners[msg.sender];

        emit NewRewardAddress(operatorId, _rewardAddress);
    }

    /// -------------------------------DAO--------------------------------------

    /// @notice Allows the DAO to set the operator defaultMaxDelegateLimit.
    /// @param _defaultMaxDelegateLimit default max delegation amount.
    function setDefaultMaxDelegateLimit(uint256 _defaultMaxDelegateLimit)
        external
        override
        userHasRole(DAO_ROLE)
        checkMaxDelegationLimit(_defaultMaxDelegateLimit)
    {
        defaultMaxDelegateLimit = _defaultMaxDelegateLimit;
    }

    /// @notice Allows the DAO to set the operator maxDelegateLimit.
    /// @param _operatorId operator id.
    /// @param _maxDelegateLimit max amount to delegate .
    function setMaxDelegateLimit(uint256 _operatorId, uint256 _maxDelegateLimit)
        external
        override
        userHasRole(DAO_ROLE)
        checkMaxDelegationLimit(_maxDelegateLimit)
    {
        (, NodeOperator storage no) = getOperator(_operatorId);
        checkCondition(no.rewardAddress != address(0), "Invalid status");
        no.maxDelegateLimit = _maxDelegateLimit;
    }

    /// @notice Allows the DAO to set the slashingDelay.
    /// @param _slashingDelay slashing delay in seconds.
    function setSlashingDelay(uint256 _slashingDelay)
        external
        override
        userHasRole(DAO_ROLE)
    {
        slashingDelay = _slashingDelay;
    }

    /// @notice Allows to set the commission rate used.
    function setCommissionRate(uint256 _commissionRate)
        external
        override
        userHasRole(DAO_ROLE)
    {
        commissionRate = _commissionRate;
    }

    /// @notice Allows the dao to update commission rate for an operator.
    /// @param _operatorId id of the operator
    /// @param _newCommissionRate new commission rate
    function updateOperatorCommissionRate(
        uint256 _operatorId,
        uint256 _newCommissionRate
    ) external override userHasRole(DAO_ROLE) {
        (, NodeOperator storage no) = getOperator(_operatorId);
        checkCondition(
            no.rewardAddress != address(0) ||
                no.status == NodeOperatorStatus.ACTIVE,
            "Invalid status"
        );

        if (no.status == NodeOperatorStatus.ACTIVE) {
            IValidator(no.validatorProxy).updateCommissionRate(
                no.validatorId,
                _newCommissionRate,
                stakeManager
            );
        }

        no.commissionRate = _newCommissionRate;

        emit UpdateCommissionRate(_operatorId, _newCommissionRate);
    }

    /// @notice Allows to update the stake amount and heimdall fees
    /// @param _minAmountStake min amount to stake
    /// @param _minHeimdallFees min amount of heimdall fees
    function setStakeAmountAndFees(
        uint256 _minAmountStake,
        uint256 _minHeimdallFees
    )
        external
        override
        userHasRole(DAO_ROLE)
        checkStakeAmount(_minAmountStake)
        checkHeimdallFees(_minHeimdallFees)
    {
        minAmountStake = _minAmountStake;
        minHeimdallFees = _minHeimdallFees;
    }

    /// @notice Allows to pause the contract.
    function togglePause() external override userHasRole(PAUSE_OPERATOR_ROLE) {
        paused() ? _unpause() : _pause();
    }

    /// @notice Allows to toggle restake.
    function setRestake(bool _restake) external override userHasRole(DAO_ROLE) {
        allowsRestake = _restake;
    }

    /// @notice Allows to toggle unjail.
    function setUnjail(bool _unjail) external override userHasRole(DAO_ROLE) {
        allowsUnjail = _unjail;
    }

    /// @notice Allows to set the StMATIC contract address.
    function setStMATIC(address _stMATIC)
        external
        override
        userHasRole(DAO_ROLE)
    {
        stMATIC = _stMATIC;
    }

    /// @notice Allows to set the validator factory contract address.
    function setValidatorFactory(address _validatorFactory)
        external
        override
        userHasRole(DAO_ROLE)
    {
        validatorFactory = _validatorFactory;
    }

    /// @notice Allows to set the stake manager contract address.
    function setStakeManager(address _stakeManager)
        external
        override
        userHasRole(DAO_ROLE)
    {
        stakeManager = _stakeManager;
    }

    /// @notice Allows to set the contract version.
    /// @param _version contract version
    function setVersion(string memory _version)
        external
        override
        userHasRole(DEFAULT_ADMIN_ROLE)
    {
        version = _version;
    }

    /// @notice Allows to get a node operator by msg.sender.
    /// @param _owner a valid address of an operator owner, if not set msg.sender will be used.
    /// @return Returns a node operator.
    function getNodeOperator(address _owner)
        external
        view
        returns (NodeOperator memory)
    {
        uint256 operatorId = operatorOwners[_owner];
        return operators[operatorId];
    }

    /// @notice Allows to get a node operator by _operatorId.
    /// @param _operatorId the id of the operator.
    /// @return Returns a node operator.
    function getNodeOperator(uint256 _operatorId)
        external
        view
        returns (NodeOperator memory)
    {
        return operators[_operatorId];
    }

    /// @notice Allows to get a list of node operators that are in ACTIVE, UNSTAKE,
    /// STOPPED CLAIMED or WAIT.
    function getNodeOperatorState()
        external
        view
        override
        returns (address[] memory)
    {
        uint256 num = totalActiveNodeOperator +
            totalStoppedNodeOperator +
            totalUnstakedNodeOperator +
            totalClaimedNodeOperator +
            totalWaitNodeOperator;

        address[] memory adds = new address[](num);
        uint256 index;

        uint256[] memory memOperatorIds = operatorIds;

        for (uint256 i = 0; i < memOperatorIds.length; i++) {
            NodeOperator memory no = operators[memOperatorIds[i]];
            NodeOperatorStatus status = no.status;
            if (
                status == NodeOperatorStatus.INACTIVE ||
                status == NodeOperatorStatus.EXIT
            ) {
                continue;
            }
            adds[index] = no.validatorShare;
            index++;
        }

        return adds;
    }

    /// @notice Get the stMATIC contract addresses
    function getContracts()
        external
        view
        override
        returns (
            address _validatorFactory,
            address _stakeManager,
            address _polygonERC20,
            address _stMATIC
        )
    {
        _validatorFactory = validatorFactory;
        _stakeManager = stakeManager;
        _polygonERC20 = polygonERC20;
        _stMATIC = stMATIC;
    }

    /// @notice Get the global state
    function getState()
        external
        view
        override
        returns (
            uint256 _totalNodeOperator,
            uint256 _totalInactiveNodeOperator,
            uint256 _totalActiveNodeOperator,
            uint256 _totalStoppedNodeOperator,
            uint256 _totalUnstakedNodeOperator,
            uint256 _totalClaimedNodeOperator,
            uint256 _totalWaitNodeOperator,
            uint256 _totalExitNodeOperator
        )
    {
        _totalNodeOperator = totalNodeOperator;
        _totalInactiveNodeOperator = totalInactiveNodeOperator;
        _totalActiveNodeOperator = totalActiveNodeOperator;
        _totalStoppedNodeOperator = totalStoppedNodeOperator;
        _totalUnstakedNodeOperator = totalUnstakedNodeOperator;
        _totalClaimedNodeOperator = totalClaimedNodeOperator;
        _totalWaitNodeOperator = totalWaitNodeOperator;
        _totalExitNodeOperator = totalExitNodeOperator;
    }

    /// @notice Get operatorIds.
    function getOperatorIds()
        external
        view
        override
        returns (uint256[] memory)
    {
        return operatorIds;
    }

    /// @notice Get validator total stake.
    /// @param _rewardAddress reward address.
    /// @return Returns the total staked by the validator.
    function getValidatorStake(address _rewardAddress)
        external
        view
        override
        returns (uint256)
    {
        if (_rewardAddress == address(0)) {
            _rewardAddress == msg.sender;
        }

        uint256 operatorId = getOperatorId(_rewardAddress);
        NodeOperator memory no = operators[operatorId];
        return IStakeManager(stakeManager).validatorStake(no.validatorId);
    }

    /// @notice Allows listing all the operator's status by checking if the local stakedAmount
    /// is not equal to the stakedAmount on stake manager.
    function getIfOperatorsWereSlashed()
        external
        view
        override
        returns (bool[] memory)
    {
        IStakeManager sm = IStakeManager(stakeManager);
        uint256 length = operatorIds.length;
        bool[] memory slashedOperatorIds = new bool[](length);

        for (uint256 idx = 0; idx < length; idx++) {
            uint256 operatorId = operatorIds[idx];
            NodeOperator memory no = operators[operatorId];

            if (no.status == NodeOperatorStatus.ACTIVE) {
                uint256 amountStakedSM = sm.validatorStake(no.validatorId);
                if (no.amountStaked != amountStakedSM) {
                    slashedOperatorIds[idx] = true;
                    continue;
                }
            }
            slashedOperatorIds[idx] = false;
        }
        return slashedOperatorIds;
    }

    /// @notice Allows slashing all the operators if the local stakedAmount is not equal
    /// to the stakedAmount on stake manager.
    function slashOperators(bool[] memory _slashedOperatorIds)
        external
        override
    {
        IStakeManager sm = IStakeManager(stakeManager);
        uint256 length = _slashedOperatorIds.length;

        checkCondition(length == operatorIds.length, "slahed operators length");

        uint256[] memory _operatorIds = operatorIds;

        for (uint256 idx = 0; idx < length; idx++) {
            if (_slashedOperatorIds[idx]) {
                uint256 operatorId = _operatorIds[idx];
                NodeOperator storage no = operators[operatorId];
                if (!(no.status == NodeOperatorStatus.ACTIVE)) {
                    continue;
                }
                uint256 amountStakedSM = sm.validatorStake(no.validatorId);
                uint256 slashedTimestamp = no.slashedTimestamp;

                if (no.amountStaked != amountStakedSM) {
                    no.slashed++;
                    no.slashedTimestamp += slashedTimestamp != 0
                        ? slashingDelay
                        : block.timestamp + slashingDelay;
                    no.amountStaked = amountStakedSM;
                } else if (
                    slashedTimestamp != 0 &&
                    no.slashedTimestamp < block.timestamp
                ) {
                    no.slashedTimestamp = 0;
                }
            }
        }
    }

    /// @notice Allows to get a list of operatorInfo for all active operators.
    /// @param _rewardData calculate operator reward.
    /// @return Returns a list of operatorInfo for all active operators.
    function getOperatorInfos(bool _rewardData)
        external
        view
        override
        returns (Operator.OperatorInfo[] memory)
    {
        Operator.OperatorInfo[]
            memory operatorInfos = new Operator.OperatorInfo[](
                totalActiveNodeOperator
            );

        uint256 length = operatorIds.length;
        uint256 index;

        for (uint256 idx = 0; idx < length; idx++) {
            uint256 operatorId = operatorIds[idx];
            NodeOperator storage no = operators[operatorId];

            if (no.status == NodeOperatorStatus.ACTIVE) {
                operatorInfos[index] = Operator.OperatorInfo({
                    operatorId: operatorId,
                    validatorShare: no.validatorShare,
                    maxDelegateLimit: no.maxDelegateLimit,
                    rewardPercentage: _rewardData
                        ? _getRewardPercentage(no.slashedTimestamp)
                        : 0,
                    rewardAddress: no.rewardAddress
                });
                index++;
            }
        }
        return operatorInfos;
    }

    function _getRewardPercentage(uint256 _slashedTimestamp)
        private
        view
        returns (uint8)
    {
        if (_slashedTimestamp == 0 || _slashedTimestamp <= block.timestamp) {
            return 100;
        }

        uint256 t = _slashedTimestamp - block.timestamp;
        uint256 penalty = ((t / slashingDelay) + (t == slashingDelay ? 0 : 1)) *
            10;
        uint8 p = penalty > 100 ? 100 : uint8(penalty);
        uint8 percentage = 100 - p;
        return percentage > 0 ? percentage : 1;
    }

    /// @notice Checks condition and displays the message
    /// @param _condition a condition
    /// @param _message message to display
    function checkCondition(bool _condition, string memory _message)
        private
        pure
    {
        require(_condition, _message);
    }

    /// @notice Retrieve the operator struct based on the operatorId
    /// @param _operatorId id of the operator
    /// @return NodeOperator structure
    function getOperator(uint256 _operatorId)
        private
        view
        returns (uint256, NodeOperator storage)
    {
        if (_operatorId == 0) {
            _operatorId = getOperatorId(msg.sender);
        }
        NodeOperator storage no = operators[_operatorId];

        return (_operatorId, no);
    }

    /// @notice Retrieve the operator struct based on the operator owner address
    /// @param _user address of the operator owner
    /// @return NodeOperator structure
    function getOperatorId(address _user) private view returns (uint256) {
        uint256 operatorId = operatorOwners[_user];
        checkCondition(operatorId != 0, "Operator not found");
        return operatorId;
    }

    /// -------------------------------Events-----------------------------------

    /// @notice A new node operator was added.
    /// @param operatorId node operator id.
    event AddOperator(uint256 operatorId);

    /// @notice A new node operator joined.
    /// @param operatorId node operator id.
    event JoinOperator(uint256 operatorId);

    /// @notice A node operator was removed.
    /// @param operatorId node operator id.
    event RemoveOperator(uint256 operatorId);

    /// @param operatorId node operator id.
    event StopOperator(uint256 operatorId);

    /// @param operatorId node operator id.
    event MigrateOperator(uint256 operatorId);

    /// @notice A node operator was staked.
    /// @param operatorId node operator id.
    event StakeOperator(
        uint256 operatorId,
        uint256 amount,
        uint256 heimdallFees
    );

    /// @notice A node operator restaked.
    /// @param operatorId node operator id.
    /// @param amount amount to restake.
    /// @param restakeRewards restake rewards.
    event RestakeOperator(
        uint256 operatorId,
        uint256 amount,
        bool restakeRewards
    );

    /// @notice A node operator was unstaked.
    /// @param operatorId node operator id.
    event UnstakeOperator(uint256 operatorId);

    /// @notice TopUp heimadall fees.
    /// @param operatorId node operator id.
    /// @param amount amount.
    event TopUpHeimdallFees(uint256 operatorId, uint256 amount);

    /// @notice Withdraw rewards.
    /// @param operatorId node operator id.
    /// @param rewardAddress reward address.
    /// @param amount amount.
    event WithdrawRewards(
        uint256 operatorId,
        address rewardAddress,
        uint256 amount
    );

    /// @notice claims unstake.
    /// @param operatorId node operator id.
    /// @param amount amount.
    event UnstakeClaim(uint256 operatorId, uint256 amount);

    /// @notice update signer publickey.
    /// @param operatorId node operator id.
    event UpdateSignerPubkey(uint256 operatorId);

    /// @notice claim herimdall fee.
    /// @param operatorId node operator id.
    event ClaimFee(uint256 operatorId);

    /// @notice update commission rate.
    event UpdateCommissionRate(uint256 operatorId, uint256 newCommissionRate);

    /// @notice Unjail a validator.
    event Unjail(uint256 operatorId);

    /// @notice update operator name.
    event NewName(uint256 operatorId, string name);

    /// @notice update operator name.
    event NewRewardAddress(uint256 operatorId, address rewardAddress);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../lib/Operator.sol";

/// @title INodeOperatorRegistry
/// @author 2021 ShardLabs
/// @notice Node operator registry interface
interface INodeOperatorRegistry {
    /// @notice Allows to add a new node operator to the system.
    /// @param _name the node operator name.
    /// @param _rewardAddress public address used for ACL and receive rewards.
    /// @param _signerPubkey public key used on heimdall len 64 bytes.
    function addOperator(
        string memory _name,
        address _rewardAddress,
        bytes memory _signerPubkey
    ) external;

    /// @notice Allows to stop a node operator.
    /// @param _operatorId node operator id.
    function stopOperator(uint256 _operatorId) external;

    /// @notice Allows to remove a node operator from the system.
    /// @param _operatorId node operator id.
    function removeOperator(uint256 _operatorId) external;

    /// @notice Allows a staked validator to join the system.
    function joinOperator() external;

    /// @notice Allows to stake an operator on the Polygon stakeManager.
    /// This function calls Polygon transferFrom so the totalAmount(_amount + _heimdallFee)
    /// has to be approved first.
    /// @param _amount amount to stake.
    /// @param _heimdallFee heimdallFee to stake.
    function stake(uint256 _amount, uint256 _heimdallFee) external;

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param _amount amount to stake.
    /// @param _restakeRewards restake rewards.
    function restake(uint256 _amount, bool _restakeRewards) external;

    /// @notice Allows the operator's owner to migrate the NFT. This can be done only
    /// if the DAO stopped the operator.
    function migrate() external;

    /// @notice Allows to unstake an operator from the stakeManager. After the withdraw_delay
    /// the operator owner can call claimStake func to withdraw the staked tokens.
    function unstake() external;

    /// @notice Allows to topup heimdall fees on polygon stakeManager.
    /// @param _heimdallFee amount to topup.
    function topUpForFee(uint256 _heimdallFee) external;

    /// @notice Allows to claim staked tokens on the stake Manager after the end of the
    /// withdraw delay
    function unstakeClaim() external;

    /// @notice Allows to get the total staked by a validator.
    /// @param _rewardAddress reward address.
    /// @return Returns the total staked.
    function getValidatorStake(address _rewardAddress)
        external
        view
        returns (uint256);

    /// @notice Allows an owner to withdraw rewards from the stakeManager.
    function withdrawRewards() external;

    /// @notice Allows to update the signer pubkey
    /// @param _signerPubkey update signer public key
    function updateSigner(bytes memory _signerPubkey) external;

    /// @notice Allows to claim the heimdall fees staked by the owner of the operator
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external;

    /// @notice Allows to unjail a validator and switch from UNSTAKE status to STAKED
    function unjail() external;

    /// @notice Allows an operator's owner to set the operator name.
    function setOperatorName(string memory _name) external;

    /// @notice Allows an operator's owner to set the operator rewardAddress.
    function setOperatorRewardAddress(address _rewardAddress) external;

    /// @notice Allows the DAO to set _defaultMaxDelegateLimit.
    function setDefaultMaxDelegateLimit(uint256 _defaultMaxDelegateLimit)
        external;

    /// @notice Allows the DAO to set _maxDelegateLimit for an operator.
    function setMaxDelegateLimit(uint256 _operatorId, uint256 _maxDelegateLimit)
        external;

    /// @notice Allows the DAO to set _slashingDelay.
    function setSlashingDelay(uint256 _slashingDelay) external;

    /// @notice Allows the DAO to set _commissionRate.
    function setCommissionRate(uint256 _commissionRate) external;

    /// @notice Allows the DAO to set _commissionRate for an operator.
    /// @param _operatorId id of the operator
    /// @param _newCommissionRate new commission rate
    function updateOperatorCommissionRate(
        uint256 _operatorId,
        uint256 _newCommissionRate
    ) external;

    /// @notice Allows the DAO to set _minAmountStake and _minHeimdallFees.
    function setStakeAmountAndFees(
        uint256 _minAmountStake,
        uint256 _minHeimdallFees
    ) external;

    /// @notice Allows to pause/unpause the node operator contract.
    function togglePause() external;

    /// @notice Allows the DAO to enable/disable restake.
    function setRestake(bool _restake) external;

    /// @notice Allows the DAO to enable/disable unjail.
    function setUnjail(bool _unjail) external;

    /// @notice Allows the DAO to set stMATIC contract.
    function setStMATIC(address _stMATIC) external;

    /// @notice Allows the DAO to set validator factory contract.
    function setValidatorFactory(address _validatorFactory) external;

    /// @notice Allows the DAO to set stake manager contract.
    function setStakeManager(address _stakeManager) external;

    /// @notice Allows to set contract version.
    function setVersion(string memory _version) external;

    /// @notice Get the stMATIC contract addresses
    function getContracts()
        external
        view
        returns (
            address _validatorFactory,
            address _stakeManager,
            address _polygonERC20,
            address _stMATIC
        );

    /// @notice Allows to get stats.
    function getState()
        external
        view
        returns (
            uint256 _totalNodeOperator,
            uint256 _totalInactiveNodeOperator,
            uint256 _totalActiveNodeOperator,
            uint256 _totalStoppedNodeOperator,
            uint256 _totalUnstakedNodeOperator,
            uint256 _totalClaimedNodeOperator,
            uint256 _totalWaitNodeOperator,
            uint256 _totalExitNodeOperator
        );

    /// @notice Allows to get all the active operators info.
    function getOperatorInfos(bool _rewardData)
        external
        view
        returns (Operator.OperatorInfo[] memory);

    /// @notice Allows slashing all the operators if the local stakedAmount is not equal
    /// to the stakedAmount on stake manager.
    function slashOperators(bool[] memory _slashedOperatorIds) external;

    /// @notice Allows listing all the operator's status by checking if the local stakedAmount
    /// is not equal to the stakedAmount on stake manager.
    function getIfOperatorsWereSlashed() external view returns (bool[] memory);

    /// @notice Allows update an operator status from WAIT to EXIT
    function exitOperator(address _validatorShare) external;

    /// @notice Allows to get all the operator ids.
    function getOperatorIds() external view returns (uint256[] memory);

    /// @notice Allows to get an node operator validatorShare contracts.
    function getNodeOperatorState() external view returns (address[] memory);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../Validator.sol";

/// @title IValidatorFactory.
/// @author 2021 ShardLabs
interface IValidatorFactory {
    /// @notice Deploy a new validator proxy contract.
    /// @return return the address of the deployed contract.
    function create() external returns (address);

    /// @notice Remove a validator proxy from the validators.
    function remove(address _validatorProxy) external;

    /// @notice Set the node operator contract address.
    function setOperator(address _operator) external;

    /// @notice Set validator implementation contract address.
    function setValidatorImplementation(address _validatorImplementation)
        external;
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "../Validator.sol";

/// @title IValidator.
/// @author 2021 ShardLabs
/// @notice Validator interface.
interface IValidator {
    /// @notice Allows to stake a validator on the Polygon stakeManager contract.
    /// @dev Stake a validator on the Polygon stakeManager contract.
    /// @param _sender msg.sender.
    /// @param _amount amount to stake.
    /// @param _heimdallFee herimdall fees.
    /// @param _acceptDelegation accept delegation.
    /// @param _signerPubkey signer public key used on the heimdall.
    /// @param _commisionRate commision rate of a validator
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _heimdallFee,
        bool _acceptDelegation,
        bytes memory _signerPubkey,
        uint256 _commisionRate,
        address stakeManager,
        address polygonERC20
    ) external returns (uint256, address);

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param _sender operator owner which approved tokens to the validato contract.
    /// @param validatorId validator id.
    /// @param amount amount to stake.
    /// @param stakeRewards restake rewards.
    /// @param amountStaked total amount staked by the operator in stake manager.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function restake(
        address _sender,
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards,
        uint256 amountStaked,
        address _stakeManager,
        address _polygonERC20
    ) external returns (bool, uint256);

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @dev Unstake a validator from the Polygon stakeManager contract by passing the validatorId
    /// @param _validatorId validatorId.
    /// @param _stakeManager address of the stake manager
    function unstake(uint256 _validatorId, address _stakeManager) external;

    /// @notice Allows to top up heimdall fees.
    /// @param _heimdallFee amount
    /// @param _sender msg.sender
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function topUpForFee(
        address _sender,
        uint256 _heimdallFee,
        address _stakeManager,
        address _polygonERC20
    ) external;

    /// @notice Allows to withdraw rewards from the validator.
    /// @dev Allows to withdraw rewards from the validator using the _validatorId. Only the
    /// owner can request withdraw in this the owner is this contract.
    /// @param _validatorId validator id.
    /// @param _rewardAddress user address used to transfer the staked tokens.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    /// @return Returns the amount transfered to the user.
    function withdrawRewards(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external returns (uint256);

    /// @notice Allows to claim staked tokens on the stake Manager after the end of the
    /// withdraw delay
    /// @param _validatorId validator id.
    /// @param _rewardAddress user address used to transfer the staked tokens.
    /// @return Returns the amount transfered to the user.
    function unstakeClaim(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external returns (uint256);

    /// @notice Allows to update the signer pubkey
    /// @param _validatorId validator id
    /// @param _signerPubkey update signer public key
    /// @param _stakeManager stake manager address
    function updateSigner(
        uint256 _validatorId,
        bytes memory _signerPubkey,
        address _stakeManager
    ) external;

    /// @notice Allows to claim the heimdall fees.
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    /// @param _ownerRecipient owner recipient
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof,
        address _ownerRecipient,
        address _stakeManager,
        address _polygonERC20
    ) external;

    /// @notice Allows to update the commision rate of a validator
    /// @param _validatorId operator id
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager stake manager address
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external;

    /// @notice Allows to unjail a validator.
    /// @param _validatorId operator id
    function unjail(uint256 _validatorId, address _stakeManager) external;

    /// @notice Allows to migrate the ownership to an other user.
    /// @param _validatorId operator id.
    /// @param _stakeManagerNFT stake manager nft contract.
    /// @param _rewardAddress reward address.
    function migrate(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress
    ) external;

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    /// @param _validatorId validator id
    /// @param _stakeManagerNFT address of the staking NFT
    /// @param _rewardAddress address that will receive the rewards from staking
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager address of the stake manager
    function join(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external;
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title StMATIC interface.
/// @author 2021 ShardLabs
interface IStMATIC {
    function withdrawTotalDelegated(address _validatorShare) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

library Operator {
    struct OperatorInfo {
        uint256 operatorId;
        address validatorShare;
        uint256 maxDelegateLimit;
        uint8 rewardPercentage;
        address rewardAddress;
    }
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./interfaces/IStakeManager.sol";
import "./interfaces/IValidator.sol";
import "./interfaces/INodeOperatorRegistry.sol";

/// @title ValidatorImplementation
/// @author 2021 ShardLabs.
/// @notice The validator contract is a simple implementation of the stakeManager API, the
/// ValidatorProxies use this contract to interact with the stakeManager.
/// When a ValidatorProxy calls this implementation the state is copied
/// (owner, implementation, operator), then they are used to check if the msg-sender is the
/// node operator contract, and if the validatorProxy implementation match with the current
/// validator contract.
contract Validator is IERC721Receiver, IValidator {
    using SafeERC20 for IERC20;

    address private implementation;
    address private operator;
    address private validatorFactory;

    /// @notice Check if the operator contract is the msg.sender.
    modifier isOperator() {
        require(
            msg.sender == operator,
            "Caller should be the operator contract"
        );
        _;
    }

    /// @notice Allows to stake on the Polygon stakeManager contract by
    /// calling stakeFor function and set the user as the equal to this validator proxy
    /// address.
    /// @param _sender the address of the operator-owner that approved Matics.
    /// @param _amount the amount to stake with.
    /// @param _heimdallFee the heimdall fees.
    /// @param _acceptDelegation accept delegation.
    /// @param _signerPubkey signer public key used on the heimdall node.
    /// @param _commissionRate validator commision rate
    /// @return Returns the validatorId and the validatorShare contract address.
    function stake(
        address _sender,
        uint256 _amount,
        uint256 _heimdallFee,
        bool _acceptDelegation,
        bytes memory _signerPubkey,
        uint256 _commissionRate,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (uint256, address) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        IERC20 polygonERC20 = IERC20(_polygonERC20);

        uint256 totalAmount = _amount + _heimdallFee;
        polygonERC20.safeTransferFrom(_sender, address(this), totalAmount);
        polygonERC20.safeApprove(address(stakeManager), totalAmount);
        stakeManager.stakeFor(
            address(this),
            _amount,
            _heimdallFee,
            _acceptDelegation,
            _signerPubkey
        );

        uint256 validatorId = stakeManager.getValidatorId(address(this));
        address validatorShare = stakeManager.getValidatorContract(validatorId);
        if (_commissionRate > 0) {
            stakeManager.updateCommissionRate(validatorId, _commissionRate);
        }

        return (validatorId, validatorShare);
    }

    /// @notice Restake validator rewards or new Matics validator on stake manager.
    /// @param _sender operator's owner that approved tokens to the validator contract.
    /// @param _validatorId validator id.
    /// @param _amount amount to stake.
    /// @param _stakeRewards restake rewards.
    /// @param _amountStaked total amount staked by the operator in stake manager.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    /// @return return a bool and the new total amount staked in stake manager.
    function restake(
        address _sender,
        uint256 _validatorId,
        uint256 _amount,
        bool _stakeRewards,
        uint256 _amountStaked,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (bool, uint256) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);

        if (_amount > 0) {
            IERC20 polygonERC20 = IERC20(_polygonERC20);
            polygonERC20.safeTransferFrom(_sender, address(this), _amount);
            polygonERC20.safeApprove(address(stakeManager), _amount);
        }
        if (stakeManager.validatorStake(_validatorId) != _amountStaked) {
            return (false, 0);
        }

        stakeManager.restake(_validatorId, _amount, _stakeRewards);

        return (true, stakeManager.validatorStake(_validatorId));
    }

    /// @notice Unstake a validator from the Polygon stakeManager contract.
    /// @param _validatorId validatorId.
    /// @param _stakeManager address of the stake manager
    function unstake(uint256 _validatorId, address _stakeManager)
        external
        override
        isOperator
    {
        // stakeManager
        IStakeManager(_stakeManager).unstake(_validatorId);
    }

    /// @notice Allows a validator to top-up the heimdall fees.
    /// @param _sender address that approved the _heimdallFee amount.
    /// @param _heimdallFee amount.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function topUpForFee(
        address _sender,
        uint256 _heimdallFee,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        IERC20 polygonERC20 = IERC20(_polygonERC20);

        polygonERC20.safeTransferFrom(_sender, address(this), _heimdallFee);
        polygonERC20.safeApprove(address(stakeManager), _heimdallFee);
        stakeManager.topUpForFee(address(this), _heimdallFee);
    }

    /// @notice Allows to withdraw rewards from the validator using the _validatorId. Only the
    /// owner can request withdraw. The rewards are transfered to the _rewardAddress.
    /// @param _validatorId validator id.
    /// @param _rewardAddress reward address.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function withdrawRewards(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (uint256) {
        IStakeManager(_stakeManager).withdrawRewards(_validatorId);

        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);

        return balance;
    }

    /// @notice Allows to unstake the staked tokens (+rewards) and transfer them
    /// to the owner rewardAddress.
    /// @param _validatorId validator id.
    /// @param _rewardAddress rewardAddress address.
    /// @param _stakeManager stake manager address
    /// @param _polygonERC20 address of the MATIC token
    function unstakeClaim(
        uint256 _validatorId,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator returns (uint256) {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        stakeManager.unstakeClaim(_validatorId);
        // polygonERC20
        // stakeManager
        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);

        return balance;
    }

    /// @notice Allows to update signer publickey.
    /// @param _validatorId validator id.
    /// @param _signerPubkey new publickey.
    /// @param _stakeManager stake manager address
    function updateSigner(
        uint256 _validatorId,
        bytes memory _signerPubkey,
        address _stakeManager
    ) external override isOperator {
        IStakeManager(_stakeManager).updateSigner(_validatorId, _signerPubkey);
    }

    /// @notice Allows withdraw heimdall fees.
    /// @param _accumFeeAmount accumulated heimdall fees.
    /// @param _index index.
    /// @param _proof proof.
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof,
        address _rewardAddress,
        address _stakeManager,
        address _polygonERC20
    ) external override isOperator {
        IStakeManager stakeManager = IStakeManager(_stakeManager);
        stakeManager.claimFee(_accumFeeAmount, _index, _proof);

        IERC20 polygonERC20 = IERC20(_polygonERC20);
        uint256 balance = polygonERC20.balanceOf(address(this));
        polygonERC20.safeTransfer(_rewardAddress, balance);
    }

    /// @notice Allows to update commission rate of a validator.
    /// @param _validatorId validator id.
    /// @param _newCommissionRate new commission rate.
    /// @param _stakeManager stake manager address
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate,
        address _stakeManager
    ) public override isOperator {
        IStakeManager(_stakeManager).updateCommissionRate(
            _validatorId,
            _newCommissionRate
        );
    }

    /// @notice Allows to unjail a validator.
    /// @param _validatorId validator id
    function unjail(uint256 _validatorId, address _stakeManager)
        external
        override
        isOperator
    {
        IStakeManager(_stakeManager).unjail(_validatorId);
    }

    /// @notice Allows to transfer the validator nft token to the reward address a validator.
    /// @param _validatorId operator id.
    /// @param _stakeManagerNFT stake manager nft contract.
    /// @param _rewardAddress reward address.
    function migrate(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress
    ) external override isOperator {
        IERC721 erc721 = IERC721(_stakeManagerNFT);
        erc721.approve(_rewardAddress, _validatorId);
        erc721.safeTransferFrom(address(this), _rewardAddress, _validatorId);
    }

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the PoLido protocol.
    /// @param _validatorId validator id
    /// @param _stakeManagerNFT address of the staking NFT
    /// @param _rewardAddress address that will receive the rewards from staking
    /// @param _newCommissionRate commission rate
    /// @param _stakeManager address of the stake manager
    function join(
        uint256 _validatorId,
        address _stakeManagerNFT,
        address _rewardAddress,
        uint256 _newCommissionRate,
        address _stakeManager
    ) external override isOperator {
        IERC721 erc721 = IERC721(_stakeManagerNFT);
        erc721.safeTransferFrom(_rewardAddress, address(this), _validatorId);
        updateCommissionRate(_validatorId, _newCommissionRate, _stakeManager);
    }

    /// @notice Allows to get the version of the validator implementation.
    /// @return Returns the version.
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice Implement @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol interface.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title polygon stake manager interface.
/// @author 2021 ShardLabs
/// @notice User to interact with the polygon stake manager.
interface IStakeManager {
    /// @notice Stake a validator on polygon stake manager.
    /// @param user user that own the validator in our case the validator contract.
    /// @param amount amount to stake.
    /// @param heimdallFee heimdall fees.
    /// @param acceptDelegation accept delegation.
    /// @param signerPubkey signer publickey used in heimdall node.
    function stakeFor(
        address user,
        uint256 amount,
        uint256 heimdallFee,
        bool acceptDelegation,
        bytes memory signerPubkey
    ) external;

    /// @notice Restake Matics for a validator on polygon stake manager.
    /// @param validatorId validator id.
    /// @param amount amount to stake.
    /// @param stakeRewards restake rewards.
    function restake(
        uint256 validatorId,
        uint256 amount,
        bool stakeRewards
    ) external;

    /// @notice Request unstake a validator.
    /// @param validatorId validator id.
    function unstake(uint256 validatorId) external;

    /// @notice Increase the heimdall fees.
    /// @param user user that own the validator in our case the validator contract.
    /// @param heimdallFee heimdall fees.
    function topUpForFee(address user, uint256 heimdallFee) external;

    /// @notice Get the validator id using the user address.
    /// @param user user that own the validator in our case the validator contract.
    /// @return return the validator id
    function getValidatorId(address user) external view returns (uint256);

    /// @notice get the validator contract used for delegation.
    /// @param validatorId validator id.
    /// @return return the address of the validator contract.
    function getValidatorContract(uint256 validatorId)
        external
        view
        returns (address);

    /// @notice Withdraw accumulated rewards
    /// @param validatorId validator id.
    function withdrawRewards(uint256 validatorId) external returns (uint256);

    /// @notice Get validator total staked.
    /// @param validatorId validator id.
    function validatorStake(uint256 validatorId)
        external
        view
        returns (uint256);

    /// @notice Allows to unstake the staked tokens on the stakeManager.
    /// @param validatorId validator id.
    function unstakeClaim(uint256 validatorId) external;

    /// @notice Allows to update the signer pubkey
    /// @param _validatorId validator id
    /// @param _signerPubkey update signer public key
    function updateSigner(uint256 _validatorId, bytes memory _signerPubkey)
        external;

    /// @notice Allows to claim the heimdall fees.
    /// @param _accumFeeAmount accumulated fees amount
    /// @param _index index
    /// @param _proof proof
    function claimFee(
        uint256 _accumFeeAmount,
        uint256 _index,
        bytes memory _proof
    ) external;

    /// @notice Allows to update the commision rate of a validator
    /// @param _validatorId operator id
    /// @param _newCommissionRate commission rate
    function updateCommissionRate(
        uint256 _validatorId,
        uint256 _newCommissionRate
    ) external;

    /// @notice Allows to unjail a validator.
    /// @param _validatorId id of the validator that is to be unjailed
    function unjail(uint256 _validatorId) external;

    /// @notice Returns a withdrawal delay.
    function withdrawalDelay() external view returns (uint256);

    /// @notice Transfers amount from delegator
    function delegationDeposit(
        uint256 validatorId,
        uint256 amount,
        address delegator
    ) external returns (bool);

    function epoch() external view returns (uint256);

    enum Status {
        Inactive,
        Active,
        Locked,
        Unstaked
    }

    struct Validator {
        uint256 amount;
        uint256 reward;
        uint256 activationEpoch;
        uint256 deactivationEpoch;
        uint256 jailTime;
        address signer;
        address contractAddress;
        Status status;
        uint256 commissionRate;
        uint256 lastCommissionUpdate;
        uint256 delegatorsReward;
        uint256 delegatedAmount;
        uint256 initialRewardPerStake;
    }

    function validators(uint256 _index)
        external
        view
        returns (Validator memory);

    /// @notice Returns the address of the nft contract
    function NFTContract() external view returns (address);

    /// @notice Returns the validator accumulated rewards on stake manager.
    function validatorReward(uint256 validatorId)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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