// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { VanillaV1Converter } from "./VanillaV1Migration01.sol";
import "./interfaces/IVanillaV1Token02.sol";
import "./interfaces/v1/VanillaV1Token01.sol";

/**
 @title Governance Token for Vanilla Finance.
 */
contract VanillaV1Token02 is ERC20("Vanilla", "VNL"), VanillaV1Converter, IVanillaV1Token02 {
    string private constant _ERROR_ACCESS_DENIED = "c1";
    address private immutable _owner;

    /**
        @notice Deploys the token and sets the caller as an owner.
     */
    constructor(IVanillaV1MigrationState _migrationState, address _vnlAddress) VanillaV1Converter(_migrationState, IERC20(_vnlAddress)) {
        _owner = msg.sender;
    }

    /**
        @dev set the decimals explicitly to 12, for (theoretical maximum of) VNL reward of a 1ETH of profit should be displayed as 1000000VNL (18-6 = 12 decimals).
     */
    function decimals() public pure override returns (uint8) {
        return 12;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, _ERROR_ACCESS_DENIED);
        _;
    }

    function mintConverted(address target, uint256 amount) internal override {
        _mint(target, amount);
    }

    /**
        @notice Mints the tokens. Used only by the VanillaRouter-contract.

        @param to The recipient address of the minted tokens
        @param tradeReward The amount of tokens to be minted
     */
    function mint(address to, uint256 tradeReward) external override onlyOwner {
        _mint(to, tradeReward);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVanillaV1MigrationState, IVanillaV1Converter} from "./interfaces/IVanillaV1Migration01.sol";

/// @title The contract keeping the record of VNL v1 -> v1.1 migration state
contract VanillaV1MigrationState is IVanillaV1MigrationState {

    address private immutable owner;

    /// @inheritdoc IVanillaV1MigrationState
    bytes32 public override stateRoot;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override blockNumber;

    /// @inheritdoc IVanillaV1MigrationState
    uint64 public override conversionDeadline;

    /// @dev the conversion deadline is initialized to 30 days from the deployment
    /// @param migrationOwner The address of the owner of migration state
    constructor(address migrationOwner) {
        owner = migrationOwner;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert UnauthorizedAccess();
        }
        _;
    }

    modifier beforeDeadline() {
        if (block.timestamp >= conversionDeadline) {
            revert MigrationStateUpdateDisabled();
        }
        _;
    }

    /// @inheritdoc IVanillaV1MigrationState
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) onlyOwner beforeDeadline external override {
        stateRoot = newStateRoot;
        blockNumber = blockNum;
        conversionDeadline = uint64(block.timestamp + 30 days);
    }

    /// @inheritdoc IVanillaV1MigrationState
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view override returns (bool) {
        // deliberately using encodePacked with a delimiter string to resolve ambiguity and let client implementations be simpler
        bytes32 leafInTree = keccak256(abi.encodePacked(tokenOwner, ":", amount));
        return block.timestamp < conversionDeadline && MerkleProof.verify(proof, stateRoot, leafInTree);
    }

}

