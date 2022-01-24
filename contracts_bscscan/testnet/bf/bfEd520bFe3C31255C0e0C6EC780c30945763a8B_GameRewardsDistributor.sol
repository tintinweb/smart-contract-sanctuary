// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ICurrencyManager.sol";
import "./interfaces/IGameRewardsDistributor.sol";
import "./interfaces/IERC20Mintable.sol";

contract GameRewardsDistributor is
    IGameRewardsDistributor,
    ContextUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    ICurrencyManager public currencyManager;

    uint256 public requirements;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant FUNCTION_SIGNATURE = 0x9209d87fc373597945cc2d520bd690f36493a9aa6bcd6f91b8ef412322d09b49;
    mapping(bytes32 => address) private _contractAddresses;
    mapping(bytes32 => bool) public currenciesApproved;
    mapping(address => bool) public validators;
    mapping(bytes => bool) public signsDistributed;
    mapping(bytes32 => uint256) public countdownsPerCurrency;
    mapping(address => mapping(bytes32 => uint256)) private _countdowns;

    modifier isTokenContract(address token) {
        require(
            IERC20Mintable(token).totalSupply() >= 0,
            "The token is not token contract"
        );
        _;
    }

    modifier currencyApproved(bytes32 currency) {
        require(currenciesApproved[currency], "Currency not approved");
        _;
    }

    modifier currencyNotApproved(bytes32 currency) {
        require(!currenciesApproved[currency], "Currency approved");
        _;
    }

    constructor() {}

    function initialize(
        ICurrencyManager _currencyManager,
        uint256 _requirements
    ) public initializer {
        require(
            address(_currencyManager) != address(0),
            "The currency manager is the zero address"
        );
        require(
            _requirements > 0,
            "The confirmation requirements is the zero value"
        );
        __Context_init_unchained();
        __Pausable_init_unchained();
        __Ownable_init_unchained();

        currencyManager = _currencyManager;
        requirements = _requirements;
        DOMAIN_SEPARATOR = keccak256(abi.encode(address(this)));
    }

    function countdownOf(address account, bytes32 currency)
        external
        view
        returns (uint256)
    {
        return _countdowns[account][currency];
    }

    function approveToken(address token)
        external
        override
        onlyOwner
        isTokenContract(token)
    {
        bytes32 currency = bytes32(uint256(uint160(token)));
        require(!currenciesApproved[currency], "Currency approved");

        currenciesApproved[currency] = true;
        _contractAddresses[currency] = token;
        emit CurrencyApproved(_msgSender(), currency);
    }

    function approveInGameCurrency(bytes32 currency)
        external
        override
        onlyOwner
        currencyNotApproved(currency)
    {
        currenciesApproved[currency] = true;
        emit CurrencyApproved(_msgSender(), currency);
    }

    function refuseCurrency(bytes32 currency)
        external
        override
        onlyOwner
        currencyApproved(currency)
    {
        require(currenciesApproved[currency], "Currency not approved");

        currenciesApproved[currency] = false;
        _contractAddresses[currency] = address(0);
        emit CurrencyRefused(_msgSender(), currency);
    }

    function approveValidator(address account) external override onlyOwner {
        require(!validators[account], "Validator approved");
        require(account != address(0), "The account is the zero address");

        validators[account] = true;
        emit ValidatorApproved(_msgSender(), account);
    }

    function refuseValidator(address validator) external override onlyOwner {
        require(validators[validator], "Validator not approved");

        validators[validator] = false;
        emit ValidatorRefused(_msgSender(), validator);
    }

    function updateRequirements(uint256 newRequirements)
        external
        override
        onlyOwner
    {
        require(newRequirements > 0, "The new requirements is the zero value");

        requirements = newRequirements;
        emit RequirementsChanged(_msgSender(), newRequirements);
    }

    function updateCountdownPerCurrency(
        bytes32 currency,
        uint256 newCountdownOfCurrency
    ) external override onlyOwner currencyApproved(currency) {
        countdownsPerCurrency[currency] = newCountdownOfCurrency;
        emit CountdownPerCurrencyChanged(
            _msgSender(),
            currency,
            newCountdownOfCurrency
        );
    }

    /**
     * @dev Pauses the contract.
     *
     *
     * Requirements:
     *
     * - the caller is the owner.
     *
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unauses the contract.
     *
     *
     * Requirements:
     *
     * - the caller is the owner.
     *
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function claimGameRewards(GameReward[] calldata gameRewards)
        external
        override
        whenNotPaused
    {
        bytes32 domain_separator = DOMAIN_SEPARATOR;
        bytes32 funcSignature = FUNCTION_SIGNATURE;
        uint256 _requirements = requirements;
        uint256 length1 = gameRewards.length;
        for (uint256 i; i < length1; ) {
            GameReward calldata reward = gameRewards[i];
            bytes32 currency = reward.currency;
            require(currenciesApproved[currency], "Currency not approved");
            require(
                reward.amounts.length == reward.signatures.length &&
                    reward.amounts.length == reward.uuids.length,
                "Invalid parameters"
            );
            require(
                block.timestamp >= _countdowns[_msgSender()][currency],
                "On the countdown to reward distribution"
            );

            uint256 total;
            uint256 length2 = reward.amounts.length;
            for (uint256 j; j < length2; ) {
                bytes[] calldata signatures = reward.signatures[j];
                require(
                    signatures.length >= _requirements,
                    "The length of signatures must be greater or equal than requirements"
                );

                uint256 amount = reward.amounts[j];
                bytes32 uuid = reward.uuids[j];
                bytes32 digest = ECDSAUpgradeable.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            domain_separator,
                            keccak256(
                                abi.encode(
                                    funcSignature,
                                    _msgSender(),
                                    currency,
                                    amount,
                                    uuid
                                )
                            )
                        )
                    )
                );
                uint256 required;
                uint256 length3 = signatures.length;
                unchecked {
                    for (uint256 k; k < length3; ++k) {
                        bytes calldata signature = signatures[k];
                        require(
                            !signsDistributed[signature],
                            "The signature has been distributed"
                        );
                        address recoverAddress = ECDSAUpgradeable.recover(
                            digest,
                            signature
                        );
                        signsDistributed[signature] = true;
                        required += validators[recoverAddress] ? 1 : 0;
                    }
                }
                require(required >= _requirements, "Not confirmed");
                total += amount;
                unchecked {
                    ++j;
                }
            }
            address contractAddress = _contractAddresses[currency];
            unchecked {
                if (contractAddress != address(0)) {
                    IERC20Mintable(contractAddress).mint(_msgSender(), total);
                    _countdowns[_msgSender()][currency] =
                        block.timestamp +
                        countdownsPerCurrency[currency];
                } else {
                    currencyManager.increase(currency, _msgSender(), total);
                }
                ++i;
            }
            emit Distributed(_msgSender(), currency, reward.amounts, reward.signatures);
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
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
import "../proxy/utils/Initializable.sol";

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
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
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ICurrencyManager {
    function increase(
        bytes32 currency,
        address account,
        uint256 amount
    ) external;

    function decrease(
        bytes32 currency,
        address account,
        uint256 amount
    ) external;

    function totalSupply(bytes32 currency) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGameRewardsDistributor {
    struct GameReward {
        bytes32 currency;
        uint256[] amounts;
        bytes[][] signatures;
        bytes32[] uuids;
    }
    /**
     * @dev Emitted when `validator` is approved from `account`
     */
    event ValidatorApproved(address account, address validator);

    /**
     * @dev Emitted when `validator` is refused from `account`
     */
    event ValidatorRefused(address account, address validator);

    /**
     * @dev Emitted when `currency` is approveds from `account`
     */
    event CurrencyApproved(address account, bytes32 currency);

    /**
     * @dev Emitted when `currency` is refused from `account`
     */
    event CurrencyRefused(address acccount, bytes32 currency);

    /**
     * @dev Emitted when `confimationRequiremnets` confirmation requirements is changed from `account`
     */
    event RequirementsChanged(
        address account,
        uint256 confimationRequiremnets
    );

    /**
     * @dev Emitted when `countdownOfTokenDistribution` is changed from `account`
     */
    event CountdownPerCurrencyChanged(
        address account,
        bytes32 currency,
        uint256 countdownOfTokenDistribution
    );

    /**
     * @dev Emitted when `rewards` is distributed to `account`
     */
    event Distributed(
        address indexed account,
        bytes32 indexed currency,
        uint256[] amounts,
        bytes[][] signatures
    );

    /**
     * @dev Approves `account` is the validator.
     *
     * Requirements:
     * - the `account` is not approved.
     * - the `account` is not the zero address.
     * - the caller is the owner.
     *
     * Emits an {ValidatorApproved} event.
     */
    function approveValidator(address account) external;

    /**
     * @dev Refuses `account` is the validator.
     *
     * Requirements:
     * - the `account` is approved.
     * - the caller is the owner.
     *
     * Emits an {ValidatorApproved} event.
     */
    function refuseValidator(address account) external;

    /**
     * @dev Approves a `token` as a reward.
     *
     * Requirements:
     *
     * - the `token` is not approved.
     * - the `token` is token contract.
     * - the caller is the owner.
     *
     * Emits an {CurrencyApproved} event.
     */
    function approveToken(address token) external;

    /**
     * @dev Approves a `currency` as a reward.
     *
     * Requirements:
     *
     * - the `currency` is not approved.
     * - the caller is the owner.
     *
     * Emits an {CurrencyApproved} event.
     */
    function approveInGameCurrency(bytes32 currency) external;

    /**
     * @dev Refuses `currency` as reward.
     *
     * Requirements:
     *
     * - the `currency` is approved.
     * - the caller is the owner.
     *
     * Emits an {CurrencyRefused} event.
     */
    function refuseCurrency(bytes32 currency) external;

    /**
     * @dev Updates `confirmation requirements`.
     *
     * Requirements:
     * - the `newRequirements` must be greater than 0.
     * - the caller is the owner.
     *
     * Emits an {RequirementsChanged} event.
     */
    function updateRequirements(uint256 newRequirements)
        external;

    /**
     * @dev Updates `countdown of currency distribution`.
     *
     * Requirements:
     * - the caller is the owner.
     *
     * Emits an {CountdownPerCurrencyChanged} event.
     */
    function updateCountdownPerCurrency(
        bytes32 currency,
        uint256 newCountdownPerCurrency
    ) external;

    /**
     * @dev Claim rewards from multiple signatures.
     *
     * Requirements:
     * - the length of `currencies` and `amounts` is match.
     * - the length of `currencies` and `signatures` is match.
     * - the length of `currencies` and `uuids` is match.
     * - the each `signature` of `signatures` must not have distributed the reward
     *
     * Emits multiple {Distributed} event.
     */
    function claimGameRewards(
        GameReward[] calldata gameRewards
    ) external;
}

// SPDX-License-Identifier: MIT


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    
    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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