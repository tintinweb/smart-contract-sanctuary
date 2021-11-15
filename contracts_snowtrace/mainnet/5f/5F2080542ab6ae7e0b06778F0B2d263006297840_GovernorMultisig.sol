// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./Multiownable.sol";

contract GovernorMultisig is Multiownable {
  /// @notice The maximum number of actions that can be included in a transaction
  uint256 public constant MAX_OPERATIONS = 10; // 10 actions

  /**
   * @notice Execute target transactions with multisig.
   * @param targets Target addresses for transaction calls
   * @param values Eth values for transaction calls
   * @param signatures Function signatures for transaction calls
   * @param calldatas Calldatas for transaction calls
   */
  function executeTransaction(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas
  ) external onlyManyOwners {
    require(
      targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
      "GovernorMultisig::executeTransaction: function information arity mismatch"
    );
    require(targets.length != 0, "GovernorMultisig::executeTransaction: must provide actions");
    require(targets.length <= MAX_OPERATIONS, "GovernorMultisig::executeTransaction: too many actions");

    for (uint8 i = 0; i < targets.length; i++) {
      bytes memory callData = bytes(signatures[i]).length == 0
        ? calldatas[i]
        : abi.encodePacked(bytes4(keccak256(bytes(signatures[i]))), calldatas[i]);

      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = targets[i].call{value: values[i]}(callData);
      require(success, "GovernorMultisig::executeTransaction: transaction execution reverted");
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

/// @author https://github.com/bitclave/Multiownable
// solhint-disable private-vars-leading-underscore
contract Multiownable {
  // VARIABLES
  uint256 public ownersGeneration;
  uint256 public howManyOwnersDecide;
  address[] public owners;
  bytes32[] public allOperations;
  address internal insideCallSender;
  uint256 internal insideCallCount;

  // Reverse lookup tables for owners and allOperations
  mapping(address => uint256) public ownersIndices; // Starts from 1
  mapping(bytes32 => uint256) public allOperationsIndicies;

  // Owners voting mask per operations
  mapping(bytes32 => uint256) public votesMaskByOperation;
  mapping(bytes32 => uint256) public votesCountByOperation;

  // EVENTS

  event OwnershipTransferred(
    address[] previousOwners,
    uint256 howManyOwnersDecide,
    address[] newOwners,
    uint256 newHowManyOwnersDecide
  );
  event OperationCreated(bytes32 operation, uint256 howMany, uint256 ownersCount, address proposer);
  event OperationUpvoted(bytes32 operation, uint256 votes, uint256 howMany, uint256 ownersCount, address upvoter);
  event OperationPerformed(bytes32 operation, uint256 howMany, uint256 ownersCount, address performer);
  event OperationDownvoted(bytes32 operation, uint256 votes, uint256 ownersCount, address downvoter);
  event OperationCancelled(bytes32 operation, address lastCanceller);

  // ACCESSORS

  function isOwner(address wallet) public view returns (bool) {
    return ownersIndices[wallet] > 0;
  }

  function ownersCount() public view returns (uint256) {
    return owners.length;
  }

  function allOperationsCount() public view returns (uint256) {
    return allOperations.length;
  }

  // MODIFIERS

  /**
   * @dev Allows to perform method by any of the owners
   */
  modifier onlyAnyOwner() {
    if (checkHowManyOwners(1)) {
      bool update = (insideCallSender == address(0));
      if (update) {
        insideCallSender = msg.sender;
        insideCallCount = 1;
      }
      _;
      if (update) {
        insideCallSender = address(0);
        insideCallCount = 0;
      }
    }
  }

  /**
   * @dev Allows to perform method only after many owners call it with the same arguments
   */
  modifier onlyManyOwners() {
    if (checkHowManyOwners(howManyOwnersDecide)) {
      bool update = (insideCallSender == address(0));
      if (update) {
        insideCallSender = msg.sender;
        insideCallCount = howManyOwnersDecide;
      }
      _;
      if (update) {
        insideCallSender = address(0);
        insideCallCount = 0;
      }
    }
  }

  /**
   * @dev Allows to perform method only after all owners call it with the same arguments
   */
  modifier onlyAllOwners() {
    if (checkHowManyOwners(owners.length)) {
      bool update = (insideCallSender == address(0));
      if (update) {
        insideCallSender = msg.sender;
        insideCallCount = owners.length;
      }
      _;
      if (update) {
        insideCallSender = address(0);
        insideCallCount = 0;
      }
    }
  }

  /**
   * @dev Allows to perform method only after some owners call it with the same arguments
   */
  modifier onlySomeOwners(uint256 howMany) {
    require(howMany > 0, "onlySomeOwners: howMany argument is zero");
    require(howMany <= owners.length, "onlySomeOwners: howMany argument exceeds the number of owners");

    if (checkHowManyOwners(howMany)) {
      bool update = (insideCallSender == address(0));
      if (update) {
        insideCallSender = msg.sender;
        insideCallCount = howMany;
      }
      _;
      if (update) {
        insideCallSender = address(0);
        insideCallCount = 0;
      }
    }
  }

  // CONSTRUCTOR

  constructor() {
    owners.push(msg.sender);
    ownersIndices[msg.sender] = 1;
    howManyOwnersDecide = 1;
  }

  // INTERNAL METHODS

  /**
   * @dev onlyManyOwners modifier helper
   */
  function checkHowManyOwners(uint256 howMany) internal returns (bool) {
    if (insideCallSender == msg.sender) {
      require(howMany <= insideCallCount, "checkHowManyOwners: nested owners modifier check require more owners");
      return true;
    }

    require(ownersIndices[msg.sender] > 0, "checkHowManyOwners: msg.sender is not an owner");
    uint256 ownerIndex = ownersIndices[msg.sender] - 1;
    bytes32 operation = keccak256(abi.encodePacked(msg.data, ownersGeneration));

    require(
      (votesMaskByOperation[operation] & (2**ownerIndex)) == 0,
      "checkHowManyOwners: owner already voted for the operation"
    );
    votesMaskByOperation[operation] |= (2**ownerIndex);
    uint256 operationVotesCount = votesCountByOperation[operation] + 1;
    votesCountByOperation[operation] = operationVotesCount;
    if (operationVotesCount == 1) {
      allOperationsIndicies[operation] = allOperations.length;
      allOperations.push(operation);
      emit OperationCreated(operation, howMany, owners.length, msg.sender);
    }
    emit OperationUpvoted(operation, operationVotesCount, howMany, owners.length, msg.sender);

    // If enough owners confirmed the same operation
    if (votesCountByOperation[operation] == howMany) {
      deleteOperation(operation);
      emit OperationPerformed(operation, howMany, owners.length, msg.sender);
      return true;
    }

    return false;
  }

  /**
   * @dev Used to delete cancelled or performed operation
   * @param operation defines which operation to delete
   */
  function deleteOperation(bytes32 operation) internal {
    uint256 index = allOperationsIndicies[operation];
    if (index < allOperations.length - 1) {
      // Not last
      allOperations[index] = allOperations[allOperations.length - 1];
      allOperationsIndicies[allOperations[index]] = index;
    }
    allOperations.pop();

    delete votesMaskByOperation[operation];
    delete votesCountByOperation[operation];
    delete allOperationsIndicies[operation];
  }

  // PUBLIC METHODS

  /**
   * @dev Allows owners to change their mind by cacnelling votesMaskByOperation operations
   * @param operation defines which operation to delete
   */
  function cancelPending(bytes32 operation) public onlyAnyOwner {
    uint256 ownerIndex = ownersIndices[msg.sender] - 1;
    require(
      (votesMaskByOperation[operation] & (2**ownerIndex)) != 0,
      "cancelPending: operation not found for this user"
    );
    votesMaskByOperation[operation] &= ~(2**ownerIndex);
    uint256 operationVotesCount = votesCountByOperation[operation] - 1;
    votesCountByOperation[operation] = operationVotesCount;
    emit OperationDownvoted(operation, operationVotesCount, owners.length, msg.sender);
    if (operationVotesCount == 0) {
      deleteOperation(operation);
      emit OperationCancelled(operation, msg.sender);
    }
  }

  /**
   * @dev Allows owners to change ownership
   * @param newOwners defines array of addresses of new owners
   */
  function transferOwnership(address[] calldata newOwners) public {
    transferOwnershipWithHowMany(newOwners, newOwners.length);
  }

  /**
   * @dev Allows owners to change ownership
   * @param newOwners defines array of addresses of new owners
   * @param newHowManyOwnersDecide defines how many owners can decide
   */
  function transferOwnershipWithHowMany(address[] calldata newOwners, uint256 newHowManyOwnersDecide)
    public
    onlyManyOwners
  {
    require(newOwners.length > 0, "transferOwnershipWithHowMany: owners array is empty");
    require(newOwners.length <= 256, "transferOwnershipWithHowMany: owners count is greater then 256");
    require(newHowManyOwnersDecide > 0, "transferOwnershipWithHowMany: newHowManyOwnersDecide equal to 0");
    require(
      newHowManyOwnersDecide <= newOwners.length,
      "transferOwnershipWithHowMany: newHowManyOwnersDecide exceeds the number of owners"
    );

    // Reset owners reverse lookup table
    for (uint256 j = 0; j < owners.length; j++) {
      delete ownersIndices[owners[j]];
    }
    for (uint256 i = 0; i < newOwners.length; i++) {
      require(newOwners[i] != address(0), "transferOwnershipWithHowMany: owners array contains zero");
      require(ownersIndices[newOwners[i]] == 0, "transferOwnershipWithHowMany: owners array contains duplicates");
      ownersIndices[newOwners[i]] = i + 1;
    }

    emit OwnershipTransferred(owners, howManyOwnersDecide, newOwners, newHowManyOwnersDecide);
    owners = newOwners;
    howManyOwnersDecide = newHowManyOwnersDecide;
    delete allOperations;
    ownersGeneration++;
  }
}