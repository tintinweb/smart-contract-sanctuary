// File: contracts/SSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ISSVRegistry.sol";

contract SSVRegistry is Initializable, OwnableUpgradeable, ISSVRegistry {
    struct Operator {
        string name;
        address ownerAddress;
        bytes publicKey;
        uint256 score;
        bool active;
        uint256 index;
    }

    struct Validator {
        address ownerAddress;
        bytes publicKey;
        Oess[] oess;
        bool active;
        uint256 index;
    }

    struct OperatorFee {
        uint256 blockNumber;
        uint256 fee;
    }

    uint256 private _operatorCount;
    uint256 private _validatorCount;
    uint256 private _activeValidatorCount;

    mapping(bytes => Operator) private _operators;
    mapping(bytes => Validator) private _validators;

    mapping(bytes => OperatorFee[]) private _operatorFees;

    mapping(address => bytes[]) private _operatorsByOwnerAddress;
    mapping(address => bytes[]) private _validatorsByAddress;

    /**
     * @dev See {ISSVRegistry-initialize}.
     */
    function initialize() external override initializer {
        __SSVRegistry_init();
    }

    function __SSVRegistry_init() internal initializer {
        __Ownable_init_unchained();
        __SSVRegistry_init_unchained();
    }

    function __SSVRegistry_init_unchained() internal initializer {
    }

    /**
     * @dev See {ISSVRegistry-registerOperator}.
     */
    function registerOperator(
        string calldata name,
        address ownerAddress,
        bytes calldata publicKey,
        uint256 fee
    ) external onlyOwner override {
        require(
            _operators[publicKey].ownerAddress == address(0),
            "operator with same public key already exists"
        );
        _operators[publicKey] = Operator(name, ownerAddress, publicKey, 0, false, _operatorsByOwnerAddress[ownerAddress].length);
        _operatorsByOwnerAddress[ownerAddress].push(publicKey);
        _updateOperatorFeeUnsafe(publicKey, fee);
        _activateOperatorUnsafe(publicKey);

        emit OperatorAdded(name, ownerAddress, publicKey);
    }

    /**
     * @dev See {ISSVRegistry-deleteOperator}.
     */
    function deleteOperator(
        bytes calldata publicKey
    ) external onlyOwner override {
        Operator storage operator = _operators[publicKey];
        _operatorsByOwnerAddress[operator.ownerAddress][operator.index] = _operatorsByOwnerAddress[operator.ownerAddress][_operatorsByOwnerAddress[operator.ownerAddress].length - 1];
        _operators[_operatorsByOwnerAddress[operator.ownerAddress][operator.index]].index = operator.index;
        _operatorsByOwnerAddress[operator.ownerAddress].pop();

        emit OperatorDeleted(operator.ownerAddress, publicKey);

        delete _operators[publicKey];
        --_operatorCount;

    }

    /**
     * @dev See {ISSVRegistry-activateOperator}.
     */
    function activateOperator(bytes calldata publicKey) external onlyOwner override {
        _activateOperatorUnsafe(publicKey);
    }

    /**
     * @dev See {ISSVRegistry-deactivateOperator}.
     */
    function deactivateOperator(bytes calldata publicKey) external onlyOwner override {
        _deactivateOperatorUnsafe(publicKey);
    }

    /**
     * @dev See {ISSVRegistry-updateOperatorFee}.
     */
    function updateOperatorFee(bytes calldata publicKey, uint256 fee) external onlyOwner override {
        _updateOperatorFeeUnsafe(publicKey, fee);
    }

    /**
     * @dev See {ISSVRegistry-updateOperatorScore}.
     */
    function updateOperatorScore(bytes calldata publicKey, uint256 score) external onlyOwner override {
        Operator storage operator = _operators[publicKey];
        operator.score = score;

        emit OperatorScoreUpdated(operator.ownerAddress, publicKey, block.number, score);
    }

    /**
     * @dev See {ISSVRegistry-registerValidator}.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external onlyOwner override {
        _validateValidatorParams(
            publicKey,
            operatorPublicKeys,
            sharesPublicKeys,
            encryptedKeys
        );
        require(ownerAddress != address(0), "owner address invalid");
        require(
            _validators[publicKey].ownerAddress == address(0),
            "validator with same public key already exists"
        );

        Validator storage validator = _validators[publicKey];
        validator.publicKey = publicKey;
        validator.ownerAddress = ownerAddress;

        for (uint256 index = 0; index < operatorPublicKeys.length; ++index) {
            validator.oess.push(
                Oess(
                    operatorPublicKeys[index],
                    sharesPublicKeys[index],
                    encryptedKeys[index]
                )
            );
        }

        validator.index = _validatorsByAddress[ownerAddress].length;
        _validatorsByAddress[ownerAddress].push(publicKey);

        ++_validatorCount;

        _activateValidatorUnsafe(publicKey);

        emit ValidatorAdded(ownerAddress, publicKey, validator.oess);
    }

    /**
     * @dev See {ISSVRegistry-updateValidator}.
     */
    function updateValidator(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external onlyOwner override {
        _validateValidatorParams(
            publicKey,
            operatorPublicKeys,
            sharesPublicKeys,
            encryptedKeys
        );
        Validator storage validator = _validators[publicKey];
        delete validator.oess;

        for (uint256 index = 0; index < operatorPublicKeys.length; ++index) {
            validator.oess.push(
                Oess(
                    operatorPublicKeys[index],
                    sharesPublicKeys[index],
                    encryptedKeys[index]
                )
            );
        }

        emit ValidatorUpdated(validator.ownerAddress, publicKey, validator.oess);
    }

    /**
     * @dev See {ISSVRegistry-deleteValidator}.
     */
    function deleteValidator(
        bytes calldata publicKey
    ) external onlyOwner override {
        Validator storage validator = _validators[publicKey];
        _validatorsByAddress[validator.ownerAddress][validator.index] = _validatorsByAddress[validator.ownerAddress][_validatorsByAddress[validator.ownerAddress].length - 1];
        _validators[_validatorsByAddress[validator.ownerAddress][validator.index]].index = validator.index;
        _validatorsByAddress[validator.ownerAddress].pop();

        --_validatorCount;
        --_activeValidatorCount;

        emit ValidatorDeleted(validator.ownerAddress, publicKey);

        delete _validators[publicKey];
    }

    /**
     * @dev See {ISSVRegistry-activateValidator}.
     */
    function activateValidator(bytes calldata publicKey) external onlyOwner override {
        _activateValidatorUnsafe(publicKey);
    }

    /**
     * @dev See {ISSVRegistry-deactivateValidator}.
     */
    function deactivateValidator(bytes calldata publicKey) external onlyOwner override {
        _deactivateValidatorUnsafe(publicKey);
    }

    /**
     * @dev See {ISSVRegistry-operatorCount}.
     */
    function operatorCount() external view override returns (uint256) {
        return _operatorCount;
    }

    /**
     * @dev See {ISSVRegistry-operators}.
     */
    function operators(bytes calldata publicKey) external view override returns (string memory, address, bytes memory, uint256, bool, uint256) {
        Operator storage operator = _operators[publicKey];
        return (operator.name, operator.ownerAddress, operator.publicKey, operator.score, operator.active, operator.index);
    }

    /**
     * @dev See {ISSVRegistry-getOperatorsByOwnerAddress}.
     */
    function getOperatorsByOwnerAddress(address ownerAddress) external view override returns (bytes[] memory) {
        return _operatorsByOwnerAddress[ownerAddress];
    }

    /**
     * @dev See {ISSVRegistry-getOperatorsByValidator}.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey) external view override returns (bytes[] memory operatorPublicKeys) {
        Validator storage validator = _validators[validatorPublicKey];

        operatorPublicKeys = new bytes[](validator.oess.length);
        for (uint256 index = 0; index < validator.oess.length; ++index) {
            operatorPublicKeys[index] = validator.oess[index].operatorPublicKey;
        }
    }

    /**
     * @dev See {ISSVRegistry-getOperatorOwner}.
     */
    function getOperatorOwner(bytes calldata publicKey) onlyOwner external override view returns (address) {
        return _operators[publicKey].ownerAddress;
    }

    /**
     * @dev See {ISSVRegistry-getOperatorCurrentFee}.
     */
    function getOperatorCurrentFee(bytes calldata operatorPublicKey) external view override returns (uint256) {
        require(_operatorFees[operatorPublicKey].length > 0, "operator not found");
        return _operatorFees[operatorPublicKey][_operatorFees[operatorPublicKey].length - 1].fee;
    }

    /**
     * @dev See {ISSVRegistry-validatorCount}.
     */
    function validatorCount() external view override returns (uint256) {
        return _validatorCount;
    }

    /**
     * @dev See {ISSVRegistry-validators}.
     */
    function validators(bytes calldata publicKey) external view override returns (address, bytes memory, bool, uint256) {
        Validator storage validator = _validators[publicKey];

        return (validator.ownerAddress, validator.publicKey, validator.active, validator.index);
    }

    /**
     * @dev See {ISSVRegistry-getValidatorsByAddress}.
     */
    function getValidatorsByAddress(address ownerAddress) external view override returns (bytes[] memory) {
        return _validatorsByAddress[ownerAddress];
    }

    /**
     * @dev See {ISSVRegistry-getValidatorOwner}.
     */
    function getValidatorOwner(bytes calldata publicKey) external view override returns (address) {
        return _validators[publicKey].ownerAddress;
    }

    /**
     * @dev See {ISSVRegistry-activateOperator}.
     */
    function _activateOperatorUnsafe(bytes calldata publicKey) private {
        require(!_operators[publicKey].active, "already active");
        _operators[publicKey].active = true;
        ++_operatorCount;

        emit OperatorActivated(_operators[publicKey].ownerAddress, publicKey);
    }

    /**
     * @dev See {ISSVRegistry-deactivateOperator}.
     */
    function _deactivateOperatorUnsafe(bytes calldata publicKey) private {
        require(_operators[publicKey].active, "already inactive");
        _operators[publicKey].active = false;
        --_operatorCount;

        emit OperatorInactivated(_operators[publicKey].ownerAddress, publicKey);
    }

    /**
     * @dev See {ISSVRegistry-updateOperatorFee}.
     */
    function _updateOperatorFeeUnsafe(bytes calldata publicKey, uint256 fee) private {
        _operatorFees[publicKey].push(
            OperatorFee(block.number, fee)
        );

        emit OperatorFeeUpdated(_operators[publicKey].ownerAddress, publicKey, block.number, fee);
    }

    /**
     * @dev See {ISSVRegistry-activateValidator}.
     */
    function _activateValidatorUnsafe(bytes calldata publicKey) private {
        require(!_validators[publicKey].active, "already active");
        _validators[publicKey].active = true;
        ++_activeValidatorCount;

        emit ValidatorActivated(_validators[publicKey].ownerAddress, publicKey);
    }

    /**
     * @dev See {ISSVRegistry-deactivateValidator}.
     */
    function _deactivateValidatorUnsafe(bytes calldata publicKey) private {
        require(_validators[publicKey].active, "already inactive");
        _validators[publicKey].active = false;
        --_activeValidatorCount;

        emit ValidatorInactivated(_validators[publicKey].ownerAddress, publicKey);
    }

    /**
     * @dev Validates the paramss for a validator.
     * @param publicKey Validator public key.
     * @param operatorPublicKeys Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function _validateValidatorParams(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) private pure {
        require(publicKey.length == 48, "invalid public key length");
        require(
            operatorPublicKeys.length == sharesPublicKeys.length &&
            operatorPublicKeys.length == encryptedKeys.length &&
            operatorPublicKeys.length >= 4 && operatorPublicKeys.length % 3 == 1,
            "OESS data structure is not valid"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// File: contracts/ISSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ISSVRegistry {
    struct Oess {
        bytes operatorPublicKey;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

    /**
     * @dev Emitted when the operator has been added.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     */
    event OperatorAdded(string name, address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deleted.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorDeleted(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been activated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorActivated(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deactivated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorInactivated(address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeUpdated(
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when an operator's score is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param score updated score value.
     */
    event OperatorScoreUpdated(
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 score
    );

    /**
     * @dev Emitted when the validator has been added.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param oessList The OESS list for this validator.
     */
    event ValidatorAdded(
        address ownerAddress,
        bytes publicKey,
        Oess[] oessList
    );

    /**
     * @dev Emitted when the validator has been updated.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     * @param oessList The OESS list for this validator.
     */
    event ValidatorUpdated(
        address ownerAddress,
        bytes publicKey,
        Oess[] oessList
    );

    /**
     * @dev Emitted when the validator is deleted.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorDeleted(address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the validator is activated.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorActivated(address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the validator is deactivated.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorInactivated(address ownerAddress, bytes publicKey);

    /**
     * @dev Initializes the contract
     */
    function initialize() external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee The fee which the operator charges for each block.
     */
    function registerOperator(string calldata name, address ownerAddress, bytes calldata publicKey, uint256 fee) external;

    /**
     * @dev Deletes an operator.
     * @param publicKey Operator public key.
     */
    function deleteOperator(bytes calldata publicKey) external;

    /**
     * @dev Activates an operator.
     * @param publicKey Operator public key.
     */
    function activateOperator(bytes calldata publicKey) external;

    /**
     * @dev Deactivates an operator.
     * @param publicKey Operator public key.
     */
    function deactivateOperator(bytes calldata publicKey) external;

    /**
     * @dev Updates an operator fee.
     * @param publicKey Operator's public key.
     * @param fee new operator fee.
     */
    function updateOperatorFee(
        bytes calldata publicKey,
        uint256 fee
    ) external;

    /**
     * @dev Updates an operator fee.
     * @param publicKey Operator's public key.
     * @param score New score.
     */
    function updateOperatorScore(
        bytes calldata publicKey,
        uint256 score
    ) external;

    /**
     * @dev Registers a new validator.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey Validator public key.
     * @param operatorPublicKeys Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external;

    /**
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param operatorPublicKeys Operator public keys.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function updateValidator(
        bytes calldata publicKey,
        bytes[] calldata operatorPublicKeys,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external;

    /**
     * @dev Deletes a validator.
     * @param publicKey Validator's public key.
     */
    function deleteValidator(bytes calldata publicKey) external;

    /**
     * @dev Activates a validator.
     * @param publicKey Validator's public key.
     */
    function activateValidator(bytes calldata publicKey) external;

    /**
     * @dev Deactivates a validator.
     * @param publicKey Validator's public key.
     */
    function deactivateValidator(bytes calldata publicKey) external;


    /**
     * @dev Returns the operator count.
     */
    function operatorCount() external view returns (uint256);

    /**
     * @dev Gets an operator by public key.
     * @param publicKey Operator's public key.
     */
    function operators(bytes calldata publicKey)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            bool,
            uint256
        );

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets operator's owner.
     * @param publicKey Operator's public key.
     */
    function getOperatorOwner(bytes calldata publicKey) external view returns (address);

    /**
     * @dev Gets operator current fee.
     * @param publicKey Operator's public key.
     */
    function getOperatorCurrentFee(bytes calldata publicKey)
        external view
        returns (uint256);

    /**
     * @dev Gets validators count.
     */
    function validatorCount() external view returns (uint256);

    /**
     * @dev Gets an validator by public key.
     * @param publicKey Validator's public key.
     */
    function validators(bytes calldata publicKey)
        external view
        returns (
            address,
            bytes memory,
            bool,
            uint256
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Get validator's owner.
     * @param publicKey Validator's public key.
     */
    function getValidatorOwner(bytes calldata publicKey) external view returns (address);
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