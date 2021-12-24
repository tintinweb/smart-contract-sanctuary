// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

import "./interfaces/IERC20.sol";

contract TulipStakingWarmup {
    address public immutable staking;
    IERC20 public immutable sTulip;

    constructor(address _staking, address _sTulip) {
        require(_staking != address(0));
        staking = _staking;
        require(_sTulip != address(0));
        sTulip = IERC20(_sTulip);
    }

    function retrieve(address _staker, uint256 _amount) external {
        require(msg.sender == staking, "NA");
        sTulip.transfer(_staker, _amount);
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