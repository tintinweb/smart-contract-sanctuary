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

/*******************************************************
 *                      Core Logic
 *******************************************************/
contract Allowlist {
  /**
   * methodName: Name of the method to validate (ie. "approve")
   * paramTypes: Param types of the method to validate (ie. ["address", "uint256"])
   * requirements: Array of requirements, where a requirement is as follows:
   *    Element 0: Requirement type (ie. "target" or "param")
   *    Element 1: Method name of validation method (ie. "isVaultToken")
   *    Element 2: Index of param to test as a string. Only applicable where requirement type is "param" (ie. "0")
   */
  struct Condition {
    string methodName;
    string[] paramTypes;
    string[][] requirements;
    address implementationAddress;
  }

  Condition[] public conditions; // Array of conditions per protocol (managed by protocol owner)
  string public protocolOriginName; // Domain name of protocol (ie. "yearn.finance")
  address public rootAllowlistAddress; // Address of root allowlist (parent/factory)

  /**
   * Initialize the contract (this will only be called by proxy)
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

  function ownerAddress() public view returns (address protcolOwnerAddress) {
    protcolOwnerAddress = IAllowlistFactory(rootAllowlistAddress)
      .protocolOwnerAddressByOriginName(protocolOriginName);
  }

  /*******************************************************
   *                   Condition CRUD Logic
   *******************************************************/
  function addCondition(Condition memory condition) public onlyOwner {
    validateCondition(condition);
    conditions.push(condition);
  }

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

  function addConditionWithoutValidation(Condition memory condition)
    public
    onlyOwner
  {
    conditions.push(condition);
  }

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
      addCondition(condition);
    }
  }

  function deleteCondition(uint256 conditionIdx) public onlyOwner {
    Condition memory lastCondition = conditions[conditions.length - 1];
    conditions[conditionIdx] = lastCondition;
    conditions.pop();
  }

  function deleteAllConditions() public onlyOwner {
    for (
      uint256 conditionIdx;
      conditionIdx < conditions.length;
      conditionIdx++
    ) {
      conditions.pop();
    }
  }

  function updateCondition(uint256 conditionIdx, Condition memory condition)
    public
    onlyOwner
  {
    deleteCondition(conditionIdx);
    addCondition(condition);
  }

  function conditionsList() public view returns (Condition[] memory test) {
    Condition[] memory _conditions = new Condition[](conditions.length);
    for (
      uint256 conditionIdx;
      conditionIdx < conditions.length;
      conditionIdx++
    ) {
      _conditions[conditionIdx] = conditions[conditionIdx];
    }
    return _conditions;
  }

  function conditionsLength() public view returns (uint256) {
    return conditions.length;
  }

  /*******************************************************
   *                Condition Validation Logic
   *******************************************************/
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

  function validateConditions() public view {
    for (
      uint256 conditionIdx;
      conditionIdx < conditions.length;
      conditionIdx++
    ) {
      Condition memory condition = conditions[conditionIdx];
      validateCondition(condition);
    }
  }

  function implementationValid() public view returns (bool) {
    (bool success, ) = address(this).staticcall(
      abi.encodeWithSignature("validateConditions()")
    );
    return success;
  }
}