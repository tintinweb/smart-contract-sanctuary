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
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}