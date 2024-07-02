/**
 *Submitted for verification at moonbeam.moonscan.io on 2022-06-08
*/

// Dependency file: src/interfaces/IAxelarGateway.sol

// SPDX-License-Identifier: MIT

// pragma solidity 0.8.9;

interface IAxelarGateway {
    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenFrozen(string symbol);

    event TokenUnfrozen(string symbol);

    event AllTokensFrozen();

    event AllTokensUnfrozen();

    event AccountBlacklisted(address indexed account);

    event AccountWhitelisted(address indexed account);

    event Upgraded(address indexed implementation);

    /******************\
    |* Public Methods *|
    \******************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function freezeToken(string calldata symbol) external;

    function unfreezeToken(string calldata symbol) external;

    function freezeAllTokens() external;

    function unfreezeAllTokens() external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}


// Dependency file: src/interfaces/IAxelarGatewayMultisig.sol


// pragma solidity 0.8.9;

// import { IAxelarGateway } from 'src/interfaces/IAxelarGateway.sol';

interface IAxelarGatewayMultisig is IAxelarGateway {
    event OwnershipTransferred(address[] preOwners, uint256 prevThreshold, address[] newOwners, uint256 newThreshold);

    event OperatorshipTransferred(
        address[] preOperators,
        uint256 prevThreshold,
        address[] newOperators,
        uint256 newThreshold
    );

    function ownerEpoch() external view returns (uint256);

    function ownerThreshold(uint256 epoch) external view returns (uint256);

    function owners(uint256 epoch) external view returns (address[] memory);

    function operatorEpoch() external view returns (uint256);

    function operatorThreshold(uint256 epoch) external view returns (uint256);

    function operators(uint256 epoch) external view returns (address[] memory);
}


// Dependency file: src/ECDSA.sol


// pragma solidity 0.8.9;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    error InvalidSignatureLength();
    error InvalidS();
    error InvalidV();
    error InvalidSignature();

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
        if (signature.length != 65) revert InvalidSignatureLength();

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
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert InvalidS();

        if (v != 27 && v != 28) revert InvalidV();

        // If the signature is valid (and not malleable), return the signer address
        if ((signer = ecrecover(hash, v, r, s)) == address(0)) revert InvalidSignature();
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


// pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

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


// Dependency file: src/interfaces/IERC20Burn.sol


// pragma solidity 0.8.9;

interface IERC20Burn {
    function burn(bytes32 salt) external;
}


// Dependency file: src/interfaces/IERC20BurnFrom.sol


// pragma solidity 0.8.9;

interface IERC20BurnFrom {
    function burnFrom(address account, uint256 amount) external;
}


// Dependency file: src/interfaces/IERC20Permit.sol


// pragma solidity 0.8.9;

interface IERC20Permit {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function nonces(address account) external view returns (uint256);

    function permit(
        address issuer,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// Dependency file: src/interfaces/IOwnable.sol


// pragma solidity 0.8.9;

interface IOwnable {
    error NotOwner();
    error InvalidOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}


// Dependency file: src/interfaces/IMintableCappedERC20.sol


// pragma solidity 0.8.9;

// import { IERC20 } from 'src/interfaces/IERC20.sol';
// import { IERC20Permit } from 'src/interfaces/IERC20Permit.sol';
// import { IOwnable } from 'src/interfaces/IOwnable.sol';

interface IMintableCappedERC20 is IERC20, IERC20Permit, IOwnable {
    error CapExceeded();

    function cap() external view returns (uint256);

    function mint(address account, uint256 amount) external;
}


// Dependency file: src/interfaces/IBurnableMintableCappedERC20.sol


// pragma solidity 0.8.9;

// import { IERC20Burn } from 'src/interfaces/IERC20Burn.sol';
// import { IERC20BurnFrom } from 'src/interfaces/IERC20BurnFrom.sol';
// import { IMintableCappedERC20 } from 'src/interfaces/IMintableCappedERC20.sol';

interface IBurnableMintableCappedERC20 is IERC20Burn, IERC20BurnFrom, IMintableCappedERC20 {
    error IsFrozen();

    function depositAddress(bytes32 salt) external view returns (address);

    function burn(bytes32 salt) external;

    function burnFrom(address account, uint256 amount) external;
}


// Dependency file: src/interfaces/ITokenDeployer.sol


// pragma solidity 0.8.9;

interface ITokenDeployer {
    function deployToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        uint256 cap,
        bytes32 salt
    ) external returns (address tokenAddress);
}


// Dependency file: src/DepositHandler.sol


// pragma solidity 0.8.9;

contract DepositHandler {
    error IsLocked();

    uint256 internal constant IS_NOT_LOCKED = uint256(1);
    uint256 internal constant IS_LOCKED = uint256(2);

    uint256 internal _lockedStatus = IS_NOT_LOCKED;

    modifier noReenter() {
        if (_lockedStatus == IS_LOCKED) revert IsLocked();

        _lockedStatus = IS_LOCKED;
        _;
        _lockedStatus = IS_NOT_LOCKED;
    }

    function execute(address callee, bytes calldata data)
        external
        noReenter
        returns (bool success, bytes memory returnData)
    {
        if (callee.code.length != 0) {
            (success, returnData) = callee.call(data);
        }
    }

    // NOTE: The gateway should always destroy the `DepositHandler` in the same runtime context that deploys it.
    function destroy(address etherDestination) external noReenter {
        selfdestruct(payable(etherDestination));
    }
}


// Dependency file: src/EternalStorage.sol


// pragma solidity 0.8.9;

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


// Dependency file: src/AdminMultisigBase.sol


// pragma solidity 0.8.9;

// import { EternalStorage } from 'src/EternalStorage.sol';

contract AdminMultisigBase is EternalStorage {
    error NotAdmin();
    error AlreadyVoted();
    error InvalidAdmins();
    error InvalidAdminThreshold();
    error DuplicateAdmin(address admin);

    // AUDIT: slot names should be prefixed with some standard string
    bytes32 internal constant KEY_ADMIN_EPOCH = keccak256('admin-epoch');

    bytes32 internal constant PREFIX_ADMIN = keccak256('admin');
    bytes32 internal constant PREFIX_ADMIN_COUNT = keccak256('admin-count');
    bytes32 internal constant PREFIX_ADMIN_THRESHOLD = keccak256('admin-threshold');
    bytes32 internal constant PREFIX_ADMIN_VOTE_COUNTS = keccak256('admin-vote-counts');
    bytes32 internal constant PREFIX_ADMIN_VOTED = keccak256('admin-voted');
    bytes32 internal constant PREFIX_IS_ADMIN = keccak256('is-admin');

    // NOTE: Given the early void return, this modifier should be used with care on functions that return data.
    modifier onlyAdmin() {
        uint256 adminEpoch = _adminEpoch();

        if (!_isAdmin(adminEpoch, msg.sender)) revert NotAdmin();

        bytes32 topic = keccak256(msg.data);

        // Check that admin has not voted, then record that they have voted.
        if (_hasVoted(adminEpoch, topic, msg.sender)) revert AlreadyVoted();

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

        for (uint256 i; i < adminCount; ++i) {
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

        if (adminLength < threshold) revert InvalidAdmins();

        if (threshold == uint256(0)) revert InvalidAdminThreshold();

        _setAdminThreshold(adminEpoch, threshold);
        _setAdminCount(adminEpoch, adminLength);

        for (uint256 i; i < adminLength; ++i) {
            address account = accounts[i];

            // Check that the account wasn't already set as an admin for this epoch.
            if (_isAdmin(adminEpoch, account)) revert DuplicateAdmin(account);

            if (account == address(0)) revert InvalidAdmins();

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


// pragma solidity 0.8.9;

// import { IAxelarGateway } from 'src/interfaces/IAxelarGateway.sol';
// import { IERC20 } from 'src/interfaces/IERC20.sol';
// import { IERC20Burn } from 'src/interfaces/IERC20Burn.sol';
// import { IERC20BurnFrom } from 'src/interfaces/IERC20BurnFrom.sol';
// import { IBurnableMintableCappedERC20 } from 'src/interfaces/IBurnableMintableCappedERC20.sol';
// import { ITokenDeployer } from 'src/interfaces/ITokenDeployer.sol';

// import { DepositHandler } from 'src/DepositHandler.sol';
// import { AdminMultisigBase } from 'src/AdminMultisigBase.sol';

abstract contract AxelarGateway is IAxelarGateway, AdminMultisigBase {
    error NotSelf();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAmount();
    error InvalidTokenDeployer();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error TokenIsFrozen(string symbol);

    enum Role {
        Admin,
        Owner,
        Operator
    }

    enum TokenType {
        InternalBurnable,
        InternalBurnableFrom,
        External
    }

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 internal constant KEY_IMPLEMENTATION =
        bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    // AUDIT: slot names should be prefixed with some standard string
    bytes32 internal constant KEY_ALL_TOKENS_FROZEN = keccak256('all-tokens-frozen');

    bytes32 internal constant PREFIX_COMMAND_EXECUTED = keccak256('command-executed');
    bytes32 internal constant PREFIX_TOKEN_ADDRESS = keccak256('token-address');
    bytes32 internal constant PREFIX_TOKEN_TYPE = keccak256('token-type');
    bytes32 internal constant PREFIX_TOKEN_FROZEN = keccak256('token-frozen');
    bytes32 internal constant PREFIX_CONTRACT_CALL_APPROVED = keccak256('contract-call-approved');
    bytes32 internal constant PREFIX_CONTRACT_CALL_APPROVED_WITH_MINT = keccak256('contract-call-approved-with-mint');

    bytes32 internal constant SELECTOR_BURN_TOKEN = keccak256('burnToken');
    bytes32 internal constant SELECTOR_DEPLOY_TOKEN = keccak256('deployToken');
    bytes32 internal constant SELECTOR_MINT_TOKEN = keccak256('mintToken');
    bytes32 internal constant SELECTOR_APPROVE_CONTRACT_CALL = keccak256('approveContractCall');
    bytes32 internal constant SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT = keccak256('approveContractCallWithMint');
    bytes32 internal constant SELECTOR_TRANSFER_OPERATORSHIP = keccak256('transferOperatorship');
    bytes32 internal constant SELECTOR_TRANSFER_OWNERSHIP = keccak256('transferOwnership');

    uint8 internal constant OLD_KEY_RETENTION = 16;

    address internal immutable TOKEN_DEPLOYER_IMPLEMENTATION;

    constructor(address tokenDeployerImplementation) {
        if (tokenDeployerImplementation.code.length == 0) revert InvalidTokenDeployer();

        TOKEN_DEPLOYER_IMPLEMENTATION = tokenDeployerImplementation;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) revert NotSelf();

        _;
    }

    /******************\
    |* Public Methods *|
    \******************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external {
        _burnTokenFrom(msg.sender, symbol, amount);
        emit TokenSent(msg.sender, destinationChain, destinationAddress, symbol, amount);
    }

    function callContract(
        string calldata destinationChain,
        string calldata destinationContractAddress,
        bytes calldata payload
    ) external {
        emit ContractCall(msg.sender, destinationChain, destinationContractAddress, keccak256(payload), payload);
    }

    function callContractWithToken(
        string calldata destinationChain,
        string calldata destinationContractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external {
        _burnTokenFrom(msg.sender, symbol, amount);
        emit ContractCallWithToken(
            msg.sender,
            destinationChain,
            destinationContractAddress,
            keccak256(payload),
            payload,
            symbol,
            amount
        );
    }

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view override returns (bool) {
        return
            getBool(_getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash));
    }

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view override returns (bool) {
        return
            getBool(
                _getIsContractCallApprovedWithMintKey(
                    commandId,
                    sourceChain,
                    sourceAddress,
                    contractAddress,
                    payloadHash,
                    symbol,
                    amount
                )
            );
    }

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external override returns (bool valid) {
        bytes32 key = _getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, msg.sender, payloadHash);
        valid = getBool(key);
        if (valid) _setBool(key, false);
    }

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external override returns (bool valid) {
        bytes32 key = _getIsContractCallApprovedWithMintKey(
            commandId,
            sourceChain,
            sourceAddress,
            msg.sender,
            payloadHash,
            symbol,
            amount
        );
        valid = getBool(key);
        if (valid) {
            _setBool(key, false);
            _mintToken(symbol, msg.sender, amount);
        }
    }

    /***********\
    |* Getters *|
    \***********/

