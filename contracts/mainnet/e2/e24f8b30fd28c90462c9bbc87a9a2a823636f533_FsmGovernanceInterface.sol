/**
 *Submitted for verification at Etherscan.io on 2021-02-14
*/

/// FsmGovernanceInterface -- governance interface for oracle security modules

// Copyright (C) 2019 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.6.7;

abstract contract FsmLike {
    function stop() virtual external;
}

abstract contract AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) virtual public view returns (bool);
}

contract FsmGovernanceInterface {
    address public owner;
    modifier onlyOwner { require(msg.sender == owner, "fsm-governance-interface/only-owner"); _;}

    address public authority;
    modifier isAuthorized {
        require(canCall(msg.sender, msg.sig), "fsm-governance-interface/not-authorized");
        _;
    }
    function canCall(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == address(0)) {
            return false;
        } else {
            return AuthorityLike(authority).canCall(src, address(this), sig);
        }
    }

    mapping (bytes32 => address) public fsms;

    event SetFsm(bytes32 collateralType, address fsm);
    event SetOwner(address owner);
    event SetAuthority(address authority);
    event StopFsm(bytes32 collateralType);

    constructor() public {
        owner = msg.sender;
        emit SetOwner(owner);
    }

    function setFsm(bytes32 collateralType, address fsm) external onlyOwner {
        fsms[collateralType] = fsm;
        emit SetFsm(collateralType, fsm);
    }

    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
        emit SetOwner(owner);
    }

    function setAuthority(address authority_) external onlyOwner {
        authority = authority_;
        emit SetAuthority(authority);
    }

    function stopFsm(bytes32 collateralType) external isAuthorized {
        FsmLike(fsms[collateralType]).stop();
        emit StopFsm(collateralType);
    }
}