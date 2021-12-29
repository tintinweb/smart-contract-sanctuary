/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/vshg2d131zzwv70wlf0ivb4pzch0jhw6-geb-fsm-governance-interface/dapp/geb-fsm-governance-interface/src/FsmGovernanceInterface.sol

pragma solidity =0.6.7;

////// /nix/store/vshg2d131zzwv70wlf0ivb4pzch0jhw6-geb-fsm-governance-interface/dapp/geb-fsm-governance-interface/src/FsmGovernanceInterface.sol
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

/* pragma solidity 0.6.7; */

abstract contract FsmLike {
    function stop() virtual external;
}

abstract contract AuthorityLike {
    function canCall(address src, address dst, bytes4 sig) virtual public view returns (bool);
}

contract FsmGovernanceInterface {
    // --- Authorization ---
    // The owner of the FSM interface
    address public owner;
    // Modifier that checks if the msg.sender is the owner
    modifier onlyOwner { require(msg.sender == owner, "fsm-governance-interface/only-owner"); _;}

    // The FSM interface authority
    address public authority;
    // Checks if msg.sender is allowed to call a specific function
    modifier isAuthorized {
        require(canCall(msg.sender, msg.sig), "fsm-governance-interface/not-authorized");
        _;
    }
    /*
    * @notice View function that checks whether an address is allowed to call a function
    * @param src The address for which we check permissions
    * @param sig The signature of the function to check permissions for
    */
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

    // --- Variables ---
    // Mapping of collateral types and associated FSMs
    mapping (bytes32 => address) public fsms;

    // --- Events ---
    event SetFsm(bytes32 collateralType, address fsm);
    event SetOwner(address owner);
    event SetAuthority(address authority);
    event StopFsm(bytes32 collateralType);

    constructor() public {
        owner = msg.sender;
        emit SetOwner(owner);
    }

    // --- Core Logic ---
    /*
    * @notice Whitelist a new FSM for a specific collateral type
    * @param collateralType The collateral type for which we set a FSM
    * @param fsm The FSM address to associate with the collateral type
    */
    function setFsm(bytes32 collateralType, address fsm) external onlyOwner {
        fsms[collateralType] = fsm;
        emit SetFsm(collateralType, fsm);
    }

    /*
    * @notice Set a new owner in the contract
    * @param owner_ New owner to set
    */
    function setOwner(address owner_) external onlyOwner {
        owner = owner_;
        emit SetOwner(owner);
    }
    /*
    * @notice Set a new authority in the contract
    * @notice authority_ New authority address
    */
    function setAuthority(address authority_) external onlyOwner {
        authority = authority_;
        emit SetAuthority(authority);
    }
    /*
    * @notice Stop a whitelisted FSM
    * @param collateralType Collateral type whose FSM will be stopped
    */
    function stopFsm(bytes32 collateralType) external isAuthorized {
        FsmLike(fsms[collateralType]).stop();
        emit StopFsm(collateralType);
    }
}