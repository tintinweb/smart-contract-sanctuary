/*
 * This file is part of the Meeds project (https://meeds.io/).
 * Copyright (C) 2020 Meeds Association
 * [email protected]
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
pragma solidity ^0.5.0;

import './TokenStorage.sol';
import './Owned.sol';
import './DataOwned.sol';

/**
 * @title ERTToken.sol
 * @dev Proxy contract that delegates calls to a dedicated ERC20 implementation
 * contract. The needed data here are implementation address and owner.
 */
contract ERTToken is TokenStorage, Owned {

    /**
     * @param _implementationAddress First version of the ERC20 Token implementation address
     * @param _dataAddress First version of data contract address
     */
    constructor(address _implementationAddress, address _dataAddress) public{
        require(_dataAddress != address(0));
        require(_implementationAddress != address(0));

        // Set implementation address and version
        version = 1;
        implementationAddress = _implementationAddress;

        // Set data address
        super._setDataAddress(1, _dataAddress);
    }

    /**
     * @dev Called for all calls that aren't implemented on proxy, like
     * ERC20 methods. This is payable to enable owner to give money to
     * the ERC20 contract
     */
    function() payable external{
      _delegateCall(implementationAddress);
    }

    /**
     * @dev Delegate call to ERC20 contract
     */
    function _delegateCall(address _impl) private{
      assembly {
         let ptr := mload(0x40)
         calldatacopy(ptr, 0, calldatasize)
         let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
         let size := returndatasize
         returndatacopy(ptr, 0, size)

         switch result
         case 0 { revert(ptr, size) }
         default { return(ptr, size) }
      }
    }

}