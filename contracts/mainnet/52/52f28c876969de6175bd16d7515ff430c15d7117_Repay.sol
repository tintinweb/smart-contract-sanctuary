/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Controller {
    function vaults(address) external view returns (address);
    function strategies(address) external view returns (address);
}

interface Strategy {
    function forceRebalance(uint256) external;
    function harvest() external;
    function setKeeper(address) external;
}

interface Vault {
    function deposit(uint256) external;
}

contract Repay {
    address public ctrl = address(0x9E65Ad11b299CA0Abefc2799dDB6314Ef2d91080);
    address public weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address public governance;
    address public yvdai;
    address public strategy;
    
    constructor() public {
        governance = msg.sender;
        yvdai = Controller(ctrl).vaults(dai);
        strategy = Controller(ctrl).strategies(weth);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    function repay(uint _amount, uint _repay) external {
        if (_amount > 0) {
            IERC20(dai).transferFrom(msg.sender, address(this), _amount);
            IERC20(dai).approve(yvdai, _amount);
            Vault(yvdai).deposit(_amount);
            uint shares = IERC20(yvdai).balanceOf(address(this));
            IERC20(yvdai).transfer(strategy, shares);
        }
        Strategy(strategy).forceRebalance(_repay);
    }

    function harvest(uint _amount) external {
        require(msg.sender == governance, "!governance");
        if (_amount > 0) {
            IERC20(dai).transferFrom(msg.sender, address(this), _amount);
            IERC20(dai).approve(yvdai, _amount);
            Vault(yvdai).deposit(_amount);
            uint shares = IERC20(yvdai).balanceOf(address(this));
            IERC20(yvdai).transfer(strategy, shares);
        }
        Strategy(strategy).harvest();
    }

    function setKeeper(address _keeper) external {
        require(msg.sender == governance, "!governance");
        Strategy(strategy).setKeeper(_keeper);
    }
}