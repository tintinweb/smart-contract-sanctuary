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

interface AdapterRegistry {

    function isValidTokenAdapter(
        string calldata tokenAdapterName
    ) 
        external 
        returns (bool);
}

struct TypedToken {
    string tokenType;
    address token;
}

/**
 * @dev BerezkaTokenAdapterGovernance contract.
 * Main function of this contract is to maintains a Structure of BerezkaDAO
 * @author Vasin Denis <denis.vasin@easychain.tech>
 */
contract BerezkaTokenAdapterGovernance is Ownable() {

    AdapterRegistry internal constant ADAPTER_REGISTRY = 
        AdapterRegistry(0x06FE76B2f432fdfEcAEf1a7d4f6C3d41B5861672);

    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev This is a set of plain assets (ERC20) used by DAO. 
    /// This list also include addresses of Uniswap/Balancer tokenized pools.
    mapping (string => EnumerableSet.AddressSet) private tokens;

    /// @dev This is a list of all token types that are managed by contract
    /// New token type is added to this list upon first adding a token with given type
    string[] public tokenTypes;

    /// @dev This is a set of debt protocol adapters that return debt in ETH
    EnumerableSet.AddressSet private ethProtocols;

    /// @dev This is a set of debt protocol adapters that return debt for ERC20 tokens
    EnumerableSet.AddressSet private protocols;

    /// @dev This is a mapping from Berezka DAO product to corresponding Vault addresses
    mapping(address => address[]) private productVaults;

    constructor(address[] memory _protocols, address[] memory _ethProtocols) public {
        _add(protocols, _protocols);
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

    function addTokens(string memory _type, address[] memory _tokens) public onlyOwner() {
        require(_tokens.length > 0, "Length should be > 0");
        require(ADAPTER_REGISTRY.isValidTokenAdapter(_type), "Invalid token adapter name");

        if (tokens[_type].length() == 0) {
            tokenTypes.push(_type);
        }
        _add(tokens[_type], _tokens);
    }

    function addProtocols(address[] memory _protocols) public onlyOwner() {
        require(_protocols.length > 0, "Length should be > 0");

        _add(protocols, _protocols);
    }

    function addEthProtocols(address[] memory _ethProtocols) public onlyOwner() {
        require(_ethProtocols.length > 0, "Length should be > 0");

        _add(ethProtocols, _ethProtocols);
    }

    function removeTokens(string memory _type, address[] memory _tokens) public onlyOwner() {
        require(_tokens.length > 0, "Length should be > 0");

        _remove(tokens[_type], _tokens);
    }

    function removeProtocols(address[] memory _protocols) public onlyOwner() {
        require(_protocols.length > 0, "Length should be > 0");

        _remove(protocols, _protocols);
    }

    function removeEthProtocols(address[] memory _ethProtocols) public onlyOwner() {
        require(_ethProtocols.length > 0, "Length should be > 0");

        _remove(ethProtocols, _ethProtocols);
    }

    function setTokenTypes(string[] memory _tokenTypes) public onlyOwner() {
        require(_tokenTypes.length > 0, "Length should be > 0");

        tokenTypes = _tokenTypes;
    }

    // View functions

    function listTokens() external view returns (TypedToken[] memory) {
        uint256 tokenLength = tokenTypes.length;
        uint256 resultLength = 0;
        for (uint256 i = 0; i < tokenLength; i++) {
            resultLength += tokens[tokenTypes[i]].length();
        }
        TypedToken[] memory result = new TypedToken[](resultLength);
        uint256 resultIndex = 0;
        for (uint256 i = 0; i < tokenLength; i++) {
            string memory tokenType = tokenTypes[i];
            address[] memory typedTokens = _list(tokens[tokenType]);
            uint256 typedTokenLength = typedTokens.length;
            for (uint256 j = 0; j < typedTokenLength; j++) {
                result[resultIndex] = TypedToken(tokenType, typedTokens[j]);
                resultIndex++;
            }
        }
        return result;
    }

    function listTokens(string calldata _type) external view returns (address[] memory) {
        return _list(tokens[_type]);
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
