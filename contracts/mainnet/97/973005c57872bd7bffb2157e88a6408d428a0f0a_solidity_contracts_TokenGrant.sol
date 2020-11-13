pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./libraries/grant/UnlockingSchedule.sol";
import "./utils/BytesLib.sol";
import "./utils/AddressArrayUtils.sol";
import "./TokenStaking.sol";
import "./TokenGrantStake.sol";
import "./GrantStakingPolicy.sol";


/// @title TokenGrant
/// @notice A token grant contract for a specified standard ERC20Burnable token.
/// Has additional functionality to stake delegate/undelegate token grants.
/// Tokens are granted to the grantee via unlocking scheme and can be
/// withdrawn gradually based on the unlocking schedule cliff and unlocking duration.
/// Optionally grant can be revoked by the token grant manager.
contract TokenGrant {
    using SafeMath for uint256;
    using UnlockingSchedule for uint256;
    using SafeERC20 for ERC20Burnable;
    using BytesLib for bytes;
    using AddressArrayUtils for address[];

    event TokenGrantCreated(uint256 id);
    event TokenGrantWithdrawn(uint256 indexed grantId, uint256 amount);
    event TokenGrantStaked(uint256 indexed grantId, uint256 amount, address operator);
    event TokenGrantRevoked(uint256 id);

    event StakingContractAuthorized(address indexed grantManager, address stakingContract);

    struct Grant {
        address grantManager; // Token grant manager.
        address grantee; // Address to which granted tokens are going to be withdrawn.
        uint256 revokedAt; // Timestamp at which grant was revoked by the grant manager.
        uint256 revokedAmount; // The number of tokens revoked from the grantee.
        uint256 revokedWithdrawn; // The number of tokens returned to the grant creator.
        bool revocable; // Whether grant manager can revoke the grant.
        uint256 amount; // Amount of tokens to be granted.
        uint256 duration; // Duration in seconds of the period in which the granted tokens will unlock.
        uint256 start; // Timestamp at which the linear unlocking schedule will start.
        uint256 cliff; // Timestamp before which no tokens will be unlocked.
        uint256 withdrawn; // Amount that was withdrawn to the grantee.
        uint256 staked; // Amount that was staked by the grantee.
        GrantStakingPolicy stakingPolicy;
    }

    uint256 public numGrants;

    ERC20Burnable public token;

    // Staking contracts authorized by the given grant manager.
    // grant manager -> staking contract -> authorized?
    mapping(address => mapping (address => bool)) internal stakingContracts;

    // Token grants.
    mapping(uint256 => Grant) public grants;

    // Token grants stakes.
    mapping(address => TokenGrantStake) public grantStakes;

    // Mapping of token grant IDs per particular address
    // involved in a grant as a grantee or as a grant manager.
    mapping(address => uint256[]) public grantIndices;

    // Token grants balances. Sum of all granted tokens to a grantee.
    // This includes granted tokens that are already unlocked and
    // available to be withdrawn to the grantee
    mapping(address => uint256) public balances;

    // Mapping of operator addresses per particular grantee address.
    mapping(address => address[]) public granteesToOperators;

    /// @notice Creates a token grant contract for a provided Standard ERC20Burnable token.
    /// @param _tokenAddress address of a token that will be linked to this contract.
    constructor(address _tokenAddress) public {
        require(_tokenAddress != address(0x0), "Token address can't be zero.");
        token = ERC20Burnable(_tokenAddress);
    }

    /// @notice Used by grant manager to authorize staking contract with the given
    /// address.
    function authorizeStakingContract(address _stakingContract) public {
        require(
            _stakingContract != address(0x0),
            "Staking contract address can't be zero"
        );
        stakingContracts[msg.sender][_stakingContract] = true;
        emit StakingContractAuthorized(msg.sender, _stakingContract);
    }

    /// @notice Gets the amount of granted tokens to the specified address.
    /// @param _owner The address to query the grants balance of.
    /// @return An uint256 representing the grants balance owned by the passed address.
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice Gets the stake balance of the specified address.
    /// @param _address The address to query the balance of.
    /// @return An uint256 representing the amount staked by the passed address.
    function stakeBalanceOf(address _address) public view returns (uint256 balance) {
        for (uint i = 0; i < grantIndices[_address].length; i++) {
            uint256 id = grantIndices[_address][i];
            balance += grants[id].staked;
        }
        return balance;
    }

    /// @notice Gets grant by ID. Returns only basic grant data.
    /// If you need unlocking schedule for the grant you must call `getGrantUnlockingSchedule()`
    /// This is to avoid Ethereum `Stack too deep` issue described here:
    /// https://forum.ethereum.org/discussion/2400/error-stack-too-deep-try-removing-local-variables
    /// @param _id ID of the token grant.
    /// @return amount The amount of tokens the grant provides.
    /// @return withdrawn The amount of tokens that have already been withdrawn
    ///                   from the grant.
    /// @return staked The amount of tokens that have been staked from the grant.
    /// @return revoked A boolean indicating whether the grant has been revoked,
    ///                 which is to say that it is no longer unlocking.
    /// @return grantee The grantee of grant.
    function getGrant(uint256 _id) public view returns (
        uint256 amount,
        uint256 withdrawn,
        uint256 staked,
        uint256 revokedAmount,
        uint256 revokedAt,
        address grantee
    ) {
        return (
            grants[_id].amount,
            grants[_id].withdrawn,
            grants[_id].staked,
            grants[_id].revokedAmount,
            grants[_id].revokedAt,
            grants[_id].grantee
        );
    }

    /// @notice Gets grant unlocking schedule by grant ID.
    /// @param _id ID of the token grant.
    /// @return grantManager The address designated as the manager of the grant,
    ///                      which is the only address that can revoke this grant.
    /// @return duration The duration, in seconds, during which the tokens will
    ///                  unlocking linearly.
    /// @return start The start time, as a timestamp comparing to `now`.
    /// @return cliff The timestamp, before which none of the tokens in the grant
    ///               will be unlocked, and after which a linear amount based on
    ///               the time elapsed since the start will be unlocked.
    /// @return policy The address of the grant's staking policy.
    function getGrantUnlockingSchedule(
        uint256 _id
    ) public view returns (
        address grantManager,
        uint256 duration,
        uint256 start,
        uint256 cliff,
        address policy
    ) {
        return (
            grants[_id].grantManager,
            grants[_id].duration,
            grants[_id].start,
            grants[_id].cliff,
            address(grants[_id].stakingPolicy)
        );
    }

    /// @notice Gets grant ids of the specified address.
    /// @param _granteeOrGrantManager The address to query.
    /// @return An uint256 array of grant IDs.
    function getGrants(address _granteeOrGrantManager) public view returns (uint256[] memory) {
        return grantIndices[_granteeOrGrantManager];
    }

    /// @notice Gets operator addresses of the specified grantee address.
    /// @param grantee The grantee address.
    /// @return An array of all operators for a given grantee.
    function getGranteeOperators(address grantee) public view returns (address[] memory) {
        return granteesToOperators[grantee];
    }

    /// @notice Gets grant stake details of the given operator.
    /// @param operator The operator address.
    /// @return grantId ID of the token grant.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return stakingContract The address of staking contract.
    function getGrantStakeDetails(address operator) public view returns (uint256 grantId, uint256 amount, address stakingContract) {
        return grantStakes[operator].getDetails();
    }


    /// @notice Receives approval of token transfer and creates a token grant with a unlocking
    /// schedule where balance withdrawn to the grantee gradually in a linear fashion until
    /// start + duration. By then all of the balance will have unlocked.
    /// @param _from The owner of the tokens who approved them to transfer.
    /// @param _amount Approved amount for the transfer to create token grant.
    /// @param _token Token contract address.
    /// @param _extraData This byte array must have the following values ABI encoded:
    /// grantManager (address) Address of the grant manager.
    /// grantee (address) Address of the grantee.
    /// duration (uint256) Duration in seconds of the unlocking period.
    /// start (uint256) Timestamp at which unlocking will start.
    /// cliffDuration (uint256) Duration in seconds of the cliff;
    ///               no tokens will be unlocked until the time `start + cliff`.
    /// revocable (bool) Whether the token grant is revocable or not (1 or 0).
    /// stakingPolicy (address) Address of the staking policy for the grant.
    function receiveApproval(address _from, uint256 _amount, address _token, bytes memory _extraData) public {
        require(ERC20Burnable(_token) == token, "Token contract must be the same one linked to this contract.");
        require(_amount <= token.balanceOf(_from), "Sender must have enough amount.");
        (address _grantManager,
         address _grantee,
         uint256 _duration,
         uint256 _start,
         uint256 _cliffDuration,
         bool _revocable,
         address _stakingPolicy) = abi.decode(
             _extraData,
             (address, address, uint256, uint256, uint256, bool, address)
        );

        require(_grantee != address(0), "Grantee address can't be zero.");
        require(
            _cliffDuration <= _duration,
            "Unlocking cliff duration must be less or equal total unlocking duration."
        );

        require(_stakingPolicy != address(0), "Staking policy can't be zero.");

        uint256 id = numGrants++;
        grants[id] = Grant(
            _grantManager,
            _grantee,
            0, 0, 0,
            _revocable,
            _amount,
            _duration,
            _start,
            _start.add(_cliffDuration),
            0, 0,
            GrantStakingPolicy(_stakingPolicy)
        );

        // Maintain a record to make it easier to query grants by grant manager.
        grantIndices[_from].push(id);

        // Maintain a record to make it easier to query grants by grantee.
        grantIndices[_grantee].push(id);

        token.safeTransferFrom(_from, address(this), _amount);

        // Maintain a record of the unlocked amount
        balances[_grantee] = balances[_grantee].add(_amount);
        emit TokenGrantCreated(id);
    }

    /// @notice Withdraws Token grant amount to grantee.
    /// @dev Transfers unlocked tokens of the token grant to grantee.
    /// @param _id Grant ID.
    function withdraw(uint256 _id) public {
        uint256 amount = withdrawable(_id);
        require(amount > 0, "Grant available to withdraw amount should be greater than zero.");

        // Update withdrawn amount.
        grants[_id].withdrawn = grants[_id].withdrawn.add(amount);

        // Update grantee grants balance.
        balances[grants[_id].grantee] = balances[grants[_id].grantee].sub(amount);

        // Transfer tokens from this contract balance to the grantee token balance.
        token.safeTransfer(grants[_id].grantee, amount);

        emit TokenGrantWithdrawn(_id, amount);
    }

    /// @notice Calculates and returns unlocked grant amount.
    /// @dev Calculates token grant amount that has already unlocked,
    /// including any tokens that have already been withdrawn by the grantee as well
    /// as any tokens that are available to withdraw but have not yet been withdrawn.
    /// @param _id Grant ID.
    function unlockedAmount(uint256 _id) public view returns (uint256) {
        Grant storage grant = grants[_id];
        return (grant.revokedAt != 0)
            // Grant revoked -> return what is remaining
            ? grant.amount.sub(grant.revokedAmount)
            // Not revoked -> calculate the unlocked amount normally
            : now.getUnlockedAmount(
                grant.amount,
                grant.duration,
                grant.start,
                grant.cliff
            );
    }

    /// @notice Calculates withdrawable granted amount.
    /// @dev Calculates the amount that has already unlocked but hasn't been withdrawn yet.
    /// @param _id Grant ID.
    function withdrawable(uint256 _id) public view returns (uint256) {
        uint256 unlocked = unlockedAmount(_id);
        uint256 withdrawn = grants[_id].withdrawn;
        uint256 staked = grants[_id].staked;

        if (withdrawn.add(staked) >= unlocked) {
            return 0;
        } else {
            return unlocked.sub(withdrawn).sub(staked);
        }
    }

    /// @notice Allows the grant manager to revoke the grant.
    /// @dev Granted tokens that are already unlocked (releasable amount)
    /// remain in the grant so grantee can still withdraw them
    /// the rest are revoked and withdrawable by token grant manager.
    /// @param _id Grant ID.
    function revoke(uint256 _id) public {
        require(grants[_id].grantManager == msg.sender, "Only grant manager can revoke.");
        require(grants[_id].revocable, "Grant must be revocable in the first place.");
        require(grants[_id].revokedAt == 0, "Grant must not be already revoked.");

        uint256 unlockedAmount = unlockedAmount(_id);
        uint256 revokedAmount = grants[_id].amount.sub(unlockedAmount);
        grants[_id].revokedAt = now;
        grants[_id].revokedAmount = revokedAmount;

        // Update grantee's grants balance.
        balances[grants[_id].grantee] = balances[grants[_id].grantee].sub(revokedAmount);
        emit TokenGrantRevoked(_id);
    }

    /// @notice Allows the grant manager to withdraw revoked tokens.
    /// @dev Will withdraw as many of the revoked tokens as possible
    /// without pushing the grant contract into a token deficit.
    /// If the grantee has staked more tokens than the unlocked amount,
    /// those tokens will remain in the grant until undelegated and returned,
    /// after which they can be withdrawn by calling `withdrawRevoked` again.
    /// @param _id Grant ID.
    function withdrawRevoked(uint256 _id) public {
        Grant storage grant = grants[_id];
        require(
            grant.grantManager == msg.sender,
            "Only grant manager can withdraw revoked tokens."
        );
        uint256 revoked = grant.revokedAmount;
        uint256 revokedWithdrawn = grant.revokedWithdrawn;
        require(revokedWithdrawn < revoked, "All revoked tokens withdrawn.");

        uint256 revokedRemaining = revoked.sub(revokedWithdrawn);

        uint256 totalAmount = grant.amount;
        uint256 staked = grant.staked;
        uint256 granteeWithdrawn = grant.withdrawn;
        uint256 remainingPresentInGrant =
            totalAmount.sub(staked).sub(revokedWithdrawn).sub(granteeWithdrawn);

        require(remainingPresentInGrant > 0, "No revoked tokens withdrawable.");

        uint256 amountToWithdraw = remainingPresentInGrant < revokedRemaining
            ? remainingPresentInGrant
            : revokedRemaining;
        token.safeTransfer(msg.sender, amountToWithdraw);
        grant.revokedWithdrawn += amountToWithdraw;
    }

    /// @notice Stake token grant.
    /// @dev Stakable token grant amount is determined
    /// by the grant's staking policy.
    /// @param _id Grant Id.
    /// @param _stakingContract Address of the staking contract.
    /// @param _amount Amount to stake.
    /// @param _extraData Data for stake delegation. This byte array must have
    /// the following values concatenated:
    /// - Beneficiary address (20 bytes)
    /// - Operator address (20 bytes)
    /// - Authorizer address (20 bytes)
    function stake(uint256 _id, address _stakingContract, uint256 _amount, bytes memory _extraData) public {
        require(grants[_id].grantee == msg.sender, "Only grantee of the grant can stake it.");
        require(grants[_id].revokedAt == 0, "Revoked grant can not be staked");
        require(
            stakingContracts[grants[_id].grantManager][_stakingContract],
            "Provided staking contract is not authorized."
        );

        // Expecting 60 bytes _extraData for stake delegation.
        require(_extraData.length == 60, "Stake delegation data must be provided.");
        address operator = _extraData.toAddress(20);

        // Calculate available amount. Amount of unlocked tokens minus what user already withdrawn and staked.
        require(_amount <= availableToStake(_id), "Must have available granted amount to stake.");

        // Keep staking record.
        TokenGrantStake grantStake = new TokenGrantStake(
            address(token),
            _id,
            _stakingContract
        );
        grantStakes[operator] = grantStake;
        granteesToOperators[grants[_id].grantee].push(operator);
        grants[_id].staked += _amount;

        token.transfer(address(grantStake), _amount);

        // Staking contract expects 40 bytes _extraData for stake delegation.
        // 20 bytes beneficiary's address + 20 bytes operator's address.
        grantStake.stake(_amount, _extraData);
        emit TokenGrantStaked(_id, _amount, operator);
    }

    ///  @notice Returns the amount of tokens available for staking from the grant.
    /// The stakeable amount is determined by the staking policy of the grant.
    /// If the grantee has withdrawn some tokens
    /// or the policy returns an erroneously high value,
    /// the stakeable amount is limited to the number of tokens remaining.
    /// @param _grantId Identifier of the grant
    function availableToStake(uint256 _grantId) public view returns (uint256) {
        Grant storage grant = grants[_grantId];
        // Revoked grants cannot be staked.
        // If the grant isn't revoked, the number of revoked tokens is 0.
        if (grant.revokedAt != 0) { return 0; }
        uint256 amount = grant.amount;
        uint256 withdrawn = grant.withdrawn;
        uint256 remaining = amount.sub(withdrawn);
        uint256 stakeable = grant.stakingPolicy.getStakeableAmount(
            now,
            amount,
            grant.duration,
            grant.start,
            grant.cliff,
            withdrawn
        );
        // Clamp the stakeable amount to what is left in the grant
        // in the case of a malfunctioning staking policy.
        if (stakeable > remaining) {
            stakeable = remaining;
        }

        return stakeable.sub(grant.staked);
    }

    /// @notice Cancels delegation within the operator initialization period
    /// without being subjected to the stake lockup for the undelegation period.
    /// This can be used to undo mistaken delegation to the wrong operator address.
    /// @param _operator Address of the stake operator.
    function cancelStake(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(
            msg.sender == _operator || msg.sender == grants[grantId].grantee,
            "Only operator or grantee can cancel the delegation."
        );

        uint256 returned = grantStake.cancelStake();
        grants[grantId].staked = grants[grantId].staked.sub(returned);
    }

    /// @notice Undelegate the token grant.
    /// @param _operator Operator of the stake.
    function undelegate(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(
            msg.sender == _operator || msg.sender == grants[grantId].grantee,
            "Only operator or grantee can undelegate."
        );

        grantStake.undelegate();
    }

    /// @notice Force cancellation of a revoked grant's stake.
    /// Can be used by the grant manager
    /// to immediately withdraw tokens back into the grant,
    /// from an operator still within the initialization period.
    /// These tokens can then be withdrawn
    /// if some revoked tokens haven't been withdrawn yet.
    function cancelRevokedStake(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(
            grants[grantId].revokedAt != 0,
            "Grant must be revoked"
        );
        require(
            msg.sender == grants[grantId].grantManager,
            "Only grant manager can force cancellation of revoked grant stake."
        );

        uint256 returned = grantStake.cancelStake();
        grants[grantId].staked = grants[grantId].staked.sub(returned);
    }

    /// @notice Force undelegation of a revoked grant's stake.
    /// @dev Can be called by the grant manager once the grant is revoked.
    /// Has to be done this way, instead of undelegating all operators when the
    /// grant is revoked, because the latter method is vulnerable to DoS via
    /// out-of-gas.
    function undelegateRevoked(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 grantId = grantStake.getGrantId();
        require(
            grants[grantId].revokedAt != 0,
            "Grant must be revoked"
        );
        require(
            msg.sender == grants[grantId].grantManager,
            "Only grant manager can force undelegation of revoked grant stake"
        );

        grantStake.undelegate();
    }

    /// @notice Recover stake of the token grant.
    /// Recovers the tokens correctly
    /// even if they were earlier recovered directly in the staking contract.
    /// @param _operator Operator of the stake.
    function recoverStake(address _operator) public {
        TokenGrantStake grantStake = grantStakes[_operator];
        uint256 returned = grantStake.recoverStake();
        uint256 grantId = grantStake.getGrantId();
        grants[grantId].staked = grants[grantId].staked.sub(returned);

        delete grantStakes[_operator];
    }
}
