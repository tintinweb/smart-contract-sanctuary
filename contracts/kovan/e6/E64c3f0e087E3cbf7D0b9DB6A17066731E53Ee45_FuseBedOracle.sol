/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/FuseBedOracle.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6 <0.9.0;

////// src/interfaces/IBedOracle.sol
/* pragma solidity ^0.8.6; */

interface IBedOracle {
    function getPrice() external view returns (uint256);
}

////// src/interfaces/IFToken.sol
/* pragma solidity ^0.8.6; */

interface IFToken {
    function underlying() external view returns (address);
}

////// src/FuseBedOracle.sol
/* pragma solidity ^0.8.6; */

/* import { IBedOracle } from "./interfaces/IBedOracle.sol"; */
/* import { IFToken } from "./interfaces/IFToken.sol"; */


contract FuseBedOracle {
    
    IBedOracle public bedOracle;
    address public bed;

    constructor(IBedOracle _bedOracle, address _bed) {
        bedOracle = _bedOracle;
        bed = _bed;
    }

    function price(address _underlying) external view returns (uint256) {
        require(_underlying == bed, "oracle not found");
        return bedOracle.getPrice();
    }

    function getUnderlyingPrice(IFToken _fToken) external view returns (uint256) {
        require(_fToken.underlying() == bed, "oracle not found");
        return bedOracle.getPrice();
    }
}