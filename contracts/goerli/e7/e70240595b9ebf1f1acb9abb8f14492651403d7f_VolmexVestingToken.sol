// SPDX-License-Identifier: BUSL 1.1
pragma solidity =0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Token/BaseToken.sol";
import "./interfaces/ITreasuryVester.sol";
import "./interfaces/IVolmexToken.sol";

/**
 * @title Factory Contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexVestingToken is BaseToken, OwnableUpgradeable {
    // TreasuryVester contract implementation
    address public treasuryImplementation;
    // volmex ERC20 token
    IVolmexToken public volmexToken;
    // unique index
    uint256 public indexCount;

    /* ========== EVENTS ========== */
    event TreasuriesCreated(
        address[] receivers,
        uint256[] quantities,
        address[] treasuryContracts,
        uint256 vestingBegin,
        uint256 vestingEnd,
        uint256 vestingCliff
    );

    /**
     * @notice Get the address of implementation contracts instance.
     * @param _implementation address of factory contract
     * @param _volmexToken address of volmex ERC20 token
     */
    function initialize(address _implementation, IVolmexToken _volmexToken)
        external
        initializer
    {
        __Ownable_init();
        init();
        treasuryImplementation = _implementation;
        volmexToken = _volmexToken;
    }

    /**
     * @notice update the TreasuryVester contract address
     * @param _implementation address of factory contract
     */
    function updateImplementationAddress(address _implementation)
        external
        onlyOwner
    {
        treasuryImplementation = _implementation;
    }

    /**
     * @notice Get the expected address of treasury vester contract
     * @param _recipient is the address of receiver
     * @param _index is a integer value
     */
    function predictTreasuryVester(address _recipient, uint256 _index)
        external
        view
        returns (address)
    {
        bytes32 salt = keccak256(abi.encodePacked(_recipient, _index));
        return
            Clones.predictDeterministicAddress(
                treasuryImplementation,
                salt,
                address(this)
            );
    }

    /**
     * @notice cloned the treasury vester contract for array of addresses
     * @param _recipients is the array of addresses of receivers
     * @param _quantities is a array of amounts which is claimable by users
     * @param _vestingDurations is array of vestingEnd, vestingBegin and vestingCliff.
     */
    function createTreasuryVesters(
        address[] calldata _recipients,
        uint256[] calldata _quantities,
        uint256[3] calldata _vestingDurations
    ) external onlyOwner {
        require(
            _recipients.length == _quantities.length,
            "VolmexVestingToken: Length of arrays are not equal"
        );
        uint256 _indexCount = indexCount;
        address[] memory treasuryContracts = new address[](_recipients.length);
        address newTreasuryContract;
        for (uint256 i = 0; i < _recipients.length; i++) {
            _indexCount++;
            bytes32 salt = keccak256(
                abi.encodePacked(_recipients[i], _indexCount)
            );
            newTreasuryContract = Clones.cloneDeterministic(
                treasuryImplementation,
                salt
            );
            _mint(_recipients[i], _quantities[i]);
            treasuryContracts[i] = newTreasuryContract;
            whiteList[newTreasuryContract] = true;
            ITreasuryVester(newTreasuryContract).initialize(
                address(this),
                address(volmexToken),
                _recipients[i],
                _vestingDurations[0],
                _vestingDurations[1],
                _vestingDurations[2],
                _quantities[i]
            );
            volmexToken.transferFrom(
                msg.sender,
                newTreasuryContract,
                _quantities[i]
            );
        }
        indexCount = _indexCount;
        emit TreasuriesCreated(
            _recipients,
            _quantities,
            treasuryContracts,
            _vestingDurations[0],
            _vestingDurations[1],
            _vestingDurations[2]
        );
    }

    function updateRecipient(address newRecipient, ITreasuryVester treasureVester)
        external
        onlyOwner
    {
        require(
            newRecipient != address(0),
            "VolmexVestingToken: Cannot be 0 address"
        );
        require(
            address(treasureVester) != address(0),
            "VolmexVestingToken: Cannot be 0 address"
        );
        address prevRecipient = treasureVester.recipient();
        uint256 balance = balanceOf(prevRecipient);
        _transfer(prevRecipient, newRecipient, balance);
        treasureVester.setRecipient(newRecipient);
    }

    /**
     * @notice Method to end vesting and transfer the refund amount.
     *
     * @param treasureVester Address on the TreasureVester contract to end vesting
     * @param refundAddress Address of the user to transfer the un-claimable amount
     */
    function endVesting(ITreasuryVester treasureVester, address refundAddress) external onlyOwner {
        require(address(treasureVester) != address(0), "VolmexVestingToken: Zero address");

        treasureVester.endVesting(refundAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity =0.8.11;

import "./GovernanceBaseToken.sol";

/**
 * @notice implementation of the Volmex Vesting token contract
 * @author  volmex.finance [[email protected]]
 */
contract BaseToken is GovernanceBaseToken {
    // mapping of eligible burner address
    mapping(address => bool) public whiteList;
    string internal constant NAME = "Vesting Token";
    string internal constant SYMBOL = "xVOLX";
    uint8 internal constant DECIMALS = 18;

    uint256 public constant REVISION = 1;

    /// @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    mapping(address => mapping(uint256 => Snapshot)) public _snapshots;

    mapping(address => uint256) public _countsSnapshots;

    bytes32 public DOMAIN_SEPARATOR;
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    mapping(address => address) internal _votingDelegates;

    mapping(address => mapping(uint256 => Snapshot))
        internal _propositionPowerSnapshots;
    mapping(address => uint256) internal _propositionPowerSnapshotsCounts;

    mapping(address => address) internal _propositionPowerDelegates;

    /**
     * @dev initializes the contract upon assignment to the InitializableAdminUpgradeabilityProxy
     */
    function init() internal initializer {
        __ERC20_init(NAME, SYMBOL);

        uint256 chainId;

        //solium-disable-next-line
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes(NAME)),
                keccak256(EIP712_REVISION),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev implements the permit function as for https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner the owner of the funds
     * @param spender the spender
     * @param value the amount
     * @param deadline the deadline timestamp, type(uint256).max for no deadline
     * @param v signature param
     * @param s signature param
     * @param r signature param
     */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(owner != address(0), "INVALID_OWNER");
        //solium-disable-next-line
        require(block.timestamp <= deadline, "INVALID_EXPIRATION");
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        currentValidNonce,
                        deadline
                    )
                )
            )
        );

        require(owner == ecrecover(digest, v, r, s), "INVALID_SIGNATURE");
        _nonces[owner] = currentValidNonce + 1;
        _approve(owner, spender, value);
    }

    /**
     * @dev returns the revision of the implementation contract
     */
    function getRevision() internal pure returns (uint256) {
        return REVISION;
    }

    /**
     * @dev Writes a snapshot before any operation involving transfer of value: _transfer, _mint and _burn
     * - On _transfer, it writes snapshots for both "from" and "to"
     * - On _mint, only for _to
     * - On _burn, only for _from
     * @param from the from address
     * @param to the to address
     * @param amount the amount to transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        address votingFromDelegatee = _getDelegatee(from, _votingDelegates);
        address votingToDelegatee = _getDelegatee(to, _votingDelegates);

        _moveDelegatesByType(
            votingFromDelegatee,
            votingToDelegatee,
            amount,
            DelegationType.VOTING_POWER
        );

        address propPowerFromDelegatee = _getDelegatee(
            from,
            _propositionPowerDelegates
        );
        address propPowerToDelegatee = _getDelegatee(
            to,
            _propositionPowerDelegates
        );

        _moveDelegatesByType(
            propPowerFromDelegatee,
            propPowerToDelegatee,
            amount,
            DelegationType.PROPOSITION_POWER
        );
    }

    function _getDelegationDataByType(DelegationType delegationType)
        internal
        view
        override
        returns (
            mapping(address => mapping(uint256 => Snapshot)) storage, //snapshots
            mapping(address => uint256) storage, //snapshots count
            mapping(address => address) storage //delegatees list
        )
    {
        if (delegationType == DelegationType.VOTING_POWER) {
            return (_snapshots, _countsSnapshots, _votingDelegates);
        } else {
            return (
                _propositionPowerSnapshots,
                _propositionPowerSnapshotsCounts,
                _propositionPowerDelegates
            );
        }
    }

    /**
     * @dev Delegates power from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateByTypeBySig(
        address delegatee,
        DelegationType delegationType,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATE_BY_TYPE_TYPEHASH,
                delegatee,
                uint256(delegationType),
                nonce,
                expiry
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INVALID_SIGNATURE");
        require(nonce == _nonces[signatory]++, "INVALID_NONCE");
        //solium-disable-next-line
        require(block.timestamp <= expiry, "INVALID_EXPIRATION");
        _delegateByType(signatory, delegatee, delegationType);
    }

    /**
     * @dev Delegates power from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 structHash = keccak256(
            abi.encode(DELEGATE_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "INVALID_SIGNATURE");
        require(nonce == _nonces[signatory]++, "INVALID_NONCE");
        //solium-disable-next-line
        require(block.timestamp <= expiry, "INVALID_EXPIRATION");
        _delegateByType(signatory, delegatee, DelegationType.VOTING_POWER);
        _delegateByType(signatory, delegatee, DelegationType.PROPOSITION_POWER);
    }

    function burn(address account, uint256 amount) external {
        require(whiteList[msg.sender], "BaseToken: Not authorized");
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: BUSL 1.1

pragma solidity =0.8.11;

interface ITreasuryVester {
    function initialize(
        address _volmexRewardFactory,
        address _volmexToken,
        address _recipient,
        uint256 _vestingBegin,
        uint256 _vestingEnd,
        uint256 _vestingCliff,
        uint256 _vestingAmount
    ) external;

    function setRecipient(address _recipient) external;

    function claim() external;

    function endVesting(address treasurer) external;

    function volmexToken() external view returns (address);

    function owner() external view returns (address);

    function recipient() external view returns (address);

    function vestingBegin() external view returns (uint256);

    function vestingEnd() external view returns (uint256);

    function vestingcliff() external view returns (uint256);

    function lastUpdate() external view returns (uint256);

    function vestingAmount() external view returns (uint256);

    function getCurrentClaimAmount() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity =0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IVolmexToken {
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * 
 * constructor() initializer {}
 * ```
 * ====
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

// SPDX-License-Identifier: BUSL 1.1
pragma solidity =0.8.11;
pragma experimental ABIEncoderV2;

import "./ERC20Upgradeable.sol";
import "../interfaces/IGovernanceBaseToken.sol";

/**
 * @notice implementation of the VOLMEX VESTING token contract
 * @author  volmex.finance [[email protected]]
 */
