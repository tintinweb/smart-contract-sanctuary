pragma solidity ^0.4.24;

// File: contracts/marketer/MarketerInterface.sol

contract MarketerInterface {
    function getMarketerKey() public returns(bytes32);
    function getMarketerAddress(bytes32 _key) public view returns(address);
}

// File: contracts/utils/ValidValue.sol

contract ValidValue {
  modifier validRange(uint256 _value) {
      require(_value > 0);
      _;
  }

  modifier validAddress(address _account) {
      require(_account != address(0));
      require(_account != address(this));
      _;
  }

  modifier validString(string _str) {
      require(bytes(_str).length > 0);
      _;
  }
}

// File: contracts/marketer/Marketer.sol

/**
 * @title Marketer contract
 *
 * @author Junghoon Seo - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="6e0406401d0b012e0c0f1a1a020b0b001a400d0103">[email&#160;protected]</a>>
 */
contract Marketer is MarketerInterface, ValidValue {
  mapping (bytes32 => address) marketerInfo;

  function getMarketerKey() public returns(bytes32) {
      bytes32 key = bytes32(keccak256(abi.encodePacked(msg.sender)));
      marketerInfo[key] = msg.sender;

      return key;
  }

  function getMarketerAddress(bytes32 _key) public view returns(address) {
      return marketerInfo[_key];
  }
}