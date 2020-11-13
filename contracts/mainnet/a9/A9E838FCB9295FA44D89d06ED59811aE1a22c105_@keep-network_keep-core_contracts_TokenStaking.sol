/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./StakeDelegatable.sol";
import "./libraries/staking/MinimumStakeSchedule.sol";
import "./libraries/staking/GrantStaking.sol";
import "./libraries/staking/Locks.sol";
import "./libraries/staking/TopUps.sol";
import "./utils/PercentUtils.sol";
import "./utils/BytesLib.sol";
import "./Authorizations.sol";
import "./TokenStakingEscrow.sol";
import "./TokenSender.sol";


/// @title TokenStaking
/// @notice A token staking contract for a specified standard ERC20Burnable token.
/// A holder of the specified token can stake delegate its tokens to this contract
/// and recover the stake after undelegation period is over.
contract TokenStaking is Authorizations, StakeDelegatable {
    using BytesLib for bytes;
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using SafeERC20 for ERC20Burnable;
    using GrantStaking for GrantStaking.Storage;
    using Locks for Locks.Storage;
    using TopUps for TopUps.Storage;

    event StakeDelegated(
        address indexed owner,
        address indexed operator
    );
    event OperatorStaked(
        address indexed operator,
        address indexed beneficiary,
        address indexed authorizer,
        uint256 value
    );
    event StakeOwnershipTransferred(
        address indexed operator,
        address indexed newOwner
    );
    event TopUpInitiated(address indexed operator, uint256 topUp);
    event TopUpCompleted(address indexed operator, uint256 newAmount);
    event Undelegated(address indexed operator, uint256 undelegatedAt);
    event RecoveredStake(address operator);
    event TokensSlashed(address indexed operator, uint256 amount);
    event TokensSeized(address indexed operator, uint256 amount);
    event StakeLocked(address indexed operator, address lockCreator, uint256 until);
    event LockReleased(address indexed operator, address lockCreator);
    event ExpiredLockReleased(address indexed operator, address lockCreator);

    uint256 public deployedAt;
    uint256 public initializationPeriod; // varies between mainnet and testnet

    ERC20Burnable internal token;
    TokenGrant internal tokenGrant;
    TokenStakingEscrow internal escrow;

    GrantStaking.Storage internal grantStaking;
    Locks.Storage internal locks;
    TopUps.Storage internal topUps;

    uint256 internal constant twoWeeks = 1209600; // [sec]
    uint256 internal constant twoMonths = 5184000; // [sec]

    // 2020-04-28; the date of deploying KEEP token.
    // TX:  0xea22d72bc7de4c82798df7194734024a1f2fd57b173d0e065864ff4e9d3dc014
    uint256 internal constant minimumStakeScheduleStart = 1588042366;

    /// @notice Creates a token staking contract for a provided Standard ERC20Burnable token.
    /// @param _token KEEP token contract.
    /// @param _tokenGrant KEEP token grant contract.
    /// @param _escrow Escrow dedicated for this staking contract.
    /// @param _registry Keep contract registry contract.
    /// @param _initializationPeriod To avoid certain attacks on work selection, recently created
    /// operators must wait for a specific period of time before being eligible for work selection.
    constructor(
        ERC20Burnable _token,
        TokenGrant _tokenGrant,
        TokenStakingEscrow _escrow,
        KeepRegistry _registry,
        uint256 _initializationPeriod
    ) Authorizations(_registry) public {
        token = _token;
        tokenGrant = _tokenGrant;
        escrow = _escrow;
        registry = _registry;
        initializationPeriod = _initializationPeriod;
        deployedAt = block.timestamp;
    }

    /// @notice Returns minimum amount of KEEP that allows sMPC cluster client to
    /// participate in the Keep network. Expressed as number with 18-decimal places.
    /// Initial minimum stake is higher than the final and lowered periodically based
    /// on the amount of steps and the length of the minimum stake schedule in seconds.
    function minimumStake() public view returns (uint256) {
        return MinimumStakeSchedule.current(minimumStakeScheduleStart);
    }

    /// @notice Returns the current value of the undelegation period.
    /// The staking contract guarantees that an undelegated operator’s stakes
    /// will stay locked for a period of time after undelegation, and thus
    /// available as collateral for any work the operator is engaged in.
    /// The undelegation period is two weeks for the first two months and
    /// two months after that.
    function undelegationPeriod() public view returns(uint256) {
        return block.timestamp < deployedAt.add(twoMonths) ? twoWeeks : twoMonths;
    }

    /// @notice Receives approval of token transfer and stakes the approved
    /// amount or adds the approved amount to an existing delegation (a “top-up”).
    /// In case of a top-up, it is expected that the operator stake is not
    /// undelegated and that the top-up is performed from the same source of
    /// tokens as the initial delegation. That is, if the tokens were delegated
    /// from a grant, top-up has to be performed from the same grant. If the
    /// delegation was done using liquid tokens, only liquid tokens from the
    /// same owner can be used to top-up the stake.
    /// Top-up can not be cancelled so it is important to be careful with the
    /// amount of KEEP added to the stake.
    /// @dev Requires that the provided token contract be the same one linked to
    /// this contract.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _value Approved amount for the transfer and stake.
    /// @param _token Token contract address.
    /// @param _extraData Data for stake delegation. This byte array must have
    /// the following values concatenated:
    /// - Beneficiary address (20 bytes), ignored for a top-up
    /// - Operator address (20 bytes)
    /// - Authorizer address (20 bytes), ignored for a top-up
    /// - Grant ID (32 bytes) - required only when called by TokenStakingEscrow
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory _extraData
    ) public {
        require(ERC20Burnable(_token) == token, "Unrecognized token");
        require(_extraData.length >= 60, "Corrupted delegation data");

        // Transfer tokens to this contract.
        token.safeTransferFrom(_from, address(this), _value);

        address operator = _extraData.toAddress(20);
        // See if there is an existing delegation for this operator...
        if (operators[operator].packedParams.getCreationTimestamp() == 0) {
            // If there is no existing delegation, delegate tokens using
            // beneficiary and authorizer passed in _extraData.
            delegate(_from, _value, operator, _extraData);
        } else {
            // If there is an existing delegation, top-up the stake.
            topUp(_from, _value, operator, _extraData);
        }
    }

    /// @notice Delegates tokens to a new operator using beneficiary and
    /// authorizer passed in _extraData parameter.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _value Approved amount for the transfer and stake.
    /// @param _operator The new operator address.
    /// @param _extraData Data for stake delegation as passed to receiveApproval.
    function delegate(
        address _from,
        uint256 _value,
        address _operator,
        bytes memory _extraData
    ) internal {
        require(_value >= minimumStake(), "Less than the minimum stake");
        
        address payable beneficiary = address(uint160(_extraData.toAddress(0)));
        address authorizer = _extraData.toAddress(40);

        operators[_operator] = Operator(
            OperatorParams.pack(_value, block.timestamp, 0),
            _from,
            beneficiary,
            authorizer
        );

        grantStaking.tryCapturingDelegationData(
            tokenGrant,
            address(escrow),
            _from,
            _operator,
            _extraData
        );

        emit StakeDelegated(_from, _operator);
        emit OperatorStaked(_operator, beneficiary, authorizer, _value);
    }

    /// @notice Performs top-up to an existing operator. Tokens added during
    /// stake initialization period are immediatelly added to the stake and
    /// stake initialization timer is reset to the current block. Tokens added
    /// in a top-up after the stake initialization period is over are not
    /// included in the operator stake until the initialization period for
    /// a top-up passes and top-up is committed. Operator must not have the stake
    /// undelegated. It is expected that the top-up is done from the same source
    /// of tokens as the initial delegation. That is, if the tokens were
    /// delegated from a grant, top-up has to be performed from the same grant.
    /// If the delegation was done using liquid tokens, only liquid tokens from
    /// the same owner can be used to top-up the stake.
    /// Top-up can not be cancelled so it is important to be careful with the
    /// amount of KEEP added to the stake.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _value Approved amount for the transfer and top-up to
    /// an existing stake.
    /// @param _operator The new operator address.
    /// @param _extraData Data for stake delegation as passed to receiveApproval
    function topUp(
        address _from,
        uint256 _value,
        address _operator,
        bytes memory _extraData
    ) internal {
        // Top-up comes from a grant if it's been initiated from TokenGrantStake
        // contract or if it's been initiated from TokenStakingEscrow by
        // redelegation.
        bool isFromGrant = address(tokenGrant.grantStakes(_operator)) == _from ||
            address(escrow) == _from;

        if (grantStaking.hasGrantDelegated(_operator)) {
            // Operator has grant delegated. We need to see if the top-up
            // is performed also from a grant.
            require(isFromGrant, "Must be from a grant");
            // If it is from a grant, we need to make sure it's from the same
            // grant as the original delegation. We do not want to mix unlocking
            // schedules.
            uint256 previousGrantId = grantStaking.getGrantForOperator(_operator);
            (, uint256 grantId) = grantStaking.tryCapturingDelegationData(
                tokenGrant, address(escrow), _from, _operator, _extraData
            );
            require(grantId == previousGrantId, "Not the same grant");
        } else {
            // Operator has no grant delegated. We need to see if the top-up
            // is performed from liquid tokens of the same owner.
            require(!isFromGrant, "Must not be from a grant");
            require(operators[_operator].owner == _from, "Not the same owner");
        }

        uint256 operatorParams = operators[_operator].packedParams;
        if (!_isInitialized(operatorParams)) {
            // If the stake is not yet initialized, we add tokens immediately
            // but we also reset stake initialization time counter.
            operators[_operator].packedParams = topUps.instantComplete(
                _value, _operator, operatorParams, escrow
            );
        } else {
            // If the stake is initialized, we do NOT add tokens immediately.
            // We initiate the top-up and will add tokens to the stake only
            // after the initialization period for a top-up passes.
            topUps.initiate(_value, _operator, operatorParams, escrow);
        }
    }

    /// @notice Commits pending top-up for the provided operator. If the top-up
    /// did not pass the initialization period, the function fails.
    /// @param _operator The operator with a pending top-up that is getting
    /// committed.
    function commitTopUp(address _operator) public {
        operators[_operator].packedParams = topUps.commit(
            _operator,
            operators[_operator].packedParams,
            initializationPeriod
        );
    }

    /// @notice Cancels stake of tokens within the operator initialization period
    /// without being subjected to the token lockup for the undelegation period.
    /// This can be used to undo mistaken delegation to the wrong operator address.
    /// @param _operator Address of the stake operator.
    function cancelStake(address _operator) public {
        address owner = operators[_operator].owner;
        require(
            msg.sender == owner ||
            msg.sender == _operator ||
            grantStaking.canUndelegate(_operator, tokenGrant),
            "Not authorized"
        );
        uint256 operatorParams = operators[_operator].packedParams;

        require(
            !_isInitialized(operatorParams),
            "Initialized stake"
        );

        uint256 amount = operatorParams.getAmount();
        operators[_operator].packedParams = operatorParams.setAmount(0);

        transferOrDeposit(owner, _operator, amount);
    }

    /// @notice Undelegates staked tokens. You will be able to recover your stake by calling
    /// `recoverStake()` with operator address once undelegation period is over.
    /// @param _operator Address of the stake operator.
    function undelegate(address _operator) public {
        undelegateAt(_operator, block.timestamp);
    }

    /// @notice Set an undelegation time for staked tokens.
    /// Undelegation will begin at the specified timestamp.
    /// You will be able to recover your stake by calling
    /// `recoverStake()` with operator address once undelegation period is over.
    /// @param _operator Address of the stake operator.
    /// @param _undelegationTimestamp The timestamp undelegation is to start at.
    function undelegateAt(
        address _operator,
        uint256 _undelegationTimestamp
    ) public {
        require(
            msg.sender == _operator ||
            msg.sender == operators[_operator].owner ||
            grantStaking.canUndelegate(_operator, tokenGrant),
            "Not authorized"
        );
        uint256 oldParams = operators[_operator].packedParams;
        require(
            _undelegationTimestamp >= block.timestamp &&
            _undelegationTimestamp > oldParams.getCreationTimestamp().add(initializationPeriod),
            "Invalid timestamp"
        );
        uint256 existingUndelegationTimestamp = oldParams.getUndelegationTimestamp();
        require(
            // Undelegation not in progress OR
            existingUndelegationTimestamp == 0 ||
            // Undelegating sooner than previously set time OR
            existingUndelegationTimestamp > _undelegationTimestamp ||
            // We have already checked above that msg.sender is owner, grantee,
            // or operator. Only owner and grantee are eligible to postpone the
            // delegation so it is enough if we exclude operator here.
            msg.sender != _operator,
            "Operator may not postpone"
        );
        operators[_operator].packedParams = oldParams.setUndelegationTimestamp(
            _undelegationTimestamp
        );
        emit Undelegated(_operator, _undelegationTimestamp);
    }

    /// @notice Recovers staked tokens and transfers them back to the owner.
    /// Recovering tokens can only be performed when the operator finished
    /// undelegating.
    /// @param _operator Operator address.
    function recoverStake(address _operator) public {
        uint256 operatorParams = operators[_operator].packedParams;
        require(
            operatorParams.getUndelegationTimestamp() != 0,
            "Not undelegated"
        );
        require(
            _isUndelegatingFinished(operatorParams),
            "Still undelegating"
        );
        require(
            !isStakeLocked(_operator),
            "Locked stake"
        );

        uint256 amount = operatorParams.getAmount();

        // If there is a pending top-up, force-commit it before returning tokens.
        amount = amount.add(topUps.cancel(_operator));

        operators[_operator].packedParams = operatorParams.setAmount(0);
        transferOrDeposit(operators[_operator].owner, _operator, amount);

        emit RecoveredStake(_operator);
    }

    /// @notice Gets stake delegation info for the given operator.
    /// @param _operator Operator address.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return createdAt The time when the stake has been delegated.
    /// @return undelegatedAt The time when undelegation has been requested.
    /// If undelegation has not been requested, 0 is returned.
    function getDelegationInfo(address _operator)
    public view returns (uint256 amount, uint256 createdAt, uint256 undelegatedAt) {
        return operators[_operator].packedParams.unpack();
    }

    /// @notice Locks given operator stake for the specified duration.
    /// Locked stake may not be recovered until the lock expires or is released,
    /// even if the normal undelegation period has passed.
    /// Only previously authorized operator contract can lock the stake.
    /// @param operator Operator address.
    /// @param duration Lock duration in seconds.
    function lockStake(
        address operator,
        uint256 duration
    ) public onlyApprovedOperatorContract(msg.sender) {
        require(
            isAuthorizedForOperator(operator, msg.sender),
            "Not authorized"
        );

        uint256 operatorParams = operators[operator].packedParams;

        require(
            _isInitialized(operatorParams),
            "Inactive stake"
        );
        require(
            !_isUndelegating(operatorParams),
            "Undelegating stake"
        );

        locks.lockStake(operator, duration);
    }

    /// @notice Removes a lock the caller had previously placed on the operator.
    /// @dev Only for operator contracts.
    /// To remove expired or disabled locks, use `releaseExpiredLocks`.
    /// The authorization check ensures that the caller must have been able
    /// to place a lock on the operator sometime in the past.
    /// We don't need to check for current approval status of the caller
    /// because unlocking stake cannot harm the operator
    /// nor interfere with other operator contracts.
    /// Therefore even disabled operator contracts may freely unlock stake.
    /// @param operator Operator address.
    function unlockStake(
        address operator
    ) public {
        require(
            isAuthorizedForOperator(operator, msg.sender),
            "Not authorized"
        );
        locks.releaseLock(operator);
    }

    /// @notice Removes the lock of the specified operator contract
    /// if the lock has expired or the contract has been disabled.
    /// @dev Necessary for removing locks placed by contracts
    /// that have been disabled by the panic button.
    /// Also applicable to prevent inadvertent DoS of `recoverStake`
    /// if too many operator contracts have failed to clean up their locks.
    function releaseExpiredLock(
        address operator,
        address operatorContract
    ) public {
        locks.releaseExpiredLock(operator, operatorContract, address(this));
    }

    /// @notice Check whether the operator has any active locks
    /// that haven't expired yet
    /// and whose creators aren't disabled by the panic button.
    function isStakeLocked(address operator) public view returns (bool) {
        return locks.isStakeLocked(operator, address(this));
    }

    /// @notice Get the locks placed on the operator.
    /// @return creators The addresses of operator contracts
    /// that have placed a lock on the operator.
    /// @return expirations The expiration times
    /// of the locks placed on the operator.
    function getLocks(address operator)
        public
        view
        returns (address[] memory creators, uint256[] memory expirations) {
        return locks.getLocks(operator);
    }

    /// @notice Slash provided token amount from every member in the misbehaved
    /// operators array and burn 100% of all the tokens.
    /// @param amountToSlash Token amount to slash from every misbehaved operator.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function slash(uint256 amountToSlash, address[] memory misbehavedOperators)
        public
        onlyApprovedOperatorContract(msg.sender) {

        uint256 totalAmountToBurn;
        address authoritySource = getAuthoritySource(msg.sender);
        for (uint i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(authorizations[authoritySource][operator], "Not authorized");

            uint256 operatorParams = operators[operator].packedParams;
            require(
                _isInitialized(operatorParams),
                "Inactive stake"
            );

            require(
                !_isStakeReleased(operator, operatorParams, msg.sender),
                "Stake is released"
            );

            uint256 currentAmount = operatorParams.getAmount();

            if (currentAmount < amountToSlash) {
                totalAmountToBurn = totalAmountToBurn.add(currentAmount);
                operators[operator].packedParams = operatorParams.setAmount(0);
                emit TokensSlashed(operator, currentAmount);
            } else {
                totalAmountToBurn = totalAmountToBurn.add(amountToSlash);
                operators[operator].packedParams = operatorParams.setAmount(
                    currentAmount.sub(amountToSlash)
                );
                emit TokensSlashed(operator, amountToSlash);
            }
        }

        token.burn(totalAmountToBurn);
    }

    /// @notice Seize provided token amount from every member in the misbehaved
    /// operators array. The tattletale is rewarded with 5% of the total seized
    /// amount scaled by the reward adjustment parameter and the rest 95% is burned.
    /// @param amountToSeize Token amount to seize from every misbehaved operator.
    /// @param rewardMultiplier Reward adjustment in percentage. Min 1% and 100% max.
    /// @param tattletale Address to receive the 5% reward.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function seize(
        uint256 amountToSeize,
        uint256 rewardMultiplier,
        address tattletale,
        address[] memory misbehavedOperators
    ) public onlyApprovedOperatorContract(msg.sender) {
        uint256 totalAmountToBurn;
        address authoritySource = getAuthoritySource(msg.sender);
        for (uint i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(authorizations[authoritySource][operator], "Not authorized");

            uint256 operatorParams = operators[operator].packedParams;
            require(
                _isInitialized(operatorParams),
                "Inactive stake"
            );

            require(
                !_isStakeReleased(operator, operatorParams, msg.sender),
                "Stake is released"
            );

            uint256 currentAmount = operatorParams.getAmount();

            if (currentAmount < amountToSeize) {
                totalAmountToBurn = totalAmountToBurn.add(currentAmount);
                operators[operator].packedParams = operatorParams.setAmount(0);
                emit TokensSeized(operator, currentAmount);
            } else {
                totalAmountToBurn = totalAmountToBurn.add(amountToSeize);
                operators[operator].packedParams = operatorParams.setAmount(
                    currentAmount.sub(amountToSeize)
                );
                emit TokensSeized(operator, amountToSeize);
            }
        }

        uint256 tattletaleReward = (totalAmountToBurn.percent(5)).percent(rewardMultiplier);

        token.safeTransfer(tattletale, tattletaleReward);
        token.burn(totalAmountToBurn.sub(tattletaleReward));
    }

    /// @notice Allows the current staking relationship owner to transfer the
    /// ownership to someone else.
    /// @param operator Address of the stake operator.
    /// @param newOwner Address of the new staking relationship owner.
    function transferStakeOwnership(address operator, address newOwner) public {
        require(msg.sender == operators[operator].owner, "Not authorized");
        operators[operator].owner = newOwner;
        emit StakeOwnershipTransferred(operator, newOwner);
    }

    /// @notice Gets the eligible stake balance of the specified address.
    /// An eligible stake is a stake that passed the initialization period
    /// and is not currently undelegating. Also, the operator had to approve
    /// the specified operator contract.
    ///
    /// Operator with a minimum required amount of eligible stake can join the
    /// network and participate in new work selection.
    ///
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    /// @return an uint256 representing the eligible stake balance.
    function eligibleStake(
        address _operator,
        address _operatorContract
    ) public view returns (uint256 balance) {
        uint256 operatorParams = operators[_operator].packedParams;
        // To be eligible for work selection, the operator must:
        // - have the operator contract authorized
        // - have the stake initialized
        // - must not be undelegating; keep in mind the `undelegatedAt` may be
        // set to a time in the future, to schedule undelegation in advance.
        // In this case the operator is still eligible until the timestamp
        // `undelegatedAt`.
        if (
            isAuthorizedForOperator(_operator, _operatorContract) &&
            _isInitialized(operatorParams) &&
            !_isUndelegating(operatorParams)
        ) {
            balance = operatorParams.getAmount();
        }
    }

    /// @notice Gets the active stake balance of the specified address.
    /// An active stake is a stake that passed the initialization period,
    /// and may be in the process of undelegation
    /// but has not been released yet,
    /// either because the undelegation period is not over,
    /// or because the operator contract has an active lock on the operator.
    /// Also, the operator had to approve the specified operator contract.
    ///
    /// The difference between eligible stake is that active stake does not make
    /// the operator eligible for work selection but it may be still finishing
    /// earlier work until the stake is released.
    /// Operator with a minimum required
    /// amount of active stake can join the network but cannot be selected to any
    /// new work.
    ///
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    /// @return an uint256 representing the eligible stake balance.
    function activeStake(
        address _operator,
        address _operatorContract
    ) public view returns (uint256 balance) {
        uint256 operatorParams = operators[_operator].packedParams;
        if (
            isAuthorizedForOperator(_operator, _operatorContract) &&
            _isInitialized(operatorParams) &&
            !_isStakeReleased(
                _operator,
                operatorParams,
                _operatorContract
            )
        ) {
            balance = operatorParams.getAmount();
        }
    }

    /// @notice Checks if the specified account has enough active stake to become
    /// network operator and that the specified operator contract has been
    /// authorized for potential slashing.
    ///
    /// Having the required minimum of active stake makes the operator eligible
    /// to join the network. If the active stake is not currently undelegating,
    /// operator is also eligible for work selection.
    ///
    /// @param staker Staker's address
    /// @param operatorContract Operator contract's address
    /// @return True if has enough active stake to participate in the network,
    /// false otherwise.
    function hasMinimumStake(
        address staker,
        address operatorContract
    ) public view returns(bool) {
        return activeStake(staker, operatorContract) >= minimumStake();
    }

    /// @notice Is the operator with the given params initialized
    function _isInitialized(uint256 _operatorParams)
        internal view returns (bool) {
        return block.timestamp > _operatorParams.getCreationTimestamp().add(initializationPeriod);
    }

    /// @notice Is the operator with the given params undelegating
    function _isUndelegating(uint256 _operatorParams)
        internal view returns (bool) {
        uint256 undelegatedAt = _operatorParams.getUndelegationTimestamp();
        return (undelegatedAt != 0) && (block.timestamp > undelegatedAt);
    }

    /// @notice Has the operator with the given params finished undelegating
    function _isUndelegatingFinished(uint256 _operatorParams)
        internal view returns (bool) {
        uint256 undelegatedAt = _operatorParams.getUndelegationTimestamp();
        return (undelegatedAt != 0) && (block.timestamp > undelegatedAt.add(undelegationPeriod()));
    }

    /// @notice Get whether the operator's stake is released
    /// as far as the operator contract is concerned.
    /// If the operator contract has a lock on the operator,
    /// the operator's stake is be released when the lock expires.
    /// Otherwise the stake is released when the operator finishes undelegating.
    function _isStakeReleased(
        address _operator,
        uint256 _operatorParams,
        address _operatorContract
    ) internal view returns (bool) {
        return _isUndelegatingFinished(_operatorParams) &&
            locks.isStakeReleased(_operator, _operatorContract);
    }

    function transferOrDeposit(
        address _owner,
        address _operator,
        uint256 _amount
    ) internal {
        if (grantStaking.hasGrantDelegated(_operator)) {
            // For tokens staked from a grant, transfer them to the escrow.
            TokenSender(address(token)).approveAndCall(
                address(escrow),
                _amount,
                abi.encode(_operator, grantStaking.getGrantForOperator(_operator))
            );
        } else {
            // For liquid tokens staked, transfer them straight to the owner.
            token.safeTransfer(_owner, _amount);
        }
    }
}
