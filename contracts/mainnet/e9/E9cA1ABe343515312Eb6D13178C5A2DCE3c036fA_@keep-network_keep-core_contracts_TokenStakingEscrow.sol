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

import "./libraries/grant/UnlockingSchedule.sol";
import "./utils/BytesLib.sol";
import "./KeepToken.sol";
import "./utils/BytesLib.sol";
import "./TokenGrant.sol";
import "./ManagedGrant.sol";
import "./TokenSender.sol";

/// @title TokenStakingEscrow
/// @notice Escrow lets the staking contract to deposit undelegated, granted
/// tokens and either withdraw them based on the grant unlocking schedule or
/// re-delegate them to another operator.
/// @dev The owner of TokenStakingEscrow is TokenStaking contract and only owner
/// can deposit. This contract works with an assumption that operator is unique
/// in the scope of `TokenStaking`, that is, no more than one delegation in the
/// `TokenStaking` can be done do the given operator ever. Even if the previous
/// delegation ended, operator address cannot be reused.
contract TokenStakingEscrow is Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using BytesLib for bytes;
    using UnlockingSchedule for uint256;

    event Deposited(
        address indexed operator,
        uint256 indexed grantId,
        uint256 amount
    );
    event DepositRedelegated(
        address indexed previousOperator,
        address indexed newOperator,
        uint256 indexed grantId,
        uint256 amount
    );
    event DepositWithdrawn(
        address indexed operator,
        address indexed grantee,
        uint256 amount
    );
    event RevokedDepositWithdrawn(
        address indexed operator,
        address indexed grantManager,
        uint256 amount
    );
    event EscrowAuthorized(
        address indexed grantManager,
        address escrow
    );

    IERC20 public keepToken;
    TokenGrant public tokenGrant;

    struct Deposit {
        uint256 grantId;
        uint256 amount;
        uint256 withdrawn;
        uint256 redelegated;
    }

    // operator address -> KEEP deposit
    mapping(address => Deposit) internal deposits;

    // Other escrows authorized by grant manager. Grantee may request to migrate
    // tokens to another authorized escrow.
    // grant manager -> escrow -> authorized?
    mapping(address => mapping (address => bool)) internal authorizedEscrows;

    constructor(
        KeepToken _keepToken,
        TokenGrant _tokenGrant
    ) public {
        keepToken = _keepToken;
        tokenGrant = _tokenGrant;
    }

    /// @notice receiveApproval accepts deposits from staking contract and
    /// stores them in the escrow by the operator address from which they were
    /// undelegated. Function expects operator address and grant identifier to
    /// be passed as ABI-encoded information in extraData. Grant with the given
    /// identifier has to exist.
    /// @param from Address depositing tokens - it has to be the address of
    /// TokenStaking contract owning TokenStakingEscrow.
    /// @param value The amount of KEEP tokens deposited.
    /// @param token The address of KEEP token contract.
    /// @param extraData ABI-encoded data containing operator address (32 bytes)
    /// and grant ID (32 bytes).
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes memory extraData
    ) public {
        require(IERC20(token) == keepToken, "Not a KEEP token");
        require(msg.sender == token, "KEEP token is not the sender");
        require(extraData.length == 64, "Unexpected data length");

        (address operator, uint256 grantId) = abi.decode(
            extraData, (address, uint256)
        );
        receiveDeposit(from, value, operator, grantId);
    }

    /// @notice Redelegates deposit or part of the deposit to another operator.
    /// Uses the same staking contract as the original delegation.
    /// @param previousOperator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    /// @dev Only grantee is allowed to call this function. For managed grant,
    /// caller has to be the managed grantee.
    /// @param amount Amount of tokens to delegate.
    /// @param extraData Data for stake delegation. This byte array must have
    /// the following values concatenated:
    /// - Beneficiary address (20 bytes)
    /// - Operator address (20 bytes)
    /// - Authorizer address (20 bytes)
    function redelegate(
        address previousOperator,
        uint256 amount,
        bytes memory extraData
    ) public {
        require(extraData.length == 60, "Corrupted delegation data");

        Deposit memory deposit = deposits[previousOperator];

        uint256 grantId = deposit.grantId;
        address newOperator = extraData.toAddress(20);
        require(isGrantee(msg.sender, grantId), "Not authorized");
        require(getAmountRevoked(grantId) == 0, "Grant revoked");
        require(
            availableAmount(previousOperator) >= amount,
            "Insufficient balance"
        );
        require(
            !hasDeposit(newOperator),
            "Redelegating to previously used operator is not allowed"
        );

        deposits[previousOperator].redelegated = deposit.redelegated.add(amount);

        TokenSender(address(keepToken)).approveAndCall(
            owner(), // TokenStaking contract associated with the escrow
            amount,
            abi.encodePacked(extraData, grantId)
        );

        emit DepositRedelegated(
            previousOperator,
            newOperator,
            grantId,
            amount
        );
    }

    /// @notice Returns true if there is a deposit for the given operator in
    /// the escrow. Otherwise, returns false.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function hasDeposit(address operator) public view returns (bool) {
        return depositedAmount(operator) > 0;
    }

    /// @notice Returns the currently available amount deposited in the escrow
    /// that may or may not be currently withdrawable. The available amount
    /// is the amount initially deposited minus the amount withdrawn and
    /// redelegated so far from that deposit.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function availableAmount(address operator) public view returns (uint256) {
        Deposit memory deposit = deposits[operator];
        return deposit.amount.sub(deposit.withdrawn).sub(deposit.redelegated);
    }

    /// @notice Returns the total amount deposited in the escrow after
    /// undelegating it from the provided operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositedAmount(address operator) public view returns (uint256) {
        return deposits[operator].amount;
    }

    /// @notice Returns grant ID for the amount deposited in the escrow after
    /// undelegating it from the provided operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositGrantId(address operator) public view returns (uint256) {
        return deposits[operator].grantId;
    }

    /// @notice Returns the amount withdrawn so far from the value deposited
    /// in the escrow contract after undelegating it from the provided operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositWithdrawnAmount(address operator) public view returns (uint256) {
        return deposits[operator].withdrawn;
    }

    /// @notice Returns the total amount redelegated so far from the value
    /// deposited in the escrow contract after undelegating it from the provided
    /// operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositRedelegatedAmount(address operator) public view returns (uint256) {
        return deposits[operator].redelegated;
    }

    /// @notice Returns the currently withdrawable amount that was previously
    /// deposited in the escrow after undelegating it from the provided operator.
    /// Tokens are unlocked based on their grant unlocking schedule.
    /// Function returns 0 for non-existing deposits and revoked grants if they
    /// have been revoked before they fully unlocked.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdrawable(address operator) public view returns (uint256) {
        Deposit memory deposit = deposits[operator];

        // Staked tokens can be only withdrawn by grantee for non-revoked grant
        // assuming that grant has not fully unlocked before it's been
        // revoked.
        //
        // It is not possible for the escrow to determine the number of tokens
        // it should return to the grantee of a revoked grant given different
        // possible staking contracts and staking policies.
        //
        // If the entire grant unlocked before it's been reverted, escrow
        // lets to withdraw the entire deposited amount.
        if (getAmountRevoked(deposit.grantId) == 0) {
            (
                uint256 duration,
                uint256 start,
                uint256 cliff
            ) = getUnlockingSchedule(deposit.grantId);

            uint256 unlocked = now.getUnlockedAmount(
                deposit.amount,
                duration,
                start,
                cliff
            );

            if (deposit.withdrawn.add(deposit.redelegated) < unlocked) {
                return unlocked.sub(deposit.withdrawn).sub(deposit.redelegated);
            }
        }

        return 0;
    }

    /// @notice Withdraws currently unlocked tokens deposited in the escrow
    /// after undelegating them from the provided operator. Only grantee or
    /// operator can call this function. Important: this function can not be
    /// called for a `ManagedGrant` grantee. This may lead to locking tokens.
    /// For `ManagedGrant`, please use `withdrawToManagedGrantee` instead.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdraw(address operator) public {
        Deposit memory deposit = deposits[operator];
        address grantee = getGrantee(deposit.grantId);

        // Make sure this function is not called for a managed grant.
        // If called for a managed grant, tokens could be locked there.
        // Better be safe than sorry.
        (bool success, ) = address(this).call(
            abi.encodeWithSignature("getManagedGrantee(address)", grantee)
        );
        require(!success, "Can not be called for managed grant");

        require(
            msg.sender == grantee || msg.sender == operator,
            "Only grantee or operator can withdraw"
        );

        withdraw(deposit, operator, grantee);
    }

    /// @notice Withdraws currently unlocked tokens deposited in the escrow
    /// after undelegating them from the provided operator. Only grantee or
    /// operator can call this function. This function works only for
    /// `ManagedGrant` grantees. For a standard grant, please use `withdraw`
    /// instead.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdrawToManagedGrantee(address operator) public {
        Deposit memory deposit = deposits[operator];
        address managedGrant = getGrantee(deposit.grantId);
        address grantee = getManagedGrantee(managedGrant);

        require(
            msg.sender == grantee || msg.sender == operator,
            "Only grantee or operator can withdraw"
        );

        withdraw(deposit, operator, grantee);
    }

    /// @notice Migrates all available tokens to another authorized escrow.
    /// Can be requested only by grantee.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    /// @param receivingEscrow Escrow to which tokens should be migrated.
    /// @dev The receiving escrow needs to accept deposits from this escrow, at
    /// least for the period of migration.
    function migrate(
        address operator,
        address receivingEscrow
    ) public {
        Deposit memory deposit = deposits[operator];
        require(isGrantee(msg.sender, deposit.grantId), "Not authorized");

        address grantManager = getGrantManager(deposit.grantId);
        require(
            authorizedEscrows[grantManager][receivingEscrow],
            "Escrow not authorized"
        );

        uint256 amountLeft = availableAmount(operator);
        deposits[operator].withdrawn = deposit.withdrawn.add(amountLeft);
        TokenSender(address(keepToken)).approveAndCall(
            receivingEscrow,
            amountLeft,
            abi.encode(operator, deposit.grantId)
        );
    }

    /// @notice Withdraws the entire amount that is still deposited in the
    /// escrow in case the grant has been revoked. Anyone can call this function
    /// and the entire amount is transferred back to the grant manager.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function withdrawRevoked(address operator) public {
        Deposit memory deposit = deposits[operator];

        require(
            getAmountRevoked(deposit.grantId) > 0,
            "No revoked tokens to withdraw"
        );

        address grantManager = getGrantManager(deposit.grantId);
        withdrawRevoked(deposit, operator, grantManager);
    }

    /// @notice Used by grant manager to authorize another escrows for
    // funds migration.
    function authorizeEscrow(address anotherEscrow) public {
        require(
            anotherEscrow != address(0x0),
            "Escrow address can't be zero"
        );
        authorizedEscrows[msg.sender][anotherEscrow] = true;
        emit EscrowAuthorized(msg.sender, anotherEscrow);
    }

    /// @notice Resolves the final grantee of ManagedGrant contract. If the
    /// provided address is not a ManagedGrant contract, function reverts.
    /// @param managedGrant Address of the managed grant contract.
    function getManagedGrantee(
        address managedGrant
    ) public view returns(address) {
        ManagedGrant grant = ManagedGrant(managedGrant);
        return grant.grantee();
    }

    function receiveDeposit(
        address from,
        uint256 value,
        address operator,
        uint256 grantId
    ) internal {
        // This contract works with an assumption that operator is unique.
        // This is fine as long as the staking contract works with the same
        // assumption so we are limiting deposits to the staking contract only.
        require(from == owner(), "Only owner can deposit");
        require(
            getAmountGranted(grantId) > 0,
            "Grant with this ID does not exist"
        );

        require(
            !hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );

        keepToken.safeTransferFrom(from, address(this), value);
        deposits[operator] = Deposit(grantId, value, 0, 0);

        emit Deposited(operator, grantId, value);
    }

    function isGrantee(
        address maybeGrantee,
        uint256 grantId
    ) internal returns (bool) {
        // Let's check the simplest case first - standard grantee.
        // If the given address is set as a grantee for grant with the given ID,
        // we return true.
        address grantee = getGrantee(grantId);
        if (maybeGrantee == grantee) {
            return true;
        }

        // If the given address is not a standard grantee, there is still
        // a chance that address is a managed grantee. We are calling
        // getManagedGrantee that will cast the grantee to ManagedGrant and try
        // to call getGrantee() function. If this call returns non-zero address,
        // it means we are dealing with a ManagedGrant.
        (, bytes memory result) = address(this).call(
            abi.encodeWithSignature("getManagedGrantee(address)", grantee)
        );
        if (result.length == 0) {
            return false;
        }
        // At this point we know we are dealing with a ManagedGrant, so the last
        // thing we need to check is whether the managed grantee of that grant
        // is the grantee address passed as a parameter.
        address managedGrantee = abi.decode(result, (address));
        return maybeGrantee == managedGrantee;
    }

    function withdraw(
        Deposit memory deposit,
        address operator,
        address grantee
    ) internal {
        uint256 amount = withdrawable(operator);

        deposits[operator].withdrawn = deposit.withdrawn.add(amount);
        keepToken.safeTransfer(grantee, amount);

        emit DepositWithdrawn(operator, grantee, amount);
    }

    function withdrawRevoked(
        Deposit memory deposit,
        address operator,
        address grantManager
    ) internal {
        uint256 amount = availableAmount(operator);
        deposits[operator].withdrawn = amount;
        keepToken.safeTransfer(grantManager, amount);

        emit RevokedDepositWithdrawn(operator, grantManager, amount);
    }

    function getAmountGranted(uint256 grantId) internal view returns (
        uint256 amountGranted
    ) {
        (amountGranted,,,,,) = tokenGrant.getGrant(grantId);
    }

    function getAmountRevoked(uint256 grantId) internal view returns (
        uint256 amountRevoked
    ) {
        (,,,amountRevoked,,) = tokenGrant.getGrant(grantId);
    }

    function getUnlockingSchedule(uint256 grantId) internal view returns (
        uint256 duration,
        uint256 start,
        uint256 cliff
    ) {
        (,duration,start,cliff,) = tokenGrant.getGrantUnlockingSchedule(grantId);
    }

    function getGrantee(uint256 grantId) internal view returns (
        address grantee
    ) {
        (,,,,,grantee) = tokenGrant.getGrant(grantId);
    }

    function getGrantManager(uint256 grantId) internal view returns (
        address grantManager
    ) {
        (grantManager,,,,) = tokenGrant.getGrantUnlockingSchedule(grantId);
    }
}