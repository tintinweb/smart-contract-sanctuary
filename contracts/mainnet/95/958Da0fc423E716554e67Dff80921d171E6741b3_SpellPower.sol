/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 remainingIceTokenReward;  // ICE Tokens that weren't distributed for user per pool.
}
interface ISorbettiere {
    function userInfo(uint256 pid, address account) external view returns (UserInfo memory user);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IBentoBoxV1BalanceAmount {
    function balanceOf(IERC20, address) external view returns (uint256);
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256 amount);
}

interface ICauldron {
    function userCollateralShare(address user) external view returns(uint256);
}

contract SpellPower {
    ISorbettiere public constant sorbettiere = ISorbettiere(0xF43480afE9863da4AcBD4419A47D9Cc7d25A647F);
    IERC20 public constant pair = IERC20(0xb5De0C3753b6E1B4dBA616Db82767F17513E6d4E);
    IERC20 public constant spell = IERC20(0x090185f2135308BaD17527004364eBcC2D37e5F6);
    IERC20 public constant sspell = IERC20(0x26FA3fFFB6EfE8c1E69103aCb4044C26B9A106a9);
    ICauldron public constant sspellCauldron = ICauldron(0xC319EEa1e792577C319723b5e60a15dA3857E7da);
    ICauldron public constant sspellCauldron2 = ICauldron(0x3410297D89dCDAf4072B805EFc1ef701Bb3dd9BF);
    IBentoBoxV1BalanceAmount public constant bento = IBentoBoxV1BalanceAmount(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    function name() external pure returns (string memory) { return "SPELLPOWER"; }
    function symbol() external pure returns (string memory) { return "SPELLPOWER"; }
    function decimals() external pure returns (uint8) { return 18; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns SUSHI voting 'powah' for `account`.
    function balanceOf(address account) external view returns (uint256 powah) {
        uint256 bento_balance = bento.toAmount(sspell, (bento.balanceOf(sspell, account) + sspellCauldron2.userCollateralShare(account) + sspellCauldron.userCollateralShare(account)), false); // get BENTO sSpell balance 'amount' (not shares)
        uint256 collective_sSpell_balance = bento_balance +  sspell.balanceOf(account); // get collective sSpell staking balances
        uint256 sSpell_powah = collective_sSpell_balance * spell.balanceOf(address(sspell)) / sspell.totalSupply(); // calculate sSpell weight
        uint256 lp_stakedBalance = sorbettiere.userInfo(0, account).amount; // get LP balance staked in Sorbettiere
        uint256 lp_balance = lp_stakedBalance + pair.balanceOf(account); // add staked LP balance & those held by `account`
        uint256 lp_powah = lp_balance * spell.balanceOf(address(pair)) / pair.totalSupply() * 2; // calculate adjusted LP weight
        powah = sSpell_powah + lp_powah; // add sSpell & LP weights for 'powah'
    }

    /// @notice Returns total 'powah' supply.
    function totalSupply() external view returns (uint256 total) {
        total = spell.balanceOf(address(sspell)) + spell.balanceOf(address(pair)) * 2;
    }
}