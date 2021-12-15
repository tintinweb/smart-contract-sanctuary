/*
ERC20GreenhouseRewardModuleInfo

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./IERC20Metadata.sol";

import "./IRewardModule.sol";
import "./ERC20GreenhouseRewardModule.sol";
import "./CrcUtils.sol";

/**
 * @title ERC20 Greenhouse reward module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20GreenhouseRewardModule contract.
 */
library ERC20GreenhouseRewardModuleInfo {
    using CrcUtils for uint256;

    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of reward module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(address module)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint8
        )
    {
        IRewardModule m = IRewardModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (address(tkn), tkn.name(), tkn.symbol(), tkn.decimals());
    }

    /**
     * @notice preview estimated rewards
     * @param module address of reward module
     * @param addr account address of interest for preview
     * @param shares number of shares that would be unstaked
     * @return estimated reward
     * @return estimated time multiplier weighted by rewards
     * @return estimated crc multiplier weighted by rewards
     */
    function rewards(
        address module,
        address addr,
        uint256 shares
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(shares > 0, "frmi1");
        ERC20GreenhouseRewardModule m = ERC20GreenhouseRewardModule(module);

        uint256 reward;
        uint256 rawSum;
        uint256 bonusSum;

        uint256 i = m.stakeCount(addr);

        // redeem first-in-last-out
        while (shares > 0) {
            require(i > 0, "frmi2");
            i -= 1;

            (uint256 s, , , , ) = m.stakes(addr, i);

            // only redeem partial stake if more shares left than needed to burn
            s = s <= shares ? s : shares;

            uint256 r;
            {
                r = rewardsPerStakedShare(module);
            }

            {
                (, , , uint256 tally, ) = m.stakes(addr, i);
                r = ((r - tally) * s) / 1e18;
                rawSum += r;
            }

            {
                (, , uint256 bonus, , ) = m.stakes(addr, i);
                r = (r * bonus) / 1e18;
                bonusSum += r;
            }

            {
                (, , , , uint256 time) = m.stakes(addr, i);
                r = (r * m.timeVestingCoefficient(time)) / 1e18;
            }
            reward += r;
            shares -= s;
        }

        return (
            reward / 1e6,
            reward > 0 ? (reward * 1e18) / bonusSum : 0,
            reward > 0 ? (bonusSum * 1e18) / rawSum : 0
        );
    }

    /**
     * @notice compute reward shares to be unlocked on the next update
     * @param module address of reward module
     * @return estimated unlockable rewards
     */
    function unlockable(address module) public view returns (uint256) {
        ERC20GreenhouseRewardModule m = ERC20GreenhouseRewardModule(module);
        address tkn = m.tokens()[0];
        if (m.lockedShares(tkn) == 0) {
            return 0;
        }
        uint256 sharesToUnlock = 0;
        for (uint256 i = 0; i < m.fundingCount(tkn); i++) {
            sharesToUnlock = sharesToUnlock + m.unlockable(tkn, i);
        }
        return sharesToUnlock;
    }

    /**
     * @notice compute effective unlocked rewards
     * @param module address of reward module
     * @return estimated current unlocked rewards
     */
    function unlocked(address module) public view returns (uint256) {
        ERC20GreenhouseRewardModule m = ERC20GreenhouseRewardModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        uint256 totalShares = m.totalShares(address(tkn));
        if (totalShares == 0) {
            return 0;
        }
        uint256 shares = unlockable(module);
        uint256 tokens = (shares * tkn.balanceOf(module)) / totalShares;
        return m.totalUnlocked() + tokens;
    }

    /**
     * @notice compute effective rewards per staked share
     * @param module module contract address
     * @return estimated rewards per staked share
     */
    function rewardsPerStakedShare(address module)
        public
        view
        returns (uint256)
    {
        ERC20GreenhouseRewardModule m = ERC20GreenhouseRewardModule(module);
        if (m.totalStakingShares() == 0) {
            return 0;
        }
        uint256 rewardsToUnlock = unlockable(module) + m.rewardDust();
        return
            m.rewardsPerStakedShare() +
            (rewardsToUnlock * 1e18) /
            m.totalStakingShares();
    }

    /**
     * @notice compute estimated CRC bonus for stake
     * @param module module contract address
     * @param shares number of shares that would be staked
     * @param crc number of CRC tokens that would be applied to stake
     * @return estimated CRC multiplier
     */
    function crcBonus(
        address module,
        uint256 shares,
        uint256 crc
    ) public view returns (uint256) {
        ERC20GreenhouseRewardModule m = ERC20GreenhouseRewardModule(module);
        return
            crc.crcBonus(
                shares,
                m.totalRawStakingShares() + shares,
                m.usage()
            );
    }
}