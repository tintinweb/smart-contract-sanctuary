//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../bridgeworld/external/IAtlasMine.sol";

contract MockAtlasMine is IAtlasMine {

    uint256 public utilizationAmount = 1 * 10**18;

    function utilization() external view returns(uint256) {
        return utilizationAmount;
    }

    function setUtilizationAmount(uint256 _utilizationAmount) external {
        utilizationAmount = _utilizationAmount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAtlasMine {

    // Returns the percentage of magic staked. 100% = 1 * 10**18
    function utilization() external view returns(uint256);
}