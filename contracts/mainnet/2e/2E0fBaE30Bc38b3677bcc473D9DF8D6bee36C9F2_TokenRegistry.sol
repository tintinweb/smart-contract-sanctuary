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
pragma solidity ^0.8.3;

/**
 * @title ITokenRegistry
 * @notice TokenRegistry interface
 */
interface ITokenRegistry {
    function isTokenTradable(address _token) external view returns (bool _isTradable);
    function areTokensTradable(address[] calldata _tokens) external view returns (bool _areTradable);
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

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
pragma solidity ^0.8.3;

import "./ITokenRegistry.sol";
import "./base/Managed.sol";

/**
 * @title TokenRegistry
 * @notice Contract storing a list of tokens that can be safely traded.
 * @notice Only the owner can make a token tradable. Managers can make a token untradable.
 */
contract TokenRegistry is ITokenRegistry, Managed {

    // Tradable flag per token
    mapping(address => bool) public isTradable;

    function isTokenTradable(address _token) external override view returns (bool _isTradable) {
        _isTradable = isTradable[_token];
    }

    function areTokensTradable(address[] calldata _tokens) external override view returns (bool _areTradable) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if(!isTradable[_tokens[i]]) {
                return false;
            }
        }
        return true;
    }

    function getTradableForTokenList(address[] calldata _tokens) external view returns (bool[] memory _tradable) {
        _tradable = new bool[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tradable[i] = isTradable[_tokens[i]];
        }
    }

    function setTradableForTokenList(address[] calldata _tokens, bool[] calldata _tradable) external {
        require(_tokens.length == _tradable.length, "TR: Array length mismatch");
        if(msg.sender == owner) {
            for (uint256 i = 0; i < _tokens.length; i++) {
                isTradable[_tokens[i]] = _tradable[i];
            }
        } else {
            require(managers[msg.sender], "TR: Unauthorised");
            for (uint256 i = 0; i < _tokens.length; i++) {
                require(_tradable[i] == false, "TR: Unauthorised operation");
                isTradable[_tokens[i]] = _tradable[i];
            }
        }
    }
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

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
pragma solidity ^0.8.3;

import "./Owned.sol";

/**
 * @title Managed
 * @notice Basic contract that defines a set of managers. Only the owner can add/remove managers.
 * @author Julien Niset, Olivier VDB - <[email protected]>, <[email protected]>
 */
contract Managed is Owned {

    // The managers
    mapping (address => bool) public managers;

    /**
     * @notice Throws if the sender is not a manager.
     */
    modifier onlyManager {
        require(managers[msg.sender] == true, "M: Must be manager");
        _;
    }

    event ManagerAdded(address indexed _manager);
    event ManagerRevoked(address indexed _manager);

    /**
    * @notice Adds a manager.
    * @param _manager The address of the manager.
    */
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "M: Address must not be null");
        if (managers[_manager] == false) {
            managers[_manager] = true;
            emit ManagerAdded(_manager);
        }
    }

    /**
    * @notice Revokes a manager.
    * @param _manager The address of the manager.
    */
    function revokeManager(address _manager) external virtual onlyOwner {
        // solhint-disable-next-line reason-string
        require(managers[_manager] == true, "M: Target must be an existing manager");
        delete managers[_manager];
        emit ManagerRevoked(_manager);
    }
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

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
pragma solidity >=0.5.4 <0.9.0;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}