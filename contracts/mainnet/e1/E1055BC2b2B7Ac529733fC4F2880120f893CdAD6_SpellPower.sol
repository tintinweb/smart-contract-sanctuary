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

contract SpellPower {
    ISorbettiere sorbettiere = ISorbettiere(0xF43480afE9863da4AcBD4419A47D9Cc7d25A647F);
    IERC20 pair = IERC20(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    IERC20 spell = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    IERC20 sspell = IERC20(0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a);
    IBentoBoxV1BalanceAmount bento = IBentoBoxV1BalanceAmount(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);

    function name() external pure returns (string memory) { return "SPELLPOWER"; }
    function symbol() external pure returns (string memory) { return "SPELLPOWER"; }
    function decimals() external pure returns (uint8) { return 18; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns SUSHI voting 'powah' for `account`.
    function balanceOf(address account) external view returns (uint256 powah) {
        uint256 bento_balance = bento.toAmount(sspell, bento.balanceOf(sspell, account), false); // get BENTO sSpell balance 'amount' (not shares)
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}