/**
 *Submitted for verification at polygonscan.com on 2021-08-12
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
        uint256 balancePower = trumpChick.balanceOf(account);

        (uint trumpMiningBalance,,) =  chickMining.getUserInfo(5, account);

        power = balancePower + trumpMiningBalance;
    }

    /// @notice Returns total power supply.
    function totalSupply() external view returns (uint256 total) {
        return trumpChick.totalSupply();
    }
}