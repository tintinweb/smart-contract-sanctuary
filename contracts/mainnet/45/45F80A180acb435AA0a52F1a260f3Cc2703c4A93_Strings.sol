// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./libraries/Strings.sol";
import "./libraries/Introspection.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Introspection {
  // function implementsMethodNameAndParamTypes(string memory methodName, string[])
  function implementsMethodSignature(address _address, string memory _signature)
    public
    view
    returns (bool)
  {
    bytes4 _selector = bytes4(keccak256(bytes(_signature)));
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_address)
    }
    bytes memory code = new bytes(contractSize);
    assembly {
      extcodecopy(_address, add(code, 0x20), 0, contractSize)
    }
    uint256 ptr = 0;
    while (ptr < contractSize) {
      // PUSH4 0x000000 (selector)
      if (code[ptr] == 0x63) {
        bytes memory selectorBytes = new bytes(64);
        selectorBytes[0] = code[ptr + 1];
        selectorBytes[1] = code[ptr + 2];
        selectorBytes[2] = code[ptr + 3];
        selectorBytes[3] = code[ptr + 4];
        bytes4 selector = abi.decode(selectorBytes, (bytes4));
        if (selector == _selector) {
          return true;
        }
      }
      ptr++;
    }
    return false;
  }

  function implementsInterface(address _address, string[] memory _interface)
    public
    view
    returns (bool)
  {
    for (uint256 methodIdx = 0; methodIdx < _interface.length; methodIdx++) {
      string memory method = _interface[methodIdx];
      bool methodIsImplemented = implementsMethodSignature(_address, method);
      if (!methodIsImplemented) {
        return false;
      }
    }
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Strings {
  /**
   * @notice Search for a needle in a haystack
   * @param haystack The string to search
   * @param needle The string to search for
   */
  function stringStartsWith(string memory haystack, string memory needle)
    public
    pure
    returns (bool)
  {
    return indexOfStringInString(needle, haystack) == 0;
  }

  /**
   * @notice Case insensitive string search
   * @param needle The string to search for
   * @param haystack The string to search
   * @return Returns -1 if no match is found, otherwise returns the index of the match
   */
  function indexOfStringInString(string memory needle, string memory haystack)
    public
    pure
    returns (int256)
  {
    bytes memory _needle = bytes(needle);
    bytes memory _haystack = bytes(haystack);
    if (_haystack.length < _needle.length) {
      return -1;
    }
    bool _match;
    for (uint256 haystackIdx; haystackIdx < _haystack.length; haystackIdx++) {
      for (uint256 needleIdx; needleIdx < _needle.length; needleIdx++) {
        uint8 needleChar = uint8(_needle[needleIdx]);
        if (haystackIdx + needleIdx >= _haystack.length) {
          return -1;
        }
        uint8 haystackChar = uint8(_haystack[haystackIdx + needleIdx]);
        if (needleChar == haystackChar) {
          _match = true;
          if (needleIdx == _needle.length - 1) {
            return int256(haystackIdx);
          }
        } else {
          _match = false;
          break;
        }
      }
    }
    return -1;
  }

  /**
   * @notice Check to see if two strings are exactly equal
   */
  function stringsEqual(string memory input1, string memory input2)
    public
    pure
    returns (bool)
  {
    uint256 input1Length = bytes(input1).length;
    uint256 input2Length = bytes(input2).length;
    uint256 maxLength;
    if (input1Length > input2Length) {
      maxLength = input1Length;
    } else {
      maxLength = input2Length;
    }
    uint256 numberOfRowsToCompare = (maxLength / 32) + 1;
    bytes32 input1Bytes32;
    bytes32 input2Bytes32;
    for (uint256 rowIdx; rowIdx < numberOfRowsToCompare; rowIdx++) {
      uint256 offset = 0x20 * (rowIdx + 1);
      assembly {
        input1Bytes32 := mload(add(input1, offset))
        input2Bytes32 := mload(add(input2, offset))
      }
      if (input1Bytes32 != input2Bytes32) {
        return false;
      }
    }
    return true;
  }

  function atoi(string memory a, uint8 base) public pure returns (uint256 i) {
    require(base == 2 || base == 8 || base == 10 || base == 16);
    bytes memory buf = bytes(a);
    for (uint256 p = 0; p < buf.length; p++) {
      uint8 digit = uint8(buf[p]) - 0x30;
      if (digit > 10) {
        digit -= 7;
      }
      require(digit < base);
      i *= base;
      i += digit;
    }
    return i;
  }

  function itoa(uint256 i, uint8 base) public pure returns (string memory a) {
    require(base == 2 || base == 8 || base == 10 || base == 16);
    if (i == 0) {
      return "0";
    }
    bytes memory buf = new bytes(256);
    uint256 p = 0;
    while (i > 0) {
      uint8 digit = uint8(i % base);
      uint8 ascii = digit + 0x30;
      if (digit > 9) {
        ascii += 7;
      }
      buf[p++] = bytes1(ascii);
      i /= base;
    }
    uint256 length = p;
    for (p = 0; p < length / 2; p++) {
      buf[p] ^= buf[length - 1 - p];
      buf[length - 1 - p] ^= buf[p];
      buf[p] ^= buf[length - 1 - p];
    }
    return string(buf);
  }
}