// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/IHauntedHouse.sol";

contract HauntedHouseHarvestHelper {
    IHauntedHouse public constant hauntedHouse = IHauntedHouse(0xB178bD23876Dd9f8aA60E7FdB0A2209Fe2D7a9AB);
    struct Reward {
        address tokenAddress;
        uint256 pendingZBOOFI;
    }

    function batchPendingZBOOFI(address userAddress, address[] memory tokenAddresses) external view returns(Reward[] memory) {
        Reward[] memory rewards = new Reward[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            Reward memory reward;
            reward.tokenAddress = tokenAddresses[i];
            reward.pendingZBOOFI = hauntedHouse.pendingZBOOFI(tokenAddresses[i], userAddress);
            rewards[i] = reward;
        }
        return rewards;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IHauntedHouse {
    struct TokenInfo {
        address rewarder; // Address of rewarder for token
        address strategy; // Address of strategy for token
        uint256 lastRewardTime; // Last time that BOOFI distribution occurred for this token
        uint256 lastCumulativeReward; // Value of cumulativeAvgZboofiPerWeightedDollar at last update
        uint256 storedPrice; // Latest value of token
        uint256 accZBOOFIPerShare; // Accumulated BOOFI per share, times ACC_BOOFI_PRECISION.
        uint256 totalShares; //total number of shares for the token
        uint256 totalTokens; //total number of tokens deposited
        uint128 multiplier; // multiplier for this token
        uint16 withdrawFeeBP; // Withdrawal fee in basis points
    }
    function BOOFI() external view returns (address);
    function strategyPool() external view returns (address);
    function performanceFeeAddress() external view returns (address);
    function updatePrice(address token, uint256 newPrice) external;
    function updatePrices(address[] calldata tokens, uint256[] calldata newPrices) external;
    function tokenList() external view returns (address[] memory);
    function tokenParameters(address tokenAddress) external view returns (TokenInfo memory);
    function deposit(address token, uint256 amount, address to) external;
    function harvest(address token, address to) external;
    function withdraw(address token, uint256 amountShares, address to) external;
    function pendingZBOOFI(address token, address userAddress) external view returns (uint256);
}