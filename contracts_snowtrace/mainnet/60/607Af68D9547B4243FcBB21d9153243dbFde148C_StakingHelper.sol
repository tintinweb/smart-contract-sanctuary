// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
import "./ERC20.sol";

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

contract StakingHelper {
    address public immutable staking;
    address public immutable Mag;

    constructor(address _staking, address _Mag) {
        require(_staking != address(0));
        staking = _staking;
        require(_Mag != address(0));
        Mag = _Mag;
    }

    function stake(uint256 _amount, address recipient) external {
        IERC20(Mag).transferFrom(msg.sender, address(this), _amount);
        IERC20(Mag).approve(staking, _amount);
        IStaking(staking).stake(_amount, recipient);
        IStaking(staking).claim(recipient);
    }
}