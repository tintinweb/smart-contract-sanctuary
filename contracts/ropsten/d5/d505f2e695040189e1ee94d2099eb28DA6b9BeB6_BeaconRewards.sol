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

import "./KeepRegistry.sol";

/// @title AuthorityDelegator
/// @notice An operator contract can delegate authority to other operator
/// contracts by implementing the AuthorityDelegator interface.
///
/// To delegate authority,
/// the recipient of delegated authority must call `claimDelegatedAuthority`,
/// specifying the contract it wants delegated authority from.
/// The staking contract calls `delegator.__isRecognized(recipient)`
/// and if the call returns `true`,
/// the named delegator contract is set as the recipient's authority delegator.
/// Any future checks of registry approval or per-operator authorization
/// will transparently mirror the delegator's status.
///
/// Authority can be delegated recursively;
/// an operator contract receiving delegated authority
/// can recognize other operator contracts as recipients of its authority.
interface AuthorityDelegator {
    function __isRecognized(address delegatedAuthorityRecipient)
        external
        returns (bool);
}

/// @title AuthorityVerifier
/// @notice An operator contract can delegate authority to other operator
/// contracts. Entry in the registry is not updated and source contract remains
/// listed there as authorized. This interface is a verifier that support verification
/// of contract authorization in case of authority delegation from the source contract.
interface AuthorityVerifier {
    /// @notice Returns true if the given operator contract has been approved
    /// for use. The function never reverts.
    function isApprovedOperatorContract(address _operatorContract)
        external
        view
        returns (bool);
}

contract Authorizations is AuthorityVerifier {
    // Authorized operator contracts.
    mapping(address => mapping(address => bool)) internal authorizations;

    // Granters of delegated authority to operator contracts.
    // E.g. keep factories granting delegated authority to keeps.
    // `delegatedAuthority[keep] = factory`
    mapping(address => address) internal delegatedAuthority;

    // Registry contract with a list of approved operator contracts and upgraders.
    KeepRegistry internal registry;

    modifier onlyApprovedOperatorContract(address operatorContract) {
        require(
            isApprovedOperatorContract(operatorContract),
            "Operator contract unapproved"
        );
        _;
    }

    constructor(KeepRegistry _registry) public {
        registry = _registry;
    }

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address);

    /// @notice Authorizes operator contract to access staked token balance of
    /// the provided operator. Can only be executed by stake operator authorizer.
    /// Contracts using delegated authority
    /// cannot be authorized with `authorizeOperatorContract`.
    /// Instead, authorize `getAuthoritySource(_operatorContract)`.
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    function authorizeOperatorContract(
        address _operator,
        address _operatorContract
    ) public onlyApprovedOperatorContract(_operatorContract) {
        require(
            authorizerOf(_operator) == msg.sender,
            "Not operator authorizer"
        );
        require(
            getAuthoritySource(_operatorContract) == _operatorContract,
            "Delegated authority used"
        );
        authorizations[_operatorContract][_operator] = true;
    }

    /// @notice Checks if operator contract has access to the staked token balance of
    /// the provided operator.
    /// @param _operator address of stake operator.
    /// @param _operatorContract address of operator contract.
    function isAuthorizedForOperator(
        address _operator,
        address _operatorContract
    ) public view returns (bool) {
        return authorizations[getAuthoritySource(_operatorContract)][_operator];
    }

    /// @notice Grant the sender the same authority as `delegatedAuthoritySource`
    /// @dev If `delegatedAuthoritySource` is an approved operator contract
    /// and recognizes the claimant, this relationship will be recorded in
    /// `delegatedAuthority`. Later, the claimant can slash, seize, place locks etc.
    /// on operators that have authorized the `delegatedAuthoritySource`.
    /// If the `delegatedAuthoritySource` is disabled with the panic button,
    /// any recipients of delegated authority from it will also be disabled.
    function claimDelegatedAuthority(address delegatedAuthoritySource)
        public
        onlyApprovedOperatorContract(delegatedAuthoritySource)
    {
        require(
            AuthorityDelegator(delegatedAuthoritySource).__isRecognized(
                msg.sender
            ),
            "Unrecognized claimant"
        );
        delegatedAuthority[msg.sender] = delegatedAuthoritySource;
    }

    /// @notice Checks if the operator contract is authorized in the registry.
    /// If the contract uses delegated authority it checks authorization of the
    /// source contract.
    /// @param _operatorContract address of operator contract.
    /// @return True if operator contract is approved, false if operator contract
    /// has not been approved or if it was disabled by the panic button.
    function isApprovedOperatorContract(address _operatorContract)
        public
        view
        returns (bool)
    {
        return
            registry.isApprovedOperatorContract(
                getAuthoritySource(_operatorContract)
            );
    }

    /// @notice Get the source of the operator contract's authority.
    /// If the contract uses delegated authority,
    /// returns the original source of the delegated authority.
    /// If the contract doesn't use delegated authority,
    /// returns the contract itself.
    /// Authorize `getAuthoritySource(operatorContract)`
    /// to grant `operatorContract` the authority to penalize an operator.
    function getAuthoritySource(address operatorContract)
        public
        view
        returns (address)
    {
        address delegatedAuthoritySource = delegatedAuthority[operatorContract];
        if (delegatedAuthoritySource == address(0)) {
            return operatorContract;
        }
        return getAuthoritySource(delegatedAuthoritySource);
    }
}

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

pragma solidity ^0.5.17;

import "./Rewards.sol";
import "./KeepRandomBeaconOperator.sol";
import "./TokenStaking.sol";

/// @title KEEP Random Beacon Signer Subsidy Rewards
/// @notice Contract distributing KEEP rewards to Random Beacon signers based
/// on the defined reward schedule.
///
/// The amount of KEEP to be distributed is determined by funding the contract,
/// and additional KEEP can be added at any time.
///
/// When an interval is over, it will be allocated a percentage of the remaining
/// unallocated rewards based on its weight, and adjusted by the number of groups
/// created in the interval if the quota is not met.
///
/// The adjustment for not meeting the group quota is a percentage that equals
/// the percentage of the quota that was met; if the number of groups created is
/// 80% of the quota then 80% of the base reward will be allocated for the
/// interval.
///
/// Any unallocated rewards will stay in the unallocated rewards pool,
/// to be allocated for future intervals. Intervals past the initially defined
/// schedule have a weight of 100%, meaning that all remaining unallocated
/// rewards will be allocated to the interval.
///
/// Groups can receive rewards once the interval they were created in is over,
/// and the group has been marked as stale.
/// There is no time limit to receiving rewards, nor is there need to wait for
/// all groups from the interval to be marked as stale.
/// Calling `receiveReward` automatically allocates the rewards for the interval
/// the specified group was created in and all previous intervals.
///
/// If a group is terminated, that fact can be reported to the reward contract.
/// Reporting a terminated group returns its allocated reward to the pool of
/// unallocated rewards.
contract BeaconRewards is Rewards {
    // Weights of the 24 reward intervals assigned over
    // 24 * beaconTermLength days.
    uint256[] internal beaconIntervalWeights = [
        4,
        8,
        10,
        12,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15,
        15
    ];

    // Beacon genesis date, 2020-09-24, is the first interval start.
    // https://etherscan.io/tx/0xe2e8ab5631473a3d7d8122ce4853c38f5cc7d3dcbfab3607f6b27a7ef3b86da2
    uint256 internal constant beaconFirstIntervalStart = 1600905600;

    // Each interval is 30 days long.
    uint256 internal constant beaconTermLength = 30 days;

    // There has to be at least 2 groups per interval to meet the group quota
    // and distribute the full reward for the given interval.
    uint256 internal constant minimumBeaconGroupsPerInterval = 2;

    KeepRandomBeaconOperator operatorContract;
    TokenStaking tokenStaking;

    constructor(
        address _token,
        address _operatorContract,
        address _stakingContract
    )
        public
        Rewards(
            _token,
            beaconFirstIntervalStart,
            beaconIntervalWeights,
            beaconTermLength,
            minimumBeaconGroupsPerInterval
        )
    {
        operatorContract = KeepRandomBeaconOperator(_operatorContract);
        tokenStaking = TokenStaking(_stakingContract);
    }

    /// @notice Sends the reward for a group to the group member beneficiaries.
    /// @param groupIndex Index of the group to receive a reward.
    function receiveReward(uint256 groupIndex) public {
        receiveReward(bytes32(groupIndex));
    }

    /// @notice Stakers can receive KEEP rewards from multiple groups of their choice
    /// in one transaction to reduce total cost comparing to single calls for rewards.
    /// It is a caller responsibility to determine the cost and consumed gas when
    /// receiving rewards from multiple groups.
    /// @param groupIndices An array of group indices.
    function receiveRewards(uint256[] memory groupIndices) public {
        uint256 len = groupIndices.length;
        bytes32[] memory bytes32identifiers = new bytes32[](len);
        for (uint256 i = 0; i < groupIndices.length; i++) {
            bytes32identifiers[i] = bytes32(groupIndices[i]);
        }
        receiveRewards(bytes32identifiers);
    }

    /// @notice Checks if the group is eligible to receive a reward.
    /// Group is eligible to receive a reward if it has been marked as stale
    /// and rewards has not been claimed yet.
    /// @param groupIndex Index of the group to check.
    function eligibleForReward(uint256 groupIndex) public view returns (bool) {
        return eligibleForReward(bytes32(groupIndex));
    }

    /// @notice Report that the group was terminated, and return its allocated
    /// rewards to the unallocated pool.
    /// @param groupIndex Index of the terminated group.
    function reportTermination(uint256 groupIndex) public {
        reportTermination(bytes32(groupIndex));
    }

    /// @notice Report about the terminated groups in batch. All the allocated
    /// rewards in these groups will be returned to the unallocated pool.
    /// @param groupIndices An array of group indices.
    function reportTerminations(uint256[] memory groupIndices) public {
        uint256 len = groupIndices.length;
        bytes32[] memory bytes32identifiers = new bytes32[](len);
        for (uint256 i = 0; i < groupIndices.length; i++) {
            bytes32identifiers[i] = bytes32(groupIndices[i]);
        }
        reportTerminations(bytes32identifiers);
    }

    /// @notice Checks if the group is terminated and thus its rewards can be
    /// returned to the unallocated pool by calling `reportTermination`.
    /// @param groupIndex Index of the potentially terminated group.
    function isTerminated(uint256 groupIndex) public view returns (bool) {
        return eligibleButTerminated(bytes32(groupIndex));
    }

    function _getKeepCount() internal view returns (uint256) {
        return operatorContract.getNumberOfCreatedGroups();
    }

    function _getKeepAtIndex(uint256 i) internal view returns (bytes32) {
        return bytes32(i);
    }

    function _getCreationTime(bytes32 groupIndexBytes)
        internal
        view
        returns (uint256)
    {
        return
            operatorContract.getGroupRegistrationTime(uint256(groupIndexBytes));
    }

    function _isClosed(bytes32 groupIndexBytes) internal view returns (bool) {
        if (_isTerminated(groupIndexBytes)) {
            return false;
        }
        bytes memory groupPubkey =
            operatorContract.getGroupPublicKey(uint256(groupIndexBytes));
        return operatorContract.isStaleGroup(groupPubkey);
    }

    function _isTerminated(bytes32 groupIndexBytes)
        internal
        view
        returns (bool)
    {
        return operatorContract.isGroupTerminated(uint256(groupIndexBytes));
    }

    function _recognizedByFactory(bytes32 groupIndexBytes)
        internal
        view
        returns (bool)
    {
        return _getKeepCount() > uint256(groupIndexBytes);
    }

    function _distributeReward(bytes32 groupIndexBytes, uint256 _value)
        internal
    {
        bytes memory groupPubkey =
            operatorContract.getGroupPublicKey(uint256(groupIndexBytes));
        address[] memory members =
            operatorContract.getGroupMembers(groupPubkey);

        uint256 memberCount = members.length;
        uint256 dividend = _value.div(memberCount);

        // Only pay other members if dividend is nonzero.
        if (dividend > 0) {
            for (uint256 i = 0; i < memberCount - 1; i++) {
                token.safeTransfer(
                    tokenStaking.beneficiaryOf(members[i]),
                    dividend
                );
            }
        }

        // Transfer of dividend for the last member. Remainder might be equal to
        // zero in case of even distribution or some small number.
        uint256 remainder = _value.mod(memberCount);
        token.safeTransfer(
            tokenStaking.beneficiaryOf(members[memberCount - 1]),
            dividend.add(remainder)
        );
    }
}

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

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

/// @dev Interface expected to be implemented by contracts added as a gas price
/// oracle consumers. Consumers are notified by GasPriceOracle every time gas
/// price change is finalized by calling their refreshGasPrice function. Each
/// consumer may decide to pull the new value from the oracle immediatelly or
/// at the moment right for the consumer.
/// Consumers must be trusted contracts whose refreshGasPrice must always
/// succeed and never consume excessive gas.
interface GasPriceOracleConsumer {
    function refreshGasPrice() external;
}

/// @notice Oracle presenting the current gas price. The oracle is manually
/// updated by its owner.
contract GasPriceOracle is Ownable {
    using SafeMath for uint256;

    event GasPriceUpdated(uint256 newValue);

    uint256 public constant governanceDelay = 1 hours;

    uint256 public gasPrice;

    uint256 public newGasPrice;
    uint256 public gasPriceChangeInitiated;

    address[] public consumerContracts;

    modifier onlyAfterGovernanceDelay {
        require(gasPriceChangeInitiated > 0, "Change not initiated");
        require(
            block.timestamp.sub(gasPriceChangeInitiated) >= governanceDelay,
            "Governance delay has not elapsed"
        );
        _;
    }

    /// @notice Initialize the gas price update. Change is finalized after
    /// the governance delay elapses.
    /// @param _newGasPrice New gas price in wei.
    function beginGasPriceUpdate(uint256 _newGasPrice) public onlyOwner {
        newGasPrice = _newGasPrice;
        gasPriceChangeInitiated = block.timestamp;
    }

    /// @notice Finalizes the gas price update. Finalization may happen only
    /// after the governance delay elapses.
    function finalizeGasPriceUpdate() public onlyAfterGovernanceDelay {
        gasPrice = newGasPrice;

        newGasPrice = 0;
        gasPriceChangeInitiated = 0;

        emit GasPriceUpdated(gasPrice);

        for (uint256 i = 0; i < consumerContracts.length; i++) {
            GasPriceOracleConsumer(consumerContracts[i]).refreshGasPrice();
        }
    }

    /// @notice Adds a new consumer contract to the oracle. Consumer contract is
    /// expected to implement GasPriceOracleConsumer interface and receives
    /// a notifcation every time gas price update is finalized.
    /// @param consumerContract The new consumer contract to add to the oracle.
    function addConsumerContract(address consumerContract) public onlyOwner {
        consumerContracts.push(consumerContract);
    }

    /// @notice Removes consumer contract from the oracle by its index.
    /// @param index Index of the consumer contract to be removed.
    function removeConsumerContract(uint256 index) public onlyOwner {
        require(index < consumerContracts.length, "Invalid index");
        consumerContracts[index] = consumerContracts[
            consumerContracts.length - 1
        ];
        consumerContracts.length--;
    }

    /// @notice Returns all consumer contracts currently registered in the
    /// oracle.
    function getConsumerContracts() public view returns (address[] memory) {
        return consumerContracts;
    }
}

pragma solidity 0.5.17;

/// @title GrantStakingPolicy
/// @notice A staking policy defines the function `getStakeableAmount`
/// which calculates how many tokens may be staked from a token grant.
contract GrantStakingPolicy {
    function getStakeableAmount(
        uint256 _now,
        uint256 grantedAmount,
        uint256 duration,
        uint256 start,
        uint256 cliff,
        uint256 withdrawn
    ) public view returns (uint256);
}

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

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./TokenStaking.sol";
import "./KeepRegistry.sol";
import "./GasPriceOracle.sol";
import "./cryptography/BLS.sol";
import "./utils/AddressArrayUtils.sol";
import "./utils/PercentUtils.sol";
import "./libraries/operator/GroupSelection.sol";
import "./libraries/operator/Groups.sol";
import "./libraries/operator/DKGResultVerification.sol";
import "./libraries/operator/Reimbursements.sol";
import "./libraries/operator/DelayFactor.sol";

interface ServiceContract {
    function entryCreated(
        uint256 requestId,
        bytes calldata entry,
        address payable submitter
    ) external;

    function fundRequestSubsidyFeePool() external payable;

    function fundDkgFeePool() external payable;

    function callbackSurplusRecipient(uint256 requestId)
        external
        view
        returns (address payable);
}

