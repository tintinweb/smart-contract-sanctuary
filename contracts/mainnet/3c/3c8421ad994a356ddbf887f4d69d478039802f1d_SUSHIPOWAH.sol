/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// a library for performing overflow-safe math, updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "SafeMath: Mul Overflow");}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IMasterChef {
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }
    
    function userInfo(uint256 pid, address account) external view returns (uint256, uint256);
    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);
    function totalAllocPoint() external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
}

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function registerProtocol() external;
}

interface ICreamRate {
    function exchangeRateStored() external view returns (uint256);
}

contract SUSHIPOWAH {
    using SafeMath for uint256;

    IMasterChef chef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    IERC20 pair = IERC20(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    IERC20 bar = IERC20(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IERC20 axSushi = IERC20(0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a);
    IBentoBoxV1 bento = IBentoBoxV1(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);
    address crxSushi = 0x228619CCa194Fbe3Ebeb2f835eC1eA5080DaFbb2; 

    function name() external pure returns(string memory) { return "SUSHIPOWAH"; }
    function symbol() external pure returns(string memory) { return "SUSHIPOWAH"; }
    function decimals() external pure returns(uint8) { return 18; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns the collective SUSHI balance for a given `account` staked among protocols with adjustments for boosts.
    function balanceOf(address account) external view returns (uint256) {
        uint256 lp_totalSushi = sushi.balanceOf(address(pair));
        uint256 lp_total = pair.totalSupply();
        (uint256 lp_stakedBalance, ) = chef.userInfo(12, account);
        uint256 lp_balance = pair.balanceOf(account).add(lp_stakedBalance);
        uint256 lp_powah = lp_totalSushi.mul(lp_balance) / lp_total.mul(2); // calculate voting weight adjusted for LP staking
        uint256 collective_xsushi_balance = collectBalances(account); // calculate xSushi staking balances
        uint256 xsushi_powah = sushi.balanceOf(address(bar)).mul(collective_xsushi_balance) / bar.totalSupply(); // calculate xSushi voting weight
        return lp_powah.add(xsushi_powah); // combine xSushi weight with adjusted LP voting weight for 'powah'
    }

    /// @dev Internal function to avoid stack 'too deep' errors on calculating {balanceOf}.
    function collectBalances(address account) private view returns (uint256 collective_xsushi_balance) {
        uint256 xsushi_balance = bar.balanceOf(account);
        uint256 axsushi_balance = axSushi.balanceOf(account);
        uint256 bento_balance = bento.toAmount(bar, bento.balanceOf(bar, account), false);
        uint256 crxsushi_balance = IERC20(crxSushi).balanceOf(account).mul(ICreamRate(crxSushi).exchangeRateStored()) / 10**18; // calculate underlying xSushi claim
        collective_xsushi_balance = xsushi_balance.add(axsushi_balance).add(bento_balance).add(crxsushi_balance);
    }

    /// @notice Returns the adjusted total 'powah' supply for LP & xSushi staking.
    function totalSupply() external view returns (uint256) {
        uint256 lp_totalSushi = sushi.balanceOf(address(pair));
        uint256 xsushi_totalSushi = sushi.balanceOf(address(bar));
        return lp_totalSushi.mul(2).add(xsushi_totalSushi);
    }
}