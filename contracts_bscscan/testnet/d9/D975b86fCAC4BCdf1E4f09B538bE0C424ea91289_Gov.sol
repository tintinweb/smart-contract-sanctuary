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
import "../proxy/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.5 <0.8.0;

import "../token/ERC20/ERC20Upgradeable.sol";
import "./IERC20PermitUpgradeable.sol";
import "../cryptography/ECDSAUpgradeable.sol";
import "../utils/CountersUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping (address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal initializer {
        __Context_init_unchained();
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory name) internal initializer {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _nonces[owner].current(),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
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

pragma solidity ^0.6.0;

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

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
}

pragma solidity ^0.6.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * Requirements:
     *
     * - this function can only be called from a constructor.
     */
    function _setupDecimals(uint8 decimals_) internal {
        require(!address(this).isContract(), "ERC20: decimals cannot be changed after construction");
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

pragma solidity ^0.6.0;

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

pragma solidity ^0.6.0;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the URI for a given token ID. May return an empty string.
     *
     * If the token's URI is non-empty and a base URI was set (via
     * {_setBaseURI}), it will be added to the token ID's URI as a prefix.
     *
     * Reverts if the token ID does not exist.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a preffix in {tokenURI} to each token's URI, when
    * they are non-empty.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param operator operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement {IERC721Receiver-onERC721Received},
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the _msgSender() to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Internal function to safely mint a new token.
     * Reverts if the given token ID already exists.
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     * @param _data bytes data to send along with a safe transfer check
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     *
     * Reverts if the token ID does not exist.
     *
     * TIP: If all token IDs share a prefix (for example, if your URIs look like
     * `https://api.myproject.com/token/<id>`), use {_setBaseURI} to store
     * it and save gas.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI}.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - when `from` is zero, `tokenId` will be minted for `to`.
     * - when `to` is zero, `from`'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

pragma solidity ^0.6.2;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
abstract contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public virtual returns (bytes4);
}

pragma solidity ^0.6.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