/// @title KeepRandomBeaconOperator
/// @notice Keep client facing contract for random beacon security-critical operations.
/// Handles group creation and expiration, BLS signature verification and incentives.
/// The contract is not upgradeable. New functionality can be implemented by deploying
/// new versions following Keep client update and re-authorization by the stakers.
contract KeepRandomBeaconOperator is ReentrancyGuard, GasPriceOracleConsumer {
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using AddressArrayUtils for address[];
    using GroupSelection for GroupSelection.Storage;
    using Groups for Groups.Storage;
    using DKGResultVerification for DKGResultVerification.Storage;

    event OnGroupRegistered(bytes groupPubKey);
    event DkgResultSubmittedEvent(
        uint256 memberIndex,
        bytes groupPubKey,
        bytes misbehaved
    );
    event RelayEntryRequested(bytes previousEntry, bytes groupPublicKey);
    event RelayEntrySubmitted();
    event GroupSelectionStarted(uint256 newEntry);
    event GroupMemberRewardsWithdrawn(
        address indexed beneficiary,
        address operator,
        uint256 amount,
        uint256 groupIndex
    );
    event RelayEntryTimeoutReported(uint256 indexed groupIndex);
    event UnauthorizedSigningReported(uint256 indexed groupIndex);

    GroupSelection.Storage groupSelection;
    Groups.Storage groups;
    DKGResultVerification.Storage dkgResultVerification;

    address[] internal serviceContracts;

    KeepRegistry internal registry;

    TokenStaking internal stakingContract;

    GasPriceOracle internal gasPriceOracle;

    /// @dev Each signing group member reward expressed in wei.
    uint256 public groupMemberBaseReward = 1000000 * 1e9; // 1M Gwei

    /// @dev Gas price ceiling value used to calculate the gas price for reimbursement
    /// next to the actual gas price from the transaction. We use gas price
    /// ceiling to defend against malicious miner-submitters who can manipulate
    /// transaction gas price.
    uint256 public gasPriceCeiling = 60 * 1e9; // (60 Gwei = 60 * 10^9 wei)

    /// @dev Size of a group in the threshold relay.
    uint256 public groupSize = 64;

    /// @dev Minimum number of group members needed to interact according to the
    /// protocol to produce a relay entry.
    uint256 public groupThreshold = 33;

    /// @dev Time in blocks after which the next group member is eligible
    /// to submit the result.
    uint256 public resultPublicationBlockStep = 6;

    /// @dev Timeout in blocks for a relay entry to appear on the chain. Blocks
    /// are counted from the moment relay request occur.
    ///
    /// Timeout is never shorter than the time needed by clients to generate
    /// relay entry and the time it takes for the last group member to become
    /// eligible to submit the result plus at least one block to submit it.
    uint256 public relayEntryTimeout =
        groupSize.mul(resultPublicationBlockStep);

    /// @dev Gas required to verify BLS signature and produce successful relay
    /// entry. Excludes callback and DKG gas. The worst case (most expensive)
    /// scenario.
    uint256 public entryVerificationGasEstimate = 280000;

    /// @dev Gas required to submit DKG result. Excludes initiation of group selection.
    uint256 public dkgGasEstimate = 1740000;

    /// @dev Gas required to trigger DKG (starting group selection).
    uint256 public groupSelectionGasEstimate = 200000;

    /// @dev Reimbursement for the submitter of the DKG result. This value is set
    /// when a new DKG request comes to the operator contract.
    ///
    /// When submitting DKG result, the submitter is reimbursed with the actual cost
    /// and some part of the fee stored in this field may be returned to the service
    /// contract.
    uint256 public dkgSubmitterReimbursementFee;

    /// @dev Seed value used for the genesis group selection.
    /// https://www.wolframalpha.com/input/?i=pi+to+78+digits
    uint256 internal constant _genesisGroupSeed =
        31415926535897932384626433832795028841971693993751058209749445923078164062862;

    /// @dev Service contract that triggered current group selection.
    ServiceContract internal groupSelectionStarterContract;

    // current relay request data
    uint256 internal currentRequestId;
    uint256 public currentRequestStartBlock;
    uint256 public currentRequestGroupIndex;
    bytes public currentRequestPreviousEntry;
    uint256 internal currentRequestEntryVerificationAndProfitFee;
    uint256 internal currentRequestCallbackFee;
    address internal currentRequestServiceContract;

    constructor(
        address _serviceContract,
        address _tokenStaking,
        address _keepRegistry,
        address _gasPriceOracle
    ) public {
        serviceContracts.push(_serviceContract);

        stakingContract = TokenStaking(_tokenStaking);
        registry = KeepRegistry(_keepRegistry);
        gasPriceOracle = GasPriceOracle(_gasPriceOracle);

        groups.stakingContract = stakingContract;
        groups.groupActiveTime = (86400 * 14) / 15; // 14 days equivalent in 15s blocks
        groups.relayEntryTimeout = relayEntryTimeout;

        // There are 78 blocks to submit group selection tickets. To minimize
        // the submitter's cost by minimizing the number of redundant tickets
        // that are not selected into the group, the following approach is
        // recommended:
        //
        // Tickets are submitted in 11 rounds, each round taking 6 blocks.
        // As the basic principle, the number of leading zeros in the ticket
        // value is subtracted from the number of rounds to determine the round
        // the ticket should be submitted in:
        // - in round 0, tickets with 11 or more leading zeros are submitted
        // - in round 1, tickets with 10 or more leading zeros are submitted
        // (...)
        // - in round 11, tickets with no leading zeros are submitted.
        //
        // In each round, group member candidate needs to monitor tickets
        // submitted by other candidates and compare them against tickets of
        // the candidate not yet submitted to determine if continuing with
        // ticket submission still makes sense.
        //
        // After 66 blocks, there is a 12 blocks mining lag allowing all
        // outstanding ticket submissions to have a higher chance of being
        // mined before the deadline.
        groupSelection.ticketSubmissionTimeout = 6 * 11 + 12;

        groupSelection.groupSize = groupSize;

        dkgResultVerification.timeDKG = 5 * (1 + 5) + 2 * (1 + 10) + 20;
        dkgResultVerification
            .resultPublicationBlockStep = resultPublicationBlockStep;
        dkgResultVerification.groupSize = groupSize;
        dkgResultVerification.signatureThreshold =
            groupThreshold +
            (groupSize - groupThreshold) /
            2;
    }

    /// @notice Triggers group selection if there are no active groups.
    function genesis() public payable {
        // If we run into a very unlikely situation when there are no active
        // groups on the contract because of slashing and groups terminated
        // or because beacon has not been used for a very long time and all
        // groups expired, we first want to make a cleanup.
        groups.expireOldGroups();
        require(numberOfGroups() == 0, "Groups exist");
        // Cleanup after potential failed DKG
        groupSelection.finish();
        // Set latest added service contract as a group selection starter to receive any DKG fee surplus.
        groupSelectionStarterContract = ServiceContract(
            serviceContracts[serviceContracts.length.sub(1)]
        );
        startGroupSelection(_genesisGroupSeed, msg.value);
    }

    modifier onlyServiceContract() {
        require(
            serviceContracts.contains(msg.sender),
            "Caller is not a service contract"
        );
        _;
    }

    /// @notice Adds service contract
    /// @param serviceContract Address of the service contract.
    function addServiceContract(address serviceContract) public {
        require(
            registry.serviceContractUpgraderFor(address(this)) == msg.sender,
            "Not authorized"
        );

        serviceContracts.push(serviceContract);
    }

    /// @notice Pulls the most recent gas price from gas price oracle.
    function refreshGasPrice() public {
        gasPriceCeiling = gasPriceOracle.gasPrice();
    }

    /// @notice Triggers the selection process of a new candidate group.
    /// @param _newEntry New random beacon value that stakers will use to
    /// generate their tickets.
    /// @param submitter Operator of this contract.
    function createGroup(uint256 _newEntry, address payable submitter)
        public
        payable
        onlyServiceContract
    {
        uint256 groupSelectionStartFee =
            groupSelectionGasEstimate.mul(gasPriceCeiling);

        groupSelectionStarterContract = ServiceContract(msg.sender);
        startGroupSelection(_newEntry, msg.value.sub(groupSelectionStartFee));

        // reimbursing a submitter that triggered group selection
        (bool success, ) =
            stakingContract.beneficiaryOf(submitter).call.value(
                groupSelectionStartFee
            )("");
        require(success, "Group selection reimbursement failed");
    }

    /// @notice Checks if it is possible to fire a new group selection.
    /// Triggering new group selection is only possible when there is no
    /// pending group selection or when the pending group selection timed out.
    function isGroupSelectionPossible() public view returns (bool) {
        if (!groupSelection.inProgress) {
            return true;
        }

        // dkgTimeout is the time after key generation protocol is expected to
        // be complete plus the expected time to submit the result.
        uint256 dkgTimeout =
            groupSelection.ticketSubmissionStartBlock +
                groupSelection.ticketSubmissionTimeout +
                dkgResultVerification.timeDKG +
                groupSize *
                resultPublicationBlockStep;

        return block.number > dkgTimeout;
    }

    /// @notice Submits ticket to request to participate in a new candidate group.
    /// @param ticket Bytes representation of a ticket that holds the following:
    /// - ticketValue: first 8 bytes of a result of keccak256 cryptography hash
    ///   function on the combination of the group selection seed (previous
    ///   beacon output), staker-specific value (address) and virtual staker index.
    /// - stakerValue: a staker-specific value which is the address of the staker.
    /// - virtualStakerIndex: 4-bytes number within a range of 1 to staker's weight;
    ///   has to be unique for all tickets submitted by the given staker for the
    ///   current candidate group selection.
    function submitTicket(bytes32 ticket) public {
        uint256 stakingWeight =
            stakingContract.eligibleStake(msg.sender, address(this)).div(
                groupSelection.minimumStake
            );
        groupSelection.submitTicket(ticket, stakingWeight);
    }

    /// @notice Gets the timeout in blocks after which group candidate ticket
    /// submission is finished.
    function ticketSubmissionTimeout() public view returns (uint256) {
        return groupSelection.ticketSubmissionTimeout;
    }

    /// @notice Gets the submitted group candidate tickets so far.
    function submittedTickets() public view returns (uint64[] memory) {
        return groupSelection.tickets;
    }

    /// @notice Gets selected participants in ascending order of their tickets.
    function selectedParticipants() public view returns (address[] memory) {
        return groupSelection.selectedParticipants();
    }

    /// @notice Submits result of DKG protocol. It is on-chain part of phase 14 of
    /// the protocol.
    /// @param submitterMemberIndex Claimed submitter candidate group member index
    /// @param groupPubKey Generated candidate group public key
    /// @param misbehaved Bytes array of misbehaved (disqualified or inactive)
    /// group members indexes in ascending order; Indexes reflect positions of
    /// members in the group as outputted by the group selection protocol.
    /// @param signatures Concatenation of signatures from members supporting the
    /// result.
    /// @param signingMembersIndexes Indices of members corresponding to each
    /// signature.
    function submitDkgResult(
        uint256 submitterMemberIndex,
        bytes memory groupPubKey,
        bytes memory misbehaved,
        bytes memory signatures,
        uint256[] memory signingMembersIndexes
    ) public nonReentrant {
        address[] memory members = selectedParticipants();

        dkgResultVerification.verify(
            submitterMemberIndex,
            groupPubKey,
            misbehaved,
            signatures,
            signingMembersIndexes,
            members,
            groupSelection.ticketSubmissionStartBlock +
                groupSelection.ticketSubmissionTimeout
        );

        groups.setGroupMembers(groupPubKey, members, misbehaved);
        groups.addGroup(groupPubKey);
        reimburseDkgSubmitter();
        emit DkgResultSubmittedEvent(
            submitterMemberIndex,
            groupPubKey,
            misbehaved
        );
        groupSelection.finish();
    }

    /// @notice Creates a request to generate a new relay entry, which will include
    /// a random number (by signing the previous entry's random number).
    /// @param requestId Request Id trackable by service contract
    /// @param previousEntry Previous relay entry
    function sign(uint256 requestId, bytes memory previousEntry)
        public
        payable
        onlyServiceContract
    {
        uint256 entryVerificationAndProfitFee =
            groupProfitFee().add(entryVerificationFee());
        require(
            msg.value >= entryVerificationAndProfitFee,
            "Insufficient new entry fee"
        );
        uint256 callbackFee = msg.value.sub(entryVerificationAndProfitFee);
        signRelayEntry(
            requestId,
            previousEntry,
            msg.sender,
            entryVerificationAndProfitFee,
            callbackFee
        );
    }

    /// @notice Creates a new relay entry and stores the associated data on the chain.
    /// @param _groupSignature Group BLS signature over the concatenation of the
    /// previous entry and seed.
    function relayEntry(bytes memory _groupSignature) public nonReentrant {
        require(isEntryInProgress(), "Entry was submitted");
        require(!hasEntryTimedOut(), "Entry timed out");

        bytes memory groupPubKey =
            groups.getGroupPublicKey(currentRequestGroupIndex);

        require(
            BLS.verify(
                groupPubKey,
                currentRequestPreviousEntry,
                _groupSignature
            ),
            "Invalid signature"
        );

        emit RelayEntrySubmitted();

        // Spend no more than groupSelectionGasEstimate + 40000 gas max
        // This will prevent relayEntry failure in case the service contract is compromised
        currentRequestServiceContract.call.gas(
            groupSelectionGasEstimate.add(40000)
        )(
            abi.encodeWithSignature(
                "entryCreated(uint256,bytes,address)",
                currentRequestId,
                _groupSignature,
                msg.sender
            )
        );

        if (currentRequestCallbackFee > 0) {
            executeCallback(uint256(keccak256(_groupSignature)));
        }

        (uint256 groupMemberReward, uint256 submitterReward, uint256 subsidy) =
            newEntryRewardsBreakdown();
        groups.addGroupMemberReward(groupPubKey, groupMemberReward);

        stakingContract.beneficiaryOf(msg.sender).call.value(submitterReward)(
            ""
        );

        if (subsidy > 0) {
            currentRequestServiceContract.call.gas(35000).value(subsidy)(
                abi.encodeWithSignature("fundRequestSubsidyFeePool()")
            );
        }

        currentRequestStartBlock = 0;
    }

    /// @notice Returns true if generation of a new relay entry is currently in
    /// progress.
    function isEntryInProgress() public view returns (bool) {
        return currentRequestStartBlock != 0;
    }

    /// @notice Function used to inform about the fact the currently ongoing
    /// new relay entry generation operation timed out. As a result, the group
    /// which was supposed to produce a new relay entry is immediately
    /// terminated and a new group is selected to produce a new relay entry.
    /// All members of the group are punished by seizing minimum stake of
    /// their tokens. The submitter of the transaction is rewarded with a
    /// tattletale reward which is limited to min(1, 20 / group_size) of the
    /// maximum tattletale reward.
    function reportRelayEntryTimeout() public {
        require(hasEntryTimedOut(), "Entry did not time out");
        groups.reportRelayEntryTimeout(currentRequestGroupIndex, groupSize);
        currentRequestStartBlock = 0;

        // We could terminate the last active group. If that's the case,
        // do not try to execute signing again because there is no group
        // which can handle it.
        if (numberOfGroups() > 0) {
            signRelayEntry(
                currentRequestId,
                currentRequestPreviousEntry,
                currentRequestServiceContract,
                currentRequestEntryVerificationAndProfitFee,
                currentRequestCallbackFee
            );
        }

        emit RelayEntryTimeoutReported(currentRequestGroupIndex);
    }

    /// @notice Gets group profit fee expressed in wei.
    function groupProfitFee() public view returns (uint256) {
        return groupMemberBaseReward.mul(groupSize);
    }

    /// @notice Checks if the specified account has enough active stake to become
    /// network operator and that this contract has been authorized for potential
    /// slashing.
    ///
    /// Having the required minimum of active stake makes the operator eligible
    /// to join the network. If the active stake is not currently undelegating,
    /// operator is also eligible for work selection.
    ///
    /// @param staker Staker's address
    /// @return True if has enough active stake to participate in the network,
    /// false otherwise.
    function hasMinimumStake(address staker) public view returns (bool) {
        return stakingContract.hasMinimumStake(staker, address(this));
    }

    /// @notice Checks if group with the given public key is registered.
    function isGroupRegistered(bytes memory groupPubKey)
        public
        view
        returns (bool)
    {
        return groups.isGroupRegistered(groupPubKey);
    }

    /// @notice Checks if a group with the given public key is a stale group.
    /// Stale group is an expired group which is no longer performing any
    /// operations. It is important to understand that an expired group may
    /// still perform some operations for which it was selected when it was still
    /// active. We consider a group to be stale when it's expired and when its
    /// expiration time and potentially executed operation timeout are both in
    /// the past.
    function isStaleGroup(bytes memory groupPubKey) public view returns (bool) {
        return groups.isStaleGroup(groupPubKey);
    }

    /// @notice Gets the number of active groups as currently marked in the
    /// contract. This is the state from when the expired groups were last updated
    /// without accounting for recent expirations.
    ///
    /// @dev Even if numberOfGroups() > 0, it is still possible requesting for
    /// a new relay entry will revert with "no active groups" failure message.
    /// This function returns the number of active groups as they are currently
    /// marked on-chain. However, during relay request, before group selection,
    /// we run group expiration and it may happen that some groups seen as active
    /// turns out to be expired.
    function numberOfGroups() public view returns (uint256) {
        return groups.numberOfGroups();
    }

    /// @notice Returns accumulated group member rewards for provided group.
    function getGroupMemberRewards(bytes memory groupPubKey)
        public
        view
        returns (uint256)
    {
        return groups.groupMemberRewards[groupPubKey];
    }

    /// @notice Return whether the given operator has withdrawn their rewards
    /// from the given group.
    function hasWithdrawnRewards(address operator, uint256 groupIndex)
        public
        view
        returns (bool)
    {
        return groups.hasWithdrawnRewards(operator, groupIndex);
    }

    /// @notice Withdraws accumulated group member rewards for operator
    /// using the provided group index.
    /// Once the accumulated reward is withdrawn from the selected group,
    /// the operator is flagged as withdrawn.
    /// Rewards can be withdrawn only from stale group.
    /// @param operator Operator address
    /// @param groupIndex Group index
    function withdrawGroupMemberRewards(address operator, uint256 groupIndex)
        public
        nonReentrant
    {
        uint256 accumulatedRewards =
            groups.withdrawFromGroup(operator, groupIndex);
        (bool success, ) =
            stakingContract.beneficiaryOf(operator).call.value(
                accumulatedRewards
            )("");
        if (success) {
            emit GroupMemberRewardsWithdrawn(
                stakingContract.beneficiaryOf(operator),
                operator,
                accumulatedRewards,
                groupIndex
            );
        }
    }

    /// @notice Gets the index of the first active group.
    function getFirstActiveGroupIndex() public view returns (uint256) {
        return groups.expiredGroupOffset;
    }

    /// @notice Gets public key of the group with the given index.
    function getGroupPublicKey(uint256 groupIndex)
        public
        view
        returns (bytes memory)
    {
        return groups.getGroupPublicKey(groupIndex);
    }

    /// @notice Returns fee for entry verification in wei. Does not include group
    /// profit fee, DKG contribution or callback fee.
    function entryVerificationFee() public view returns (uint256) {
        return entryVerificationGasEstimate.mul(gasPriceCeiling);
    }

    /// @notice Returns fee for group creation in wei. Includes the cost of DKG
    /// and the cost of triggering group selection.
    function groupCreationFee() public view returns (uint256) {
        return
            dkgGasEstimate.add(groupSelectionGasEstimate).mul(gasPriceCeiling);
    }

    /// @notice Returns members of the given group by group public key.
    function getGroupMembers(bytes memory groupPubKey)
        public
        view
        returns (address[] memory members)
    {
        return groups.getGroupMembers(groupPubKey);
    }

    function getNumberOfCreatedGroups() public view returns (uint256) {
        return groups.groups.length;
    }

    function getGroupRegistrationTime(uint256 groupIndex)
        public
        view
        returns (uint256)
    {
        return groups.getGroupRegistrationTime(groupIndex);
    }

    function isGroupTerminated(uint256 groupIndex) public view returns (bool) {
        return groups.isGroupTerminated(groupIndex);
    }

    /// @notice Reports unauthorized signing for the provided group. Must provide
    /// a valid signature of the tattletale address as a message. Successful signature
    /// verification means the private key has been leaked and all group members
    /// should be punished by seizing their tokens. The submitter of this proof is
    /// rewarded with 5% of the total seized amount scaled by the reward adjustment
    /// parameter and the rest 95% is burned.
    function reportUnauthorizedSigning(
        uint256 groupIndex,
        bytes memory signedMsgSender
    ) public {
        groups.reportUnauthorizedSigning(
            groupIndex,
            signedMsgSender,
            stakingContract.minimumStake()
        );
        emit UnauthorizedSigningReported(groupIndex);
    }

    function startGroupSelection(uint256 _newEntry, uint256 _payment) internal {
        require(
            _payment >= gasPriceCeiling.mul(dkgGasEstimate),
            "Insufficient DKG fee"
        );

        require(isGroupSelectionPossible(), "Group selection in progress");

        // If previous group selection failed and there is reimbursement left
        // return it to the DKG fee pool.
        if (dkgSubmitterReimbursementFee > 0) {
            uint256 surplus = dkgSubmitterReimbursementFee;
            dkgSubmitterReimbursementFee = 0;
            ServiceContract(groupSelectionStarterContract).fundDkgFeePool.value(
                surplus
            )();
        }

        groupSelection.minimumStake = stakingContract.minimumStake();
        groupSelection.start(_newEntry);
        emit GroupSelectionStarted(_newEntry);
        dkgSubmitterReimbursementFee = _payment;
    }

    /// @notice Compare the reimbursement fee calculated based on the current
    /// transaction gas price and the current price feed estimate with the DKG
    /// reimbursement fee calculated and paid at the moment when the DKG was
    /// requested. If there is any surplus, it will be returned to the DKG fee
    /// pool of the service contract which triggered the DKG.
    function reimburseDkgSubmitter() internal {
        uint256 gasPrice = gasPriceCeiling;
        // We need to check if tx.gasprice is non-zero as a workaround to a bug
        // in go-ethereum:
        // https://github.com/ethereum/go-ethereum/pull/20189
        if (tx.gasprice > 0 && tx.gasprice < gasPriceCeiling) {
            gasPrice = tx.gasprice;
        }

        uint256 reimbursementFee = dkgGasEstimate.mul(gasPrice);
        address payable beneficiary = stakingContract.beneficiaryOf(msg.sender);

        if (reimbursementFee < dkgSubmitterReimbursementFee) {
            uint256 surplus =
                dkgSubmitterReimbursementFee.sub(reimbursementFee);
            dkgSubmitterReimbursementFee = 0;
            // Reimburse submitter with actual DKG cost.
            beneficiary.call.value(reimbursementFee)("");

            // Return surplus to the contract that started DKG.
            groupSelectionStarterContract.fundDkgFeePool.value(surplus)();
        } else {
            // If submitter used higher gas price reimburse only
            // dkgSubmitterReimbursementFee max.
            reimbursementFee = dkgSubmitterReimbursementFee;
            dkgSubmitterReimbursementFee = 0;
            beneficiary.call.value(reimbursementFee)("");
        }
    }

    function signRelayEntry(
        uint256 requestId,
        bytes memory previousEntry,
        address serviceContract,
        uint256 entryVerificationAndProfitFee,
        uint256 callbackFee
    ) internal {
        require(!isEntryInProgress(), "Beacon is busy");

        uint256 groupIndex =
            groups.selectGroup(uint256(keccak256(previousEntry)));

        currentRequestId = requestId;
        currentRequestStartBlock = block.number;
        currentRequestEntryVerificationAndProfitFee = entryVerificationAndProfitFee;
        currentRequestCallbackFee = callbackFee;
        currentRequestGroupIndex = groupIndex;
        currentRequestPreviousEntry = previousEntry;
        currentRequestServiceContract = serviceContract;

        bytes memory groupPubKey = groups.getGroupPublicKey(groupIndex);
        emit RelayEntryRequested(previousEntry, groupPubKey);
    }

    /// @notice Executes customer specified callback for the relay entry request.
    /// @param entry The generated random number.
    function executeCallback(uint256 entry) internal {
        // Make sure not to spend more than what was received from the service
        // contract for the callback
        uint256 gasLimit = currentRequestCallbackFee.div(gasPriceCeiling);

        // Make sure not to spend more than 2 million gas on a callback.
        // This is to protect members from relay entry failure and potential
        // slashing in case of any changes in .call() gas limit.
        gasLimit = gasLimit > 2000000 ? 2000000 : gasLimit;

        bytes memory callbackSurplusRecipientData;
        (, callbackSurplusRecipientData) = currentRequestServiceContract
            .call
            .gas(40000)(
            abi.encodeWithSignature(
                "callbackSurplusRecipient(uint256)",
                currentRequestId
            )
        );

        uint256 gasBeforeCallback = gasleft();
        currentRequestServiceContract.call.gas(gasLimit)(
            abi.encodeWithSignature(
                "executeCallback(uint256,uint256)",
                currentRequestId,
                entry
            )
        );

        uint256 gasAfterCallback = gasleft();
        uint256 gasSpent = gasBeforeCallback.sub(gasAfterCallback);

        Reimbursements.reimburseCallback(
            stakingContract,
            gasPriceCeiling,
            gasLimit,
            gasSpent,
            currentRequestCallbackFee,
            callbackSurplusRecipientData
        );
    }

    /// @notice Get rewards breakdown in wei for successful entry for the
    /// current signing request.
    function newEntryRewardsBreakdown()
        internal
        view
        returns (
            uint256 groupMemberReward,
            uint256 submitterReward,
            uint256 subsidy
        )
    {
        uint256 decimals = 1e16; // Adding 16 decimals to perform float division.

        uint256 delayFactor =
            DelayFactor.calculate(currentRequestStartBlock, relayEntryTimeout);
        groupMemberReward = groupMemberBaseReward.mul(delayFactor).div(
            decimals
        );

        // delay penalty = base reward * (1 - delay factor)
        uint256 groupMemberDelayPenalty =
            groupMemberBaseReward.mul(decimals.sub(delayFactor));

        // The submitter reward consists of:
        // The callback gas expenditure (reimbursed by the service contract)
        // The entry verification fee to cover the cost of verifying the submission,
        // paid regardless of their gas expenditure
        // Submitter extra reward - 5% of the delay penalties of the entire group
        uint256 submitterExtraReward =
            groupMemberDelayPenalty.mul(groupSize).percent(5).div(decimals);
        uint256 entryVerificationFee =
            currentRequestEntryVerificationAndProfitFee.sub(groupProfitFee());
        submitterReward = entryVerificationFee.add(submitterExtraReward);

        // Rewards not paid out to the operators are paid out to requesters to subsidize new requests.
        subsidy = groupProfitFee().sub(groupMemberReward.mul(groupSize)).sub(
            submitterExtraReward
        );
    }

    /// @notice Returns true if the currently ongoing new relay entry generation
    /// operation timed out. There is a certain timeout for a new relay entry
    /// to be produced, see `relayEntryTimeout` value.
    function hasEntryTimedOut() internal view returns (bool) {
        return
            currentRequestStartBlock != 0 &&
            block.number > currentRequestStartBlock + relayEntryTimeout;
    }
}

pragma solidity 0.5.17;

