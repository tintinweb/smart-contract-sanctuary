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
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


// The struct consists of TokenBalance structs for
// (base) token and its underlying tokens (if exist).
struct FullTokenBalance {
    TokenBalanceMeta base;
    TokenBalanceMeta[] underlying;
}


// The struct consists of token's address,
// amount, and ERC20-style metadata.
// NOTE: 0xEeee...EEeE address is used for ETH.
struct TokenBalanceMeta {
    address token;
    uint256 amount;
    ERC20Metadata erc20metadata;
}


// The struct consists of ERC20-style token metadata.
struct ERC20Metadata {
    string name;
    string symbol;
    uint8 decimals;
}


// The struct consists of protocol adapter's name
// and array of TokenBalanceWithAdapter structs.
struct AdapterBalance {
    bytes32 protocolAdapterName;
    TokenBalance[] tokenBalances;
}


// The struct consists of TokenBalance struct
// and token adapter's name, which should be used
// to retrieve underlying tokens and rates.
struct TokenBalance {
    bytes32 tokenAdapterName;
    address token;
    uint256 amount;
}


// The struct consists of token address,
// and price per full share (1e18).
struct Component {
    address token;
    uint256 rate;
}


//=============================== Interactive Adapters Structs ====================================


struct TransactionData {
    Action[] actions;
    Input[] inputs;
    Output[] requiredOutputs;
    uint256 nonce;
}


struct Action {
    bytes32 protocolAdapterName;
    ActionType actionType;
    address[] tokens;
    uint256[] amounts;
    AmountType[] amountTypes;
    bytes data;
}


struct Input {
    address token;
    uint256 amount;
    AmountType amountType;
    uint256 fee;
    address beneficiary;
}


struct Output {
    address token;
    uint256 amount;
}


enum ActionType { None, Deposit, Withdraw }


enum AmountType { None, Relative, Absolute }
