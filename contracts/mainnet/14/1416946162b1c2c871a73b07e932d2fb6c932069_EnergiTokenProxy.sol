// Copyright (C) 2020 Energi Core

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

pragma solidity ^0.5.0;

import './IEnergiTokenProxy.sol';

contract EnergiTokenProxy is IEnergiTokenProxy {

    address public delegate;

    address public proxyOwner;

    modifier onlyProxyOwner {
        require(msg.sender == proxyOwner, 'EnergiTokenProxy: FORBIDDEN');
        _;
    }

    constructor(address _owner, address _delegate) public {
        proxyOwner = _owner;
        delegate = _delegate;
    }

    function setProxyOwner(address _owner) external onlyProxyOwner {
        proxyOwner = _owner;
    }

    function upgradeDelegate(address _delegate) external onlyProxyOwner {
        delegate = _delegate;
    }

    function () external payable {

        address _delegate = delegate;
        require(_delegate != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _delegate, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}
