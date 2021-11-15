// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract SSVNetwork {
  uint256 public operatorCount;
  uint256 public validatorCount;

  struct Operator {
    string name;
    bytes pubkey;
    uint256 score;
    address paymentAddress;
    bool isExists;
  }

  struct Oess {
    bytes operatorPubKey;
    uint index;
    bytes sharePubKey;
    bytes encryptedKey;
  }

  struct Validator {
    bytes pubkey;
    mapping(uint => Oess) oess;
    address ownerAddress;
    bool isExists;
  }

  mapping(bytes => Operator) private operators;

  mapping(bytes => Validator) internal validators;

  /**
   * @dev Emitted when the operator has been added.
   * @param name Opeator's display name.
   * @param pubkey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
   * @param paymentAddress Operator's ethereum address that can collect fees.
   */
  event OperatorAdded(string name, bytes pubkey, address paymentAddress);

  /**
   * @dev Emitted when the validator has been added.
   * @param pubkey The public key of a validator.
   * @param ownerAddress The user's ethereum address that is the owner of the validator.
   */
  event ValidatorAdded(bytes pubkey, address ownerAddress, bytes oess);

  function fromHexChar(uint8 c) internal pure returns (uint8) {
    if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
      return c - uint8(bytes1('0'));
    }
    if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
      return 10 + c - uint8(bytes1('a'));
    }
    if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
      return 10 + c - uint8(bytes1('A'));
    }
  }

  // Convert an hexadecimal string to raw bytes
  function fromHex(string memory s) internal pure returns (bytes memory) {
    bytes memory ss = bytes(s);
    require(ss.length%2 == 0); // length must be even
    bytes memory r = new bytes(ss.length/2);
    for (uint i=0; i<ss.length/2; ++i) {
      r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 + fromHexChar(uint8(ss[2*i+1])));
    }
    return r;
  }

  /**
   * @dev Add new operator to the list.
   * @param _name Opeator's display name.
   * @param _pubkey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
   * @param _paymentAddress Operator's ethereum address that can collect fees.
   */
  function addOperator(string calldata _name, string calldata _pubkey, address _paymentAddress) public {
    bytes memory publicKey = bytes(_pubkey);

    if (operators[publicKey].isExists) {
      revert('Operator with same public key already exists');
    }
    operators[publicKey] = Operator(_name, publicKey, 0, _paymentAddress, true);
    emit OperatorAdded(_name, publicKey, _paymentAddress);
    operatorCount++;
  }

  /**
   * @dev Add new validator to the list.
   * @param pubkey Validator public key.
   * @param operatorPubKeys Operator public keys.
   * @param indexes Operator indexes.
   * @param sharePubKeys Shares public keys.
   * @param encryptedKeys Encrypted private keys.
   * @param ownerAddress The user's ethereum address that is the owner of the validator.
   */
  function addValidator(
    string calldata pubkey,
    string[] calldata operatorPubKeys,
    uint[] calldata indexes,
    string[] calldata sharePubKeys,
    string[] calldata encryptedKeys,
    address ownerAddress
  ) public {
    bytes memory publicKey = fromHex(pubkey);
    require(publicKey.length == 48, pubkey);
    require(operatorPubKeys.length == sharePubKeys.length && sharePubKeys.length == encryptedKeys.length && indexes.length == encryptedKeys.length, 'OESS data structure is not valid');

    if (validators[publicKey].isExists) {
      revert('Validator with same public key already exists');
    }

    Validator storage validatorItem = validators[publicKey];
    validatorItem.pubkey = publicKey;
    validatorItem.ownerAddress = ownerAddress;
    bytes memory oessList;
    for(uint i=0; i< operatorPubKeys.length; i++) {
      validatorItem.oess[i] = Oess(fromHex(operatorPubKeys[i]), indexes[i], fromHex(sharePubKeys[i]), fromHex(encryptedKeys[i]));
      // that manipulation allows to merge into one string all oess struct items and split them with separator
      oessList = abi.encodePacked(oessList, 'oess-separator' , abi.encode(validatorItem.oess[i]));
    }
    emit ValidatorAdded(publicKey, ownerAddress, oessList);

    validatorCount++;
  }


  /**
   * @dev Get operator by public key.
   * @param pubkey Operator public key.
   */
  function getOperator(string calldata pubkey) public view returns (string memory, bytes memory, uint256, address) {
    bytes memory publicKey = bytes(pubkey);
  
    if (!operators[publicKey].isExists) {
      revert('Operator with public key not exists');
    }

    return (operators[publicKey].name, operators[publicKey].pubkey, operators[publicKey].score, operators[publicKey].paymentAddress);
  }  
}

