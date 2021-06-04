// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import "./BoringERC20.sol";
import "./BoringMath.sol";


contract MC2Rewarder {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    address public owner;
    uint256 public rewardMultiplier;
    IERC20 public rewardToken;

    uint256 private constant REWARD_TOKEN_DIVISOR = 1e18;
    address private MASTERCHEF_V2;

    constructor (address _owner, uint256 _rewardMultiplier, IERC20 _rewardToken, address _MASTERCHEF_V2) public {
        owner = _owner;
        rewardMultiplier = _rewardMultiplier;
        rewardToken = _rewardToken;
        MASTERCHEF_V2 = _MASTERCHEF_V2;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setRewardMultiplier(uint256 _multiplier) public onlyOwner {
        rewardMultiplier = _multiplier;
    }

    function onSushiReward (uint256, address, address to, uint256 sushiAmount, uint256) onlyMCV2 external {
        uint256 pendingReward = sushiAmount.mul(rewardMultiplier) / REWARD_TOKEN_DIVISOR;
        uint256 rewardBal = rewardToken.balanceOf(address(this));
        if (pendingReward > rewardBal) {
            rewardToken.safeTransfer(to, rewardBal);
        } else {
            rewardToken.safeTransfer(to, pendingReward);
        }
    }
    
    function pendingTokens(uint256, address, uint256 sushiAmount) external view returns (IERC20[] memory rewardTokens, uint256[] memory rewardAmounts) {
        IERC20[] memory _rewardTokens = new IERC20[](1);
        _rewardTokens[0] = (rewardToken);
        uint256[] memory _rewardAmounts = new uint256[](1);
        _rewardAmounts[0] = sushiAmount.mul(rewardMultiplier) / REWARD_TOKEN_DIVISOR;
        return (_rewardTokens, _rewardAmounts);
    }

    modifier onlyMCV2 {
        require(
            msg.sender == MASTERCHEF_V2,
            "Only MCV2 can call this function."
        );
        _;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
  
}