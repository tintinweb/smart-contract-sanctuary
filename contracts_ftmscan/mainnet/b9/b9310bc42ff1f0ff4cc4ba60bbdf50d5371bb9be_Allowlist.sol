// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./Ownable.sol";
import "./Strings.sol";
import "./Introspection.sol";
import "./JsonWriter.sol";
import "./CalldataValidation.sol";

/*******************************************************
 *                   Main Contract Logic
 *******************************************************/
contract Allowlist is IAllowlist, Ownable {
  using JsonWriter for JsonWriter.Json; // Initialize JSON writer
  string[] public conditionsIds; // Array of condition IDs
  mapping(string => Condition) public conditionById; // Condition ID to condition mapping
  string public name; // Domain name of protocol (ie. "yearn.finance")
  address public allowlistFactoryAddress; // Address of root allowlist (parent/factory)
  mapping(string => address) public implementationById; // Implementation ID to implementation address mapping
  string[] public implementationsIds; // Array of implementation IDs

  /**
   * @notice Initialize the contract (this will only be called by proxy)
   * @param _name The allowlist name (for the protocols this is domain name: ie. "yearn.finance")
   */
  function initialize(string memory _name, address _ownerAddress) public {
    require(
      allowlistFactoryAddress == address(0),
      "Contract is already initialized"
    );
    allowlistFactoryAddress = msg.sender;
    name = _name;
    ownerAddress = _ownerAddress;
  }

  /*******************************************************
   *                   Implementation Logic
   *******************************************************/

  struct Implementation {
    string id;
    address addr;
  }

  /**
   * @notice Set implementation address for an ID (ie. "VAULT_VALIDATIONS" => 0x...)
   * @param implementationId The unique of the implementation
   * @param implementationAddress The address of the new implementation
   */
  function setImplementation(
    string memory implementationId,
    address implementationAddress
  ) public onlyOwner {
    // Add implementation ID to the implementationsIds list if it doesn't exist
    bool implementationExists = implementationById[implementationId] !=
      address(0);
    if (!implementationExists) {
      implementationsIds.push(implementationId);
    }

    // Set implementation
    implementationById[implementationId] = implementationAddress;

    // Validate implementation against existing conditions
    validateConditions();
  }

  /**
   * @notice Set multiple implementations
   * @param implementations An array of implementation tuples
   */
  function setImplementations(Implementation[] memory implementations)
    public
    onlyOwner
  {
    for (
      uint256 implementationIdx;
      implementationIdx < implementations.length;
      implementationIdx++
    ) {
      Implementation memory implementation = implementations[implementationIdx];
      setImplementation(implementation.id, implementation.addr);
    }
  }

  function implementationsIdsList() public view returns (string[] memory) {
    return implementationsIds;
  }

  function implementationsList() public view returns (Implementation[] memory) {
    string[] memory _implementationsIdsList = implementationsIdsList();
    Implementation[] memory implementations = new Implementation[](
      _implementationsIdsList.length
    );
    for (
      uint256 implementationIdx;
      implementationIdx < _implementationsIdsList.length;
      implementationIdx++
    ) {
      string memory implementationId = _implementationsIdsList[
        implementationIdx
      ];
      address implementationAddress = implementationById[implementationId];
      implementations[implementationIdx] = Implementation({
        id: implementationId,
        addr: implementationAddress
      });
    }
    return implementations;
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
      string memory conditionId = conditionsIds[0];
      deleteCondition(conditionId);
    }
  }

  /**
   * @notice Update an existing condition
   * @dev Reads condition.id to determine which condition to update
   * @param condition The new condition
   */
  function updateCondition(Condition memory condition) public onlyOwner {
    bool conditionExists = !Strings.stringsEqual(
      conditionById[condition.id].id,
      ""
    );
    require(conditionExists, "Condition with this ID does not exist");
    deleteCondition(condition.id);
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
   * @notice Fetch current conditions list as JSON
   * @return Returns JSON representation of conditions list
   */
  function conditionsJson() public view returns (string memory) {
    Condition[] memory conditions = conditionsList();

    // Start array
    JsonWriter.Json memory writer;
    writer = writer.writeStartArray();
    for (
      uint256 conditionIdx;
      conditionIdx < conditions.length;
      conditionIdx++
    ) {
      // Load condition
      Condition memory condition = conditions[conditionIdx];

      // Start object
      writer = writer.writeStartObject();

      // ID
      writer = writer.writeStringProperty("id", condition.id);

      // Implementation ID
      writer = writer.writeStringProperty(
        "implementationId",
        condition.implementationId
      );

      // Method name
      writer = writer.writeStringProperty("methodName", condition.methodName);

      // Param types
      writer = writer.writeStartArray("paramTypes");
      for (
        uint256 paramTypeIdx;
        paramTypeIdx < condition.paramTypes.length;
        paramTypeIdx++
      ) {
        writer = writer.writeStringValue(condition.paramTypes[paramTypeIdx]);
      }
      writer = writer.writeEndArray();

      // Requirements
      writer = writer.writeStartArray("requirements");
      for (
        uint256 requirementIdx;
        requirementIdx < condition.requirements.length;
        requirementIdx++
      ) {
        string[] memory requirement = condition.requirements[requirementIdx];
        writer = writer.writeStartArray();
        for (
          uint256 requirementItemIdx;
          requirementItemIdx < requirement.length;
          requirementItemIdx++
        ) {
          writer = writer.writeStringValue(requirement[requirementItemIdx]);
        }
        writer = writer.writeEndArray();
      }
      writer = writer.writeEndArray();

      // End object
      writer = writer.writeEndObject();
    }
    // End array
    writer = writer.writeEndArray();
    return writer.value;
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

      address implementationAddress = implementationById[
        condition.implementationId
      ];
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

  /**
   * @notice Determine whether or not a given target and calldata is valid
   * @dev In order to be valid, target and calldata must pass the allowlist conditions tests
   * @param targetAddress The target address of the method call
   * @param data The raw calldata of the call
   * @return isValid True if valid, false if not
   */
  function validateCalldata(address targetAddress, bytes calldata data)
    public
    view
    returns (bool isValid)
  {
    isValid = CalldataValidation.validateCalldataByAllowlist(
      address(this),
      targetAddress,
      data
    );
  }
}