    function allTokensFrozen() external view override returns (bool) {
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

    /// @dev Returns the current `adminEpoch`.
    function adminEpoch() external view override returns (uint256) {
        return _adminEpoch();
    }

    /// @dev Returns the admin threshold for a given `adminEpoch`.
    function adminThreshold(uint256 epoch) external view override returns (uint256) {
        return _getAdminThreshold(epoch);
    }

    /// @dev Returns the array of admins within a given `adminEpoch`.
    function admins(uint256 epoch) external view override returns (address[] memory results) {
        uint256 adminCount = _getAdminCount(epoch);
        results = new address[](adminCount);

        for (uint256 i; i < adminCount; ++i) {
            results[i] = _getAdmin(epoch, i);
        }
    }

    /*******************\
    |* Admin Functions *|
    \*******************/

    function freezeToken(string calldata symbol) external override onlyAdmin {
        _setBool(_getFreezeTokenKey(symbol), true);

        emit TokenFrozen(symbol);
    }

    function unfreezeToken(string calldata symbol) external override onlyAdmin {
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

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external override onlyAdmin {
        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        emit Upgraded(newImplementation);

        // AUDIT: If `newImplementation.setup` performs `selfdestruct`, it will result in the loss of _this_ implementation (thereby losing the gateway)
        //        if `upgrade` is entered within the context of _this_ implementation itself.
        if (setupParams.length != 0) {
            (bool success, ) = newImplementation.delegatecall(
                abi.encodeWithSelector(IAxelarGateway.setup.selector, setupParams)
            );

            if (!success) revert SetupFailed();
        }

        _setImplementation(newImplementation);
    }

    /**********************\
    |* Internal Functions *|
    \**********************/

    function _burnTokenFrom(
        address sender,
        string memory symbol,
        uint256 amount
    ) internal {
        address tokenAddress = tokenAddresses(symbol);

        if (tokenAddress == address(0)) revert TokenDoesNotExist(symbol);
        if (amount == 0) revert InvalidAmount();

        TokenType tokenType = _getTokenType(symbol);
        bool burnSuccess;

        if (tokenType == TokenType.External) {
            _checkTokenStatus(symbol);

            burnSuccess = _callERC20Token(
                tokenAddress,
                abi.encodeWithSelector(IERC20.transferFrom.selector, sender, address(this), amount)
            );

            if (!burnSuccess) revert BurnFailed(symbol);

            return;
        }

        if (tokenType == TokenType.InternalBurnableFrom) {
            burnSuccess = _callERC20Token(
                tokenAddress,
                abi.encodeWithSelector(IERC20BurnFrom.burnFrom.selector, sender, amount)
            );

            if (!burnSuccess) revert BurnFailed(symbol);

            return;
        }

        burnSuccess = _callERC20Token(
            tokenAddress,
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                sender,
                IBurnableMintableCappedERC20(tokenAddress).depositAddress(bytes32(0)),
                amount
            )
        );

        if (!burnSuccess) revert BurnFailed(symbol);

        IERC20Burn(tokenAddress).burn(bytes32(0));
    }

    function _deployToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        address tokenAddress
    ) internal {
        // Ensure that this symbol has not been taken.
        if (tokenAddresses(symbol) != address(0)) revert TokenAlreadyExists(symbol);

        if (tokenAddress == address(0)) {
            // If token address is no specified, it indicates a request to deploy one.
            bytes32 salt = keccak256(abi.encodePacked(symbol));

            (bool success, bytes memory data) = TOKEN_DEPLOYER_IMPLEMENTATION.delegatecall(
                abi.encodeWithSelector(ITokenDeployer.deployToken.selector, name, symbol, decimals, cap, salt)
            );

            if (!success) revert TokenDeployFailed(symbol);

            tokenAddress = abi.decode(data, (address));

            _setTokenType(symbol, TokenType.InternalBurnableFrom);
        } else {
            // If token address is specified, ensure that there is a contact at the specified address.
            if (tokenAddress.code.length == uint256(0)) revert TokenContractDoesNotExist(tokenAddress);

            // Mark that this symbol is an external token, which is needed to differentiate between operations on mint and burn.
            _setTokenType(symbol, TokenType.External);
        }

        _setTokenAddress(symbol, tokenAddress);

        emit TokenDeployed(symbol, tokenAddress);
    }

