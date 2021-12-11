/*
ERC20StakingModuleInfo

https://github.com/CFT-io/core

SPDX-License-Identifier: MIT
*/

// pragma solidity 0.8.4;
pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Metadata.sol";

import "./IStakingModule.sol";
import "./ERC20StakingModule.sol";

/**
 * @title ERC20 staking module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC20StakingModule contract.
 */
library ERC20StakingModuleInfo {
    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of staking module
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
        IStakingModule m = IStakingModule(module);
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (address(tkn), tkn.name(), tkn.symbol(), tkn.decimals());
    }

    /**
     * @notice quote the share value for an amount of tokens
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens. if zero, return entire share balance
     * @return number of shares
     */
    function shares(
        address module,
        address addr,
        uint256 amount
    ) public view returns (uint256) {
        ERC20StakingModule m = ERC20StakingModule(module);

        // return all user shares
        if (amount == 0) {
            return m.shares(addr);
        }

        uint256 totalShares = m.totalShares();
        require(totalShares > 0, "smi1");

        // convert token amount to shares
        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        uint256 s = (totalShares * amount) / tkn.balanceOf(module);

        require(s > 0, "smi2");
        require(m.shares(addr) >= s, "smi3");

        return s;
    }

    /**
     * @notice get shares per token
     * @param module address of staking module
     * @return current shares per token
     */
    function sharesPerToken(address module) public view returns (uint256) {
        ERC20StakingModule m = ERC20StakingModule(module);

        uint256 totalShares = m.totalShares();
        if (totalShares == 0) {
            return 1e24;
        }

        IERC20Metadata tkn = IERC20Metadata(m.tokens()[0]);
        return (totalShares * 1e18) / tkn.balanceOf(module);
    }
}