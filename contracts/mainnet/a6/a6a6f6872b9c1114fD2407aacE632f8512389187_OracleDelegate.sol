/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

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

// File: contracts/oracle/OracleDelegate.sol

pragma solidity 0.4.26;

/**
 * Math operations with safety checks
 */



contract OracleDelegate is OracleStorage, Owned {
  /**
    *
    * EVENTS
    *
    */
  event SetAdmin(address addr);
  event UpdatePrice(bytes32[] keys, uint[] prices);
  event SetDebtClean(bytes32 indexed id, bool isDebtClean);
  event SetStoremanGroupConfig(bytes32 indexed id, uint8 status, uint deposit, uint[2] chain, uint[2] curve, bytes gpk1, bytes gpk2, uint startTime, uint endTime);
  event SetStoremanGroupStatus(bytes32 indexed id, uint8 status);
  event UpdateDeposit(bytes32 indexed id, uint deposit);

  /**
    *
    * MODIFIERS
    *
    */

  modifier onlyAdmin() {
      require((msg.sender == admin) || (msg.sender == owner), "not admin");
      _;
  }

  /**
  *
  * MANIPULATIONS
  *
  */

  function updatePrice(
    bytes32[] keys,
    uint[] prices
  )
    external
    onlyAdmin
  {
    require(keys.length == prices.length, "length not same");

    for (uint256 i = 0; i < keys.length; i++) {
      mapPrices[keys[i]] = prices[i];
    }

    emit UpdatePrice(keys, prices);
  }

  function updateDeposit(
    bytes32 smgID,
    uint amount
  )
    external
    onlyAdmin
  {
    mapStoremanGroupConfig[smgID].deposit = amount;

    emit UpdateDeposit(smgID, amount);
  }

  function setStoremanGroupStatus(
    bytes32 id,
    uint8  status
  )
    external
    onlyAdmin
  {
    mapStoremanGroupConfig[id].status = status;

    emit SetStoremanGroupStatus(id, status);
  }

  function setStoremanGroupConfig(
    bytes32 id,
    uint8   status,
    uint    deposit,
    uint[2] chain,
    uint[2] curve,
    bytes   gpk1,
    bytes   gpk2,
    uint    startTime,
    uint    endTime
  )
    external
    onlyAdmin
  {
    mapStoremanGroupConfig[id].deposit = deposit;
    mapStoremanGroupConfig[id].status = status;
    mapStoremanGroupConfig[id].chain[0] = chain[0];
    mapStoremanGroupConfig[id].chain[1] = chain[1];
    mapStoremanGroupConfig[id].curve[0] = curve[0];
    mapStoremanGroupConfig[id].curve[1] = curve[1];
    mapStoremanGroupConfig[id].gpk1 = gpk1;
    mapStoremanGroupConfig[id].gpk2 = gpk2;
    mapStoremanGroupConfig[id].startTime = startTime;
    mapStoremanGroupConfig[id].endTime = endTime;

    emit SetStoremanGroupConfig(id, status, deposit, chain, curve, gpk1, gpk2, startTime, endTime);
  }

  // robot 都是true时,才调用
  function setDebtClean(
    bytes32 storemanGroupId,
    bool isClean
  )
    external
    onlyAdmin
  {
    mapStoremanGroupConfig[storemanGroupId].isDebtClean = isClean;

    emit SetDebtClean(storemanGroupId, isClean);
  }

  function setAdmin(
    address addr
  ) external onlyOwner
  {
    admin = addr;

    emit SetAdmin(addr);
  }

  function getValue(bytes32 key) external view returns (uint) {
    return mapPrices[key];
  }

  function getValues(bytes32[] keys) external view returns (uint[] values) {
    values = new uint[](keys.length);
    for(uint256 i = 0; i < keys.length; i++) {
        values[i] = mapPrices[keys[i]];
    }
  }

  function getDeposit(bytes32 smgID) external view returns (uint) {
    return mapStoremanGroupConfig[smgID].deposit;
  }

  function getStoremanGroupConfig(
    bytes32 id
  )
    external
    view
    returns(bytes32 groupId, uint8 status, uint deposit, uint chain1, uint chain2, uint curve1, uint curve2, bytes gpk1, bytes gpk2, uint startTime, uint endTime)
  {
    groupId = id;
    status = mapStoremanGroupConfig[id].status;
    deposit = mapStoremanGroupConfig[id].deposit;
    chain1 = mapStoremanGroupConfig[id].chain[0];
    chain2 = mapStoremanGroupConfig[id].chain[1];
    curve1 = mapStoremanGroupConfig[id].curve[0];
    curve2 = mapStoremanGroupConfig[id].curve[1];
    gpk1 = mapStoremanGroupConfig[id].gpk1;
    gpk2 = mapStoremanGroupConfig[id].gpk2;
    startTime = mapStoremanGroupConfig[id].startTime;
    endTime = mapStoremanGroupConfig[id].endTime;
  }

  function getStoremanGroupStatus(bytes32 id)
    public
    view
    returns(uint8 status, uint startTime, uint endTime)
  {
    status = mapStoremanGroupConfig[id].status;
    startTime = mapStoremanGroupConfig[id].startTime;
    endTime = mapStoremanGroupConfig[id].endTime;
  }

  function isDebtClean(
    bytes32 storemanGroupId
  )
    external
    view
    returns (bool)
  {
    return mapStoremanGroupConfig[storemanGroupId].isDebtClean;
  }
}