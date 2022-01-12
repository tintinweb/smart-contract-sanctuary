/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// File: https://github.com/OtterClam/otter-contracts/blob/main/contracts/interfaces/IOtterStaking.sol

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

interface IOtterStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

// File: https://github.com/OtterClam/otter-contracts/blob/main/contracts/interfaces/IERC20.sol


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

// File: contracts/StakingHelper.sol


pragma solidity 0.7.5;



contract OtterStakingHelper {
    address public immutable staking;
    address public immutable CLAM;

    constructor(address _staking, address _CLAM) {
        require(_staking != address(0));
        staking = _staking;
        require(_CLAM != address(0));
        CLAM = _CLAM;
    }

    function stake(uint256 _amount, address _recipient) external {
        IERC20(CLAM).transferFrom(msg.sender, address(this), _amount);
        IERC20(CLAM).approve(staking, _amount);
        IOtterStaking(staking).stake(_amount, _recipient);
        IOtterStaking(staking).claim(_recipient);
    }
}