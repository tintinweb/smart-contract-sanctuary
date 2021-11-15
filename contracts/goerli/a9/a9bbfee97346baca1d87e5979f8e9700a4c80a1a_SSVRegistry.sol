// File: contracts/SSVRegistry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ISSVRegistry.sol";

contract SSVRegistry is Initializable, OwnableUpgradeable, ISSVRegistry {
    uint256 public operatorCount;
    uint256 public validatorCount;

    mapping(bytes => Operator) public override operators;
    mapping(bytes => Validator) internal validators;

    mapping(bytes => OperatorFee[]) private operatorFees;

    mapping(address => bytes[]) private operatorsByAddress;
    mapping(address => bytes[]) private validatorsByAddress;

    function initialize() public virtual override initializer {
        __SSVRegistry_init();
    }

    function __SSVRegistry_init() internal initializer {
        __Ownable_init_unchained();
        __SSVRegistry_init_unchained();
    }

    function __SSVRegistry_init_unchained() internal initializer {
    }

    function getValidatorOwner(bytes calldata _publicKey) onlyOwner external override view returns (address) {
        return validators[_publicKey].ownerAddress;
    }

    function getOperatorOwner(bytes calldata _publicKey) onlyOwner external override view returns (address) {
        return operators[_publicKey].ownerAddress;
    }

    function _validateValidatorParams(
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) private pure {
        require(_publicKey.length == 48, "Invalid public key length");
        require(
            _operatorPublicKeys.length == _sharesPublicKeys.length &&
                _operatorPublicKeys.length == _encryptedKeys.length,
            "OESS data structure is not valid"
        );
    }

    /**
     * @dev See {ISSVRegistry-registerOperator}.
     */
    function registerOperator(
        string calldata _name,
        address _ownerAddress,
        bytes calldata _publicKey,
        uint256 _fee
    ) onlyOwner public virtual override {
        require(
            operators[_publicKey].ownerAddress == address(0),
            "Operator with same public key already exists"
        );
        operators[_publicKey] = Operator(_name, _ownerAddress, _publicKey, 0, false, operatorsByAddress[_ownerAddress].length);
        operatorsByAddress[_ownerAddress].push(_publicKey);
        emit OperatorAdded(_name, _ownerAddress, _publicKey);
        operatorCount++;
        updateOperatorFee(_publicKey, _fee);
        activateOperator(_publicKey);
    }

    /**
     * @dev See {ISSVRegistry-registerValidator}.
     */
    function registerValidator(
        address _ownerAddress,
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) onlyOwner public virtual override {
        _validateValidatorParams(
            _publicKey,
            _operatorPublicKeys,
            _sharesPublicKeys,
            _encryptedKeys
        );
        require(_ownerAddress != address(0), "Owner address invalid");
        require(
            validators[_publicKey].ownerAddress == address(0),
            "Validator with same public key already exists"
        );

        Validator storage validatorItem = validators[_publicKey];
        validatorItem.publicKey = _publicKey;
        validatorItem.ownerAddress = _ownerAddress;

        for (uint256 index = 0; index < _operatorPublicKeys.length; ++index) {
            validatorItem.oess.push(
                Oess(
                    index,
                    _operatorPublicKeys[index],
                    _sharesPublicKeys[index],
                    _encryptedKeys[index]
                )
            );
        }
        validatorItem.index = validatorsByAddress[_ownerAddress].length;
        validatorsByAddress[_ownerAddress].push(_publicKey);
        validatorCount++;
        emit ValidatorAdded(_ownerAddress, _publicKey, validatorItem.oess);
        activateValidator(_publicKey);
    }

    /**
     * @dev See {ISSVRegistry-updateValidator}.
     */
    function updateValidator(
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) onlyOwner public virtual override {
        _validateValidatorParams(
            _publicKey,
            _operatorPublicKeys,
            _sharesPublicKeys,
            _encryptedKeys
        );
        Validator storage validatorItem = validators[_publicKey];
        delete validatorItem.oess;

        for (uint256 index = 0; index < _operatorPublicKeys.length; ++index) {
            validatorItem.oess.push(
                Oess(
                    index,
                    _operatorPublicKeys[index],
                    _sharesPublicKeys[index],
                    _encryptedKeys[index]
                )
            );
        }

        emit ValidatorUpdated(validatorItem.ownerAddress, _publicKey, validatorItem.oess);
    }

    /**
     * @dev See {ISSVRegistry-deleteValidator}.
     */
    function deleteValidator(
        address _ownerAddress,
        bytes calldata _publicKey
    ) onlyOwner public virtual override {
        Validator storage validatorItem = validators[_publicKey];
        validatorsByAddress[_ownerAddress][validatorItem.index] = validatorsByAddress[_ownerAddress][validatorsByAddress[_ownerAddress].length - 1];
        validatorsByAddress[_ownerAddress].pop();
        validators[validatorsByAddress[_ownerAddress][validatorItem.index]].index = validatorItem.index;
        delete validators[_publicKey];

        --validatorCount;

        emit ValidatorDeleted(_ownerAddress, _publicKey);
    }

    /**
     * @dev See {ISSVRegistry-deleteOperator}.
     */
    function deleteOperator(
        address _ownerAddress,
        bytes calldata _publicKey
    ) onlyOwner public virtual override {
        Operator storage operatorItem = operators[_publicKey];
        operatorsByAddress[_ownerAddress][operatorItem.index] = operatorsByAddress[_ownerAddress][operatorsByAddress[_ownerAddress].length - 1];

        operatorsByAddress[_ownerAddress].pop();
        operators[operatorsByAddress[_ownerAddress][operatorItem.index]].index = operatorItem.index;
        delete operators[_publicKey];

        --operatorCount;

        emit OperatorDeleted(operatorItem.name, _publicKey);
    }

    /**
     * @dev See {ISSVRegistry-getOperatorCurrentFee}.
     */
    function getOperatorCurrentFee(bytes calldata _operatorPubKey) onlyOwner public view override returns (uint256) {
        require(operatorFees[_operatorPubKey].length > 0, "Operator fees not found");
        return operatorFees[_operatorPubKey][operatorFees[_operatorPubKey].length - 1].fee;
    }

    /**
     * @dev See {ISSVRegistry-getValidatorUsage}.
     */
    function getValidatorUsage(
        bytes calldata _pubKey,
        uint256 _fromBlockNumber,
        uint256 _toBlockNumber
    ) onlyOwner public view override returns (uint256 usage) {
        for (uint256 index = 0; index < validators[_pubKey].oess.length; ++index) {
            Oess memory oessItem = validators[_pubKey].oess[index];
            uint256 lastBlockNumber = _toBlockNumber;
            bool oldestFeeUsed = false;
            for (uint256 feeReverseIndex = 0; !oldestFeeUsed && feeReverseIndex < operatorFees[oessItem.operatorPublicKey].length; ++feeReverseIndex) {
                uint256 feeIndex = operatorFees[oessItem.operatorPublicKey].length - feeReverseIndex - 1;
                if (operatorFees[oessItem.operatorPublicKey][feeIndex].blockNumber < lastBlockNumber) {
                    uint256 startBlockNumber = Math.max(_fromBlockNumber, operatorFees[oessItem.operatorPublicKey][feeIndex].blockNumber);
                    usage += (lastBlockNumber - startBlockNumber) * operatorFees[oessItem.operatorPublicKey][feeIndex].fee;
                    if (startBlockNumber == _fromBlockNumber) {
                        oldestFeeUsed = true;
                    } else {
                        lastBlockNumber = startBlockNumber;
                    }
                }
            }
        }
    }

    /**
     * @dev See {ISSVRegistry-updateOperatorFee}.
     */
    function updateOperatorFee(bytes calldata _pubKey, uint256 _fee) onlyOwner public virtual override {
        operatorFees[_pubKey].push(
            OperatorFee(block.number, _fee)
        );
        emit OperatorFeeUpdated(_pubKey, block.number, _fee);
    }

    function getOperatorPubKeysInUse(bytes calldata _validatorPubKey) onlyOwner public virtual override returns (bytes[] memory operatorPubKeys) {
        Validator storage validatorItem = validators[_validatorPubKey];

        operatorPubKeys = new bytes[](validatorItem.oess.length);
        for (uint256 index = 0; index < validatorItem.oess.length; ++index) {
            operatorPubKeys[index] = validatorItem.oess[index].operatorPublicKey;
        }
    }

    function getOperatorsByAddress(address _ownerAddress) onlyOwner external view virtual override returns (bytes[] memory) {
        return operatorsByAddress[_ownerAddress];
    }

    function getValidatorsByAddress(address _ownerAddress) onlyOwner external view virtual override returns (bytes[] memory) {
        return validatorsByAddress[_ownerAddress];
    }

    function activateOperator(bytes calldata _pubKey) onlyOwner override public {
        require(!operators[_pubKey].active, "already active");
        operators[_pubKey].active = true;

        emit OperatorActive(operators[_pubKey].ownerAddress, _pubKey);
    }

    function deactivateOperator(bytes calldata _pubKey) onlyOwner override external {
        require(operators[_pubKey].active, "already inactive");
        operators[_pubKey].active = false;

        emit OperatorInactive(operators[_pubKey].ownerAddress, _pubKey);
    }

    function activateValidator(bytes calldata _pubKey) onlyOwner override public {
        require(!validators[_pubKey].active, "already active");
        validators[_pubKey].active = true;

        emit ValidatorActive(validators[_pubKey].ownerAddress, _pubKey);
    }

    function deactivateValidator(bytes calldata _pubKey) onlyOwner override external {
        require(validators[_pubKey].active, "already inactive");
        validators[_pubKey].active = false;

        emit ValidatorInactive(validators[_pubKey].ownerAddress, _pubKey);
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ISSVRegistry {
    struct Oess {
        uint256 index;
        bytes operatorPublicKey;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

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

    function initialize() external;

    /**
     * @dev Register new validator.
     * @param _ownerAddress The user's ethereum address that is the owner of the validator.
     * @param _publicKey Validator public key.
     * @param _operatorPublicKeys Operator public keys.
     * @param _sharesPublicKeys Shares public keys.
     * @param _encryptedKeys Encrypted private keys.
     */
    function registerValidator(
        address _ownerAddress,
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) external;

    /**
     * @dev Register new operator.
     * @param _name Operator's display name.
     * @param _ownerAddress Operator's ethereum address that can collect fees.
     * @param _publicKey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
     */
    function registerOperator(
        string calldata _name,
        address _ownerAddress,
        bytes calldata _publicKey,
        uint256 _fee
    ) external;

    /**
     * @dev Gets an operator by public key.
     * @param _publicKey Operator's Public Key.
     */
    function operators(bytes calldata _publicKey)
        external
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            bool,
            uint256
        );

    function getValidatorOwner(bytes calldata _publicKey) external view returns (address);

    function getOperatorOwner(bytes calldata _publicKey) external view returns (address);

    /**
     * @dev Gets an operator public keys by owner address.
     * @param _ownerAddress Owner Address.
     */
    function getOperatorsByAddress(address _ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Gets a validator public keys by owner address.
     * @param _ownerAddress Owner Address.
     */
    function getValidatorsByAddress(address _ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Emitted when the operator has been added.
     * @param name Opeator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
     */
    event OperatorAdded(string name, address ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deleted.
     * @param publicKey Operator's Public Key.
     */
    event OperatorDeleted(string name, bytes publicKey);

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
     * @dev Emitted when the validator has been deleted.
     * @param publicKey Operator's Public Key.
     */
    event ValidatorDeleted(address ownerAddress, bytes publicKey);

    /**
     * @param validatorPublicKey The public key of a validator.
     * @param index Operator index.
     * @param operatorPublicKey Operator public key.
     * @param sharedPublicKey Share public key.
     * @param encryptedKey Encrypted private key.
     */
    event OessAdded(
        bytes validatorPublicKey,
        uint256 index,
        bytes operatorPublicKey,
        bytes sharedPublicKey,
        bytes encryptedKey
    );

    event ValidatorActive(address ownerAddress, bytes publicKey);
    event ValidatorInactive(address ownerAddress, bytes publicKey);

    event OperatorActive(address ownerAddress, bytes publicKey);
    event OperatorInactive(address ownerAddress, bytes publicKey);

    /**
     * @dev Updates a validator in the list.
     * @param _publicKey Validator public key.
     * @param _operatorPublicKeys Operator public keys.
     * @param _sharesPublicKeys Shares public keys.
     * @param _encryptedKeys Encrypted private keys.
     */
    function updateValidator(
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) external;

    /**
     * @dev Deletes a validator from the list.
     * @param _ownerAddress The user's ethereum address that is the owner of the validator.
     * @param _publicKey Validator public key.
     */
    function deleteValidator(
        address _ownerAddress,
        bytes calldata _publicKey
    ) external;

    /**
     * @dev Deletes an operator from the list.
     * @param _ownerAddress The user's ethereum address that is the owner of the operator.
     * @param _publicKey Operator public key.
     */
    function deleteOperator(
        address _ownerAddress,
        bytes calldata _publicKey
    ) external;

    /**
     * @dev Gets operator current fee.
     * @param _operatorPublicKey Operator public key.
     */
    function getOperatorCurrentFee(bytes calldata _operatorPublicKey)
        external view
        returns (uint256);

    /**
     * @dev Gets validator usage fees.
     * @param _pubKey Validator public key.
     * @param _fromBlockNumber from which block number.
     * @param _toBlockNumber to which block number.
     */
    function getValidatorUsage(bytes calldata _pubKey, uint256 _fromBlockNumber, uint256 _toBlockNumber)
        external view
        returns (uint256);

    /**
     * @dev Update an operator fee.
     * @param _pubKey Operator's public key.
     * @param _fee new operator fee.
     */
    function updateOperatorFee(
        bytes calldata _pubKey,
        uint256 _fee
    ) external;

    /**
     * @param pubKey Operator's public key.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeUpdated(
        bytes pubKey,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Get operators list which are in use of validator.
     * @param _validatorPubKey Validator public key.
     */
    function getOperatorPubKeysInUse(bytes calldata _validatorPubKey)
        external
        returns (bytes[] memory);

    function activateValidator(bytes calldata _pubKey) external;
    function deactivateValidator(bytes calldata _pubKey) external;

    function activateOperator(bytes calldata _pubKey) external;
    function deactivateOperator(bytes calldata _pubKey) external;
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

