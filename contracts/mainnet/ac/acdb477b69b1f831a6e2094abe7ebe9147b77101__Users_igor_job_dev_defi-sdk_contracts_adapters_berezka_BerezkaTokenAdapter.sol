// Copyright (C) 2020 Easy Chain. <https://easychain.tech>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import { ERC20 } from "../../ERC20.sol";
import { TokenMetadata, Component } from "../../Structs.sol";
import { TokenAdapter } from "../TokenAdapter.sol";
import { ProtocolAdapter } from "../ProtocolAdapter.sol";


interface IBerezkaTokenAdapterGovernance {
    function listTokens() external view returns (address[] memory);
    function listProtocols() external view returns (address[] memory);
    function listEthProtocols() external view returns (address[] memory);
    function listProducts() external view returns (address[] memory);
    function getVaults(address _token) external view returns (address[] memory);
}


/**
 * @title Token adapter for Berezka DAO.
 * @dev Implementation of TokenAdapter interface.
 * @author Vasin Denis <denis.vasin@easychain.tech>
 */
contract BerezkaTokenAdapter is TokenAdapter {

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    string internal constant ERC20_TOKEN = "ERC20";

    IBerezkaTokenAdapterGovernance immutable private governance;

    constructor(address _governance) public {
        governance = IBerezkaTokenAdapterGovernance(_governance);
    }

    /**
     * @return TokenMetadata struct with ERC20-style token info.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getMetadata(address token) 
        external 
        view 
        override 
        returns (TokenMetadata memory) 
    {
        return TokenMetadata({
            token: token,
            name: ERC20(token).name(),
            symbol: ERC20(token).symbol(),
            decimals: ERC20(token).decimals()
        });
    }

    /**
     * @return Array of Component structs with underlying tokens rates for the given token.
     * @dev Implementation of TokenAdapter interface function.
     */
    function getComponents(address token)
        external
        view
        override
        returns (Component[] memory)
    {
        address[] memory vaults = governance.getVaults(token);
        address[] memory assets = governance.listTokens();
        address[] memory debtAdapters = governance.listProtocols();
        uint256 length = assets.length;
        uint256 totalSupply = ERC20(token).totalSupply();

        Component[] memory underlyingTokens = new Component[](1 + length);

        // Handle ERC20 assets + debt
        for (uint256 i = 0; i < length; i++) {
            underlyingTokens[i] = _getTokenComponents(assets[i], vaults, debtAdapters, totalSupply);
        }

        // Handle ETH
        underlyingTokens[length] = _getEthComponents(vaults, totalSupply);
        

        
        return underlyingTokens;
    }

    // Internal functions

    function _getEthComponents(
        address[] memory _vaults,
        uint256 _totalSupply
    )
        internal
        view
        returns (Component memory)
    {
        address[] memory debtsInEth = governance.listEthProtocols();

        uint256 ethBalance = 0;
        uint256 ethDebt = 0;

        // Compute negative amount for a given asset using all debt adapters
        for (uint256 j = 0; j < _vaults.length; j++) {
            address vault = _vaults[j];
            ethBalance += vault.balance;
            ethDebt += _computeDebt(debtsInEth, ETH, vault);
        }

        return Component({
            token: ETH,
            tokenType: ERC20_TOKEN,
            rate: (ethBalance * 1e18 / _totalSupply) - (ethDebt * 1e18 / _totalSupply)
        });
    }

    function _getTokenComponents(
        address _asset,
        address[] memory _vaults,
        address[] memory _debtAdapters,
        uint256 _totalSupply
    ) 
        internal
        view
        returns (Component memory)
    {
        uint256 componentBalance = 0;
        uint256 componentDebt = 0;

        // Compute positive amount for a given asset
        uint256 vaultsLength = _vaults.length;
        for (uint256 j = 0; j < vaultsLength; j++) {
            address vault = _vaults[j];
            componentBalance += ERC20(_asset).balanceOf(vault);
            componentDebt += _computeDebt(_debtAdapters, _asset, vault);
        }

        // Asset amount
        return(Component({
            token: _asset,
            tokenType: ERC20_TOKEN,
            rate: (componentBalance * 1e18 / _totalSupply) - (componentDebt * 1e18 / _totalSupply)
        }));
    }

    function _computeDebt(
        address[] memory _debtAdapters,
        address _asset,
        address _vault
    ) 
        internal
        view
        returns (uint256)
    {
        // Compute negative amount for a given asset using all debt adapters
        uint256 componentDebt = 0;
        uint256 debtsLength = _debtAdapters.length;
        for (uint256 k = 0; k < debtsLength; k++) {
            ProtocolAdapter debtAdapter = ProtocolAdapter(_debtAdapters[k]);
            try debtAdapter.getBalance(_asset, _vault) returns (uint256 _amount) {
                componentDebt += _amount;
            } catch {} // solhint-disable-line no-empty-blocks
        }
        return componentDebt;
    }
}
