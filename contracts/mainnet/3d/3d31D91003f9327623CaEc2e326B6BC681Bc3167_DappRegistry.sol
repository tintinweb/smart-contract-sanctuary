// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

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

import "./IAuthoriser.sol";
import "./dapp/IFilter.sol";

contract DappRegistry is IAuthoriser {

    // The timelock period
    uint64 public timelockPeriod;
    // The new timelock period
    uint64 public newTimelockPeriod;
    // Time at which the new timelock becomes effective
    uint64 public timelockPeriodChangeAfter;

    // bit vector of enabled registry ids for each wallet
    mapping (address => bytes32) public enabledRegistryIds; // [wallet] => [bit vector of 256 registry ids]
    // authorised dapps and their filters for each registry id
    mapping (uint8 => mapping (address => bytes32)) public authorisations; // [registryId] => [dapp] => [{filter:160}{validAfter:64}]
    // pending authorised dapps and their filters for each registry id
    mapping (uint8 => mapping (address => bytes32)) public pendingFilterUpdates; // [registryId] => [dapp] => [{filter:160}{validAfter:64}]
    // owners for each registry id
    mapping (uint8 => address) public registryOwners; // [registryId] => [owner]
    
    event RegistryCreated(uint8 registryId, address registryOwner);
    event OwnerChanged(uint8 registryId, address newRegistryOwner);
    event TimelockChangeRequested(uint64 newTimelockPeriod);
    event TimelockChanged(uint64 newTimelockPeriod);
    event FilterUpdated(uint8 indexed registryId, address dapp, address filter, uint256 validAfter);
    event FilterUpdateRequested(uint8 indexed registryId, address dapp, address filter, uint256 validAfter);
    event DappAdded(uint8 indexed registryId, address dapp, address filter, uint256 validAfter);
    event DappRemoved(uint8 indexed registryId, address dapp);
    event ToggledRegistry(address indexed sender, uint8 registryId, bool enabled);

    modifier onlyOwner(uint8 _registryId) {
        validateOwner(_registryId);
        _;
    }
    
    constructor(uint64 _timelockPeriod) {
        // set the timelock period
        timelockPeriod = _timelockPeriod;
        // set the owner of the Argent Registry (registryId = 0)
        registryOwners[0] = msg.sender;

        emit RegistryCreated(0, msg.sender);
        emit TimelockChanged(_timelockPeriod);
    }

    /********* Wallet-centered functions *************/

    /**
    * @notice Returns whether a registry is enabled for a wallet
    * @param _wallet The wallet
    * @param _registryId The registry id
    */
    function isEnabledRegistry(address _wallet, uint8 _registryId) external view returns (bool isEnabled) {
        uint registries = uint(enabledRegistryIds[_wallet]);
        return (((registries >> _registryId) & 1) > 0) /* "is bit set for regId?" */ == (_registryId > 0) /* "not Argent registry?" */;
    }

    /**
    * @notice Returns whether a (_spender, _to, _data) call is authorised for a wallet
    * @param _wallet The wallet
    * @param _spender The spender of the tokens for token approvals, or the target of the transaction otherwise
    * @param _to The target of the transaction
    * @param _data The calldata of the transaction
    */
    function isAuthorised(address _wallet, address _spender, address _to, bytes calldata _data) public view override returns (bool) {
        uint registries = uint(enabledRegistryIds[_wallet]);
        // Check Argent Default Registry first. It is enabled by default, implying that a zero 
        // at position 0 of the `registries` bit vector means that the Argent Registry is enabled)
        for(uint registryId = 0; registryId == 0 || (registries >> registryId) > 0; registryId++) {
            bool isEnabled = (((registries >> registryId) & 1) > 0) /* "is bit set for regId?" */ == (registryId > 0) /* "not Argent registry?" */;
            if(isEnabled) { // if registryId is enabled
                uint auth = uint(authorisations[uint8(registryId)][_spender]); 
                uint validAfter = auth & 0xffffffffffffffff;
                if (0 < validAfter && validAfter <= block.timestamp) { // if the current time is greater than the validity time
                    address filter = address(uint160(auth >> 64));
                    if(filter == address(0) || IFilter(filter).isValid(_wallet, _spender, _to, _data)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    /**
    * @notice Returns whether a collection of (_spender, _to, _data) calls are authorised for a wallet
    * @param _wallet The wallet
    * @param _spenders The spenders of the tokens for token approvals, or the targets of the transaction otherwise
    * @param _to The targets of the transaction
    * @param _data The calldata of the transaction
    */
    function areAuthorised(
        address _wallet,
        address[] calldata _spenders,
        address[] calldata _to,
        bytes[] calldata _data
    )
        external
        view
        override
        returns (bool) 
    {
        for(uint i = 0; i < _spenders.length; i++) {
            if(!isAuthorised(_wallet, _spenders[i], _to[i], _data[i])) {
                return false;
            }
        }
        return true;
    }

    /**
    * @notice Allows a wallet to decide whether _registryId should be part of the list of enabled registries for that wallet
    * @param _registryId The id of the registry to enable/disable
    * @param _enabled Whether the registry should be enabled (true) or disabled (false)
    */
    function toggleRegistry(uint8 _registryId, bool _enabled) external {
        require(registryOwners[_registryId] != address(0), "DR: unknown registry");
        uint registries = uint(enabledRegistryIds[msg.sender]);
        bool current = (((registries >> _registryId) & 1) > 0) /* "is bit set for regId?" */ == (_registryId > 0) /* "not Argent registry?" */;
        if(current != _enabled) {
            enabledRegistryIds[msg.sender] = bytes32(registries ^ (uint(1) << _registryId)); // toggle [_registryId]^th bit
            emit ToggledRegistry(msg.sender, _registryId, _enabled);
        }
    }

    /**************  Management of registry list  *****************/

    /**
    * @notice Create a new registry. Only the owner of the Argent registry (i.e. the registry with id 0 -- hence the use of `onlyOwner(0)`)
    * can create a new registry.
    * @param _registryId The id of the registry to create
    * @param _registryOwner The owner of that new registry
    */
    function createRegistry(uint8 _registryId, address _registryOwner) external onlyOwner(0) {
        require(_registryOwner != address(0), "DR: registry owner is 0");
        require(registryOwners[_registryId] == address(0), "DR: duplicate registry");
        registryOwners[_registryId] = _registryOwner;
        emit RegistryCreated(_registryId, _registryOwner);
    }

    // Note: removeRegistry is not supported because that would allow the owner to replace registries that 
    // have already been enabled by users with a new (potentially maliciously populated) registry 

    /**
    * @notice Lets a registry owner change the owner of the registry.
    * @param _registryId The id of the registry
    * @param _newRegistryOwner The new owner of the registry
    */
    function changeOwner(uint8 _registryId, address _newRegistryOwner) external onlyOwner(_registryId) {
        require(_newRegistryOwner != address(0), "DR: new registry owner is 0");
        registryOwners[_registryId] = _newRegistryOwner;
        emit OwnerChanged(_registryId, _newRegistryOwner);
    }

    /**
    * @notice Request a change of the timelock value. Only the owner of the Argent registry (i.e. the registry with id 0 -- 
    * hence the use of `onlyOwner(0)`) can perform that action. This action can be confirmed after the (old) timelock period.
    * @param _newTimelockPeriod The new timelock period
    */
    function requestTimelockChange(uint64 _newTimelockPeriod) external onlyOwner(0) {
        newTimelockPeriod = _newTimelockPeriod;
        timelockPeriodChangeAfter = uint64(block.timestamp) + timelockPeriod;
        emit TimelockChangeRequested(_newTimelockPeriod);
    }

    /**
    * @notice Confirm a change of the timelock value requested by `requestTimelockChange()`.
    */
    function confirmTimelockChange() external {
        uint64 newPeriod = newTimelockPeriod;
        require(timelockPeriodChangeAfter > 0 && timelockPeriodChangeAfter <= block.timestamp, "DR: can't (yet) change timelock");
        timelockPeriod = newPeriod;
        newTimelockPeriod = 0;
        timelockPeriodChangeAfter = 0;
        emit TimelockChanged(newPeriod);
    }

    /**************  Management of registries' content  *****************/

    /**
    * @notice Returns the (filter, validAfter) tuple recorded for a dapp in a given registry.
    * `filter` is the authorisation filter stored for the dapp (if any) and `validAfter` is the 
    * timestamp after which the filter becomes active.
    * @param _registryId The registry id
    * @param _dapp The dapp
    */
    function getAuthorisation(uint8 _registryId, address _dapp) external view returns (address filter, uint64 validAfter) {
        uint auth = uint(authorisations[_registryId][_dapp]);
        filter = address(uint160(auth >> 64));
        validAfter = uint64(auth & 0xffffffffffffffff);
    }

    /**
    * @notice Add a new dapp to the registry with an optional filter
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to authorise.
    * @param _filter The address of the filter contract to use, if any.
    */
    function addDapp(uint8 _registryId, address _dapp, address _filter) external onlyOwner(_registryId) {
        require(authorisations[_registryId][_dapp] == bytes32(0), "DR: dapp already added");
        uint validAfter = block.timestamp + timelockPeriod;
        // Store the new authorisation as {filter:160}{validAfter:64}.
        authorisations[_registryId][_dapp] = bytes32((uint(uint160(_filter)) << 64) | validAfter);
        emit DappAdded(_registryId, _dapp, _filter, validAfter);
    }


    /**
    * @notice Deauthorise a dapp in a registry
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to deauthorise.
    */
    function removeDapp(uint8 _registryId, address _dapp) external onlyOwner(_registryId) {
        require(authorisations[_registryId][_dapp] != bytes32(0), "DR: unknown dapp");
        delete authorisations[_registryId][_dapp];
        delete pendingFilterUpdates[_registryId][_dapp];
        emit DappRemoved(_registryId, _dapp);
    }

    /**
    * @notice Request to change an authorisation filter for a dapp that has previously been authorised. We cannot 
    * immediately override the existing filter and need to store the new filter for a timelock period before being 
    * able to change the filter.
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to authorise.
    * @param _filter The address of the new filter contract to use.
    */
    function requestFilterUpdate(uint8 _registryId, address _dapp, address _filter) external onlyOwner(_registryId) {
        require(authorisations[_registryId][_dapp] != bytes32(0), "DR: unknown dapp");
        uint validAfter = block.timestamp + timelockPeriod;
        // Store the future authorisation as {filter:160}{validAfter:64}
        pendingFilterUpdates[_registryId][_dapp] = bytes32((uint(uint160(_filter)) << 64) | validAfter);
        emit FilterUpdateRequested(_registryId, _dapp, _filter, validAfter);
    }

    /**
    * @notice Confirm the filter change requested by `requestFilterUpdate`
    * @param _registryId The id of the registry to modify
    * @param _dapp The address of the dapp contract to authorise.
    */
    function confirmFilterUpdate(uint8 _registryId, address _dapp) external {
        uint newAuth = uint(pendingFilterUpdates[_registryId][_dapp]);
        require(newAuth > 0, "DR: no pending filter update");
        uint validAfter = newAuth & 0xffffffffffffffff;
        require(validAfter <= block.timestamp, "DR: too early to confirm auth");
        authorisations[_registryId][_dapp] = bytes32(newAuth);
        emit FilterUpdated(_registryId, _dapp, address(uint160(newAuth >> 64)), validAfter); 
        delete pendingFilterUpdates[_registryId][_dapp];
    }

    /********  Internal Functions ***********/

    function validateOwner(uint8 _registryId) internal view {
        address owner = registryOwners[_registryId];
        require(owner != address(0), "DR: unknown registry");
        require(msg.sender == owner, "DR: sender != registry owner");
    }
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

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

interface IAuthoriser {
    function isAuthorised(address _sender, address _spender, address _to, bytes calldata _data) external view returns (bool);
    function areAuthorised(
        address _spender,
        address[] calldata _spenders,
        address[] calldata _to,
        bytes[] calldata _data
    )
        external
        view
        returns (bool);
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

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

interface IFilter {
    function isValid(address _wallet, address _spender, address _to, bytes calldata _data) external view returns (bool valid);
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