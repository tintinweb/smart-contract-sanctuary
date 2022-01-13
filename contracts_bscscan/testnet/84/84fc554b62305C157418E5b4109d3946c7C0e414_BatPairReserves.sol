//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

import "./IPancakeFactory.sol";
import "./IPancakePair.sol";

contract BatPairReserves {
    IPancakeFactory public factory;

    constructor(IPancakeFactory _factory) {
        factory = _factory;
    }

    function getBatPairReserves(address[] calldata tokens) public view returns(uint256[] memory) {
        require(tokens.length%2 == 0, "tokens length must be even number");
        uint256[] memory ret = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length/2; i++) {
            address pairAddr = factory.getPair(tokens[i*2], tokens[i*2+1]);
            if (pairAddr == address(0)) {
                ret[i*2] = 0;
                ret[i*2+1] = 0;
                continue;
            }

            IPancakePair pair = IPancakePair(pairAddr);
            address token0 = pair.token0();
            (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
            if (token0 == tokens[i+2+1]) {
                (reserve0, reserve1) = (reserve1, reserve0);
            }

            ret[i*2] = uint256(reserve0);
            ret[i*2+1] = uint256(reserve1);
        }

        return ret;
    }

}