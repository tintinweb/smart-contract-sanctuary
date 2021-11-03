// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IQuantumArtSeeder.sol";

contract BogusSeeder is IQuantumArtSeeder{

    function dropIdToSeed(uint256 dropId) public view override returns (uint256) {
        return 0;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuantumArtSeeder {
    function dropIdToSeed(uint256 dropId) view external returns (uint256);
}