/// @title KeepRegistry
/// @notice Governance owned registry of approved contracts and roles.
contract KeepRegistry {
    enum ContractStatus {New, Approved, Disabled}

    // Governance role is to enable recovery from key compromise by rekeying
    // other roles. Also, it can disable operator contract panic buttons
    // permanently.
    address public governance;

    // Registry Keeper maintains approved operator contracts. Each operator
    // contract must be approved before it can be authorized by a staker or
    // used by a service contract.
    address public registryKeeper;

    // Each operator contract has a Panic Button which can disable malicious
    // or malfunctioning contract that have been previously approved by the
    // Registry Keeper.
    //
    // New operator contract added to the registry has a default panic button
    // value assigned (defaultPanicButton). Panic button for each operator
    // contract can be later updated by Governance to individual value.
    //
    // It is possible to disable panic button for individual contract by
    // setting the panic button to zero address. In such case, operator contract
    // can not be disabled and is permanently approved in the registry.
    mapping(address => address) public panicButtons;

    // Default panic button for each new operator contract added to the
    // registry. Can be later updated for each contract.
    address public defaultPanicButton;

    // Each service contract has a Operator Contract Upgrader whose purpose
    // is to manage operator contracts for that specific service contract.
    // The Operator Contract Upgrader can add new operator contracts to the
    // service contract’s operator contract list, and deprecate old ones.
    mapping(address => address) public operatorContractUpgraders;

    // Operator contract may have a Service Contract Upgrader whose purpose is
    // to manage service contracts for that specific operator contract.
    // Service Contract Upgrader can add and remove service contracts
    // from the list of service contracts approved to work with the operator
    // contract. List of service contracts is maintained in the operator
    // contract and is optional - not every operator contract needs to have
    // a list of service contracts it wants to cooperate with.
    mapping(address => address) public serviceContractUpgraders;

    // The registry of operator contracts
    mapping(address => ContractStatus) public operatorContracts;

    event OperatorContractApproved(address operatorContract);
    event OperatorContractDisabled(address operatorContract);

    event GovernanceUpdated(address governance);
    event RegistryKeeperUpdated(address registryKeeper);
    event DefaultPanicButtonUpdated(address defaultPanicButton);
    event OperatorContractPanicButtonDisabled(address operatorContract);
    event OperatorContractPanicButtonUpdated(
        address operatorContract,
        address panicButton
    );
    event OperatorContractUpgraderUpdated(
        address serviceContract,
        address upgrader
    );
    event ServiceContractUpgraderUpdated(
        address operatorContract,
        address keeper
    );

    modifier onlyGovernance() {
        require(governance == msg.sender, "Not authorized");
        _;
    }

    modifier onlyRegistryKeeper() {
        require(registryKeeper == msg.sender, "Not authorized");
        _;
    }

    modifier onlyPanicButton(address _operatorContract) {
        address panicButton = panicButtons[_operatorContract];
        require(panicButton != address(0), "Panic button disabled");
        require(panicButton == msg.sender, "Not authorized");
        _;
    }

    modifier onlyForNewContract(address _operatorContract) {
        require(
            isNewOperatorContract(_operatorContract),
            "Not a new operator contract"
        );
        _;
    }

    modifier onlyForApprovedContract(address _operatorContract) {
        require(
            isApprovedOperatorContract(_operatorContract),
            "Not an approved operator contract"
        );
        _;
    }

    constructor() public {
        governance = msg.sender;
        registryKeeper = msg.sender;
        defaultPanicButton = msg.sender;
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
        emit GovernanceUpdated(governance);
    }

    function setRegistryKeeper(address _registryKeeper) public onlyGovernance {
        registryKeeper = _registryKeeper;
        emit RegistryKeeperUpdated(registryKeeper);
    }

    function setDefaultPanicButton(address _panicButton) public onlyGovernance {
        defaultPanicButton = _panicButton;
        emit DefaultPanicButtonUpdated(defaultPanicButton);
    }

    function setOperatorContractPanicButton(
        address _operatorContract,
        address _panicButton
    ) public onlyForApprovedContract(_operatorContract) onlyGovernance {
        require(
            panicButtons[_operatorContract] != address(0),
            "Disabled panic button cannot be updated"
        );
        require(
            _panicButton != address(0),
            "Panic button must be non-zero address"
        );

        panicButtons[_operatorContract] = _panicButton;

        emit OperatorContractPanicButtonUpdated(
            _operatorContract,
            _panicButton
        );
    }

    function disableOperatorContractPanicButton(address _operatorContract)
        public
        onlyForApprovedContract(_operatorContract)
        onlyGovernance
    {
        require(
            panicButtons[_operatorContract] != address(0),
            "Panic button already disabled"
        );

        panicButtons[_operatorContract] = address(0);

        emit OperatorContractPanicButtonDisabled(_operatorContract);
    }

    function setOperatorContractUpgrader(
        address _serviceContract,
        address _operatorContractUpgrader
    ) public onlyGovernance {
        operatorContractUpgraders[_serviceContract] = _operatorContractUpgrader;
        emit OperatorContractUpgraderUpdated(
            _serviceContract,
            _operatorContractUpgrader
        );
    }

    function setServiceContractUpgrader(
        address _operatorContract,
        address _serviceContractUpgrader
    ) public onlyGovernance {
        serviceContractUpgraders[_operatorContract] = _serviceContractUpgrader;
        emit ServiceContractUpgraderUpdated(
            _operatorContract,
            _serviceContractUpgrader
        );
    }

    function approveOperatorContract(address operatorContract)
        public
        onlyForNewContract(operatorContract)
        onlyRegistryKeeper
    {
        operatorContracts[operatorContract] = ContractStatus.Approved;
        panicButtons[operatorContract] = defaultPanicButton;
        emit OperatorContractApproved(operatorContract);
    }

    function disableOperatorContract(address operatorContract)
        public
        onlyForApprovedContract(operatorContract)
        onlyPanicButton(operatorContract)
    {
        operatorContracts[operatorContract] = ContractStatus.Disabled;
        emit OperatorContractDisabled(operatorContract);
    }

    function isNewOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.New;
    }

    function isApprovedOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.Approved;
    }

    function operatorContractUpgraderFor(address _serviceContract)
        public
        view
        returns (address)
    {
        return operatorContractUpgraders[_serviceContract];
    }

    function serviceContractUpgraderFor(address _operatorContract)
        public
        view
        returns (address)
    {
        return serviceContractUpgraders[_operatorContract];
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

/// @dev Interface of recipient contract for approveAndCall pattern.
interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

/// @title KEEP Token
/// @dev Standard ERC20Burnable token
contract KeepToken is ERC20Burnable, ERC20Detailed {
    string public constant NAME = "KEEP Token";
    string public constant SYMBOL = "KEEP";
    uint8 public constant DECIMALS = 18; // The number of digits after the decimal place when displaying token values on-screen.
    uint256 public constant INITIAL_SUPPLY = 10**27; // 1 billion tokens, 18 decimal places.

    /// @dev Gives msg.sender all of existing tokens.
    constructor() public ERC20Detailed(NAME, SYMBOL, DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /// @notice Set allowance for other address and notify.
    /// Allows `_spender` to spend no more than `_value` tokens
    /// on your behalf and then ping the contract about it.
    /// @param _spender The address authorized to spend.
    /// @param _value The max amount they can spend.
    /// @param _extraData Extra information to send to the approved contract.
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
    }
}

pragma solidity ^0.5.4;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "./TokenGrant.sol";

/// @title ManagedGrant
/// @notice A managed grant acts as the grantee towards the token grant contract,
/// proxying instructions from the actual grantee.
/// The address used by the actual grantee
/// to issue instructions and withdraw tokens
/// can be reassigned with the consent of the grant manager.
contract ManagedGrant {
    using SafeERC20 for ERC20Burnable;

    ERC20Burnable public token;
    TokenGrant public tokenGrant;
    address public grantManager;
    uint256 public grantId;
    address public grantee;
    address public requestedNewGrantee;

    event GranteeReassignmentRequested(address newGrantee);
    event GranteeReassignmentConfirmed(address oldGrantee, address newGrantee);
    event GranteeReassignmentCancelled(address cancelledRequestedGrantee);
    event GranteeReassignmentChanged(
        address previouslyRequestedGrantee,
        address newRequestedGrantee
    );
    event TokensWithdrawn(address destination, uint256 amount);

    constructor(
        address _tokenAddress,
        address _tokenGrant,
        address _grantManager,
        uint256 _grantId,
        address _grantee
    ) public {
        token = ERC20Burnable(_tokenAddress);
        tokenGrant = TokenGrant(_tokenGrant);
        grantManager = _grantManager;
        grantId = _grantId;
        grantee = _grantee;
    }

    /// @notice Request a reassignment of the grantee address.
    /// Can only be called by the grantee.
    /// @param _newGrantee The requested new grantee.
    function requestGranteeReassignment(address _newGrantee)
        public
        onlyGrantee
        noRequestedReassignment
    {
        _setRequestedNewGrantee(_newGrantee);
        emit GranteeReassignmentRequested(_newGrantee);
    }

    /// @notice Cancel a pending grantee reassignment request.
    /// Can only be called by the grantee.
    function cancelReassignmentRequest()
        public
        onlyGrantee
        withRequestedReassignment
    {
        address cancelledGrantee = requestedNewGrantee;
        requestedNewGrantee = address(0);
        emit GranteeReassignmentCancelled(cancelledGrantee);
    }

    /// @notice Change a pending reassignment request to a different grantee.
    /// Can only be called by the grantee.
    /// @param _newGrantee The address of the new requested grantee.
    function changeReassignmentRequest(address _newGrantee)
        public
        onlyGrantee
        withRequestedReassignment
    {
        address previouslyRequestedGrantee = requestedNewGrantee;
        require(
            previouslyRequestedGrantee != _newGrantee,
            "Unchanged reassignment request"
        );
        _setRequestedNewGrantee(_newGrantee);
        emit GranteeReassignmentChanged(
            previouslyRequestedGrantee,
            _newGrantee
        );
    }

    /// @notice Confirm a grantee reassignment request and set the new grantee as the grantee.
    /// Can only be called by the grant manager.
    /// @param _newGrantee The address of the new grantee.
    /// Must match the currently requested new grantee.
    function confirmGranteeReassignment(address _newGrantee)
        public
        onlyManager
        withRequestedReassignment
    {
        address oldGrantee = grantee;
        require(
            requestedNewGrantee == _newGrantee,
            "Reassignment address mismatch"
        );
        grantee = requestedNewGrantee;
        requestedNewGrantee = address(0);
        emit GranteeReassignmentConfirmed(oldGrantee, _newGrantee);
    }

    /// @notice Withdraw all unlocked tokens from the grant.
    function withdraw() public onlyGrantee {
        require(
            requestedNewGrantee == address(0),
            "Can not withdraw with pending reassignment"
        );
        tokenGrant.withdraw(grantId);
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(grantee, amount);
        emit TokensWithdrawn(grantee, amount);
    }

    /// @notice Stake tokens from the grant.
    /// @param _stakingContract The contract to stake the tokens on.
    /// @param _amount The amount of tokens to stake.
    /// @param _extraData Data for the stake delegation.
    /// This byte array must have the following values concatenated:
    /// beneficiary address (20 bytes)
    /// operator address (20 bytes)
    /// authorizer address (20 bytes)
    function stake(
        address _stakingContract,
        uint256 _amount,
        bytes memory _extraData
    ) public onlyGrantee {
        tokenGrant.stake(grantId, _stakingContract, _amount, _extraData);
    }

    /// @notice Cancel delegating tokens to the given operator.
    function cancelStake(address _operator) public onlyGranteeOr(_operator) {
        tokenGrant.cancelStake(_operator);
    }

    /// @notice Begin undelegating tokens from the given operator.
    function undelegate(address _operator) public onlyGranteeOr(_operator) {
        tokenGrant.undelegate(_operator);
    }

    /// @notice Recover tokens previously staked and delegated to the operator.
    function recoverStake(address _operator) public {
        tokenGrant.recoverStake(_operator);
    }

    function _setRequestedNewGrantee(address _newGrantee) internal {
        require(_newGrantee != address(0), "Invalid new grantee address");
        require(_newGrantee != grantee, "New grantee same as current grantee");

        requestedNewGrantee = _newGrantee;
    }

    modifier withRequestedReassignment {
        require(requestedNewGrantee != address(0), "No reassignment requested");
        _;
    }

    modifier noRequestedReassignment {
        require(
            requestedNewGrantee == address(0),
            "Reassignment already requested"
        );
        _;
    }

    modifier onlyGrantee {
        require(msg.sender == grantee, "Only grantee may perform this action");
        _;
    }

    modifier onlyGranteeOr(address _operator) {
        require(
            msg.sender == grantee || msg.sender == _operator,
            "Only grantee or operator may perform this action"
        );
        _;
    }

    modifier onlyManager {
        require(
            msg.sender == grantManager,
            "Only grantManager may perform this action"
        );
        _;
    }
}

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

pragma solidity ^0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";

import "./KeepToken.sol";

/// @title KEEP Signer Subsidy Rewards
/// @notice A contract for distributing KEEP token rewards to keeps.
/// When a reward contract is created, the creator defines a reward schedule
/// consisting of one or more reward intervals and their interval weights,
/// the length of reward intervals, and the quota of how many keeps must be
/// created in an interval for the full reward for that interval to be paid out.
///
/// The amount of KEEP to be distributed is determined by funding the contract,
/// and additional KEEP can be added at any time.
/// The reward contract is funded with `approveAndCall` with no extra data,
/// but it also collects any KEEP mistakenly sent to it in any other way.
///
/// An interval is defined by the timestamps [startOf, endOf);
/// a keep created at the time `startOf(i)` belongs to interval `i`
/// and one created at `endOf(i)` belongs to `i+1`.
///
/// When an interval is over, it will be allocated a percentage of the remaining
/// unallocated rewards based on its weight, and adjusted by the number of keeps
/// created in the interval if the quota is not met.
///
/// The adjustment for not meeting the keep quota is a percentage that equals
/// the percentage of the quota that was met; if the number of keeps created is
/// 80% of the quota then 80% of the base reward will be allocated for the
/// interval.
///
/// Any unallocated rewards will stay in the unallocated rewards pool,
/// to be allocated for future intervals. Intervals past the initially defined
/// schedule have a weight of 100%, meaning that all remaining unallocated
/// rewards will be allocated to the interval.
///
/// Keeps of the appropriate type can receive rewards once the interval they
/// were created in is over, and the keep has closed happily.
/// There is no time limit to receiving rewards, nor is there need to wait for
/// all keeps from the interval to close.
/// Calling `receiveReward` automatically allocates the rewards for the interval
/// the specified keep was created in and all previous intervals.
///
/// If a keep is terminated, that fact can be reported to the reward contract.
/// Reporting a terminated keep returns its allocated reward to the pool of
/// unallocated rewards.
///
/// @dev A concrete implementation of the abstract rewards contract must specify
/// functions for accessing information about keeps and paying out rewards.
/// For the purpose of rewards, Random Beacon signing groups count as "keeps"
/// and the beacon operator contract acts as the "factory".
contract Rewards is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for KeepToken;

    KeepToken public token;

    // Array representing the percentage of unallocated rewards
    // available for each reward interval.
    uint256[] public intervalWeights; // percent array
    // Length of one interval in seconds (timestamp diff).
    uint256 public termLength;
    // The number of keeps required in an interval
    // for the full reward to be allocated to the interval.
    uint256 public minimumKeepsPerInterval;

    // Total number of KEEP tokens to distribute by this contract.
    // Includes those already dispensed.
    uint256 public totalRewards;
    // Rewards that haven't been allocated to finished intervals.
    uint256 public unallocatedRewards;
    // Rewards that have been dispensed from this contract as signer rewards.
    // `token.balanceOf(address(this))` should always equal
    // `totalRewards.sub(dispensedRewards)`
    uint256 public dispensedRewards;
    // The following invariant should always hold:
    // token.balanceOf(address(this)) >= totalRewards.sub(dispensedRewards)

    // Timestamp of first interval beginning.
    // Interval 0 covers everything before `firstIntervalStart`
    // and the first `termLength` after `firstIntervalStart`.
    uint256 public firstIntervalStart;
    // Mapping of interval number to tokens allocated for the interval.
    uint256[] internal intervalAllocations;

    // mapping of keeps to booleans.
    // True if the keep has been used to claim a reward.
    mapping(bytes32 => bool) internal claimed;
    // Mapping of interval to number of keeps created in/before the interval
    mapping(uint256 => uint256) internal keepsByInterval;
    // Mapping of interval to number of keeps whose rewards have been paid out,
    // or reallocated because the keep closed unhappily
    mapping(uint256 => uint256) public intervalKeepsProcessed;

    // Indicates whether the contract has been properly funded. Rewards can not
    // be allocated before the first funding and the owner of the
    // contract is responsible for marking it as already funded. Further funding
    // of the contract is possible with no owner's intervention.
    bool public funded = false;

    // Owner of the contract may initiate an upgrade to a new rewards contract
    // but the pending and past intervals must have their rewards allocated
    // before any KEEP tokens are transferred out from this contract.
    uint256 public upgradeInitiatedTimestamp;
    uint256 public upgradeFinalizedTimestamp;
    address public newRewardsContract;

    event RewardReceived(bytes32 keep, uint256 amount);
    event UpgradeInitiated(address newRewardsContract);
    event UpgradeFinalized(uint256 amountTransferred);

    constructor(
        address _token,
        uint256 _firstIntervalStart,
        uint256[] memory _intervalWeights,
        uint256 _termLength,
        uint256 _minimumKeepsPerInterval
    ) public {
        token = KeepToken(_token);
        firstIntervalStart = _firstIntervalStart;
        intervalWeights = _intervalWeights;
        termLength = _termLength;
        minimumKeepsPerInterval = _minimumKeepsPerInterval;
    }

    /// @notice Funds the rewards contract.
    /// @dev Adds the received amount of tokens to `totalRewards` and
    /// `unallocatedRewards`. May be called at any time, even after allocating
    /// some intervals.
    /// If the contract has been upgraded,
    /// the funding will be transferred to the new contract instead.
    /// Changes to `unallocatedRewards` will take effect on subsequent interval
    /// allocations. Intended to be used with `approveAndCall`.
    /// If the reward contract has received tokens outside `approveAndCall`,
    /// this collects them as well.
    /// The following invariant should hold right after calling this function:
    /// token.balanceOf(address(this)) == totalRewards.sub(dispensedRewards).
    /// @param _from The original sender of the tokens.
    /// Must have approved at least `_value` tokens for the rewards contract.
    /// @param _value The amount of tokens to fund.
    /// @param _token The token to fund the rewards in.
    /// Must match the one specified in the rewards contract.
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes memory
    ) public {
        require(IERC20(_token) == token, "Unsupported token");

        token.safeTransferFrom(_from, address(this), _value);

        uint256 currentBalance = token.balanceOf(address(this));
        uint256 beforeBalance = totalRewards.sub(dispensedRewards);
        require(
            currentBalance >= beforeBalance,
            "Reward contract has lost tokens"
        );

        uint256 addedBalance = currentBalance.sub(beforeBalance);

        totalRewards = totalRewards.add(addedBalance);
        deallocate(addedBalance);
    }

    function markAsFunded() public onlyOwner {
        funded = true;
    }

    /// @notice Stakers can receive KEEP rewards from multiple keeps of their choice
    /// in one transaction to reduce total cost comparing to single calls for rewards.
    /// It is a caller responsibility to determine the cost and consumed gas when
    /// receiving rewards from multiple keeps.
    /// @param keepIdentifiers An array of keep identifiers.
    function receiveRewards(bytes32[] memory keepIdentifiers) public {
        for (uint256 i = 0; i < keepIdentifiers.length; i++) {
            receiveReward(keepIdentifiers[i]);
        }
    }

    /// @notice Sends the reward for a keep to the keep members.
    /// @param keepIdentifier A unique identifier for the keep,
    /// e.g. address or number converted to a `bytes32`.
    function receiveReward(bytes32 keepIdentifier)
        public
        factoryMustRecognize(keepIdentifier)
        rewardsNotClaimed(keepIdentifier)
        mustBeClosed(keepIdentifier)
    {
        _processKeep(true, keepIdentifier);
    }

    /// @notice Report about the terminated keeps in batch. All the allocated
    /// rewards in these keeps will be returned to the unallocated pool.
    /// @param keepIdentifiers An array of keep identifiers.
    function reportTerminations(bytes32[] memory keepIdentifiers) public {
        for (uint256 i = 0; i < keepIdentifiers.length; i++) {
            reportTermination(keepIdentifiers[i]);
        }
    }

    /// @notice Report that the keep was terminated, and return its allocated
    /// rewards to the unallocated pool.
    /// @param keepIdentifier The terminated keep.
    function reportTermination(bytes32 keepIdentifier)
        public
        factoryMustRecognize(keepIdentifier)
        rewardsNotClaimed(keepIdentifier)
        mustBeTerminated(keepIdentifier)
    {
        _processKeep(false, keepIdentifier);
    }

    /// @notice Checks if a keep is eligible to receive rewards.
    /// @dev Keeps that close dishonorably or early are not eligible for rewards.
    /// @param _keep The keep to check.
    /// @return True if the keep is eligible, false otherwise
    function eligibleForReward(bytes32 _keep) public view returns (bool) {
        return
            _recognizedByFactory(_keep) &&
            _isClosed(_keep) &&
            !rewardClaimed(_keep);
    }

    /// @notice Checks if a keep is terminated and thus its rewards can be
    /// returned to the unallocated pool.
    /// @param _keep The keep to check.
    /// @return True if the keep is terminated, false otherwise
    function eligibleButTerminated(bytes32 _keep) public view returns (bool) {
        return _recognizedByFactory(_keep) && _isTerminated(_keep);
    }

    /// @notice Return the interval number the provided timestamp falls within.
    /// @dev If the timestamp is before `firstIntervalStart`, the interval is 0.
    /// @param timestamp The timestamp whose interval is queried.
    /// @return The interval of the timestamp.
    function intervalOf(uint256 timestamp) public view returns (uint256) {
        uint256 _firstIntervalStart = firstIntervalStart;
        uint256 _termLength = termLength;

        if (timestamp < _firstIntervalStart) {
            return 0;
        }

        uint256 difference = timestamp.sub(_firstIntervalStart);
        uint256 interval = difference.div(_termLength);

        return interval;
    }

    /// @notice Return the timestamp corresponding to the start of the interval.
    /// @dev The start of an interval is inclusive;
    /// a keep created at the timestamp `startOf(i)` is in interval `i`.
    /// @param interval The interval whose start is queried.
    /// @return The start timestamp of the interval.
    function startOf(uint256 interval) public view returns (uint256) {
        return firstIntervalStart.add(interval.mul(termLength));
    }

    /// @notice Return the timestamp corresponding to the end of the interval.
    /// @dev The end of an interval is exclusive;
    /// a keep created at the timestamp `endOf(i)` is in interval `i+1`.
    /// @param interval The interval whose end is queried.
    /// @return The end timestamp of the interval.
    function endOf(uint256 interval) public view returns (uint256) {
        return startOf(interval.add(1));
    }

    /// @notice Return whether the given interval is finished.
    /// @param interval The interval.
    /// @return Whether the interval is finished.
    function isFinished(uint256 interval) public view returns (bool) {
        return block.timestamp >= endOf(interval);
    }

    /// @notice Return whether the given keep has already claimed rewards
    /// or had its rewards reallocated due to termination.
    /// @param _keep The identifier of the keep.
    /// @return True if rewards have been paid out for the keep,
    /// or its termination has been reported.
    /// False otherwise.
    function rewardClaimed(bytes32 _keep) public view returns (bool) {
        return claimed[_keep];
    }

    /// @notice Return the number of keeps created in the specified interval.
    /// @param interval The interval.
    /// @return Number of keeps created in the interval.
    function keepsInInterval(uint256 interval) public returns (uint256) {
        return (_getEndpoint(interval).sub(_getPreviousEndpoint(interval)));
    }

    /// @notice Return the percentage of remaining unallocated rewards
    /// that is to be allocated to the specified interval.
    /// @param interval The interval.
    /// @return The percentage weight of the interval.
    function getIntervalWeight(uint256 interval) public view returns (uint256) {
        if (interval < intervalWeights.length) {
            return intervalWeights[interval];
        } else {
            return intervalWeights[intervalWeights.length - 1];
        }
    }

    /// @notice Get the number of intervals with explicitly specified weights.
    /// All subsequent intervals will have an implicit weight of 100.
    /// @return The number of explicitly specified intervals.
    function getIntervalCount() public view returns (uint256) {
        return intervalWeights.length;
    }

    /// @notice Allocate rewards for unallocated intervals up to and including
    /// the given interval.
    /// @dev The given interval must be finished and unallocated.
    /// To allocate rewards correctly, any earlier intervals that are still
    /// unallocated will be allocated before the given interval.
    /// With reasonable interval lengths this should not pose a problem,
    /// and if allocating a later interval results in an out-of-gas issue,
    /// forcing the allocation of an earlier interval should fix it.
    /// @param interval The interval to allocate.
    function allocateRewards(uint256 interval)
        public
        mustBeFinished(interval)
        mustBeFunded
    {
        uint256 allocatedIntervals = intervalAllocations.length;
        require(!(interval < allocatedIntervals), "Interval already allocated");
        // Allocate previous intervals first
        if (interval > allocatedIntervals) {
            allocateRewards(interval.sub(1));
        }
        uint256 totalAllocation = _adjustedAllocation(interval);
        unallocatedRewards = unallocatedRewards.sub(totalAllocation);
        intervalAllocations.push(totalAllocation);
    }

    /// @notice Get the total amount of tokens
    /// allocated for all keeps in the specified interval.
    /// @dev This function returns correct results for any allocated interval.
    /// Dividing the allocated rewards by the number of keeps in the interval
    /// will give the correct reward for a keep in the interval.
    /// However, if a keep in the interval is terminated
    /// its reward will be returned to the pool of unallocated tokens.
    /// This will not be reflected in the return value of this function.
    /// @param interval A previously allocated interval.
    /// @return The total number of tokens allocated for keeps in the interval.
    function getAllocatedRewards(uint256 interval)
        public
        view
        returns (uint256)
    {
        require(
            interval < intervalAllocations.length,
            "Interval not allocated yet"
        );
        return intervalAllocations[interval];
    }

    /// @notice Return whether the specified interval has been allocated.
    /// @param interval The interval.
    /// @return Whether the interval has been allocated yet.
    function isAllocated(uint256 interval) public view returns (bool) {
        uint256 allocatedIntervals = intervalAllocations.length;
        return (interval < allocatedIntervals);
    }

    /// @notice Initiates the process of upgrading to another rewards contract.
    /// @param _newRewardsContract The address of a new rewards contract.
    function initiateRewardsUpgrade(address _newRewardsContract)
        public
        onlyOwner
    {
        upgradeInitiatedTimestamp = block.timestamp;
        newRewardsContract = _newRewardsContract;
        emit UpgradeInitiated(newRewardsContract);
    }

    /// @notice Finalizes the process of upgrading to another rewards contract
    /// by allocating all past intervals and then, transferring the
    /// not-yet-allocated tokens to a new rewards contract.
    /// Can be called only when the interval during which the upgrade was
    /// initiated ended.
    /// Before finalizing the upgrade, make sure all terminated groups are
    /// reported.
    function finalizeRewardsUpgrade() public onlyOwner {
        require(upgradeInitiatedTimestamp != 0, "Upgrade not initiated");

        uint256 currentInterval = intervalOf(block.timestamp);
        uint256 upgradeInitiatedInterval =
            intervalOf(upgradeInitiatedTimestamp);

        require(
            currentInterval > upgradeInitiatedInterval,
            "Interval at which the upgrade was initiated hasn't ended yet"
        );

        // ensure all past intervals are allocated
        if (!isAllocated(currentInterval.sub(1))) {
            allocateRewards(currentInterval.sub(1));
        }

        // transfer the unallocated KEEP to the new rewards contract and update
        // this contract's balances
        uint256 amountToTransfer = unallocatedRewards;

        totalRewards = totalRewards.sub(amountToTransfer);
        unallocatedRewards = 0;

        emit UpgradeFinalized(amountToTransfer);

        bool success =
            token.approveAndCall(
                newRewardsContract,
                amountToTransfer,
                bytes("")
            );
        require(success, "Upgrade finalization failed");

        upgradeInitiatedTimestamp = 0;
        upgradeFinalizedTimestamp = block.timestamp;
    }

    /// @notice Return the number of keeps created before `intervalEndpoint`
    /// @dev Wraps the binary search of `_find`
    /// with a number of checks for edge cases.
    function _findEndpoint(uint256 intervalEndpoint)
        internal
        view
        returns (uint256)
    {
        require(
            intervalEndpoint <= block.timestamp,
            "interval hasn't ended yet"
        );
        uint256 keepCount = _getKeepCount();
        // no keeps created yet -> return 0
        if (keepCount == 0) {
            return 0;
        }

        uint256 lb = 0; // lower bound, inclusive
        uint256 timestampLB = _getCreationTime(_getKeepAtIndex(lb));
        // all keeps created after the interval -> return 0
        if (timestampLB >= intervalEndpoint) {
            return 0;
        }

        uint256 ub = keepCount.sub(1); // upper bound, inclusive
        uint256 timestampUB = _getCreationTime(_getKeepAtIndex(ub));
        // all keeps created in or before the interval -> return keep count
        if (timestampUB < intervalEndpoint) {
            return keepCount;
        }

        // The above cases also cover the case
        // where only 1 keep has been created;
        // lb == ub
        // if it was created after the interval, return 0
        // otherwise, return 1

        return _find(lb, timestampLB, ub, timestampUB, intervalEndpoint);
    }

    /// @notice Return the number of keeps created before `targetTime`,
    /// with specified upper and lower bounds.
    /// @dev Binary search assumes the following invariants:
    ///   lower bound >= 0, lbTime < targetTime
    ///   upper bound < keepCount, ubTime >= targetTime
    /// @param _lb The lower bound of the search (inclusive)
    /// @param _lbTime The creation time of keep number `lb`
    /// @param _ub The upper bound of the search (inclusive)
    /// @param _ubTime The creation time of keep number `ub`
    /// @param targetTime The target time
    function _find(
        uint256 _lb,
        uint256 _lbTime,
        uint256 _ub,
        uint256 _ubTime,
        uint256 targetTime
    ) internal view returns (uint256) {
        uint256 lb = _lb;
        uint256 lbTime = _lbTime;
        uint256 ub = _ub;
        uint256 ubTime = _ubTime;
        uint256 len = ub.sub(lb);
        while (len > 1) {
            // upper bound >= lower bound + 2
            // mid > lower bound
            uint256 mid = lb.add(len.div(2));
            uint256 midTime = _getCreationTime(_getKeepAtIndex(mid));

            if (midTime >= targetTime) {
                ub = mid;
                ubTime = midTime;
            } else {
                lb = mid;
                lbTime = midTime;
            }
            len = ub.sub(lb);
        }
        return ub;
    }

    /// @notice Return the endpoint index of the interval,
    /// i.e. the number of keeps created in and before the interval.
    /// The interval must have ended; otherwise the endpoint might still change.
    /// @dev Uses a locally cached result, and stores the result if it isn't
    /// cached yet. All keeps created before the initiation fall in interval 0.
    /// @param interval The number of the interval.
    /// @return endpoint The number of keeps the factory had created
    /// before the end of the interval.
    function _getEndpoint(uint256 interval)
        internal
        mustBeFinished(interval)
        returns (uint256 endpoint)
    {
        // Get the endpoint from local cache;
        // might not be recorded yet
        uint256 maybeEndpoint = keepsByInterval[interval];

        // Either the endpoint is zero
        // (no keeps created by the end of the interval)
        // or the endpoint isn't cached yet
        if (maybeEndpoint == 0) {
            // Check what the real endpoint is
            // if the actual value is 0, this call short-circuits
            // so we don't need to special-case the zero
            uint256 realEndpoint = _findEndpoint(endOf(interval));
            // We didn't have the correct value cached,
            // so store it
            if (realEndpoint != 0) {
                keepsByInterval[interval] = realEndpoint;
            }
            endpoint = realEndpoint;
        } else {
            endpoint = maybeEndpoint;
        }
        return endpoint;
    }

    /// @notice Get the endpoint of the previous interval.
    /// @dev Like _getEndpoint, gracefully handles the beginning of interval 0.
    /// @param interval The interval.
    /// @return The number of keeps created by the end of the preceding interval.
    function _getPreviousEndpoint(uint256 interval) internal returns (uint256) {
        if (interval == 0) {
            return 0;
        } else {
            return _getEndpoint(interval.sub(1));
        }
    }

    /// @notice Calculate the reward allocation for an interval
    /// without adjusting for the number of keeps in the interval.
    /// @param interval The next interval to be allocated.
    /// Results for other intervals will not be accurate.
    /// @return The base reward allocation for the interval.
    function _baseAllocation(uint256 interval) internal view returns (uint256) {
        uint256 _unallocatedRewards = unallocatedRewards;
        uint256 weightPercentage = getIntervalWeight(interval);
        return _unallocatedRewards.mul(weightPercentage).div(100);
    }

    /// @notice Calculate the reward allocation for an interval
    /// after adjusting for the number of keeps in the interval.
    /// @dev An interval with at least `minimumKeepsPerInterval` keeps
    /// will have the full reward allocated to it.
    /// An interval with fewer keeps will only be allocated a fraction of the
    /// base reward equaling the fraction of the quota that was met.
    /// The reward allocated for each keep in the interval is constant
    /// regardless of the number of keeps in the interval until the quota is
    /// met, and further increases in the number of keeps will lead to the same
    /// allocation being shared among more of them. Each keep in an interval is
    /// allocated the same reward. If the number of keeps in an interval meets
    /// the quota, but the base allocation isn't divisible by the number of
    /// keeps, the remainder will remain unallocated.
    /// Allocations for an already allocated interval, or when all prior
    /// intervals haven't been allocated yet, will produce incorrect results.
    /// @param interval The next interval to be allocated.
    /// @return The amount of tokens to allocate as rewards for the interval.
    function _adjustedAllocation(uint256 interval) internal returns (uint256) {
        uint256 __baseAllocation = _baseAllocation(interval);
        if (__baseAllocation == 0) {
            return 0;
        }
        uint256 keepCount = keepsInInterval(interval);
        uint256 adjustmentCount = Math.max(keepCount, minimumKeepsPerInterval);
        if (adjustmentCount == 0) {
            return 0;
        }
        // Rewards divide equally among keeps
        return __baseAllocation.mul(keepCount).div(adjustmentCount);
    }

    /// @notice Process the rewards for the given keep, allocating finished
    /// intervals as necessary, and then either paying out the rewards to the
    /// keep's members or returning them to the unallocated pool, depending on
    /// the keep's eligibility.
    /// @param eligible Whether the keep is eligible for rewards or not.
    /// @param keepIdentifier The specified keep.
    function _processKeep(bool eligible, bytes32 keepIdentifier) internal {
        uint256 creationTime = _getCreationTime(keepIdentifier);
        uint256 interval = intervalOf(creationTime);
        if (!isAllocated(interval)) {
            allocateRewards(interval);
        }
        uint256 allocation = intervalAllocations[interval];
        uint256 _keepsInInterval = keepsInInterval(interval);
        uint256 perKeepReward = allocation.div(_keepsInInterval);
        claimed[keepIdentifier] = true;
        intervalKeepsProcessed[interval] = intervalKeepsProcessed[interval].add(
            1
        );

        if (eligible) {
            dispensedRewards = dispensedRewards.add(perKeepReward);
            _distributeReward(keepIdentifier, perKeepReward);
            emit RewardReceived(keepIdentifier, perKeepReward);
        } else {
            // Return the reward to the unallocated pool
            deallocate(perKeepReward);
        }
    }

    /// @notice Return the given amount to the unallocated pool.
    /// If the contract has been upgraded,
    /// the deallocated amount will be sent to the new contract.
    /// @param amount The amount to deallocate
    function deallocate(uint256 amount) internal {
        if (upgradeFinalizedTimestamp != 0) {
            bool success =
                token.approveAndCall(newRewardsContract, amount, bytes(""));
            if (!success) {
                unallocatedRewards = unallocatedRewards.add(amount);
            }
        } else {
            unallocatedRewards = unallocatedRewards.add(amount);
        }
    }

    /// @notice Get the total number of keeps ever created by the factory,
    /// including closed and terminated keeps.
    /// @return The number of keeps.
    function _getKeepCount() internal view returns (uint256);

    /// @notice Get the identifier of the keep at the given index,
    /// when all keeps created by the factory are ordered by creation time.
    /// @param index The index of the queried keep.
    /// @return The `bytes32` identifier of the keep at the given index.
    /// @dev Implementation is not required to check if a keep with the given
    /// index exists.
    function _getKeepAtIndex(uint256 index) internal view returns (bytes32);

    /// @notice Get the creation time of the given keep.
    /// @param _keep The identifier of the keep.
    /// @return The creation timestamp of the keep.
    /// @dev If the idenfifier is invalid or not recognized by factory, function
    /// may revert or return 0.
    function _getCreationTime(bytes32 _keep) internal view returns (uint256);

    /// @notice Is the given keep closed.
    /// @param _keep The identifier of the keep.
    /// @return True if the keep is closed, false otherwise.
    /// If the identifier is invalid, may return false or an error.
    function _isClosed(bytes32 _keep) internal view returns (bool);

    /// @notice Is the given keep terminated.
    /// @param _keep The identifier of the keep.
    /// @return True if the keep is terminated, false otherwise.
    /// If the identifier is invalid, may return false or an error.
    function _isTerminated(bytes32 _keep) internal view returns (bool);

    /// @notice Does the given `bytes32` identifier match a valid keep.
    /// @param _keep A possible keep identifier.
    /// @return True if the identifier matches a keep created by the factory.
    /// For any other identifier, must return false and not an error.
    function _recognizedByFactory(bytes32 _keep) internal view returns (bool);

    /// @notice Pay the given amount of tokens to members of the keep.
    /// @param _keep The keep whose members to reward.
    /// @param amount The total amount of tokens to distribute to the members.
    function _distributeReward(bytes32 _keep, uint256 amount) internal;

    modifier rewardsNotClaimed(bytes32 _keep) {
        require(!rewardClaimed(_keep), "Rewards already claimed");
        _;
    }

    modifier mustBeFinished(uint256 interval) {
        require(isFinished(interval), "Interval hasn't ended yet");
        _;
    }

    modifier mustBeClosed(bytes32 _keep) {
        require(_isClosed(_keep), "Keep is not closed");
        _;
    }

    modifier mustBeTerminated(bytes32 _keep) {
        require(_isTerminated(_keep), "Keep is not terminated");
        _;
    }

    modifier factoryMustRecognize(bytes32 _keep) {
        require(_recognizedByFactory(_keep), "Keep not recognized by factory");
        _;
    }

    modifier mustBeFunded() {
        require(funded, "Contract has not been funded yet");
        _;
    }
}

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

