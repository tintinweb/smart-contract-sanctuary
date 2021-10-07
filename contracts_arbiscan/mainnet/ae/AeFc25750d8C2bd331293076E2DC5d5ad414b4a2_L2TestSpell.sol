// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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

pragma solidity ^0.6.11;

interface L2Spell {
  function act() external;
}

interface AuthLike {
  function rely(address usr) external;

  function deny(address usr) external;
}

// A test spell that ensures that DAI permissions are set correctly

contract L2TestSpell is L2Spell {
  address public immutable l2Dai;

  constructor(address _l2Dai) public {
    l2Dai = _l2Dai;
  }

  function act() external override {
    address guy = 0x0000000000000000000000000000000000000000;

    AuthLike(l2Dai).rely(guy);
    AuthLike(l2Dai).deny(guy);
  }
}