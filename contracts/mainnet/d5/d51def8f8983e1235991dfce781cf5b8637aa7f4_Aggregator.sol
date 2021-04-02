// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.5.17;

import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Owned.sol";
import "./Context.sol";


contract IRewardPool {
    function notifyRewards(uint reward) external;
}

contract Aggregator is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /// Protocol developers rewards
    uint public constant FEE_FACTOR = 3;

    // Beneficial address
    address public beneficial;

    /// Reward token
    IERC20 public rewardToken;

    // Reward pool address
    address public rewardPool;

    constructor(address _token1, address _rewardPool) public {
        beneficial = msg.sender;
        
        rewardToken = IERC20(_token1);
        rewardPool = _rewardPool;
    }

    /// Capture tokens or any other tokens
    function capture(address _token) onlyOwner external {
        require(_token != address(rewardToken), "capture: can not capture reward tokens");

        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(beneficial, balance);
    }  

    function notifyRewards() onlyOwner nonReentrant external {
        uint reward = rewardToken.balanceOf(address(this));

        /// Split the governance and protocol developers rewards
        uint _developerRewards = reward.div(FEE_FACTOR);
        uint _governanceRewards = reward.sub(_developerRewards);

        rewardToken.safeTransfer(beneficial, _developerRewards);
        rewardToken.safeTransfer(rewardPool, _governanceRewards);

        IRewardPool(rewardPool).notifyRewards(_governanceRewards);
    }
}