import "./utils/OperatorParams.sol";

/// @title Stake Delegatable
/// @notice A base contract to allow stake delegation for staking contracts.
contract StakeDelegatable {
    using OperatorParams for uint256;

    mapping(address => Operator) internal operators;

    struct Operator {
        uint256 packedParams;
        address owner;
        address payable beneficiary;
        address authorizer;
    }

    /// @notice Gets the stake balance of the specified address.
    /// @param _address The address to query the balance of.
    /// @return An uint256 representing the amount staked by the passed address.
    function balanceOf(address _address) public view returns (uint256 balance) {
        return operators[_address].packedParams.getAmount();
    }

    /// @notice Gets the stake owner for the specified operator address.
    /// @return Stake owner address.
    function ownerOf(address _operator) public view returns (address) {
        return operators[_operator].owner;
    }

    /// @notice Gets the beneficiary for the specified operator address.
    /// @return Beneficiary address.
    function beneficiaryOf(address _operator)
        public
        view
        returns (address payable)
    {
        return operators[_operator].beneficiary;
    }

    /// @notice Gets the authorizer for the specified operator address.
    /// @return Authorizer address.
    function authorizerOf(address _operator) public view returns (address) {
        return operators[_operator].authorizer;
    }
}

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
    event TokenGrantStaked(
        uint256 indexed grantId,
        uint256 amount,
        address operator
    );
    event TokenGrantRevoked(uint256 id);

    event StakingContractAuthorized(
        address indexed grantManager,
        address stakingContract
    );

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
    mapping(address => mapping(address => bool)) internal stakingContracts;

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
    function stakeBalanceOf(address _address)
        public
        view
        returns (uint256 balance)
    {
        for (uint256 i = 0; i < grantIndices[_address].length; i++) {
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
    function getGrant(uint256 _id)
        public
        view
        returns (
            uint256 amount,
            uint256 withdrawn,
            uint256 staked,
            uint256 revokedAmount,
            uint256 revokedAt,
            address grantee
        )
    {
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
    function getGrantUnlockingSchedule(uint256 _id)
        public
        view
        returns (
            address grantManager,
            uint256 duration,
            uint256 start,
            uint256 cliff,
            address policy
        )
    {
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
    function getGrants(address _granteeOrGrantManager)
        public
        view
        returns (uint256[] memory)
    {
        return grantIndices[_granteeOrGrantManager];
    }

    /// @notice Gets operator addresses of the specified grantee address.
    /// @param grantee The grantee address.
    /// @return An array of all operators for a given grantee.
    function getGranteeOperators(address grantee)
        public
        view
        returns (address[] memory)
    {
        return granteesToOperators[grantee];
    }

    /// @notice Gets grant stake details of the given operator.
    /// @param operator The operator address.
    /// @return grantId ID of the token grant.
    /// @return amount The amount of tokens the given operator delegated.
    /// @return stakingContract The address of staking contract.
    function getGrantStakeDetails(address operator)
        public
        view
        returns (
            uint256 grantId,
            uint256 amount,
            address stakingContract
        )
    {
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
    function receiveApproval(
        address _from,
        uint256 _amount,
        address _token,
        bytes memory _extraData
    ) public {
        require(
            ERC20Burnable(_token) == token,
            "Token contract must be the same one linked to this contract."
        );
        require(
            _amount <= token.balanceOf(_from),
            "Sender must have enough amount."
        );
        (
            address _grantManager,
            address _grantee,
            uint256 _duration,
            uint256 _start,
            uint256 _cliffDuration,
            bool _revocable,
            address _stakingPolicy
        ) =
            abi.decode(
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
            0,
            0,
            0,
            _revocable,
            _amount,
            _duration,
            _start,
            _start.add(_cliffDuration),
            0,
            0,
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
        require(
            amount > 0,
            "Grant available to withdraw amount should be greater than zero."
        );

        // Update withdrawn amount.
        grants[_id].withdrawn = grants[_id].withdrawn.add(amount);

        // Update grantee grants balance.
        balances[grants[_id].grantee] = balances[grants[_id].grantee].sub(
            amount
        );

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
        return
            (grant.revokedAt != 0) // Grant revoked -> return what is remaining
                ? grant.amount.sub(grant.revokedAmount) // Not revoked -> calculate the unlocked amount normally
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
        require(
            grants[_id].grantManager == msg.sender,
            "Only grant manager can revoke."
        );
        require(
            grants[_id].revocable,
            "Grant must be revocable in the first place."
        );
        require(
            grants[_id].revokedAt == 0,
            "Grant must not be already revoked."
        );

        uint256 unlockedAmount = unlockedAmount(_id);
        uint256 revokedAmount = grants[_id].amount.sub(unlockedAmount);
        grants[_id].revokedAt = now;
        grants[_id].revokedAmount = revokedAmount;

        // Update grantee's grants balance.
        balances[grants[_id].grantee] = balances[grants[_id].grantee].sub(
            revokedAmount
        );
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

        uint256 amountToWithdraw =
            remainingPresentInGrant < revokedRemaining
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
    function stake(
        uint256 _id,
        address _stakingContract,
        uint256 _amount,
        bytes memory _extraData
    ) public {
        require(
            grants[_id].grantee == msg.sender,
            "Only grantee of the grant can stake it."
        );
        require(grants[_id].revokedAt == 0, "Revoked grant can not be staked");
        require(
            stakingContracts[grants[_id].grantManager][_stakingContract],
            "Provided staking contract is not authorized."
        );

        // Expecting 60 bytes _extraData for stake delegation.
        require(
            _extraData.length == 60,
            "Stake delegation data must be provided."
        );
        address operator = _extraData.toAddress(20);

        // Calculate available amount. Amount of unlocked tokens minus what user already withdrawn and staked.
        require(
            _amount <= availableToStake(_id),
            "Must have available granted amount to stake."
        );

        // Keep staking record.
        TokenGrantStake grantStake =
            new TokenGrantStake(address(token), _id, _stakingContract);
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
        if (grant.revokedAt != 0) {
            return 0;
        }
        uint256 amount = grant.amount;
        uint256 withdrawn = grant.withdrawn;
        uint256 remaining = amount.sub(withdrawn);
        uint256 stakeable =
            grant.stakingPolicy.getStakeableAmount(
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
        require(grants[grantId].revokedAt != 0, "Grant must be revoked");
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
        require(grants[grantId].revokedAt != 0, "Grant must be revoked");
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

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./TokenStaking.sol";
import "./TokenSender.sol";
import "./utils/BytesLib.sol";

/// @dev Interface of sender contract for approveAndCall pattern.
interface tokenSender {
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes calldata _extraData
    ) external;
}

contract TokenGrantStake {
    using SafeMath for uint256;
    using BytesLib for bytes;

    ERC20Burnable token;
    TokenStaking tokenStaking;

    address tokenGrant; // Address of the master grant contract.

    uint256 grantId; // ID of the grant for this stake.
    uint256 amount; // Amount of staked tokens.
    address operator; // Operator of the stake.

    constructor(
        address _tokenAddress,
        uint256 _grantId,
        address _tokenStaking
    ) public {
        require(_tokenAddress != address(0x0), "Token address can't be zero.");
        require(
            _tokenStaking != address(0x0),
            "Staking contract address can't be zero."
        );

        token = ERC20Burnable(_tokenAddress);
        tokenGrant = msg.sender;
        grantId = _grantId;
        tokenStaking = TokenStaking(_tokenStaking);
    }

    function stake(uint256 _amount, bytes memory _extraData) public onlyGrant {
        amount = _amount;
        operator = _extraData.toAddress(20);
        tokenSender(address(token)).approveAndCall(
            address(tokenStaking),
            _amount,
            _extraData
        );
    }

    function getGrantId() public view onlyGrant returns (uint256) {
        return grantId;
    }

    function getAmount() public view onlyGrant returns (uint256) {
        return amount;
    }

    function getStakingContract() public view onlyGrant returns (address) {
        return address(tokenStaking);
    }

    function getDetails()
        public
        view
        onlyGrant
        returns (
            uint256 _grantId,
            uint256 _amount,
            address _tokenStaking
        )
    {
        return (grantId, amount, address(tokenStaking));
    }

    function cancelStake() public onlyGrant returns (uint256) {
        tokenStaking.cancelStake(operator);
        return returnTokens();
    }

    function undelegate() public onlyGrant {
        tokenStaking.undelegate(operator);
    }

    function recoverStake() public onlyGrant returns (uint256) {
        tokenStaking.recoverStake(operator);
        return returnTokens();
    }

    function returnTokens() internal returns (uint256) {
        uint256 returnedAmount = token.balanceOf(address(this));
        amount -= returnedAmount;
        token.transfer(tokenGrant, returnedAmount);
        return returnedAmount;
    }

    modifier onlyGrant {
        require(msg.sender == tokenGrant, "For token grant contract only");
        _;
    }
}

pragma solidity 0.5.17;

/// @dev Interface of sender contract for approveAndCall pattern.
interface TokenSender {
    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes calldata _extraData
    ) external;
}

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

    event StakeDelegated(address indexed owner, address indexed operator);
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
    event StakeLocked(
        address indexed operator,
        address lockCreator,
        uint256 until
    );
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
    ) public Authorizations(_registry) {
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
    function undelegationPeriod() public view returns (uint256) {
        return
            block.timestamp < deployedAt.add(twoMonths) ? twoWeeks : twoMonths;
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

        require(!_isInitialized(operatorParams), "Initialized stake");

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
    function undelegateAt(address _operator, uint256 _undelegationTimestamp)
        public
    {
        require(
            msg.sender == _operator ||
                msg.sender == operators[_operator].owner ||
                grantStaking.canUndelegate(_operator, tokenGrant),
            "Not authorized"
        );
        uint256 oldParams = operators[_operator].packedParams;
        require(
            _undelegationTimestamp >= block.timestamp &&
                _undelegationTimestamp >
                oldParams.getCreationTimestamp().add(initializationPeriod),
            "Invalid timestamp"
        );
        uint256 existingUndelegationTimestamp =
            oldParams.getUndelegationTimestamp();
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
        require(_isUndelegatingFinished(operatorParams), "Still undelegating");
        require(!isStakeLocked(_operator), "Locked stake");

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
        public
        view
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        return operators[_operator].packedParams.unpack();
    }

    /// @notice Locks given operator stake for the specified duration.
    /// Locked stake may not be recovered until the lock expires or is released,
    /// even if the normal undelegation period has passed.
    /// Only previously authorized operator contract can lock the stake.
    /// @param operator Operator address.
    /// @param duration Lock duration in seconds.
    function lockStake(address operator, uint256 duration)
        public
        onlyApprovedOperatorContract(msg.sender)
    {
        require(
            isAuthorizedForOperator(operator, msg.sender),
            "Not authorized"
        );

        uint256 operatorParams = operators[operator].packedParams;

        require(_isInitialized(operatorParams), "Inactive stake");
        require(!_isUndelegating(operatorParams), "Undelegating stake");

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
    function unlockStake(address operator) public {
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
    function releaseExpiredLock(address operator, address operatorContract)
        public
    {
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
        returns (address[] memory creators, uint256[] memory expirations)
    {
        return locks.getLocks(operator);
    }

    /// @notice Slash provided token amount from every member in the misbehaved
    /// operators array and burn 100% of all the tokens.
    /// @param amountToSlash Token amount to slash from every misbehaved operator.
    /// @param misbehavedOperators Array of addresses to seize the tokens from.
    function slash(uint256 amountToSlash, address[] memory misbehavedOperators)
        public
        onlyApprovedOperatorContract(msg.sender)
    {
        uint256 totalAmountToBurn;
        address authoritySource = getAuthoritySource(msg.sender);
        for (uint256 i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(
                authorizations[authoritySource][operator],
                "Not authorized"
            );

            uint256 operatorParams = operators[operator].packedParams;
            require(_isInitialized(operatorParams), "Inactive stake");

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
        for (uint256 i = 0; i < misbehavedOperators.length; i++) {
            address operator = misbehavedOperators[i];
            require(
                authorizations[authoritySource][operator],
                "Not authorized"
            );

            uint256 operatorParams = operators[operator].packedParams;
            require(_isInitialized(operatorParams), "Inactive stake");

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

        uint256 tattletaleReward =
            (totalAmountToBurn.percent(5)).percent(rewardMultiplier);

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
    function eligibleStake(address _operator, address _operatorContract)
        public
        view
        returns (uint256 balance)
    {
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
    function activeStake(address _operator, address _operatorContract)
        public
        view
        returns (uint256 balance)
    {
        uint256 operatorParams = operators[_operator].packedParams;
        if (
            isAuthorizedForOperator(_operator, _operatorContract) &&
            _isInitialized(operatorParams) &&
            !_isStakeReleased(_operator, operatorParams, _operatorContract)
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
    function hasMinimumStake(address staker, address operatorContract)
        public
        view
        returns (bool)
    {
        return activeStake(staker, operatorContract) >= minimumStake();
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
        bool isFromGrant =
            address(tokenGrant.grantStakes(_operator)) == _from ||
                address(escrow) == _from;

        if (grantStaking.hasGrantDelegated(_operator)) {
            // Operator has grant delegated. We need to see if the top-up
            // is performed also from a grant.
            require(isFromGrant, "Must be from a grant");
            // If it is from a grant, we need to make sure it's from the same
            // grant as the original delegation. We do not want to mix unlocking
            // schedules.
            uint256 previousGrantId =
                grantStaking.getGrantForOperator(_operator);
            (, uint256 grantId) =
                grantStaking.tryCapturingDelegationData(
                    tokenGrant,
                    address(escrow),
                    _from,
                    _operator,
                    _extraData
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
                _value,
                _operator,
                operatorParams,
                escrow
            );
        } else {
            // If the stake is initialized, we do NOT add tokens immediately.
            // We initiate the top-up and will add tokens to the stake only
            // after the initialization period for a top-up passes.
            topUps.initiate(_value, _operator, operatorParams, escrow);
        }
    }

    /// @notice Is the operator with the given params initialized
    function _isInitialized(uint256 _operatorParams)
        internal
        view
        returns (bool)
    {
        return
            block.timestamp >
            _operatorParams.getCreationTimestamp().add(initializationPeriod);
    }

    /// @notice Is the operator with the given params undelegating
    function _isUndelegating(uint256 _operatorParams)
        internal
        view
        returns (bool)
    {
        uint256 undelegatedAt = _operatorParams.getUndelegationTimestamp();
        return (undelegatedAt != 0) && (block.timestamp > undelegatedAt);
    }

    /// @notice Has the operator with the given params finished undelegating
    function _isUndelegatingFinished(uint256 _operatorParams)
        internal
        view
        returns (bool)
    {
        uint256 undelegatedAt = _operatorParams.getUndelegationTimestamp();
        return
            (undelegatedAt != 0) &&
            (block.timestamp > undelegatedAt.add(undelegationPeriod()));
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
        return
            _isUndelegatingFinished(_operatorParams) &&
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
                abi.encode(
                    _operator,
                    grantStaking.getGrantForOperator(_operator)
                )
            );
        } else {
            // For liquid tokens staked, transfer them straight to the owner.
            token.safeTransfer(_owner, _amount);
        }
    }
}

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
    event EscrowAuthorized(address indexed grantManager, address escrow);

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
    mapping(address => mapping(address => bool)) internal authorizedEscrows;

    constructor(KeepToken _keepToken, TokenGrant _tokenGrant) public {
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

        (address operator, uint256 grantId) =
            abi.decode(extraData, (address, uint256));
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

        deposits[previousOperator].redelegated = deposit.redelegated.add(
            amount
        );

        TokenSender(address(keepToken)).approveAndCall(
            owner(), // TokenStaking contract associated with the escrow
            amount,
            abi.encodePacked(extraData, grantId)
        );

        emit DepositRedelegated(previousOperator, newOperator, grantId, amount);
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
    function depositWithdrawnAmount(address operator)
        public
        view
        returns (uint256)
    {
        return deposits[operator].withdrawn;
    }

    /// @notice Returns the total amount redelegated so far from the value
    /// deposited in the escrow contract after undelegating it from the provided
    /// operator.
    /// @param operator Address of the operator from the undelegated/canceled
    /// delegation from which tokens were deposited.
    function depositRedelegatedAmount(address operator)
        public
        view
        returns (uint256)
    {
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
            (uint256 duration, uint256 start, uint256 cliff) =
                getUnlockingSchedule(deposit.grantId);

            uint256 unlocked =
                now.getUnlockedAmount(deposit.amount, duration, start, cliff);

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
        (bool success, ) =
            address(this).call(
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
    function migrate(address operator, address receivingEscrow) public {
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
        require(anotherEscrow != address(0x0), "Escrow address can't be zero");
        authorizedEscrows[msg.sender][anotherEscrow] = true;
        emit EscrowAuthorized(msg.sender, anotherEscrow);
    }

    /// @notice Resolves the final grantee of ManagedGrant contract. If the
    /// provided address is not a ManagedGrant contract, function reverts.
    /// @param managedGrant Address of the managed grant contract.
    function getManagedGrantee(address managedGrant)
        public
        view
        returns (address)
    {
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

    function isGrantee(address maybeGrantee, uint256 grantId)
        internal
        returns (bool)
    {
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
        (, bytes memory result) =
            address(this).call(
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

    function getAmountGranted(uint256 grantId)
        internal
        view
        returns (uint256 amountGranted)
    {
        (amountGranted, , , , , ) = tokenGrant.getGrant(grantId);
    }

    function getAmountRevoked(uint256 grantId)
        internal
        view
        returns (uint256 amountRevoked)
    {
        (, , , amountRevoked, , ) = tokenGrant.getGrant(grantId);
    }

    function getUnlockingSchedule(uint256 grantId)
        internal
        view
        returns (
            uint256 duration,
            uint256 start,
            uint256 cliff
        )
    {
        (, duration, start, cliff, ) = tokenGrant.getGrantUnlockingSchedule(
            grantId
        );
    }

    function getGrantee(uint256 grantId)
        internal
        view
        returns (address grantee)
    {
        (, , , , , grantee) = tokenGrant.getGrant(grantId);
    }

    function getGrantManager(uint256 grantId)
        internal
        view
        returns (address grantManager)
    {
        (grantManager, , , , ) = tokenGrant.getGrantUnlockingSchedule(grantId);
    }
}

pragma solidity 0.5.17;

import "../utils/ModUtils.sol";

/**
 * @title Operations on alt_bn128
 * @dev Implementations of common elliptic curve operations on Ethereum's
 * (poorly named) alt_bn128 curve. Whenever possible, use post-Byzantium
 * pre-compiled contracts to offset gas costs. Note that these pre-compiles
 * might not be available on all (eg private) chains.
 */
library AltBn128 {
    using ModUtils for uint256;

    // G1Point implements a point in G1 group.
    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // gfP2 implements a field of size p² as a quadratic extension of the base field.
    struct gfP2 {
        uint256 x;
        uint256 y;
    }

    // G2Point implements a point in G2 group.
    struct G2Point {
        gfP2 x;
        gfP2 y;
    }

    // p is a prime over which we form a basic field
    // Taken from go-ethereum/crypto/bn256/cloudflare/constants.go
    uint256 constant p =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    function getP() internal pure returns (uint256) {
        return p;
    }

    /**
     * @dev Gets generator of G1 group.
     * Taken from go-ethereum/crypto/bn256/cloudflare/curve.go
     */
    uint256 constant g1x = 1;
    uint256 constant g1y = 2;

    function g1() internal pure returns (G1Point memory) {
        return G1Point(g1x, g1y);
    }

    /**
     * @dev Gets generator of G2 group.
     * Taken from go-ethereum/crypto/bn256/cloudflare/twist.go
     */
    uint256 constant g2xx =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant g2xy =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant g2yx =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant g2yy =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;

    function g2() internal pure returns (G2Point memory) {
        return G2Point(gfP2(g2xx, g2xy), gfP2(g2yx, g2yy));
    }

    /**
     * @dev Gets twist curve B constant.
     * Taken from go-ethereum/crypto/bn256/cloudflare/twist.go
     */
    uint256 constant twistBx =
        266929791119991161246907387137283842545076965332900288569378510910307636690;
    uint256 constant twistBy =
        19485874751759354771024239261021720505790618469301721065564631296452457478373;

    function twistB() private pure returns (gfP2 memory) {
        return gfP2(twistBx, twistBy);
    }

    /**
     * @dev Gets root of the point where x and y are equal.
     */
    uint256 constant hexRootX =
        21573744529824266246521972077326577680729363968861965890554801909984373949499;
    uint256 constant hexRootY =
        16854739155576650954933913186877292401521110422362946064090026408937773542853;

    function hexRoot() private pure returns (gfP2 memory) {
        return gfP2(hexRootX, hexRootY);
    }

    /**
     * @dev g1YFromX computes a Y value for a G1 point based on an X value.
     * This computation is simply evaluating the curve equation for Y on a
     * given X, and allows a point on the curve to be represented by just
     * an X value + a sign bit.
     */
    function g1YFromX(uint256 x) internal view returns (uint256) {
        return ((x.modExp(3, p) + 3) % p).modSqrt(p);
    }

    /**
     * @dev g2YFromX computes a Y value for a G2 point based on an X value.
     * This computation is simply evaluating the curve equation for Y on a
     * given X, and allows a point on the curve to be represented by just
     * an X value + a sign bit.
     */
    function g2YFromX(gfP2 memory _x) internal pure returns (gfP2 memory y) {
        (uint256 xx, uint256 xy) = _gfP2CubeAddTwistB(_x.x, _x.y);

        // Using formula y = x ^ (p^2 + 15) / 32 from
        // https://github.com/ethereum/beacon_chain/blob/master/beacon_chain/utils/bls.py
        // (p^2 + 15) / 32 results into a big 512bit value, so breaking it to two uint256 as (a * a + b)
        uint256 a =
            3869331240733915743250440106392954448556483137451914450067252501901456824595;
        uint256 b =
            146360017852723390495514512480590656176144969185739259173561346299185050597;

        (uint256 xbx, uint256 xby) = _gfP2Pow(xx, xy, b);
        (uint256 yax, uint256 yay) = _gfP2Pow(xx, xy, a);
        (uint256 ya2x, uint256 ya2y) = _gfP2Pow(yax, yay, a);
        (y.x, y.y) = _gfP2Multiply(ya2x, ya2y, xbx, xby);

        // Multiply y by hexRoot constant to find correct y.
        while (!_g2X2y(xx, xy, y.x, y.y)) {
            (y.x, y.y) = _gfP2Multiply(y.x, y.y, hexRootX, hexRootY);
        }
    }

    /**
     * @dev Hash a byte array message, m, and map it deterministically to a
     * point on G1. Note that this approach was chosen for its simplicity /
     * lower gas cost on the EVM, rather than good distribution of points on
     * G1.
     */
    function g1HashToPoint(bytes memory m)
        internal
        view
        returns (G1Point memory)
    {
        bytes32 h = sha256(m);
        uint256 x = uint256(h) % p;
        uint256 y;

        while (true) {
            y = g1YFromX(x);
            if (y > 0) {
                return G1Point(x, y);
            }
            x += 1;
        }
    }

    /**
     * @dev Calculates whether the provided number is even or odd.
     * @return 0x01 if y is an even number and 0x00 if it's odd.
     */
    function parity(uint256 value) private pure returns (bytes1) {
        return bytes32(value)[31] & 0x01;
    }

    /**
     * @dev Compress a point on G1 to a single uint256 for serialization.
     */
    function g1Compress(G1Point memory point) internal pure returns (bytes32) {
        bytes32 m = bytes32(point.x);

        bytes1 leadM = m[0] | (parity(point.y) << 7);
        uint256 mask = 0xff << (31 * 8);
        m = (m & ~bytes32(mask)) | (leadM >> 0);

        return m;
    }

    /**
     * @dev Compress a point on G2 to a pair of uint256 for serialization.
     */
    function g2Compress(G2Point memory point)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 m = bytes32(point.x.x);

        bytes1 leadM = m[0] | (parity(point.y.x) << 7);
        uint256 mask = 0xff << (31 * 8);
        m = (m & ~bytes32(mask)) | (leadM >> 0);

        return abi.encodePacked(m, bytes32(point.x.y));
    }

    /**
     * @dev Decompress a point on G1 from a single uint256.
     */
    function g1Decompress(bytes32 m) internal view returns (G1Point memory) {
        bytes32 mX = bytes32(0);
        bytes1 leadX = m[0] & 0x7f;
        uint256 mask = 0xff << (31 * 8);
        mX = (m & ~bytes32(mask)) | (leadX >> 0);

        uint256 x = uint256(mX);
        uint256 y = g1YFromX(x);

        if (parity(y) != (m[0] & 0x80) >> 7) {
            y = p - y;
        }

        require(isG1PointOnCurve(G1Point(x, y)), "Malformed bn256.G1 point.");

        return G1Point(x, y);
    }

    /**
     * @dev Unmarshals a point on G1 from bytes in an uncompressed form.
     */
    function g1Unmarshal(bytes memory m)
        internal
        pure
        returns (G1Point memory)
    {
        require(m.length == 64, "Invalid G1 bytes length");

        bytes32 x;
        bytes32 y;

        /* solium-disable-next-line */
        assembly {
            x := mload(add(m, 0x20))
            y := mload(add(m, 0x40))
        }

        return G1Point(uint256(x), uint256(y));
    }

    /**
     * @dev Marshals a point on G1 to bytes form.
     */
    function g1Marshal(G1Point memory point)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory m = new bytes(64);
        bytes32 x = bytes32(point.x);
        bytes32 y = bytes32(point.y);

        /* solium-disable-next-line */
        assembly {
            mstore(add(m, 32), x)
            mstore(add(m, 64), y)
        }

        return m;
    }

    /**
     * @dev Unmarshals a point on G2 from bytes in an uncompressed form.
     */
    function g2Unmarshal(bytes memory m)
        internal
        pure
        returns (G2Point memory)
    {
        require(m.length == 128, "Invalid G2 bytes length");

        uint256 xx;
        uint256 xy;
        uint256 yx;
        uint256 yy;

        /* solium-disable-next-line */
        assembly {
            xx := mload(add(m, 0x20))
            xy := mload(add(m, 0x40))
            yx := mload(add(m, 0x60))
            yy := mload(add(m, 0x80))
        }

        return G2Point(gfP2(xx, xy), gfP2(yx, yy));
    }

    /**
     * @dev Decompress a point on G2 from a pair of uint256.
     */
    function g2Decompress(bytes memory m)
        internal
        pure
        returns (G2Point memory)
    {
        require(m.length == 64, "Invalid G2 compressed bytes length");

        bytes32 x1;
        bytes32 x2;
        uint256 temp;

        // Extract two bytes32 from bytes array
        /* solium-disable-next-line */
        assembly {
            temp := add(m, 32)
            x1 := mload(temp)
            temp := add(m, 64)
            x2 := mload(temp)
        }

        bytes32 mX = bytes32(0);
        bytes1 leadX = x1[0] & 0x7f;
        uint256 mask = 0xff << (31 * 8);
        mX = (x1 & ~bytes32(mask)) | (leadX >> 0);

        gfP2 memory x = gfP2(uint256(mX), uint256(x2));
        gfP2 memory y = g2YFromX(x);

        if (parity(y.x) != (m[0] & 0x80) >> 7) {
            y.x = p - y.x;
            y.y = p - y.y;
        }

        return G2Point(x, y);
    }

    /**
     * @dev Wrap the point addition pre-compile introduced in Byzantium. Return
     * the sum of two points on G1. Revert if the provided points aren't on the
     * curve.
     */
    function g1Add(G1Point memory a, G1Point memory b)
        internal
        view
        returns (G1Point memory c)
    {
        /* solium-disable-next-line */
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(a))
            mstore(add(arg, 0x20), mload(add(a, 0x20)))
            mstore(add(arg, 0x40), mload(b))
            mstore(add(arg, 0x60), mload(add(b, 0x20)))
            // 0x60 is the ECADD precompile address
            if iszero(staticcall(not(0), 0x06, arg, 0x80, c, 0x40)) {
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Return the sum of two gfP2 field elements.
     */
    function gfP2Add(gfP2 memory a, gfP2 memory b)
        internal
        pure
        returns (gfP2 memory)
    {
        return gfP2(addmod(a.x, b.x, p), addmod(a.y, b.y, p));
    }

    /**
     * @dev Return multiplication of two gfP2 field elements.
     */
    function gfP2Multiply(gfP2 memory a, gfP2 memory b)
        internal
        pure
        returns (gfP2 memory)
    {
        return
            gfP2(
                addmod(mulmod(a.x, b.y, p), mulmod(b.x, a.y, p), p),
                addmod(mulmod(a.y, b.y, p), p - mulmod(a.x, b.x, p), p)
            );
    }

    /**
     * @dev Return gfP2 element to the power of the provided exponent.
     */
    function gfP2Pow(gfP2 memory _a, uint256 _exp)
        internal
        pure
        returns (gfP2 memory result)
    {
        (uint256 x, uint256 y) = _gfP2Pow(_a.x, _a.y, _exp);
        return gfP2(x, y);
    }

    function gfP2Square(gfP2 memory a) internal pure returns (gfP2 memory) {
        return gfP2Multiply(a, a);
    }

    function gfP2Cube(gfP2 memory a) internal pure returns (gfP2 memory) {
        return gfP2Multiply(a, gfP2Square(a));
    }

    function gfP2CubeAddTwistB(gfP2 memory a)
        internal
        pure
        returns (gfP2 memory)
    {
        (uint256 x, uint256 y) = _gfP2CubeAddTwistB(a.x, a.y);
        return gfP2(x, y);
    }

    /**
     * @dev Return true if G2 point's y^2 equals x.
     */
    function g2X2y(gfP2 memory x, gfP2 memory y) internal pure returns (bool) {
        gfP2 memory y2;
        y2 = gfP2Square(y);

        return (y2.x == x.x && y2.y == x.y);
    }

    /**
     * @dev Return true if G1 point is on the curve.
     */
    function isG1PointOnCurve(G1Point memory point)
        internal
        view
        returns (bool)
    {
        return point.y.modExp(2, p) == (point.x.modExp(3, p) + 3) % p;
    }

    /**
     * @dev Return true if G2 point is on the curve.
     */
    function isG2PointOnCurve(G2Point memory point)
        internal
        pure
        returns (bool)
    {
        (uint256 y2x, uint256 y2y) = _gfP2Square(point.y.x, point.y.y);
        (uint256 x3x, uint256 x3y) = _gfP2CubeAddTwistB(point.x.x, point.x.y);

        return (y2x == x3x && y2y == x3y);
    }

    /**
     * @dev Wrap the scalar point multiplication pre-compile introduced in
     * Byzantium. The result of a point from G1 multiplied by a scalar should
     * match the point added to itself the same number of times. Revert if the
     * provided point isn't on the curve.
     */
    function scalarMultiply(G1Point memory p_1, uint256 scalar)
        internal
        view
        returns (G1Point memory p_2)
    {
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(p_1))
            mstore(add(arg, 0x20), mload(add(p_1, 0x20)))
            mstore(add(arg, 0x40), scalar)
            // 0x07 is the ECMUL precompile address
            if iszero(staticcall(not(0), 0x07, arg, 0x60, p_2, 0x40)) {
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Wrap the pairing check pre-compile introduced in Byzantium. Return
     * the result of a pairing check of 2 pairs (G1 p1, G2 p2) (G1 p3, G2 p4)
     */
    function pairing(
        G1Point memory p1,
        G2Point memory p2,
        G1Point memory p3,
        G2Point memory p4
    ) internal view returns (bool result) {
        uint256 _c;
        /* solium-disable-next-line */
        assembly {
            let c := mload(0x40)
            let arg := add(c, 0x20)

            mstore(arg, mload(p1))
            mstore(add(arg, 0x20), mload(add(p1, 0x20)))

            let p2x := mload(p2)
            mstore(add(arg, 0x40), mload(p2x))
            mstore(add(arg, 0x60), mload(add(p2x, 0x20)))

            let p2y := mload(add(p2, 0x20))
            mstore(add(arg, 0x80), mload(p2y))
            mstore(add(arg, 0xa0), mload(add(p2y, 0x20)))

            mstore(add(arg, 0xc0), mload(p3))
            mstore(add(arg, 0xe0), mload(add(p3, 0x20)))

            let p4x := mload(p4)
            mstore(add(arg, 0x100), mload(p4x))
            mstore(add(arg, 0x120), mload(add(p4x, 0x20)))

            let p4y := mload(add(p4, 0x20))
            mstore(add(arg, 0x140), mload(p4y))
            mstore(add(arg, 0x160), mload(add(p4y, 0x20)))

            // call(gasLimit, to, value, inputOffset, inputSize, outputOffset, outputSize)
            if iszero(staticcall(not(0), 0x08, arg, 0x180, c, 0x20)) {
                revert(0, 0)
            }
            _c := mload(c)
        }
        return _c != 0;
    }

    function _gfP2Add(
        uint256 ax,
        uint256 ay,
        uint256 bx,
        uint256 by
    ) private pure returns (uint256 x, uint256 y) {
        x = addmod(ax, bx, p);
        y = addmod(ay, by, p);
    }

    function _gfP2Multiply(
        uint256 ax,
        uint256 ay,
        uint256 bx,
        uint256 by
    ) private pure returns (uint256 x, uint256 y) {
        x = addmod(mulmod(ax, by, p), mulmod(bx, ay, p), p);
        y = addmod(mulmod(ay, by, p), p - mulmod(ax, bx, p), p);
    }

    function _gfP2CubeAddTwistB(uint256 ax, uint256 ay)
        private
        pure
        returns (uint256 x, uint256 y)
    {
        (uint256 a3x, uint256 a3y) = _gfP2Cube(ax, ay);
        return _gfP2Add(a3x, a3y, twistBx, twistBy);
    }

    function _gfP2Pow(
        uint256 _ax,
        uint256 _ay,
        uint256 _exp
    ) private pure returns (uint256 x, uint256 y) {
        uint256 exp = _exp;
        x = 0;
        y = 1;
        uint256 ax = _ax;
        uint256 ay = _ay;

        // Reduce exp dividing by 2 gradually to 0 while computing final
        // result only when exp is an odd number.
        while (exp > 0) {
            if (parity(exp) == 0x01) {
                (x, y) = _gfP2Multiply(x, y, ax, ay);
            }

            exp = exp / 2;
            (ax, ay) = _gfP2Multiply(ax, ay, ax, ay);
        }
    }

    function _gfP2Square(uint256 _ax, uint256 _ay)
        private
        pure
        returns (uint256 x, uint256 y)
    {
        return _gfP2Multiply(_ax, _ay, _ax, _ay);
    }

    function _gfP2Cube(uint256 _ax, uint256 _ay)
        private
        pure
        returns (uint256 x, uint256 y)
    {
        (uint256 _bx, uint256 _by) = _gfP2Square(_ax, _ay);
        return _gfP2Multiply(_ax, _ay, _bx, _by);
    }

    function _g2X2y(
        uint256 xx,
        uint256 xy,
        uint256 yx,
        uint256 yy
    ) private pure returns (bool) {
        (uint256 y2x, uint256 y2y) = _gfP2Square(yx, yy);

        return (y2x == xx && y2y == xy);
    }
}

pragma solidity 0.5.17;

import "./AltBn128.sol";

/**
 * @title BLS signatures verification
 * @dev Library for verification of 2-pairing-check BLS signatures, including
 * basic, aggregated, or reconstructed threshold BLS signatures, generated
 * using the AltBn128 curve.
 */
library BLS {
    /**
     * @dev Creates a signature over message using the provided secret key.
     */
    function sign(bytes memory message, uint256 secretKey)
        public
        view
        returns (bytes memory)
    {
        AltBn128.G1Point memory p_1 = AltBn128.g1HashToPoint(message);
        AltBn128.G1Point memory p_2 = AltBn128.scalarMultiply(p_1, secretKey);

        return AltBn128.g1Marshal(p_2);
    }

    /**
     * @dev Verify performs the pairing operation to check if the signature
     * is correct for the provided message and the corresponding public key.
     * Public key must be a valid point on G2 curve in an uncompressed format.
     * Message must be a valid point on G1 curve in an uncompressed format.
     * Signature must be a valid point on G1 curve in an uncompressed format.
     */
    function verify(
        bytes memory publicKey,
        bytes memory message,
        bytes memory signature
    ) public view returns (bool) {
        AltBn128.G1Point memory _signature = AltBn128.g1Unmarshal(signature);

        return
            AltBn128.pairing(
                AltBn128.G1Point(_signature.x, AltBn128.getP() - _signature.y),
                AltBn128.g2(),
                AltBn128.g1Unmarshal(message),
                AltBn128.g2Unmarshal(publicKey)
            );
    }

    /**
     * @dev VerifyBytes wraps the functionality of BLS.verify, but hashes a message
     * to a point on G1 and marshal to bytes first to allow raw bytes verificaion.
     */
    function verifyBytes(
        bytes memory publicKey,
        bytes memory message,
        bytes memory signature
    ) public view returns (bool) {
        AltBn128.G1Point memory point = AltBn128.g1HashToPoint(message);
        bytes memory messageAsPoint = AltBn128.g1Marshal(point);

        return verify(publicKey, messageAsPoint, signature);
    }
}

pragma solidity 0.5.17;

import "../utils/AddressArrayUtils.sol";
import "../StakeDelegatable.sol";
import "../TokenGrant.sol";
import "../ManagedGrant.sol";

/// @title Roles Lookup
/// @notice Library facilitating lookup of roles in stake delegation setup.
library RolesLookup {
    using AddressArrayUtils for address[];

    /// @notice Returns true if the tokenOwner delegated tokens to operator
    /// using the provided stakeDelegatable contract. Othwerwise, returns false.
    /// This function works only for the case when tokenOwner own those tokens
    /// and those are not tokens from a grant.
    function isTokenOwnerForOperator(
        address tokenOwner,
        address operator,
        StakeDelegatable stakeDelegatable
    ) internal view returns (bool) {
        return stakeDelegatable.ownerOf(operator) == tokenOwner;
    }

    /// @notice Returns true if the grantee delegated tokens to operator
    /// with the provided tokenGrant contract. Otherwise, returns false.
    /// This function works only for the case when tokens were generated from
    /// a non-managed grant, that is, the grantee is a non-contract address to
    /// which the delegated tokens were granted.
    /// @dev This function does not validate the staking reltionship on
    /// a particular staking contract. It only checks whether the grantee
    /// staked at least one time with the given operator. If you are interested
    /// in a particular token staking contract, you need to perform additional
    /// check.
    function isGranteeForOperator(
        address grantee,
        address operator,
        TokenGrant tokenGrant
    ) internal view returns (bool) {
        address[] memory operators = tokenGrant.getGranteeOperators(grantee);
        return operators.contains(operator);
    }

    /// @notice Returns true if the grantee from the given managed grant contract
    /// delegated tokens to operator with the provided tokenGrant contract.
    /// Otherwise, returns false. In case the grantee declared by the managed
    /// grant contract does not match the provided grantee, function reverts.
    /// This function works only for cases when grantee, from TokenGrant's
    /// perspective, is a smart contract exposing grantee() function returning
    /// the final grantee. One possibility is the ManagedGrant contract.
    /// @dev This function does not validate the staking reltionship on
    /// a particular staking contract. It only checks whether the grantee
    /// staked at least one time with the given operator. If you are interested
    /// in a particular token staking contract, you need to perform additional
    /// check.
    function isManagedGranteeForOperator(
        address grantee,
        address operator,
        address managedGrantContract,
        TokenGrant tokenGrant
    ) internal view returns (bool) {
        require(
            ManagedGrant(managedGrantContract).grantee() == grantee,
            "Not a grantee of the provided contract"
        );

        address[] memory operators =
            tokenGrant.getGranteeOperators(managedGrantContract);
        return operators.contains(operator);
    }

    /// @notice Returns true if grant with the given ID has been created with
    /// managed grant pointing currently to the grantee passed as a parameter.
    /// @dev The function does not revert if grant has not been created with
    /// a managed grantee. This function is not a view because it uses low-level
    /// call to check if the grant has been created with a managed grant.
    /// It does not however modify any state.
    function isManagedGranteeForGrant(
        address grantee,
        uint256 grantId,
        TokenGrant tokenGrant
    ) internal returns (bool) {
        (, , , , , address managedGrant) = tokenGrant.getGrant(grantId);
        (, bytes memory result) =
            managedGrant.call(abi.encodeWithSignature("grantee()"));
        if (result.length == 0) {
            return false;
        }
        address managedGrantee = abi.decode(result, (address));
        return grantee == managedGrantee;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library UnlockingSchedule {
    using SafeMath for uint256;

    function getUnlockedAmount(
        uint256 _now,
        uint256 grantedAmount,
        uint256 duration,
        uint256 start,
        uint256 cliff
    ) internal pure returns (uint256) {
        bool cliffNotReached = _now < cliff;
        if (cliffNotReached) {
            return 0;
        }

        uint256 timeElapsed = _now.sub(start);

        bool unlockingPeriodFinished = timeElapsed >= duration;
        if (unlockingPeriodFinished) {
            return grantedAmount;
        }

        return grantedAmount.mul(timeElapsed).div(duration);
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "../../utils/BytesLib.sol";
import "./GroupSelection.sol";

library DKGResultVerification {
    using BytesLib for bytes;
    using ECDSA for bytes32;
    using GroupSelection for GroupSelection.Storage;

    struct Storage {
        // Time in blocks after which DKG result is complete and ready to be
        // published by clients.
        uint256 timeDKG;
        // Time in blocks after which the next group member is eligible
        // to submit DKG result.
        uint256 resultPublicationBlockStep;
        // Size of a group in the threshold relay.
        uint256 groupSize;
        // The minimum number of signatures required to support DKG result.
        // This number needs to be at least the same as the signing threshold
        // and it is recommended to make it higher than the signing threshold
        // to keep a safety margin for misbehaving members.
        uint256 signatureThreshold;
    }

    /// @notice Verifies the submitted DKG result against supporting member
    /// signatures and if the submitter is eligible to submit at the current
    /// block. Every signature supporting the result has to be from a unique
    /// group member.
    ///
    /// @param submitterMemberIndex Claimed submitter candidate group member index
    /// @param groupPubKey Generated candidate group public key
    /// @param misbehaved Bytes array of misbehaved (disqualified or inactive)
    /// group members indexes; Indexes reflect positions of members in the group,
    /// as outputted by the group selection protocol.
    /// @param signatures Concatenation of signatures from members supporting the
    /// result.
    /// @param signingMemberIndices Indices of members corresponding to each
    /// signature. Indices have to be unique.
    /// @param members Addresses of candidate group members as outputted by the
    /// group selection protocol.
    /// @param groupSelectionEndBlock Block height at which the group selection
    /// protocol ended.
    function verify(
        Storage storage self,
        uint256 submitterMemberIndex,
        bytes memory groupPubKey,
        bytes memory misbehaved,
        bytes memory signatures,
        uint256[] memory signingMemberIndices,
        address[] memory members,
        uint256 groupSelectionEndBlock
    ) public view {
        require(submitterMemberIndex > 0, "Invalid submitter index");
        require(
            members[submitterMemberIndex - 1] == msg.sender,
            "Unexpected submitter index"
        );

        uint256 T_init = groupSelectionEndBlock + self.timeDKG;
        require(
            block.number >=
                (T_init +
                    (submitterMemberIndex - 1) *
                    self.resultPublicationBlockStep),
            "Submitter not eligible"
        );

        require(groupPubKey.length == 128, "Malformed group public key");

        require(
            misbehaved.length <= self.groupSize - self.signatureThreshold,
            "Malformed misbehaved bytes"
        );

        uint256 signaturesCount = signatures.length / 65;
        require(signatures.length >= 65, "Too short signatures array");
        require(signatures.length % 65 == 0, "Malformed signatures array");
        require(
            signaturesCount == signingMemberIndices.length,
            "Unexpected signatures count"
        );
        require(
            signaturesCount >= self.signatureThreshold,
            "Too few signatures"
        );
        require(signaturesCount <= self.groupSize, "Too many signatures");

        bytes32 resultHash =
            keccak256(abi.encodePacked(groupPubKey, misbehaved));

        bytes memory current; // Current signature to be checked.

        bool[] memory usedMemberIndices = new bool[](self.groupSize);

        for (uint256 i = 0; i < signaturesCount; i++) {
            uint256 memberIndex = signingMemberIndices[i];
            require(memberIndex > 0, "Invalid index");
            require(memberIndex <= members.length, "Index out of range");

            require(
                !usedMemberIndices[memberIndex - 1],
                "Duplicate member index"
            );
            usedMemberIndices[memberIndex - 1] = true;

            current = signatures.slice(65 * i, 65);
            address recoveredAddress =
                resultHash.toEthSignedMessageHash().recover(current);
            require(
                members[memberIndex - 1] == recoveredAddress,
                "Invalid signature"
            );
        }
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library DelayFactor {
    using SafeMath for uint256;

    /// @notice Gets delay factor for rewards calculation.
    /// @return Integer representing floating-point number with 16 decimals places.
    function calculate(
        uint256 currentRequestStartBlock,
        uint256 relayEntryTimeout
    ) public view returns (uint256 delayFactor) {
        uint256 decimals = 1e16; // Adding 16 decimals to perform float division.

        // T_deadline is the earliest block when no submissions are accepted
        // and an entry timed out. The last block the entry can be published in is
        //     currentRequestStartBlock + relayEntryTimeout
        // and submission are no longer accepted from block
        //     currentRequestStartBlock + relayEntryTimeout + 1.
        uint256 deadlineBlock =
            currentRequestStartBlock.add(relayEntryTimeout).add(1);

        // T_begin is the earliest block the result can be published in.
        // Relay entry can be generated instantly after relay request is
        // registered on-chain so a new entry can be published at the next
        // block the earliest.
        uint256 submissionStartBlock = currentRequestStartBlock.add(1);

        // Use submissionStartBlock block as entryReceivedBlock if entry submitted earlier than expected.
        uint256 entryReceivedBlock =
            block.number <= submissionStartBlock
                ? submissionStartBlock
                : block.number;

        // T_remaining = T_deadline - T_received
        uint256 remainingBlocks = deadlineBlock.sub(entryReceivedBlock);

        // T_deadline - T_begin
        uint256 submissionWindow = deadlineBlock.sub(submissionStartBlock);

        // delay factor = [ T_remaining / (T_deadline - T_begin)]^2
        //
        // Since we add 16 decimal places to perform float division, we do:
        // delay factor = [ T_temaining * decimals / (T_deadline - T_begin)]^2 / decimals =
        //    = [T_remaining / (T_deadline - T_begin) ]^2 * decimals
        delayFactor = ((remainingBlocks.mul(decimals).div(submissionWindow))**2)
            .div(decimals);
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../utils/BytesLib.sol";

/// @title Group Selection
/// @notice The group selection protocol is an interactive method of selecting
/// candidate group from the set of all stakers given a pseudorandom seed value.
///
/// The protocol produces a representative result, where each staker's profit is
/// proportional to the number of tokens they have staked. Produced candidate
/// groups are of constant size.
///
/// Group selection protocol accepts seed as an input - a pseudorandom value
/// used to construct candidate tickets. Each candidate group member can
/// submit their tickets. The maximum number of tickets one can submit depends
/// on their staking weight - relation of the minimum stake to the candidate's
/// stake.
///
/// There is a certain timeout, expressed in blocks, when tickets can be
/// submitted. Each ticket is a mix of staker's address, virtual staker index
/// and group selection seed. Candidate group members are selected based on
/// the best tickets submitted. There has to be a minimum number of tickets
/// submitted, equal to the candidate group size so that the protocol can
/// complete successfully.
library GroupSelection {
    using SafeMath for uint256;
    using BytesLib for bytes;

    struct Storage {
        // Tickets submitted by member candidates during the current group
        // selection execution and accepted by the protocol for the
        // consideration.
        uint64[] tickets;
        // Information about ticket submitters (group member candidates).
        mapping(uint256 => address) candidate;
        // Pseudorandom seed value used as an input for the group selection.
        uint256 seed;
        // Timeout in blocks after which the ticket submission is finished.
        uint256 ticketSubmissionTimeout;
        // Number of block at which the group selection started and from which
        // ticket submissions are accepted.
        uint256 ticketSubmissionStartBlock;
        // Indicates whether a group selection is currently in progress.
        // Concurrent group selections are not allowed.
        bool inProgress;
        // Captures the minimum stake when group selection starts. This is to ensure the
        // same staking weight divisor is applied for all member candidates participating.
        uint256 minimumStake;
        // Map simulates a sorted linked list of ticket values by their indexes.
        // key -> value represent indices from the tickets[] array.
        // 'key' index holds an index of a ticket and 'value' holds an index
        // of the next ticket. Tickets are sorted by their value in
        // descending order starting from the tail.
        // Ex. tickets = [151, 42, 175, 7]
        // tail: 2 because tickets[2] = 175
        // previousTicketIndex[0] -> 1
        // previousTicketIndex[1] -> 3
        // previousTicketIndex[2] -> 0
        // previousTicketIndex[3] -> 3 note: index that holds a lowest
        // value points to itself because there is no `nil` in Solidity.
        // Traversing from tail: [2]->[0]->[1]->[3] result in 175->151->42->7
        bytes previousTicketIndices;
        // Tail represents an index of a ticket in a tickets[] array which holds
        // the highest ticket value. It is a tail of the linked list defined by
        // `previousTicketIndex`.
        uint256 tail;
        // Size of a group in the threshold relay.
        uint256 groupSize;
    }

    /// @notice Starts group selection protocol.
    /// @param _seed pseudorandom seed value used as an input for the group
    /// selection. All submitted tickets needs to have the seed mixed-in into the
    /// value.
    function start(Storage storage self, uint256 _seed) public {
        // We execute the minimum required cleanup here needed in case the
        // previous group selection failed and did not clean up properly in
        // finish function.
        cleanupTickets(self);
        self.inProgress = true;
        self.seed = _seed;
        self.ticketSubmissionStartBlock = block.number;
    }

    /// @notice Finishes group selection protocol clearing up all the submitted
    /// tickets. This function may be expensive if not executed as a part of
    /// another transaction consuming a lot of gas and as a result, getting
    /// gas refund for clearing up the storage.
    function finish(Storage storage self) public {
        cleanupCandidates(self);
        cleanupTickets(self);
        self.inProgress = false;
    }

    /// @notice Submits ticket to request to participate in a new candidate group.
    /// @param ticket Bytes representation of a ticket that holds the following:
    /// - ticketValue: first 8 bytes of a result of keccak256 cryptography hash
    ///   function on the combination of the group selection seed (previous
    ///   beacon output), staker-specific value (address) and virtual staker index.
    /// - stakerValue: a staker-specific value which is the address of the staker.
    /// - virtualStakerIndex: 4-bytes number within a range of 1 to staker's weight;
    ///   has to be unique for all tickets submitted by the given staker for the
    ///   current candidate group selection.
    /// @param stakingWeight Ratio of the minimum stake to the candidate's
    /// stake.
    function submitTicket(
        Storage storage self,
        bytes32 ticket,
        uint256 stakingWeight
    ) public {
        uint64 ticketValue;
        uint160 stakerValue;
        uint32 virtualStakerIndex;

        bytes memory ticketBytes = abi.encodePacked(ticket);
        /* solium-disable-next-line */
        assembly {
            // ticket value is 8 bytes long
            ticketValue := mload(add(ticketBytes, 8))
            // staker value is 20 bytes long
            stakerValue := mload(add(ticketBytes, 28))
            // virtual staker index is 4 bytes long
            virtualStakerIndex := mload(add(ticketBytes, 32))
        }

        submitTicket(
            self,
            ticketValue,
            uint256(stakerValue),
            uint256(virtualStakerIndex),
            stakingWeight
        );
    }

    /// @notice Submits ticket to request to participate in a new candidate group.
    /// @param ticketValue First 8 bytes of a result of keccak256 cryptography hash
    /// function on the combination of the group selection seed (previous
    /// beacon output), staker-specific value (address) and virtual staker index.
    /// @param stakerValue Staker-specific value which is the address of the staker.
    /// @param virtualStakerIndex 4-bytes number within a range of 1 to staker's weight;
    /// has to be unique for all tickets submitted by the given staker for the
    /// current candidate group selection.
    /// @param stakingWeight Ratio of the minimum stake to the candidate's
    /// stake.
    function submitTicket(
        Storage storage self,
        uint64 ticketValue,
        uint256 stakerValue,
        uint256 virtualStakerIndex,
        uint256 stakingWeight
    ) public {
        if (
            block.number >
            self.ticketSubmissionStartBlock.add(self.ticketSubmissionTimeout)
        ) {
            revert("Ticket submission is over");
        }

        if (self.candidate[ticketValue] != address(0)) {
            revert("Duplicate ticket");
        }

        if (
            isTicketValid(
                ticketValue,
                stakerValue,
                virtualStakerIndex,
                stakingWeight,
                self.seed
            )
        ) {
            addTicket(self, ticketValue);
        } else {
            revert("Invalid ticket");
        }
    }

    /// @notice Performs full verification of the ticket.
    function isTicketValid(
        uint64 ticketValue,
        uint256 stakerValue,
        uint256 virtualStakerIndex,
        uint256 stakingWeight,
        uint256 groupSelectionSeed
    ) internal view returns (bool) {
        uint64 ticketValueExpected;
        bytes memory ticketBytes =
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        groupSelectionSeed,
                        stakerValue,
                        virtualStakerIndex
                    )
                )
            );
        // use first 8 bytes to compare ticket values
        /* solium-disable-next-line */
        assembly {
            ticketValueExpected := mload(add(ticketBytes, 8))
        }

        bool isVirtualStakerIndexValid =
            virtualStakerIndex > 0 && virtualStakerIndex <= stakingWeight;
        bool isStakerValueValid = stakerValue == uint256(msg.sender);
        bool isTicketValueValid = ticketValue == ticketValueExpected;

        return
            isVirtualStakerIndexValid &&
            isStakerValueValid &&
            isTicketValueValid;
    }

    /// @notice Adds a new, verified ticket. Ticket is accepted when it is lower
    /// than the currently highest ticket or when the number of tickets is still
    /// below the group size.
    function addTicket(Storage storage self, uint64 newTicketValue) internal {
        uint256[] memory previousTicketIndex = readPreviousTicketIndices(self);
        uint256[] memory ordered =
            getTicketValueOrderedIndices(self, previousTicketIndex);

        // any ticket goes when the tickets array size is lower than the group size
        if (self.tickets.length < self.groupSize) {
            // no tickets
            if (self.tickets.length == 0) {
                self.tickets.push(newTicketValue);
                // higher than the current highest
            } else if (newTicketValue > self.tickets[self.tail]) {
                self.tickets.push(newTicketValue);
                uint256 oldTail = self.tail;
                self.tail = self.tickets.length - 1;
                previousTicketIndex[self.tail] = oldTail;
                // lower than the current lowest
            } else if (newTicketValue < self.tickets[ordered[0]]) {
                self.tickets.push(newTicketValue);
                // last element points to itself
                previousTicketIndex[self.tickets.length - 1] =
                    self.tickets.length -
                    1;
                // previous lowest ticket points to the new lowest
                previousTicketIndex[ordered[0]] = self.tickets.length - 1;
                // higher than the lowest ticket value and lower than the highest ticket value
            } else {
                self.tickets.push(newTicketValue);
                uint256 j = findReplacementIndex(self, newTicketValue, ordered);
                previousTicketIndex[
                    self.tickets.length - 1
                ] = previousTicketIndex[j];
                previousTicketIndex[j] = self.tickets.length - 1;
            }
            self.candidate[newTicketValue] = msg.sender;
        } else if (newTicketValue < self.tickets[self.tail]) {
            uint256 ticketToRemove = self.tickets[self.tail];
            // new ticket is lower than currently lowest
            if (newTicketValue < self.tickets[ordered[0]]) {
                // replacing highest ticket with the new lowest
                self.tickets[self.tail] = newTicketValue;
                uint256 newTail = previousTicketIndex[self.tail];
                previousTicketIndex[ordered[0]] = self.tail;
                previousTicketIndex[self.tail] = self.tail;
                self.tail = newTail;
            } else {
                // new ticket is between lowest and highest
                uint256 j = findReplacementIndex(self, newTicketValue, ordered);
                self.tickets[self.tail] = newTicketValue;
                // do not change the order if a new ticket is still highest
                if (j != self.tail) {
                    uint256 newTail = previousTicketIndex[self.tail];
                    previousTicketIndex[self.tail] = previousTicketIndex[j];
                    previousTicketIndex[j] = self.tail;
                    self.tail = newTail;
                }
            }
            // we are replacing tickets so we also need to replace information
            // about the submitter
            delete self.candidate[ticketToRemove];
            self.candidate[newTicketValue] = msg.sender;
        }
        storePreviousTicketIndices(self, previousTicketIndex);
    }

    /// @notice Use binary search to find an index for a new ticket in the tickets[] array
    function findReplacementIndex(
        Storage storage self,
        uint64 newTicketValue,
        uint256[] memory ordered
    ) internal view returns (uint256) {
        uint256 lo = 0;
        uint256 hi = ordered.length - 1;
        uint256 mid = 0;
        while (lo <= hi) {
            mid = (lo + hi) >> 1;
            if (newTicketValue < self.tickets[ordered[mid]]) {
                hi = mid - 1;
            } else if (newTicketValue > self.tickets[ordered[mid]]) {
                lo = mid + 1;
            } else {
                return ordered[mid];
            }
        }

        return ordered[lo];
    }

    function readPreviousTicketIndices(Storage storage self)
        internal
        view
        returns (uint256[] memory uncompressed)
    {
        bytes memory compressed = self.previousTicketIndices;
        uncompressed = new uint256[](self.groupSize);
        for (uint256 i = 0; i < compressed.length; i++) {
            uncompressed[i] = uint256(uint8(compressed[i]));
        }
    }

    function storePreviousTicketIndices(
        Storage storage self,
        uint256[] memory uncompressed
    ) internal {
        bytes memory compressed = new bytes(uncompressed.length);
        for (uint256 i = 0; i < compressed.length; i++) {
            compressed[i] = bytes1(uint8(uncompressed[i]));
        }
        self.previousTicketIndices = compressed;
    }

    /// @notice Creates an array of ticket indexes based on their values in the
    ///  ascending order:
    ///
    /// ordered[n-1] = tail
    /// ordered[n-2] = previousTicketIndex[tail]
    /// ordered[n-3] = previousTicketIndex[ordered[n-2]]
    function getTicketValueOrderedIndices(
        Storage storage self,
        uint256[] memory previousIndices
    ) internal view returns (uint256[] memory) {
        uint256[] memory ordered = new uint256[](self.tickets.length);
        if (ordered.length > 0) {
            ordered[self.tickets.length - 1] = self.tail;
            if (ordered.length > 1) {
                for (uint256 i = self.tickets.length - 1; i > 0; i--) {
                    ordered[i - 1] = previousIndices[ordered[i]];
                }
            }
        }

        return ordered;
    }

    /// @notice Gets selected participants in ascending order of their tickets.
    function selectedParticipants(Storage storage self)
        public
        view
        returns (address[] memory)
    {
        require(
            block.number >=
                self.ticketSubmissionStartBlock.add(
                    self.ticketSubmissionTimeout
                ),
            "Ticket submission in progress"
        );

        require(
            self.tickets.length >= self.groupSize,
            "Not enough tickets submitted"
        );

        uint256[] memory previousTicketIndex = readPreviousTicketIndices(self);
        address[] memory selected = new address[](self.groupSize);
        uint256 ticketIndex = self.tail;
        selected[self.tickets.length - 1] = self.candidate[
            self.tickets[ticketIndex]
        ];
        for (uint256 i = self.tickets.length - 1; i > 0; i--) {
            ticketIndex = previousTicketIndex[ticketIndex];
            selected[i - 1] = self.candidate[self.tickets[ticketIndex]];
        }

        return selected;
    }

    /// @notice Clears up data of the group selection tickets.
    function cleanupTickets(Storage storage self) internal {
        delete self.tickets;
        self.tail = 0;
    }

    /// @notice Clears up data of the group selection candidates.
    /// This operation may have a significant cost if not executed as a part of
    /// another transaction consuming a lot of gas and as a result, getting
    /// gas refund for clearing up the storage.
    function cleanupCandidates(Storage storage self) internal {
        for (uint256 i = 0; i < self.tickets.length; i++) {
            delete self.candidate[self.tickets[i]];
        }
    }
}

pragma solidity 0.5.17;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../utils/BytesLib.sol";
import "../../utils/PercentUtils.sol";
import "../../cryptography/AltBn128.sol";
import "../../cryptography/BLS.sol";
import "../../TokenStaking.sol";

library Groups {
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using BytesLib for bytes;

    // The index of a group is flagged with the most significant bit set,
    // to distinguish the group `0` from null.
    // The flag is toggled with bitwise XOR (`^`)
    // which keeps all other bits intact but flips the flag bit.
    // The flag should be set before writing to `groupIndices`,
    // and unset after reading from `groupIndices`
    // before using the value.
    uint256 constant GROUP_INDEX_FLAG = 1 << 255;

    uint256 constant ONE_MONTH = 86400 * 30;
    uint256 constant THREE_MONTHS = 3 * ONE_MONTH;
    uint256 constant SIX_MONTHS = 6 * ONE_MONTH;

    struct Group {
        bytes groupPubKey;
        uint256 registrationBlockHeight;
        bool terminated;
        uint248 registrationTime;
    }

    struct Storage {
        // Time in blocks after which a group expires.
        uint256 groupActiveTime;
        // Duplicated constant from operator contract to avoid extra call.
        // The value is set when the operator contract is added.
        uint256 relayEntryTimeout;
        // Mapping of `groupPubKey` to flagged `groupIndex`
        mapping(bytes => uint256) groupIndices;
        Group[] groups;
        uint256[] activeTerminatedGroups;
        mapping(bytes => address[]) groupMembers;
        // Sum of all group member rewards earned so far. The value is the same for
        // all group members. Submitter reward and reimbursement is paid immediately
        // and is not included here. Each group member can withdraw no more than
        // this value.
        mapping(bytes => uint256) groupMemberRewards;
        // Mapping of `groupPubKey, operator`
        // to whether the operator has withdrawn rewards from that group.
        mapping(bytes => mapping(address => bool)) withdrawn;
        // expiredGroupOffset is pointing to the first active group, it is also the
        // expired groups counter
        uint256 expiredGroupOffset;
        TokenStaking stakingContract;
    }

    /// @notice Adds a new group.
    function addGroup(Storage storage self, bytes memory groupPubKey) public {
        self.groupIndices[groupPubKey] = (self.groups.length ^
            GROUP_INDEX_FLAG);
        self.groups.push(
            Group(groupPubKey, block.number, false, uint248(block.timestamp))
        );
    }

    /// @notice Sets addresses of members for the group with the given public key
    /// eliminating members at positions pointed by the misbehaved array.
    /// @param groupPubKey Group public key.
    /// @param members Group member addresses as outputted by the group selection
    /// protocol.
    /// @param misbehaved Bytes array of misbehaved (disqualified or inactive)
    /// group members indexes in ascending order; Indexes reflect positions of
    /// members in the group as outputted by the group selection protocol -
    /// member indexes start from 1.
    function setGroupMembers(
        Storage storage self,
        bytes memory groupPubKey,
        address[] memory members,
        bytes memory misbehaved
    ) public {
        self.groupMembers[groupPubKey] = members;

        // Iterate misbehaved array backwards, replace misbehaved
        // member with the last element and reduce array length
        uint256 i = misbehaved.length;
        while (i > 0) {
            // group member indexes start from 1, so we need to -1 on misbehaved
            uint256 memberArrayPosition = misbehaved.toUint8(i - 1) - 1;
            self.groupMembers[groupPubKey][memberArrayPosition] = self
                .groupMembers[groupPubKey][
                self.groupMembers[groupPubKey].length - 1
            ];
            self.groupMembers[groupPubKey].length--;
            i--;
        }
    }

    /// @notice Adds group member reward per group so the accumulated amount can
    /// be withdrawn later.
    function addGroupMemberReward(
        Storage storage self,
        bytes memory groupPubKey,
        uint256 amount
    ) internal {
        self.groupMemberRewards[groupPubKey] = self.groupMemberRewards[
            groupPubKey
        ]
            .add(amount);
    }

    /// @notice Returns accumulated group member rewards for provided group.
    function getGroupMemberRewards(
        Storage storage self,
        bytes memory groupPubKey
    ) internal view returns (uint256) {
        return self.groupMemberRewards[groupPubKey];
    }

    /// @notice Gets group public key.
    function getGroupPublicKey(Storage storage self, uint256 groupIndex)
        internal
        view
        returns (bytes memory)
    {
        return self.groups[groupIndex].groupPubKey;
    }

    /// @notice Gets group member.
    function getGroupMember(
        Storage storage self,
        bytes memory groupPubKey,
        uint256 memberIndex
    ) internal view returns (address) {
        return self.groupMembers[groupPubKey][memberIndex];
    }

    /// @notice Terminates group with the provided index. Reverts if the group
    /// is already terminated.
    function terminateGroup(Storage storage self, uint256 groupIndex) public {
        require(
            !isGroupTerminated(self, groupIndex),
            "Group has been already terminated"
        );
        self.groups[groupIndex].terminated = true;
        self.activeTerminatedGroups.length++;

        // Sorting activeTerminatedGroups in ascending order so a non-terminated
        // group is properly selected.
        uint256 i;
        for (
            i = self.activeTerminatedGroups.length - 1;
            i > 0 && self.activeTerminatedGroups[i - 1] > groupIndex;
            i--
        ) {
            self.activeTerminatedGroups[i] = self.activeTerminatedGroups[i - 1];
        }
        self.activeTerminatedGroups[i] = groupIndex;
    }

    /// @notice Checks if group with the given index is terminated.
    function isGroupTerminated(Storage storage self, uint256 groupIndex)
        internal
        view
        returns (bool)
    {
        return self.groups[groupIndex].terminated;
    }

    /// @notice Checks if group with the given public key is registered.
    function isGroupRegistered(Storage storage self, bytes memory groupPubKey)
        internal
        view
        returns (bool)
    {
        // Values in `groupIndices` are flagged with `GROUP_INDEX_FLAG`
        // and thus nonzero, even for group 0
        return self.groupIndices[groupPubKey] > 0;
    }

    /// @notice Gets the cutoff time in blocks until which the given group is
    /// considered as an active group assuming it hasn't been terminated before.
    function groupActiveTimeOf(Storage storage self, Group memory group)
        internal
        view
        returns (uint256)
    {
        return uint256(group.registrationBlockHeight).add(self.groupActiveTime);
    }

    /// @notice Gets the cutoff time in blocks after which the given group is
    /// considered as stale. Stale group is an expired group which is no longer
    /// performing any operations.
    function groupStaleTime(Storage storage self, Group memory group)
        internal
        view
        returns (uint256)
    {
        return groupActiveTimeOf(self, group).add(self.relayEntryTimeout);
    }

    /// @notice Checks if a group with the given public key is a stale group.
    /// Stale group is an expired group which is no longer performing any
    /// operations. It is important to understand that an expired group may
    /// still perform some operations for which it was selected when it was still
    /// active. We consider a group to be stale when it's expired and when its
    /// expiration time and potentially executed operation timeout are both in
    /// the past.
    function isStaleGroup(Storage storage self, bytes memory groupPubKey)
        public
        view
        returns (bool)
    {
        uint256 flaggedIndex = self.groupIndices[groupPubKey];
        require(flaggedIndex != 0, "Group does not exist");
        uint256 index = flaggedIndex ^ GROUP_INDEX_FLAG;
        bool isExpired = self.expiredGroupOffset > index;
        bool isStale = groupStaleTime(self, self.groups[index]) < block.number;
        return isExpired && isStale;
    }

    /// @notice Checks if a group with the given index is a stale group.
    /// Stale group is an expired group which is no longer performing any
    /// operations. It is important to understand that an expired group may
    /// still perform some operations for which it was selected when it was still
    /// active. We consider a group to be stale when it's expired and when its
    /// expiration time and potentially executed operation timeout are both in
    /// the past.
    function isStaleGroup(Storage storage self, uint256 groupIndex)
        public
        view
        returns (bool)
    {
        return groupStaleTime(self, self.groups[groupIndex]) < block.number;
    }

    /// @notice Gets the number of active groups. Expired and terminated groups are
    /// not counted as active.
    function numberOfGroups(Storage storage self)
        internal
        view
        returns (uint256)
    {
        return
            self.groups.length.sub(self.expiredGroupOffset).sub(
                self.activeTerminatedGroups.length
            );
    }

    /// @notice Goes through groups starting from the oldest one that is still
    /// active and checks if it hasn't expired. If so, updates the information
    /// about expired groups so that all expired groups are marked as such.
    function expireOldGroups(Storage storage self) public {
        // Move expiredGroupOffset as long as there are some groups that should
        // be marked as expired. It is possible that expired group offset will
        // move out of the groups array by one position. It means that all groups
        // are expired (it points to the first active group) and that place in
        // groups array - currently empty - will be possibly filled later by
        // a new group.
        while (
            self.expiredGroupOffset < self.groups.length &&
            groupActiveTimeOf(self, self.groups[self.expiredGroupOffset]) <
            block.number
        ) {
            self.expiredGroupOffset++;
        }

        // Go through all activeTerminatedGroups and if some of the terminated
        // groups are expired, remove them from activeTerminatedGroups collection.
        // This is needed because we evaluate the shift of selected group index
        // based on how many non-expired groups has been terminated.
        for (uint256 i = 0; i < self.activeTerminatedGroups.length; i++) {
            if (self.expiredGroupOffset > self.activeTerminatedGroups[i]) {
                self.activeTerminatedGroups[i] = self.activeTerminatedGroups[
                    self.activeTerminatedGroups.length - 1
                ];
                self.activeTerminatedGroups.length--;
            }
        }
    }

    /// @notice Returns an index of a randomly selected active group. Terminated
    /// and expired groups are not considered as active.
    /// Before new group is selected, information about expired groups
    /// is updated. At least one active group needs to be present for this
    /// function to succeed.
    /// @param seed Random number used as a group selection seed.
    function selectGroup(Storage storage self, uint256 seed)
        public
        returns (uint256)
    {
        expireOldGroups(self);

        require(numberOfGroups(self) > 0, "No active groups");

        uint256 selectedGroup = seed % numberOfGroups(self);
        return
            shiftByTerminatedGroups(
                self,
                shiftByExpiredGroups(self, selectedGroup)
            );
    }

    /// @notice Evaluates the shift of selected group index based on the number of
    /// expired groups.
    function shiftByExpiredGroups(Storage storage self, uint256 selectedIndex)
        internal
        view
        returns (uint256)
    {
        return self.expiredGroupOffset.add(selectedIndex);
    }

    /// @notice Evaluates the shift of selected group index based on the number of
    /// non-expired, terminated groups.
    function shiftByTerminatedGroups(
        Storage storage self,
        uint256 selectedIndex
    ) internal view returns (uint256) {
        uint256 shiftedIndex = selectedIndex;
        for (uint256 i = 0; i < self.activeTerminatedGroups.length; i++) {
            if (self.activeTerminatedGroups[i] <= shiftedIndex) {
                shiftedIndex++;
            }
        }

        return shiftedIndex;
    }

    /// @notice Withdraws accumulated group member rewards for operator
    /// using the provided group index.
    /// Once the accumulated reward is withdrawn from the selected group,
    /// the operator is flagged as withdrawn.
    /// Rewards can be withdrawn only from stale group.
    /// @param operator Operator address.
    /// @param groupIndex Group index.
    function withdrawFromGroup(
        Storage storage self,
        address operator,
        uint256 groupIndex
    ) public returns (uint256 rewards) {
        bool isExpired = self.expiredGroupOffset > groupIndex;
        bool isStale = isStaleGroup(self, groupIndex);
        require(isExpired && isStale, "Group must be expired and stale");
        bytes memory groupPublicKey = getGroupPublicKey(self, groupIndex);
        require(
            !(self.withdrawn[groupPublicKey][operator]),
            "Rewards already withdrawn"
        );
        self.withdrawn[groupPublicKey][operator] = true;
        for (uint256 i = 0; i < self.groupMembers[groupPublicKey].length; i++) {
            if (operator == self.groupMembers[groupPublicKey][i]) {
                rewards = rewards.add(self.groupMemberRewards[groupPublicKey]);
            }
        }
    }

    /// @notice Returns members of the given group by group public key.
    /// @param groupPubKey Group public key.
    function getGroupMembers(Storage storage self, bytes memory groupPubKey)
        public
        view
        returns (address[] memory members)
    {
        return self.groupMembers[groupPubKey];
    }

    /// @notice Returns addresses of all the members in the provided group.
    function getGroupMembers(Storage storage self, uint256 groupIndex)
        public
        view
        returns (address[] memory members)
    {
        bytes memory groupPubKey = self.groups[groupIndex].groupPubKey;
        return self.groupMembers[groupPubKey];
    }

    function getGroupRegistrationTime(Storage storage self, uint256 groupIndex)
        public
        view
        returns (uint256)
    {
        return uint256(self.groups[groupIndex].registrationTime);
    }

    /// @notice Reports unauthorized signing for the provided group. Must provide
    /// a valid signature of the group address as a message. Successful signature
    /// verification means the private key has been leaked and all group members
    /// should be punished by seizing their tokens. The submitter of this proof is
    /// rewarded with 5% of the total seized amount scaled by the reward adjustment
    /// parameter and the rest 95% is burned. Group has to be active or expired.
    /// Unauthorized signing cannot be reported for stale or terminated group.
    /// In case of reporting unauthorized signing for stale group,
    /// terminated group, or when the signature is inavlid, function reverts.
    function reportUnauthorizedSigning(
        Storage storage self,
        uint256 groupIndex,
        bytes memory signedMsgSender,
        uint256 minimumStake
    ) public {
        require(!isStaleGroup(self, groupIndex), "Group can not be stale");
        bytes memory groupPubKey = getGroupPublicKey(self, groupIndex);

        require(
            BLS.verifyBytes(
                groupPubKey,
                abi.encodePacked(msg.sender),
                signedMsgSender
            ),
            "Invalid signature"
        );

        terminateGroup(self, groupIndex);
        self.stakingContract.seize(
            minimumStake,
            100,
            msg.sender,
            self.groupMembers[groupPubKey]
        );
    }

    function reportRelayEntryTimeout(
        Storage storage self,
        uint256 groupIndex,
        uint256 groupSize
    ) public {
        uint256 punishment = relayEntryTimeoutPunishment(self);
        terminateGroup(self, groupIndex);
        // Reward is limited to min(1, 20 / group_size) of the maximum tattletale reward, see the Yellow Paper for more details.
        uint256 rewardAdjustment = uint256(20 * 100).div(groupSize); // Reward adjustment in percentage
        rewardAdjustment = rewardAdjustment > 100 ? 100 : rewardAdjustment; // Reward adjustment can be 100% max
        self.stakingContract.seize(
            punishment,
            rewardAdjustment,
            msg.sender,
            getGroupMembers(self, groupIndex)
        );
    }

    /// @notice Evaluates relay entry timeout punishment using the following
    /// rules:
    /// - 1% of the minimum stake for the first 3 months,
    /// - 50% of the minimum stake between the first 3 and 6 months,
    /// - 100% of the minimum stake after the first 6 months.
    function relayEntryTimeoutPunishment(Storage storage self)
        public
        view
        returns (uint256)
    {
        uint256 minimumStake = self.stakingContract.minimumStake();

        uint256 stakingContractDeployedAt = self.stakingContract.deployedAt();
        /* solium-disable-next-line security/no-block-members */
        if (now < stakingContractDeployedAt + THREE_MONTHS) {
            return minimumStake.percent(1);
            /* solium-disable-next-line security/no-block-members */
        } else if (now < stakingContractDeployedAt + SIX_MONTHS) {
            return minimumStake.percent(50);
        } else {
            return minimumStake;
        }
    }

    /// @notice Return whether the given operator
    /// has withdrawn their rewards from the given group.
    function hasWithdrawnRewards(
        Storage storage self,
        address operator,
        uint256 groupIndex
    ) public view returns (bool) {
        return self.withdrawn[getGroupPublicKey(self, groupIndex)][operator];
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../../utils/BytesLib.sol";
import "../../TokenStaking.sol";

library Reimbursements {
    using SafeMath for uint256;
    using BytesLib for bytes;

    /// @notice Reimburses callback execution cost and surplus based on actual gas
    /// usage to the submitter's beneficiary address and if necessary to the
    /// callback requestor (surplus recipient).
    /// @param stakingContract Staking contract to get the address of the beneficiary
    /// @param gasPriceCeiling Gas price ceiling in wei
    /// @param gasLimit Gas limit set for the callback
    /// @param gasSpent Gas spent by the submitter on the callback
    /// @param callbackFee Fee paid for the callback by the requestor
    /// @param callbackSurplusRecipientData Data containing surplus recipient address
    function reimburseCallback(
        TokenStaking stakingContract,
        uint256 gasPriceCeiling,
        uint256 gasLimit,
        uint256 gasSpent,
        uint256 callbackFee,
        bytes memory callbackSurplusRecipientData
    ) public {
        uint256 gasPrice = gasPriceCeiling;
        // We need to check if tx.gasprice is non-zero as a workaround to a bug
        // in go-ethereum:
        // https://github.com/ethereum/go-ethereum/pull/20189
        if (tx.gasprice > 0 && tx.gasprice < gasPriceCeiling) {
            gasPrice = tx.gasprice;
        }

        // Obtain the actual callback gas expenditure and refund the surplus.
        //
        // In case of heavily underpriced transactions, EVM may wrap the call
        // with additional opcodes. In this case gasSpent > gasLimit.
        // The worst scenario cost is included in entry verification fee.
        // If this happens we return just the gasLimit here.
        uint256 actualCallbackGas = gasSpent < gasLimit ? gasSpent : gasLimit;
        uint256 actualCallbackFee = actualCallbackGas.mul(gasPrice);

        // Get the beneficiary.
        address payable beneficiary = stakingContract.beneficiaryOf(msg.sender);

        // If we spent less on the callback than the customer transferred for the
        // callback execution, we need to reimburse the difference.
        if (actualCallbackFee < callbackFee) {
            uint256 callbackSurplus = callbackFee.sub(actualCallbackFee);
            // Reimburse submitter with his actual callback cost.
            beneficiary.call.value(actualCallbackFee)("");

            // Return callback surplus to the requestor.
            // Expecting 32 bytes data containing 20 byte address
            if (callbackSurplusRecipientData.length == 32) {
                address surplusRecipient =
                    callbackSurplusRecipientData.toAddress(12);
                surplusRecipient.call.gas(8000).value(callbackSurplus)("");
            }
        } else {
            // Reimburse submitter with the callback payment sent by the requestor.
            beneficiary.call.value(callbackFee)("");
        }
    }
}

pragma solidity 0.5.17;

import "../../TokenGrant.sol";
import "../../TokenStakingEscrow.sol";
import "../..//utils/BytesLib.sol";
import "../RolesLookup.sol";

/// @notice TokenStaking contract library allowing to capture the details of
/// delegated grants and offering functions allowing to check grantee
/// authentication for stake delegation management.
library GrantStaking {
    using BytesLib for bytes;
    using RolesLookup for address payable;

    /// @dev Grant ID is flagged with the most significant bit set, to
    /// distinguish the grant ID `0` from default (null) value. The flag is
    /// toggled with bitwise XOR (`^`) which keeps all other bits intact but
    /// flips the flag bit. The flag should be set before writing to
    /// `operatorToGrant`, and unset after reading from `operatorToGrant`
    /// before using the value.
    uint256 constant GRANT_ID_FLAG = 1 << 255;

    struct Storage {
        /// @dev Do not read or write this mapping directly; please use
        /// `hasGrantDelegated`, `setGrantForOperator`, and `getGrantForOperator`
        /// instead.
        mapping(address => uint256) _operatorToGrant;
    }

    /// @notice Tries to capture delegation data if the pending delegation has
    /// been created from a grant. There are only two possibilities and they
    /// need to be handled differently: delegation comes from the TokenGrant
    /// contract or delegation comes from TokenStakingEscrow. In those two cases
    /// grant ID has to be captured in a different way.
    /// @dev In case of a delegation from the escrow, it is expected that grant
    /// ID is passed in extraData bytes array. When the delegation comes from
    /// the TokenGrant contract, delegation data are obtained directly from that
    /// contract using `tryCapturingGrantId` function.
    /// @param tokenGrant KEEP token grant contract reference.
    /// @param escrow TokenStakingEscrow contract address.
    /// @param from The owner of the tokens who approved them to transfer.
    /// @param operator The operator tokens are delegated to.
    /// @param extraData Data for stake delegation, as passed to
    /// `receiveApproval` of `TokenStaking`.
    function tryCapturingDelegationData(
        Storage storage self,
        TokenGrant tokenGrant,
        address escrow,
        address from,
        address operator,
        bytes memory extraData
    ) public returns (bool, uint256) {
        if (from == escrow) {
            require(
                extraData.length == 92,
                "Corrupted delegation data from escrow"
            );
            uint256 grantId = extraData.toUint(60);
            setGrantForOperator(self, operator, grantId);
            return (true, grantId);
        } else {
            return tryCapturingGrantId(self, tokenGrant, operator);
        }
    }

    /// @notice Checks if the delegation for the given operator has been created
    /// from a grant defined in the passed token grant contract and if so,
    /// captures the grant ID for that delegation.
    /// Grant ID can be later retrieved based on the operator address and used
    /// to authenticate grantee or to fetch the information about grant
    /// unlocking schedule for escrow.
    /// @param tokenGrant KEEP token grant contract reference.
    /// @param operator The operator tokens are delegated to.
    function tryCapturingGrantId(
        Storage storage self,
        TokenGrant tokenGrant,
        address operator
    ) internal returns (bool, uint256) {
        (bool success, bytes memory data) =
            address(tokenGrant).call(
                abi.encodeWithSignature(
                    "getGrantStakeDetails(address)",
                    operator
                )
            );
        if (success) {
            (uint256 grantId, , address grantStakingContract) =
                abi.decode(data, (uint256, uint256, address));
            // Double-check if the delegation in TokenGrant has been defined
            // for this staking contract. If not, it means it's an old
            // delegation and the current one does not come from a grant.
            // The scenario covered here is:
            // - grantee delegated to operator A from a TokenGrant using another
            //   staking contract,
            // - someone delegates to operator A using liquid tokens and this
            //   staking contract.
            // Without this check, we'd consider the second delegation as coming
            // from a grant.
            if (address(this) != grantStakingContract) {
                return (false, 0);
            }

            setGrantForOperator(self, operator, grantId);
            return (true, grantId);
        }

        return (false, 0);
    }

    /// @notice Returns true if the given operator operates on stake delegated
    /// from a grant. false is returned otherwise.
    /// @param operator The operator to which tokens from a grant are
    /// potentially delegated to.
    function hasGrantDelegated(Storage storage self, address operator)
        public
        view
        returns (bool)
    {
        return self._operatorToGrant[operator] != 0;
    }

    /// @notice Associates operator with the provided grant ID. It means that
    /// the given operator delegates on stake from the grant with this ID.
    /// @param operator The operator tokens are delegate to.
    /// @param grantId Identifier of a grant from which the tokens are delegated
    /// to.
    function setGrantForOperator(
        Storage storage self,
        address operator,
        uint256 grantId
    ) public {
        self._operatorToGrant[operator] = grantId ^ GRANT_ID_FLAG;
    }

    /// @notice Returns grant ID for the provided operator. If the operator
    /// does not operate on stake delegated from a grant, function reverts.
    /// @dev To avoid reverting in case the grant ID for the operator does not
    /// exist, consider calling hasGrantDelegated before.
    /// @param operator The operator tokens are delegate to.
    function getGrantForOperator(Storage storage self, address operator)
        public
        view
        returns (uint256)
    {
        uint256 grantId = self._operatorToGrant[operator];
        require(grantId != 0, "No grant for the operator");
        return grantId ^ GRANT_ID_FLAG;
    }

    /// @notice Returns true if msg.sender is grantee eligible to trigger stake
    /// undelegation for this operator. Function checks both standard grantee
    /// and managed grantee case.
    /// @param operator The operator tokens are delegated to.
    /// @param tokenGrant KEEP token grant contract reference.
    function canUndelegate(
        Storage storage self,
        address operator,
        TokenGrant tokenGrant
    ) public returns (bool) {
        // First of all, we need to see if the operator has grant delegated.
        // If not, we don't need to bother about checking grantee or
        // managed grantee and we just return false.
        if (!hasGrantDelegated(self, operator)) {
            return false;
        }

        uint256 grantId = getGrantForOperator(self, operator);
        (, , , , uint256 revokedAt, address grantee) =
            tokenGrant.getGrant(grantId);

        // Is msg.sender grantee of a standard grant?
        if (msg.sender == grantee) {
            return true;
        }

        // If not, we need to dig deeper and see if we are dealing with
        // a grantee from a managed grant.
        if ((msg.sender).isManagedGranteeForGrant(grantId, tokenGrant)) {
            return true;
        }

        // There is only one possibility left - grant has been revoked and
        // grant manager wants to take back delegated tokens.
        if (revokedAt == 0) {
            return false;
        }
        (address grantManager, , , , ) =
            tokenGrant.getGrantUnlockingSchedule(grantId);
        return msg.sender == grantManager;
    }
}

pragma solidity 0.5.17;

library LockUtils {
    struct Lock {
        address creator;
        uint96 expiresAt;
    }

    /// @notice The LockSet is like an array of unique `uint256`s,
    /// but additionally supports O(1) membership tests and removals.
    /// @dev Because the LockSet relies on a mapping,
    /// it can only be used in storage, not in memory.
    struct LockSet {
        // locks[positions[lock.creator] - 1] = lock
        Lock[] locks;
        mapping(address => uint256) positions;
    }

    /// @notice Check whether the LockSet `self` contains a lock by `creator`
    function contains(LockSet storage self, address creator)
        internal
        view
        returns (bool)
    {
        return (self.positions[creator] != 0);
    }

    function getLockTime(LockSet storage self, address creator)
        internal
        view
        returns (uint96)
    {
        uint256 positionPlusOne = self.positions[creator];
        if (positionPlusOne == 0) {
            return 0;
        }
        return self.locks[positionPlusOne - 1].expiresAt;
    }

    /// @notice Set the lock of `creator` to `expiresAt`,
    /// overriding the current value if any.
    function setLock(
        LockSet storage self,
        address _creator,
        uint96 _expiresAt
    ) internal {
        uint256 positionPlusOne = self.positions[_creator];
        Lock memory lock = Lock(_creator, _expiresAt);
        // No existing lock
        if (positionPlusOne == 0) {
            self.locks.push(lock);
            self.positions[_creator] = self.locks.length;
            // Existing lock present
        } else {
            self.locks[positionPlusOne - 1].expiresAt = _expiresAt;
        }
    }

    /// @notice Remove the lock of `creator`.
    /// If no lock present, do nothing.
    function releaseLock(LockSet storage self, address _creator) internal {
        uint256 positionPlusOne = self.positions[_creator];
        if (positionPlusOne != 0) {
            uint256 lockCount = self.locks.length;
            if (positionPlusOne != lockCount) {
                // Not the last lock,
                // so we need to move the last lock into the emptied position.
                Lock memory lastLock = self.locks[lockCount - 1];
                self.locks[positionPlusOne - 1] = lastLock;
                self.positions[lastLock.creator] = positionPlusOne;
            }
            self.locks.length--;
            self.positions[_creator] = 0;
        }
    }

    /// @notice Return the locks of the LockSet `self`.
    function enumerate(LockSet storage self)
        internal
        view
        returns (Lock[] memory)
    {
        return self.locks;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {AuthorityVerifier} from "../../Authorizations.sol";
import "./LockUtils.sol";

library Locks {
    using SafeMath for uint256;
    using LockUtils for LockUtils.LockSet;

    event StakeLocked(
        address indexed operator,
        address lockCreator,
        uint256 until
    );
    event LockReleased(address indexed operator, address lockCreator);
    event ExpiredLockReleased(address indexed operator, address lockCreator);

    uint256 public constant maximumLockDuration = 86400 * 200; // 200 days in seconds

    struct Storage {
        // Locks placed on the operator.
        // `operatorLocks[operator]` returns all locks placed on the operator.
        // Each authorized operator contract can place one lock on an operator.
        mapping(address => LockUtils.LockSet) operatorLocks;
    }

    function lockStake(
        Storage storage self,
        address operator,
        uint256 duration
    ) public {
        require(duration <= maximumLockDuration, "Lock duration too long");
        self.operatorLocks[operator].setLock(
            msg.sender,
            uint96(block.timestamp.add(duration))
        );
        emit StakeLocked(operator, msg.sender, block.timestamp.add(duration));
    }

    function releaseLock(Storage storage self, address operator) public {
        self.operatorLocks[operator].releaseLock(msg.sender);
        emit LockReleased(operator, msg.sender);
    }

    function releaseExpiredLock(
        Storage storage self,
        address operator,
        address operatorContract,
        address authorityVerifier
    ) public {
        LockUtils.LockSet storage locks = self.operatorLocks[operator];

        require(locks.contains(operatorContract), "No matching lock present");

        bool expired = block.timestamp >= locks.getLockTime(operatorContract);
        bool disabled =
            !AuthorityVerifier(authorityVerifier).isApprovedOperatorContract(
                operatorContract
            );

        require(expired || disabled, "Lock still active and valid");

        locks.releaseLock(operatorContract);

        emit ExpiredLockReleased(operator, operatorContract);
    }

    /// @dev AuthorityVerifier is a trusted implementation and not a third-party,
    /// external contract. AuthorityVerifier never reverts on the check and
    /// has a reasonable gas consumption.
    function isStakeLocked(
        Storage storage self,
        address operator,
        address authorityVerifier
    ) public view returns (bool) {
        LockUtils.Lock[] storage _locks = self.operatorLocks[operator].locks;
        LockUtils.Lock memory lock;
        for (uint256 i = 0; i < _locks.length; i++) {
            lock = _locks[i];
            if (block.timestamp < lock.expiresAt) {
                if (
                    AuthorityVerifier(authorityVerifier)
                        .isApprovedOperatorContract(lock.creator)
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    function isStakeReleased(
        Storage storage self,
        address operator,
        address operatorContract
    ) public view returns (bool) {
        LockUtils.LockSet storage locks = self.operatorLocks[operator];
        // `getLockTime` returns 0 if the lock doesn't exist,
        // thus we don't need to check for its presence separately.
        return block.timestamp >= locks.getLockTime(operatorContract);
    }

    function getLocks(Storage storage self, address operator)
        public
        view
        returns (address[] memory creators, uint256[] memory expirations)
    {
        uint256 lockCount = self.operatorLocks[operator].locks.length;
        creators = new address[](lockCount);
        expirations = new uint256[](lockCount);
        LockUtils.Lock memory lock;
        for (uint256 i = 0; i < lockCount; i++) {
            lock = self.operatorLocks[operator].locks[i];
            creators[i] = lock.creator;
            expirations[i] = lock.expiresAt;
        }
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/// @notice MinimumStakeSchedule defines the minimum stake parametrization and
/// schedule. It starts with a minimum stake of 100k KEEP. Over the following
/// 2 years, the minimum stake is lowered periodically using a uniform stepwise
/// function, eventually ending at 10k.
library MinimumStakeSchedule {
    using SafeMath for uint256;

    // 2 years in seconds (seconds per day * days in a year * years)
    uint256 public constant schedule = 86400 * 365 * 2;
    uint256 public constant steps = 10;
    uint256 public constant base = 10000 * 1e18;

    /// @notice Returns the current value of the minimum stake. The minimum
    /// stake is lowered periodically over the course of 2 years since the time
    /// of the shedule start and eventually ends at 10k KEEP.
    function current(uint256 scheduleStart) internal view returns (uint256) {
        if (now < scheduleStart.add(schedule)) {
            uint256 currentStep =
                steps.mul(now.sub(scheduleStart)).div(schedule);
            return base.mul(steps.sub(currentStep));
        }
        return base;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../../TokenStakingEscrow.sol";
import "../../utils/OperatorParams.sol";

/// @notice TokenStaking contract library allowing to perform two-step stake
/// top-ups for existing delegations.
/// Top-up is a two-step process: it is initiated with a declared top-up value
/// and after waiting for at least the initialization period it can be
/// committed.
library TopUps {
    using SafeMath for uint256;
    using OperatorParams for uint256;

    event TopUpInitiated(address indexed operator, uint256 topUp);
    event TopUpCompleted(address indexed operator, uint256 newAmount);

    struct TopUp {
        uint256 amount;
        uint256 createdAt;
    }

    struct Storage {
        // operator -> TopUp
        mapping(address => TopUp) topUps;
    }

    /// @notice Performs top-up in one step when stake is not yet initialized by
    /// adding the top-up amount to the stake and resetting stake initialization
    /// time counter.
    /// @dev This function should be called only for not yet initialized stake.
    /// @param value Top-up value, the number of tokens added to the stake.
    /// @param operator Operator The operator with existing delegation to which
    /// the tokens should be added to.
    /// @param operatorParams Parameters of that operator, as stored in the
    /// staking contract.
    /// @param escrow Reference to TokenStakingEscrow contract.
    /// @return New value of parameters. It should be updated for the operator
    /// in the staking contract.
    function instantComplete(
        Storage storage self,
        uint256 value,
        address operator,
        uint256 operatorParams,
        TokenStakingEscrow escrow
    ) public returns (uint256 newParams) {
        // Stake is not yet initialized so we don't need to check if the
        // operator is not undelegating - initializing and undelegating at the
        // same time is not possible. We do however, need to check whether the
        // operator has not canceled its previous stake for that operator,
        // depositing the stake it in the escrow. We do not want to allow
        // resurrecting operators with cancelled stake by top-ups.
        require(
            !escrow.hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );
        require(value > 0, "Top-up value must be greater than zero");

        uint256 newAmount = operatorParams.getAmount().add(value);
        newParams = operatorParams.setAmountAndCreationTimestamp(
            newAmount,
            block.timestamp
        );

        emit TopUpCompleted(operator, newAmount);
    }

    /// @notice Initiates top-up of the given value for tokens delegated to
    /// the provided operator. If there is an existing top-up still
    /// initializing, top-up values are summed up and initialization period
    /// is set to the current block timestamp.
    /// @dev This function should be called only for active operators with
    /// initialized stake.
    /// @param value Top-up value, the number of tokens added to the stake.
    /// @param operator Operator The operator with existing delegation to which
    /// the tokens should be added to.
    /// @param operatorParams Parameters of that operator, as stored in the
    /// staking contract.
    /// @param escrow Reference to TokenStakingEscrow contract.
    function initiate(
        Storage storage self,
        uint256 value,
        address operator,
        uint256 operatorParams,
        TokenStakingEscrow escrow
    ) public {
        // Stake is initialized, the operator is still active so we need
        // to check if it's not undelegating.
        require(!isUndelegating(operatorParams), "Stake undelegated");
        // We also need to check if the stake for the operator is not already
        // in the escrow because it's been previously cancelled.
        require(
            !escrow.hasDeposit(operator),
            "Stake for the operator already deposited in the escrow"
        );
        require(value > 0, "Top-up value must be greater than zero");

        TopUp memory awaiting = self.topUps[operator];
        self.topUps[operator] = TopUp(awaiting.amount.add(value), now);
        emit TopUpInitiated(operator, value);
    }

    /// @notice Commits the top-up if it passed the initialization period.
    /// Tokens are added to the stake once the top-up is committed.
    /// @param operator Operator The operator with a pending stake top-up.
    /// @param initializationPeriod Stake initialization period.
    function commit(
        Storage storage self,
        address operator,
        uint256 operatorParams,
        uint256 initializationPeriod
    ) public returns (uint256 newParams) {
        TopUp memory topUp = self.topUps[operator];
        require(topUp.amount > 0, "No top up to commit");
        require(
            now > topUp.createdAt.add(initializationPeriod),
            "Stake is initializing"
        );

        uint256 newAmount = operatorParams.getAmount().add(topUp.amount);
        newParams = operatorParams.setAmount(newAmount);

        delete self.topUps[operator];
        emit TopUpCompleted(operator, newAmount);
    }

    /// @notice Cancels pending, initiating top-up. If there is no initiating
    /// top-up for the operator, function does nothing. This function should be
    /// used when the stake is recovered to return tokens from a pending,
    /// initiating top-up.
    /// @param operator Operator The operator from which the stake is recovered.
    function cancel(Storage storage self, address operator)
        public
        returns (uint256)
    {
        TopUp memory topUp = self.topUps[operator];
        if (topUp.amount == 0) {
            return 0;
        }

        delete self.topUps[operator];
        return topUp.amount;
    }

    /// @notice Returns true if the given operatorParams indicate that the
    /// operator is undelegating its stake or that it completed stake
    /// undelegation.
    /// @param operatorParams Parameters of the operator, as stored in the
    /// staking contract.
    function isUndelegating(uint256 operatorParams)
        internal
        view
        returns (bool)
    {
        uint256 undelegatedAt = operatorParams.getUndelegationTimestamp();
        return (undelegatedAt != 0) && (block.timestamp > undelegatedAt);
    }
}

pragma solidity 0.5.17;

library AddressArrayUtils {
    function contains(address[] memory self, address _address)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < self.length; i++) {
            if (_address == self[i]) {
                return true;
            }
        }
        return false;
    }

    function removeAddress(address[] storage self, address _addressToRemove)
        internal
        returns (address[] storage)
    {
        for (uint256 i = 0; i < self.length; i++) {
            // If address is found in array.
            if (_addressToRemove == self[i]) {
                // Delete element at index and shift array.
                for (uint256 j = i; j < self.length - 1; j++) {
                    self[j] = self[j + 1];
                }
                self.length--;
                i--;
            }
        }
        return self;
    }
}

pragma solidity 0.5.17;

/*
Verison pulled from https://github.com/summa-tx/bitcoin-spv/blob/2535e4edaeaac4b2b095903fce684ae1c05761bc/solidity/contracts/BytesLib.sol
*/

/*
https://github.com/GNSPS/solidity-bytes-utils/
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
For more information, please refer to <https://unlicense.org>
*/

/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
                case 2 {
                    // Since the new array still fits in the slot, we just need to
                    // update the contents of the slot.
                    // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                    sstore(
                        _preBytes_slot,
                        // all the modifications to the slot are inside this
                        // next block
                        add(
                            // we can just add to the slot contents because the
                            // bytes we want to change are the LSBs
                            fslot,
                            add(
                                mul(
                                    div(
                                        // load the bytes from memory
                                        mload(add(_postBytes, 0x20)),
                                        // zero all bytes to the right
                                        exp(0x100, sub(32, mlength))
                                    ),
                                    // and now shift left the number of bytes to
                                    // leave space for the length in the slot
                                    exp(0x100, sub(32, newlength))
                                ),
                                // increase length by the double of the memory
                                // bytes length
                                mul(mlength, 2)
                            )
                        )
                    )
                }
                case 1 {
                    // The stored value fits in the slot, but the combined value
                    // will exceed it.
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // The contents of the _postBytes array start 32 bytes into
                    // the structure. Our first read should obtain the `submod`
                    // bytes that can fit into the unused space in the last word
                    // of the stored array. To get this, we read 32 bytes starting
                    // from `submod`, so the data we read overlaps with the array
                    // contents by `submod` bytes. Masking the lowest-order
                    // `submod` bytes allows us to add that value directly to the
                    // stored value.

                    let submod := sub(32, slength)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(
                        sc,
                        add(
                            and(
                                fslot,
                                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                            ),
                            and(mload(mc), mask)
                        )
                    )

                    for {
                        mc := add(mc, 0x20)
                        sc := add(sc, 1)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
                default {
                    // get the keccak hash to get the contents of the array
                    mstore(0x0, _preBytes_slot)
                    // Start copying to the last used word of the stored array.
                    let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                    // save new length
                    sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                    // Copy over the first `submod` bytes of the new data as in
                    // case 1 above.
                    let slengthmod := mod(slength, 32)
                    let mlengthmod := mod(mlength, 32)
                    let submod := sub(32, slengthmod)
                    let mc := add(_postBytes, submod)
                    let end := add(_postBytes, mlength)
                    let mask := sub(exp(0x100, submod), 1)

                    sstore(sc, add(sload(sc), and(mload(mc), mask)))

                    for {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } lt(mc, end) {
                        sc := add(sc, 1)
                        mc := add(mc, 0x20)
                    } {
                        sstore(sc, mload(mc))
                    }

                    mask := exp(0x100, sub(mc, end))

                    sstore(sc, mul(div(mload(mc), mask), mask))
                }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory res) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        uint256 _totalLen = _start + 20;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Address conversion out of bounds."
        );
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(
            _bytes.length >= (_start + 1),
            "Uint8 conversion out of bounds."
        );
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        uint256 _totalLen = _start + 32;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Uint conversion out of bounds."
        );
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
                case 1 {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                    let cb := 1

                    let mc := add(_preBytes, 0x20)
                    let end := add(mc, length)

                    for {
                        let cc := add(_postBytes, 0x20)
                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                    } eq(add(lt(mc, end), cb), 2) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        // if any of these checks fails then arrays are not equal
                        if iszero(eq(mload(mc), mload(cc))) {
                            // unsuccess:
                            success := 0
                            cb := 0
                        }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
                case 1 {
                    // slength can contain both the length and contents of the array
                    // if length < 32 bytes so let's prepare for that
                    // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                    if iszero(iszero(slength)) {
                        switch lt(slength, 32)
                            case 1 {
                                // blank the last byte which is the length
                                fslot := mul(div(fslot, 0x100), 0x100)

                                if iszero(
                                    eq(fslot, mload(add(_postBytes, 0x20)))
                                ) {
                                    // unsuccess:
                                    success := 0
                                }
                            }
                            default {
                                // cb is a circuit breaker in the for loop since there's
                                //  no said feature for inline assembly loops
                                // cb = 1 - don't breaker
                                // cb = 0 - break
                                let cb := 1

                                // get the keccak hash to get the contents of the array
                                mstore(0x0, _preBytes_slot)
                                let sc := keccak256(0x0, 0x20)

                                let mc := add(_postBytes, 0x20)
                                let end := add(mc, mlength)

                                // the next line is the loop condition:
                                // while(uint(mc < end) + cb == 2)
                                for {

                                } eq(add(lt(mc, end), cb), 2) {
                                    sc := add(sc, 1)
                                    mc := add(mc, 0x20)
                                } {
                                    if iszero(eq(sload(sc), mload(mc))) {
                                        // unsuccess:
                                        success := 0
                                        cb := 0
                                    }
                                }
                            }
                    }
                }
                default {
                    // unsuccess:
                    success := 0
                }
        }

        return success;
    }

    function toBytes32(bytes memory _source)
        internal
        pure
        returns (bytes32 result)
    {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes32 result) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

pragma solidity 0.5.17;

library ModUtils {
    /**
     * @dev Wrap the modular exponent pre-compile introduced in Byzantium.
     * Returns base^exponent mod p.
     */
    function modExp(
        uint256 base,
        uint256 exponent,
        uint256 p
    ) internal view returns (uint256 o) {
        /* solium-disable-next-line */
        assembly {
            // Args for the precompile: [<length_of_BASE> <length_of_EXPONENT>
            // <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>]
            let output := mload(0x40)
            let args := add(output, 0x20)
            mstore(args, 0x20)
            mstore(add(args, 0x20), 0x20)
            mstore(add(args, 0x40), 0x20)
            mstore(add(args, 0x60), base)
            mstore(add(args, 0x80), exponent)
            mstore(add(args, 0xa0), p)

            // 0x05 is the modular exponent contract address
            if iszero(staticcall(not(0), 0x05, args, 0xc0, output, 0x20)) {
                revert(0, 0)
            }
            o := mload(output)
        }
    }

    /**
     * @dev Calculates and returns the square root of a mod p if such a square
     * root exists. The modulus p must be an odd prime. If a square root does
     * not exist, function returns 0.
     */
    function modSqrt(uint256 a, uint256 p) internal view returns (uint256) {
        if (legendre(a, p) != 1) {
            return 0;
        }

        if (a == 0) {
            return 0;
        }

        if (p % 4 == 3) {
            return modExp(a, (p + 1) / 4, p);
        }

        uint256 s = p - 1;
        uint256 e = 0;

        while (s % 2 == 0) {
            s = s / 2;
            e = e + 1;
        }

        // Note the smaller int- finding n with Legendre symbol or -1
        // should be quick
        uint256 n = 2;
        while (legendre(n, p) != -1) {
            n = n + 1;
        }

        uint256 x = modExp(a, (s + 1) / 2, p);
        uint256 b = modExp(a, s, p);
        uint256 g = modExp(n, s, p);
        uint256 r = e;
        uint256 gs = 0;
        uint256 m = 0;
        uint256 t = b;

        while (true) {
            t = b;
            m = 0;

            for (m = 0; m < r; m++) {
                if (t == 1) {
                    break;
                }
                t = modExp(t, 2, p);
            }

            if (m == 0) {
                return x;
            }

            gs = modExp(g, uint256(2)**(r - m - 1), p);
            g = (gs * gs) % p;
            x = (x * gs) % p;
            b = (b * g) % p;
            r = m;
        }
    }

    /**
     * @dev Calculates the Legendre symbol of the given a mod p.
     * @return Returns 1 if a is a quadratic residue mod p, -1 if it is
     * a non-quadratic residue, and 0 if a is 0.
     */
    function legendre(uint256 a, uint256 p) internal view returns (int256) {
        uint256 raised = modExp(a, (p - 1) / uint256(2), p);

        if (raised == 0 || raised == 1) {
            return int256(raised);
        } else if (raised == p - 1) {
            return -1;
        }

        require(false, "Failed to calculate legendre.");
    }
}

pragma solidity 0.5.17;

library OperatorParams {
    // OperatorParams packs values that are commonly used together
    // into a single uint256 to reduce the cost functions
    // like querying eligibility.
    //
    // An OperatorParams uint256 contains:
    // - the operator's staked token amount (uint128)
    // - the operator's creation timestamp (uint64)
    // - the operator's undelegation timestamp (uint64)
    //
    // These are packed as [amount | createdAt | undelegatedAt]
    //
    // Staked KEEP is stored in an uint128,
    // which is sufficient because KEEP tokens have 18 decimals (2^60)
    // and there will be at most 10^9 KEEP in existence (2^30).
    //
    // Creation and undelegation times are stored in an uint64 each.
    // Thus uint64s would be sufficient for around 3*10^11 years.
    uint256 constant TIMESTAMP_WIDTH = 64;
    uint256 constant AMOUNT_WIDTH = 128;

    uint256 constant TIMESTAMP_MAX = (2**TIMESTAMP_WIDTH) - 1;
    uint256 constant AMOUNT_MAX = (2**AMOUNT_WIDTH) - 1;

    uint256 constant CREATION_SHIFT = TIMESTAMP_WIDTH;
    uint256 constant AMOUNT_SHIFT = 2 * TIMESTAMP_WIDTH;

    function pack(
        uint256 amount,
        uint256 createdAt,
        uint256 undelegatedAt
    ) internal pure returns (uint256) {
        // Check for staked amount overflow.
        // We shouldn't actually ever need this.
        require(amount <= AMOUNT_MAX, "uint128 overflow");
        // Bitwise OR the timestamps together.
        // The resulting number is equal or greater than either,
        // and tells if we have a bit set outside the 64 available bits.
        require(
            (createdAt | undelegatedAt) <= TIMESTAMP_MAX,
            "uint64 overflow"
        );

        return ((amount << AMOUNT_SHIFT) |
            (createdAt << CREATION_SHIFT) |
            undelegatedAt);
    }

    function unpack(uint256 packedParams)
        internal
        pure
        returns (
            uint256 amount,
            uint256 createdAt,
            uint256 undelegatedAt
        )
    {
        amount = getAmount(packedParams);
        createdAt = getCreationTimestamp(packedParams);
        undelegatedAt = getUndelegationTimestamp(packedParams);
    }

    function getAmount(uint256 packedParams) internal pure returns (uint256) {
        return (packedParams >> AMOUNT_SHIFT) & AMOUNT_MAX;
    }

    function setAmount(uint256 packedParams, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return
            pack(
                amount,
                getCreationTimestamp(packedParams),
                getUndelegationTimestamp(packedParams)
            );
    }

    function getCreationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return (packedParams >> CREATION_SHIFT) & TIMESTAMP_MAX;
    }

    function setCreationTimestamp(
        uint256 packedParams,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }

    function getUndelegationTimestamp(uint256 packedParams)
        internal
        pure
        returns (uint256)
    {
        return packedParams & TIMESTAMP_MAX;
    }

    function setUndelegationTimestamp(
        uint256 packedParams,
        uint256 undelegationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                getAmount(packedParams),
                getCreationTimestamp(packedParams),
                undelegationTimestamp
            );
    }

    function setAmountAndCreationTimestamp(
        uint256 packedParams,
        uint256 amount,
        uint256 creationTimestamp
    ) internal pure returns (uint256) {
        return
            pack(
                amount,
                creationTimestamp,
                getUndelegationTimestamp(packedParams)
            );
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library PercentUtils {
    using SafeMath for uint256;

    // Return `b`% of `a`
    // 200.percent(40) == 80
    // Commutative, works both ways
    function percent(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(100);
    }

    // Return `a` as percentage of `b`:
    // 80.asPercentOf(200) == 40
    function asPercentOf(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(100).div(b);
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * NOTE: This call _does not revert_ if the signature is invalid, or
     * if the signer is otherwise unable to be retrieved. In those scenarios,
     * the zero address is returned.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";

/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
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