    function _mintToken(
        string memory symbol,
        address account,
        uint256 amount
    ) internal {
        address tokenAddress = tokenAddresses(symbol);

        if (tokenAddress == address(0)) revert TokenDoesNotExist(symbol);

        if (_getTokenType(symbol) == TokenType.External) {
            _checkTokenStatus(symbol);

            bool success = _callERC20Token(
                tokenAddress,
                abi.encodeWithSelector(IERC20.transfer.selector, account, amount)
            );

            if (!success) revert MintFailed(symbol);
        } else {
            IBurnableMintableCappedERC20(tokenAddress).mint(account, amount);
        }
    }

    function _burnToken(string memory symbol, bytes32 salt) internal {
        address tokenAddress = tokenAddresses(symbol);

        if (tokenAddress == address(0)) revert TokenDoesNotExist(symbol);

        if (_getTokenType(symbol) == TokenType.External) {
            _checkTokenStatus(symbol);

            DepositHandler depositHandler = new DepositHandler{ salt: salt }();

            (bool success, bytes memory returnData) = depositHandler.execute(
                tokenAddress,
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    address(this),
                    IERC20(tokenAddress).balanceOf(address(depositHandler))
                )
            );

            if (!success || (returnData.length != uint256(0) && !abi.decode(returnData, (bool))))
                revert BurnFailed(symbol);

            // NOTE: `depositHandler` must always be destroyed in the same runtime context that it is deployed.
            depositHandler.destroy(address(this));
        } else {
            IERC20Burn(tokenAddress).burn(salt);
        }
    }

    function _approveContractCall(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    ) internal {
        _setContractCallApproved(commandId, sourceChain, sourceAddress, contractAddress, payloadHash);
        emit ContractCallApproved(
            commandId,
            sourceChain,
            sourceAddress,
            contractAddress,
            payloadHash,
            sourceTxHash,
            sourceEventIndex
        );
    }

    function _approveContractCallWithMint(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string memory symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    ) internal {
        _setContractCallApprovedWithMint(
            commandId,
            sourceChain,
            sourceAddress,
            contractAddress,
            payloadHash,
            symbol,
            amount
        );
        emit ContractCallApprovedWithMint(
            commandId,
            sourceChain,
            sourceAddress,
            contractAddress,
            payloadHash,
            symbol,
            amount,
            sourceTxHash,
            sourceEventIndex
        );
    }

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getTokenTypeKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_TYPE, symbol));
    }

    function _getFreezeTokenKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_FROZEN, symbol));
    }

    function _getTokenAddressKey(string memory symbol) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_TOKEN_ADDRESS, symbol));
    }

    function _getIsCommandExecutedKey(bytes32 commandId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_COMMAND_EXECUTED, commandId));
    }

    function _getIsContractCallApprovedKey(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PREFIX_CONTRACT_CALL_APPROVED,
                    commandId,
                    sourceChain,
                    sourceAddress,
                    contractAddress,
                    payloadHash
                )
            );
    }

    function _getIsContractCallApprovedWithMintKey(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string memory symbol,
        uint256 amount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PREFIX_CONTRACT_CALL_APPROVED_WITH_MINT,
                    commandId,
                    sourceChain,
                    sourceAddress,
                    contractAddress,
                    payloadHash,
                    symbol,
                    amount
                )
            );
    }

    /********************\
    |* Internal Methods *|
    \********************/

    function _callERC20Token(address tokenAddress, bytes memory callData) internal returns (bool) {
        (bool success, bytes memory returnData) = tokenAddress.call(callData);
        return success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

    /********************\
    |* Internal Getters *|
    \********************/

    function _getTokenType(string memory symbol) internal view returns (TokenType) {
        return TokenType(getUint(_getTokenTypeKey(symbol)));
    }

    function _checkTokenStatus(string memory symbol) internal view {
        if (tokenFrozen(symbol) || getBool(KEY_ALL_TOKENS_FROZEN)) revert TokenIsFrozen(symbol);
    }

    /********************\
    |* Internal Setters *|
    \********************/

    function _setTokenType(string memory symbol, TokenType tokenType) internal {
        _setUint(_getTokenTypeKey(symbol), uint256(tokenType));
    }

    function _setTokenAddress(string memory symbol, address tokenAddress) internal {
        _setAddress(_getTokenAddressKey(symbol), tokenAddress);
    }

    function _setCommandExecuted(bytes32 commandId, bool executed) internal {
        _setBool(_getIsCommandExecutedKey(commandId), executed);
    }

    function _setContractCallApproved(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) internal {
        _setBool(
            _getIsContractCallApprovedKey(commandId, sourceChain, sourceAddress, contractAddress, payloadHash),
            true
        );
    }

    function _setContractCallApprovedWithMint(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string memory symbol,
        uint256 amount
    ) internal {
        _setBool(
            _getIsContractCallApprovedWithMintKey(
                commandId,
                sourceChain,
                sourceAddress,
                contractAddress,
                payloadHash,
                symbol,
                amount
            ),
            true
        );
    }

    function _setImplementation(address newImplementation) internal {
        _setAddress(KEY_IMPLEMENTATION, newImplementation);
    }
}


