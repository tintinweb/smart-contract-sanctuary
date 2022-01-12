/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// File: https://github.com/OtterClam/otter-contracts/blob/main/contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

// File: contracts/stakingWarmup.sol


pragma solidity 0.7.5;


contract WorldTreasuryStakingWarmup {
    address public immutable staking;
    address public immutable sCLAM;

    constructor(address _staking, address _sCLAM) {
        require(_staking != address(0));
        staking = _staking;
        require(_sCLAM != address(0));
        sCLAM = _sCLAM;
    }

    function retrieve(address _staker, uint256 _amount) external {
        require(msg.sender == staking);
        IERC20(sCLAM).transfer(_staker, _amount);
    }
}