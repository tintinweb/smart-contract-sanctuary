// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./BaseGovernanceModule.sol";
import "./UniERC20.sol";
import "./BaseRewards.sol";


contract GovernanceRewards is BaseGovernanceModule, BaseRewards {
    using SafeMath for uint256;
    using UniERC20 for IERC20;

    // solhint-disable-next-line no-empty-blocks
    constructor(IERC20 _gift, address _mothership) BaseGovernanceModule(_mothership) BaseRewards(_gift) {}

    function _notifyStakeChanged(address account, uint256 newBalance) internal override updateReward(account) {
        _set(account, newBalance);
    }

    function rescueFunds(IERC20 token, uint256 amount) external onlyOwner {
        require(token != gift, "Can't rescue gift");

        token.uniTransfer(msg.sender, amount);
    }
}