// SPDX-License-Identifier: MIT
pragma solidity >=0.5.10 <0.9.0;

import "./StakeBase.sol";

contract VanKushRewardsToken is StakeBase {

    constructor () public  {
        _mint(msg.sender, 1000000000 * 10**18);
    }

    function name() external pure returns (string memory) {
        return "Van Kush Rewards Token";
    }

    function symbol() external pure returns (string memory) {
        return "VKRW";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function mint(address to, uint256 value) external onlyOwner returns (bool) {
        _mint2(to, value);
        return true;
    }

    function burn(uint256 value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function burnFrom(address from, uint256 value) external returns (bool) {
        _burnFrom(from, value);
        return true;
    }

    function info() external view 
    returns (address, uint256, uint256, uint256, uint256) {
        return accountInfo(msg.sender);
    }

    function stakeInfo(uint8 idx) external view 
    returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return accountStakeInfo(msg.sender, idx);
    }

    function stakeCount() external view returns (uint256) {
        return accountStakeCount(msg.sender);
    }

    function stake(uint256 amount, address referrer) external returns (bool) {
        return stakeAccount(msg.sender, amount, referrer);
    }

    function unstake(uint8 idx) external returns (bool) {
        _unstake(msg.sender, idx);

        return true;
    }
    
    function withdrawCommissions() external returns (uint256) {
        return withdrawAccountCommissions(msg.sender);
    }

    function withdrawStakeProfit(uint8 idx) external returns (uint256) {
        return withdrawAccountStakeProfit(msg.sender, idx);
    }

    function withdrawStakeCapital(uint8 idx) external returns (uint256) {
        return withdrawAccountStakeCapital(msg.sender, idx);
    }

}