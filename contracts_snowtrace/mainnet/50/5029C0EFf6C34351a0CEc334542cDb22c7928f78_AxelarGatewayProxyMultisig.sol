// Dependency file: src/interfaces/IAxelarGateway.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.8.0 <0.9.0;

interface IAxelarGateway {
    /**********\
    |* Events *|
    \**********/

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event TokenFrozen(string indexed symbol);

    event TokenUnfrozen(string indexed symbol);

    event AllTokensFrozen();

    event AllTokensUnfrozen();

    event AccountBlacklisted(address indexed account);

    event AccountWhitelisted(address indexed account);

    event Upgraded(address indexed implementation);

    /***********\
    |* Getters *|
    \***********/

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function freezeToken(string memory symbol) external;

    function unfreezeToken(string memory symbol) external;

    function freezeAllTokens() external;

    function unfreezeAllTokens() external;

    function upgrade(address newImplementation, bytes calldata setupParams) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}


// Dependency file: src/EternalStorage.sol


// pragma solidity >=0.8.0 <0.9.0;

/**
 * @title EternalStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract EternalStorage {
    mapping(bytes32 => uint256) private _uintStorage;
    mapping(bytes32 => string) private _stringStorage;
    mapping(bytes32 => address) private _addressStorage;
    mapping(bytes32 => bytes) private _bytesStorage;
    mapping(bytes32 => bool) private _boolStorage;
    mapping(bytes32 => int256) private _intStorage;

    // *** Getter Methods ***
    function getUint(bytes32 key) public view returns (uint256) {
        return _uintStorage[key];
    }

    function getString(bytes32 key) public view returns (string memory) {
        return _stringStorage[key];
    }

    function getAddress(bytes32 key) public view returns (address) {
        return _addressStorage[key];
    }

    function getBytes(bytes32 key) public view returns (bytes memory) {
        return _bytesStorage[key];
    }

    function getBool(bytes32 key) public view returns (bool) {
        return _boolStorage[key];
    }

    function getInt(bytes32 key) public view returns (int256) {
        return _intStorage[key];
    }

    // *** Setter Methods ***
    function _setUint(bytes32 key, uint256 value) internal {
        _uintStorage[key] = value;
    }

    function _setString(bytes32 key, string memory value) internal {
        _stringStorage[key] = value;
    }

    function _setAddress(bytes32 key, address value) internal {
        _addressStorage[key] = value;
    }

    function _setBytes(bytes32 key, bytes memory value) internal {
        _bytesStorage[key] = value;
    }

    function _setBool(bytes32 key, bool value) internal {
        _boolStorage[key] = value;
    }

    function _setInt(bytes32 key, int256 value) internal {
        _intStorage[key] = value;
    }

    // *** Delete Methods ***
    function _deleteUint(bytes32 key) internal {
        delete _uintStorage[key];
    }

    function _deleteString(bytes32 key) internal {
        delete _stringStorage[key];
    }

    function _deleteAddress(bytes32 key) internal {
        delete _addressStorage[key];
    }

    function _deleteBytes(bytes32 key) internal {
        delete _bytesStorage[key];
    }

    function _deleteBool(bytes32 key) internal {
        delete _boolStorage[key];
    }

    function _deleteInt(bytes32 key) internal {
        delete _intStorage[key];
    }
}


// Dependency file: src/AxelarGatewayProxy.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { EternalStorage } from 'src/EternalStorage.sol';

contract AxelarGatewayProxy is EternalStorage {
    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 internal constant KEY_IMPLEMENTATION =
        bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    fallback() external payable {
        address implementation = getAddress(KEY_IMPLEMENTATION);

        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {
        revert('NO_ETHER');
    }
}


// Dependency file: src/interfaces/IAxelarGatewayMultisig.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { IAxelarGateway } from 'src/interfaces/IAxelarGateway.sol';

interface IAxelarGatewayMultisig is IAxelarGateway {

    event OwnershipTransferred(address[] preOwners, uint256 prevThreshold, address[] newOwners, uint256 newThreshold);

    event OperatorshipTransferred(address[] preOperators, uint256 prevThreshold, address[] newOperators, uint256 newThreshold);

    function owners() external view returns (address[] memory);

    function operators() external view returns (address[] memory);

}


// Dependency file: src/ECDSA.sol


// pragma solidity >=0.8.0 <0.9.0;

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
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address signer) {
        // Check the signature length
        require(signature.length == 65, 'INV_LEN');

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
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, 'INV_S');

        require(v == 27 || v == 28, 'INV_V');

        // If the signature is valid (and not malleable), return the signer address
        require((signer = ecrecover(hash, v, r, s)) != address(0), 'INV_SIG');
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
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
}


// Dependency file: src/interfaces/IERC20.sol


// pragma solidity >=0.8.0 <0.9.0;

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


// Dependency file: src/Context.sol


// pragma solidity >=0.8.0 <0.9.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: src/ERC20.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { IERC20 } from 'src/interfaces/IERC20.sol';

// import { Context } from 'src/Context.sol';

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
contract ERC20 is Context, IERC20 {
    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;

    string public name;
    string public symbol;

    uint8 public immutable decimals;

    /**
     * @dev Sets the values for {name}, {symbol}, and {decimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance[sender][_msgSender()] - amount);
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
        _approve(_msgSender(), spender, allowance[_msgSender()][spender] + addedValue);
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
        _approve(_msgSender(), spender, allowance[_msgSender()][spender] - subtractedValue);
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), 'ZERO_ADDR');
        require(recipient != address(0), 'ZERO_ADDR');

        _beforeTokenTransfer(sender, recipient, amount);

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
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
        require(account != address(0), 'ZERO_ADDR');

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balanceOf[account] += amount;
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
        require(account != address(0), 'ZERO_ADDR');

        _beforeTokenTransfer(account, address(0), amount);

        balanceOf[account] -= amount;
        totalSupply -= amount;
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'ZERO_ADDR');
        require(spender != address(0), 'ZERO_ADDR');

        allowance[owner][spender] = amount;
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// Dependency file: src/Ownable.sol


// pragma solidity >=0.8.0 <0.9.0;

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, 'NOT_OWNER');
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'ZERO_ADDR');

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


// Dependency file: src/Burner.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { BurnableMintableCappedERC20 } from 'src/BurnableMintableCappedERC20.sol';

contract Burner {
    constructor(address tokenAddress, bytes32 salt) {
        BurnableMintableCappedERC20(tokenAddress).burn(salt);

        selfdestruct(payable(address(0)));
    }
}


// Dependency file: src/BurnableMintableCappedERC20.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { ERC20 } from 'src/ERC20.sol';
// import { Ownable } from 'src/Ownable.sol';
// import { Burner } from 'src/Burner.sol';
// import { EternalStorage } from 'src/EternalStorage.sol';

contract BurnableMintableCappedERC20 is ERC20, Ownable {
    uint256 public cap;

    bytes32 private constant PREFIX_TOKEN_FROZEN = keccak256('token-frozen');
    bytes32 private constant KEY_ALL_TOKENS_FROZEN = keccak256('all-tokens-frozen');

    event Frozen(address indexed owner);
    event Unfrozen(address indexed owner);

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 capacity
    ) ERC20(name, symbol, decimals) Ownable() {
        cap = capacity;
    }

    function depositAddress(bytes32 salt) public view returns (address) {
        // This would be easier, cheaper, simpler, and result in  globally consistent deposit addresses for any salt (all chains, all tokens).
        // return address(uint160(uint256(keccak256(abi.encodePacked(bytes32(0x000000000000000000000000000000000000000000000000000000000000dead), salt)))));

        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.1/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                owner,
                                salt,
                                keccak256(abi.encodePacked(type(Burner).creationCode, abi.encode(address(this)), salt))
                            )
                        )
                    )
                )
            );
    }

    function mint(address account, uint256 amount) public onlyOwner {
        uint256 capacity = cap;
        require(capacity == 0 || totalSupply + amount <= capacity, 'CAP_EXCEEDED');

        _mint(account, amount);
    }

    function burn(bytes32 salt) public onlyOwner {
        address account = depositAddress(salt);
        _burn(account, balanceOf[account]);
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal view override {
        require(!EternalStorage(owner).getBool(KEY_ALL_TOKENS_FROZEN), 'IS_FROZEN');
        require(!EternalStorage(owner).getBool(keccak256(abi.encodePacked(PREFIX_TOKEN_FROZEN, symbol))), 'IS_FROZEN');
    }
}


// Dependency file: src/AdminMultisigBase.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { EternalStorage } from 'src/EternalStorage.sol';

contract AdminMultisigBase is EternalStorage {
    // AUDIT: slot names should be prefixed with some standard string
    // AUDIT: constants should be literal and their derivation should be in comments
    bytes32 internal constant KEY_ADMIN_EPOCH = keccak256('admin-epoch');

    bytes32 internal constant PREFIX_ADMIN = keccak256('admin');
    bytes32 internal constant PREFIX_ADMIN_COUNT = keccak256('admin-count');
    bytes32 internal constant PREFIX_ADMIN_THRESHOLD = keccak256('admin-threshold');
    bytes32 internal constant PREFIX_ADMIN_VOTE_COUNTS = keccak256('admin-vote-counts');
    bytes32 internal constant PREFIX_ADMIN_VOTED = keccak256('admin-voted');
    bytes32 internal constant PREFIX_IS_ADMIN = keccak256('is-admin');

    modifier onlyAdmin() {
        uint256 adminEpoch = _adminEpoch();

        require(_isAdmin(adminEpoch, msg.sender), 'NOT_ADMIN');

        bytes32 topic = keccak256(msg.data);

        // Check that admin has not voted, then record that they have voted.
        require(!_hasVoted(adminEpoch, topic, msg.sender), 'VOTED');
        _setHasVoted(adminEpoch, topic, msg.sender, true);

        // Determine the new vote count and update it.
        uint256 adminVoteCount = _getVoteCount(adminEpoch, topic) + uint256(1);
        _setVoteCount(adminEpoch, topic, adminVoteCount);

        // Do not proceed with operation execution if insufficient votes.
        if (adminVoteCount < _getAdminThreshold(adminEpoch)) return;

        _;

        // Clear vote count and voted booleans.
        _setVoteCount(adminEpoch, topic, uint256(0));

        uint256 adminCount = _getAdminCount(adminEpoch);

        for (uint256 i; i < adminCount; i++) {
            _setHasVoted(adminEpoch, topic, _getAdmin(adminEpoch, i), false);
        }
    }

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getAdminKey(uint256 adminEpoch, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_ADMIN, adminEpoch, index));
    }

    function _getAdminCountKey(uint256 adminEpoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_ADMIN_COUNT, adminEpoch));
    }

    function _getAdminThresholdKey(uint256 adminEpoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_ADMIN_THRESHOLD, adminEpoch));
    }

    function _getAdminVoteCountsKey(uint256 adminEpoch, bytes32 topic) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_ADMIN_VOTE_COUNTS, adminEpoch, topic));
    }

    function _getAdminVotedKey(
        uint256 adminEpoch,
        bytes32 topic,
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_ADMIN_VOTED, adminEpoch, topic, account));
    }

    function _getIsAdminKey(uint256 adminEpoch, address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_IS_ADMIN, adminEpoch, account));
    }

    /***********\
    |* Getters *|
    \***********/

    function _adminEpoch() internal view returns (uint256) {
        return getUint(KEY_ADMIN_EPOCH);
    }

    function _getAdmin(uint256 adminEpoch, uint256 index) internal view returns (address) {
        return getAddress(_getAdminKey(adminEpoch, index));
    }

    function _getAdminCount(uint256 adminEpoch) internal view returns (uint256) {
        return getUint(_getAdminCountKey(adminEpoch));
    }

    function _getAdminThreshold(uint256 adminEpoch) internal view returns (uint256) {
        return getUint(_getAdminThresholdKey(adminEpoch));
    }

    function _getVoteCount(uint256 adminEpoch, bytes32 topic) internal view returns (uint256) {
        return getUint(_getAdminVoteCountsKey(adminEpoch, topic));
    }

    function _hasVoted(
        uint256 adminEpoch,
        bytes32 topic,
        address account
    ) internal view returns (bool) {
        return getBool(_getAdminVotedKey(adminEpoch, topic, account));
    }

    function _isAdmin(uint256 adminEpoch, address account) internal view returns (bool) {
        return getBool(_getIsAdminKey(adminEpoch, account));
    }

    /***********\
    |* Setters *|
    \***********/

    function _setAdminEpoch(uint256 adminEpoch) internal {
        _setUint(KEY_ADMIN_EPOCH, adminEpoch);
    }

    function _setAdmin(
        uint256 adminEpoch,
        uint256 index,
        address account
    ) internal {
        _setAddress(_getAdminKey(adminEpoch, index), account);
    }

    function _setAdminCount(uint256 adminEpoch, uint256 adminCount) internal {
        _setUint(_getAdminCountKey(adminEpoch), adminCount);
    }

    function _setAdmins(
        uint256 adminEpoch,
        address[] memory accounts,
        uint256 threshold
    ) internal {
        uint256 adminLength = accounts.length;

        require(adminLength >= threshold, 'INV_ADMINS');
        require(threshold > uint256(0), 'INV_ADMIN_THLD');

        _setAdminThreshold(adminEpoch, threshold);
        _setAdminCount(adminEpoch, adminLength);

        for (uint256 i; i < adminLength; i++) {
            address account = accounts[i];

            // Check that the account wasn't already set as an admin for this epoch.
            require(!_isAdmin(adminEpoch, account), 'DUP_ADMIN');

            // Set this account as the i-th admin in this epoch (needed to we can clear topic votes in `onlyAdmin`).
            _setAdmin(adminEpoch, i, account);
            _setIsAdmin(adminEpoch, account, true);
        }
    }

    function _setAdminThreshold(uint256 adminEpoch, uint256 adminThreshold) internal {
        _setUint(_getAdminThresholdKey(adminEpoch), adminThreshold);
    }

    function _setVoteCount(
        uint256 adminEpoch,
        bytes32 topic,
        uint256 voteCount
    ) internal {
        _setUint(_getAdminVoteCountsKey(adminEpoch, topic), voteCount);
    }

    function _setHasVoted(
        uint256 adminEpoch,
        bytes32 topic,
        address account,
        bool voted
    ) internal {
        _setBool(_getAdminVotedKey(adminEpoch, topic, account), voted);
    }

    function _setIsAdmin(
        uint256 adminEpoch,
        address account,
        bool isAdmin
    ) internal {
        _setBool(_getIsAdminKey(adminEpoch, account), isAdmin);
    }
}