/// @title Conversion functionality for migrating VNL v1 tokens to VNL v1.1
abstract contract VanillaV1Converter is IVanillaV1Converter {
    /// @inheritdoc IVanillaV1Converter
    IVanillaV1MigrationState public override migrationState;
    IERC20 internal vnl;

    constructor(IVanillaV1MigrationState _state, IERC20 _VNLv1) {
        migrationState = _state;
        vnl = _VNLv1;
    }

    function mintConverted(address target, uint256 amount) internal virtual;


    /// @inheritdoc IVanillaV1Converter
    function checkEligibility(bytes32[] memory proof) external view override returns (bool convertible, bool transferable) {
        uint256 balance = vnl.balanceOf(msg.sender);

        convertible = migrationState.verifyEligibility(proof, msg.sender, balance);
        transferable = balance > 0 && vnl.allowance(msg.sender, address(this)) >= balance;
    }

    /// @inheritdoc IVanillaV1Converter
    function convertVNL(bytes32[] memory proof) external override {
        if (block.timestamp >= migrationState.conversionDeadline()) {
            revert ConversionWindowClosed();
        }

        uint256 convertedAmount = vnl.balanceOf(msg.sender);
        if (convertedAmount == 0) {
            revert NoConvertibleVNL();
        }

        // because VanillaV1Token01's cannot be burned, the conversion just locks them into this contract permanently
        address freezer = address(this);
        uint256 previouslyFrozen = vnl.balanceOf(freezer);

        // we know that OpenZeppelin ERC20 returns always true and reverts on failure, so no need to check the return value
        vnl.transferFrom(msg.sender, freezer, convertedAmount);

        // These should never fail as we know precisely how VanillaV1Token01.transferFrom is implemented
        if (vnl.balanceOf(freezer) != previouslyFrozen + convertedAmount) {
            revert FreezerBalanceMismatch();
        }
        if (vnl.balanceOf(msg.sender) > 0) {
            revert UnexpectedTokensAfterConversion();
        }

        if (!migrationState.verifyEligibility(proof, msg.sender, convertedAmount)) {
            revert VerificationFailed();
        }

        // finally let implementor to mint the converted amount of tokens and log the event
        mintConverted(msg.sender, convertedAmount);
        emit VNLConverted(msg.sender, convertedAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./IVanillaV1Migration01.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVanillaV1Token02 is IERC20, IVanillaV1Converter {

    function mint(address to, uint256 tradeReward) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface VanillaV1Token01 is IERC20 {
    function mint(address to, uint256 tradeReward) external;
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IVanillaV1MigrationState {

    /// @notice The current Merkle tree root for checking the eligibility for token conversion
    /// @dev tree leaves are tuples of (VNLv1-owner-address, VNLv1-token-balance), ordered as keccak256(abi.encodePacked(tokenOwner, ":", amount))
    function stateRoot() external view returns (bytes32);

    /// @notice Gets the block.number which was used to calculate the `stateRoot()` (for off-chain verification)
    function blockNumber() external view returns (uint64);

    /// @notice Gets the current deadline for conversion as block.timestamp
    function conversionDeadline() external view returns (uint64);

    /// @notice Checks if `tokenOwner` owning `amount` of VNL v1s is eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing,
    /// leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @param tokenOwner The address owning the VanillaV1Token01 tokens
    /// @param amount The amount of VanillaV1Token01 tokens (i.e. the balance of the tokenowner)
    /// @return true iff `tokenOwner` is eligible to convert `amount` tokens to VanillaV1Token02
    function verifyEligibility(bytes32[] memory proof, address tokenOwner, uint256 amount) external view returns (bool);

    /// @notice Updates the Merkle tree for provable ownership of convertible VNL v1 tokens. Only for the owner.
    /// @dev Moves also the internal deadline forward 30 days
    /// @param newStateRoot The new Merkle tree root for checking the eligibility for token conversion
    /// @param blockNum The block.number whose state was used to calculate the `newStateRoot`
    function updateConvertibleState(bytes32 newStateRoot, uint64 blockNum) external;

    /// @notice thrown if non-owners try to modify state
    error UnauthorizedAccess();

    /// @notice thrown if attempting to update migration state after conversion deadline
    error MigrationStateUpdateDisabled();
}

interface IVanillaV1Converter {
    /// @notice Gets the address of the migration state contract
    function migrationState() external view returns (IVanillaV1MigrationState);

    /// @dev Emitted when VNL v1.01 is converted to v1.02
    /// @param converter The owner of tokens.
    /// @param amount Number of converted tokens.
    event VNLConverted(address converter, uint256 amount);

    /// @notice Checks if all `msg.sender`s VanillaV1Token01's are eligible for token conversion. Needs a Merkle `proof`.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    /// @return convertible true if `msg.sender` is eligible to convert all VanillaV1Token01 tokens to VanillaV1Token02 and conversion window is open
    /// @return transferable true if `msg.sender`'s VanillaV1Token01 tokens are ready to be transferred for conversion
    function checkEligibility(bytes32[] memory proof) external view returns (bool convertible, bool transferable);

    /// @notice Converts _ALL_ `msg.sender`s VanillaV1Token01's to VanillaV1Token02 if eligible. The conversion is irreversible.
    /// @dev The proof must be generated from a Merkle tree where leaf data is formatted as "<address>:<VNL v1 balance>" before hashing, and leaves and intermediate nodes are always hashed with keccak256 and then sorted.
    /// @param proof The proof that user is operating on the same state
    function convertVNL(bytes32[] memory proof) external;

    /// @notice thrown when attempting to convert VNL after deadline
    error ConversionWindowClosed();

    /// @notice thrown when attempting to convert 0 VNL
    error NoConvertibleVNL();

    /// @notice thrown if for some reason VNL freezer balance doesn't match the transferred amount + old balance
    error FreezerBalanceMismatch();

    /// @notice thrown if for some reason user holds VNL v1 tokens after conversion (i.e. transfer failed)
    error UnexpectedTokensAfterConversion();

    /// @notice thrown if user provided incorrect proof for conversion eligibility
    error VerificationFailed();
}

