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

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./KeepToken.sol";
import "./TokenGrant.sol";
import "./StakeDelegatable.sol";
import "./TokenStaking.sol";
import "./libraries/RolesLookup.sol";
import "./utils/BytesLib.sol";
import "./TokenSender.sol";

/// @title StakingPortBacker
/// @notice Provides additional liquidity from the primary token supply for
/// token owners staking on the previous staking contract version and letting
/// them to stake on the new staking contract version without having to wait
/// for the entire undelegation period to unlock their tokens.
///
/// It lets the Keep team to make an amount of KEEP tokens available to
/// temporarily stake on behalf of a token owner, provided that they have those
/// same tokens currently locked up in the old staking contract. Undelegation of
/// all tokens in the new staking contract would be blocked until the
/// temporarily-staked tokens provided by the Keep team are repaid by the token
/// owner.
///
/// The expected mode of usage for users who have already staked on the old
/// contract is to:
/// 1. Copy stake.
/// 2. Undelegate from the old staking contract.
/// 3. Operate as normal on the new staking contract.
/// 4. Once the old staking contract's undelegated balance is available for
/// recovery, recover it and use the recovered tokens to repay the
/// StakingPortBacker contract.
contract StakingPortBacker is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using BytesLib for bytes;
    using RolesLookup for address payable;

    event StakeCopied(
        address indexed owner,
        address indexed operator,
        uint256 value
    );
    event StakePaidBack(
        address indexed owner,
        address indexed operator
    );
    event TokensWithdrawn(uint256 amount);

    /// @notice The maximum allowed time for the token owner to repay the
    /// delegation backed by tokens from this contract. After this time, the
    /// owner of the contract can undelegate and recover not paid back
    /// delegations.
    uint256 public constant maxAllowedBackingDuration = 7776000; // ~3 months

    IERC20 public keepToken;
    TokenGrant internal tokenGrant;
    StakeDelegatable public oldStakingContract;
    TokenStaking public newStakingContract;

    struct CopiedStake {
        address owner;
        uint256 amount;
        uint256 timestamp;
        bool paidBack;
    }

    mapping(address => bool) public allowedOperators; // operator -> allowed to copy?
    mapping(address => CopiedStake) public copiedStakes; // operator -> copied stake info

    constructor(
        IERC20 _keepToken,
        TokenGrant _tokenGrant,
        StakeDelegatable _oldStakingContract,
        TokenStaking _newStakingContract
    ) public {
        keepToken = _keepToken;
        tokenGrant = _tokenGrant;
        oldStakingContract = _oldStakingContract;
        newStakingContract = _newStakingContract;
    }

    /// @notice Lets the owner of the contract to register operator from staking
    /// relationships that will be allowed to use the token supply provided by
    /// this contract.
    /// @dev The reason for explicitly listing which relationships are allowed
    /// to use the supply is to avoid a situation when someone stakes on the old
    /// contract later, after deploying the new staking contract version, just
    /// to drain the supply from this contract.
    /// @param operator The operator from the staking relationship on the old
    /// staking contract that will be allowed to use the token supply provided
    /// by this contract.
    function allowOperator(address operator) public onlyOwner {
        allowedOperators[operator] = true;
    }

    /// @notice Lets the owner of the contract to register operators from
    /// staking relationships that will be allowed to use the token supply
    /// provided by this contract.
    /// @dev The reason for explicitly listing which relationships are allowed
    /// to use the supply is to avoid a situation when someone stakes on the old
    /// contract later, after deploying the new staking contract version, just
    /// to drain the supply from this contract.
    /// @param operators Array of operator addresses from the staking
    /// relationships on the old staking contract that will be allowed to use
    /// the token supply provided by this contract.
    function allowOperators(address[] memory operators) public onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            allowOperator(operators[i]);
        }
    }

    /// @notice Copies staking relationship from the old token staking contract
    /// to the new staking contract. Only the owner of the relationship can copy
    /// it to the new staking contract, the relationship can only be copied once,
    /// and undelegation must not be complete on that relationship.
    /// Operator, beneficiary, authorizer, and stake amount will be the same
    /// as in the original delegation. Until the delegation is repaid, this
    /// contract is the owner of the delegation on the new staking contract.
    /// @param operator The operator from the staking relationship on the old
    /// staking contract that should be copied to the new staking contract.
    function copyStake(address operator) public {
        uint256 oldStakeBalance = oldStakingContract.balanceOf(operator);
        require(oldStakeBalance > 0, "No stake on the old staking contract");
        require(copiedStakes[operator].amount == 0, "Stake already copied");
        require(allowedOperators[operator], "Operator not allowed");

        // Get the delegation data from the old TokenStaking contract.
        (address delegationOwner, bytes memory delegationData) = getDelegation(
            operator
        );

        if (delegationOwner != msg.sender) {
            // Sender is not the owner of the relationship, but it is possible
            // it is grantee or managed grantee. We can't rely on
            // TokenGrant.granteesToOperators because we need to ensure the
            // relationship between msg.sender and the specific staking contract
            // (the instance from which we are migrating). The only option is to
            // use TokenGrant.grantStakes.
            (
                uint256 grantId,
                address stakingContract,
                address grantee
            ) = getGrantDelegation(operator);
            require(
                stakingContract == address(oldStakingContract),
                "Unexpected grant staking contract"
            );
            require(
                msg.sender == grantee ||
                msg.sender.isManagedGranteeForGrant(grantId, tokenGrant),
                "Not authorized"
            );
        }

        copiedStakes[operator] = CopiedStake(
            msg.sender,
            oldStakeBalance,
            block.timestamp,
            false
        );

        TokenSender(address(keepToken)).approveAndCall(
            address(newStakingContract),
            oldStakeBalance,
            delegationData
        );

        emit StakeCopied(msg.sender, operator, oldStakeBalance);
    }

    /// @notice Used by the original staking relationship owner to pay back for
    /// the delegation. Once the delegation is paid back, the staking relationship
    /// ownership on the new staking contract is transferred to the owner of the
    /// delegation in the old staking contract version.
    /// @param from The owner of the tokens who approved them to transfer.
    /// It has to be the owner of the original relationship.
    /// @param value Approved amount for the transfer. It has to be the same
    /// as the amount of tokens in the original staking relationship at the
    /// moment when this relationship was copied to the new staking contract.
    /// @param token KEEP token contract address.
    /// @param extraData ABI-encoded operator address from the staking
    /// relationship that is repaid.
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes memory extraData
    ) public {
        require(token == address(keepToken), "Not a KEEP token");
        require(extraData.length == 32, "Corrupted input data");
        address operator = abi.decode(extraData, (address));

        CopiedStake memory stake = copiedStakes[operator];
        require(stake.amount > 0, "Stake not copied for the operator");
        require(!stake.paidBack, "Already paid back");
        require(from == stake.owner, "Not authorized to pay back");
        require(value == stake.amount, "Unexpected amount");

        // Transfer tokens to this contract.
        keepToken.safeTransferFrom(from, address(this), value);
        copiedStakes[operator].paidBack = true;

        newStakingContract.transferStakeOwnership(operator, stake.owner);

        emit StakePaidBack(stake.owner, operator);
    }

    /// @notice Undelegates stake on the new staking contract from the provided
    /// operator.
    /// @param operator The operator address.
    function undelegate(address operator) public {
        CopiedStake memory stake = copiedStakes[operator];
        require(
            stake.owner == msg.sender || operator == msg.sender,
            "Not authorized"
        );
        newStakingContract.undelegate(operator);
    }

    /// @notice Force-undelegates stake on the new staking contract from the
    /// provided operator. Used by the owner of this contract to undelegate
    /// stake if the delegation has not been paid back on time.
    /// @param operator The operator address.
    function forceUndelegate(address operator) public onlyOwner {
        CopiedStake memory stake = copiedStakes[operator];
        require(
            stake.timestamp.add(maxAllowedBackingDuration) < block.timestamp,
            "Maximum allowed backing duration not exceeded yet"
        );
        newStakingContract.undelegate(operator);
    }

    /// @notice Recovers stake on the new staking contract from the provided
    /// operator.
    /// @param operator The operator address.
    function recoverStake(address operator) public {
        newStakingContract.recoverStake(operator);
    }

    /// @notice Allows the contract owner to withdraw tokens from the balance
    /// the contract has available to back stake copying.
    /// @param amount The amount of tokens that should be withdrawn.
    function withdraw(uint256 amount) public onlyOwner {
        keepToken.safeTransfer(owner(), amount);
        emit TokensWithdrawn(amount);
    }

    function getDelegation(address operator) internal view returns (
        address delegationOwner,
        bytes memory delegationData
    ) {
        delegationOwner = oldStakingContract.ownerOf(operator);
        address beneficiary = oldStakingContract.beneficiaryOf(operator);
        address authorizer = oldStakingContract.authorizerOf(operator);
        delegationData = abi.encodePacked(beneficiary, operator, authorizer);
    }

    function getGrantDelegation(address operator) internal view returns(
        uint256 grantId,
        address stakingContract,
        address grantee
    ) {
        // Preliminary check for user's convenience. For non-existing delegations
        // getGrantStakeDetails reverts with no clear message.
        require(
            address(tokenGrant.grantStakes(operator)) != address(0),
            "No grant delegated for the operator"
        );
        (grantId,,stakingContract) = tokenGrant.getGrantStakeDetails(operator);
        (,,,,, grantee) = tokenGrant.getGrant(grantId);
    }
}