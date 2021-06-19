/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IMasterChefUserInfo {
    function userInfo(uint256 pid, address account) external view returns (uint256, uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IBentoBoxV1BalanceAmount {
    function balanceOf(IERC20, address) external view returns (uint256);
    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}

interface ICreamRate {
    function exchangeRateStored() external view returns (uint256);
}

contract SUSHIPOWAH {
    IMasterChefUserInfo chef = IMasterChefUserInfo(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    IERC20 pair = IERC20(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    IERC20 bar = IERC20(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IERC20 sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IERC20 axSushi = IERC20(0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a);
    IBentoBoxV1BalanceAmount bento = IBentoBoxV1BalanceAmount(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);
    address crxSushi = 0x228619CCa194Fbe3Ebeb2f835eC1eA5080DaFbb2; 

    function name() external pure returns (string memory) { return "SUSHIPOWAH"; }
    function symbol() external pure returns (string memory) { return "SUSHIPOWAH"; }
    function decimals() external pure returns (uint8) { return 18; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns SUSHI voting 'powah' for `account`.
    function balanceOf(address account) external view returns (uint256 powah) {
        uint256 axsushi_balance = bar.balanceOf(address(axSushi)) * axSushi.balanceOf(account) / axSushi.totalSupply(); // get adjusted tally for aToken
        uint256 bento_balance = bento.toAmount(bar, bento.balanceOf(bar, account), false); // get BENTO xSushi balance 'amount' (not shares)
        uint256 crxsushi_balance = bar.balanceOf(address(crxSushi)) * IERC20(crxSushi).balanceOf(account) / IERC20(crxSushi).totalSupply(); // get adjusted tally for cToken
        uint256 collective_xsushi_balance = bar.balanceOf(account) + axsushi_balance + bento_balance + crxsushi_balance; // get collective xSushi staking balances
        uint256 xsushi_powah = sushi.balanceOf(address(bar)) * collective_xsushi_balance / bar.totalSupply(); // calculate xSushi weight
        (uint256 lp_stakedBalance, ) = chef.userInfo(12, account); // get LP balance staked in MasterChef
        uint256 lp_balance = lp_stakedBalance + pair.balanceOf(account); // add staked LP balance & those held by `account`
        uint256 lp_powah = sushi.balanceOf(address(pair)) * lp_balance / pair.totalSupply() * 2; // calculate adjusted LP weight
        powah = xsushi_powah + lp_powah; // add xSushi & LP weights for 'powah'
    }

    /// @notice Returns total 'powah' supply.
    function totalSupply() external view returns (uint256 total) {
        total = sushi.balanceOf(address(bar)) + sushi.balanceOf(address(pair)) * 2;
    }
}