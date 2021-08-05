/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.6.6;

contract ApiShow {
    // MoboxFarm
    function getRewardFor(uint256[] memory pIndexArray_, address[] memory users_) external {}
    function getDevReward() external {}
    function setMineToken() external {}
    function setDevTeam(address dev_) external {}
    function setRewardHelper(address addr_) external {}
    function addMysteryBox(address to_, uint256 amount_) external {}

    // MomoBidder
    function bid(uint256 amount, uint256 tokenId) external {}
    function withdraw721() external {}
    function auctionEnd() external {}
    function startNextRound(uint256 startTime, uint256 endTime, uint256 tokenId) external {}
    function updateRoundInfo(uint256 startTime, uint256 endTime, uint256 tokenId) external {}

    // GemMinter
    function hApplyForGem(uint256 applyNum_) external {}
    function nApplyForGem(uint256 applyNum_) external {}
    function claimfrozenMbox() external {}
    function claimfrozenGem() external  {}

    // MoMoInlay
    function takeOn(uint256 momoId_, uint256 gemId_, uint256 pos_) external {}
    function takeOff(uint256 momoId_, uint256 pos_) external {}
    function levelUp(uint256 gemId_, uint256 amount_) external {}
    function inlayQuickLvUp(uint256 momoId_, uint256 pos_) external {}

    // MoMoRenter
    function createRent(uint256 tokenId_, uint256 curRentDays_, uint256 curRentRound_, uint256 curRentPrice_ ) external {}
    function addRentRenewal(uint256 tokenId_, uint256 orderId_,  uint256 nextRentDays_, uint256 nextRentRound_, uint256 nextRentPrice_) external {}
    function cancelRent(uint256 tokenId_, uint256 orderId_) external {}
    function rent(uint256 tokenId_, uint256 orderId_, uint256 gameId_, uint256 price_) external {}
    function renewRent(uint256 tokenId_, uint256 orderId_, uint256 price_) external {}

    // MoMoStaker
    function getReward() external {}
    function bid(
        address[] memory auctors_, 
        uint256[] memory indexs_,
        uint256[] memory startTimes_,
        uint256[] memory prices_,
        bool ignoreSold
    ) external  {}

    // Mystery
    function hApplyForBox(uint256 applyNum_) external {}
    function nApplyForBox(uint256 applyNum_) external {}
    function claimfrozenBox() external {}
}