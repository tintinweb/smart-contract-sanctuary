// SPDX-License-Identifier: GPL-3.0
// Copyright 2021 The expo-go Authors
// This file is part of expo-go.
//
// expo-go is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.10;

// import the eip20 library
import "./EIP20.sol";

// this is contracts example for erc20 token
contract Token is EIP20 {
	constructor() EIP20("Test token", "TST") {
		_mint(msg.sender, 100000000000000000000000);
	}
}