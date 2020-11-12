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

import { EnumerableSet } from "./EnumerableSet.sol";
import { Ownable } from "./Ownable.sol";

/**
 * @dev BerezkaTokenAdapterGovernance contract.
 * Main function of this contract is to maintains a Structure of BerezkaDAO
 * @author Vasin Denis <denis.vasin@easychain.tech>
 */
contract BerezkaTokenAdapterGovernance is Ownable() {

    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev This is a set of plain assets (ERC20) used by DAO. 
    /// This list also include addresses of Uniswap/Balancer tokenized pools.
    EnumerableSet.AddressSet private tokens;

    /// @dev This is a set of debt protocol adapters that return debt in ETH
    EnumerableSet.AddressSet private ethProtocols;

    /// @dev This is a set of debt protocol adapters that return debt for ERC20 tokens
    EnumerableSet.AddressSet private protocols;

    /// @dev This is a mapping from Berezka DAO product to corresponding Vault addresses
    mapping(address => address[]) private productVaults;

    constructor(address[] memory _tokens, address[] memory _protocols, address[] memory _ethProtocols) public {
        _add(protocols, _protocols);
        _add(tokens, _tokens);
        _add(ethProtocols, _ethProtocols);
    }

    // Modification functions (all only by owner)

    function setProductVaults(address _product, address[] memory _vaults) public onlyOwner() {
        require(_product != address(0), "_product is 0");
        require(_vaults.length > 0, "_vaults.length should be > 0");

        productVaults[_product] = _vaults;
    }

    function removeProduct(address _product) public onlyOwner() {
        require(_product != address(0), "_product is 0");

        delete productVaults[_product];
    }

    function addTokens(address[] memory _tokens) public onlyOwner() {
        _add(tokens, _tokens);
    }

    function addProtocols(address[] memory _protocols) public onlyOwner() {
        _add(protocols, _protocols);
    }

    function removeTokens(address[] memory _tokens) public onlyOwner() {
        _remove(tokens, _tokens);
    }

    function removeProtocols(address[] memory _protocols) public onlyOwner() {
        _remove(protocols, _protocols);
    }

    function removeEthProtocols(address[] memory _ethProtocols) public onlyOwner() {
        _remove(ethProtocols, _ethProtocols);
    }

    // View functions

    function listTokens() external view returns (address[] memory) {
        return _list(tokens);
    }

    function listProtocols() external view returns (address[] memory) {
        return _list(protocols);
    }

    function listEthProtocols() external view returns (address[] memory) {
        return _list(ethProtocols);
    }

    function getVaults(address _token) external view returns (address[] memory) {
        return productVaults[_token];
    }

    // Internal functions

    function _add(EnumerableSet.AddressSet storage _set, address[] memory _addresses) internal {
        for (uint i = 0; i < _addresses.length; i++) {
            _set.add(_addresses[i]);
        }
    }

    function _remove(EnumerableSet.AddressSet storage _set, address[] memory _addresses) internal {
        for (uint i = 0; i < _addresses.length; i++) {
            _set.remove(_addresses[i]);
        }
    }

    function _list(EnumerableSet.AddressSet storage _set) internal view returns(address[] memory) {
        address[] memory result = new address[](_set.length());
        for (uint i = 0; i < _set.length(); i++) {
            result[i] = _set.at(i);
        }
        return result;
    }
}
