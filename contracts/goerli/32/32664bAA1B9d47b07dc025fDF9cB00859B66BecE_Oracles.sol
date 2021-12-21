// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./presets/OwnablePausableUpgradeable.sol";
import "./interfaces/IRewardEthToken.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IOracles.sol";
import "./interfaces/IMerkleDistributor.sol";
import "./interfaces/IPoolValidators.sol";
import "./interfaces/IOraclesV1.sol";

/**
 * @title Oracles
 *
 * @dev Oracles contract stores accounts responsible for submitting or update values based on the off-chain data.
 * The threshold of inputs from different oracles is required to submit the data.
 */
contract Oracles is IOracles, OwnablePausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // @dev Rewards nonce is used to protect from submitting the same rewards vote several times.
    CountersUpgradeable.Counter private rewardsNonce;

    // @dev Validators nonce is used to protect from submitting the same validator vote several times.
    CountersUpgradeable.Counter private validatorsNonce;

    // @dev Address of the RewardEthToken contract.
    IRewardEthToken private rewardEthToken;

    // @dev Address of the Pool contract.
    IPool private pool;

    // @dev Address of the Pool contract.
    IPoolValidators private poolValidators;

    // @dev Address of the MerkleDistributor contract.
    IMerkleDistributor private merkleDistributor;

    /**
    * @dev Modifier for checking whether the caller is an oracle.
    */
    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, msg.sender), "Oracles: access denied");
        _;
    }

    /**
     * @dev See {IOracles-initialize}.
     */
    function initialize(
        address admin,
        address oraclesV1,
        address _rewardEthToken,
        address _pool,
        address _poolValidators,
        address _merkleDistributor
    )
        external override initializer
    {
        require(admin != address(0), "Pool: invalid admin address");
        require(_rewardEthToken != address(0), "Pool: invalid RewardEthToken address");
        require(_pool != address(0), "Pool: invalid Pool address");
        require(_poolValidators != address(0), "Pool: invalid PoolValidators address");
        require(_merkleDistributor != address(0), "Pool: invalid MerkleDistributor address");

        __OwnablePausableUpgradeable_init(admin);

        // migrate data from previous Oracles contract
        rewardsNonce._value = IOraclesV1(oraclesV1).currentNonce().add(1000);
        uint256 oraclesCount = AccessControlUpgradeable(oraclesV1).getRoleMemberCount(ORACLE_ROLE);
        for (uint256 i = 0; i < oraclesCount; i++) {
            address oracle = AccessControlUpgradeable(oraclesV1).getRoleMember(ORACLE_ROLE, i);
            _setupRole(ORACLE_ROLE, oracle);
            emit OracleAdded(oracle);
        }

        rewardEthToken = IRewardEthToken(_rewardEthToken);
        pool = IPool(_pool);
        poolValidators = IPoolValidators(_poolValidators);
        merkleDistributor = IMerkleDistributor(_merkleDistributor);
        emit Initialized(rewardsNonce.current());
    }

    /**
     * @dev See {IOracles-currentRewardsNonce}.
     */
    function currentRewardsNonce() external override view returns (uint256) {
        return rewardsNonce.current();
    }

    /**
     * @dev See {IOracles-currentValidatorsNonce}.
     */
    function currentValidatorsNonce() external override view returns (uint256) {
        return validatorsNonce.current();
    }

    /**
     * @dev See {IOracles-isOracle}.
     */
    function isOracle(address account) external override view returns (bool) {
        return hasRole(ORACLE_ROLE, account);
    }

    /**
     * @dev See {IOracles-addOracle}.
     */
    function addOracle(address account) external override {
        grantRole(ORACLE_ROLE, account);
        emit OracleAdded(account);
    }

    /**
     * @dev See {IOracles-removeOracle}.
     */
    function removeOracle(address account) external override {
        revokeRole(ORACLE_ROLE, account);
        emit OracleRemoved(account);
    }

    /**
     * @dev See {IOracles-isMerkleRootVoting}.
     */
    function isMerkleRootVoting() public override view returns (bool) {
        uint256 lastRewardBlockNumber = rewardEthToken.lastUpdateBlockNumber();
        return merkleDistributor.lastUpdateBlockNumber() < lastRewardBlockNumber && lastRewardBlockNumber != block.number;
    }

    /**
    * @dev Function for checking whether number of signatures is enough to update the value.
    * @param signaturesCount - number of signatures.
    */
    function isEnoughSignatures(uint256 signaturesCount) internal view returns (bool) {
        return signaturesCount.mul(3) > getRoleMemberCount(ORACLE_ROLE).mul(2);
    }

    /**
     * @dev See {IOracles-submitRewards}.
     */
    function submitRewards(
        uint256 totalRewards,
        uint256 activatedValidators,
        bytes[] calldata signatures
    )
        external override onlyOracle whenNotPaused
    {
        require(isEnoughSignatures(signatures.length), "Oracles: invalid number of signatures");

        // calculate candidate ID hash
        uint256 nonce = rewardsNonce.current();
        bytes32 candidateId = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encode(nonce, activatedValidators, totalRewards))
        );

        // check signatures and calculate number of submitted oracle votes
        address[] memory signedOracles = new address[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            bytes memory signature = signatures[i];
            address signer = ECDSAUpgradeable.recover(candidateId, signature);
            require(hasRole(ORACLE_ROLE, signer), "Oracles: invalid signer");

            for (uint256 j = 0; j < i; j++) {
                require(signedOracles[j] != signer, "Oracles: repeated signature");
            }
            signedOracles[i] = signer;
            emit RewardsVoteSubmitted(msg.sender, signer, nonce, totalRewards, activatedValidators);
        }

        // increment nonce for future signatures
        rewardsNonce.increment();

        // update total rewards
        rewardEthToken.updateTotalRewards(totalRewards);

        // update activated validators
        if (activatedValidators != pool.activatedValidators()) {
            pool.setActivatedValidators(activatedValidators);
        }
    }

    /**
     * @dev See {IOracles-submitMerkleRoot}.
     */
    function submitMerkleRoot(
        bytes32 merkleRoot,
        string calldata merkleProofs,
        bytes[] calldata signatures
    )
        external override onlyOracle whenNotPaused
    {
        require(isMerkleRootVoting(), "Oracles: too early");
        require(isEnoughSignatures(signatures.length), "Oracles: invalid number of signatures");

        // calculate candidate ID hash
        uint256 nonce = rewardsNonce.current();
        bytes32 candidateId = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encode(nonce, merkleProofs, merkleRoot))
        );

        // check signatures and calculate number of submitted oracle votes
        address[] memory signedOracles = new address[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            bytes memory signature = signatures[i];
            address signer = ECDSAUpgradeable.recover(candidateId, signature);
            require(hasRole(ORACLE_ROLE, signer), "Oracles: invalid signer");

            for (uint256 j = 0; j < i; j++) {
                require(signedOracles[j] != signer, "Oracles: repeated signature");
            }
            signedOracles[i] = signer;
            emit MerkleRootVoteSubmitted(msg.sender, signer, nonce, merkleRoot, merkleProofs);
        }

        // increment nonce for future signatures
        rewardsNonce.increment();

        // update merkle root
        merkleDistributor.setMerkleRoot(merkleRoot, merkleProofs);
    }

    /**
     * @dev See {IOracles-registerValidator}.
     */
    function registerValidator(
        IPoolValidators.DepositData calldata depositData,
        bytes32[] calldata merkleProof,
        bytes32 validatorsDepositRoot,
        bytes[] calldata signatures
    )
        external override onlyOracle whenNotPaused
    {
        require(
            pool.validatorRegistration().get_deposit_root() == validatorsDepositRoot,
            "Oracles: invalid validators deposit root"
        );
        require(isEnoughSignatures(signatures.length), "Oracles: invalid number of signatures");

        // calculate candidate ID hash
        uint256 nonce = validatorsNonce.current();
        bytes32 candidateId = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encode(nonce, depositData.publicKey, depositData.operator, validatorsDepositRoot))
        );

        // check signatures and calculate number of submitted oracle votes
        address[] memory signedOracles = new address[](signatures.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            bytes memory signature = signatures[i];
            address signer = ECDSAUpgradeable.recover(candidateId, signature);
            require(hasRole(ORACLE_ROLE, signer), "Oracles: invalid signer");

            for (uint256 j = 0; j < i; j++) {
                require(signedOracles[j] != signer, "Oracles: repeated signature");
            }
            signedOracles[i] = signer;
            emit RegisterValidatorVoteSubmitted(
                msg.sender,
                signer,
                depositData.operator,
                depositData.publicKey,
                nonce
            );
        }

        // increment nonce for future signatures
        validatorsNonce.increment();

        // register validator
        poolValidators.registerValidator(depositData, merkleProof);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMathUpgradeable.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library CountersUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
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
            revert("ECDSA: invalid signature length");
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

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/IOwnablePausable.sol";