pragma solidity ^0.6.0;

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
 * As of v2.5.0, only `address` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.AddressSet;`.
 *
 * @author Alberto Cuesta Cañada
 */
library EnumerableSet {
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../TransferHelper.sol";
import "./BuildToken.sol";
import "../token/TokenControllerInterface.sol";
import "../token/ControlledToken.sol";
import "../token/WrappedToken.sol";
import "../prizePool/PrizePool.sol";
import "../nft/nft.sol";
import "@openzeppelin/contracts-upgradeable/drafts/ERC20PermitUpgradeable.sol";


contract BlindBox is ERC20PermitUpgradeable {
    using SafeMath for uint256;
    event mint_box(uint256, string);
    event draw_out(address, uint256, uint256);
    event draw(address, uint256,address,uint256);
    event mix_true(address, uint256, uint256, bool);
    event resetDraw(uint256 ,uint256[]);
    event resetMix(uint256 _series_id, uint256[]);
    event resetReward(uint256 _series_id, Reward);
    event resetLevel(uint256,uint256[]);
    event reset_ratio(uint256);

    uint256 public constant MIN_NAME_LENGTH = 4;
    uint256 public constant MIN_IMAGE_LINK_LENGTH = 8;
    uint256 public constant MAX_IMAGE_LINK_LENGTH = 128;
    uint256 public constant MIX_TRUE_LOW_LEVEL_NUMBER = 5;
    uint256 public constant DEFAUL_DECIMAL_PLACES = 100;
    struct Config {
        address owner;
        address lable_address;
        address platform_token;
        address key_token;
        address payable prize_pool;
        address flip;
        address nft;
    }

    Config public config;

    enum Grade {S, A, B, C, D}

    struct Box {
        string  name;
        uint256 series_id;
        string  image;
        uint256[] level;
        uint256[] draw;
        uint256[] mix;
        Reward reward;
    }

    struct Reward {
        address[] token;
        uint256[] amount;
    }

    BuildToken public controlledTokenBuilder;

    mapping(uint256 => Box) public box_info;

    uint256[] series_ids;

    constructor(address _owner,
                address _lableAddress,
                address platform_token,
                BuildToken _controlledTokenBuilder,
                address _nft) public {
        controlledTokenBuilder = _controlledTokenBuilder;
        config = Config(_owner, _lableAddress,platform_token,address(0),address(0),address(0),_nft);
    }

    function init(BuildToken.ControlledTokenConfig memory _config,address _flip,address  _prize_pool)onlyOwner public {
        require(_flip != address(0) &&
                config.flip == address(0) &&
                config.key_token == address(0),
                "BlindBox Err:Can not be re-initialized");
        ControlledToken token = _createToken(_config.name, _config.symbol, _config.decimals, _config.controller);
        config.key_token = address(token);
        config.flip = _flip;
        config.prize_pool = payable(_prize_pool);
    }

    function MintBox(Box memory _box)
        onlyOwner
        checkBox(_box) public {
        box_info[_box.series_id] = _box;
        series_ids.push(_box.series_id);
        emit mint_box(_box.series_id, _box.name);
    }

    //ptoken - > k token ratio default 2 decimal places
    uint256 ratio = 1000;
    function Draw(uint256 _number, address _inviter)
        onlynumberofDraw(_number) public
    {
        //keytoken(_number) * ratio = ptoken
        uint256 drawNumber = _number * 10 ** 18 / DEFAUL_DECIMAL_PLACES * ratio;
        require(_inviter != address(0), "BlindBox Err:inviter cannot equal address(0)");
        WrappedToken platform_token = WrappedToken(config.platform_token);
        uint256 amount = platform_token.allowance(msg.sender, address(this));
        require(amount >= drawNumber , "BlindBox Err:amount cannot than allowance");
        TransferHelper.safeTransferFrom(config.platform_token, msg.sender, address(this), drawNumber);
        platform_token.burn(drawNumber/10, msg.sender);
        TransferHelper.safeTransfer(config.platform_token, config.prize_pool, drawNumber / 10 * 8);
        TransferHelper.safeTransfer(config.platform_token, config.lable_address, drawNumber / 100 * 5);
        TransferHelper.safeTransfer(config.platform_token, _inviter, drawNumber / 100 * 5);
        _mint(msg.sender, _number*10**18, _number);
        emit draw(msg.sender, _number,_inviter,drawNumber);
    }

    function ResetRatio(uint256 _ratio) onlyOwner public {
        ratio = _ratio;
        emit reset_ratio(_ratio);
    }

    function mintKey(address sender,uint256 number) onlyFlip external{
        if (number == 1){
            _mint(sender, 1*10**18, 1);
        }else{
            _mint(sender, 10*10**18, 1);
        }
    }

    function DrawOut(uint256 _series_id, uint256 _number)
        onlyBox(_series_id)
        onlynumberofDrawOut(_number) public
    {
        WrappedToken key_token = WrappedToken(config.key_token);
        uint256 amount = key_token.allowance(msg.sender, address(this));
        require(amount == _number * 10 ** 18, "BlindBox Err:amount cannot than allowance");
        Box storage box = box_info[_series_id];
        nft(config.nft).Draw(msg.sender,_number,1,_series_id,box.draw,box.level);
        ControlledToken(config.key_token).controllerBurn(msg.sender,amount);
        emit draw_out(msg.sender, _series_id, _number);
    }

    function MixTrue(uint256 _series_id, uint256 _grade_id,uint256[] memory _tokens_id)
        onlyBox(_series_id)
        onlyGrade(_grade_id)
        checkTokenIdLens(_series_id,_tokens_id)
        public {
        Box storage box = box_info[_series_id];
        nft(config.nft).gradeCompose(msg.sender,_series_id,box.mix,box.level,_grade_id,_tokens_id);
    }

    function Convert(uint256 _series_id,uint256[] memory _token_ids)
        onlyBox(_series_id) public {
        nft(config.nft).cashCheckByTokenID(msg.sender,_series_id,box_info[_series_id].level,_token_ids);
        _sendReward(_series_id);
    }

    receive() external payable{}

    function _sendReward(uint256 _series_id) internal {
        Box storage _box = box_info[_series_id];
        uint256 reward_lens = _box.reward.token.length;
        for (uint i = 0; i < reward_lens; i++) {
            address token = _box.reward.token[i];
            uint256 amount = _box.reward.amount[i];
            PrizePool(config.prize_pool).sender(msg.sender,token, amount);
        }
    }

    event resetOwner(address);
    function ResetOwner(address _owner) onlyOwner public{
        config.owner = _owner;
        emit resetOwner(_owner);
    }

    function ResetDraw(uint256 _series_id, uint256[] memory _draw)
        onlyOwner
        onlyBox(_series_id) public {
        box_info[_series_id].draw = _draw;
        emit resetDraw(_series_id, _draw);
    }

    function ResetMix(uint256 _series_id, uint256[] memory _mix)
        onlyOwner
        onlyBox(_series_id) public {
        box_info[_series_id].mix = _mix;
        emit resetMix(_series_id, _mix);
    }

    function ResetReward(uint256 _series_id, Reward memory _reward)
        onlyOwner
        onlyBox(_series_id)public {
        require(_reward.token.length == _reward.amount.length,
                "BlindBox Err: reward token not equal reward amount");
        box_info[_series_id].reward = _reward;
        emit resetReward(_series_id, _reward);
    }

    function QueryBox(uint256 _series_id) public view returns (Box memory){
        return box_info[_series_id];
    }

    function QueryConfig() public view returns (Config memory){
        return config;
    }

    function QuerySeriesIds() public view returns (uint256[] memory){
        return series_ids;
    }

    function QueryRatio() view public returns (uint256 ,uint256){
        return (1*10**18/DEFAUL_DECIMAL_PLACES*ratio
                ,10*10**18/DEFAUL_DECIMAL_PLACES*ratio);
    }

    function QueryDraws(uint256 _series_id) public view returns (uint256[] memory){
        return box_info[_series_id].draw;
    }

    function QueryLevels(uint256 _series_id) public view returns (uint256[] memory){
        return box_info[_series_id].level;
    }

    function QueryImage(uint256 _series_id) public view returns (string memory){
        return box_info[_series_id].image;
    }

    function QueryBoxs(
                       uint256 start,
                       uint256 end
                       ) public view returns (Box[] memory, uint256){


        uint256 lens = series_ids.length;
        if (lens <= 0 || start > end || start > lens){
            Box[] memory result;
            return (result, lens);
        }
        uint256 index = end;
        if (end > lens) {
            index = lens;
        }
        if (index - start > 30){
            index = start + 30;
        }
        Box[] memory result = new Box[](index - start);
        uint id;
        for (uint i = start; i < index; i++) {
            result[id] = box_info[series_ids[i]];
            id++;
        }
        return (result, lens);
    }

    function _mint(address to, uint256 amount, uint256 number) internal {
        ControlledToken(config.key_token).controllerMint(to, amount, number);
    }

    function _createToken(
        string memory name,
        string memory token,
        uint8 decimals,
        TokenControllerInterface controller
    ) internal returns (ControlledToken){
        return controlledTokenBuilder.createControlledToken(
            BuildToken.ControlledTokenConfig(name, token, decimals, controller));
    }

    modifier onlyOwner(){
        require(msg.sender == config.owner, "BlindBox Err: Unauthoruzed");
        _;
    }

    modifier onlyFlip(){
        require(msg.sender == config.flip, "BlindBox Err: Unauthoruzed");
        _;
    }

    modifier onlynumberofDraw(uint256 _number){
        require(_number == 1 || _number == 10, "BlindBox Err:draw number can only be equal to 1 or 10");
        _;
    }

    modifier onlynumberofDrawOut(uint256 _number){
        require(_number == 1 || _number == 11, "BlindBox Err:draw number can only be equal to 1 or 11");
        _;
    }

    modifier checkBox(Box memory _box){
        uint256 nameLen = bytes(_box.name).length;
        require(nameLen >= MIN_NAME_LENGTH, "BlindBox Err: name length must be less than MIN_NAME_NAME");
        Box storage _box_info = box_info[_box.series_id];
        require(_box_info.series_id == 0, "BlindBox Err: Box already exists");
        uint256 imageLinkLen = bytes(_box.image).length;
        require(imageLinkLen >= MIN_IMAGE_LINK_LENGTH,
                "BlindBox Err: ImageLink length must be less than MIN_IMAGE_LINK_LENGTH");
        require(imageLinkLen <= MAX_IMAGE_LINK_LENGTH,
                "BlindBox Err: ImageLink length must be small than MAX_IMAGE_LINK_LENGTH");
        require(_box.reward.token.length == _box.reward.amount.length,
                "BlindBox Err: reward token not equal reward amount");
        _;
    }

    modifier onlyGrade(uint256 _grade_id){
        require(_grade_id <= 5,"BlindBox  Err:Grade does not exist");
        _;
    }

    modifier checkTokenIdLens(uint256 _series_id,uint256[] memory _tokens_id){
        require(_tokens_id.length ==  MIX_TRUE_LOW_LEVEL_NUMBER,"BlindBox Err: Only receive 5 nft token id");
        _;
    }

    modifier onlyBox(uint256 _series_id){
        Box storage _box_info = box_info[_series_id];
        require(_box_info.series_id != 0, "BlindBox Err: series not found");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../token/ControlledTokenProxyFactory.sol";

contract BuildToken {

    event CreatedControlledToken(address indexed token);

    struct ControlledTokenConfig {
        string name;
        string symbol;
        uint8 decimals;
        TokenControllerInterface controller;
        //address controller;
    }

    ControlledTokenProxyFactory public controlledTokenProxyFactory;

    constructor(ControlledTokenProxyFactory _controlledTokenProxyFactory) public {
        require(address(_controlledTokenProxyFactory) != address(0),"BlindBox Err:ControlledToken Not Zero");
        controlledTokenProxyFactory = _controlledTokenProxyFactory;
    }

    function createControlledToken(
                                  ControlledTokenConfig calldata config
                                  ) external returns(ControlledToken){
        ControlledToken token = controlledTokenProxyFactory.create();
        //ControlledToken token;
        token.initialize(
                         config.name,
                         config.symbol,
                         config.decimals,
                         config.controller
                         );
        emit CreatedControlledToken(address(token));
        return token;
    }
    TokenControllerInterface public  controller;
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual  {
        controller.beforeTokenTransfer(from, to, amount);
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../token/WrappedToken.sol";
import "../TransferHelper.sol";
import "../staking/staking.sol";

contract Gov {
    using SafeMath for uint256;

    uint256 public constant PERCENT_PRECISION = 4;

    uint256 public constant MIN_TITLE_LENGTH = 4;
    uint256 public constant MAX_TITLE_LENGTH = 64;
    uint256 public constant MIN_DESC_LENGTH = 4;
    uint256 public constant MAX_DESC_LENGTH = 256;
    uint256 public constant MIN_LINK_LENGTH = 12;
    uint256 public constant MAX_LINK_LENGTH = 128;

    uint256 public constant MAX_USER_VOTER_NUMBER = 20;

    uint256 public constant MAX_LIMIT = 30;
    Config public config;
    State public state;
    UsersItmap banks;
    PollItmap polls;
    VoterItmap voters;

    struct Config {
        address owner;
        address platform_token;
        uint256 quorum;
        uint256 threshold;
        uint256 voting_period;
        uint256 effective_delay;
        uint256 expiration_period;
        uint256 proposal_deposit;

        address  blindbox;
        address  prizepool;
    }
    struct State {
        uint256 poll_count;
        uint256 total_share;
        uint256 total_deposit;
    }
    struct TokenManager {
        uint256 share;
        mapping(uint256 => VoterInfo) locked_balance;
        uint256[] participated_polls;
        uint256 maxIdx;
    }

    struct VoterInfo {
        address user;
        VoteOption vote;
        uint256 balance;
    }

    struct Poll {
        uint256 id;
        address creator;
        PollStatus status;
        uint256 yes_votes;
        uint256 no_votes;
        uint256 end_height;
        string title;
        string description;
        string link;
        address target;
        string selector;
        bytes data;
        uint256 deposit_amount;
        uint256 total_balance_at_end_poll;
    }

    enum PollStatus { InProgress, Passed, Rejected, Executed, Expired, All }
    enum VoteOption { Yes, No }

    struct PollItmap {
        mapping(uint256 => PollIndexValue) data;
        PollsKeyFlag[] keys;
        uint256 size;
    }
    struct PollIndexValue {
        uint256 keyIndex;
        Poll value;
    }
    struct PollsKeyFlag {
        uint256 key;
        bool deleted;
    }

    struct UsersItmap {
        mapping(address => UsersIndexValue) data;
        UsersKeyFlag[] keys;
        uint256 size;
    }

    struct UsersIndexValue {
        uint256 keyIndex;
        TokenManager value;
    }

    struct UsersKeyFlag {
        address key;
        bool deleted;
    }

    struct VoterItmap {
        mapping(uint256 => VoterIndexValue) data;
        VotersKeyFlag[] keys;
        uint256 size;
    }

    struct VoterIndexValue {
        uint256 keyIndex;
        VoterManager value;
    }

    struct VotersKeyFlag {
        uint256 key;
        bool deleted;
    }

    struct VoterManager {
        address[] user;
        VoteOption[] vote;
        uint256[] balance;
    }


    struct StakerResponse {
        uint256 balance;
        uint256 share;
        voteResp[] locked_balance;
        uint256 maxIdx;
    }

    struct voteResp {
        uint256 poll_id;
        VoterInfo value;
    }


    event create_poll(address _creator, uint256 _poll_id, uint256 _end_height);
    event update_config(address _owner, address _platform_token, uint256 _quorum,
                uint256 _threshold, uint256 _voting_period,
                uint256 _effective_delay, uint256 _expiration_period,
                uint256 _proposal_deposit);
    event stake_voting_token(address _user, uint256 _amount);
    event withdraw_voting_tokens(address _user, uint256 _amount);
    event cast_vote(address _user, uint256 _poll_id, VoteOption vote, uint256 _amount);
    event to_binary(address,uint256);
    event end_poll_log(uint256,string,bool);
    event execute_log(uint256);
    event expire_log(uint256);

    modifier assertPercent(uint256 _percent) {
        require( _percent <= 1 * (10**PERCENT_PRECISION),
            "Gov: percent must be smaller than 1");
        _;
    }

    function assertTitle(string memory _title) pure private {
        uint256 titleLen = bytes(_title).length;
        require( titleLen >= MIN_TITLE_LENGTH,
            "Gov: title length must be grater than MIN_TITLE_LENGTH");
        require( titleLen <= MAX_TITLE_LENGTH,
            "Gov: title length must be small than MAX_TITLE_LENGTH");
    }

    function assertDesc(string memory _desc) pure private {
        uint256 descLen = bytes(_desc).length;
        require( descLen >= MIN_DESC_LENGTH,
            "Gov: desc length must be grater than MIN_DESC_LENGTH");
        require( descLen <= MAX_DESC_LENGTH,
            "Gov: desc length must be small than MAX_DESC_LENGTH");
    }

    function assertLink(string memory _link) pure private {
        uint256 linkLen = bytes(_link).length;
        require( linkLen >= MIN_LINK_LENGTH,
            "Gov: link length must be grater than MIN_LINK_LENGTH");
        require( linkLen <= MAX_LINK_LENGTH,
            "Gov: link length must be small than MAX_LINK_LENGTH");
    }


    constructor(address _owner, address _platform_token, uint256 _quorum,
                uint256 _threshold, uint256 _voting_period,
                uint256 _effective_delay, uint256 _expiration_period,
                uint256 _proposal_deposit) public
                assertPercent(_quorum) assertPercent(_threshold) {
        config.owner = _owner;
        config.platform_token = _platform_token;
        config.quorum = _quorum;
        config.threshold = _threshold;
        config.voting_period = _voting_period;
        config.effective_delay = _effective_delay;
        config.expiration_period = _expiration_period;
        config.proposal_deposit = _proposal_deposit;
    }
        function UpdateConfig(address _owner, address _platform_token, uint256 _quorum,
                uint256 _threshold, uint256 _voting_period,
                uint256 _effective_delay, uint256 _expiration_period,
                uint256 _proposal_deposit
        ) external assertPercent(_quorum) assertPercent(_threshold) {
        require(config.owner == msg.sender, "Gov UpdateConfig: unauthorized");
        config.owner = _owner;
        config.platform_token = _platform_token;
        config.quorum = _quorum;
        config.threshold = _threshold;
        config.voting_period = _voting_period;
        config.effective_delay = _effective_delay;
        config.expiration_period = _expiration_period;
        config.proposal_deposit = _proposal_deposit;
        emit update_config(_owner, _platform_token, _quorum, _threshold,
                           _voting_period, _effective_delay, _expiration_period,
                            _proposal_deposit);
    }

    function Init(address  _prize_pool_addr,
                  address _blindbox_addr,
                  address _platform_lp,
                  address _staking_addr)public{
        require(msg.sender == config.owner,"Gov Err: unauthorized");
        config.prizepool = _prize_pool_addr;
        config.blindbox = _blindbox_addr;
        //BlindBox(payable(_blindbox_addr)).init(_token,_filp,_prize_pool_addr);
        //feat: init staking register platform-usdt lp token pool
        Staking(_staking_addr).registerPlatformAsset(config.platform_token,_platform_lp);
    }

    function CreatePoll(uint256 _deposit_amount, string memory _title,
                        string memory _description, string memory _link, address _target,
                        string memory _selector, bytes memory _data
        ) public {
        assertTitle(_title);
        assertDesc(_description);
        assertLink(_link);
        require(_deposit_amount >= config.proposal_deposit,
                "Gov CreatePoll: Must deposit more than proposal token");
        TransferHelper.safeTransferFrom(config.platform_token, msg.sender,
                                        address(this), _deposit_amount);
        state.poll_count += 1;
        state.total_deposit += _deposit_amount;

        uint256 poll_id = state.poll_count;

        Poll memory poll;
        poll.id = poll_id;
        poll.creator = msg.sender;
        poll.status = PollStatus.InProgress;
        poll.yes_votes = 0;
        poll.no_votes = 0;
        poll.end_height = block.number + config.voting_period;
        poll.title = _title;
        poll.description = _description;
        poll.link = _link;
        poll.target = _target;
        poll.selector = _selector;
        poll.data = _data;
        poll.deposit_amount = _deposit_amount;
        poll.total_balance_at_end_poll = 0;

        _polls_itmap_insert_or_update( poll_id, poll);
        emit create_poll(msg.sender, poll_id, block.number +
                         config.voting_period);
    }

    function StakeVotingTokens(uint256 _amount) public {
        require(_amount > 0, "Gov StakeVotingTokens: Insufficient funds send");
        if (!_banks_itmap_contains(msg.sender)) {
            TokenManager memory value;
            _banks_itmap_insert_or_update(msg.sender, value);
        }
        TokenManager storage token_manager = _banks_itmap_value_get(msg.sender);
        WrappedToken wrappedToken = WrappedToken(config.platform_token);
        uint256 total_balance = wrappedToken.balanceOf(address(this)) -
            state.total_deposit;
        TransferHelper.safeTransferFrom(config.platform_token, msg.sender,
                                        address(this), _amount);
        uint256 share = 0;
        if (total_balance == 0 || state.total_share == 0) {
            share = _amount;
        } else {
            share = _amount * state.total_share / total_balance;
        }

        token_manager.share += share;
        state.total_share += share;
        emit stake_voting_token(msg.sender, _amount);
    }

    function WithdrawVotingTokens(uint256 _amount) public {
        require(_banks_itmap_contains(msg.sender), "Gov WithdrawVotingTokens: Nothing staked");
        TokenManager storage token_manager = _banks_itmap_value_get(msg.sender);
        WrappedToken wrappedToken = WrappedToken(config.platform_token);
        uint256 total_balance = wrappedToken.balanceOf(address(this)) - state.total_deposit;
        uint256 locked_balance = _locked_balance(token_manager);
        uint256 locked_share = locked_balance * state.total_share / total_balance;
        uint256 withdraw_share = _amount * state.total_share / total_balance;


        require(locked_share + withdraw_share <= token_manager.share,
            "Gov WithdrawVotingTokens: User is trying to withdraw too many tokens.");
        token_manager.share -= withdraw_share;
        state.total_share -= withdraw_share;
        TransferHelper.safeTransfer(config.platform_token, msg.sender, _amount);
        emit withdraw_voting_tokens(msg.sender, _amount);
    }

    function CastVote(uint256 _poll_id, VoteOption vote, uint256 _amount) public {
        require(_poll_id > 0 && state.poll_count >= _poll_id, "Gov CastVote: Poll does not exist");
        Poll storage a_poll = _polls_itmap_value_get(_poll_id);
        require(a_poll.status == PollStatus.InProgress && block.number <
            a_poll.end_height, "Gov CastVote: Poll is not in progress");
        require(_banks_itmap_contains(msg.sender), "Gov CastVote: User does not have enough staked tokens.");
        TokenManager storage token_manager = _banks_itmap_value_get(msg.sender);
        require(token_manager.locked_balance[_poll_id].balance == 0, "Gov CastVote: User has already voted.");
        _update_token_manager(token_manager);
        require(token_manager.participated_polls.length < MAX_USER_VOTER_NUMBER,
               "Gov CastVote: User voted exceed MAX_USER_VOTER_NUMBER");
        WrappedToken wrappedToken = WrappedToken(config.platform_token);
        uint256 total_balance = wrappedToken.balanceOf(address(this)) - state.total_deposit;
        require(token_manager.share * total_balance / state.total_share >= _amount,
                "Gov CastVote: User does not have enough staked tokens.");
        if (vote == VoteOption.Yes) {
            a_poll.yes_votes += _amount;
        } else {
            a_poll.no_votes += _amount;
        }

        VoterInfo memory vote_info;
        vote_info.vote = vote;
        vote_info.balance = _amount;
        vote_info.user = msg.sender;

        token_manager.participated_polls.push(_poll_id);
        token_manager.locked_balance[_poll_id] = vote_info;
        uint256 max_poll_id = token_manager.participated_polls[token_manager.maxIdx];
        if (token_manager.locked_balance[max_poll_id].balance < _amount) {
            token_manager.maxIdx = token_manager.participated_polls.length - 1;
        }
        if (!_voters_itmap_contains(_poll_id)) {
            VoterManager memory value;
            value.user = new address[](1);
            value.vote = new VoteOption[](1);
            value.balance = new uint256[](1);
            value.user[0] = msg.sender;
            value.vote[0] = vote;
            value.balance[0] = _amount;
            _voters_itmap_insert_or_update(_poll_id, value);
        } else {
            VoterManager storage voter_manager = _voters_itmap_value_get(_poll_id);
            voter_manager.user.push(msg.sender);
            voter_manager.vote.push(vote);
            voter_manager.balance.push(_amount);
        }
        emit cast_vote(msg.sender, _poll_id, vote, _amount);
    }

    function EndPoll(uint256 _poll_id) public {
        Poll storage _poll = polls.data[_poll_id].value;
        require (_poll.status == PollStatus.InProgress,"Gov EndPoll: Poll is not in progress");
        require (_poll.end_height <= block.number,"Gov EndPoll: Voting period has not expired");

        WrappedToken token = WrappedToken(config.platform_token);
        uint256 balance = token.balanceOf(address(this));
        uint256 tallied_weight = _poll.yes_votes.add(_poll.no_votes);
        uint256 staked_weight = balance.sub(state.total_deposit);
        uint256 quorum = tallied_weight.mul(10**PERCENT_PRECISION).div(staked_weight);
        bool passed = false;
        string memory rejected_reason;
        _poll.status = PollStatus.Rejected;
        if (tallied_weight == 0 || quorum < config.quorum){
            rejected_reason = "Quorum not reached";
        }else{
            uint256 passratio = _poll.yes_votes.mul(10**PERCENT_PRECISION).div(tallied_weight);
            if (passratio > config.threshold){
                _poll.status = PollStatus.Passed;
                passed = true;
            }else{
                rejected_reason = "Threshold not reached";
            }
            if (_poll.deposit_amount > 0){
                TransferHelper.safeTransfer(config.platform_token,_poll.creator,_poll.deposit_amount);
                emit to_binary(_poll.creator,_poll.deposit_amount);
            }
        }
        state.total_deposit = state.total_deposit.sub(_poll.deposit_amount);
        _poll.total_balance_at_end_poll = staked_weight;

        _voters_itmap_remove(_poll_id);
        emit end_poll_log(_poll_id,rejected_reason,passed);
    }

    function ExcutePoll(uint256 _poll_id) public {
        Poll storage _poll = polls.data[_poll_id].value;
        require(_poll.status == PollStatus.Passed,"Gov ExcutePoll:ExcutePoll Poll is not in passed status");
        require(_poll.end_height.add(config.effective_delay) <= block.number,"Gov ExcutePoll: ExcutePoll Effective delay has not expired");
        _passCommand(_poll.target,_poll.selector,_poll.data);
        _poll.status = PollStatus.Executed;
        emit execute_log(_poll_id);
    }

    function ExpirePoll(uint256 _poll_id) public {
        Poll storage _poll = polls.data[_poll_id].value;
        require(_poll.status == PollStatus.Passed,"Gov ExpirePoll: Poll is not in passed status");
        require((_poll.target != address(0) && bytes(_poll.selector).length > 0),"Gov ExpirePoll: Cannot make a text proposal to expired state");
        require(_poll.end_height.add(config.expiration_period) <= block.number,"Gov ExpirePoll: Expire height has not been reached");
        _poll.status = PollStatus.Expired;
        emit expire_log(_poll_id);
    }
        function _locked_balance(TokenManager storage _token_manager) internal returns (uint256) {
        if (_token_manager.participated_polls.length == 0) {
            return 0;
        }
        uint256 max_poll_id = _token_manager.participated_polls[_token_manager.maxIdx];
        if (polls.data[max_poll_id].value.status == PollStatus.InProgress) {
            return _token_manager.locked_balance[max_poll_id].balance;
        }
        _update_token_manager(_token_manager);
        if (_token_manager.participated_polls.length == 0) {
            return 0;
        }
        max_poll_id = _token_manager.participated_polls[_token_manager.maxIdx];
        return _token_manager.locked_balance[max_poll_id].balance;
    }

        // 从此开始

    function QueryConfig() external view returns (Config memory) {
        return config;
    }

    function QueryState() external view returns (State memory) {
        return state;
    }

    function QueryStaker(address user) external view returns (StakerResponse memory staker) {
        if (!_banks_itmap_contains(user) || state.total_share == 0) {
            return staker;
        }
        WrappedToken wrappedToken = WrappedToken(config.platform_token);
        uint256 total_balance = wrappedToken.balanceOf(address(this)) - state.total_deposit;
        TokenManager storage token_manager = _banks_itmap_value_get(user);
        staker.share = token_manager.share;
	staker.maxIdx = token_manager.maxIdx;
	staker.balance = staker.share * total_balance / state.total_share;
        staker.locked_balance = new voteResp[](token_manager.participated_polls.length);
        for (uint256 i = 0; i < token_manager.participated_polls.length; i++) {
            uint256 poll_id = token_manager.participated_polls[i];
            staker.locked_balance[i].value = token_manager.locked_balance[poll_id];
            staker.locked_balance[i].poll_id = poll_id;
        }
        return staker;
    }

    function QueryPoll(uint256 _poll_id) external view returns (Poll memory poll) {
        if (_poll_id == 0 || state.poll_count < _poll_id) {
            return poll;
        }
        poll = _polls_itmap_value_get(_poll_id);
        return poll;
    }

    function QueryPolls(PollStatus fileter, uint256 _start_after, uint256 _limit, bool _isAsc)
        external view returns (Poll[] memory poll, uint256 len) {
        if (_limit == 0) {
            return (poll , len);
        }
        uint256 limit = _limit;
        if (limit > MAX_LIMIT) {
            limit = MAX_LIMIT;
        }
        poll = new Poll[](limit);
        len = 0;
        uint256 keyindex = 1;
        if (_start_after != 0) {
            if (!_polls_itmap_contains(_start_after) ) {
                return (poll , len);
            }
            keyindex = _polls_itmap_keyindex(_start_after);
        }
        if (_isAsc) {
            if (_start_after != 0) {
                keyindex++;
            }
            if (keyindex > state.poll_count) {
                return (poll, len);
            }
            if (_polls_itmap_delete(keyindex)) {
                keyindex = _polls_itmap_iterate_next(keyindex);
            }
            for ( uint256 i = keyindex; _polls_itmap_iterate_valid(i) && (len < limit);
                i = _polls_itmap_iterate_next(i)) {
                Poll memory tmp = _polls_itmap_iterate_get(i);
                if (fileter != PollStatus.All && tmp.status != fileter) {
                    continue;
                }
                poll[len++] = tmp;
            }
        } else {
            if (_start_after == 0) {
                keyindex = _polls_itmap_keyindex(state.poll_count);
            } else {
                if (keyindex <= 1) {
                    return (poll, len);
                }
                keyindex--;
            }
            if (_polls_itmap_delete(keyindex)) {
                keyindex = _polls_itmap_iterate_prev(keyindex);
            }
            for (uint256 i = keyindex; _polls_itmap_iterate_valid(i) && (len < limit);
                i = _polls_itmap_iterate_prev(i)) {
                Poll memory tmp = _polls_itmap_iterate_get(i);
                if (fileter != PollStatus.All && tmp.status != fileter) {
                    continue;
                }
                poll[len++] = tmp;
            }
        }
    }

    function QueryVoters(uint256 poll_id, uint256 _start, uint256 _limit, bool _isAsc)
        external view returns  (uint256 len) {
 
    }
        //至此结束
    function _update_token_manager(TokenManager storage _token_manager) internal returns (uint256) {
        _token_manager.maxIdx = 0;
        uint256 max_balance = 0;
        uint256 remove_poll_cnt = 0;
        uint256 length = _token_manager.participated_polls.length;
        for (uint256 i = 0; i < length - remove_poll_cnt; i++) {
            uint256 poll_id = _token_manager.participated_polls[i];
            while (polls.data[poll_id].value.status != PollStatus.InProgress) {
                remove_poll_cnt++;
                if (length - remove_poll_cnt <= i) {
                    break;
                }
                uint256 tmp = _token_manager.participated_polls[i];
                _token_manager.participated_polls[i] =
                    _token_manager.participated_polls[length - remove_poll_cnt];
                _token_manager.participated_polls[length - remove_poll_cnt] = tmp;

                poll_id = _token_manager.participated_polls[i];
            }
            uint256 balance = _token_manager.locked_balance[poll_id].balance;
            if (max_balance < balance) {
                max_balance = balance;
                _token_manager.maxIdx = i;
            }
        }
        for (uint256 i = 0; i < remove_poll_cnt; i++) {
            uint256 len = _token_manager.participated_polls.length;
            uint256 poll_id = _token_manager.participated_polls[len-1];
            _token_manager.participated_polls.pop();
            delete _token_manager.locked_balance[poll_id];
        }
    }

    function _passCommand(address _target, string memory _selector, bytes memory _data) internal {
        bytes memory callData;
        if (bytes(_selector).length == 0) {
            callData = _data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(_selector))), _data);
        }
        (bool success, ) = _target.call(callData);
        require(success, "Gov Err: PassCommand transaction execution reverted.");
    }

    function _polls_itmap_insert_or_update(uint256 key, Poll memory value) internal returns (bool) {
        uint256 keyIndex = polls.data[key].keyIndex;
        polls.data[key].value = value;
        if (keyIndex > 0) return false;

        polls.keys.push(PollsKeyFlag({key: key, deleted: false}));
        polls.data[key].keyIndex = polls.keys.length;
        polls.size++;
        return true;
    }

    function _polls_itmap_remove(uint256 key) internal returns (bool) {
        uint256 keyIndex = polls.data[key].keyIndex;
        require(keyIndex > 0, "_polls_itmap_remove internal error");
        if (polls.keys[keyIndex - 1].deleted) return false;
        delete polls.data[key].value;
        polls.keys[keyIndex - 1].deleted = true;
        polls.size--;
        return true;
    }

    function _polls_itmap_contains(uint256 key) internal view returns (bool) {
        return polls.data[key].keyIndex > 0;
    }

    function _polls_itmap_keyindex(uint256 key) internal view returns (uint256) {
        return polls.data[key].keyIndex;
    }

    function _polls_itmap_delete(uint256 keyIndex) internal view returns (bool) {

        if (keyIndex == 0) {
            return true;
        }
        return polls.keys[keyIndex-1].deleted;
    }

    function _polls_itmap_iterate_valid(uint256 keyIndex) internal view returns (bool) {
        return keyIndex != 0 && keyIndex <= polls.keys.length;
    }

    function _polls_itmap_iterate_next(uint256 keyIndex) internal view returns (uint256) {
        keyIndex++;
        while (
            keyIndex < polls.keys.length && polls.keys[keyIndex-1].deleted
        ) keyIndex++;
        return keyIndex;
    }

    function _polls_itmap_iterate_prev(uint256 keyIndex) internal view returns (uint256) {
        if (keyIndex > polls.keys.length || keyIndex == 0) return polls.keys.length;

        keyIndex--;
        while (keyIndex > 0 && polls.keys[keyIndex-1].deleted) keyIndex--;
        return keyIndex;
    }

    function _polls_itmap_iterate_get(uint256 keyIndex) internal view returns
    (Poll storage value) {
        value = polls.data[polls.keys[keyIndex-1].key].value;
    }

    function _polls_itmap_value_get(uint256 key) internal view returns
    (Poll storage value) {
        uint256 keyIndex = _polls_itmap_keyindex(key);
        value = polls.data[polls.keys[keyIndex-1].key].value;
    }

    function _banks_itmap_insert_or_update(address key, TokenManager memory value) internal returns (bool) {
        uint256 keyIndex = banks.data[key].keyIndex;
        banks.data[key].value = value;
        if (keyIndex > 0) return false;

        banks.keys.push(UsersKeyFlag({key: key, deleted: false}));
        banks.data[key].keyIndex = banks.keys.length;
        banks.size++;
        return true;
    }

    function _banks_itmap_remove(address key) internal returns (bool) {
        uint256 keyIndex = banks.data[key].keyIndex;
        require(keyIndex > 0, "_banks_itmap_remove internal error");
        if (banks.keys[keyIndex - 1].deleted) return false;
        delete banks.data[key].value;
        banks.keys[keyIndex - 1].deleted = true;
        banks.size--;
        return true;
    }

    function _banks_itmap_contains(address key) internal view returns (bool) {
        return banks.data[key].keyIndex > 0;
    }

    function _banks_itmap_keyindex(address key) internal view returns (uint256) {
        return banks.data[key].keyIndex;
    }

    function _banks_itmap_delete(uint256 keyIndex) internal view returns (bool) {

        if (keyIndex == 0) {
            return true;
        }
        return banks.keys[keyIndex-1].deleted;
    }

    function _banks_itmap_iterate_valid(uint256 keyIndex) internal view returns (bool) {
        return keyIndex != 0 && keyIndex <= banks.keys.length;
    }

    function _banks_itmap_iterate_next(uint256 keyIndex) internal view returns (uint256) {
        keyIndex++;
        while (
            keyIndex < banks.keys.length && banks.keys[keyIndex-1].deleted
        ) keyIndex++;
        return keyIndex;
    }

    function _banks_itmap_iterate_prev(uint256 keyIndex) internal view returns (uint256) {
        if (keyIndex > banks.keys.length || keyIndex == 0) return banks.keys.length;

        keyIndex--;
        while (keyIndex > 0 && banks.keys[keyIndex-1].deleted) keyIndex--;
        return keyIndex;
    }

    function _banks_itmap_iterate_get(uint256 keyIndex) internal view returns
    (TokenManager storage value) {
        value = banks.data[banks.keys[keyIndex-1].key].value;
    }

    function _banks_itmap_value_get(address key) internal view returns
    (TokenManager storage value) {
        uint256 keyIndex = _banks_itmap_keyindex(key);
        value = banks.data[banks.keys[keyIndex-1].key].value;
    }

    function _voters_itmap_insert_or_update(uint256 key, VoterManager memory value) internal returns (bool) {
        uint256 keyIndex = voters.data[key].keyIndex;
        voters.data[key].value = value;
        if (keyIndex > 0) return false;

        voters.keys.push(VotersKeyFlag({key: key, deleted: false}));
        voters.data[key].keyIndex = voters.keys.length;
        voters.size++;
        return true;
    }

    function _voters_itmap_remove(uint256 key) internal returns (bool) {
        uint256 keyIndex = voters.data[key].keyIndex;
        if (keyIndex > 0) {
            if (voters.keys[keyIndex - 1].deleted) return false;
            delete voters.data[key].value;
            voters.keys[keyIndex - 1].deleted = true;
            voters.size--;
        }
        return true;
    }

    function _voters_itmap_contains(uint256 key) internal view returns (bool) {
        return voters.data[key].keyIndex > 0;
    }

    function _voters_itmap_keyindex(uint256 key) internal view returns (uint256) {
        return voters.data[key].keyIndex;
    }

    function _voters_itmap_delete(uint256 keyIndex) internal view returns (bool) {

        if (keyIndex == 0) {
            return true;
        }
        return voters.keys[keyIndex-1].deleted;
    }

    function _voters_itmap_iterate_valid(uint256 keyIndex) internal view returns (bool) {
        return keyIndex != 0 && keyIndex <= voters.keys.length;
    }

    function _voters_itmap_iterate_next(uint256 keyIndex) internal view returns (uint256) {
        keyIndex++;
        while (
            keyIndex < voters.keys.length && voters.keys[keyIndex-1].deleted
        ) keyIndex++;
        return keyIndex;
    }

    function _voters_itmap_iterate_prev(uint256 keyIndex) internal view returns (uint256) {
        if (keyIndex > voters.keys.length || keyIndex == 0) return voters.keys.length;

        keyIndex--;
        while (keyIndex > 0 && voters.keys[keyIndex-1].deleted) keyIndex--;
        return keyIndex;
    }

    function _voters_itmap_iterate_get(uint256 keyIndex) internal view returns
    (VoterManager storage value) {
        value = voters.data[voters.keys[keyIndex-1].key].value;
    }

    function _voters_itmap_value_get(uint256 key) internal view returns
    (VoterManager storage value) {
        uint256 keyIndex = _voters_itmap_keyindex(key);
        value = voters.data[voters.keys[keyIndex-1].key].value;
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../token/WrappedToken.sol";
import "../TransferHelper.sol";
import "../nft/nft.sol";
import "../blindBox/BlindBox.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";


contract Lock {
    using SafeMath for uint256;

    uint256 private _status;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 public constant ONE_NFT_REWARD_AMOUNT = 1000 * (10**18);

    uint256 public constant MAX_NFT_REWARD = 20;

    uint256 lastRewardNFTId;
    Config public config;
    uint256 public currentIdx;
    mapping(uint256 => Reward) public rewardData;
    // user -> idx -> amount
    mapping(address => mapping(uint256 => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(uint256 => uint256)) public rewards;
    mapping(address => RewardBalance[]) public userRewards;

    mapping(address => Balances) public balances;
    mapping(address => LockedBalance[]) public userLocks;

    uint256 public totalRewardAmount;
    uint256 public totalCollateralAmount;
    uint256 public totalDistributeAmount;

    uint256 public totalWithdrawCollateralAmount;

    struct Config {
        WrappedToken platform_token;
        nft          nft_token;
        BlindBox     blind_box;
        uint256      periodDuration;
        uint256      rewardsDuration;
        uint256      lockDuration;
    }

    struct Reward {
        uint256 periodFinish;
        uint256 lockFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 collateralAmount;
        uint256 rewardAmount;
        uint256 modLeft;
    }

    struct Balances {
        uint256 total;
        // idx -> amount
        mapping(uint256 => uint256 ) stakeAmount;
    }

    struct LockedBalance {
        uint256 amount;
        uint256 idx;
    }

    struct RewardBalance {
        uint256 amount;
        uint256 idx;
    }

    struct LockedBalanceResp {
        uint256 amount;
        uint256 idx;
        bool lock;
    }

    event rewardToken(uint256 amount);
    event staked(address indexed user, uint256 amount);
    event withdrawn(address indexed user, uint256 amount);
    event rewardPaid(address indexed user, uint256 reward);

    modifier nonReentrant() {
        require(_status != _ENTERED, "Lock: nonReentrant reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(address _platform_token, uint256 _periodDuration, uint256
                _rewardsDuration, uint256 _lockDuration, address _nft_token,
                address payable _blind_box) public {
        require(_periodDuration > 0, "Lock: _periodDuration should greater then 0");
        require(_rewardsDuration >= _periodDuration, "Lock: _rewardsDuration should greater or equal then _periodDuration");
        require(_lockDuration >= _rewardsDuration, "Lock: _lockDuration should greater or equal then _rewardsDuration");
        config.platform_token = WrappedToken(_platform_token);
        config.periodDuration = _periodDuration;
        config.rewardsDuration = _rewardsDuration;
        config.lockDuration = _lockDuration;
        config.nft_token = nft(_nft_token);
        config.blind_box = BlindBox(_blind_box);
        currentIdx = GetPeriodInd();
        rewardData[currentIdx].lastUpdateTime = block.timestamp;
        rewardData[currentIdx].periodFinish = block.timestamp.div(config.periodDuration).mul(config.periodDuration).add(config.rewardsDuration);
        rewardData[currentIdx].lockFinish = block.timestamp.div(config.periodDuration).mul(config.periodDuration).add(config.lockDuration);
        lastRewardNFTId = 10000000;
    }

    function RewardToken(uint256 amount) external nonReentrant {
        updateReward(address(0), currentIdx);
        // uint256 amount = config.platform_token.allowance(msg.sender, address(this));
        require(amount > 0, "Lock: RewardToken wrong asset");
        TransferHelper.safeTransferFrom(address(config.platform_token), msg.sender, address(this), amount);

        Reward storage rewardRef = rewardData[currentIdx];
        rewardRef.rewardAmount = rewardRef.rewardAmount.add(amount);

        uint256 remaining = rewardRef.periodFinish.sub(block.timestamp);
        uint256 leftover = remaining.mul(rewardRef.rewardRate);
        totalRewardAmount = totalRewardAmount.add(amount);
        amount = amount.add(leftover).add(rewardRef.modLeft);
        rewardRef.rewardRate = amount.div(remaining);
        rewardRef.modLeft = amount.mod(remaining);
        emit rewardToken(amount);
    }

    function Stake(uint256 amount) external nonReentrant {
        updateReward(msg.sender, currentIdx);
        // uint256 amount = config.platform_token.allowance(msg.sender, address(this));
        require(amount > 0, "Lock: stake Cannot stake 0");

        Balances storage bal = balances[msg.sender];
        bal.total = bal.total.add(amount);
        bal.stakeAmount[currentIdx] = bal.stakeAmount[currentIdx].add(amount);

        LockedBalance[] storage locks = userLocks[msg.sender];
        uint256 len = locks.length;
        if (len > 0 && currentIdx == locks[len-1].idx) {
            locks[len-1].amount = locks[len-1].amount.add(amount);
        } else {
            locks.push(LockedBalance({amount: amount, idx: currentIdx}));
        }

        rewardData[currentIdx].collateralAmount = rewardData[currentIdx].collateralAmount.add(amount);
        totalCollateralAmount = totalCollateralAmount.add(amount);

        TransferHelper.safeTransferFrom(address(config.platform_token), msg.sender, address(this), amount);
        uint256 nftRewardCnt = amount / ONE_NFT_REWARD_AMOUNT;
        if (nftRewardCnt > 0) {
            if (nftRewardCnt > MAX_NFT_REWARD) {
                nftRewardCnt = MAX_NFT_REWARD;
            }
            uint256[] memory seriesIds = config.blind_box.QuerySeriesIds();
             for (uint256 i = 0; i < nftRewardCnt; i++) {
                uint256 randSeridId = uint256(keccak256(abi.encodePacked(block.difficulty,
                     block.coinbase, now, blockhash(block.number-1), i))) % seriesIds.length;

                config.nft_token.Draw(msg.sender, 1, 0, seriesIds[randSeridId],
                                      config.blind_box.QueryDraws(seriesIds[randSeridId]),config.blind_box.QueryLevels(seriesIds[randSeridId]));
             }
        }
        emit staked(msg.sender, amount);
    }

    function GetReward(uint256 _start, uint256 _end) public nonReentrant{
        require(_start < _end, "GetReward: arg1 must less than arg2");
        LockedBalance[] storage locks = userLocks[msg.sender];
        uint256 length = locks.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 idx = locks[i].idx;
            updateReward(msg.sender, idx);
        }

        RewardBalance[] storage userReward = userRewards[msg.sender];
        mapping(uint256 => uint256) storage bal = rewards[msg.sender];
        uint256 amount = 0;
        length = userReward.length;
        if (length == 0) {
            return;
        }
        uint256 i = 0;
        for (; i < length; i++) {
            uint256 idx = userReward[i].idx;
            amount = amount.add(userReward[i].amount);
            delete userReward[i];
            delete bal[idx];
        }
        if (i == length) {
            delete userRewards[msg.sender];
        }
        totalDistributeAmount = totalDistributeAmount.add(amount);
        TransferHelper.safeTransfer(address(config.platform_token), msg.sender, amount);
        emit rewardPaid(msg.sender, amount);
    }

    function WithdrawExpiredLocks(uint256 _start, uint256 _end) external {
        GetReward(_start, _end);
        LockedBalance[] storage locks = userLocks[msg.sender];
        Balances storage bal = balances[msg.sender];
        uint256 amount = 0;
        uint256 length = locks.length;
        if (locks.length < _end) {
            _end = locks.length;
        }
        if (length == 0) {
            return;
        }
        // require(length > 0, "Lock: WithdrawExpiredLocks is 0");
        uint256 idx = locks[length-1].idx;
        uint256 unlockTime = rewardData[idx].lockFinish;
        if (_start == 0 && length == locks.length && unlockTime <= block.timestamp) {
            amount = bal.total;
            bal.total = 0;
            for (uint256 i = 0; i < length; i++) {
                idx = locks[i].idx;
                delete bal.stakeAmount[idx];
            }
            delete userLocks[msg.sender];
        } else {
            for (uint256 i = _start; i < _end; i++) {
                idx = locks[i].idx;
                unlockTime = rewardData[idx].lockFinish;
                if (unlockTime > block.timestamp) break;
                amount = amount.add(locks[i].amount);
                bal.total = bal.total.sub(locks[i].amount);
                delete locks[i];
                delete bal.stakeAmount[idx];
            }
        }
        if (amount == 0) {
            return;
        }
        // require(amount > 0, "Lock: WithdrawExpiredLocks is 0");
        totalWithdrawCollateralAmount = totalWithdrawCollateralAmount.add(amount);
        TransferHelper.safeTransfer(address(config.platform_token), msg.sender, amount);
    }

    function QueryConfig() external view returns (Config memory) {
        return config;
    }

    function GetPeriodInd() public view returns (uint256) {
        return block.timestamp.div(config.periodDuration);
    }

    function ClaimableRewards(address user) external view returns (uint256 total, RewardBalance[] memory claRewards) {
        LockedBalance[] storage locks = userLocks[user];
        claRewards = new RewardBalance[](locks.length);
        uint256 length = locks.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 idx = locks[i].idx;
            uint256 amount = _earned(user, idx);
            total = total.add(amount);
            claRewards[i].amount = amount;
            claRewards[i].idx = idx;
        }
    }

    function GetStakeAmounts(address user) external view returns (uint256 total, uint256 unlockable,
        uint256 locked, LockedBalanceResp[] memory lockData) {
        LockedBalance[] storage locks = userLocks[user];
        lockData = new LockedBalanceResp[](locks.length);
        for (uint256 i = 0; i < locks.length; i++) {
            uint256 idx = locks[i].idx;
            uint256 unlockTime = rewardData[idx].lockFinish;
            if (unlockTime > block.timestamp) {
                locked = locked.add(locks[i].amount);
                lockData[i].lock = true;
            } else {
                unlockable = unlockable.add(locks[i].amount);
                lockData[i].lock = false;
            }
            lockData[i].amount = locks[i].amount;
            lockData[i].idx = locks[i].idx;
        }
        return (balances[user].total, unlockable, locked, lockData);
    }

    function TotalStake() view external returns (uint256 total) {
        uint256 periodFinish = block.timestamp.div(config.periodDuration).mul(config.periodDuration);
        uint256 idx = GetPeriodInd();

        Reward storage data = rewardData[idx];
        total = total.add(data.collateralAmount);
        while (data.periodFinish > periodFinish && idx > 0) {
            data = rewardData[--idx];
            total = total.add(data.collateralAmount);
        }
    }

    function TotalAllStake() view external returns (uint256) {
        return totalCollateralAmount - totalWithdrawCollateralAmount;
    }

    function LastTimeRewardApplicable(uint256 idx) public view returns (uint256) {
        return Math.min(block.timestamp, rewardData[idx].periodFinish);
    }

    function RewardPerToken(uint256 idx) external view returns (uint256) {
        return _rewardPerToken(idx);
    }

    function updateReward(address account, uint256 idx) internal {
        rewardData[idx].rewardPerTokenStored = _rewardPerToken(idx);
        rewardData[idx].lastUpdateTime = LastTimeRewardApplicable(idx);
        if (account != address(0)) {
            rewards[account][idx] = _earned(account, idx);
            RewardBalance[] storage rewardBalance = userRewards[account];
            uint256 len = rewardBalance.length;
            if (len > 0 && rewardBalance[len-1].idx == idx) {
                rewardBalance[len-1].amount = rewards[account][idx];
            } else {
                rewardBalance.push(RewardBalance({amount: rewards[account][idx], idx: idx}));
            }
            userRewardPerTokenPaid[account][idx] = rewardData[idx].rewardPerTokenStored;
        }

        idx = GetPeriodInd();
        if (idx != currentIdx) {
            currentIdx = idx;
            delete rewardData[idx];
            rewardData[idx].lastUpdateTime = block.timestamp;
            rewardData[idx].periodFinish = block.timestamp.div(config.periodDuration).mul(config.periodDuration).add(config.rewardsDuration);
            rewardData[idx].lockFinish = block.timestamp.div(config.periodDuration).mul(config.periodDuration).add(config.lockDuration);
        }
    }

    function _earned(
        address _user,
        uint256 idx
    ) internal view returns (uint256) {
        Balances storage bal = balances[_user];
        return bal.stakeAmount[idx].mul(
            _rewardPerToken(idx).sub(userRewardPerTokenPaid[_user][idx])
        ).div(1e18).add(rewards[_user][idx]);
    }

    function _rewardPerToken(uint256 idx) internal view returns (uint256) {
        uint256 supply = rewardData[idx].collateralAmount;
        if (supply == 0) {
            return rewardData[idx].rewardPerTokenStored;
        }
        return rewardData[idx].rewardPerTokenStored.add(
                LastTimeRewardApplicable(idx).sub(
                    rewardData[idx].lastUpdateTime).mul(
                        rewardData[idx].rewardRate).mul(1e18).div(supply)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract nft is ERC721 {
     struct Config {
        address  owner;
        address  lockContract;
        address  blindBox;
        address  flip;
    }

    Config public config;

    mapping (uint256 => uint256) private _tokenSerialNumber;
    mapping (uint256 => string) private _tokenTypeNumber;
    mapping (uint256 => string) private _tokenGrade;   
    mapping (uint256 => uint256) private _gradeSymbol;       
    mapping (uint256 => uint256) private _tokenGradeId;     

    mapping (address => uint256[]) private _addrAllTokenId; 
    mapping (uint256 => uint256) private _tokenToIndex;    

    string public lastresult;
    uint public lastblocknumberused; 
    bytes32 public lastblockhashused;
    uint256 max_page;
    uint256 private lastTokenId; 
    
    event DrawCard(address user, uint256 tokenId, uint256 tokenSerialNumber, string tokenTypeNumber);
    event DrawCardForD(address user, uint256 tokenId, uint256 tokenSerialNumber, string tokenTypeNumber);
    constructor (
        string memory name_, 
        string memory symbol_
        ) public ERC721(name_, symbol_) {
        config.owner = msg.sender;
        config.lockContract = address(0);
        config.blindBox = address(0);
        config.flip = address(0);
        max_page = 50;
        lastTokenId = 0;
    }

    modifier authentication(){
        require(
            msg.sender == config.flip || msg.sender ==config.lockContract || msg.sender ==config.blindBox,
            "Nft Err: Unauthoruzed");
        _;
    }

    event initLog(address addrOne, address addrTwo, address addrThree);
    function init(address blindBox,address flip, address lock_contract) public  {
        require(msg.sender == config.owner, "Nft Err: Unauthoruzed");
        require(config.blindBox == address(0) &&
                config.flip == address(0) &&
                config.lockContract == address(0),
                "Nft Err:Can not be re-initialized");
        config.flip = flip;
        config.lockContract = lock_contract;
        config.blindBox = blindBox;
        emit initLog(blindBox, flip, lock_contract);
    }

    function queryConfig() public view returns(address  blindBox, address flip, address lockContract){
        blindBox = config.blindBox;
        flip = config.flip;
        lockContract = config.lockContract;
    }

    function Draw(address to, uint256 number, uint256 IsDCard, uint256 _seriesId, uint256[] memory _drawPr,
    uint256[] memory _gradeNumber)  authentication public
    {
        uint256 _pecision = _drawPr[0] + _drawPr[1] +_drawPr[2] +_drawPr[3];
        for (uint256 i = 0; i < number; i++) {
            uint256 tokenids = lastTokenId;
            _safeMint(to, lastTokenId);

            if (IsDCard == 0){
                drawCardForD(to, tokenids, _seriesId, _gradeNumber);
            }else {
                drawCard(to,tokenids,_seriesId,_pecision,_drawPr,_gradeNumber);
            }

        }  
    }

    function getAddrTokenId(address _user, uint index) public view returns(uint256)
    {
      return _addrAllTokenId[_user][index];
    }

    function getAddrIndex(uint256 _tokenId) public view returns(uint256)
    {
      return _tokenToIndex[_tokenId];
    }

    function getAddrAllTokenIds(address _user, uint256 _pageSize, uint256 _page) public view 
    returns(uint256[] memory result) 
    {   
        uint256 total =  _addrAllTokenId[_user].length;
        require( _pageSize * (_page - 1)  < total, "Nft Err: No more NFT");
        
        uint256 pageSize = _pageSize;
        uint256 page = _page;
        if (pageSize > max_page) {
            pageSize = max_page;
        }

        uint256 start_index = (page - 1) * pageSize;
        uint256 end_index;

        if ( total-start_index <  pageSize)
        {
            end_index = total; 
        }
        else           
        {
            end_index = start_index + pageSize; 
        }

        result = new uint256[](pageSize);

        uint256 j = 0 ;
        for (uint256 i = start_index; i < end_index ; i++ ){ 
            result[j] = getAddrTokenId(_user,i);
            j++;
        }
        return result;
    }

    function _mint(address to, uint256 tokenId) internal virtual override{
        super._mint(to , tokenId);
        _addrAllTokenId[to].push(tokenId);
        _tokenToIndex[tokenId] = _addrAllTokenId[to].length - 1;
        lastTokenId ++;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        super._transfer(from, to , tokenId);

        uint256 len = _addrAllTokenId[from].length; 
        uint256 tokenId_index = _tokenToIndex[tokenId]; 
        uint256 last_tokeniId = _addrAllTokenId[from][len-1]; 

        _addrAllTokenId[from][tokenId_index] = last_tokeniId; 
        _tokenToIndex[last_tokeniId] = tokenId_index;         

        _addrAllTokenId[from].pop(); 
        uint256 tolen = _addrAllTokenId[to].length;
        _addrAllTokenId[to].push(tokenId);
        _tokenToIndex[tokenId] = tolen;  
    }

    function burn(address user, uint256 tokenId) public { 
        require(user == ownerOf(tokenId), 'Nft Err: tokenId no belong to user');

        delete _tokenSerialNumber[tokenId];
        delete _tokenGrade[tokenId];
        delete _tokenGradeId[tokenId];
        delete _tokenTypeNumber[tokenId];
        delete _gradeSymbol[tokenId];
        
        uint256 len = _addrAllTokenId[user].length; 
        uint256 tokenId_index = _tokenToIndex[tokenId]; 
        uint256 last_tokeniId = _addrAllTokenId[user][len-1];

        _addrAllTokenId[user][tokenId_index] = last_tokeniId; 
        _tokenToIndex[last_tokeniId] = tokenId_index;         

        _addrAllTokenId[user].pop(); 
        delete  _tokenToIndex[tokenId];  
    
        _burn(tokenId);
    }
    
    function sha(uint128 wager) view private returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.coinbase, now, lastblockhashused, wager)));
    }

    function drawCard(address to, uint256 tokenId, uint256 _seriesId, uint256 _pecision,
    uint256[] memory _drawPr,uint256[] memory _gradeNumber) public returns(uint){
        uint128 wager = uint128(tokenId);           
        lastblocknumberused = block.number - 1 ;
        lastblockhashused = blockhash(lastblocknumberused);
        uint128 lastblockhashused_uint = uint128(uint(lastblockhashused)) + wager;
        uint256 hashymchasherton = sha(lastblockhashused_uint);

        uint256 rand = hashymchasherton % _pecision;

        if( rand <= _drawPr[0])
            {
                addAttribute(tokenId, _seriesId, "S", 1, _gradeNumber[0], hashymchasherton);
            }else if ( rand <= _drawPr[0] + _drawPr[1])
            {   
                addAttribute(tokenId, _seriesId, "A", 2, _gradeNumber[1], hashymchasherton);
            }else if ( rand <= _drawPr[0] +_drawPr[1] + _drawPr[2])
            {   
                addAttribute(tokenId, _seriesId, "B", 3, _gradeNumber[2], hashymchasherton);
            }else {
                addAttribute(tokenId, _seriesId, "C", 4, _gradeNumber[3], hashymchasherton);
            }
            emit DrawCard(to, tokenId, _tokenSerialNumber[tokenId], _tokenTypeNumber[tokenId]);     
    }

    function addAttribute(uint256 tokenId,uint256 seriesId, string memory tokenGrade, uint256 gradeSymbol,
    uint256 gradeNumber,uint256 hashymchasherton) private
    {
                _tokenSerialNumber[tokenId] = seriesId;
                _tokenGrade[tokenId] = tokenGrade;
                _gradeSymbol[tokenId] = gradeSymbol;
                
                if (gradeNumber == 1){
                    _tokenGradeId[tokenId] = 1;
                    _tokenTypeNumber[tokenId] = strConcat(tokenGrade, "1");
                }else {
                    uint256 randId = hashymchasherton % gradeNumber + 1;
                    _tokenGradeId[tokenId] = randId;
                    _tokenTypeNumber[tokenId] = strConcat(tokenGrade, toString(randId));
                }
    }

    function drawCardForD(address to, uint256 tokenId, uint256 _seriesId,uint256[] memory _gradeNumber) public {
        uint128 wager = uint128(tokenId);           
        lastblocknumberused = block.number - 1 ;
        lastblockhashused = blockhash(lastblocknumberused);
        uint128 lastblockhashused_uint = uint128(uint(lastblockhashused)) + wager;
        uint256 hashymchasherton = sha(lastblockhashused_uint);

        addAttribute(tokenId, _seriesId, "D", 5, _gradeNumber[4], hashymchasherton);
        emit DrawCardForD(to, tokenId, _tokenSerialNumber[tokenId],_tokenTypeNumber[tokenId]);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint j = 0; j < _bb.length; j++) bret[k++] = _bb[j];
        return string(ret);
    }

    function getNftInfo(uint256 tokenId) public view returns(uint256 tSerialNumber,
      string memory tTypeNumber, string memory tGrade, uint256  tGradeId){
        tSerialNumber = _tokenSerialNumber[tokenId];
        tTypeNumber = _tokenTypeNumber[tokenId];
        tGrade = _tokenGrade[tokenId];
        tGradeId = _tokenGradeId[tokenId]; 
    }
    
    function getOwnerAddr() public view returns(address){
        return config.owner;
    }

    function exists(uint256 tokenId) public view returns(bool) {
         return _exists(tokenId);
    }

    event gradeComposelog(string res, uint256 tokenId, uint256 tokenSerialNumber, string tokenTypeNumber);

    function gradeCompose(address user, uint256 seriesId,uint256[] memory _composePrs, uint256[] memory gradeNumbers,
    uint256 _grade,uint256[] memory tokenIds) authentication public 
    {   
        address _user = user;
        uint256 _pecision = 100000;
        uint256 _seriesId = seriesId; 
        uint256 grade = _grade;
        uint256[] memory _gradeNumbers = gradeNumbers;

        require(tokenIds.length == 5, 'Nft Err: []tokenIds quantity not five');

        require(
                  checkSeriesId(_seriesId,_tokenSerialNumber[tokenIds[0]], _tokenSerialNumber[tokenIds[1]], 
                  _tokenSerialNumber[tokenIds[2]], _tokenSerialNumber[tokenIds[3]], _tokenSerialNumber[tokenIds[4]]),
                  'Nft Err: Not all the five nft belonging to the same series'
          );

        require(
                  checkNftOwner(_user, tokenIds[0], tokenIds[1], tokenIds[2], tokenIds[3], tokenIds[4]),
                  'Nft Err: Not all the five nft belong to this address'
          );

        require(  
                  checkNftGrade(grade,_gradeSymbol[tokenIds[0]], _gradeSymbol[tokenIds[1]], _gradeSymbol[tokenIds[2]],
                   _gradeSymbol[tokenIds[3]], _gradeSymbol[tokenIds[4]]),
                  'Nft Err: The grades of the five nft are different'
        );
        
        burn(_user,tokenIds[0]);
        burn(_user,tokenIds[1]);
        burn(_user,tokenIds[2]);
        burn(_user,tokenIds[3]);
        burn(_user,tokenIds[4]);

        uint128 wager = uint128(1);             
        lastblocknumberused = block.number - 1 ;
        lastblockhashused = blockhash(lastblocknumberused);
        uint128 lastblockhashused_uint = uint128(uint(lastblockhashused)) + wager;
        uint256 hashymchasherton = sha(lastblockhashused_uint);
        uint256 rand = hashymchasherton % _pecision;
        
        uint256 ltId = lastTokenId;
        _safeMint(_user, lastTokenId);

        string memory res;
        if ( rand < _composePrs[grade-2])
        {
            res = "win";
            if( grade == 2)
            {   
                addAttribute(ltId, _seriesId, "S", 1, _gradeNumbers[0], hashymchasherton);
            }
            else if ( grade == 3 )
            {   
                addAttribute(ltId, _seriesId, "A", 2, _gradeNumbers[1], hashymchasherton);
            }
            else if ( grade == 4 )
            {   
                addAttribute(ltId, _seriesId, "B", 3, _gradeNumbers[2], hashymchasherton);
            }
            else 
            {
                addAttribute(ltId, _seriesId, "C", 4, _gradeNumbers[3], hashymchasherton);
            }
        }
        else
        {
            res = "loss";
            if( grade == 2)
            {       
                addAttribute(ltId, _seriesId, "A", 2, _gradeNumbers[1], hashymchasherton);
            }
            else if ( grade == 3 )
            {   
                addAttribute(ltId, _seriesId, "B", 3, _gradeNumbers[2], hashymchasherton);
            }
            else if ( grade == 4 )
            {
                addAttribute(ltId, _seriesId, "C", 4, _gradeNumbers[3], hashymchasherton);
            }
            else
            {
                addAttribute(ltId, _seriesId, "D", 5, _gradeNumbers[4], hashymchasherton);
            }
        }
        emit gradeComposelog(res, ltId, _tokenSerialNumber[ltId], _tokenTypeNumber[ltId]);  
    }

    function checkSeriesId(uint256 _seriesId,uint256 _id1, uint256 _id2, uint256 _id3, uint256 _id4,uint256 _id5) public pure returns(bool)
    {
        if (_id1 == _seriesId &&  _id2 == _seriesId && _id3 == _seriesId && _id4 == _seriesId && _id5 == _seriesId)
            {
            return true;
            }else{
            return false;
            }
    }

    function checkNftOwner(address user,uint256 id_1, uint256 id_2, uint256 id_3, 
    uint256 id_4,uint256 id_5) public view returns(bool)
    {
        if (ownerOf(id_1) == user && ownerOf(id_2) == user && ownerOf(id_3) == user && ownerOf(id_4) == user && ownerOf(id_5) == user)
        {
            return true;
        }else{
            return false;
        }
    }

    function checkNftGrade(uint256 _grade, uint256 _id1, uint256 _id2, 
    uint256 _id3, uint256 _id4,uint256 _id5) public pure returns(bool)
    {   
        if (_id1 == _grade &&  _id2 == _grade && _id3 == _grade && _id4 == _grade && _id5 == _grade)
        {
          return true;
        }else{
          return false;
        }
    }

    event cashCheckByTokenIdLog(uint256 _seriesId);
    function cashCheckByTokenID(address _user,uint256 _seriesId,uint256[] memory _gradeNumbers, 
    uint256[] memory _tokenIds) authentication  public 
    {   
        uint256 cardNumber = _gradeNumbers[0] +_gradeNumbers[1] +_gradeNumbers[2] +_gradeNumbers[3] +_gradeNumbers[4];
        require(cardNumber == _tokenIds.length, 'Nft Err: Insufficient number of NFTs');

        address  user = _user;
        uint128 S_res = 0;
        uint128 A_res = 0;
        uint128 B_res = 0;
        uint128 C_res = 0;
        uint128 D_res = 0;

        uint128 start;
        for (uint256 i = 0; i < _tokenIds.length; i++){
            string  memory existLog = strConcat(toString(_tokenIds[i]), " Tokenid does not exist");
            require( exists(_tokenIds[i]), existLog);
            require(_tokenSerialNumber[_tokenIds[i]] == _seriesId, 'Nft Err: Not all nft belonging to the same series');

            if (_gradeSymbol[_tokenIds[i]] == 1){
                start = S_res;
            }else if (_gradeSymbol[_tokenIds[i]] == 2) {
                start = A_res;
            }else if (_gradeSymbol[_tokenIds[i]] == 3) {
                start = B_res;
            }else if (_gradeSymbol[_tokenIds[i]] == 4) {
                start = C_res;
            }else {
                start = D_res;
            }

            if (start & (1 << (_tokenGradeId[_tokenIds[i]] - 1)) == 0 ){
                start = uint128(start | 1 << (_tokenGradeId[_tokenIds[i]] - 1));
                if (_gradeSymbol[_tokenIds[i]] == 1){
                    S_res = start ;
                }else if (_gradeSymbol[_tokenIds[i]] == 2) {
                    A_res = start;
                }else if (_gradeSymbol[_tokenIds[i]] == 3) {
                    B_res = start;
                }else if (_gradeSymbol[_tokenIds[i]] == 4) {
                    C_res = start;
                }else {
                    D_res = start;
                }
                burn(user, _tokenIds[i]);
            }
        }

        uint256[] memory gradeNumbers_ = _gradeNumbers;
        require( 
                checkRet(reckon(gradeNumbers_[0]),S_res,reckon(gradeNumbers_[1]),A_res,reckon(gradeNumbers_[2]),
                B_res,reckon(gradeNumbers_[3]),C_res,reckon(gradeNumbers_[4]),D_res), 
                'Error: failed, Please confirm that all are collected'
        );
        emit cashCheckByTokenIdLog(_seriesId);
    }

    function reckon(uint256 num) public pure returns(uint128 res){
        res = 0;
        uint128 c = 1;
        for (uint256 i = 0; i < num ; i++ ){             
            res = res + (c << uint128(i));
        }
    }

    function checkRet(uint128  S_check, uint128 S_res,uint128  A_check, uint128 A_res,uint128 B_check,
    uint128 B_res,uint128 C_check,uint128 C_res,uint128 D_check,uint128 D_res) public pure returns(bool)
    {
        if (S_check == S_res &&  A_check == A_res && B_check == B_res && C_check == C_res && D_check == D_res)
            {
            return true;
            }else{
            return false;
            }
    }

    function getAddrSeriesTokenIds(address _user, uint256 _seriesId, uint256 _pageSize, uint256 _page) public view 
    returns(uint256[] memory result) 
    {   
        address user = _user;
        uint256 total =  _addrAllTokenId[user].length;
        require( _pageSize * (_page - 1)  < total, "Nft Err: No more NFT");
        
        uint256 pageSize = _pageSize;
        uint256 page = _page;
        if (pageSize > max_page) {
            pageSize = max_page;
        }

        uint256 start_index = (page - 1) * pageSize;
        uint256 end_index;

        if ( total-start_index <  pageSize)
        {
            end_index = total; 
        }
        else           
        {
            end_index = start_index + pageSize; 
        }

        result = new uint256[](pageSize);

        uint256 j = 0 ;
        for (uint256 i = start_index; i < end_index ; i++ ){
            if (_tokenSerialNumber[_addrAllTokenId[user][i]] == _seriesId){
                result[j] = getAddrTokenId(user,i);
                j++;
            }else{
                if (end_index < total){
                    end_index++;
                }
            }
        }
        return result;
    }

    function getAddrTokenNumberForSeries(address _user, uint256 _seriesId) public view returns(uint256)
    {
        uint256 len = _addrAllTokenId[_user].length;
        uint256 num = 0;
        for (uint256 i = 0; i < len ; i ++){
            if (_tokenSerialNumber[_addrAllTokenId[_user][i]] == _seriesId){
                num++;
            }
        }
        return num;
    }

    function transferArray(address from, address to, uint256[] memory tokenIds) public virtual{
        uint256 len = tokenIds.length;
        require( len > 0,'Nft Err: TokenID is Null');
        for (uint256 i = 0; i < len ; i ++){
            require(exists(tokenIds[i]),"Nft Err: Tokenid does not exist");
            transferFrom(from, to, tokenIds[i]);
        }
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../swap/IPancakeRouter.sol";
import "../token/WrappedToken.sol";
import "../TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/drafts/ERC20PermitUpgradeable.sol";
contract PrizePool is ERC20PermitUpgradeable{
    event send_log(address,address,uint256);
    event swapEthers(uint256);
    event swapErc20(address,uint256);

    struct Config{
        address build_box_address;
        address platform_token;
        address panacke_router;
        address ether_address;
        address gov_address;
    }

    uint256 constant TwoMinute = 1200;
    uint256 constant Zero = 0;

    Config public config;

    constructor(address _build_box_address,
                address _platform_token,
                address _panacke_router,
                address _ether_address,
                uint256 _min_cake_reward,
                address _gov_address,
                address _cake_address)public{
        config = Config(
                        _build_box_address,
                        _platform_token,
                        _panacke_router,
                        _ether_address,
                        _gov_address
                        );
        //min_reward[_ether_address] = _min_ether*10**18;
        min_reward[_cake_address] = _min_cake_reward*10**18;
    }

    mapping(address => uint256) public min_reward;

    function ResetMinReward(address token,uint256 amount) onlyGover public{
        min_reward[token] = amount;
    }

    function SwapErc20(address _token,uint256 _account,address[] memory _path)
        onlyReward(_token)
        checkMinReward(_token)
        public{
        require(_account > 0 ,"PrizePool Err: account cannot be 0");
        uint amount = WrappedToken(config.platform_token).balanceOf(address(this));
        require(amount >= _account,"PrizePool Err:platform not enough");
        WrappedToken(config.platform_token).approve(config.panacke_router,_account);
        //address[] memory path = new address[](2);
        //path[0]=config.platform_token;
        //path[1]=_token;
        uint256 deadline = now+TwoMinute;
        IPancakeRouter01(config.panacke_router).swapExactTokensForTokens(_account,Zero,_path,address(this),deadline);
        emit swapErc20(_token,_account);
    }

    function SwapEthers(uint256 _account,address[] memory _path)
        onlyReward(config.ether_address)
        checkMinReward(config.ether_address)
        public{
        require(_account > 0 ,"PrizePool Err: account cannot be 0");
        uint amount = WrappedToken(config.platform_token).balanceOf(address(this));
        require(amount >= _account,"PrizePool Err:platform not enough");
        WrappedToken(config.platform_token).approve(config.panacke_router,_account);
        //address[] memory path = new address[](2);
        //path[0] = config.platform_token;
        //path[1] = config.ether_address;
        uint256 deadline = now+TwoMinute;
        IPancakeRouter01(config.panacke_router).swapExactTokensForETH(_account,Zero,_path,address(this),deadline);
        emit swapEthers(_account);
    }

    receive() external payable {}

    function sender(address payable to,address token,uint256 amount) onlyBuildBox external{
        if (token == address(0)){
            to.transfer(amount);
        }else{
            TransferHelper.safeTransfer(token,to,amount);
        }
        emit send_log(to,token,amount);
    }

    function QueryConfig() view public returns (Config memory){
        return config;
    }

    function QueryMinReward(address token) view public returns (uint256 amount){
        return min_reward[token];
    }

    modifier onlyReward(address token){
        require(min_reward[token] > 0,"PrizePool Err:reward Not Found");
        _;
    }

    modifier checkMinReward(address _token){
        uint256 amount;
        if (_token == config.ether_address){
            amount = address(this).balance;
        }else{
            amount = WrappedToken(_token).balanceOf(address(this));
        }
        require(amount < min_reward[_token],"PrizePool Err: Token greater than the minimum value");
        _;
    }

    modifier onlyBuildBox{
        require(config.build_box_address == msg.sender,"PrizePool Err: Unauthoruzed");
        _;
    }

    modifier onlyGover{
        require(config.gov_address == msg.sender,"PrizePool Err: Unauthoruzed");
        _;
    }

}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
import "../token/WrappedToken.sol";
import "../lock/lock_contract.sol";
import "../TransferHelper.sol";
contract Staking{
   using SafeMath for uint256;

   uint256 public constant DISTRIBUTION_INTERVAL = 60;

   struct Config{
       address owner;
       address platform_token;
       address staker_donate;
   }

   bool public unregister_platform_asset = true;

   Config public config;
   Distribute public distribute;
   constructor (address _owner,
                address _platform_token,
                address _staker_donate,
                uint256 _distrbiute_amount)public{
       config.owner = _owner;
       config.platform_token = _platform_token;
       config.staker_donate = _staker_donate;
       distribute.amount = _distrbiute_amount;
       distribute.last = now;
   }

   struct PoolInfo{
       address asset_token;
       address staking_token;
       uint256 pending_reward;
       uint256 total_bond_amount;
       uint256 reward_index;
   }

   struct StakeRewardResponse{
       address staking_token;
       uint256 pending_reward;
   }

   struct RewardInfoResponse{
       address staker;
       address asset_token;
       uint256 index;
       uint256 bond_amount;
       uint256 pending_reward;
   }

   struct PoolInfoResponse{
       address asset_token;
       address staking_token;
       uint256 total_bond_amount;
       uint256 reward_index;
       uint256 pending_reward;
   }

   struct RewardInfo {
       uint256 index;
       uint256 bond_amount;
       uint256 pending_reward;
   }

   struct Distribute{
       uint256 last;
       uint256 amount;
       //address usdt_platform_lptoken;
   }


   function QueryDistribute() public view returns (Distribute memory){
       return distribute;
   }

   event distribute_log(uint256,uint256);

   function Distributer() public {
       require(distribute.last + DISTRIBUTION_INTERVAL < now,"Staking: Distribute Cannot distribute platform token before interval");
       uint256 time_elapsed = now.sub(distribute.last);
       uint256 lp_lens = lp_list.length;
       uint256 amount = time_elapsed.mul(distribute.amount).div(lp_lens);
       //ques : all or only platform ?
       if (amount > 0){
           for (uint256 i = 0; i < lp_lens;i++){
               depositReward(lp_list[i], amount);
           }
       }
       distribute.last = distribute.last.add(time_elapsed);
       emit distribute_log(amount,distribute.last);
   }

   struct itmap{
       mapping(address => RewardInfo) reward;
       address[] user_bonds;
   }

   mapping (address => itmap) user_lps_reward;
   mapping(address => PoolInfo) public lp_poolInfo;
   address[] lp_list;

   event register_asset_log(address,address);
   event register_platform_asset_log(address);
   event bond_log(address , uint256);
   event unbond_log(address,uint256);
   event withdraw_log(address,uint256);
   event deposit_reward_log  (address , uint256);
   event update_config_log(address);
   event staker_log(address,uint256);

   function UpdateConfig(address _owner,address _staker_donate) public {
       require(config.owner == msg.sender,"Staking: UpdateConfig Unauthoruzed");
       config.owner = _owner;
       config.staker_donate = _staker_donate;
       emit update_config_log(_owner);
   }

   function registerPlatformAsset(address _platform_token,address _lp_token)public{
       require(config.owner == msg.sender,"Staking: RegisterAsset Unauthoruzed");
       require(lp_poolInfo[_lp_token].staking_token == address(0),"Staking: Platform Asset was already registered");
       require(unregister_platform_asset,"Staking: Can only call once");
       require(config.platform_token == _platform_token,"Staking: Platform Not expected address");
       lp_poolInfo[_lp_token].asset_token = _platform_token;
       lp_poolInfo[_lp_token].staking_token = _lp_token;
       unregister_platform_asset = false;
       //distribute.usdt_platform_lptoken = _platform_token;
       lp_list.push(_lp_token);
       emit register_platform_asset_log(_lp_token);
   }

   function Bond(address _lp_token) public{
       PoolInfo storage _pool_info = lp_poolInfo[_lp_token];
       require(_pool_info.asset_token != address(0),"Staking: Bond Staking Token Not Found!");
       RewardInfo storage _reward_info = user_lps_reward[msg.sender].reward[_lp_token];
       WrappedToken collateral_token = WrappedToken(_lp_token);
       uint256 amount = collateral_token.allowance(msg.sender,address(this));
       TransferHelper.safeTransferFrom(_lp_token,msg.sender,address(this),amount);
       _itmap_insert(msg.sender,_lp_token);
       _before_share_change(_pool_info,_reward_info);
       _increase_bond_amount(_pool_info,_reward_info,amount);
       emit bond_log(_lp_token,amount);
   }

   function depositReward(address _staking_lp_token,uint256 amount) internal {
       PoolInfo storage _pool_info = lp_poolInfo[_staking_lp_token];
       require(_pool_info.asset_token != address(0),"Staking: Staking Token Not Found!");
       if (_pool_info.total_bond_amount == 0){
           _pool_info.pending_reward = SafeMath.add(_pool_info.pending_reward,
                                                    amount);
       }else{
           uint256 reward_per_bond = SafeMath.div(
                                                  SafeMath.add(_pool_info.pending_reward,amount)*1e18
                                                  ,_pool_info.total_bond_amount);
            _pool_info.reward_index = SafeMath.add(_pool_info.reward_index,
                                                    reward_per_bond);
            _pool_info.pending_reward = 0;
       }
       emit deposit_reward_log(_staking_lp_token,amount);
   }


   function Unbond(address _lp_token,uint256 amount)public{
       PoolInfo storage _pool_info = lp_poolInfo[_lp_token];
       require(_pool_info.staking_token != address(0),"Staking: Unbond lp_token does not exist");
       itmap storage user_reward = user_lps_reward[msg.sender];
       RewardInfo storage _reward_info = user_reward.reward[_lp_token];
       require(_reward_info.bond_amount > 0 || _reward_info.pending_reward > 0,"Staking: msg.sender not find lp_token");
       require(_reward_info.bond_amount >= amount,"Staking: Cannot unbond more than bond amount");
       _before_share_change(_pool_info,_reward_info);
       _decrease_bond_amount(_pool_info,_reward_info,amount);
       if (_reward_info.pending_reward == 0 && _reward_info.bond_amount == 0){
           delete user_reward.reward[_lp_token];
           require (_itmap_remove(msg.sender,_lp_token),"Staking: Unbond Clearance lp_token failure");
       }
       TransferHelper.safeTransfer(_lp_token,msg.sender,amount);
       emit unbond_log(_lp_token,amount);
   }

   function Withdraw(address _lp_token,uint256 _start,uint256 _end) public {
        uint256 amount = 0;
        itmap storage user_reward = user_lps_reward[msg.sender];
        if (_lp_token == address(0)){
            require(_end > _start,"Staking: Withdraw all end cannot be less than the begin");
            uint256 lp_length = user_reward.user_bonds.length;
            if (_end > lp_length){
                _end = lp_length;
            }
            for (uint256 i = _start ; i < _end; i++){
                amount = 0;

                address  _user_lp = user_reward.user_bonds[i];
                RewardInfo storage _reward_info = user_reward.reward[_user_lp];
                if (_reward_info.pending_reward == 0 &&
                    _reward_info.bond_amount == 0){
                    require(_itmap_remove(msg.sender,_user_lp),"Staking:Withdraw Clearance lp_token failure");
                    _end--;
                }else{
                    PoolInfo storage _pool_info = lp_poolInfo[_user_lp];
                    require(_pool_info.staking_token != address(0),"Staking: Withdraw lp_token does not exist");
                    _before_share_change(_pool_info,_reward_info);
                    amount = amount.add(_reward_info.pending_reward);
                    _reward_info.pending_reward = 0;

                    if (amount > 0){

                        TransferHelper.safeTransfer(config.platform_token,msg.sender,amount.div(2));
                        TransferHelper.safeApprove(config.platform_token,config.staker_donate,amount.sub(amount.div(2)));
                        Lock staker_handler = Lock(config.staker_donate);
                        staker_handler.RewardToken(amount.sub(amount.div(2)));
                        emit staker_log(msg.sender,amount);
                    }
                    emit withdraw_log(_user_lp,_reward_info.bond_amount);
                    if (_reward_info.pending_reward == 0 &&
                    _reward_info.bond_amount == 0){
                        require(_itmap_remove(msg.sender,_user_lp),"Staking:Withdraw Clearance lp_token failure");
                        _end--;
                    }
                }
            }
        }else{
            PoolInfo storage _pool_info = lp_poolInfo[_lp_token];
            require(_pool_info.staking_token != address(0),"Staking: Unbond lp_token does not exist");
            require(_pool_info.staking_token == _lp_token,"Staking: WithDraw The parameter does not match the expected");
            RewardInfo storage _reward_info = user_reward.reward[_lp_token];
            require(_reward_info.bond_amount > 0 || _reward_info.pending_reward > 0,"Staking: msg.sender not find lp_token");
            _before_share_change(_pool_info,_reward_info);
            amount = amount.add(_reward_info.pending_reward);
            _reward_info.pending_reward = 0;
            if (amount > 0){

                TransferHelper.safeTransfer(config.platform_token,msg.sender,amount.div(2));

                TransferHelper.safeApprove(config.platform_token,config.staker_donate,amount.sub(amount.div(2)));

                Lock staker_handler = Lock(config.staker_donate);
                staker_handler.RewardToken(amount.sub(amount.div(2)));
                emit staker_log(msg.sender,amount);
            }
            if (_reward_info.pending_reward == 0 &&
                _reward_info.bond_amount == 0){
                require(_itmap_remove(msg.sender,_lp_token),"Staking:Withdraw Clearance lp_token failure");
            }
            emit withdraw_log(_lp_token,_reward_info.bond_amount);
        }

    }

    function QueryConfig()public view returns (Config memory result){
        return config;
    }

    function QueryPoolInfo(address _lp_token)public view returns(PoolInfoResponse memory result){
        require(_lp_token != address(0),"Staking: Can't pass in an empty address");
        require(lp_poolInfo[_lp_token].asset_token != address(0),"Staking: Staking Token address does not exist");
        PoolInfo storage poolinfo = lp_poolInfo[_lp_token];
        result.asset_token=poolinfo.asset_token;
        result.staking_token=poolinfo.staking_token;
        result.total_bond_amount=poolinfo.total_bond_amount;
        result.reward_index=poolinfo.reward_index;
        result.pending_reward=poolinfo.pending_reward;
    }


    function QueryRewardInfo(address _lp_token,address _staker)public view returns(RewardInfoResponse[] memory){
        itmap storage user_reward = user_lps_reward[_staker];

        if (user_reward.user_bonds.length <= 0){
            RewardInfoResponse[] memory result;
            return result;
        }

        if(_lp_token == address(0)){
            uint256 lptoken_len = user_reward.user_bonds.length;
            RewardInfoResponse[] memory result = new RewardInfoResponse[](lptoken_len);
            for(uint i = 0; i < lptoken_len;i++){
                address user_lp_addr = user_reward.user_bonds[i];
                RewardInfo storage _reward_info = user_reward.reward[user_lp_addr];
                result[i].staker = _staker;
                result[i].asset_token = user_lp_addr;
                result[i].index = _reward_info.index;
                result[i].bond_amount = _reward_info.bond_amount;
                result[i].pending_reward = _reward_info.pending_reward;
            }
            return result;
        }else {
            RewardInfoResponse[] memory result = new RewardInfoResponse[](1);
            RewardInfo storage _reward_info = user_reward.reward[_lp_token];
            if (_reward_info.bond_amount == 0 && _reward_info.pending_reward == 0){
                return result;
            }
            result[0].staker = _staker;
            result[0].asset_token = _lp_token;
            result[0].index = _reward_info.index;
            result[0].bond_amount = _reward_info.bond_amount;
            result[0].pending_reward = _reward_info.pending_reward;
            return result;
        }
    }


   function QueryBondReward() public view returns(StakeRewardResponse[] memory){
        itmap storage user_reward = user_lps_reward[msg.sender];
        if (user_reward.user_bonds.length == 0){
            StakeRewardResponse[] memory result;
            return result;
        }
        uint256 lptoken_len = user_reward.user_bonds.length;
        StakeRewardResponse[] memory result = new StakeRewardResponse[](lptoken_len);
        for(uint i = 0; i < lptoken_len;i++){
            address user_lp_addr = user_reward.user_bonds[i];
            RewardInfo storage _reward_info = user_reward.reward[user_lp_addr];
            PoolInfo storage _pool_info = lp_poolInfo[user_lp_addr];
            result[i].staking_token = user_lp_addr;
            uint256 _pending_reward = (_reward_info.bond_amount.mul(_pool_info.reward_index)).
                sub(_reward_info.bond_amount.mul(_reward_info.index)).div(1e18);
            result[i].pending_reward = _reward_info.pending_reward.add(_pending_reward);
        }
        return result;
   }

   function _increase_bond_amount(PoolInfo storage _pool_info,RewardInfo storage _reward_info,uint256 amount) internal {
       _pool_info.total_bond_amount = _pool_info.total_bond_amount.add(amount);
       _reward_info.bond_amount = _reward_info.bond_amount.add(amount);
   }

   function _before_share_change(PoolInfo storage _pool_info,RewardInfo storage _reward_info)internal{
       uint256 pending_reward = (_reward_info.bond_amount.mul(_pool_info.reward_index)).
           sub(_reward_info.bond_amount.mul(_reward_info.index)).div(1e18);
       _reward_info.index = _pool_info.reward_index;
       _reward_info.pending_reward = _reward_info.pending_reward.add(pending_reward);
   }

   function _decrease_bond_amount(PoolInfo storage _pool_info,RewardInfo storage _reward_info,uint256 amount) internal{
       require(_pool_info.staking_token != address(0),"Staking: _decrease_bond_amount lp_token does not exist");
       require(_reward_info.bond_amount > 0 || _reward_info.pending_reward > 0,"Staking: _decrease_bond_amount msg.sender not find lp_token");
       _pool_info.total_bond_amount = _pool_info.total_bond_amount.sub(amount);
       _reward_info.bond_amount = _reward_info.bond_amount.sub(amount);
   }

   function _itmap_insert(address _sender,address _staking_token) internal {
       itmap storage user_reward = user_lps_reward[_sender];
       if (user_reward.reward[_staking_token].pending_reward == 0 &&
           user_reward.reward[_staking_token].bond_amount == 0){
           user_reward.user_bonds.push(_staking_token);
       }
   }

   function _itmap_remove(address _sender,address _staking_token) internal returns(bool){
       itmap storage user_reward = user_lps_reward[_sender];
       require(user_reward.user_bonds.length > 0,"Staking: _itmap_remove Staker is incorrect");
       uint256 itmp_length = user_reward.user_bonds.length;
       for (uint i = itmp_length ; i >= 1 ; i--){
            if (user_reward.user_bonds[i-1] == _staking_token){
                user_reward.user_bonds[i-1] = user_reward.user_bonds[itmp_length-1];
                user_reward.user_bonds.pop();
                return true;
            }
        }
       return false;
   }
}

pragma solidity ^0.6.0;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}
interface IPancakeRouter02 is IPancakeRouter01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/drafts/ERC20PermitUpgradeable.sol";

import "./TokenControllerInterface.sol";
import "./ControlledTokenInterface.sol";
import "./WrappedToken.sol";


/// @title Controlled ERC20 Token
/// @notice ERC20 Tokens with a controller for minting & burning
contract ControlledToken is ERC20PermitUpgradeable, ControlledTokenInterface {

  /// @dev Emitted when an instance is initialized
  event Initialized(
    string _name,
    string _symbol,
    uint8 _decimals,
    TokenControllerInterface _controller
  );

  /// @notice Interface to the contract responsible for controlling mint/burn
  TokenControllerInterface public override controller;

  /// @notice Initializes the Controlled Token with Token Details and the Controller
  /// @param _name The name of the Token
  /// @param _symbol The symbol for the Token
  /// @param _decimals The number of decimals for the Token
  /// @param _controller Address of the Controller contract for minting & burning
  function initialize(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    TokenControllerInterface _controller
  )
    public
    virtual
    initializer
  {
    require(address(_controller) != address(0), "ControlledToken/controller-not-zero");
    __ERC20_init(_name, _symbol);
    __ERC20Permit_init("ControlledToken");
    controller = _controller;
    _setupDecimals(_decimals);

    emit Initialized(
      _name,
      _symbol,
      _decimals,
      _controller
    );
  }

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param _user Address of the receiver of the minted tokens
  /// @param _amount Amount of tokens to mint
  function controllerMint(address _user, uint256 _amount,uint256 _number) external virtual override onlyController {
      uint256 mint_number = _amount;
      if (_number == 10){
          mint_number = 11*10**18;
      }
      _mint(_user, mint_number);
  }

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurn(address _user, uint256 _amount) external virtual override onlyController {
    _burn(_user, _amount);
  }

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param _operator Address of the operator performing the burn action via the controller contract
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external virtual override onlyController {
      if (_operator != _user) {
          uint256 decreasedAllowance = allowance(_user, _operator).sub(_amount, "ControlledToken/exceeds-allowance");
          _approve(_user, _operator, decreasedAllowance);
    }
    _burn(_user, _amount);
  }

  /// @dev Function modifier to ensure that the caller is the controller contract
  modifier onlyController {
      require(msg.sender == address(controller), "ControlledToken/only-controller");
    _;
  }

  /// @dev Controller hook to provide notifications & rule validations on token transfers to the controller.
  /// This includes minting and burning.
  /// May be overridden to provide more granular control over operator-burning
  /// @param from Address of the account sending the tokens (address(0x0) on minting)
  /// @param to Address of the account receiving the tokens (address(0x0) on burning)
  /// @param amount Amount of tokens being transferred
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      //     controller.beforeTokenTransfer(from, to, amount);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./TokenControllerInterface.sol";

/// @title Controlled ERC20 Token
/// @notice ERC20 Tokens with a controller for minting & burning
interface ControlledTokenInterface is IERC20Upgradeable {

  /// @notice Interface to the contract responsible for controlling mint/burn
  function controller() external view returns (TokenControllerInterface);

  /// @notice Allows the controller to mint tokens for a user account
  /// @dev May be overridden to provide more granular control over minting
  /// @param _user Address of the receiver of the minted tokens
  /// @param _amount Amount of tokens to mint
  function controllerMint(address _user, uint256 _amount,uint256 _number) external;

  /// @notice Allows the controller to burn tokens from a user account
  /// @dev May be overridden to provide more granular control over burning
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurn(address _user, uint256 _amount) external;

  /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
  /// @dev May be overridden to provide more granular control over operator-burning
  /// @param _operator Address of the operator performing the burn action via the controller contract
  /// @param _user Address of the holder account to burn tokens from
  /// @param _amount Amount of tokens to burn
  function controllerBurnFrom(address _operator, address _user, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

import "./ControlledToken.sol";
import "./external/ProxyFactory.sol";

/// @title Controlled ERC20 Token Factory
/// @notice Minimal proxy pattern for creating new Controlled ERC20 Tokens
contract ControlledTokenProxyFactory is ProxyFactory {

  /// @notice Contract template for deploying proxied tokens
  ControlledToken public instance;

  /// @notice Initializes the Factory with an instance of the Controlled ERC20 Token
  constructor () public {
    instance = new ControlledToken();
  }

  /// @notice Creates a new Controlled ERC20 Token as a proxy of the template instance
  /// @return A reference to the new proxied Controlled ERC20 Token
  function create() external returns (ControlledToken) {
    return ControlledToken(deployMinimal(address(instance), ""));
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.7.0;

/// @title Controlled ERC20 Token Interface
/// @notice Required interface for Controlled ERC20 Tokens linked to a Prize Pool
/// @dev Defines the spec required to be implemented by a Controlled ERC20 Token
interface TokenControllerInterface {

  /// @dev Controller hook to provide notifications & rule validations on token transfers to the controller.
  /// This includes minting and burning.
  /// @param from Address of the account sending the tokens (address(0x0) on minting)
  /// @param to Address of the account receiving the tokens (address(0x0) on burning)
  /// @param amount Amount of tokens being transferred
  function beforeTokenTransfer(address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedToken is ERC20, Ownable {
    using SafeMath for uint256;
    event Burn(address indexed _sender, address indexed _to, uint256 amount);
    address public mint_address;

    constructor( address mint,
                 string memory name,
                 string memory symbol,
                 uint256 amount,
                 uint256 quantity,
                 address quantity_address
        ) public ERC20(name, symbol) {
        _mint(mint, amount.sub(quantity));
        _mint(quantity_address,quantity);
        //mint_address = mint;
    }

    function burn(uint256 amount, address to) public {
        _burn(_msgSender(), amount);

        emit Burn(_msgSender(), to, amount);
    }
}

pragma solidity ^0.6.0;

// solium-disable security/no-inline-assembly
// solium-disable security/no-low-level-calls
contract ProxyFactory {

  event ProxyCreated(address proxy);

  function deployMinimal(address _logic, bytes memory _data) public returns (address proxy) {
    // Adapted from https://github.com/optionality/clone-factory/blob/32782f82dfc5a00d103a7e61a17a5dedbd1e8e9d/contracts/CloneFactory.sol
    bytes20 targetBytes = bytes20(_logic);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      proxy := create(0, clone, 0x37)
    }

    emit ProxyCreated(address(proxy));

    if(_data.length > 0) {
      (bool success,) = proxy.call(_data);
      require(success, "ProxyFactory/constructor-call-failed");
    }
  }
}

