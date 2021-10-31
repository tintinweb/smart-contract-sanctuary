//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ChildDeployer.sol";
import "./DaughterContract.sol";
import "../interfaces/IDaughterContract.sol";

contract MomContract is ChildDeployer {
  event NewChildBorn(address house, string name, uint256 year);

  enum SEX {
    BOY,
    GIRL
  }

  address[] public children;

  constructor() {}

  function getChildrenCount() public view returns (uint256) {
    return children.length;
  }

  function bornDaughter(string memory name, uint256 year) private returns (address child) {
    bytes memory bytecode = type(DaughterContract).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(name, year));

    assembly {
      child := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    IDaughterContract(child).initialize(name, year);
  }

  function bornSon(string memory name, uint256 year) private returns (address child) {
    child = deploy(msg.sender, name, year);
  }

  function born(string memory name, uint256 year, SEX sex) external returns (address child, uint256 childId) {
    require(year > 2000, "Invalid year");

    if (sex == SEX.GIRL) {
      child = bornDaughter(name, year);
    } else {
      child = bornSon(name, year);
    }

    childId = children.length;
    children.push(child);

    emit NewChildBorn(child, name, year);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SonContract.sol";
import "../interfaces/IChildDeployer.sol";

contract ChildDeployer is IChildDeployer {
  struct Parameters {
    address mom;
    string name;
    uint256 birthYear;
  }

  Parameters public override parameters;

  function deploy(address mom, string memory name, uint256 birthYear) internal returns (address house) {
    parameters = Parameters({ mom: mom, name: name, birthYear: birthYear });
    house = address(new SonContract{salt: keccak256(abi.encode(mom, name, birthYear))}());
    delete parameters;
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

  function initialize(string memory, uint256) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IChildDeployer.sol";

contract SonContract {
  string public name;
  uint256 public birthYear;

  address public mom;

  constructor() {
    (address _mom, string memory _name, uint256 _birthYear) = IChildDeployer(msg.sender).parameters();

    mom = _mom;
    name = _name;
    birthYear = _birthYear;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IChildDeployer {
  function parameters() external view returns (
    address mom,
    string memory name,
    uint256 birthYear
  );
}