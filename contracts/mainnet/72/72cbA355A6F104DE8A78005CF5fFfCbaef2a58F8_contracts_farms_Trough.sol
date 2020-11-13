pragma solidity ^0.5.17;

import "./Farm.sol";

contract Trough is Farm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private rewardMultiplier;
    uint256 private rewardDivisor;

    event Fed(address indexed user, uint256 amount);

    constructor(
        IERC20 _ham,
        IERC20 _wrappedToken,
        uint256 _rewardMultiplier,
        uint256 _rewardDivisor
    ) Farm(_ham, _wrappedToken) public {
        rewardMultiplier = _rewardMultiplier;
        rewardDivisor = _rewardDivisor;
    }

    function stake(uint256 amount) checkStart public {
        wrappedToken.safeTransferFrom(msg.sender, address(this), amount);
        rewards[msg.sender] = rewards[msg.sender].add(amount.mul(rewardMultiplier).div(rewardDivisor));
        emit Fed(msg.sender, amount);
    }
}
