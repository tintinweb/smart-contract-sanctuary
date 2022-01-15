// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./Strings.sol";
import "./AbiDecoder.sol";
import { IAllowlist } from "./Allowlist.sol";

/**
 * @title Validate raw calldata against an allowlist
 * @author yearn.finance
 */

/*******************************************************
 *                   Main Contract Logic
 *******************************************************/
library CalldataValidation {
  /**
   * @notice Calculate a method signature given a condition
   * @param condition The condition from which to generate the signature
   * @return signature The method signature in string format (ie. "approve(address,uint256)")
   */
  function methodSignatureByCondition(IAllowlist.Condition memory condition)
    public
    pure
    returns (string memory signature)
  {
    bytes memory signatureBytes = abi.encodePacked(condition.methodName, "(");
    for (uint256 paramIdx; paramIdx < condition.paramTypes.length; paramIdx++) {
      signatureBytes = abi.encodePacked(
        signatureBytes,
        condition.paramTypes[paramIdx]
      );
      if (paramIdx + 1 < condition.paramTypes.length) {
        signatureBytes = abi.encodePacked(signatureBytes, ",");
      }
    }
    signatureBytes = abi.encodePacked(signatureBytes, ")");
    signature = string(signatureBytes);
  }

  /**
   * @notice Check target validity
   * @param implementationAddress The address the validation method will be executed against
   * @param targetAddress The target address to validate
   * @param requirementValidationMethod The method to execute
   * @return targetValid Returns true if the target is valid and false otherwise
   * @dev If "requirementValidationMethod" is "isValidVaultToken" and target address is usdc
   *      the validation check will look like this: usdc.isValidVaultToken(targetAddress),
   *      where the result of the validation method is expected to return a bool
   */
  function checkTarget(
    address implementationAddress,
    address targetAddress,
    string memory requirementValidationMethod
  ) public view returns (bool targetValid) {
    string memory methodSignature = string(
      abi.encodePacked(requirementValidationMethod, "(address)")
    );
    (, bytes memory data) = address(implementationAddress).staticcall(
      abi.encodeWithSignature(methodSignature, targetAddress)
    );
    targetValid = abi.decode(data, (bool));
  }

  /**
   * @notice Check method selector validity
   * @param data Raw input calldata (we will extract the 4-byte selector
   *             from the beginning of the calldata)
   * @param condition The condition struct to check (we generate the complete
   *        method selector using condition.methodName and condition.paramTypes)
   * @return methodSelectorValid Returns true if the method selector is valid and false otherwise
   */
  function checkMethodSelector(
    bytes calldata data,
    IAllowlist.Condition memory condition
  ) public pure returns (bool methodSelectorValid) {
    string memory methodSignature = methodSignatureByCondition(condition);
    bytes4 methodSelectorBySignature = bytes4(
      keccak256(bytes(methodSignature))
    );
    bytes4 methodSelectorByCalldata = bytes4(data[0:4]);
    methodSelectorValid = methodSelectorBySignature == methodSelectorByCalldata;
  }

  /**
   * @notice Check an individual method param's validity
   * @param implementationAddress The address the validation method will be executed against
   * @param requirement The specific requirement (of type "param") to check (ie. ["param", "isVault", "0"])
   * @dev A condition may have multiple requirements, all of which must be true
   * @dev The middle element of a requirement is the requirement validation method
   * @dev The last element of a requirement is the parameter index to validate against
   * @param condition The entire condition struct to check the param against
   * @param data Raw input calldata for the original method call
   * @return Returns true if the param is valid, false if not
   */
  function checkParam(
    address implementationAddress,
    string[] memory requirement,
    IAllowlist.Condition memory condition,
    bytes calldata data
  ) public view returns (bool) {
    uint256 paramIdx = Strings.atoi(requirement[2], 10);
    string memory paramType = condition.paramTypes[paramIdx];
    bytes memory paramCalldata = AbiDecoder.getParamFromCalldata(
      data,
      paramType,
      paramIdx
    );
    string memory methodSignature = string(
      abi.encodePacked(requirement[1], "(", paramType, ")")
    );
    bytes memory encodedCalldata = abi.encodePacked(
      bytes4(keccak256(bytes(methodSignature))),
      paramCalldata
    );
    bool success;
    bytes memory resultData;
    (success, resultData) = address(implementationAddress).staticcall(
      encodedCalldata
    );
    if (success) {
      return abi.decode(resultData, (bool));
    }
    return false;
  }

  /**
   * @notice Test a target address and calldata against a specific condition and implementation
   * @param condition The condition to test
   * @param targetAddress Target address of the original method call
   * @param data Calldata of the original methodcall
   * @return Returns true if the condition passes and false if not
   * @dev The condition check is comprised of 3 parts:
          - Method selector check (to make sure the calldata method selector matches the condition method selector)
          - Target check (to make sure the target is valid)
          - Param check (to make sure the specified param is valid)
   */
  function testCondition(
    IAllowlist.Condition memory condition,
    address targetAddress,
    bytes calldata data
  ) public view returns (bool) {
    string[][] memory requirements = condition.requirements;
    address implementationAddress = condition.implementationAddress;
    for (
      uint256 requirementIdx;
      requirementIdx < requirements.length;
      requirementIdx++
    ) {
      string[] memory requirement = requirements[requirementIdx];
      string memory requirementType = requirement[0];
      string memory requirementValidationMethod = requirement[1];
      if (!checkMethodSelector(data, condition)) {
        return false;
      }
      if (Strings.stringsEqual(requirementType, "target")) {
        bool targetValid = checkTarget(
          implementationAddress,
          targetAddress,
          requirementValidationMethod
        );
        if (!targetValid) {
          return false;
        }
      } else if (Strings.stringsEqual(requirementType, "param")) {
        bool paramValid = checkParam(
          implementationAddress,
          requirement,
          condition,
          data
        );
        if (!paramValid) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * @notice Test target address and calldata against all stored protocol conditions
   * @dev This is done to determine whether or not the target address and calldata are valid and whitelisted
   * @dev This is the primary method that should be called by integrators
   * @param allowlistAddress The address of the allowlist to check calldata against
   * @param targetAddress The target address of the call
   * @param data The raw calldata to test
   * @return Returns true if the calldata/target test is successful and false if not
   */
  function validateCalldataByAllowlist(
    address allowlistAddress,
    address targetAddress,
    bytes calldata data
  ) public view returns (bool) {
    IAllowlist.Condition[] memory _conditions = IAllowlist(allowlistAddress)
      .conditionsList();
    for (
      uint256 conditionIdx;
      conditionIdx < _conditions.length;
      conditionIdx++
    ) {
      IAllowlist.Condition memory condition = _conditions[conditionIdx];
      bool conditionPassed = testCondition(condition, targetAddress, data);
      if (conditionPassed) {
        return true;
      }
    }
    return false;
  }
}