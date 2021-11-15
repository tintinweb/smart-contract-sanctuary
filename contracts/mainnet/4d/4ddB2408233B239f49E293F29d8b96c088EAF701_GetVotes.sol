//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function totalSupply() external view returns (uint256);
}

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    function userInfo(uint256 _poolId, address _user)
        external
        view
        returns (IMasterChef.UserInfo memory);
}

interface IMuseStaker {
    function userInfo(address _user)
        external
        view
        returns (
            uint256 bal,
            uint256 claimable,
            uint256 deposited,
            uint256 timelock,
            bool isClaimable,
            uint256 globalShares,
            uint256 globalBalance
        );
}

/*
    This governance voting strategy enables to check the sum of Muse tokens an address has in LP providing and wallet
*/
contract GetVotes {
    IERC20 public muse = IERC20(0xB6Ca7399B4F9CA56FC27cBfF44F4d2e4Eef1fc81);
    IERC20 public uniLp = IERC20(0x20d2C17d1928EF4290BF17F922a10eAa2770BF43);
    IMasterChef public masterChef =
        IMasterChef(0x193b775aF4BF9E11656cA48724A710359446BF52);
    IMuseStaker public museStaker =
        IMuseStaker(0x4ffDE8e98227c17A64A9df30DfB1d3049457c5Db);

    function getVotes(address _user) public view returns (uint256) {
        uint256 userMuseBalance = muse.balanceOf(_user);
        // lp tokens from user on masterchef
        uint256 userLpTokens = masterChef.userInfo(0, _user).amount;
        //total supply of of muse in lp
        uint256 museInLpPool = muse.balanceOf(address(uniLp));
        //total supply of lp tokens
        uint256 lpTokensTotalSupply = uniLp.totalSupply();
        // do calc for uniswap
        uint256 museFromStake =
            (museInLpPool / lpTokensTotalSupply) * userLpTokens;

        //calc muse from single stake
        uint256 claimable;
        uint256 deposited;

        (, claimable, deposited, , , , ) = museStaker.userInfo(_user);

        uint256 museFromSingleStake = claimable + deposited;

        return
            (userMuseBalance + museFromStake + museFromSingleStake) / 1 ether;
    }
}

