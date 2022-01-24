// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IPetGotchi {
  function lastExecuted() external view returns (uint256);
  function petGotchis() external;
}

contract LazyPetterResolver {
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

        canExec = (block.timestamp - lastExecuted) > 43200;

        execPayload = abi.encodeWithSelector(
            IPetGotchi.petGotchis.selector
        );
    }
}