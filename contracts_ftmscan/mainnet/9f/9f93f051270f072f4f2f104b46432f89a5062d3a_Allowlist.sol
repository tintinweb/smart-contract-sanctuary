// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./Strings.sol";
import "./Introspection.sol";

/*******************************************************
 *                      Interfaces
 *******************************************************/
interface IAllowlistFactory {
  function protocolOwnerAddressByOriginName(string memory originName)
    external
    view
    returns (address ownerAddress);
}

contract Allowlist {
  /**
   * id: ID of the condition (must be unique and contain no spaces.. ie. "VAULT_DEPOSIT")
   * methodName: Name of the method to validate (ie. "approve")
   * paramTypes: Param types of the method to validate (ie. ["address", "uint256"])
   * requirements: Array of requirements, where a requirement is as follows:
   *    Element 0: Requirement type (ie. "target" or "param")
   *    Element 1: Method name of validation method (ie. "isVaultToken")
   *    Element 2: Index of param to test as a string. Only applicable where requirement type is "param" (ie. "0")
   */
  struct Condition {
    string id;
    string methodName;
    string[] paramTypes;
    string[][] requirements;
    address implementationAddress;
  }

  string[] public conditionsIds; // Array of condition IDs
  mapping(string => Condition) public conditionById; // Condition ID to condition mapping
  string public protocolOriginName; // Domain name of protocol (ie. "yearn.finance")
  address public rootAllowlistAddress; // Address of root allowlist (parent/factory)

  /**
   * @notice Initialize the contract (this will only be called by proxy)
   * @param _protocolOriginName The domain name for the protocol (ie. "yearn.finance")
   */
  function initialize(string memory _protocolOriginName) public {
    require(
      rootAllowlistAddress == address(0),
      "Contract is already initialized"
    );
    rootAllowlistAddress = msg.sender;
    protocolOriginName = _protocolOriginName;
  }

  /*******************************************************
   *                     Owner logic
   *******************************************************/
  modifier onlyOwner() {
    require(
      msg.sender == ownerAddress() || msg.sender == address(0),
      "Caller is not the protocol owner"
    );
    _;
  }

  /**
   * @notice Fetch the controlling address for the protocol
   * @return protocolOwnerAddress The address of protocol owner
   */
  function ownerAddress() public view returns (address protocolOwnerAddress) {
    protocolOwnerAddress = IAllowlistFactory(rootAllowlistAddress)
      .protocolOwnerAddressByOriginName(protocolOriginName);
  }

  /*******************************************************
   *                   Condition CRUD Logic
   *******************************************************/

  /**
   * @dev Internal method for adding a condition
   * @dev Condition ID validation happens here (IDs must be unqiue and not have spaces)
   * @dev Actual condition validation does not happen here (it happens in "validateCondition(condition)")
   */
  function _addCondition(Condition memory condition) internal {
    // Condition ID must be unique
    bool conditionExists = !Strings.stringsEqual(
      conditionById[condition.id].id,
      ""
    );
    require(conditionExists == false, "Condition with this ID already exists");

    // Condition ID cannot have spaces
    bool idHasSpaces = Strings.indexOfStringInString(" ", condition.id) != -1;
    require(idHasSpaces == false, "Condition IDs cannot have spaces");

    // Add condition
    conditionById[condition.id] = condition;
    conditionsIds.push(condition.id);
  }

  /**
   * @notice Add a condition with validation
   * @param condition The condition to add
   */
  function addCondition(Condition memory condition) public onlyOwner {
    validateCondition(condition);
    _addCondition(condition);
  }

  /**
   * @notice Add multiple conditions with validation
   * @param _conditions The conditions to add
   */
  function addConditions(Condition[] memory _conditions) public onlyOwner {
    for (
      uint256 conditionIdx;
      conditionIdx < _conditions.length;
      conditionIdx++
    ) {
      Condition memory condition = _conditions[conditionIdx];
      addCondition(condition);
    }
  }

  /**
   * @notice Add a condition without validation
   * @param condition The condition to add
   */
  function addConditionWithoutValidation(Condition memory condition)
    public
    onlyOwner
  {
    _addCondition(condition);
  }

  /**
   * @notice Add multiple conditions without validation
   * @param _conditions The conditions to add
   */
  function addConditionsWithoutValidation(Condition[] memory _conditions)
    public
    onlyOwner
  {
    for (
      uint256 conditionIdx;
      conditionIdx < _conditions.length;
      conditionIdx++
    ) {
      Condition memory condition = _conditions[conditionIdx];
      addConditionWithoutValidation(condition);
    }
  }

  /**
   * @notice Delete a condition given an ID
   * @param conditionId The ID of the condition to delete
   */
  function deleteCondition(string memory conditionId) public onlyOwner {
    string memory lastConditionId = conditionsIds[conditionsIds.length - 1];
    for (
      uint256 conditionIdx;
      conditionIdx < conditionsIds.length;
      conditionIdx++
    ) {
      string memory currentConditionId = conditionsIds[conditionIdx];
      if (Strings.stringsEqual(currentConditionId, conditionId)) {
        conditionsIds[conditionIdx] = lastConditionId;
        conditionsIds.pop();
        delete conditionById[conditionId];
        return;
      }
    }
    revert("Cannot find condition with that ID");
  }

  /**
   * @notice Delete multiple conditions given a list of IDs
   * @param _conditionsIds A list of condition IDs to delete
   */
  function deleteConditions(string[] memory _conditionsIds) public onlyOwner {
    for (
      uint256 conditionIdx;
      conditionIdx < _conditionsIds.length;
      conditionIdx++
    ) {
      string memory conditionId = _conditionsIds[conditionIdx];
      deleteCondition(conditionId);
    }
  }

  /**
   * @notice Delete every condition
   */
  function deleteAllConditions() public onlyOwner {
    uint256 _conditionsLength = conditionsIds.length;
    for (
      uint256 conditionIdx;
      conditionIdx < _conditionsLength;
      conditionIdx++
    ) {
      string memory conditionId = conditionsIds[conditionIdx];
      deleteCondition(conditionId);
    }
  }

  /**
   * @notice Update a condition
   * @param conditionId The ID of the condition to update
   * @param condition The new condition
   */
  function updateCondition(
    string memory conditionId,
    Condition memory condition
  ) public onlyOwner {
    deleteCondition(conditionId);
    addCondition(condition);
  }

  /**
   * @notice Fetch a list of conditions
   * @return Returns all conditions
   */
  function conditionsList() public view returns (Condition[] memory) {
    Condition[] memory _conditions = new Condition[](conditionsIds.length);
    for (
      uint256 conditionIdx;
      conditionIdx < conditionsIds.length;
      conditionIdx++
    ) {
      _conditions[conditionIdx] = conditionById[conditionsIds[conditionIdx]];
    }
    return _conditions;
  }

  /**
   * @notice Fetch a list of all condition IDs
   * @return An array of condition IDs
   */
  function conditionsIdsList() public view returns (string[] memory) {
    return conditionsIds;
  }

  /**
   * @notice Fetch the total number of conditions in this contract
   * @return Returns length of conditionIds
   */
  function conditionsLength() public view returns (uint256) {
    return conditionsIds.length;
  }

  /*******************************************************
   *                Condition Validation Logic
   *******************************************************/
  /**
   * @notice Validate the integrity of a condition
   * @dev For example: are the arguments of the condition valid, and do they point to a valid implementation?
   * @param condition The condition to validate
   */
  function validateCondition(Condition memory condition) public view {
    string[][] memory requirements = condition.requirements;

    for (
      uint256 requirementIdx;
      requirementIdx < requirements.length;
      requirementIdx++
    ) {
      string[] memory requirement = requirements[requirementIdx];
      string memory requirementType = requirement[0];
      string memory requirementValidationMethod = requirement[1];
      string memory methodSignature;
      string memory paramType;
      bool requirementTypeIsTarget = Strings.stringsEqual(
        requirementType,
        "target"
      );
      bool requirementTypeIsParam = Strings.stringsEqual(
        requirementType,
        "param"
      );
      if (requirementTypeIsTarget) {
        require(
          requirement.length == 2,
          "Requirement length must be equal to 2"
        );
        methodSignature = string(
          abi.encodePacked(requirementValidationMethod, "(address)")
        );
      } else if (requirementTypeIsParam) {
        require(
          requirement.length == 3,
          "Requirement length must be equal to 3"
        );
        uint256 paramIdx = Strings.atoi(requirement[2], 10);
        require(
          paramIdx <= condition.paramTypes.length - 1,
          "Requirement parameter index is out of range"
        );
        paramType = condition.paramTypes[paramIdx];
        methodSignature = string(
          abi.encodePacked(requirementValidationMethod, "(", paramType, ")")
        );
      } else {
        revert("Unsupported requirement type");
      }

      address implementationAddress = condition.implementationAddress;
      require(
        implementationAddress != address(0),
        "Implementation address is not set"
      );

      bool implementsInterface = Introspection.implementsMethodSignature(
        implementationAddress,
        methodSignature
      );
      require(
        implementsInterface == true,
        "Implementation does not implement method selector"
      );
    }
  }

  /**
   * @notice Validate all conditions
   * @dev Reverts if some conditions are invalid
   */
  function validateConditions() public view {
    for (
      uint256 conditionIdx;
      conditionIdx < conditionsIds.length;
      conditionIdx++
    ) {
      string memory conditionId = conditionsIds[conditionIdx];
      Condition memory condition = conditionById[conditionId];
      validateCondition(condition);
    }
  }

  /**
   * @notice Determine whether or not all conditions are valid
   * @return Return true if all conditions are valid, false if not
   */
  function conditionsValid() public view returns (bool) {
    (bool success, ) = address(this).staticcall(
      abi.encodeWithSignature("validateConditions()")
    );
    return success;
  }
}