// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IOracle {

    function ETHPriceOfERC20(address erc20Address) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IOracle } from "./../interfaces/IOracle.sol";

contract MockOracle is IOracle {

    function ETHPriceOfERC20(address erc20Address) public view override returns(uint256) {
        return 1;
    }

}