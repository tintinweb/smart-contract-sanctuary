// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.7;

struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
}
interface IJoeStaking {
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

interface IwMEMO is IERC20 {
    function wMEMOToMEMO(uint256 amount) external view returns(uint256);
}

contract TimePower {
    IJoeStaking public constant joeStaking = IJoeStaking(0xd6a4F121CA35509aF06A0Be99093d08462f53052);
    IERC20 public constant AvaxTime = IERC20(0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917);
    IERC20 public constant MimTime = IERC20(0x113f413371fC4CC4C9d6416cf1DE9dFd7BF747Df);
    IERC20 public constant TIME = IERC20(0xb54f16fB19478766A268F172C9480f8da1a7c9C3);
    IERC20 public constant MEMO = IERC20(0x136Acd46C134E8269052c62A67042D6bDeDde3C9);
    IwMEMO public constant wMEMO = IwMEMO(0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b);
    ICauldron public constant wMEMOCauldron1 = ICauldron(0x56984F04d2d04B2F63403f0EbeDD3487716bA49d);
    ICauldron public constant wMEMOCauldron2 = ICauldron(0x35fA7A723B3B39f15623Ff1Eb26D8701E7D6bB21);
    IBentoBoxV1BalanceAmount public constant bento = IBentoBoxV1BalanceAmount(0xf4F46382C2bE1603Dc817551Ff9A7b333Ed1D18f);

    function name() external pure returns (string memory) { return "SPELLPOWER"; }
    function symbol() external pure returns (string memory) { return "SPELLPOWER"; }
    function decimals() external pure returns (uint8) { return 9; }
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transfer(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }

    /// @notice Returns SUSHI voting 'powah' for `account`.
    function balanceOf(address account) external view returns (uint256 powah) {
        uint256 bento_balance = bento.toAmount(wMEMO, (bento.balanceOf(wMEMO, account) + wMEMOCauldron1.userCollateralShare(account) + wMEMOCauldron2.userCollateralShare(account)), false); // get BENTO wMEMO balance 'amount' (not shares)
        uint256 collective_wMEMO_balance = bento_balance +  wMEMO.balanceOf(account); // get collective wMEMO staking balances
        uint256 time_powah =  wMEMO.wMEMOToMEMO(collective_wMEMO_balance) + MEMO.balanceOf(account) + TIME.balanceOf(account); // calculate TIME weight
        uint256 avax_time_balance = joeStaking.userInfo(45, account).amount + AvaxTime.balanceOf(account); // add staked LP balance & those held by `account`
        uint256 avax_time_powah = avax_time_balance * TIME.balanceOf(address(AvaxTime)) / AvaxTime.totalSupply() * 2; // calculate adjusted LP weight
        uint256 mim_time_powah = MimTime.balanceOf(account) * TIME.balanceOf(address(MimTime)) / MimTime.totalSupply() * 2; // calculate adjusted LP weight
        powah = time_powah + avax_time_powah + mim_time_powah; // add wMEMO & LP weights for 'powah'
    }

    /// @notice Returns total 'powah' supply.
    function totalSupply() external view returns (uint256 total) {
        total = TIME.balanceOf(address(AvaxTime)) * 2+ TIME.balanceOf(address(MimTime)) * 2 + TIME.balanceOf(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    }
}