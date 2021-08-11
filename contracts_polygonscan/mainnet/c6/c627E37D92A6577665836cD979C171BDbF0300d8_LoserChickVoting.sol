/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

interface IChickMining {    
    function getUserInfo(uint256 _pid, address _user) external view returns (uint256 _amount, uint256 _rewardDebt, uint256 _rewardToClaim);
}

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract LoserChickVoting {
    IChickMining chickMining = IChickMining(0x0A058646784E2cF89B24BFE12C9C2f2920342fA7);
    IERC721 shriekingChick = IERC721(0xE50B1F6E58A0A77B0a41aedc085190808D25D706);
    IERC721 luckyChick = IERC721(0x8580a90f6E378dB283ddb8af06356a962551e89A);
    IERC721 laborChick = IERC721(0x388EB34b54fE92e944b81A23f8e60146cA838180);
    IERC721 bossChick = IERC721(0x4F1e6318aCc9Ee33c88f0E3E3578D5aD62E19285);
    IERC721 trumpChick = IERC721(0x4f17c6514B9Ca3aBccfDefd12DF2dfA195A76dC4);
   
   
    function name() external pure returns (string memory) { return "LoserChickVoting"; }
    function symbol() external pure returns (string memory) { return "vCHICKNFT"; }
    function decimals() external pure returns (uint8) { return 0; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns Chick voting power for `account`.
    function balanceOf(address account) external view returns (uint256 power) {
        uint256 balancePower = shriekingChick.balanceOf(account) * 10000 
         + luckyChick.balanceOf(account) * 2500 
         + laborChick.balanceOf(account) * 250 
         + bossChick.balanceOf(account) * 50 
         + trumpChick.balanceOf(account);

        (uint shriekingMiningBalance,,) =  chickMining.getUserInfo(1, account);
        (uint luckyMiningBalance,,) =  chickMining.getUserInfo(2, account);
        (uint laborMiningBalance,,) =  chickMining.getUserInfo(3, account);
        (uint bossMiningBalance,,) =  chickMining.getUserInfo(4, account);
        (uint trumpMiningBalance,,) =  chickMining.getUserInfo(5, account);

        uint256 miningPower = shriekingMiningBalance * 10000 + luckyMiningBalance * 2500 + laborMiningBalance * 250 + bossMiningBalance * 50 + trumpMiningBalance;
       
        power = balancePower + miningPower;
    }

    /// @notice Returns total power supply.
    function totalSupply() external view returns (uint256 total) {
        return shriekingChick.totalSupply() * 10000 
        + luckyChick.totalSupply() * 2500 
        + laborChick.totalSupply() * 250 
        + bossChick.totalSupply() * 50 
        + trumpChick.totalSupply();
    }
}