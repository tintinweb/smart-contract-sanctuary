/**
 *Submitted for verification at snowtrace.io on 2021-11-12
*/

// File: contracts/lib/BasicStorageLib.sol

pragma solidity ^0.4.24;

library BasicStorageLib {

    struct UintData {
        mapping(bytes => mapping(bytes => uint))           _storage;
    }

    struct BoolData {
        mapping(bytes => mapping(bytes => bool))           _storage;
    }

    struct AddressData {
        mapping(bytes => mapping(bytes => address))        _storage;
    }

    struct BytesData {
        mapping(bytes => mapping(bytes => bytes))          _storage;
    }

    struct StringData {
        mapping(bytes => mapping(bytes => string))         _storage;
    }

    /* uintStorage */

    function setStorage(UintData storage self, bytes memory key, bytes memory innerKey, uint value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(UintData storage self, bytes memory key, bytes memory innerKey) internal view returns (uint) {
        return self._storage[key][innerKey];
    }

    function delStorage(UintData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* boolStorage */

    function setStorage(BoolData storage self, bytes memory key, bytes memory innerKey, bool value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(BoolData storage self, bytes memory key, bytes memory innerKey) internal view returns (bool) {
        return self._storage[key][innerKey];
    }

    function delStorage(BoolData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* addressStorage */

    function setStorage(AddressData storage self, bytes memory key, bytes memory innerKey, address value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(AddressData storage self, bytes memory key, bytes memory innerKey) internal view returns (address) {
        return self._storage[key][innerKey];
    }

    function delStorage(AddressData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* bytesStorage */

    function setStorage(BytesData storage self, bytes memory key, bytes memory innerKey, bytes memory value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(BytesData storage self, bytes memory key, bytes memory innerKey) internal view returns (bytes memory) {
        return self._storage[key][innerKey];
    }

    function delStorage(BytesData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

    /* stringStorage */

    function setStorage(StringData storage self, bytes memory key, bytes memory innerKey, string memory value) internal {
        self._storage[key][innerKey] = value;
    }

    function getStorage(StringData storage self, bytes memory key, bytes memory innerKey) internal view returns (string memory) {
        return self._storage[key][innerKey];
    }

    function delStorage(StringData storage self, bytes memory key, bytes memory innerKey) internal {
        delete self._storage[key][innerKey];
    }

}

// File: contracts/components/BasicStorage.sol

pragma solidity ^0.4.24;


contract BasicStorage {
    /************************************************************
     **
     ** VARIABLES
     **
     ************************************************************/

    //// basic variables
    using BasicStorageLib for BasicStorageLib.UintData;
    using BasicStorageLib for BasicStorageLib.BoolData;
    using BasicStorageLib for BasicStorageLib.AddressData;
    using BasicStorageLib for BasicStorageLib.BytesData;
    using BasicStorageLib for BasicStorageLib.StringData;

    BasicStorageLib.UintData    internal uintData;
    BasicStorageLib.BoolData    internal boolData;
    BasicStorageLib.AddressData internal addressData;
    BasicStorageLib.BytesData   internal bytesData;
    BasicStorageLib.StringData  internal stringData;
}

// File: contracts/oracle/OracleStorage.sol

pragma solidity 0.4.26;


contract OracleStorage is BasicStorage {
  /************************************************************
    **
    ** STRUCTURE DEFINATIONS
    **
    ************************************************************/
  struct StoremanGroupConfig {
    uint    deposit;
    uint[2] chain;
    uint[2] curve;
    bytes   gpk1;
    bytes   gpk2;
    uint    startTime;
    uint    endTime;
    uint8   status;
    bool    isDebtClean;
  }

  /************************************************************
    **
    ** VARIABLES
    **
    ************************************************************/
  /// @notice symbol -> price,
  mapping(bytes32 => uint) public mapPrices;

  /// @notice smgId -> StoremanGroupConfig
  mapping(bytes32 => StoremanGroupConfig) public mapStoremanGroupConfig;

  /// @notice owner and admin have the authority of admin
  address public admin;
}

// File: contracts/components/Owned.sol

/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//

pragma solidity ^0.4.24;

/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the message sender to be `owner`
    constructor() public {
        owner = msg.sender;
    }

    address public newOwner;

    function transferOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /// @notice `owner` can step down and assign some other address to this role
    /// @param _newOwner The address of the new owner. 0x0 can be used to create
    ///  an unowned neutral vault, however that cannot be undone
    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}

// File: contracts/components/Proxy.sol

/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */


contract Proxy {

    event Upgraded(address indexed implementation);

    address internal _implementation;

    function implementation() public view returns (address) {
        return _implementation;
    }

    function () external payable {
        address _impl = _implementation;
        require(_impl != address(0), "implementation contract not set");

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

// File: contracts/oracle/OracleProxy.sol

/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//

pragma solidity 0.4.26;




contract OracleProxy is OracleStorage, Owned, Proxy {
    /**
    *
    * MANIPULATIONS
    *
    */

    /// @notice                           function for setting or upgrading OracleDelegate address by owner
    /// @param impl                       OracleDelegate contract address
    function upgradeTo(address impl) public onlyOwner {
        require(impl != address(0), "Cannot upgrade to invalid address");
        require(impl != _implementation, "Cannot upgrade to the same implementation");
        _implementation = impl;
        emit Upgraded(impl);
    }
}