// File: contracts/SSVNetwork.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
 
contract SSVNetwork {
  uint256 public operatorCount;

  struct Operator {
    string name;
    address pubkey;
    uint256 score;
    address paymentAddress;
  }

  mapping(uint => Operator) private operators;

  /**
   * @dev Emitted when the operator has been added.
   * @param name Opeator's display name.
   * @param pubkey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
   * @param score A rating parameter to evaluate operators by.
   * @param paymentAddress Operator's ethereum address that can collect fees.
   */
  event OperatorAdded(string name, address pubkey, uint256 score, address paymentAddress);

  /**
   * @dev Add new operator to the list.
   * @param _name Opeator's display name.
   * @param _pubkey Operator's Public Key. Will be used to encrypt secret shares of validators keys.
   * @param _score A rating parameter to evaluate operators by.
   * @param _paymentAddress Operator's ethereum address that can collect fees.
   */
  function addOperator(string memory _name, address _pubkey, uint256 _score, address _paymentAddress) public {
    operators[operatorCount] = Operator(_name, _pubkey, _score, _paymentAddress);
    emit OperatorAdded(_name, _pubkey, _score, _paymentAddress);
    operatorCount++;
  }

  function tmp() public {
  }
}

{
  "optimizer": {
    "enabled": false,
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