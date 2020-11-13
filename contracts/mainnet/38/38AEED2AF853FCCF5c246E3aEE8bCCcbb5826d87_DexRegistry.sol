pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

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

// SPDX-License-Identifier: GPL-3.0-only


/**
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

interface IAugustusSwapper {
    function getTokenTransferProxy() external view returns (address);

    struct Route {
        address payable exchange;
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee; // only used for 0xV3
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; // only used for 0xV3
        Route[] routes;
    }

    struct BuyRoute {
        address payable exchange;
        address targetExchange;
        uint256 fromAmount;
        uint256 toAmount;
        bytes payload;
        uint256 networkFee; // only used for 0xV3
    }
}


/**
 * @title IDexRegistry
 * @notice Interface for DexRegistry.
 * @author Olivier VDB - <olivier@argent.xyz>
 */
interface IDexRegistry {
    function verifyExchangeAdapters(IAugustusSwapper.Path[] calldata _path) external view;
    function verifyExchangeAdapters(IAugustusSwapper.BuyRoute[] calldata _routes) external view;
}



/**
 * @title DexRegistry
 * @notice Simple registry containing whitelisted DEX adapters to be used with the TokenExchanger.
 * @author Olivier VDB - <olivier@argent.xyz>
 */
contract DexRegistry is IDexRegistry, Owned {

    // Whitelisted DEX adapters
    mapping(address => bool) public isAuthorised;

    event DexAdded(address indexed _dex);
    event DexRemoved(address indexed _dex);


    /**
     * @notice Add/Remove a DEX adapter to/from the whitelist.
     * @param _dexes array of DEX adapters to add to (or remove from) the whitelist
     * @param _authorised array where each entry is true to add the corresponding DEX to the whitelist, false to remove it
     */
    function setAuthorised(address[] calldata _dexes, bool[] calldata _authorised) external onlyOwner {
        for(uint256 i = 0; i < _dexes.length; i++) {
            if(isAuthorised[_dexes[i]] != _authorised[i]) {
                isAuthorised[_dexes[i]] = _authorised[i];
                if(_authorised[i]) { 
                    emit DexAdded(_dexes[i]); 
                } else { 
                    emit DexRemoved(_dexes[i]);
                }
            }
        }
    }

    function verifyExchangeAdapters(IAugustusSwapper.Path[] calldata _path) external override view {
        for (uint i = 0; i < _path.length; i++) {
            for (uint j = 0; j < _path[i].routes.length; j++) {
                require(isAuthorised[_path[i].routes[j].exchange], "DR: Unauthorised DEX");
            }
        }
    }

    function verifyExchangeAdapters(IAugustusSwapper.BuyRoute[] calldata _routes) external override view {
        for (uint j = 0; j < _routes.length; j++) {
            require(isAuthorised[_routes[j].exchange], "DR: Unauthorised DEX");
        }
    }


}