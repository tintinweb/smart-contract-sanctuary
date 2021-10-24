// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "../interfaces/IRedOracle.sol";

/**
 * @title RedStone
 * @author Pods Finance
 * @notice Storage of prices feeds by asset
 */
contract RedStoneOracle {
    uint8 public _decimals = 8;

    function setDecimals(uint8 decimals) external {
        _decimals = decimals;
    }

    function getLatestPrice() external view returns (int256, uint256) {
        IRedOracle redStone = IRedOracle(0x48b1151947532ba913bfdEc0E822fEbd14483e7E);
        int256 currentPrice = int256(redStone.getPrice("CL=F"));
        return (currentPrice, block.timestamp);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        IRedOracle redStone = IRedOracle(0x48b1151947532ba913bfdEc0E822fEbd14483e7E);
        answer = int256(redStone.getPrice("CL=F"));
        return (1, answer, 1, block.timestamp, uint80(answer));
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

interface IRedOracle {
    function getPrice(string memory ticker) external view returns (uint256 price);
}