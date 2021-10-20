// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;
/* solhint-disable not-rely-on-time, reason-string, func-name-mixedcase, var-name-mixedcase */

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { EIP712 } from "../libraries/EIP712.sol";
import { EIP2612 } from "../libraries/EIP2612.sol";
import { EIP3009 } from "../libraries/EIP3009.sol";
import { IJollyRoger } from "../interfaces/IJollyRoger.sol";

/*
                 _.--""""''-.
              .-'            '.
            .'                 '.
           /            .        )
          |                   _  (
          |          .       / \  \
          \         .     .  \_/  |
           \    .--' .  '         /
            \  /  .'____ _       /,
             '/   (\    `)\       |
             ||\__||    |;-.-.-,-,|
             \\___//|   \--'-'-'-'|
        🏴‍☠🦜  '---' \             |
       .--.           '---------.__)  .-.
      .'   \                         /  '.
     (      '.                    _.'     )
      '---.   '.              _.-'    .--'
           `.   `-._      _.-'   _.-'`
             `-._   '-.,-'   _.-'
                 `-._   `'.-'
               _.-'` `;.   '-._
        .--.-'`  _.-'`  `'-._  `'-.--.
       (       .'            '.       )
        `,  _.'                '._  ,'
          ``                      ``
*/
/**
 * @title JollyRoger (🏴‍☠)
 * @author 0xBlackbeard
 * @notice PirateDAO governance token
 * @dev ERC-20 with supply and metadata controls, plus add-ons for off-chain signatures ops (see EIPs: 712, 2612, 3009)
 */
