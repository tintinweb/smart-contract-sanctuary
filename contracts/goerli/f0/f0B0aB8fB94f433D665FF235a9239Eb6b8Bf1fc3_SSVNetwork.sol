// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ISSVNetwork.sol";

contract SSVNetwork is ISSVNetwork {
    uint256 public operatorCount;
    uint256 public validatorCount;

    mapping(bytes => Operator) public override operators;
    mapping(bytes => Validator) internal validators;

    modifier onlyValidator(bytes calldata _publicKey) {
        require(
            validators[_publicKey].ownerAddress != address(0),
            "Validator with public key is not exists"
        );
        require(msg.sender == validators[_publicKey].ownerAddress, "Caller is not validator owner");
        _;
    }

    modifier onlyOperator(bytes calldata _publicKey) {
        require(
            operators[_publicKey].ownerAddress != address(0),
            "Operator with public key is not exists"
        );
        require(msg.sender == operators[_publicKey].ownerAddress, "Caller is not operator owner");
        _;
    }

    function _validateValidatorParams(
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) private view {
        require(_publicKey.length == 48, "Invalid public key length");
        require(
            _operatorPublicKeys.length == _sharesPublicKeys.length &&
                _operatorPublicKeys.length == _encryptedKeys.length,
            "OESS data structure is not valid"
        );
    }

    /**
     * @dev See {ISSVNetwork-addOperator}.
     */
    function addOperator(
        string calldata _name,
        address _ownerAddress,
        bytes calldata _publicKey
    ) public virtual override {
        require(
            operators[_publicKey].ownerAddress == address(0),
            "Operator with same public key already exists"
        );

        operators[_publicKey] = Operator(_name, _ownerAddress, _publicKey, 0);

        emit OperatorAdded(_name, _ownerAddress, _publicKey);

        operatorCount++;
    }

    /**
     * @dev See {ISSVNetwork-addValidator}.
     */
    function addValidator(
        address _ownerAddress,
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) public virtual override {
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

        validatorCount++;
        emit ValidatorAdded(_ownerAddress, _publicKey, validatorItem.oess);
    }

    /**
     * @dev See {ISSVNetwork-updateValidator}.
     */
    function updateValidator(
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) onlyValidator(_publicKey) public virtual override {
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
     * @dev See {ISSVNetwork-deleteValidator}.
     */
    function deleteValidator(
        bytes calldata _publicKey
    ) onlyValidator(_publicKey) public virtual override {
        address ownerAddress = validators[_publicKey].ownerAddress;
        delete validators[_publicKey];
        validatorCount--;
        emit ValidatorDeleted(ownerAddress, _publicKey);
    }

    /**
     * @dev See {ISSVNetwork-deleteOperator}.
     */
    function deleteOperator(
        bytes calldata _publicKey
    ) onlyOperator(_publicKey) public virtual override {
        string memory name = operators[_publicKey].name;
        delete operators[_publicKey];
        operatorCount--;
        emit OperatorDeleted(name, _publicKey);
    }

    function deleteOperatorTestArt(
        bytes calldata _publicKey
    ) onlyOperator(_publicKey) public {
        string memory name = operators[_publicKey].name;
        delete operators[_publicKey];
        operatorCount--;
        emit OperatorDeleted(name, _publicKey);
    }
}

// File: contracts/ISSVNetwork.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ISSVNetwork {
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
    }

    struct Validator {
        address ownerAddress;
        bytes publicKey;
        Oess[] oess;
    }

    /**
     * @dev Add new validator to the list.
     * @param _ownerAddress The user's ethereum address that is the owner of the validator.
     * @param _publicKey Validator public key.
     * @param _operatorPublicKeys Operator public keys.
     * @param _sharesPublicKeys Shares public keys.
     * @param _encryptedKeys Encrypted private keys.
     */
    function addValidator(
        address _ownerAddress,
        bytes calldata _publicKey,
        bytes[] calldata _operatorPublicKeys,
        bytes[] calldata _sharesPublicKeys,
        bytes[] calldata _encryptedKeys
    ) external;

    /**
     * @dev Adds a new operator to the list.
     * @param _name Operator's display name.
     * @param _ownerAddress Operator's ethereum address that can collect fees.
     * @param _publicKey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
     */
    function addOperator(
        string calldata _name,
        address _ownerAddress,
        bytes calldata _publicKey
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
            uint256
        );

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
     * @param _publicKey Validator public key.
     */
    function deleteValidator(
        bytes calldata _publicKey
    ) external;

    /**
     * @dev Deletes an operator from the list.
     * @param _publicKey Operator public key.
     */
    function deleteOperator(
        bytes calldata _publicKey
    ) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}