/**
 * @title OwnablePausableUpgradeable
 *
 * @dev Bundles Access Control, Pausable and Upgradeable contracts in one.
 *
 */
abstract contract OwnablePausableUpgradeable is IOwnablePausable, PausableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
    * @dev Modifier for checking whether the caller is an admin.
    */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "OwnablePausable: access denied");
        _;
    }

    /**
    * @dev Modifier for checking whether the caller is a pauser.
    */
    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, msg.sender), "OwnablePausable: access denied");
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __OwnablePausableUpgradeable_init(address _admin) internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __OwnablePausableUpgradeable_init_unchained(_admin);
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `PAUSER_ROLE` to the admin account.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __OwnablePausableUpgradeable_init_unchained(address _admin) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
    }

    /**
     * @dev See {IOwnablePausable-isAdmin}.
     */
    function isAdmin(address _account) external override view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     * @dev See {IOwnablePausable-addAdmin}.
     */
    function addAdmin(address _account) external override {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     * @dev See {IOwnablePausable-removeAdmin}.
     */
    function removeAdmin(address _account) external override {
        revokeRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /**
     * @dev See {IOwnablePausable-isPauser}.
     */
    function isPauser(address _account) external override view returns (bool) {
        return hasRole(PAUSER_ROLE, _account);
    }

    /**
     * @dev See {IOwnablePausable-addPauser}.
     */
    function addPauser(address _account) external override {
        grantRole(PAUSER_ROLE, _account);
    }

    /**
     * @dev See {IOwnablePausable-removePauser}.
     */
    function removePauser(address _account) external override {
        revokeRole(PAUSER_ROLE, _account);
    }

    /**
     * @dev See {IOwnablePausable-pause}.
     */
    function pause() external override onlyPauser {
        _pause();
    }

    /**
     * @dev See {IOwnablePausable-unpause}.
     */
    function unpause() external override onlyPauser {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the RewardEthToken contract.
 */
interface IRewardEthToken is IERC20Upgradeable {
    /**
    * @dev Structure for storing information about user reward checkpoint.
    * @param rewardPerToken - user reward per token.
    * @param reward - user reward checkpoint.
    */
    struct Checkpoint {
        uint128 reward;
        uint128 rewardPerToken;
    }

    /**
    * @dev Event for tracking updated protocol fee recipient.
    * @param recipient - address of the new fee recipient.
    */
    event ProtocolFeeRecipientUpdated(address recipient);

    /**
    * @dev Event for tracking updated protocol fee.
    * @param protocolFee - new protocol fee.
    */
    event ProtocolFeeUpdated(uint256 protocolFee);

    /**
    * @dev Event for tracking whether rewards distribution through merkle distributor is enabled/disabled.
    * @param account - address of the account.
    * @param isDisabled - whether rewards distribution is disabled.
    */
    event RewardsToggled(address indexed account, bool isDisabled);

    /**
    * @dev Event for tracking rewards update by oracles.
    * @param periodRewards - rewards since the last update.
    * @param totalRewards - total amount of rewards.
    * @param rewardPerToken - calculated reward per token for account reward calculation.
    * @param distributorReward - distributor reward.
    * @param protocolReward - protocol reward.
    */
    event RewardsUpdated(
        uint256 periodRewards,
        uint256 totalRewards,
        uint256 rewardPerToken,
        uint256 distributorReward,
        uint256 protocolReward
    );

    /**
    * @dev Function for upgrading the RewardEthToken contract. The `initialize` function must be defined
    * if deploying contract for the first time that will initialize the state variables above.
    * @param _oracles - address of the Oracles contract.
    */
    function upgrade(address _oracles) external;

    /**
    * @dev Function for getting the address of the merkle distributor.
    */
    function merkleDistributor() external view returns (address);

    /**
    * @dev Function for getting the address of the protocol fee recipient.
    */
    function protocolFeeRecipient() external view returns (address);

    /**
    * @dev Function for changing the protocol fee recipient's address.
    * @param recipient - new protocol fee recipient's address.
    */
    function setProtocolFeeRecipient(address recipient) external;

    /**
    * @dev Function for getting protocol fee. The percentage fee users pay from their reward for using the pool service.
    */
    function protocolFee() external view returns (uint256);

    /**
    * @dev Function for changing the protocol fee.
    * @param _protocolFee - new protocol fee. Must be less than 10000 (100.00%).
    */
    function setProtocolFee(uint256 _protocolFee) external;

    /**
    * @dev Function for retrieving the total rewards amount.
    */
    function totalRewards() external view returns (uint128);

    /**
    * @dev Function for retrieving the last total rewards update block number.
    */
    function lastUpdateBlockNumber() external view returns (uint256);

    /**
    * @dev Function for retrieving current reward per token used for account reward calculation.
    */
    function rewardPerToken() external view returns (uint128);

    /**
    * @dev Function for setting whether rewards are disabled for the account.
    * Can only be called by the `StakedEthToken` contract.
    * @param account - address of the account to disable rewards for.
    * @param isDisabled - whether the rewards will be disabled.
    */
    function setRewardsDisabled(address account, bool isDisabled) external;

    /**
    * @dev Function for retrieving account's current checkpoint.
    * @param account - address of the account to retrieve the checkpoint for.
    */
    function checkpoints(address account) external view returns (uint128, uint128);

    /**
    * @dev Function for checking whether account's reward will be distributed through the merkle distributor.
    * @param account - address of the account.
    */
    function rewardsDisabled(address account) external view returns (bool);

    /**
    * @dev Function for updating account's reward checkpoint.
    * @param account - address of the account to update the reward checkpoint for.
    */
    function updateRewardCheckpoint(address account) external returns (bool);

    /**
    * @dev Function for updating reward checkpoints for two accounts simultaneously (for gas savings).
    * @param account1 - address of the first account to update the reward checkpoint for.
    * @param account2 - address of the second account to update the reward checkpoint for.
    */
    function updateRewardCheckpoints(address account1, address account2) external returns (bool, bool);

    /**
    * @dev Function for updating validators total rewards.
    * Can only be called by Oracles contract.
    * @param newTotalRewards - new total rewards.
    */
    function updateTotalRewards(uint256 newTotalRewards) external;

    /**
    * @dev Function for claiming rETH2 from the merkle distribution.
    * Can only be called by MerkleDistributor contract.
    * @param account - address of the account the tokens will be assigned to.
    * @param amount - amount of tokens to assign to the account.
    */
    function claim(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IDepositContract.sol";
import "./IPoolValidators.sol";

/**
 * @dev Interface of the Pool contract.
 */
interface IPool {
    /**
    * @dev Event for tracking registered validators.
    * @param publicKey - validator public key.
    * @param operator - address of the validator operator.
    */
    event ValidatorRegistered(bytes publicKey, address operator);

    /**
    * @dev Event for tracking refunds.
    * @param sender - address of the refund sender.
    * @param amount - refunded amount.
    */
    event Refunded(address indexed sender, uint256 amount);

    /**
    * @dev Event for tracking scheduled deposit activation.
    * @param sender - address of the deposit sender.
    * @param validatorIndex - index of the activated validator.
    * @param value - deposit amount to be activated.
    */
    event ActivationScheduled(address indexed sender, uint256 validatorIndex, uint256 value);

    /**
    * @dev Event for tracking activated deposits.
    * @param account - account the deposit was activated for.
    * @param validatorIndex - index of the activated validator.
    * @param value - amount activated.
    * @param sender - address of the transaction sender.
    */
    event Activated(address indexed account, uint256 validatorIndex, uint256 value, address indexed sender);

    /**
    * @dev Event for tracking activated validators updates.
    * @param activatedValidators - new total amount of activated validators.
    * @param sender - address of the transaction sender.
    */
    event ActivatedValidatorsUpdated(uint256 activatedValidators, address sender);

    /**
    * @dev Event for tracking updates to the minimal deposit amount considered for the activation period.
    * @param minActivatingDeposit - new minimal deposit amount considered for the activation.
    * @param sender - address of the transaction sender.
    */
    event MinActivatingDepositUpdated(uint256 minActivatingDeposit, address sender);

    /**
    * @dev Event for tracking pending validators limit.
    * When it's exceeded, the deposits will be set for the activation.
    * @param pendingValidatorsLimit - pending validators percent limit.
    * @param sender - address of the transaction sender.
    */
    event PendingValidatorsLimitUpdated(uint256 pendingValidatorsLimit, address sender);

    /**
    * @dev Event for tracking added deposits with partner.
    * @param partner - address of the partner.
    * @param amount - the amount added.
    */
    event StakedWithPartner(address indexed partner, uint256 amount);

    /**
    * @dev Event for tracking added deposits with referrer.
    * @param referrer - address of the referrer.
    * @param amount - the amount added.
    */
    event StakedWithReferrer(address indexed referrer, uint256 amount);

    /**
    * @dev Function for upgrading the Pools contract. The `initialize` function must be defined if deploying contract
    * for the first time that will initialize the state variables above.
    * @param _poolValidators - address of the PoolValidators contract.
    * @param _oracles - address of the Oracles contract.
    */
    function upgrade(address _poolValidators, address _oracles) external;

    /**
    * @dev Function for getting the total validator deposit.
    */
    // solhint-disable-next-line func-name-mixedcase
    function VALIDATOR_TOTAL_DEPOSIT() external view returns (uint256);

    /**
    * @dev Function for retrieving the total amount of pending validators.
    */
    function pendingValidators() external view returns (uint256);

    /**
    * @dev Function for retrieving the total amount of activated validators.
    */
    function activatedValidators() external view returns (uint256);

    /**
    * @dev Function for retrieving the withdrawal credentials used to
    * initiate pool validators withdrawal from the beacon chain.
    */
    function withdrawalCredentials() external view returns (bytes32);

    /**
    * @dev Function for getting the minimal deposit amount considered for the activation.
    */
    function minActivatingDeposit() external view returns (uint256);

    /**
    * @dev Function for getting the pending validators percent limit.
    * When it's exceeded, the deposits will be set for the activation.
    */
    function pendingValidatorsLimit() external view returns (uint256);

    /**
    * @dev Function for getting the amount of activating deposits.
    * @param account - address of the account to get the amount for.
    * @param validatorIndex - index of the activated validator.
    */
    function activations(address account, uint256 validatorIndex) external view returns (uint256);

    /**
    * @dev Function for setting minimal deposit amount considered for the activation period.
    * @param newMinActivatingDeposit - new minimal deposit amount considered for the activation.
    */
    function setMinActivatingDeposit(uint256 newMinActivatingDeposit) external;

    /**
    * @dev Function for changing the total amount of activated validators.
    * @param newActivatedValidators - new total amount of activated validators.
    */
    function setActivatedValidators(uint256 newActivatedValidators) external;

    /**
    * @dev Function for changing pending validators limit.
    * @param newPendingValidatorsLimit - new pending validators limit. When it's exceeded, the deposits will be set for the activation.
    */
    function setPendingValidatorsLimit(uint256 newPendingValidatorsLimit) external;

    /**
    * @dev Function for checking whether validator index can be activated.
    * @param validatorIndex - index of the validator to check.
    */
    function canActivate(uint256 validatorIndex) external view returns (bool);

    /**
    * @dev Function for retrieving the validator registration contract address.
    */
    function validatorRegistration() external view returns (IDepositContract);

    /**
    * @dev Function for staking ether to the pool to the different tokens' recipient.
    * @param recipient - address of the tokens recipient.
    */
    function stakeOnBehalf(address recipient) external payable;

    /**
    * @dev Function for staking ether to the pool.
    */
    function stake() external payable;

    /**
    * @dev Function for staking ether with the partner that will receive the revenue share from the protocol fee.
    * @param partner - address of partner who will get the revenue share.
    */
    function stakeWithPartner(address partner) external payable;

    /**
    * @dev Function for staking ether with the partner that will receive the revenue share from the protocol fee
    * and the different tokens' recipient.
    * @param partner - address of partner who will get the revenue share.
    * @param recipient - address of the tokens recipient.
    */
    function stakeWithPartnerOnBehalf(address partner, address recipient) external payable;

    /**
    * @dev Function for staking ether with the referrer who will receive the one time bonus.
    * @param referrer - address of referrer who will get its referral bonus.
    */
    function stakeWithReferrer(address referrer) external payable;

    /**
    * @dev Function for staking ether with the referrer who will receive the one time bonus
    * and the different tokens' recipient.
    * @param referrer - address of referrer who will get its referral bonus.
    * @param recipient - address of the tokens recipient.
    */
    function stakeWithReferrerOnBehalf(address referrer, address recipient) external payable;

    /**
    * @dev Function for minting account's tokens for the specific validator index.
    * @param account - account address to activate the tokens for.
    * @param validatorIndex - index of the activated validator.
    */
    function activate(address account, uint256 validatorIndex) external;

    /**
    * @dev Function for minting account's tokens for the specific validator indexes.
    * @param account - account address to activate the tokens for.
    * @param validatorIndexes - list of activated validator indexes.
    */
    function activateMultiple(address account, uint256[] calldata validatorIndexes) external;

    /**
    * @dev Function for registering new pool validator registration.
    * @param depositData - the deposit data to submit for the validator.
    */
    function registerValidator(IPoolValidators.DepositData calldata depositData) external;

    /**
    * @dev Function for refunding to the pool.
    * Can only be executed by the account with admin role.
    */
    function refund() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

import "./IPoolValidators.sol";
pragma abicoder v2;

/**
 * @dev Interface of the Oracles contract.
 */
interface IOracles {
    /**
    * @dev Event for tracking the Oracles contract initialization.
    * @param rewardsNonce - rewards nonce the contract was initialized with.
    */
    event Initialized(uint256 rewardsNonce);

    /**
    * @dev Event for tracking oracle rewards votes.
    * @param sender - address of the transaction sender.
    * @param oracle - address of the account which submitted vote.
    * @param nonce - current nonce.
    * @param totalRewards - submitted value of total rewards.
    * @param activatedValidators - submitted amount of activated validators.
    */
    event RewardsVoteSubmitted(
        address indexed sender,
        address indexed oracle,
        uint256 nonce,
        uint256 totalRewards,
        uint256 activatedValidators
    );

    /**
    * @dev Event for tracking oracle merkle root votes.
    * @param sender - address of the transaction sender.
    * @param oracle - address of the account which submitted vote.
    * @param nonce - current nonce.
    * @param merkleRoot - new merkle root.
    * @param merkleProofs - link to the merkle proofs.
    */
    event MerkleRootVoteSubmitted(
        address indexed sender,
        address indexed oracle,
        uint256 nonce,
        bytes32 indexed merkleRoot,
        string merkleProofs
    );

    /**
    * @dev Event for tracking validator registration votes.
    * @param sender - address of the transaction sender.
    * @param oracle - address of the signed oracle.
    * @param operator - address of the operator the vote was sent for.
    * @param publicKey - public key of the validator the vote was sent for.
    * @param nonce - validator registration nonce.
    */
    event RegisterValidatorVoteSubmitted(
        address indexed sender,
        address indexed oracle,
        address indexed operator,
        bytes publicKey,
        uint256 nonce
    );

    /**
    * @dev Event for tracking new or updates oracles.
    * @param oracle - address of new or updated oracle.
    */
    event OracleAdded(address indexed oracle);

    /**
    * @dev Event for tracking removed oracles.
    * @param oracle - address of removed oracle.
    */
    event OracleRemoved(address indexed oracle);

    /**
    * @dev Constructor for initializing the Oracles contract.
    * @param admin - address of the contract admin.
    * @param oraclesV1 - address of the Oracles V1 contract.
    * @param _rewardEthToken - address of the RewardEthToken contract.
    * @param _pool - address of the Pool contract.
    * @param _poolValidators - address of the PoolValidators contract.
    * @param _merkleDistributor - address of the MerkleDistributor contract.
    */
    function initialize(
        address admin,
        address oraclesV1,
        address _rewardEthToken,
        address _pool,
        address _poolValidators,
        address _merkleDistributor
    ) external;

    /**
    * @dev Function for checking whether an account has an oracle role.
    * @param account - account to check.
    */
    function isOracle(address account) external view returns (bool);

    /**
    * @dev Function for checking whether the oracles are currently voting for new merkle root.
    */
    function isMerkleRootVoting() external view returns (bool);

    /**
    * @dev Function for retrieving current rewards nonce.
    */
    function currentRewardsNonce() external view returns (uint256);

    /**
    * @dev Function for retrieving current validators nonce.
    */
    function currentValidatorsNonce() external view returns (uint256);

    /**
    * @dev Function for adding an oracle role to the account.
    * Can only be called by an account with an admin role.
    * @param account - account to assign an oracle role to.
    */
    function addOracle(address account) external;

    /**
    * @dev Function for removing an oracle role from the account.
    * Can only be called by an account with an admin role.
    * @param account - account to remove an oracle role from.
    */
    function removeOracle(address account) external;

    /**
    * @dev Function for submitting oracle vote for total rewards.
    * The quorum of signatures over the same data is required to submit the new value.
    * @param totalRewards - voted total rewards.
    * @param activatedValidators - voted amount of activated validators.
    * @param signatures - oracles' signatures.
    */
    function submitRewards(
        uint256 totalRewards,
        uint256 activatedValidators,
        bytes[] calldata signatures
    ) external;

    /**
    * @dev Function for submitting new merkle root.
    * The quorum of signatures over the same data is required to submit the new value.
    * @param merkleRoot - hash of the new merkle root.
    * @param merkleProofs - link to the merkle proofs.
    * @param signatures - oracles' signatures.
    */
    function submitMerkleRoot(
        bytes32 merkleRoot,
        string calldata merkleProofs,
        bytes[] calldata signatures
    ) external;

    /**
    * @dev Function for submitting registration of the new validator.
    * The quorum of signatures over the same data is required to register.
    * @param depositData - the deposit data for the registration.
    * @param merkleProof - an array of hashes to verify whether the deposit data is part of the deposit data merkle root.
    * @param validatorsDepositRoot - validators deposit root to protect from malicious operators.
    * @param signatures - oracles' signatures.
    */
    function registerValidator(
        IPoolValidators.DepositData calldata depositData,
        bytes32[] calldata merkleProof,
        bytes32 validatorsDepositRoot,
        bytes[] calldata signatures
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IOracles.sol";

/**
 * @dev Interface of the MerkleDistributor contract.
 * Allows anyone to claim a token if they exist in a merkle root.
 */
interface IMerkleDistributor {
    /**
    * @dev Event for tracking merkle root updates.
    * @param sender - address of the new transaction sender.
    * @param merkleRoot - new merkle root hash.
    * @param merkleProofs - link to the merkle proofs.
    */
    event MerkleRootUpdated(
        address indexed sender,
        bytes32 indexed merkleRoot,
        string merkleProofs
    );

    /**
    * @dev Event for tracking periodic tokens distributions.
    * @param from - address to transfer the tokens from.
    * @param token - address of the token.
    * @param beneficiary - address of the beneficiary, the allocation is added to.
    * @param amount - amount of tokens to distribute.
    * @param startBlock - start block of the tokens distribution.
    * @param endBlock - end block of the tokens distribution.
    */
    event PeriodicDistributionAdded(
        address indexed from,
        address indexed token,
        address indexed beneficiary,
        uint256 amount,
        uint256 startBlock,
        uint256 endBlock
    );

    /**
    * @dev Event for tracking one time tokens distributions.
    * @param from - address to transfer the tokens from.
    * @param origin - predefined origin address to label the distribution.
    * @param token - address of the token.
    * @param amount - amount of tokens to distribute.
    * @param rewardsLink - link to the file where rewards are stored.
    */
    event OneTimeDistributionAdded(
        address indexed from,
        address indexed origin,
        address indexed token,
        uint256 amount,
        string rewardsLink
    );

    /**
    * @dev Event for tracking tokens' claims.
    * @param account - the address of the user that has claimed the tokens.
    * @param index - the index of the user that has claimed the tokens.
    * @param tokens - list of token addresses the user got amounts in.
    * @param amounts - list of user token amounts.
    */
    event Claimed(address indexed account, uint256 index, address[] tokens, uint256[] amounts);

    /**
    * @dev Function for getting the current merkle root.
    */
    function merkleRoot() external view returns (bytes32);

    /**
    * @dev Function for getting the RewardEthToken contract address.
    */
    function rewardEthToken() external view returns (address);

    /**
    * @dev Function for getting the Oracles contract address.
    */
    function oracles() external view returns (IOracles);

    /**
    * @dev Function for retrieving the last total merkle root update block number.
    */
    function lastUpdateBlockNumber() external view returns (uint256);

    /**
    * @dev Function for upgrading the MerkleDistributor contract. The `initialize` function must be defined
    * if deploying contract for the first time that will initialize the state variables above.
    * @param _oracles - address of the Oracles contract.
    */
    function upgrade(address _oracles) external;

    /**
    * @dev Function for checking the claimed bit map.
    * @param _merkleRoot - the merkle root hash.
    * @param _wordIndex - the word index of te bit map.
    */
    function claimedBitMap(bytes32 _merkleRoot, uint256 _wordIndex) external view returns (uint256);

    /**
    * @dev Function for changing the merkle root. Can only be called by `Oracles` contract.
    * @param newMerkleRoot - new merkle root hash.
    * @param merkleProofs - URL to the merkle proofs.
    */
    function setMerkleRoot(bytes32 newMerkleRoot, string calldata merkleProofs) external;

    /**
    * @dev Function for distributing tokens periodically for the number of blocks.
    * @param from - address of the account to transfer the tokens from.
    * @param token - address of the token.
    * @param beneficiary - address of the beneficiary.
    * @param amount - amount of tokens to distribute.
    * @param durationInBlocks - duration in blocks when the token distribution should be stopped.
    */
    function distributePeriodically(
        address from,
        address token,
        address beneficiary,
        uint256 amount,
        uint256 durationInBlocks
    ) external;

    /**
    * @dev Function for distributing tokens one time.
    * @param from - address of the account to transfer the tokens from.
    * @param origin - predefined origin address to label the distribution.
    * @param token - address of the token.
    * @param amount - amount of tokens to distribute.
    * @param rewardsLink - link to the file where rewards for the accounts are stored.
    */
    function distributeOneTime(
        address from,
        address origin,
        address token,
        uint256 amount,
        string calldata rewardsLink
    ) external;

    /**
    * @dev Function for checking whether the tokens were already claimed.
    * @param index - the index of the user that is part of the merkle root.
    */
    function isClaimed(uint256 index) external view returns (bool);

    /**
    * @dev Function for claiming the given amount of tokens to the account address.
    * Reverts if the inputs are invalid or the oracles are currently updating the merkle root.
    * @param index - the index of the user that is part of the merkle root.
    * @param account - the address of the user that is part of the merkle root.
    * @param tokens - list of the token addresses.
    * @param amounts - list of token amounts.
    * @param merkleProof - an array of hashes to verify whether the user is part of the merkle root.
    */
    function claim(
        uint256 index,
        address account,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[] calldata merkleProof
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @dev Interface of the PoolValidators contract.
 */
interface IPoolValidators {
    /**
    * @dev Structure for storing operator data.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param committed - defines whether operator has committed its readiness to host validators.
    */
    struct Operator {
        bytes32 depositDataMerkleRoot;
        bool committed;
    }

    /**
    * @dev Structure for passing information about the validator deposit data.
    * @param operator - address of the operator.
    * @param withdrawalCredentials - withdrawal credentials used for generating the deposit data.
    * @param depositDataRoot - hash tree root of the deposit data, generated by the operator.
    * @param publicKey - BLS public key of the validator, generated by the operator.
    * @param signature - BLS signature of the validator, generated by the operator.
    */
    struct DepositData {
        address operator;
        bytes32 withdrawalCredentials;
        bytes32 depositDataRoot;
        bytes publicKey;
        bytes signature;
    }

    /**
    * @dev Event for tracking new operators.
    * @param operator - address of the operator.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param depositDataMerkleProofs - validators deposit data merkle proofs.
    */
    event OperatorAdded(
        address indexed operator,
        bytes32 indexed depositDataMerkleRoot,
        string depositDataMerkleProofs
    );

    /**
    * @dev Event for tracking operator's commitments.
    * @param operator - address of the operator that expressed its readiness to host validators.
    */
    event OperatorCommitted(address indexed operator);

    /**
    * @dev Event for tracking operators' removals.
    * @param sender - address of the transaction sender.
    * @param operator - address of the operator.
    */
    event OperatorRemoved(
        address indexed sender,
        address indexed operator
    );

    /**
    * @dev Constructor for initializing the PoolValidators contract.
    * @param _admin - address of the contract admin.
    * @param _pool - address of the Pool contract.
    * @param _oracles - address of the Oracles contract.
    */
    function initialize(address _admin, address _pool, address _oracles) external;

    /**
    * @dev Function for retrieving the operator.
    * @param _operator - address of the operator to retrieve the data for.
    */
    function getOperator(address _operator) external view returns (bytes32, bool);

    /**
    * @dev Function for checking whether validator is registered.
    * @param validatorId - hash of the validator public key to receive the status for.
    */
    function isValidatorRegistered(bytes32 validatorId) external view returns (bool);

    /**
    * @dev Function for adding new operator.
    * @param _operator - address of the operator to add or update.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param depositDataMerkleProofs - validators deposit data merkle proofs.
    */
    function addOperator(
        address _operator,
        bytes32 depositDataMerkleRoot,
        string calldata depositDataMerkleProofs
    ) external;

    /**
    * @dev Function for committing operator. Must be called by the operator address
    * specified through the `addOperator` function call.
    */
    function commitOperator() external;

    /**
    * @dev Function for removing operator. Can be called either by operator or admin.
    * @param _operator - address of the operator to remove.
    */
    function removeOperator(address _operator) external;

    /**
    * @dev Function for registering the validator.
    * @param depositData - deposit data of the validator.
    * @param merkleProof - an array of hashes to verify whether the deposit data is part of the merkle root.
    */
    function registerValidator(DepositData calldata depositData, bytes32[] calldata merkleProof) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

pragma abicoder v2;

/**
 * @dev Interface of the Oracles V1 contract.
 */
interface IOraclesV1 {
    /**
    * @dev Function for retrieving current rewards nonce.
    */
    function currentNonce() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

/**
 * @dev Interface of the OwnablePausableUpgradeable and OwnablePausable contracts.
 */
interface IOwnablePausable {
    /**
    * @dev Function for checking whether an account has an admin role.
    * @param _account - account to check.
    */
    function isAdmin(address _account) external view returns (bool);

    /**
    * @dev Function for assigning an admin role to the account.
    * Can only be called by an account with an admin role.
    * @param _account - account to assign an admin role to.
    */
    function addAdmin(address _account) external;

    /**
    * @dev Function for removing an admin role from the account.
    * Can only be called by an account with an admin role.
    * @param _account - account to remove an admin role from.
    */
    function removeAdmin(address _account) external;

    /**
    * @dev Function for checking whether an account has a pauser role.
    * @param _account - account to check.
    */
    function isPauser(address _account) external view returns (bool);

    /**
    * @dev Function for adding a pauser role to the account.
    * Can only be called by an account with an admin role.
    * @param _account - account to assign a pauser role to.
    */
    function addPauser(address _account) external;

    /**
    * @dev Function for removing a pauser role from the account.
    * Can only be called by an account with an admin role.
    * @param _account - account to remove a pauser role from.
    */
    function removePauser(address _account) external;

    /**
    * @dev Function for pausing the contract.
    */
    function pause() external;

    /**
    * @dev Function for unpausing the contract.
    */
    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
/// https://github.com/ethereum/eth2.0-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}