contract JollyRoger is EIP712, EIP2612, EIP3009, IJollyRoger {
	uint256 private _totalSupply;
	uint256 private _maximumSupply = 818e18;

	mapping(address => uint256) private _balances;
	mapping(address => mapping(address => uint256)) private _allowances;

	string public override name = "PirateDAO Governance Token";
	string public override symbol = unicode"🏴‍☠️";

	address public override supplyManager;
	address public override metadataManager;

	uint32 public override supplyFreeze = 80 days;
	uint32 public immutable override supplyFreezeMinimum = 2 days;

	uint256 public override supplyFreezeEnds;
	uint256 public immutable override supplyGrowthMaximum = _maximumSupply / 4;

	/**
	 * @notice Constructs the JollyRoger token
	 * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
	 *
	 * @param _metadataManager The address with the ability to change token metadata
	 * @param _supplyManager The address with the ability to regulate supply and mint new tokens
	 */
	constructor(address _metadataManager, address _supplyManager) EIP712(name, "1") {
		require(_metadataManager != address(0), "JollyRoger::constructor: MM cannot be the zero address at deployment");
		require(_supplyManager != address(0), "JollyRoger::constructor: SM cannot be the zero address at deployment");

		supplyManager = _supplyManager;
		emit SupplyManagerChanged(address(0), supplyManager);

		metadataManager = _metadataManager;
		emit MetadataManagerChanged(address(0), metadataManager);

		supplyFreezeEnds = block.timestamp + supplyFreeze;
	}

	/**
	 * @dev See {IERC20Metadata-decimals}
	 */
	function decimals() external pure override returns (uint8) {
		return 18;
	}

	/**
	 * @dev See {IERC20-totalSupply}
	 */
	function totalSupply() external view override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev Maximum amount of token units allowed to exist
	 */
	function maximumSupply() external view override returns (uint256) {
		return _maximumSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}
	 */
	function balanceOf(address account) external view override returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev The maximum amount of mintable tokens left before hitting `maximumSupply`
	 */
	function mintable() external view override returns (uint256) {
		return _maximumSupply - _totalSupply;
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-allowance}
	 */
	function allowance(address owner, address spender) external view override returns (uint256) {
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * Requirements:
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 amount) external override returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance (not required by the ERC20 standard).
	 *
	 * Requirements:
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external override returns (bool) {
		address spender = msg.sender;
		uint256 spenderAllowance = _allowances[sender][spender];

		if (spender != sender && spenderAllowance != type(uint256).max) {
			require(spenderAllowance >= amount, "JollyRoger::transferFrom: amount exceeds allowance");
			unchecked {
				_approve(sender, spender, spenderAllowance - amount);
			}
		}

		_transfer(sender, recipient, amount);

		return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 * - `spender` cannot be the zero address.
	 *
	 * @param spender Spender's address
	 * @param addedAmount Amount of increase in allowance
	 * @return Boolean flag indicating success
	 */
	function increaseAllowance(address spender, uint256 addedAmount) external override returns (bool) {
		_approve(msg.sender, spender, _allowances[msg.sender][spender] + addedAmount);
		return true;
	}

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least `subtractedAmount`.
	 *
	 * @param spender Spender's address
	 * @param subtractedAmount Amount of decrease in allowance
	 * @return Boolean flag indicating success
	 */
	function decreaseAllowance(address spender, uint256 subtractedAmount) external override returns (bool) {
		uint256 spenderAllowance = _allowances[msg.sender][spender];
		require(spenderAllowance >= subtractedAmount, "JollyRoger::decreaseAllowance: allowance below zero");

		unchecked {
			_approve(msg.sender, spender, spenderAllowance - subtractedAmount);
		}

		return true;
	}

	/**
	 * @notice Updates allowance with a signed permit
	 *
	 * @param owner     Owner's address (Authorizer)
	 * @param spender   Spender's address
	 * @param value     Amount of allowance
	 * @param deadline  The time at which this expires (unix time)
	 * @param v 		The recovery byte of the signature
	 * @param r 		Half of the ECDSA signature pair
	 * @param s 		Half of the ECDSA signature pair
	 */
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external override(EIP2612, IJollyRoger) {
		require(block.timestamp <= deadline, "JollyRoger::permit: expired deadline");

		bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));
		bytes32 typedDataHash = _hashTypedDataV4(structHash);
		address signer = ECDSA.recover(typedDataHash, v, r, s);
		require(signer == owner, "JollyRoger::permit: invalid signature");

		_approve(owner, spender, value);
	}

	/**
	 * @notice Mints new tokens
	 * @param dst The recipient address
	 * @param amount The number of tokens to be minted
	 * @return Boolean flag indicating success of mint op
	 */
	function mint(address dst, uint256 amount) external override returns (bool) {
		require(msg.sender == supplyManager, "JollyRoger::mint: only SM can mint");
		require(amount > 0, "JollyRoger::mint: zero mint");
		require(_totalSupply + amount <= _maximumSupply, "JollyRoger::mint: max supply reached");

		_mint(dst, amount);

		return true;
	}

	/**
	 * @notice Burns tokens
	 * @param src The address from which tokens will be burnt
	 * @param amount The number of tokens to be burned
	 * @return Boolean flag indicating success of burn op
	 */
	function burn(address src, uint256 amount) external override returns (bool) {
		require(amount > 0, "JollyRoger::burn: zero burn");

		address spender = msg.sender;
		uint256 spenderAllowance = _allowances[src][spender];

		if (spender != src && spenderAllowance != type(uint256).max) {
			require(spenderAllowance >= amount, "JollyRoger::burn: amount exceeds allowance");
			unchecked {
				_approve(src, spender, spenderAllowance - amount);
			}
		}

		_burn(src, amount);

		return true;
	}

	/**
	 * @notice Changes the supply manager address. The supply manager can also be permanently removed here
	 * @param newSupplyManager The address of the new supply manager
	 * @return true if successful
	 */
	function setSupplyManager(address newSupplyManager) external override returns (bool) {
		require(msg.sender == supplyManager, "JollyRoger::setSupplyManager: only SM can change SM");
		require(newSupplyManager != supplyManager, "JollyRoger::setSupplyManager: new SM must differ from current SM");

		emit SupplyManagerChanged(supplyManager, newSupplyManager);
		supplyManager = newSupplyManager;

		return true;
	}

	/**
	 * @notice Changes the metadata manager address. The metadata manager can also be permanently removed here
	 * @param newMetadataManager The address of the new metadata manager
	 * @return true if successful
	 */
	function setMetadataManager(address newMetadataManager) external override returns (bool) {
		require(msg.sender == metadataManager, "JollyRoger::setMetadataManager: only MM can change MM");
		require(
			newMetadataManager != metadataManager,
			"JollyRoger::setMetadataManager: new MM must differ from current MM"
		);

		emit MetadataManagerChanged(metadataManager, newMetadataManager);
		metadataManager = newMetadataManager;

		return true;
	}

	/**
	 * @notice Set the maximum amount of tokens that will be able to exist
	 * @param newMaxSupply The new maximum supply
	 * @return true if successful
	 */
	function setMaximumSupply(uint256 newMaxSupply) external override returns (bool) {
		require(msg.sender == supplyManager, "JollyRoger::setMaximumSupply: only SM can change max supply");
		require(
			newMaxSupply <= _maximumSupply + supplyGrowthMaximum,
			"JollyRoger::setMaximumSupply: illegal max supply growth"
		);
		require(newMaxSupply > 0, "JollyRoger::setMaximumSupply: max supply cannot be 0");

		emit MaxSupplyChanged(_maximumSupply, newMaxSupply);
		_maximumSupply = newMaxSupply;

		supplyFreezeEnds = block.timestamp + supplyFreeze;

		return true;
	}

	/**
	 * @notice Sets the minimum time between supply changes
	 * @param newFreeze The new supply change waiting window
	 * @return true if successful
	 */
	function setSupplyFreeze(uint32 newFreeze) external override returns (bool) {
		require(msg.sender == supplyManager, "JollyRoger::setSupplyFreeze: only SM can change freeze period");
		require(newFreeze >= supplyFreezeMinimum, "JollyRoger::setSupplyFreeze: freeze period must be > minimum");

		emit SupplyFreezeChanged(supplyFreeze, newFreeze);
		supplyFreeze = newFreeze;

		return true;
	}

	/**
	 * @notice Update the token name and symbol
	 * @param _name The new name for the token
	 * @param _symbol The new symbol for the token
	 * @return true if successful
	 */
	function updateTokenMetadata(string memory _name, string memory _symbol) external override returns (bool) {
		require(msg.sender == metadataManager, "JollyRoger::updateTokenMetadata: only MM can update token metadata");
		require(
			keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked(name)) ||
				keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked(symbol)),
			"JollyRoger::updateTokenMetadata: new name or symbol must differ"
		);

		name = _name;
		symbol = _symbol;
		emit TokenMetadataUpdated(name, symbol);

		return true;
	}

	/**
	 * @dev Moves `amount` of tokens from `sender` to `recipient`.
	 *
	 * This internal function is equivalent to {transfer}, and can be used to implement token fees, slashing, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 *
	 * @param sender The address which owns the tokens to be transferred
	 * @param recipient The address which is receiving tokens
	 * @param amount The number of tokens that are being transferred
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal {
		require(sender != address(0), "JollyRoger::_transfer: transfer from the zero address");
		require(recipient != address(0), "JollyRoger::_transfer: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "JollyRoger::_transfer: transfer amount exceeds balance");

		unchecked {
			_balances[sender] = senderBalance - amount;
		}

		_balances[recipient] += amount;
		emit Transfer(sender, recipient, amount);

		_afterTokenTransfer(sender, recipient, amount);
	}

	/**
	 * @dev See {EIP3009-transferWithAuthorization} and {EIP3009-receiveWithAuthorization}.
	 */
	function _transferWithAuth(
		bytes32 typeHash,
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal override {
		require(block.timestamp > validAfter, "JollyRoger::transferWithAuth: authorization not yet valid");
		require(block.timestamp < validBefore, "JollyRoger::transferWithAuth: authorization expired");
		require(!_authorizations[from][nonce], "JollyRoger::transferWithAuth: authorization spent");

		bytes32 structHash = keccak256(abi.encode(typeHash, from, to, value, validAfter, validBefore, nonce));
		bytes32 typedDataHash = _hashTypedDataV4(structHash);
		address signer = ECDSA.recover(typedDataHash, v, r, s);
		require(from == signer, "JollyRoger::transferWithAuthorization: invalid signature");

		_authorizations[from][nonce] = true;
		emit AuthorizationUsed(from, nonce);

		_transfer(from, to, value);
	}

	/**
	 * @dev Creates `amount` tokens and assigns them to `to`, increasing the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements:
	 * - `to` cannot be the zero address.
	 *
	 * @param to The address which is receiving tokens
	 * @param amount The number of tokens that are being minted
	 */
	function _mint(address to, uint256 amount) internal {
		require(to != address(0), "JollyRoger::_mint: mint to the zero address");

		_beforeTokenTransfer(address(0), to, amount);

		_totalSupply += amount;
		_balances[to] += amount;
		emit Transfer(address(0), to, amount);

		_afterTokenTransfer(address(0), to, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `from`, reducing the total supply.
	 *
	 * Emits a {Transfer} event, with `to` set to the zero address.
	 *
	 * Requirements:
	 * - `from` cannot be the zero address.
	 * - `from` must have at least `amount` tokens.
	 *
	 * @param from The address which owns the tokens that will be burnt
	 * @param amount The number of tokens that are being burned
	 */
	function _burn(address from, uint256 amount) internal {
		require(from != address(0), "JollyRoger::_burn: burn from the zero address");

		_beforeTokenTransfer(from, address(0), amount);

		uint256 accountBalance = _balances[from];
		require(accountBalance >= amount, "JollyRoger::_burn: amount exceeds balance");

		unchecked {
			_balances[from] = accountBalance - amount;
		}

		_totalSupply -= amount;
		emit Transfer(from, address(0), amount);

		_afterTokenTransfer(from, address(0), amount);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
	 *
	 * This internal function is equivalent to `approve`, and can be used to, e.g., set automatic allowances
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 *
	 * @param owner The address which owns the tokens to be approved
	 * @param spender The address which will be approved to transfer or burn tokens
	 * @param amount The number of tokens that are approved (2^256-1 means infinite)
	 */
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal {
		require(owner != address(0), "JollyRoger::_approve: approve from the zero address");
		require(spender != address(0), "JollyRoger::_approve: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Hook that is called before any transfer of tokens. This includes minting and burning.
	 *
	 * Calling conditions:
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens will be transferred to `to`.
	 * - when `from` is zero, `amount` tokens will be minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
	 * - when `from` and `to` are never both zero.
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal pure {} // solhint-disable-line no-empty-blocks

	/**
	 * @dev Hook that is called after any transfer of tokens. This includes minting and burning.
	 *
	 * Calling conditions:
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens has been transferred to `to`
	 * - when `from` is zero, `amount` tokens have been minted for `to`
	 * - when `to` is zero, `amount` of ``from``'s tokens have been burned
	 * - when `from` and `to` are never both zero
	 */
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal pure {} // solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by this JSON-RPC method:
 * https://docs.metamask.io/guide/signing-data.html (`eth_signTypedDataV4` in MetaMask).
 */
abstract contract EIP712 {
	/* solhint-disable var-name-mixedcase */
	bytes32 private immutable _DOMAIN_TYPEHASH =
		keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

	// Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
	// invalidate the cached domain separator if the chain id changes.
	bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
	uint256 private immutable _CACHED_CHAIN_ID;
	bytes32 private immutable _HASHED_NAME;
	bytes32 private immutable _HASHED_VERSION;

	/* solhint-enable var-name-mixedcase */

	/**
	 * @dev Initializes the domain separator and parameter caches. These parameters cannot be changed.
	 *
	 * The meaning of `name` and `version` is specified in https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator:
	 * - `name`: the user readable name of the signing domain, i.e. a dApp or protocol name.
	 * - `version`: the current major version of the signing domain.
	 */
	constructor(string memory name, string memory version) {
		bytes32 hashedName = keccak256(bytes(name));
		bytes32 hashedVersion = keccak256(bytes(version));
		bytes32 domainTypeHash = keccak256(
			"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
		);

		_HASHED_NAME = hashedName;
		_HASHED_VERSION = hashedVersion;
		_CACHED_CHAIN_ID = block.chainid;
		_CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(domainTypeHash, hashedName, hashedVersion);
	}

	/**
	 * @dev Returns the domain separator for the current chain.
	 */
	function _domainSeparatorV4() internal view returns (bytes32) {
		if (block.chainid == _CACHED_CHAIN_ID) {
			return _CACHED_DOMAIN_SEPARATOR;
		} else {
			return _buildDomainSeparator(_DOMAIN_TYPEHASH, _HASHED_NAME, _HASHED_VERSION);
		}
	}

	function _buildDomainSeparator(
		bytes32 typeHash,
		bytes32 nameHash,
		bytes32 versionHash
	) private view returns (bytes32) {
		return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
	}

	/**
	 * @dev Given an hashed struct (https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct), this function
	 * returns the hash of the fully encoded EIP712 message for this domain.
	 *
	 * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
	 * ```solidity
	 * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
	 *     keccak256("Mail(address to,string contents)"),
	 *     mailTo,
	 *     keccak256(bytes(mailContents))
	 * )));
	 * address signer = ECDSA.recover(digest, signature);
	 * ```
	 */
	function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
		return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
	}

	/**
	 * @dev Returns the domain separator used in the encoding of signatures as defined by {EIP712}.
	 */
	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() external view returns (bytes32) {
		return _domainSeparatorV4();
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev A middleware contract abstracting EIP2612 which allows for approvals to be made via secp256k1 signatures.
 *
 * This kind of “account abstraction for ERC-20” brings about two main benefits:
 *  - transactions involving ERC-20 operations can be paid using the token itself rather than ETH
 *  - approve and pull operations can happen atomically in a single transaction instead of two consecutive transactions
 */
abstract contract EIP2612 {
	using Counters for Counters.Counter;

	mapping(address => Counters.Counter) internal _nonces;

	/// @dev The EIP-712 typehash for permit (EIP-2612)
	// solhint-disable-next-line var-name-mixedcase
	bytes32 internal immutable _PERMIT_TYPEHASH =
		keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

	/**
	 * @notice Updates allowance with a signed permit
	 * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens, given ``owner``'s signed approval.
	 *
	 * IMPORTANT: The same issues {IERC20-approve} has related to transaction ordering also apply here.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 * - `spender` cannot be the zero address.
	 * - `deadline` must be a timestamp in the future.
	 * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
	 * - the signature must use ``owner``'s current nonce (see {nonces}).
	 *
	 * For more information on the signature format, see: https://eips.ethereum.org/EIPS/eip-2612#specification
	 */
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external virtual;

	/**
	 * @dev Returns the current nonce for `owner`. This value must be included whenever a new signature is generated
	 *
	 * Every successful call to `permit` increases ``owner``'s nonce by one. This prevents signature reuse.
	 */
	function nonces(address owner) external view returns (uint256) {
		return _nonces[owner].current();
	}

	/**
	 * @dev "Consume a nonce"
	 * @return currentNonce The current value with increment
	 */
	function _useNonce(address owner) internal returns (uint256 currentNonce) {
		Counters.Counter storage nonce = _nonces[owner];
		currentNonce = nonce.current();
		nonce.increment();
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev A middleware containing a set of functions to enable meta-transactions and atomic interactions with ERC-20
 * token contracts via signatures conforming to the EIP-712 typed message signing specification.
 *
 * This enables the user to:
 * - delegate the gas payment to someone else,
 * - pay for gas in the token itself rather than in ETH,
 * - perform one or more token transfers and other operations in a single atomic transaction,
 * - transfer ERC-20 tokens to another address, and have the recipient submit the transaction,
 * - batch multiple transactions with minimal overhead, and
 * - perform multiple txs without worrying about tx failures due to nonce-reuse or improper tx ordering
 */
abstract contract EIP3009 is Context {
	event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

	mapping(address => mapping(bytes32 => bool)) internal _authorizations;

	/// @notice The EIP-712 typehash for transferWithAuthorization (EIP-3009)
	// solhint-disable-next-line var-name-mixedcase
	bytes32 internal immutable _TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
		keccak256(
			"TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
		);

	/// @notice The EIP-712 typehash for receiveWithAuthorization (EIP-3009)
	// solhint-disable-next-line var-name-mixedcase
	bytes32 internal immutable _RECEIVE_WITH_AUTHORIZATION_TYPEHASH =
		keccak256(
			"ReceiveWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)"
		);

	/**
	 * @notice Returns the state of an authorization
	 * @dev Nonces are randomly generated 32-byte data sequences unique to the authorizer's address
	 *
	 * @param authorizer The authorizer's address
	 * @param nonce A nonce for the authorization
	 * @return True if the nonce is used
	 */
	function authorizationState(address authorizer, bytes32 nonce) external view returns (bool) {
		return _authorizations[authorizer][nonce];
	}

	/**
	 * @notice Executes a transfer with a signed authorization
	 *
	 * @param from          Sender's address (authorizer)
	 * @param to            Recipient's address
	 * @param value         Amount to be transferred
	 * @param validAfter    The time after which this is valid (unix time)
	 * @param validBefore   The time before which this is valid (unix time)
	 * @param n         	A unique number used once
	 * @param v 			The recovery byte of the signature
	 * @param r 			Half of the ECDSA signature pair
	 * @param s 			Half of the ECDSA signature pair
	 */
	function transferWithAuthorization(
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 n,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		_transferWithAuth(_TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, n, v, r, s);
	}

	/**
	 * @notice Receives a transfer with a signed authorization from the sender (authorizer)
	 * @dev With an additional check to match the recipient address against the caller to prevent front-running attacks
	 *
	 * @param from          Sender's address (authorizer)
	 * @param to            Recipient's address
	 * @param value         Amount to be transferred
	 * @param validAfter    The time after which this is valid (unix time)
	 * @param validBefore   The time before which this is valid (unix time)
	 * @param n         	A unique number used once
	 * @param v 			The recovery byte of the signature
	 * @param r 			Half of the ECDSA signature pair
	 * @param s 			Half of the ECDSA signature pair
	 */
	function receiveWithAuthorization(
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 n,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		require(to == _msgSender(), "EIP3009::receiveWithAuth: caller must be the recipient"); // solhint-disable-line reason-string

		_transferWithAuth(_RECEIVE_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, n, v, r, s);
	}

	function _transferWithAuth(
		bytes32 typeHash,
		address from,
		address to,
		uint256 value,
		uint256 validAfter,
		uint256 validBefore,
		bytes32 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IJollyRoger is IERC20, IERC20Metadata {
	/// @notice An event that's emitted when the token maximum supply cap is changed
	event MaxSupplyChanged(uint256 indexed oldMaxSupply, uint256 indexed newMaxSupply);

	/// @notice An event that's emitted when the token supply change freeze period is changed
	event SupplyFreezeChanged(uint32 oldFreeze, uint32 indexed newFreeze);

	/// @notice An event that's emitted when the token metadata is updated
	event TokenMetadataUpdated(string indexed newName, string indexed newSymbol);

	/// @notice An event that's emitted when the token metadata manager is changed
	event MetadataManagerChanged(address indexed oldMM, address indexed newMM);

	/// @notice An event that's emitted when the token supply manager is changed
	event SupplyManagerChanged(address indexed oldSM, address indexed newSM);

	function maximumSupply() external view returns (uint256);

	function mintable() external view returns (uint256);

	function mint(address dst, uint256 amount) external returns (bool);

	function burn(address src, uint256 amount) external returns (bool);

	function increaseAllowance(address spender, uint256 amount) external returns (bool);

	function decreaseAllowance(address spender, uint256 amount) external returns (bool);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function metadataManager() external view returns (address);

	function updateTokenMetadata(string memory tokenName, string memory tokenSymbol) external returns (bool);

	function supplyManager() external view returns (address);

	function supplyFreezeEnds() external view returns (uint256);

	function supplyFreeze() external view returns (uint32);

	function supplyFreezeMinimum() external view returns (uint32);

	function supplyGrowthMaximum() external view returns (uint256);

	function setSupplyManager(address newSupplyManager) external returns (bool);

	function setMetadataManager(address newMetadataManager) external returns (bool);

	function setSupplyFreeze(uint32 period) external returns (bool);

	function setMaximumSupply(uint256 newMaxSupply) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}