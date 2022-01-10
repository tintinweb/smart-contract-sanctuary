// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import "./BaseSplitCodeFactory.sol";

contract MockFactoryCreatedContract {
    bytes32 private _id;

    constructor(bytes32 id) {
        require(id != 0, "NON_ZERO_ID");
        _id = id;
    }

    function getId() external view returns (bytes32) {
        return _id;
    }
}

contract MockSplitCodeFactory is BaseSplitCodeFactory {
    event ContractCreated(address destination);

    constructor() BaseSplitCodeFactory(type(MockFactoryCreatedContract).creationCode) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function create(bytes32 id) external returns (address) {
        address destination = _create(abi.encode(id));
        emit ContractCreated(destination);

        return destination;
    }
}