/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;



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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

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
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;
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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                block.chainid,
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
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;





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
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping (address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {
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
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interface/IStrategy.sol



pragma solidity ^0.8.0;

/**
 * @title Strategy interface
 * @author solace.fi
 * @notice Interface for investment Strategy contract
 */
interface IStrategy {
    function withdraw(uint256 _amount) external returns (uint256 _loss);
    function deposit() external payable;
    function estimatedTotalAssets() external view returns (uint256);
    function delegatedAssets() external view returns (uint256);
    function harvest() external;
    function isActive() external view returns (bool);
}


// File contracts/interface/IWETH10.sol


// Copyright (C) 2015, 2016, 2017 Dapphub
// Adapted by Ethereum Community 2021
pragma solidity 0.8.0;

/// @dev Wrapped Ether v10 (WETH10) is an Ether (ETH) ERC-20 wrapper. You can `deposit` ETH and obtain a WETH10 balance which can then be operated as an ERC-20 token. You can
/// `withdraw` ETH from WETH10, which will then burn WETH10 token in your wallet. The amount of WETH10 token in any wallet is always identical to the
/// balance of ETH deposited minus the ETH withdrawn with that specific wallet.
interface IWETH10 is IERC20 {

    /// @dev Returns current amount of flash-minted WETH10 token.
    function flashMinted() external view returns(uint256);

    /// @dev `msg.value` of ETH sent to this contract grants caller account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to caller account.
    function deposit() external payable;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance.
    /// Emits {Transfer} event to reflect WETH10 token mint of `msg.value` from `address(0)` to `to` account.
    function depositTo(address to) external payable;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to the same.
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdraw(uint256 value) external;

    /// @dev Burn `value` WETH10 token from caller account and withdraw matching ETH to account (`to`).
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from caller account.
    /// Requirements:
    ///   - caller account must have at least `value` balance of WETH10 token.
    function withdrawTo(address payable to, uint256 value) external;

    /// @dev Burn `value` WETH10 token from account (`from`) and withdraw matching ETH to account (`to`).
    /// Emits {Approval} event to reflect reduced allowance `value` for caller account to spend from account (`from`),
    /// unless allowance is set to `type(uint256).max`
    /// Emits {Transfer} event to reflect WETH10 token burn of `value` to `address(0)` from account (`from`).
    /// Requirements:
    ///   - `from` account must have at least `value` balance of WETH10 token.
    ///   - `from` account must have approved caller to spend at least `value` of WETH10 token, unless `from` and caller are the same account.
    function withdrawFrom(address from, address payable to, uint256 value) external;

    /// @dev `msg.value` of ETH sent to this contract grants `to` account a matching increase in WETH10 token balance,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function depositToAndCall(address to, bytes calldata data) external payable returns (bool);

    /// @dev Sets `value` as allowance of `spender` account over caller account's WETH10 token,
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// Emits {Approval} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// For more information on {approveAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);

    /// @dev Moves `value` WETH10 token from caller's account to account (`to`),
    /// after which a call is executed to an ERC677-compliant contract with the `data` parameter.
    /// A transfer to `address(0)` triggers an ETH withdraw matching the sent WETH10 token in favor of caller.
    /// Emits {Transfer} event.
    /// Returns boolean value indicating whether operation succeeded.
    /// Requirements:
    ///   - caller account must have at least `value` WETH10 token.
    /// For more information on {transferAndCall} format, see https://github.com/ethereum/EIPs/issues/677.
    function transferAndCall(address to, uint value, bytes calldata data) external returns (bool);
}


// File contracts/interface/IRegistry.sol


pragma solidity 0.8.0;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts in the Solaverse.
 */
interface IRegistry {

    /// Protocol contract address getters
    function master() external returns (address);
    function vault() external returns (address);
    function treasury() external returns (address);
    function governance() external returns (address);
    function solace() external returns (address);
    function locker() external returns (address);
    function claimsAdjustor() external returns (address);
    function claimsEscrow() external returns (address);

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance The new governor.
     */
    function setGovernance(address _governance) external;

    /**
     * @notice Sets the solace token contract.
     * Can only be called by the current governor.
     * @param _solace The solace token address.
     */
    function setSolace(address _solace) external;

    /**
     * @notice Sets the master contract.
     * Can only be called by the current governor.
     * @param _master The master contract address.
     */
    function setMaster(address _master) external;

    /**
     * @notice Sets the vault contract.
     * Can only be called by the current governor.
     * @param _vault The vault contract address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets the treasury contract.
     * Can only be called by the current governor.
     * @param _treasury The treasury contract address.
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Sets the locker contract.
     * Can only be called by the current governor.
     * @param _locker The locker address.
     */
    function setLocker(address _locker) external;

        /**
     * @notice Sets the Claims Adjustor contract.
     * Can only be called by the current governor.
     * @param _claimsAdjustor The Claims Adjustor address.
     */
    function setClaimsAdjustor(address _claimsAdjustor) external;

    /**
     * @notice Sets the Claims Escrow contract.
     * Can only be called by the current governor.
     * @param _claimsEscrow The sClaims Escrow address.
     */
    function setClaimsEscrow(address _claimsEscrow) external;

    /**
     * @notice Adds a new product.
     * Can only be called by the current governor.
     * @param _product The product to add.
     */
    function addProduct(address _product) external;

    /**
     * @notice Removes a product.
     * Can only be called by the current governor.
     * @param _product The product to remove.
     */
    function removeProduct(address _product) external;

    /**
     * @notice Returns the number of products.
     * @return The number of products.
     */
    function numProducts() external view returns (uint256);

    /**
     * @notice Returns the product at the given index.
     * @param _productNum The index to query.
     * @return The address of the product.
     */
    function getProduct(uint256 _productNum) external view returns (address);

    /**
     * @notice Returns true if the given address is a product.
     * @param _product The address to query.
     * @return True if the address is a product.
     */
    function isProduct(address _product) external view returns (bool);
}


// File contracts/interface/IClaimsEscrow.sol


pragma solidity 0.8.0;


/**
 * @title IClaimsEscrow: Escrow Contract for solace.fi claims
 * @author solace.fi
 * @notice The interface for the Claims Escrow contract.
 */
interface IClaimsEscrow {
    function receiveClaim(address _claimant) external payable returns (uint256 claimId);
}


// File contracts/interface/IVault.sol



pragma solidity ^0.8.0;


/**
 * @title Vault interface
 * @author solace.fi
 * @notice Interface for Vault contract
 */

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IVault is IERC20, IERC20Permit {

    function deposit() external payable;
    function withdraw(uint256 _amount, uint256 _maxLoss) external returns (uint256);
    function token() external view returns (IERC20);
    function debtOutstanding(address) external view returns (uint256);
    function revokeStrategy(address) external;
    function strategies(address) external view returns (StrategyParams memory);
    function processClaim(address claimant, uint256 amount) external;
    function report(
        uint256 gain,
        uint256 loss,
        uint256 _debtPayment
    ) external returns (uint256);
}


// File contracts/Vault.sol



pragma solidity 0.8.0;








/**
 * @title Vault
 * @author solace.fi
 * @notice Capital Providers can deposit ETH to mint shares of the Vault (CP tokens)
 */
contract Vault is ERC20Permit, IVault {
    using SafeERC20 for IERC20;
    using Address for address;
    /*
    struct StrategyParams {
        uint256 performanceFee; // Strategist's fee (basis points)
        uint256 activation; // Activation block.timestamp
        uint256 debtRatio; // Maximum borrow amount (in BPS of total assets)
        uint256 minDebtPerHarvest; // Lower limit on the increase of debt since last harvest
        uint256 maxDebtPerHarvest; // Upper limit on the increase of debt since last harvest
        uint256 lastReport; // block.timestamp of the last time a report occured
        uint256 totalDebt; // Total outstanding debt that Strategy has
        uint256 totalGain; // Total returns that Strategy has realized for Vault
        uint256 totalLoss; // Total losses that Strategy has realized for Vault
    }
    */
    /*************
    GLOBAL CONSTANTS
    *************/

    uint256 constant DEGREDATION_COEFFICIENT = 10 ** 18;
    uint256 constant MAX_BPS = 10000; // 10k basis points (100%)
    uint256 constant SECS_PER_YEAR = 31556952; // 365.2425 days

    /*************
    GLOBAL VARIABLES
    *************/

    uint256 public activation;
    uint256 public delegatedAssets;
    uint256 public debtRatio; // Debt ratio for the Vault across all strategies (in BPS, <= 10k)
    uint256 public totalDebt; // Amount of tokens that all strategies have borrowed
    uint256 public lastReport; // block.timestamp of last report
    uint256 public lockedProfit; // how much profit is locked and cant be withdrawn
    uint256 public performanceFee;
    uint256 public lockedProfitDegration; // rate per block of degration. DEGREDATION_COEFFICIENT is 100% per block
    uint256 public minCapitalRequirement;

    uint256 public managementFee; // Governance Fee for management of Vault (given to `rewards`)

    bool public emergencyShutdown;

    /// WETH
    IERC20 public override token;

    /// address with rights to call governance functions
    address public governance;

    /// Rewards contract/wallet where Governance fees are sent to
    address public rewards;

    /// Registry of protocol contract addresses
    IRegistry public registry;

    /// @notice Determines the order of strategies to pull funds from. Managed by governance
    address[] public withdrawalQueue;

    /*************
    MAPPINGS
    *************/

    // TypeError: Overriding public state variable return types differ.
    //mapping (address => StrategyParams) public override strategies;
    mapping (address => StrategyParams) internal _strategies;
    function strategies(address _strategy) external view override returns (StrategyParams memory) {
        StrategyParams memory params = _strategies[_strategy];
        return params;
    }
    mapping (address => uint256) internal _strategyDelegatedAssets;

    /*************
    EVENTS
    *************/

    event StrategyAdded(
        address indexed strategy,
        uint256 debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 performanceFee
    );

    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 totalGain,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtRatio
    );

    event DepositMade(address indexed depositor, uint256 indexed amount, uint256 indexed shares);
    event WithdrawalMade(address indexed withdrawer, uint256 indexed value);
    event StrategyAddedToQueue(address indexed strategy);
    event StrategyRemovedFromQueue(address indexed strategy);
    event UpdateWithdrawalQueue(address[] indexed queue);
    event StrategyRevoked(address strategy);
    event EmergencyShutdown(bool active);
    event ClaimProcessed(address indexed claimant, uint256 indexed amount);
    event StrategyUpdateDebtRatio(address indexed strategy, uint256 indexed newDebtRatio);
    event StrategyUpdateMinDebtPerHarvest(address indexed strategy, uint256 indexed newMinDebtPerHarvest);
    event StrategyUpdateMaxDebtPerHarvest(address indexed strategy, uint256 indexed newMaxDebtPerHarvest);
    event StrategyUpdatePerformanceFee(address indexed strategy, uint256 indexed newPerformanceFee);

    constructor (address _governance, address _registry, address _token) ERC20("Solace CP Token", "SCP") ERC20Permit("Solace CP Token") {
        governance = _governance;
        rewards = msg.sender; // set governance address as rewards destination for now

        registry = IRegistry(_registry);

        token = IERC20(_token);

        lastReport = block.timestamp;
        activation = block.timestamp;

        lockedProfitDegration = (DEGREDATION_COEFFICIENT * 46) / 10 ** 6; // 6 hours in blocks
    }

    /*************
    EXTERNAL FUNCTIONS
    *************/

    /**
     * @notice Transfers the governance role to a new governor.
     * Can only be called by the current governor.
     * @param _governance the new governor
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    /**
     * @notice Changes the locked profit degration.
     * Can only be called by the current governor.
     * @param degration rate of degration in percent per second scaled to 1e18.
     */
    function setLockedProfitDegration(uint256 degration) external {
        require(msg.sender == governance, "!governance");
        lockedProfitDegration = degration;
    }

    /**
     * @notice Changes the minimum capital requirement of the vault
     * Can only be called by the current governor.
     * During withdrawals, withdrawals are possible down to the Vault's MCR.
     * @param newMCR The new minimum capital requirement.
     */
    function setMinCapitalRequirement(uint256 newMCR) external {
        require(msg.sender == governance, "!governance");
        minCapitalRequirement = newMCR;
    }

    /**
     * @notice Changes the performanceFee of the Vault.
     * Can only be called by the current governor.
     * @param fee New performanceFee to use
     */
    function setPerformanceFee(uint256 fee) external {
        require(msg.sender == governance, "!governance");
        require(fee <= MAX_BPS, "cannot exceed MAX_BPS");
        performanceFee = fee;
    }

    /**
     * @notice Activates or deactivates Vault mode where all Strategies go into full withdrawal.
     * Can only be called by the current governor.
     * During Emergency Shutdown:
     * 1. No Users may deposit into the Vault (but may withdraw as usual.)
     * 2. Governance may not add new Strategies.
     * 3. Each Strategy must pay back their debt as quickly as reasonable to minimally affect their position.
     * 4. Only Governance may undo Emergency Shutdown.
     * @param active If true, the Vault goes into Emergency Shutdown.
     * If false, the Vault goes back into Normal Operation.
    */
    function setEmergencyShutdown(bool active) external {
        require(msg.sender == governance, "!governance");
        emergencyShutdown = active;
        emit EmergencyShutdown(active);
    }

    /**
     * @notice Sets `withdrawalQueue` to be in the order specified by input array
     * @dev Specify addresses in the order in which funds should be withdrawn.
     * The ordering should be least impactful (the Strategy whose core positions will be least impacted by
     * having funds removed) first, with the next least impactful second, etc.
     * @param _queue array of addresses of strategy contracts
     */
    function setWithdrawalQueue(address[] memory _queue) external {
        require(msg.sender == governance, "!governance");
        // check that each entry in input array is an active strategy
        for (uint256 i = 0; i < _queue.length; i++) {
            require(_strategies[_queue[i]].activation > 0, "must be a current strategy");
        }
        // set input to be the new queue
        withdrawalQueue = _queue;

        emit UpdateWithdrawalQueue(_queue);
    }

    /**
     * @notice Allows governance to approve a new Strategy
     * Can only be called by the current governor.
     * @param _strategy The address of Strategy contract to add
     * @param _debtRatio The share of the total assets in the `vault that the `strategy` has access to.
     * @param _minDebtPerHarvest Lower limit on the increase of debt since last harvest
     * @param _maxDebtPerHarvest Upper limit on the increase of debt since last harvest
     * @param _performanceFee The fee the strategist will receive based on this Vault's performance.
     */
    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _minDebtPerHarvest,
        uint256 _maxDebtPerHarvest,
        uint256 _performanceFee
    ) external {
        require(msg.sender == governance, "!governance");
        require(!emergencyShutdown, "vault is in emergency shutdown");
        require(_strategy != address(0), "strategy cannot be set to zero address");
        require(debtRatio + _debtRatio <= MAX_BPS, "debtRatio exceeds MAX BPS");
        require(_performanceFee <= MAX_BPS - performanceFee, "invalid performance fee");
        require(_minDebtPerHarvest <= _maxDebtPerHarvest, "minDebtPerHarvest exceeds maxDebtPerHarvest");

        // Add strategy to approved strategies
        _strategies[_strategy] = StrategyParams({
            performanceFee: _performanceFee,
            activation: block.timestamp,
            debtRatio: _debtRatio,
            minDebtPerHarvest: _minDebtPerHarvest,
            maxDebtPerHarvest: _maxDebtPerHarvest,
            lastReport: block.timestamp,
            totalDebt: 0,
            totalGain: 0,
            totalLoss: 0
        });

        // Append strategy to withdrawal queue
        withdrawalQueue.push(_strategy);

        debtRatio += _debtRatio;

        emit StrategyAdded(_strategy, _debtRatio, _minDebtPerHarvest, _maxDebtPerHarvest, _performanceFee);
    }

    /**
     * @notice Adds `_strategy` to `withdrawalQueue`
     * Can only be called by the current governor.
     * @param _strategy address of the strategy to add
     */
    function addStrategyToQueue(address _strategy) external {

        require(msg.sender == governance, "!governance");
        require(_strategies[_strategy].activation > 0, "must be a current strategy");

        // check that strategy is not already in the queue
        for (uint256 i = 0; i < withdrawalQueue.length; i++) {
            require(withdrawalQueue[i] != _strategy, "strategy already in queue");
        }

        withdrawalQueue.push(_strategy);

        emit StrategyAddedToQueue(_strategy);
    }

    /**
     * @notice Remove `_strategy` from `withdrawalQueue`
     * Can only be called by the current governor.
     * Can only be called on an active strategy (added using addStrategy)
     * `_strategy` cannot already be in the queue
     * @param _strategy address of the strategy to remove
     */
    function removeStrategyFromQueue(address _strategy) external {

        require(msg.sender == governance, "!governance");
        require(_strategies[_strategy].activation > 0, "must be a current strategy");

        address[] storage newQueue;

        for (uint256 i = 0; i < withdrawalQueue.length; i++) {
            if (withdrawalQueue[i] != _strategy) {
                newQueue.push(withdrawalQueue[i]);
            }
        }

        // we added all the elements back in the queue
        if (withdrawalQueue.length == newQueue.length) revert("strategy not in queue");

        // set withdrawalQueue to be the new one without the removed strategy
        withdrawalQueue = newQueue;
        emit StrategyRemovedFromQueue(_strategy);
    }

    /**
     * @notice Revoke a Strategy, setting its debt limit to 0 and preventing any future deposits.
     * Should only be used in the scenario where the Strategy is being retired
     * but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in market
     * conditions leading to losses, or an imminent failure in an external
     * dependency.
     * This may only be called by governance or the Strategy itself.
     * A Strategy will only revoke itself during emergency shutdown.
     * @param strategy The Strategy to revoke.
    */
    function revokeStrategy(address strategy) external override {
        require(msg.sender == governance ||
            _strategies[msg.sender].activation > 0, "must be called by governance or strategy to be revoked"
        );
        _revokeStrategy(strategy);
    }

    /**
     * @notice Allows the Claims Adjustor contract to process a claim
     * Only callable by the ClaimsAdjustor contract
     * Sends claimed `amount` to Escrow, where it is withdrawable by the claimant after a cooldown period
     * @param claimant Address of the claimant
     * @param amount Amount to pay out
     * Reverts if Vault is in Emergency Shutdown
     */
    function processClaim(address claimant, uint256 amount) external override {
        require(!emergencyShutdown, "cannot process claim when vault is in emergency shutdown");
        require(msg.sender == registry.claimsAdjustor(), "!claimsAdjustor");

        // unwrap some WETH to make ETH available for claims payout
        IWETH10(address(token)).withdraw(amount);

        IClaimsEscrow escrow = IClaimsEscrow(registry.claimsEscrow());
        escrow.receiveClaim{value: amount}(claimant);

        emit ClaimProcessed(claimant, amount);
    }

    /**
     * @notice Change the quantity of assets `strategy` may manage.
     * Can only be called by the current governor.
     * Can only be called on an active strategy (added using addStrategy)
     * @param _strategy address of the strategy to update
     * @param _debtRatio The new `debtRatio` of Strategy (quantity of assets it can manage)
     */
    function updateStrategyDebtRatio(address _strategy, uint256 _debtRatio) external {
        require(msg.sender == governance, "!governance");
        require(_strategies[_strategy].activation > 0, "must be a current strategy");

        debtRatio -= _strategies[_strategy].debtRatio;
        _strategies[_strategy].debtRatio = _debtRatio;
        debtRatio += _debtRatio;

        require(debtRatio <= MAX_BPS, "Vault debt ratio cannot exceed MAX_BPS");

        emit StrategyUpdateDebtRatio(_strategy, _debtRatio);
    }

    /**
     * @notice Change the quantity assets per block this Vault may deposit to or
     * withdraw from `strategy`.
     * Can only be called by the current governor.
     * Can only be called on an active strategy (added using addStrategy)
     * @param _strategy Address of the strategy to update
     * @param _minDebtPerHarvest New lower limit on the increase of debt since last harvest
     */
    function updateStrategyMinDebtPerHarvest(address _strategy, uint256 _minDebtPerHarvest) external {
        require(msg.sender == governance, "!governance");
        require(_strategies[_strategy].activation > 0, "must be a current strategy");
        require(_strategies[_strategy].maxDebtPerHarvest >= _minDebtPerHarvest, "cannot exceed Strategy maxDebtPerHarvest");

        _strategies[_strategy].minDebtPerHarvest = _minDebtPerHarvest;

        emit StrategyUpdateMinDebtPerHarvest(_strategy, _minDebtPerHarvest);
    }

    /**
     * @notice Change the quantity assets per block this Vault may deposit to or
     * withdraw from `strategy`.
     * Can only be called by the current governor.
     * Can only be called on an active strategy (added using addStrategy)
     * @param _strategy Address of the strategy to update
     * @param _maxDebtPerHarvest New upper limit on the increase of debt since last harvest
     */
    function updateStrategyMaxDebtPerHarvest(address _strategy, uint256 _maxDebtPerHarvest) external {
        require(msg.sender == governance, "!governance");
        require(_strategies[_strategy].activation > 0, "must be a current strategy");
        require(_strategies[_strategy].minDebtPerHarvest <= _maxDebtPerHarvest, "cannot be lower than Strategy minDebtPerHarvest");

        _strategies[_strategy].maxDebtPerHarvest = _maxDebtPerHarvest;

        emit StrategyUpdateMaxDebtPerHarvest(_strategy, _maxDebtPerHarvest);
    }

    /**
     * @notice Change the fee the strategist will receive based on this Vault's performance
     * Can only be called by the current governor.
     * Can only be called on an active strategy (added using addStrategy)
     * @param _strategy Address of the strategy to update
     * @param _performanceFee The new fee the strategist will receive.
     */
    function updateStrategyPerformanceFee(address _strategy, uint256 _performanceFee) external {
        require(msg.sender == governance, "!governance");
        require(_strategies[_strategy].activation > 0, "must be a current strategy");
        require(_performanceFee <= MAX_BPS - performanceFee, "cannot exceed MAX_BPS after Vault performanceFee is deducted");

        _strategies[_strategy].performanceFee = _performanceFee;

        emit StrategyUpdatePerformanceFee(_strategy, _performanceFee);
    }

    /**
     * @notice Allows a user to deposit ETH into the Vault (becoming a Capital Provider)
     * Shares of the Vault (CP tokens) are minteed to caller
     * Called when Vault receives ETH
     * Deposits `_amount` `token`, issuing shares to `recipient`.
     * Reverts if Vault is in Emergency Shutdown
     */
    function deposit() public payable override {
        require(!emergencyShutdown, "cannot deposit when vault is in emergency shutdown");
        uint256 amount = msg.value;
        uint256 shares;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = (amount * totalSupply()) / _totalAssets();
        }

        // Issuance of shares needs to be done before taking the deposit
        _mint(msg.sender, shares);

        // Wrap the depositor's ETH to add WETH to the vault
        IWETH10(address(token)).deposit{value: amount}();

        emit DepositMade(msg.sender, amount, shares);
    }

    /**
     * @notice Allows a user to redeem shares for ETH
     * Burns CP tokens and transfers ETH to the CP
     * @param shares amount of shares to redeem
     * @return value in ETH that the shares where redeemed for
     */
    function withdraw(uint256 shares, uint256 maxLoss) external override returns (uint256) {

        require(shares <= balanceOf(msg.sender), "cannot redeem more shares than you own");

        uint256 value = _shareValue(shares);
        uint256 totalLoss;

        // Stop withdrawal if process brings the Vault's `totalAssets` value below minimum capital requirement
        require(_totalAssets() - value >= minCapitalRequirement, "withdrawal brings Vault assets below MCR");

        // If redeemable amount exceeds vaultBalance, withdraw funds from strategies in the withdrawal queue
        uint256 vaultBalance = token.balanceOf(address(this));

        if (value > vaultBalance) {

            for (uint256 i = 0; i < withdrawalQueue.length; i++) {

                // Break if we are done withdrawing from Strategies
                vaultBalance = token.balanceOf(address(this));
                if (value <= vaultBalance) {
                    break;
                }

                uint256 amountNeeded = value - vaultBalance;

                // Do not withdraw more than the Strategy's debt so that it can still work based on the profits it has
                if (_strategies[withdrawalQueue[i]].totalDebt < amountNeeded) {
                    amountNeeded = _strategies[withdrawalQueue[i]].totalDebt;
                }

                // if there is nothing to withdraw from this Strategy, move on to the next one
                if (amountNeeded == 0) continue;

                uint256 loss = IStrategy(withdrawalQueue[i]).withdraw(amountNeeded);
                uint256 withdrawn = token.balanceOf(address(this)) - vaultBalance;

                // Withdrawer incurs any losses from liquidation
                if (loss > 0) {
                    value -= loss;
                    totalLoss += loss;
                    _strategies[withdrawalQueue[i]].totalLoss += loss;
                }

                // Reduce the Strategy's debt by the amount withdrawn ("realized returns")
                // This doesn't add to returns as it's not earned by "normal means"
                _strategies[withdrawalQueue[i]].totalDebt -= withdrawn + loss;
                totalDebt -= withdrawn + loss;
            }
        }

        vaultBalance = token.balanceOf(address(this));

        if (vaultBalance < value) {
            value = vaultBalance;
            shares = _sharesForAmount(value + totalLoss);
        }

        // revert if losses from withdrawing are more than what is considered acceptable.
        assert(totalLoss <= maxLoss * (value + totalLoss) / MAX_BPS);

        // burn shares and transfer ETH to withdrawer
        _burn(msg.sender, shares);
        IWETH10(address(token)).withdraw(value);
        payable(msg.sender).transfer(value);

        emit WithdrawalMade(msg.sender, value);

        return value;
    }

    /**
     * @notice Reports the amount of assets the calling Strategy has free (usually in terms of ROI).
     * The performance fee is determined here, off of the strategy's profits (if any), and sent to governance.
     * The strategist's fee is also determined here (off of profits), to be handled according
     * to the strategist on the next harvest.
     * This may only be called by a Strategy managed by this Vault.
     * @dev For approved strategies, this is the most efficient behavior.
     * The Strategy reports back what it has free, then Vault "decides"
     * whether to take some back or give it more. Note that the most it can
     * take is `gain + _debtPayment`, and the most it can give is all of the
     * remaining reserves. Anything outside of those bounds is abnormal behavior.
     * All approved strategies must have increased diligence around
     * calling this function, as abnormal behavior could become catastrophic.
     * @param gain Amount Strategy has realized as a gain on it's investment since its
     * last report, and is free to be given back to Vault as earnings
     * @param loss Amount Strategy has realized as a loss on it's investment since its
     * last report, and should be accounted for on the Vault's balance sheet
     * @param _debtPayment Amount Strategy has made available to cover outstanding debt
     * @return Amount of debt outstanding (if totalDebt > debtLimit or emergency shutdown).
    */
    function report(uint256 gain, uint256 loss, uint256 _debtPayment) external override returns (uint256) {
        require(_strategies[msg.sender].activation > 0, "must be called by an active strategy");
        require(token.balanceOf(msg.sender) >= gain + _debtPayment, "need to have available tokens to withdraw");

        // Report loss before rest of calculations if possible
        if (loss > 0) _reportLoss(msg.sender, loss);

        // Assess both management fee and performance fee, and issue both as shares of the vault
        _assessFees(msg.sender, gain);

        // Returns are always "realized gains"
        _strategies[msg.sender].totalGain += gain;

        // Outstanding debt the Strategy wants to take back from the Vault (if any)
        // NOTE: debtOutstanding <= StrategyParams.totalDebt
        uint256 debt = _debtOutstanding(msg.sender);
        uint256 debtPayment;
        if (debt < _debtPayment) {
            debtPayment = debt;
        } else {
            debtPayment = _debtPayment;
        }

        if (debtPayment > 0) {
            _strategies[msg.sender].totalDebt -= debtPayment;
            totalDebt -= debtPayment;
            debt -= debtPayment; // `debt` is being tracked for later
        }

        // Compute the line of credit the Vault is able to offer the Strategy (if any)
        uint256 credit = _creditAvailable(msg.sender);

        // Update the actual debt based on the full credit we are extending to the Strategy
        // or the returns if we are taking funds back
        // NOTE: credit + _strategies[msg.sender].totalDebt is always < debtLimit
        // NOTE: At least one of `credit` or `debt` is always 0 (both can be 0)
        if (credit > 0) {
            _strategies[msg.sender].totalDebt += credit;
            totalDebt += credit;
        }

        // Give/take balance to Strategy, based on the difference between the reported gains
        // (if any), the debt payment (if any), the credit increase we are offering (if any),
        // and the debt needed to be paid off (if any)
        // NOTE: This is just used to adjust the balance of tokens between the Strategy and
        // the Vault based on the Strategy's debt limit (as well as the Vault's).
        uint256 totalAvail = gain + debtPayment;
        if (totalAvail < credit){  // credit surplus, give to Strategy
            SafeERC20.safeTransfer(token, msg.sender, credit - totalAvail);
        } else if (totalAvail > credit) {  // credit deficit, take from Strategy
            SafeERC20.safeTransferFrom(token, msg.sender, address(this), totalAvail - credit);
        }
        // else, don't do anything because it is balanced

        // Update cached value of delegated assets (used to properly account for mgmt fee in `_assessFees`)
        delegatedAssets -= _strategyDelegatedAssets[msg.sender];

        // NOTE: Take the min of totalDebt and delegatedAssets) to guard against improper computation
        uint256 strategyDelegatedAssets;
        if (_strategies[msg.sender].totalDebt < IStrategy(msg.sender).delegatedAssets()) {
            strategyDelegatedAssets = _strategies[msg.sender].totalDebt;
        } else {
            strategyDelegatedAssets = IStrategy(msg.sender).delegatedAssets();
        }
        delegatedAssets += strategyDelegatedAssets;
        _strategyDelegatedAssets[msg.sender] = delegatedAssets;

        // Update reporting time
        _strategies[msg.sender].lastReport = block.timestamp;
        lastReport = block.timestamp;
        // profit is locked and gradually released per block
        lockedProfit = gain;

        emit StrategyReported(
            msg.sender,
            gain,
            loss,
            debtPayment,
            _strategies[msg.sender].totalGain,
            _strategies[msg.sender].totalLoss,
            _strategies[msg.sender].totalDebt,
            credit,
            _strategies[msg.sender].debtRatio
        );

        if (_strategies[msg.sender].debtRatio == 0 || emergencyShutdown) {
            // Take every last penny the Strategy has (Emergency Exit/revokeStrategy)
            // NOTE: This is different than `debt` in order to extract *all* of the returns
            return IStrategy(msg.sender).estimatedTotalAssets();
        } else {
            // Otherwise, just return what we have as debt outstanding
            return debt;
        }
    }

    /*************
    EXTERNAL VIEW FUNCTIONS
    *************/

    /**
     * @notice Amount of tokens in Vault a Strategy has access to as a credit line.
     * Check the Strategy's debt limit, as well as the tokens available in the Vault,
     * and determine the maximum amount of tokens (if any) the Strategy may draw on.
     * In the rare case the Vault is in emergency shutdown this will return 0.
     * @param strategy The Strategy to check. Defaults to caller.
     * @return The quantity of tokens available for the Strategy to draw on.
     */
    function creditAvailable(address strategy) external view returns (uint256) {
        return _creditAvailable(strategy);
    }

    /**
    * @notice Provide an accurate expected value for the return this `strategy`
    * would provide to the Vault the next time `report()` is called
    * (since the last time it was called).
    * @param strategy The Strategy to determine the expected return for. Defaults to caller.
    * @return The anticipated amount `strategy` should make on its investment
    * since its last report.
    */
    function expectedReturn(address strategy) external view returns (uint256) {
        _expectedReturn(strategy);
    }

    /**
    * @notice Returns the maximum redeemable shares by the `user` such that Vault does not go under MCR
    * @param user Address of user to check
    * @return Max redeemable shares by the user
    */
    function maxRedeemableShares(address user) external view returns (uint256) {
        uint256 userBalance = balanceOf(user);
        uint256 vaultBalanceAfterWithdraw = _totalAssets() - _shareValue(userBalance);

        // if user's CP token balance takes Vault `totalAssets` below MCP,
        //... return the difference between totalAsset and MCP (in # shares)
        if (vaultBalanceAfterWithdraw < minCapitalRequirement) {
            uint256 diff = _totalAssets() - minCapitalRequirement;
            return _sharesForAmount(_shareValue(diff));
        } else {
            // else, user can withdraw up to their balance of CP tokens
            return userBalance;
        }
    }

    /**
     * @notice Returns the total quantity of all assets under control of this
        Vault, including those loaned out to a Strategy as well as those currently
        held in the Vault.
     * @return The total assets under control of this vault.
    */
    function totalAssets() external view returns (uint256) {
        return _totalAssets();
    }

    /**
     * @notice Determines if `strategy` is past its debt limit and if any tokens
     * should be withdrawn to the Vault.
     * @param strategy The Strategy to check. Defaults to the caller.
     * @return The quantity of tokens to withdraw.
    */
    function debtOutstanding(address strategy) external view override returns (uint256) {
        return _debtOutstanding(strategy);
    }

    /*************
    INTERNAL FUNCTIONS
    *************/

    function _revokeStrategy(address strategy) internal {
        debtRatio -= _strategies[strategy].debtRatio;
        _strategies[strategy].debtRatio = 0;
        emit StrategyRevoked(strategy);
    }

    function _reportLoss(address strategy, uint256 loss) internal {
        uint256 strategyTotalDebt = _strategies[strategy].totalDebt;
        require(strategyTotalDebt >= loss, "loss can only be up the amount of debt issued to strategy");
        _strategies[strategy].totalLoss += loss;
        _strategies[strategy].totalDebt = strategyTotalDebt - loss;
        totalDebt -= loss;

        // Also, make sure we reduce our trust with the strategy by the same amount
        uint256 strategyDebtRatio = _strategies[strategy].debtRatio;

        uint256 ratioChange;

        if (loss * MAX_BPS / _totalAssets() < strategyDebtRatio) {
            ratioChange = loss * MAX_BPS / _totalAssets();
        } else {
            ratioChange = strategyDebtRatio;
        }
        _strategies[strategy].debtRatio -= ratioChange;
        debtRatio -= ratioChange;
    }

    /**
     * @notice Issue new shares to cover fees
     * In effect, this reduces overall share price by the combined fee
     * may throw if Vault.totalAssets() > 1e64, or not called for more than a year
     */
    function _assessFees(address strategy, uint256 gain) internal {
        uint256 governanceFee = (
            (
                (totalDebt - delegatedAssets)
                * (block.timestamp - lastReport)
                * managementFee
            )
            / MAX_BPS
            / SECS_PER_YEAR
        );

        // Strategist fee only applies in certain conditions
        uint256 strategistFee = 0;

        // NOTE: Applies if Strategy is not shutting down, or it is but all debt paid off
        // NOTE: No fee is taken when a Strategy is unwinding it's position, until all debt is paid
        if (gain > 0) {
            // NOTE: Unlikely to throw unless strategy reports >1e72 harvest profit
            strategistFee = (gain * _strategies[strategy].performanceFee) / MAX_BPS;
            governanceFee += gain * performanceFee / MAX_BPS;
        }

        // NOTE: This must be called prior to taking new collateral, or the calculation will be wrong!
        // NOTE: This must be done at the same time, to ensure the relative ratio of governance_fee : strategist_fee is kept intact
        uint256 totalFee = governanceFee + strategistFee;

        if (totalFee > 0) {
            // issue shares as reward
            uint256 reward;
            if (totalSupply() == 0) {
                reward = totalFee;
            } else {
                reward = (totalFee * totalSupply()) / _totalAssets();
            }

            // Issuance of shares needs to be done before taking the deposit
            _mint(address(this), reward);

            // Send the rewards out as new shares in this Vault
            if (strategistFee > 0) {
                // NOTE: Unlikely to throw unless sqrt(reward) >>> 1e39
                uint256 strategistReward = (strategistFee * reward) / totalFee;
                _transfer(address(this), strategy, strategistReward);
                // NOTE: Strategy distributes rewards at the end of harvest()
            }

            // Governance earns any dust leftovers from flooring math above
            if (balanceOf(address(this)) > 0) {
                _transfer(address(this), rewards, balanceOf(address(this)));
            }
        }
    }

    /*************
    INTERNAL VIEW FUNCTIONS
    *************/

    /**
     * @notice Quantity of all assets under control of this Vault, including those loaned out to Strategies
     */
    function _totalAssets() internal view returns (uint256) {
        return token.balanceOf(address(this)) + totalDebt;
    }

    function _creditAvailable(address _strategy) internal view returns (uint256) {
        if (emergencyShutdown) return 0;

        uint256 vaultTotalAssets = _totalAssets();
        uint256 vaultDebtLimit = (debtRatio * vaultTotalAssets) / MAX_BPS;
        uint256 strategyDebtLimit = (_strategies[_strategy].debtRatio * vaultTotalAssets) / MAX_BPS;

        // No credit available to issue if credit line has been exhasted
        if (vaultDebtLimit <= totalDebt || strategyDebtLimit <= _strategies[_strategy].totalDebt) return 0;

        uint256 available = strategyDebtLimit - _strategies[_strategy].totalDebt;

        // Adjust by the global debt limit left
        if (vaultDebtLimit - totalDebt < available) available = vaultDebtLimit - totalDebt;

        // Can only borrow up to what the contract has in reserve
        if (token.balanceOf(address(this)) < available) available = token.balanceOf(address(this));

        if (available < _strategies[_strategy].minDebtPerHarvest) return 0;

        if (_strategies[_strategy].maxDebtPerHarvest < available) return _strategies[_strategy].maxDebtPerHarvest;

        return available;
    }

    function _expectedReturn(address strategy) internal view returns (uint256) {
        uint256 strategyLastReport = _strategies[strategy].lastReport;
        uint256 timeSinceLastHarvest = block.timestamp - strategyLastReport;
        uint256 totalHarvestTime = strategyLastReport - _strategies[strategy].activation;

        // NOTE: If either `timeSinceLastHarvest` or `totalHarvestTime` is 0, we can short-circuit to `0`
        if (timeSinceLastHarvest > 0 && totalHarvestTime > 0 && IStrategy(strategy).isActive()) {
            // NOTE: Unlikely to throw unless strategy accumalates >1e68 returns
            // NOTE: Calculate average over period of time where harvests have occured in the past
            return (_strategies[strategy].totalGain * timeSinceLastHarvest) / totalHarvestTime;
        } else {
            // Covers the scenario when block.timestamp == activation
            return 0;
        }
    }

    /**
     * @notice Determines the current value of `shares`
     * @param shares amount of shares to calculate value for.
     */
    function _shareValue(uint256 shares) internal view returns (uint256) {

        // If sqrt(Vault.totalAssets()) >>> 1e39, this could potentially revert
        uint256 lockedFundsRatio = (block.timestamp - lastReport) * lockedProfitDegration;
        uint256 freeFunds = _totalAssets();

        if (lockedFundsRatio < DEGREDATION_COEFFICIENT) {
            freeFunds -= (lockedProfit - (lockedFundsRatio * lockedProfit / DEGREDATION_COEFFICIENT));
        }

        // using 1e3 for extra precision here when decimals is low
        return ((10 ** 3 * (shares * freeFunds)) / totalSupply()) / 10 ** 3;
    }

    /**
     * @notice Determines how many shares `amount` of token would receive.
     * @param amount of tokens to calculate number of shares for
     */
    function _sharesForAmount(uint256 amount) internal view returns (uint256) {
        if (_totalAssets() > 0) {
            // NOTE: if sqrt(token.totalSupply()) > 1e37, this could potentially revert
            return ((10 ** 3 * (amount * totalSupply())) / _totalAssets()) / 10 ** 3;
        } else {
            return 0;
        }
    }

    function _debtOutstanding(address strategy) internal view returns (uint256) {
        uint256 strategyDebtLimit = _strategies[strategy].debtRatio * _totalAssets() / MAX_BPS;
        uint256 strategyTotalDebt = _strategies[strategy].totalDebt;

        if (emergencyShutdown) {
            return strategyTotalDebt;
        } else if (strategyTotalDebt <= strategyDebtLimit) {
            return 0;
        } else {
            return strategyTotalDebt - strategyDebtLimit;
        }
    }

    /**
     * @notice Fallback function to allow contract to receive ETH
     * Mints CP tokens to caller if caller is not Vault or WETH
     */
    receive() external payable {
        if (msg.sender != address(token)) {
            deposit();
        }
    }

}