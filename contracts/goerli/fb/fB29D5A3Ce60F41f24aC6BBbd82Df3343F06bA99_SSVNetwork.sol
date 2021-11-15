// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISSVNetwork.sol';

contract SSVNetwork is ISSVNetwork {
  uint256 public operatorCount;
  uint256 public validatorCount;

  mapping(bytes => Operator) public override operators;
  mapping(bytes => Validator) internal validators;

  /**
   * @dev See {ISSVNetwork-addOperator}.
   */
  function addOperator(string calldata _name, address _ownerAddress, bytes calldata _publicKey) virtual override public {
    require(operators[_publicKey].ownerAddress == address(0), 'Operator with same public key already exists');

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
  ) virtual override public {
    require(_publicKey.length == 48, 'Invalid public key length');
    require(_operatorPublicKeys.length == _sharesPublicKeys.length && _operatorPublicKeys.length == _encryptedKeys.length, 'OESS data structure is not valid');
    require(_ownerAddress != address(0), 'Owner address invalid');
    require(validators[_publicKey].ownerAddress == address(0), 'Validator with same public key already exists');

    Validator storage validatorItem = validators[_publicKey];
    validatorItem.publicKey = _publicKey;
    validatorItem.ownerAddress = _ownerAddress;

    for(uint index = 0; index < _operatorPublicKeys.length; ++index) {
      validatorItem.oess.push(Oess(index, _operatorPublicKeys[index], _sharesPublicKeys[index], _encryptedKeys[index]));
    }

    validatorCount++;
    emit ValidatorAdded(_ownerAddress, _publicKey, validatorItem.oess);
  }
}

// File: contracts/ISSVNetwork.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISSVNetwork {
  struct Oess {
    uint index;
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
  function addValidator(address _ownerAddress, bytes calldata _publicKey, bytes[] calldata _operatorPublicKeys, bytes[] calldata _sharesPublicKeys, bytes[] calldata _encryptedKeys) external;

  /**
   * @dev Adds a new operator to the list.
   * @param _name Operator's display name.
   * @param _ownerAddress Operator's ethereum address that can collect fees.
   * @param _publicKey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
   */
  function addOperator(string calldata _name, address _ownerAddress, bytes calldata _publicKey) external;

  /**
   * @dev Gets an operator by public key.
   * @param _publicKey Operator's Public Key.
   */
  function operators(bytes calldata _publicKey) external returns (string memory, address, bytes memory, uint256);

  /**
   * @dev Emitted when the operator has been added.
   * @param name Opeator's display name.
   * @param ownerAddress Operator's ethereum address that can collect fees.
   * @param publicKey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
   */
  event OperatorAdded(string name, address ownerAddress, bytes publicKey);

  /**
   * @dev Emitted when the validator has been added.
   * @param ownerAddress The user's ethereum address that is the owner of the validator.
   * @param publicKey The public key of a validator.
   * @param oessList The OESS list for this validator.
   */
  event ValidatorAdded(address ownerAddress, bytes publicKey, Oess[] oessList);

  /**
   * @param validatorPublicKey The public key of a validator.
   * @param index Operator index.
   * @param operatorPublicKey Operator public key.
   * @param sharedPublicKey Share public key.
   * @param encryptedKey Encrypted private key.
   */
  event OessAdded(bytes validatorPublicKey, uint index, bytes operatorPublicKey, bytes sharedPublicKey, bytes encryptedKey);
}