abstract contract GovernanceBaseToken is
    ERC20Upgradeable,
    IGovernanceBaseToken
{
    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH =
        keccak256(
            "DelegateByType(address delegatee,uint256 type,uint256 nonce,uint256 expiry)"
        );

    bytes32 public constant DELEGATE_TYPEHASH =
        keccak256("Delegate(address delegatee,uint256 nonce,uint256 expiry)");

    /// @dev snapshot of a value on a specific block, used for votes
    struct Snapshot {
        uint128 blockNumber;
        uint128 value;
    }

    /**
     * @dev delegates one specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function delegateByType(address delegatee, DelegationType delegationType)
        external
        override
    {
        _delegateByType(msg.sender, delegatee, delegationType);
    }

    /**
     * @dev delegates all the powers to a specific user
     * @param delegatee the user to which the power will be delegated
     **/
    function delegate(address delegatee) external override {
        _delegateByType(msg.sender, delegatee, DelegationType.VOTING_POWER);
        _delegateByType(
            msg.sender,
            delegatee,
            DelegationType.PROPOSITION_POWER
        );
    }

    /**
     * @dev returns the delegatee of an user
     * @param delegator the address of the delegator
     **/
    function getDelegateeByType(
        address delegator,
        DelegationType delegationType
    ) external view override returns (address) {
        (
            ,
            ,
            mapping(address => address) storage delegates
        ) = _getDelegationDataByType(delegationType);

        return _getDelegatee(delegator, delegates);
    }

    /**
     * @dev returns the current delegated power of a user. The current power is the
     * power delegated at the time of the last snapshot
     * @param user the user
     **/
    function getPowerCurrent(address user, DelegationType delegationType)
        external
        view
        override
        returns (uint256)
    {
        (
            mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
            mapping(address => uint256) storage snapshotsCounts,

        ) = _getDelegationDataByType(delegationType);

        return
            _searchByBlockNumber(
                snapshots,
                snapshotsCounts,
                user,
                block.number
            );
    }

    /**
     * @dev returns the delegated power of a user at a certain block
     * @param user the user
     **/
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view override returns (uint256) {
        (
            mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
            mapping(address => uint256) storage snapshotsCounts,

        ) = _getDelegationDataByType(delegationType);

        return
            _searchByBlockNumber(snapshots, snapshotsCounts, user, blockNumber);
    }

    /**
     * @dev returns the total supply at a certain block number
     * used by the voting strategy contracts to calculate the total votes needed for threshold/quorum
     * In this initial implementation with no AAVE minting, simply returns the current supply
     * A snapshots mapping will need to be added in case a mint function is added to the AAVE token in the future
     **/
    function totalSupplyAt(uint256 blockNumber)
        external
        view
        override
        returns (uint256)
    {
        return super.totalSupply();
    }

    /**
     * @dev delegates the specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function _delegateByType(
        address delegator,
        address delegatee,
        DelegationType delegationType
    ) internal {
        require(delegatee != address(0), "INVALID_DELEGATEE");

        (
            ,
            ,
            mapping(address => address) storage delegates
        ) = _getDelegationDataByType(delegationType);

        uint256 delegatorBalance = balanceOf(delegator);

        address previousDelegatee = _getDelegatee(delegator, delegates);

        delegates[delegator] = delegatee;

        _moveDelegatesByType(
            previousDelegatee,
            delegatee,
            delegatorBalance,
            delegationType
        );
        emit DelegateChanged(delegator, delegatee, delegationType);
    }

    /**
     * @dev moves delegated power from one user to another
     * @param from the user from which delegated power is moved
     * @param to the user that will receive the delegated power
     * @param amount the amount of delegated power to be moved
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function _moveDelegatesByType(
        address from,
        address to,
        uint256 amount,
        DelegationType delegationType
    ) internal {
        if (from == to) {
            return;
        }

        (
            mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
            mapping(address => uint256) storage snapshotsCounts,

        ) = _getDelegationDataByType(delegationType);

        if (from != address(0)) {
            uint256 previous = 0;
            uint256 fromSnapshotsCount = snapshotsCounts[from];

            if (fromSnapshotsCount != 0) {
                previous = snapshots[from][fromSnapshotsCount - 1].value;
            } else {
                previous = balanceOf(from);
            }

            _writeSnapshot(
                snapshots,
                snapshotsCounts,
                from,
                uint128(previous),
                uint128(previous - amount)
            );

            emit DelegatedPowerChanged(from, previous - amount, delegationType);
        }
        if (to != address(0)) {
            uint256 previous = 0;
            uint256 toSnapshotsCount = snapshotsCounts[to];
            if (toSnapshotsCount != 0) {
                previous = snapshots[to][toSnapshotsCount - 1].value;
            } else {
                previous = balanceOf(to);
            }

            _writeSnapshot(
                snapshots,
                snapshotsCounts,
                to,
                uint128(previous),
                uint128(previous + amount)
            );

            emit DelegatedPowerChanged(to, previous + amount, delegationType);
        }
    }

    /**
     * @dev searches a snapshot by block number. Uses binary search.
     * @param snapshots the snapshots mapping
     * @param snapshotsCounts the number of snapshots
     * @param user the user for which the snapshot is being searched
     * @param blockNumber the block number being searched
     **/
    function _searchByBlockNumber(
        mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
        mapping(address => uint256) storage snapshotsCounts,
        address user,
        uint256 blockNumber
    ) internal view returns (uint256) {
        require(blockNumber <= block.number, "INVALID_BLOCK_NUMBER");

        uint256 snapshotsCount = snapshotsCounts[user];

        if (snapshotsCount == 0) {
            return balanceOf(user);
        }

        // First check most recent balance
        if (snapshots[user][snapshotsCount - 1].blockNumber <= blockNumber) {
            return snapshots[user][snapshotsCount - 1].value;
        }

        // Next check implicit zero balance
        if (snapshots[user][0].blockNumber > blockNumber) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = snapshotsCount - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Snapshot memory snapshot = snapshots[user][center];
            if (snapshot.blockNumber == blockNumber) {
                return snapshot.value;
            } else if (snapshot.blockNumber < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return snapshots[user][lower].value;
    }

    /**
     * @dev returns the delegation data (snapshot, snapshotsCount, list of delegates) by delegation type
     * NOTE: Ideal implementation would have mapped this in a struct by delegation type. Unfortunately,
     * the AAVE token and StakeToken already include a mapping for the snapshots, so we require contracts
     * who inherit from this to provide access to the delegation data by overriding this method.
     * @param delegationType the type of delegation
     **/
    function _getDelegationDataByType(DelegationType delegationType)
        internal
        view
        virtual
        returns (
            mapping(address => mapping(uint256 => Snapshot)) storage, //snapshots
            mapping(address => uint256) storage, //snapshots count
            mapping(address => address) storage //delegatees list
        );

    /**
     * @dev Writes a snapshot for an owner of tokens
     * @param owner The owner of the tokens
     * @param oldValue The value before the operation that is gonna be executed after the snapshot
     * @param newValue The value after the operation
     */
    function _writeSnapshot(
        mapping(address => mapping(uint256 => Snapshot)) storage snapshots,
        mapping(address => uint256) storage snapshotsCounts,
        address owner,
        uint128 oldValue,
        uint128 newValue
    ) internal {
        uint128 currentBlock = uint128(block.number);

        uint256 ownerSnapshotsCount = snapshotsCounts[owner];
        mapping(uint256 => Snapshot) storage snapshotsOwner = snapshots[owner];

        // Doing multiple operations in the same block
        if (
            ownerSnapshotsCount != 0 &&
            snapshotsOwner[ownerSnapshotsCount - 1].blockNumber == currentBlock
        ) {
            snapshotsOwner[ownerSnapshotsCount - 1].value = newValue;
        } else {
            snapshotsOwner[ownerSnapshotsCount] = Snapshot(
                currentBlock,
                newValue
            );
            snapshotsCounts[owner] = ownerSnapshotsCount + 1;
        }
    }

    /**
     * @dev returns the user delegatee. If a user never performed any delegation,
     * his delegated address will be 0x0. In that case we simply return the user itself
     * @param delegator the address of the user for which return the delegatee
     * @param delegates the array of delegates for a particular type of delegation
     **/
    function _getDelegatee(
        address delegator,
        mapping(address => address) storage delegates
    ) internal view returns (address) {
        address previousDelegatee = delegates[delegator];

        if (previousDelegatee == address(0)) {
            return delegator;
        }

        return previousDelegatee;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.11;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address, uint256) public virtual override returns (bool) {
        revert("Vesting token cannot be transfer");
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address, uint256) public virtual override returns (bool) {
        revert("Vesting token cannot be transfer");
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override returns (bool) {
        revert("Vesting token cannot be transfer");
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity =0.8.11;
pragma abicoder v2;

interface IGovernanceBaseToken {
    enum DelegationType {
        VOTING_POWER,
        PROPOSITION_POWER
    }

    /**
     * @dev emitted when a user delegates to another
     * @param delegator the delegator
     * @param delegatee the delegatee
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    event DelegateChanged(
        address indexed delegator,
        address indexed delegatee,
        DelegationType delegationType
    );

    /**
     * @dev emitted when an action changes the delegated power of a user
     * @param user the user which delegated power has changed
     * @param amount the amount of delegated power for the user
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    event DelegatedPowerChanged(
        address indexed user,
        uint256 amount,
        DelegationType delegationType
    );

    /**
     * @dev delegates the specific power to a delegatee
     * @param delegatee the user which delegated power has changed
     * @param delegationType the type of delegation (VOTING_POWER, PROPOSITION_POWER)
     **/
    function delegateByType(address delegatee, DelegationType delegationType)
        external;

    /**
     * @dev delegates all the powers to a specific user
     * @param delegatee the user to which the power will be delegated
     **/
    function delegate(address delegatee) external;

    /**
     * @dev returns the delegatee of an user
     * @param delegator the address of the delegator
     **/
    function getDelegateeByType(
        address delegator,
        DelegationType delegationType
    ) external view returns (address);

    /**
     * @dev returns the current delegated power of a user. The current power is the
     * power delegated at the time of the last snapshot
     * @param user the user
     **/
    function getPowerCurrent(address user, DelegationType delegationType)
        external
        view
        returns (uint256);

    /**
     * @dev returns the delegated power of a user at a certain block
     * @param user the user
     **/
    function getPowerAtBlock(
        address user,
        uint256 blockNumber,
        DelegationType delegationType
    ) external view returns (uint256);

    /**
     * @dev returns the total supply at a certain block number
     **/
    function totalSupplyAt(uint256 blockNumber)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}