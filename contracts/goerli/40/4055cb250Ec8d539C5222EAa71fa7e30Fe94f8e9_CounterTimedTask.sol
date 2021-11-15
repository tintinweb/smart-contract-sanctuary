// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import {PokeMeReady} from "./PokeMeReady.sol";

contract CounterTimedTask is PokeMeReady {
    uint256 public count;

    // solhint-disable-next-line no-empty-blocks
    constructor(address payable _pokeMe) PokeMeReady(_pokeMe) {}

    // solhint-disable not-rely-on-time
    function increaseCount(uint256 amount) external onlyPokeMe {
        count += amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

abstract contract PokeMeReady {
    address payable public immutable pokeMe;

    constructor(address payable _pokeMe) {
        pokeMe = _pokeMe;
    }

    modifier onlyPokeMe() {
        require(msg.sender == pokeMe, "PokeMeReady: onlyPokeMe");
        _;
    }
}