// Dependency file: src/AxelarGateway.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { IAxelarGateway } from 'src/interfaces/IAxelarGateway.sol';

// import { BurnableMintableCappedERC20 } from 'src/BurnableMintableCappedERC20.sol';
// import { AdminMultisigBase } from 'src/AdminMultisigBase.sol';

abstract contract AxelarGateway is IAxelarGateway, AdminMultisigBase {
    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 internal constant KEY_IMPLEMENTATION =
        bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    // AUDIT: slot names should be prefixed with some standard string
    // AUDIT: constants should be literal and their derivation should be in comments
    bytes32 internal constant KEY_ALL_TOKENS_FROZEN = keccak256('all-tokens-frozen');

    bytes32 internal constant PREFIX_COMMAND_EXECUTED = keccak256('command-executed');
    bytes32 internal constant PREFIX_TOKEN_ADDRESS = keccak256('token-address');
    bytes32 internal constant PREFIX_TOKEN_FROZEN = keccak256('token-frozen');

    bytes32 internal constant SELECTOR_BURN_TOKEN = keccak256('burnToken');
    bytes32 internal constant SELECTOR_DEPLOY_TOKEN = keccak256('deployToken');
    bytes32 internal constant SELECTOR_MINT_TOKEN = keccak256('mintToken');
    bytes32 internal constant SELECTOR_TRANSFER_OPERATORSHIP = keccak256('transferOperatorship');
    bytes32 internal constant SELECTOR_TRANSFER_OWNERSHIP = keccak256('transferOwnership');

    uint8 internal constant OLD_KEY_RETENTION = 16;

    modifier onlySelf() {
        require(msg.sender == address(this), 'NOT_SELF');

        _;
    }

    /***********\
    |* Getters *|
    \***********/

    function allTokensFrozen() public view override returns (bool) {
        return getBool(KEY_ALL_TOKENS_FROZEN);
    }

    function implementation() public view override returns (address) {
        return getAddress(KEY_IMPLEMENTATION);
    }

    function tokenAddresses(string memory symbol) public view override returns (address) {
        return getAddress(_getTokenAddressKey(symbol));
    }

    function tokenFrozen(string memory symbol) public view override returns (bool) {
        return getBool(_getFreezeTokenKey(symbol));
    }

    function isCommandExecuted(bytes32 commandId) public view override returns (bool) {
        return getBool(_getIsCommandExecutedKey(commandId));
    }

    /*******************\
    |* Admin Functions *|
    \*******************/

    function freezeToken(string memory symbol) external override onlyAdmin {
        _setBool(_getFreezeTokenKey(symbol), true);

        emit TokenFrozen(symbol);
    }

    function unfreezeToken(string memory symbol) external override onlyAdmin {
        _setBool(_getFreezeTokenKey(symbol), false);

        emit TokenUnfrozen(symbol);
    }

    function freezeAllTokens() external override onlyAdmin {
        _setBool(KEY_ALL_TOKENS_FROZEN, true);

        emit AllTokensFrozen();
    }

    function unfreezeAllTokens() external override onlyAdmin {
        _setBool(KEY_ALL_TOKENS_FROZEN, false);

        emit AllTokensUnfrozen();
    }

    function upgrade(address newImplementation, bytes calldata setupParams) external override onlyAdmin {
        emit Upgraded(newImplementation);

        // AUDIT: If `newImplementation.setup` performs `selfdestruct`, it will result in the loss of _this_ implementation (thereby losing the gateway)
        //        if `upgrade` is entered within the context of _this_ implementation itself.
        (bool success, ) = newImplementation.delegatecall(
            abi.encodeWithSelector(IAxelarGateway.setup.selector, setupParams)
        );
        require(success, 'SETUP_FAILED');

        _setImplementation(newImplementation);
    }

    /**********************\
    |* Internal Functions *|
    \**********************/

    function _deployToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap
    ) internal {
        require(tokenAddresses(symbol) == address(0), 'TOKEN_EXIST');

        bytes32 salt = keccak256(abi.encodePacked(symbol));
        address token = address(new BurnableMintableCappedERC20{ salt: salt }(name, symbol, decimals, cap));

        _setTokenAddress(symbol, token);

        emit TokenDeployed(symbol, token);
    }

    function _mintToken(
        string memory symbol,
        address account,
        uint256 amount
    ) internal {
        address tokenAddress = tokenAddresses(symbol);
        require(tokenAddress != address(0), 'TOKEN_NOT_EXIST');

        BurnableMintableCappedERC20(tokenAddress).mint(account, amount);
    }

    function _burnToken(string memory symbol, bytes32 salt) internal {
        address tokenAddress = tokenAddresses(symbol);
        require(tokenAddress != address(0), 'TOKEN_NOT_EXIST');

        BurnableMintableCappedERC20(tokenAddress).burn(salt);
    }

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getFreezeTokenKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_FROZEN, symbol));
    }

    function _getTokenAddressKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_ADDRESS, symbol));
    }

    function _getIsCommandExecutedKey(bytes32 commandId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_COMMAND_EXECUTED, commandId));
    }

    /********************\
    |* Internal Getters *|
    \********************/

    function _getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /********************\
    |* Internal Setters *|
    \********************/

    function _setTokenAddress(string memory symbol, address tokenAddr) internal {
        _setAddress(_getTokenAddressKey(symbol), tokenAddr);
    }

    function _setCommandExecuted(bytes32 commandId, bool executed) internal {
        _setBool(_getIsCommandExecutedKey(commandId), executed);
    }

    function _setImplementation(address newImplementation) internal {
        _setAddress(KEY_IMPLEMENTATION, newImplementation);
    }
}


