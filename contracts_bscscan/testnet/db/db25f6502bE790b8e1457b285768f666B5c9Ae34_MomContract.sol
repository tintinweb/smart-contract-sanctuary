//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./DaughterContract.sol";
import "../interfaces/IDaughterContract.sol";

contract MomContract {
  event NewChildBorn(address house, string name, uint256 year);

  address[] public children;

  constructor() {}

  function getChildrenCount() public view returns (uint256) {
    return children.length;
  }

  function born(string memory name, uint256 year) external returns (address child, uint256 childId) {
    require(year > 2000, "Invalid year");

    bytes memory bytecode = type(DaughterContract).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(name, year));

    assembly {
      child := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    IDaughterContract(child).initialize(name, year);

    childId = children.length;
    children.push(child);

    emit NewChildBorn(child, name, year);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DaughterContract {
  string public name;
  uint256 public birthYear;

  address public mom;

  constructor() {
    mom = msg.sender;
  }

  modifier onlyMom() {
    require(msg.sender == mom, "Limited by Mom");
    _;
  }

  function initialize(string memory _name, uint256 _birthYear) external onlyMom {
    name = _name;
    birthYear = _birthYear;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDaughterContract {
  function name() external view returns (string memory);
  function birthYear() external view returns (uint256);

  function initialize(string memory name, uint256 year) external;
}