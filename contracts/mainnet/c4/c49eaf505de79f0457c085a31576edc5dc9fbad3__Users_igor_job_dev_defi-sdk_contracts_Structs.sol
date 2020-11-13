// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
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


struct ProtocolBalance {
    ProtocolMetadata metadata;
    AdapterBalance[] adapterBalances;
}


struct ProtocolMetadata {
    string name;
    string description;
    string websiteURL;
    string iconURL;
    uint256 version;
}


struct AdapterBalance {
    AdapterMetadata metadata;
    FullTokenBalance[] balances;
}


struct AdapterMetadata {
    address adapterAddress;
    string adapterType; // "Asset", "Debt"
}


// token and its underlying tokens (if exist) balances
struct FullTokenBalance {
    TokenBalance base;
    TokenBalance[] underlying;
}


struct TokenBalance {
    TokenMetadata metadata;
    uint256 amount;
}


// ERC20-style token metadata
// 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE address is used for ETH
struct TokenMetadata {
    address token;
    string name;
    string symbol;
    uint8 decimals;
}


struct Component {
    address token;
    string tokenType;  // "ERC20" by default
    uint256 rate;  // price per full share (1e18)
}