// Dependency file: src/AxelarGatewayMultisig.sol


// pragma solidity >=0.8.0 <0.9.0;

// import { IAxelarGatewayMultisig } from 'src/interfaces/IAxelarGatewayMultisig.sol';

// import { ECDSA } from 'src/ECDSA.sol';
// import { AxelarGateway } from 'src/AxelarGateway.sol';

contract AxelarGatewayMultisig is IAxelarGatewayMultisig, AxelarGateway {
    // AUDIT: slot names should be prefixed with some standard string
    // AUDIT: constants should be literal and their derivation should be in comments
    bytes32 internal constant KEY_OWNER_EPOCH = keccak256('owner-epoch');

    bytes32 internal constant PREFIX_OWNER = keccak256('owner');
    bytes32 internal constant PREFIX_OWNER_COUNT = keccak256('owner-count');
    bytes32 internal constant PREFIX_OWNER_THRESHOLD = keccak256('owner-threshold');
    bytes32 internal constant PREFIX_IS_OWNER = keccak256('is-owner');

    bytes32 internal constant KEY_OPERATOR_EPOCH = keccak256('operator-epoch');

    bytes32 internal constant PREFIX_OPERATOR = keccak256('operator');
    bytes32 internal constant PREFIX_OPERATOR_COUNT = keccak256('operator-count');
    bytes32 internal constant PREFIX_OPERATOR_THRESHOLD = keccak256('operator-threshold');
    bytes32 internal constant PREFIX_IS_OPERATOR = keccak256('is-operator');

    function _containsDuplicates(address[] memory accounts) internal pure returns (bool) {
        uint256 count = accounts.length;

        for (uint256 i; i < count; ++i) {
            for (uint256 j = i + 1; j < count; ++j) {
                if (accounts[i] == accounts[j]) return true;
            }
        }

        return false;
    }

    /************************\
    |* Owners Functionality *|
    \************************/

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getOwnerKey(uint256 ownerEpoch, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OWNER, ownerEpoch, index));
    }

    function _getOwnerCountKey(uint256 ownerEpoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OWNER_COUNT, ownerEpoch));
    }

    function _getOwnerThresholdKey(uint256 ownerEpoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OWNER_THRESHOLD, ownerEpoch));
    }

    function _getIsOwnerKey(uint256 ownerEpoch, address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_IS_OWNER, ownerEpoch, account));
    }

    /***********\
    |* Getters *|
    \***********/

    function _ownerEpoch() internal view returns (uint256) {
        return getUint(KEY_OWNER_EPOCH);
    }

    function _getOwner(uint256 ownerEpoch, uint256 index) internal view returns (address) {
        return getAddress(_getOwnerKey(ownerEpoch, index));
    }

    function _getOwnerCount(uint256 ownerEpoch) internal view returns (uint256) {
        return getUint(_getOwnerCountKey(ownerEpoch));
    }

    function _getOwnerThreshold(uint256 ownerEpoch) internal view returns (uint256) {
        return getUint(_getOwnerThresholdKey(ownerEpoch));
    }

    function _isOwner(uint256 ownerEpoch, address account) internal view returns (bool) {
        return getBool(_getIsOwnerKey(ownerEpoch, account));
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are owners in the same `ownerEpoch`, within the last `OLD_KEY_RETENTION + 1` owner epochs.
    function _areValidRecentOwners(address[] memory accounts) internal view returns (bool) {
        uint256 ownerEpoch = _ownerEpoch();
        uint256 recentEpochs = OLD_KEY_RETENTION + uint256(1);
        uint256 lowerBoundOwnerEpoch = ownerEpoch > recentEpochs ? ownerEpoch - recentEpochs : uint256(0);

        while (ownerEpoch > lowerBoundOwnerEpoch) {
            if (_areValidOwnersInEpoch(ownerEpoch--, accounts)) return true;
        }

        return false;
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are owners in the `ownerEpoch`.
    function _areValidOwnersInEpoch(uint256 ownerEpoch, address[] memory accounts) internal view returns (bool) {
        if (_containsDuplicates(accounts)) return false;

        uint256 threshold = _getOwnerThreshold(ownerEpoch);
        uint256 validSignerCount;

        for (uint256 i; i < accounts.length; i++) {
            if (_isOwner(ownerEpoch, accounts[i]) && ++validSignerCount >= threshold) return true;
        }

        return false;
    }

    /// @dev Returns the array of owners within the current `ownerEpoch`.
    function owners() public view override returns (address[] memory results) {
        uint256 ownerEpoch = _ownerEpoch();
        uint256 ownerCount = _getOwnerCount(ownerEpoch);
        results = new address[](ownerCount);

        for (uint256 i; i < ownerCount; i++) {
            results[i] = _getOwner(ownerEpoch, i);
        }
    }

    /***********\
    |* Setters *|
    \***********/

    function _setOwnerEpoch(uint256 ownerEpoch) internal {
        _setUint(KEY_OWNER_EPOCH, ownerEpoch);
    }

    function _setOwner(
        uint256 ownerEpoch,
        uint256 index,
        address account
    ) internal {
        require(account != address(0), 'ZERO_ADDR');
        _setAddress(_getOwnerKey(ownerEpoch, index), account);
    }

    function _setOwnerCount(uint256 ownerEpoch, uint256 ownerCount) internal {
        _setUint(_getOwnerCountKey(ownerEpoch), ownerCount);
    }

    function _setOwners(
        uint256 ownerEpoch,
        address[] memory accounts,
        uint256 threshold
    ) internal {
        uint256 accountLength = accounts.length;

        require(accountLength >= threshold, 'INV_OWNERS');
        require(threshold > uint256(0), 'INV_OWNER_THLD');

        _setOwnerThreshold(ownerEpoch, threshold);
        _setOwnerCount(ownerEpoch, accountLength);

        for (uint256 i; i < accountLength; i++) {
            address account = accounts[i];

            // Check that the account wasn't already set as an owner for this ownerEpoch.
            require(!_isOwner(ownerEpoch, account), 'DUP_OWNER');

            // Set this account as the i-th owner in this ownerEpoch (needed to we can get all the owners for `owners`).
            _setOwner(ownerEpoch, i, account);
            _setIsOwner(ownerEpoch, account, true);
        }
    }

    function _setOwnerThreshold(uint256 ownerEpoch, uint256 ownerThreshold) internal {
        _setUint(_getOwnerThresholdKey(ownerEpoch), ownerThreshold);
    }

    function _setIsOwner(
        uint256 ownerEpoch,
        address account,
        bool isOwner
    ) internal {
        _setBool(_getIsOwnerKey(ownerEpoch, account), isOwner);
    }

    /**************************\
    |* Operator Functionality *|
    \**************************/

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getOperatorKey(uint256 operatorEpoch, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OPERATOR, operatorEpoch, index));
    }

    function _getOperatorCountKey(uint256 operatorEpoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OPERATOR_COUNT, operatorEpoch));
    }

    function _getOperatorThresholdKey(uint256 operatorEpoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OPERATOR_THRESHOLD, operatorEpoch));
    }

    function _getIsOperatorKey(uint256 operatorEpoch, address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_IS_OPERATOR, operatorEpoch, account));
    }

    /***********\
    |* Getters *|
    \***********/

    function _operatorEpoch() internal view returns (uint256) {
        return getUint(KEY_OPERATOR_EPOCH);
    }

    function _getOperator(uint256 operatorEpoch, uint256 index) internal view returns (address) {
        return getAddress(_getOperatorKey(operatorEpoch, index));
    }

    function _getOperatorCount(uint256 operatorEpoch) internal view returns (uint256) {
        return getUint(_getOperatorCountKey(operatorEpoch));
    }

    function _getOperatorThreshold(uint256 operatorEpoch) internal view returns (uint256) {
        return getUint(_getOperatorThresholdKey(operatorEpoch));
    }

    function _isOperator(uint256 operatorEpoch, address account) internal view returns (bool) {
        return getBool(_getIsOperatorKey(operatorEpoch, account));
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are operator in the same `operatorEpoch`, within the last `OLD_KEY_RETENTION + 1` operator epochs.
    function _areValidRecentOperators(address[] memory accounts) internal view returns (bool) {
        uint256 operatorEpoch = _operatorEpoch();
        uint256 recentEpochs = OLD_KEY_RETENTION + uint256(1);
        uint256 lowerBoundOperatorEpoch = operatorEpoch > recentEpochs ? operatorEpoch - recentEpochs : uint256(0);

        while (operatorEpoch > lowerBoundOperatorEpoch) {
            if (_areValidOperatorsInEpoch(operatorEpoch--, accounts)) return true;
        }

        return false;
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are operator in the `operatorEpoch`.
    function _areValidOperatorsInEpoch(uint256 operatorEpoch, address[] memory accounts) internal view returns (bool) {
        if (_containsDuplicates(accounts)) return false;

        uint256 threshold = _getOperatorThreshold(operatorEpoch);
        uint256 validSignerCount;

        for (uint256 i; i < accounts.length; i++) {
            if (_isOperator(operatorEpoch, accounts[i]) && ++validSignerCount >= threshold) return true;
        }

        return false;
    }

    /// @dev Returns the array of operators within the current `operatorEpoch`.
    function operators() public view override returns (address[] memory results) {
        uint256 operatorEpoch = _operatorEpoch();
        uint256 operatorCount = _getOperatorCount(operatorEpoch);
        results = new address[](operatorCount);

        for (uint256 i; i < operatorCount; i++) {
            results[i] = _getOperator(operatorEpoch, i);
        }
    }

    /***********\
    |* Setters *|
    \***********/

    function _setOperatorEpoch(uint256 operatorEpoch) internal {
        _setUint(KEY_OPERATOR_EPOCH, operatorEpoch);
    }

    function _setOperator(
        uint256 operatorEpoch,
        uint256 index,
        address account
    ) internal {
        // AUDIT: Should have `require(account != address(0), 'ZERO_ADDR');` like Singlesig?
        _setAddress(_getOperatorKey(operatorEpoch, index), account);
    }

    function _setOperatorCount(uint256 operatorEpoch, uint256 operatorCount) internal {
        _setUint(_getOperatorCountKey(operatorEpoch), operatorCount);
    }

    function _setOperators(
        uint256 operatorEpoch,
        address[] memory accounts,
        uint256 threshold
    ) internal {
        uint256 accountLength = accounts.length;

        require(accountLength >= threshold, 'INV_OPERATORS');
        require(threshold > uint256(0), 'INV_OPERATOR_THLD');

        _setOperatorThreshold(operatorEpoch, threshold);
        _setOperatorCount(operatorEpoch, accountLength);

        for (uint256 i; i < accountLength; i++) {
            address account = accounts[i];

            // Check that the account wasn't already set as an operator for this operatorEpoch.
            require(!_isOperator(operatorEpoch, account), 'DUP_OPERATOR');

            // Set this account as the i-th operator in this operatorEpoch (needed to we can get all the operators for `operators`).
            _setOperator(operatorEpoch, i, account);
            _setIsOperator(operatorEpoch, account, true);
        }
    }

    function _setOperatorThreshold(uint256 operatorEpoch, uint256 operatorThreshold) internal {
        _setUint(_getOperatorThresholdKey(operatorEpoch), operatorThreshold);
    }

    function _setIsOperator(
        uint256 operatorEpoch,
        address account,
        bool isOperator
    ) internal {
        _setBool(_getIsOperatorKey(operatorEpoch, account), isOperator);
    }

    /**********************\
    |* Self Functionality *|
    \**********************/

    function deployToken(bytes calldata params) external onlySelf {
        (string memory name, string memory symbol, uint8 decimals, uint256 cap) = abi.decode(
            params,
            (string, string, uint8, uint256)
        );

        _deployToken(name, symbol, decimals, cap);
    }

    function mintToken(bytes calldata params) external onlySelf {
        (string memory symbol, address account, uint256 amount) = abi.decode(params, (string, address, uint256));

        _mintToken(symbol, account, amount);
    }

    function burnToken(bytes calldata params) external onlySelf {
        (string memory symbol, bytes32 salt) = abi.decode(params, (string, bytes32));

        _burnToken(symbol, salt);
    }

    function transferOwnership(bytes calldata params) external onlySelf {
        (address[] memory newOwners, uint256 newThreshold) = abi.decode(params, (address[], uint256));

        uint256 ownerEpoch = _ownerEpoch();

        emit OwnershipTransferred(owners(), _getOwnerThreshold(ownerEpoch), newOwners, newThreshold);

        _setOwnerEpoch(++ownerEpoch);
        _setOwners(ownerEpoch, newOwners, newThreshold);
    }

    function transferOperatorship(bytes calldata params) external onlySelf {
        (address[] memory newOperators, uint256 newThreshold) = abi.decode(params, (address[], uint256));

        uint256 ownerEpoch = _ownerEpoch();

        emit OperatorshipTransferred(operators(), _getOperatorThreshold(ownerEpoch), newOperators, newThreshold);

        uint256 operatorEpoch = _operatorEpoch();
        _setOperatorEpoch(++operatorEpoch);
        _setOperators(operatorEpoch, newOperators, newThreshold);
    }

    /**************************\
    |* External Functionality *|
    \**************************/

    function setup(bytes calldata params) external override {
        // Prevent setup from being called on a non-proxy (the implementation).
        require(implementation() != address(0), 'NOT_PROXY');

        (
            address[] memory adminAddresses,
            uint256 adminThreshold,
            address[] memory ownerAddresses,
            uint256 ownerThreshold,
            address[] memory operatorAddresses,
            uint256 operatorThreshold
        ) = abi.decode(params, (address[], uint256, address[], uint256, address[], uint256));

        uint256 adminEpoch = _adminEpoch() + uint256(1);
        _setAdminEpoch(adminEpoch);
        _setAdmins(adminEpoch, adminAddresses, adminThreshold);

        uint256 ownerEpoch = _ownerEpoch() + uint256(1);
        _setOwnerEpoch(ownerEpoch);
        _setOwners(ownerEpoch, ownerAddresses, ownerThreshold);

        uint256 operatorEpoch = _operatorEpoch() + uint256(1);
        _setOperatorEpoch(operatorEpoch);
        _setOperators(operatorEpoch, operatorAddresses, operatorThreshold);

        emit OwnershipTransferred(new address[](uint256(0)), uint256(0), ownerAddresses, ownerThreshold);
        emit OperatorshipTransferred(new address[](uint256(0)), uint256(0), operatorAddresses, operatorThreshold);
    }

    function execute(bytes calldata input) external override {
        (bytes memory data, bytes[] memory signatures) = abi.decode(input, (bytes, bytes[]));

        _execute(data, signatures);
    }

    function _execute(bytes memory data, bytes[] memory signatures) internal {
        uint256 signatureCount = signatures.length;

        address[] memory signers = new address[](signatureCount);

        for (uint256 i; i < signatureCount; i++) {
            signers[i] = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(data)), signatures[i]);
        }

        (uint256 chainId, bytes32[] memory commandIds, string[] memory commands, bytes[] memory params) = abi.decode(
            data,
            (uint256, bytes32[], string[], bytes[])
        );

        require(chainId == _getChainID(), 'INV_CHAIN');

        uint256 commandsLength = commandIds.length;

        require(commandsLength == commands.length && commandsLength == params.length, 'INV_CMDS');

        bool areValidCurrentOwners = _areValidOwnersInEpoch(_ownerEpoch(), signers);
        bool areValidRecentOwners = areValidCurrentOwners || _areValidRecentOwners(signers);
        bool areValidRecentOperators = _areValidRecentOperators(signers);

        for (uint256 i; i < commandsLength; i++) {
            bytes32 commandId = commandIds[i];

            if (isCommandExecuted(commandId)) continue; /* Ignore if duplicate commandId received */

            bytes4 commandSelector;
            bytes32 commandHash = keccak256(abi.encodePacked(commands[i]));

            if (commandHash == SELECTOR_DEPLOY_TOKEN) {
                if (!areValidRecentOwners) continue;

                commandSelector = AxelarGatewayMultisig.deployToken.selector;
            } else if (commandHash == SELECTOR_MINT_TOKEN) {
                if (!areValidRecentOperators && !areValidRecentOwners) continue;

                commandSelector = AxelarGatewayMultisig.mintToken.selector;
            } else if (commandHash == SELECTOR_BURN_TOKEN) {
                if (!areValidRecentOperators && !areValidRecentOwners) continue;

                commandSelector = AxelarGatewayMultisig.burnToken.selector;
            } else if (commandHash == SELECTOR_TRANSFER_OWNERSHIP) {
                if (!areValidCurrentOwners) continue;

                commandSelector = AxelarGatewayMultisig.transferOwnership.selector;
            } else if (commandHash == SELECTOR_TRANSFER_OPERATORSHIP) {
                if (!areValidCurrentOwners) continue;

                commandSelector = AxelarGatewayMultisig.transferOperatorship.selector;
            } else {
                continue; /* Ignore if unknown command received */
            }

            // Prevent a re-entrancy from executing this command before it can be marked as successful.
            _setCommandExecuted(commandId, true);
            (bool success, ) = address(this).call(abi.encodeWithSelector(commandSelector, params[i]));
            _setCommandExecuted(commandId, success);

            if (success) {
                emit Executed(commandId);
            }
        }
    }
}


// Root file: src/AxelarGatewayProxyMultisig.sol


pragma solidity >=0.8.0 <0.9.0;

// import { IAxelarGateway } from 'src/interfaces/IAxelarGateway.sol';

// import { AxelarGatewayProxy } from 'src/AxelarGatewayProxy.sol';
// import { AxelarGatewayMultisig } from 'src/AxelarGatewayMultisig.sol';

contract AxelarGatewayProxyMultisig is AxelarGatewayProxy {
    constructor(bytes memory params) {
        // AUDIT: constructor contains entire AxelarGatewayMultisig bytecode. Consider passing in an AxelarGatewayMultisig address.
        address gateway = address(new AxelarGatewayMultisig());

        _setAddress(KEY_IMPLEMENTATION, gateway);

        (bool success, ) = gateway.delegatecall(abi.encodeWithSelector(IAxelarGateway.setup.selector, params));
        require(success, 'SETUP_FAILED');
    }

    function setup(bytes calldata params) external {}
}