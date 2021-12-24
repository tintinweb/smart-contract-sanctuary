// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";

contract TulipStakingHelper {
    event LogStake(address indexed recipient, uint256 amount);

    IStaking public immutable staking;
    IERC20 public immutable Tulip;

    constructor(address _staking, address _Tulip) {
        require(_staking != address(0));
        staking = IStaking(_staking);
        require(_Tulip != address(0));
        Tulip = IERC20(_Tulip);
    }

    function stake(uint256 _amount, address recipient) external {
        Tulip.transferFrom(msg.sender, address(this), _amount);
        Tulip.approve(address(staking), _amount);
        staking.stake(_amount, recipient);
        staking.claim(recipient);
        emit LogStake(recipient, _amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}