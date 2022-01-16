// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AdminModule {

    function newMarket(address token_, string memory name_, string memory symbol_) external {}

    function enableMarket(address token_) external {}

    function disableMarket(address token_) external {}

    function setupRewards(address token_, address rewardtoken_, uint rewardPerSec_) external {}

}

contract UserModule {

    function updateRewards(address token_) public returns (uint[] memory newRewardPrices_) {}

    function updateUserReward(address user_, address token_) public returns (uint[] memory updatedRewards_) {}

    function supply(address token_, uint amount_) external returns (uint itokenAmount_) {}

    function withdraw(address token_, uint amount_) external returns (uint itokenAmount_) {}

    function withdrawItoken(address token_, uint itokenAmount_) external returns (uint amount_) {}

    function claim(address user_, address token_) external returns (uint[] memory updatedRewards_) {}

    function updateRewardsOnTransfer(address from_, address to_) external {}

}

contract ReadModule {

    function tokenEnabled(address token_) external view returns (bool) {}

    function markets() external view returns (address[] memory) {}

    function marketsLength() external view returns (uint length_) {}

    function tokenToItoken(address token_) external view returns (address) {}

    function itokenToToken(address itoken_) external view returns (address) {}

    function rewardTokens(address token_) external view returns (address[] memory) {}

    function rewardRate(address token_, address rewardToken_) external view returns (uint) {}

    function rewardPrice(address token_, address rewardToken_) external view returns (uint rewardPrice_, uint lastUpdateTime_) {}

    function userRewards(address user_, address token_, address rewardToken_) external view returns (uint lastRewardPrice_, uint reward_) {}

}

contract Protocol1DummyImplementation is AdminModule, UserModule, ReadModule {

    receive() external payable {}
    
}