/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// hevm: flattened sources of src/Simple.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.9;

////// src/Simple.sol
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.8.9; */

contract A {
    address public x;

    constructor(address x_) public {
        x = x_;
    }
}

contract Factory {

    function create() external {
         A a = new A(address(42));
    }
}