//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPetGotchi {
  function lastExecuted() external view returns (uint256);

  function pet() external;
}

contract PetResolver {
  address public immutable pet;

  constructor(address _pet) {
    pet = _pet;
  }

  function checker()
    external
    view
    returns (bool canExec, bytes memory execPayload)
  {
    uint256 lastExecuted = IPetGotchi(pet).lastExecuted();

    canExec = (block.timestamp - lastExecuted) > 43260;

    execPayload = abi.encodeWithSelector(IPetGotchi.pet.selector);
  }
}