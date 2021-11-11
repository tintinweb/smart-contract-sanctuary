/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// hevm: flattened sources of src/CharterManager.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;

////// src/CharterManager.sol
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

/* pragma solidity 0.6.12; */

interface VatLike_16 {
    function live() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function fork(bytes32, address, address, int256, int256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function hope(address) external;
    function ilks(bytes32) external view returns (
        uint256 Art,  // [wad]
        uint256 rate, // [ray]
        uint256 spot, // [ray]
        uint256 line, // [rad]
        uint256 dust  // [rad]
    );
}

interface SpotterLike_3 {
    function ilks(bytes32) external returns (address, uint256);
}

interface GemLike_7 {
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

interface ManagedGemJoinLike {
    function gem() external view returns (GemLike_7);
    function ilk() external view returns (bytes32);
    function join(address, uint256) external;
    function exit(address, address, uint256) external;
}

contract UrnProxy {
    address immutable public usr;

    constructor(address vat_, address usr_) public {
        usr = usr_;
        VatLike_16(vat_).hope(msg.sender);
    }
}

contract CharterManager {
    address public implementation;
    mapping (address => uint256) public wards;

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event SetImplementation(address indexed);

    constructor() public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "CharterManager/non-authed");
        _;
    }

    function setImplementation(address implementation_) external auth {
        implementation = implementation_;
        emit SetImplementation(implementation_);
    }

    fallback() external {
        address _impl = implementation;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}