// Root file: src/AxelarGatewayMultisig.sol


pragma solidity 0.8.9;

// import { IAxelarGatewayMultisig } from 'src/interfaces/IAxelarGatewayMultisig.sol';

// import { ECDSA } from 'src/ECDSA.sol';
// import { AxelarGateway } from 'src/AxelarGateway.sol';

contract AxelarGatewayMultisig is IAxelarGatewayMultisig, AxelarGateway {
    error InvalidAddress();
    error InvalidOwners();
    error InvalidOwnerThreshold();
    error DuplicateOwner(address owner);
    error InvalidOperators();
    error InvalidOperatorThreshold();
    error DuplicateOperator(address operator);
    error NotProxy();
    error InvalidChainId();
    error MalformedSigners();
    error InvalidCommands();

    // AUDIT: slot names should be prefixed with some standard string
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

    constructor(address tokenDeployer) AxelarGateway(tokenDeployer) {}

    function _isSortedAscAndContainsNoDuplicate(address[] memory accounts) internal pure returns (bool) {
        for (uint256 i; i < accounts.length - 1; ++i) {
            if (accounts[i] >= accounts[i + 1]) {
                return false;
            }
        }

        return true;
    }

    /************************\
    |* Owners Functionality *|
    \************************/

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getOwnerKey(uint256 epoch, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OWNER, epoch, index));
    }

    function _getOwnerCountKey(uint256 epoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OWNER_COUNT, epoch));
    }

    function _getOwnerThresholdKey(uint256 epoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OWNER_THRESHOLD, epoch));
    }

    function _getIsOwnerKey(uint256 epoch, address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_IS_OWNER, epoch, account));
    }

    /***********\
    |* Getters *|
    \***********/

    function _ownerEpoch() internal view returns (uint256) {
        return getUint(KEY_OWNER_EPOCH);
    }

    function _getOwner(uint256 epoch, uint256 index) internal view returns (address) {
        return getAddress(_getOwnerKey(epoch, index));
    }

    function _getOwnerCount(uint256 epoch) internal view returns (uint256) {
        return getUint(_getOwnerCountKey(epoch));
    }

    function _getOwnerThreshold(uint256 epoch) internal view returns (uint256) {
        return getUint(_getOwnerThresholdKey(epoch));
    }

    function _isOwner(uint256 epoch, address account) internal view returns (bool) {
        return getBool(_getIsOwnerKey(epoch, account));
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are owners within the last `OLD_KEY_RETENTION + 1` owner epochs (excluding the current one).
    function _areValidPreviousOwners(address[] memory accounts) internal view returns (bool) {
        uint256 epoch = _ownerEpoch();
        uint256 recentEpochs = OLD_KEY_RETENTION + uint256(1);
        uint256 lowerBoundOwnerEpoch = epoch > recentEpochs ? epoch - recentEpochs : uint256(0);

        --epoch;
        while (epoch > lowerBoundOwnerEpoch) {
            if (_areValidOwnersInEpoch(epoch--, accounts)) return true;
        }

        return false;
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are owners in the `ownerEpoch`.
    function _areValidOwnersInEpoch(uint256 epoch, address[] memory accounts) internal view returns (bool) {
        uint256 threshold = _getOwnerThreshold(epoch);
        uint256 validSignerCount;

        for (uint256 i; i < accounts.length; ++i) {
            if (_isOwner(epoch, accounts[i]) && ++validSignerCount >= threshold) return true;
        }

        return false;
    }

    /// @dev Returns the current `ownerEpoch`.
    function ownerEpoch() external view override returns (uint256) {
        return _ownerEpoch();
    }

    /// @dev Returns the threshold for a given `ownerEpoch`.
    function ownerThreshold(uint256 epoch) external view override returns (uint256) {
        return _getOwnerThreshold(epoch);
    }

    /// @dev Returns the array of owners within a given `ownerEpoch`.
    function owners(uint256 epoch) public view override returns (address[] memory results) {
        uint256 ownerCount = _getOwnerCount(epoch);
        results = new address[](ownerCount);

        for (uint256 i; i < ownerCount; ++i) {
            results[i] = _getOwner(epoch, i);
        }
    }

    /***********\
    |* Setters *|
    \***********/

    function _setOwnerEpoch(uint256 epoch) internal {
        _setUint(KEY_OWNER_EPOCH, epoch);
    }

    function _setOwner(
        uint256 epoch,
        uint256 index,
        address account
    ) internal {
        if (account == address(0)) revert InvalidAddress();

        _setAddress(_getOwnerKey(epoch, index), account);
    }

    function _setOwnerCount(uint256 epoch, uint256 ownerCount) internal {
        _setUint(_getOwnerCountKey(epoch), ownerCount);
    }

    function _setOwners(
        uint256 epoch,
        address[] memory accounts,
        uint256 threshold
    ) internal {
        uint256 accountLength = accounts.length;

        if (accountLength < threshold) revert InvalidOwners();

        if (threshold == uint256(0)) revert InvalidOwnerThreshold();

        _setOwnerThreshold(epoch, threshold);
        _setOwnerCount(epoch, accountLength);

        for (uint256 i; i < accountLength; ++i) {
            address account = accounts[i];

            // Check that the account wasn't already set as an owner for this ownerEpoch.
            if (_isOwner(epoch, account)) revert DuplicateOwner(account);

            if (account == address(0)) revert InvalidOwners();

            // Set this account as the i-th owner in this ownerEpoch (needed so we can get all the owners for `owners`).
            _setOwner(epoch, i, account);
            _setIsOwner(epoch, account, true);
        }
    }

    function _setOwnerThreshold(uint256 epoch, uint256 threshold) internal {
        _setUint(_getOwnerThresholdKey(epoch), threshold);
    }

    function _setIsOwner(
        uint256 epoch,
        address account,
        bool isOwner
    ) internal {
        _setBool(_getIsOwnerKey(epoch, account), isOwner);
    }

    /**************************\
    |* Operator Functionality *|
    \**************************/

    /********************\
    |* Pure Key Getters *|
    \********************/

    function _getOperatorKey(uint256 epoch, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OPERATOR, epoch, index));
    }

    function _getOperatorCountKey(uint256 epoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OPERATOR_COUNT, epoch));
    }

    function _getOperatorThresholdKey(uint256 epoch) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_OPERATOR_THRESHOLD, epoch));
    }

    function _getIsOperatorKey(uint256 epoch, address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PREFIX_IS_OPERATOR, epoch, account));
    }

    /***********\
    |* Getters *|
    \***********/

    function _operatorEpoch() internal view returns (uint256) {
        return getUint(KEY_OPERATOR_EPOCH);
    }

    function _getOperator(uint256 epoch, uint256 index) internal view returns (address) {
        return getAddress(_getOperatorKey(epoch, index));
    }

    function _getOperatorCount(uint256 epoch) internal view returns (uint256) {
        return getUint(_getOperatorCountKey(epoch));
    }

    function _getOperatorThreshold(uint256 epoch) internal view returns (uint256) {
        return getUint(_getOperatorThresholdKey(epoch));
    }

    function _isOperator(uint256 epoch, address account) internal view returns (bool) {
        return getBool(_getIsOperatorKey(epoch, account));
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are operator in the same `operatorEpoch`, within the last `OLD_KEY_RETENTION + 1` operator epochs.
    function _areValidRecentOperators(address[] memory accounts) internal view returns (bool) {
        uint256 epoch = _operatorEpoch();
        uint256 recentEpochs = OLD_KEY_RETENTION + uint256(1);
        uint256 lowerBoundOperatorEpoch = epoch > recentEpochs ? epoch - recentEpochs : uint256(0);

        while (epoch > lowerBoundOperatorEpoch) {
            if (_areValidOperatorsInEpoch(epoch--, accounts)) return true;
        }

        return false;
    }

    /// @dev Returns true if a sufficient quantity of `accounts` are operator in the `operatorEpoch`.
    function _areValidOperatorsInEpoch(uint256 epoch, address[] memory accounts) internal view returns (bool) {
        uint256 threshold = _getOperatorThreshold(epoch);
        uint256 validSignerCount;

        for (uint256 i; i < accounts.length; ++i) {
            if (_isOperator(epoch, accounts[i]) && ++validSignerCount >= threshold) return true;
        }

        return false;
    }

    /// @dev Returns the current `operatorEpoch`.
    function operatorEpoch() external view override returns (uint256) {
        return _operatorEpoch();
    }

    /// @dev Returns the threshold for a given `operatorEpoch`.
    function operatorThreshold(uint256 epoch) external view override returns (uint256) {
        return _getOperatorThreshold(epoch);
    }

    /// @dev Returns the array of operators within a given `operatorEpoch`.
    function operators(uint256 epoch) public view override returns (address[] memory results) {
        uint256 operatorCount = _getOperatorCount(epoch);
        results = new address[](operatorCount);

        for (uint256 i; i < operatorCount; ++i) {
            results[i] = _getOperator(epoch, i);
        }
    }

    /***********\
    |* Setters *|
    \***********/

    function _setOperatorEpoch(uint256 epoch) internal {
        _setUint(KEY_OPERATOR_EPOCH, epoch);
    }

    function _setOperator(
        uint256 epoch,
        uint256 index,
        address account
    ) internal {
        _setAddress(_getOperatorKey(epoch, index), account);
    }

    function _setOperatorCount(uint256 epoch, uint256 operatorCount) internal {
        _setUint(_getOperatorCountKey(epoch), operatorCount);
    }

    function _setOperators(
        uint256 epoch,
        address[] memory accounts,
        uint256 threshold
    ) internal {
        uint256 accountLength = accounts.length;

        if (accountLength < threshold) revert InvalidOperators();

        if (threshold == uint256(0)) revert InvalidOperatorThreshold();

        _setOperatorThreshold(epoch, threshold);
        _setOperatorCount(epoch, accountLength);

        for (uint256 i; i < accountLength; ++i) {
            address account = accounts[i];

            // Check that the account wasn't already set as an operator for this operatorEpoch.
            if (_isOperator(epoch, account)) revert DuplicateOperator(account);

            if (account == address(0)) revert InvalidOperators();

            // Set this account as the i-th operator in this operatorEpoch (needed so we can get all the operators for `operators`).
            _setOperator(epoch, i, account);
            _setIsOperator(epoch, account, true);
        }
    }

    function _setOperatorThreshold(uint256 epoch, uint256 threshold) internal {
        _setUint(_getOperatorThresholdKey(epoch), threshold);
    }

    function _setIsOperator(
        uint256 epoch,
        address account,
        bool isOperator
    ) internal {
        _setBool(_getIsOperatorKey(epoch, account), isOperator);
    }

    /**********************\
    |* Self Functionality *|
    \**********************/

    function deployToken(bytes calldata params, bytes32) external onlySelf {
        (string memory name, string memory symbol, uint8 decimals, uint256 cap, address tokenAddr) = abi.decode(
            params,
            (string, string, uint8, uint256, address)
        );

        _deployToken(name, symbol, decimals, cap, tokenAddr);
    }

    function mintToken(bytes calldata params, bytes32) external onlySelf {
        (string memory symbol, address account, uint256 amount) = abi.decode(params, (string, address, uint256));

        _mintToken(symbol, account, amount);
    }

    function burnToken(bytes calldata params, bytes32) external onlySelf {
        (string memory symbol, bytes32 salt) = abi.decode(params, (string, bytes32));

        _burnToken(symbol, salt);
    }

    function approveContractCall(bytes calldata params, bytes32 commandId) external onlySelf {
        (
            string memory sourceChain,
            string memory sourceAddress,
            address contractAddress,
            bytes32 payloadHash,
            bytes32 sourceTxHash,
            uint256 sourceEventIndex
        ) = abi.decode(params, (string, string, address, bytes32, bytes32, uint256));

        _approveContractCall(
            commandId,
            sourceChain,
            sourceAddress,
            contractAddress,
            payloadHash,
            sourceTxHash,
            sourceEventIndex
        );
    }

    function approveContractCallWithMint(bytes calldata params, bytes32 commandId) external onlySelf {
        (
            string memory sourceChain,
            string memory sourceAddress,
            address contractAddress,
            bytes32 payloadHash,
            string memory symbol,
            uint256 amount,
            bytes32 sourceTxHash,
            uint256 sourceEventIndex
        ) = abi.decode(params, (string, string, address, bytes32, string, uint256, bytes32, uint256));

        _approveContractCallWithMint(
            commandId,
            sourceChain,
            sourceAddress,
            contractAddress,
            payloadHash,
            symbol,
            amount,
            sourceTxHash,
            sourceEventIndex
        );
    }

    function transferOwnership(bytes calldata params, bytes32) external onlySelf {
        (address[] memory newOwners, uint256 newThreshold) = abi.decode(params, (address[], uint256));

        uint256 epoch = _ownerEpoch();

        emit OwnershipTransferred(owners(epoch), _getOwnerThreshold(epoch), newOwners, newThreshold);

        _setOwnerEpoch(++epoch);
        _setOwners(epoch, newOwners, newThreshold);
    }

    function transferOperatorship(bytes calldata params, bytes32) external onlySelf {
        (address[] memory newOperators, uint256 newThreshold) = abi.decode(params, (address[], uint256));

        uint256 epoch = _operatorEpoch();

        emit OperatorshipTransferred(operators(epoch), _getOperatorThreshold(epoch), newOperators, newThreshold);

        _setOperatorEpoch(++epoch);
        _setOperators(epoch, newOperators, newThreshold);
    }

    /**************************\
    |* External Functionality *|
    \**************************/

    function setup(bytes calldata params) external override {
        // Prevent setup from being called on a non-proxy (the implementation).
        if (implementation() == address(0)) revert NotProxy();

        (
            address[] memory adminAddresses,
            uint256 newAdminThreshold,
            address[] memory ownerAddresses,
            uint256 newOwnerThreshold,
            address[] memory operatorAddresses,
            uint256 newOperatorThreshold
        ) = abi.decode(params, (address[], uint256, address[], uint256, address[], uint256));

        // NOTE: Admin epoch is incremented to easily invalidate current admin-related state.
        uint256 newAdminEpoch = _adminEpoch() + uint256(1);
        _setAdminEpoch(newAdminEpoch);
        _setAdmins(newAdminEpoch, adminAddresses, newAdminThreshold);

        uint256 newOwnerEpoch = _ownerEpoch() + uint256(1);
        _setOwnerEpoch(newOwnerEpoch);
        _setOwners(newOwnerEpoch, ownerAddresses, newOwnerThreshold);

        uint256 newOperatorEpoch = _operatorEpoch() + uint256(1);
        _setOperatorEpoch(newOperatorEpoch);
        _setOperators(newOperatorEpoch, operatorAddresses, newOperatorThreshold);

        emit OwnershipTransferred(new address[](uint256(0)), uint256(0), ownerAddresses, newOwnerThreshold);
        emit OperatorshipTransferred(new address[](uint256(0)), uint256(0), operatorAddresses, newOperatorThreshold);

        // We would need to delete AXL token for the very release and therefore and re-deploy it
        // with the latest token code that has the potential to support token refund in the future.
        // This is a one-time thing and should be gotten rid of right after release.
        _setTokenAddress('AXL', address(0));
    }

    function execute(bytes calldata input) external override {
        (bytes memory data, bytes[] memory signatures) = abi.decode(input, (bytes, bytes[]));

        _execute(data, signatures);
    }

    function _execute(bytes memory data, bytes[] memory signatures) internal {
        uint256 signatureCount = signatures.length;

        address[] memory signers = new address[](signatureCount);

        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(data));

        for (uint256 i; i < signatureCount; ++i) {
            signers[i] = ECDSA.recover(messageHash, signatures[i]);
        }

        (
            uint256 chainId,
            Role signersRole,
            bytes32[] memory commandIds,
            string[] memory commands,
            bytes[] memory params
        ) = abi.decode(data, (uint256, Role, bytes32[], string[], bytes[]));

        if (chainId != block.chainid) revert InvalidChainId();

        if (!_isSortedAscAndContainsNoDuplicate(signers)) revert MalformedSigners();

        uint256 commandsLength = commandIds.length;

        if (commandsLength != commands.length || commandsLength != params.length) revert InvalidCommands();

        bool areValidCurrentOwners;
        bool areValidRecentOwners;
        bool areValidRecentOperators;

        if (signersRole == Role.Owner) {
            areValidCurrentOwners = _areValidOwnersInEpoch(_ownerEpoch(), signers);
            areValidRecentOwners = areValidCurrentOwners || _areValidPreviousOwners(signers);
        } else if (signersRole == Role.Operator) {
            areValidRecentOperators = _areValidRecentOperators(signers);
        }

        for (uint256 i; i < commandsLength; ++i) {
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
            } else if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL) {
                if (!areValidRecentOperators && !areValidRecentOwners) continue;

                commandSelector = AxelarGatewayMultisig.approveContractCall.selector;
            } else if (commandHash == SELECTOR_APPROVE_CONTRACT_CALL_WITH_MINT) {
                if (!areValidRecentOperators && !areValidRecentOwners) continue;

                commandSelector = AxelarGatewayMultisig.approveContractCallWithMint.selector;
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
            (bool success, ) = address(this).call(abi.encodeWithSelector(commandSelector, params[i], commandId));
            _setCommandExecuted(commandId, success);

            if (success) {
                emit Executed(commandId);
            }
        }
    }
}