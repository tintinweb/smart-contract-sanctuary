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

// File: contracts/components/Halt.sol

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


contract Halt is Owned {

    bool public halted = false;

    modifier notHalted() {
        require(!halted, "Smart contract is halted");
        _;
    }

    modifier isHalted() {
        require(halted, "Smart contract is not halted");
        _;
    }

    /// @notice function Emergency situation that requires
    /// @notice contribution period to stop or not.
    function setHalt(bool halt)
        public
        onlyOwner
    {
        halted = halt;
    }
}

// File: contracts/lib/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath div 0"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath sub b > a");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath add overflow");

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath mod 0");
        return a % b;
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

// File: contracts/quota/QuotaStorage.sol

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



contract QuotaStorage is BasicStorage {
    
    /// @dev Math operations with safety checks
    using SafeMath for uint;

    struct Quota {
        /// amount of original token to be received, equals to amount of WAN token to be minted
        uint debt_receivable;
        /// amount of WAN token to be burnt
        uint debt_payable;
        /// amount of original token has been exchanged to the wanchain
        uint _debt;
        /// amount of original token to be received, equals to amount of WAN token to be minted
        uint asset_receivable;
        /// amount of WAN token to be burnt
        uint asset_payable;
        /// amount of original token has been exchanged to the wanchain
        uint _asset;
        /// data is active
        bool _active;
    }

    /// @dev the denominator of deposit rate value
    uint public constant DENOMINATOR = 10000;

    /// @dev mapping: tokenId => storemanPk => Quota
    mapping(uint => mapping(bytes32 => Quota)) quotaMap;

    /// @dev mapping: storemanPk => tokenIndex => tokenId, tokenIndex:0,1,2,3...
    mapping(bytes32 => mapping(uint => uint)) storemanTokensMap;

    /// @dev mapping: storemanPk => token count
    mapping(bytes32 => uint) storemanTokenCountMap;

    /// @dev mapping: htlcAddress => exist
    mapping(address => bool) public htlcGroupMap;

    /// @dev save deposit oracle address (storeman admin or oracle)
    address public depositOracleAddress;

    /// @dev save price oracle address
    address public priceOracleAddress;

    /// @dev deposit rate use for deposit amount calculate
    uint public depositRate;

    /// @dev deposit token's symbol
    string public depositTokenSymbol;

    /// @dev token manger contract address
    address public tokenManagerAddress;

    /// @dev oracle address for check other chain's debt clean
    address public debtOracleAddress;

    /// @dev limit the minimize value of fast cross chain
    uint public fastCrossMinValue;

    modifier onlyHtlc() {
        require(htlcGroupMap[msg.sender], "Not in HTLC group");
        _;
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

// File: contracts/quota/QuotaProxy.sol

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

/**
 * Math operations with safety checks
 */




contract QuotaProxy is QuotaStorage, Halt, Proxy {
    ///@dev                     update the address of HTLCDelegate contract
    ///@param impl            the address of the new HTLCDelegate contract
    function upgradeTo(address impl) public onlyOwner {
        require(impl != address(0), "Cannot upgrade to invalid address");
        require(
            impl != _implementation,
            "Cannot upgrade to the same implementation"
        );
        _implementation = impl;
        emit Upgraded(impl);
    }
}

// File: contracts/quota/QuotaStorageV2.sol

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


/**
 * Math operations with safety checks
 */

contract QuotaStorageV2 is QuotaProxy {
    /// @dev mapping: tokenId => storemanPk => Quota
    mapping(uint => mapping(bytes32 => Quota)) v2QuotaMap;

    /// @dev mapping: storemanPk => tokenIndex => tokenId, tokenIndex:0,1,2,3...
    mapping(bytes32 => mapping(uint => uint)) v2TokensMap;

    /// @dev mapping: storemanPk => token count
    mapping(bytes32 => uint) v2TokenCountMap;

    /// upgrade version
    uint public version;
}

// File: contracts/interfaces/IOracle.sol

pragma solidity 0.4.26;

interface IOracle {
  function getDeposit(bytes32 smgID) external view returns (uint);
  function getValue(bytes32 key) external view returns (uint);
  function getValues(bytes32[] keys) external view returns (uint[] values);
  function getStoremanGroupConfig(
    bytes32 id
  ) external view returns(bytes32 groupId, uint8 status, uint deposit, uint chain1, uint chain2, uint curve1, uint curve2, bytes gpk1, bytes gpk2, uint startTime, uint endTime);
}

// File: contracts/quota/QuotaDelegate.sol

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

/**
 * Math operations with safety checks
 */



interface _ITokenManager {
    function getAncestorSymbol(uint id) external view returns (string symbol, uint8 decimals);
}

interface _IStoremanGroup {
    function getDeposit(bytes32 id) external view returns(uint deposit);
}

interface IDebtOracle {
    function isDebtClean(bytes32 storemanGroupId) external view returns (bool);
}


contract QuotaDelegate is QuotaStorageV2 {

    event AssetTransfered(bytes32 indexed srcStoremanGroupId, bytes32 indexed dstStoremanGroupId, uint tokenId, uint value);

    event DebtReceived(bytes32 indexed srcStoremanGroupId, bytes32 indexed dstStoremanGroupId, uint tokenId, uint value);

    modifier checkMinValue(uint tokenId, uint value) {
        if (fastCrossMinValue > 0) {
            string memory symbol;
            uint decimals;
            (symbol, decimals) = getTokenAncestorInfo(tokenId);
            uint price = getPrice(symbol);
            if (price > 0) {
                uint count = fastCrossMinValue.mul(10**decimals).div(price);
                require(value >= count, "value too small");
            }
        }
        _;
    }
    
    /// @notice                         config params for owner
    /// @param _priceOracleAddr         token price oracle contract address
    /// @param _htlcAddr                HTLC contract address
    /// @param _depositOracleAddr       deposit oracle address, storemanAdmin or oracle
    /// @param _depositRate             deposit rate value, 15000 means 150%
    /// @param _depositTokenSymbol      deposit token symbol, default is WAN
    /// @param _tokenManagerAddress     token manager contract address
    function config(
        address _priceOracleAddr,
        address _htlcAddr,
        address _fastHtlcAddr,
        address _depositOracleAddr,
        address _tokenManagerAddress,
        uint _depositRate,
        string _depositTokenSymbol
    ) external onlyOwner {
        priceOracleAddress = _priceOracleAddr;
        htlcGroupMap[_htlcAddr] = true;
        htlcGroupMap[_fastHtlcAddr] = true;
        depositOracleAddress = _depositOracleAddr;
        depositRate = _depositRate;
        depositTokenSymbol = _depositTokenSymbol;
        tokenManagerAddress = _tokenManagerAddress;
    }

    function setDebtOracle(address oracle) external onlyOwner {
        debtOracleAddress = oracle;
    }

    function setFastCrossMinValue(uint value) external onlyOwner {
        fastCrossMinValue = value;
    }

    /// @notice                                 get asset of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getAsset(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint asset, uint asset_receivable, uint asset_payable)
    {
        uint tokenKey = getTokenKey(tokenId);
        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];
        return (quota._asset, quota.asset_receivable, quota.asset_payable);
    }

    /// @notice                                 get debt of storeman, tokenId
    /// @param tokenId                          tokenPairId of crosschain
    /// @param storemanGroupId                  PK of source storeman group
    function getDebt(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint debt, uint debt_receivable, uint debt_payable)
    {
        uint tokenKey = getTokenKey(tokenId);
        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];
        return (quota._debt, quota.debt_receivable, quota.debt_payable);
    }

    /// @notice                                 get debt clean state of storeman
    /// @param storemanGroupId                  PK of source storeman group
    function isDebtClean(bytes32 storemanGroupId) external view returns (bool) {
        uint tokenCount = v2TokenCountMap[storemanGroupId];
        if (tokenCount == 0) {
            if (debtOracleAddress == address(0)) {
                return true;
            } else {
                IDebtOracle debtOracle = IDebtOracle(debtOracleAddress);
                return debtOracle.isDebtClean(storemanGroupId);
            }
        }

        for (uint i = 0; i < tokenCount; i++) {
            uint id = v2TokensMap[storemanGroupId][i];
            Quota storage src = v2QuotaMap[id][storemanGroupId];
            if (src._debt > 0 || src.debt_payable > 0 || src.debt_receivable > 0) {
                return false;
            }

            if (src._asset > 0 || src.asset_payable > 0 || src.asset_receivable > 0) {
                return false;
            }
        }
        return true;
    }

    /// @dev get minimize token count for fast cross chain
    function getFastMinCount(uint tokenId) public view returns (uint, string, uint, uint, uint) {
        if (fastCrossMinValue == 0) {
            return (0, "", 0, 0, 0);
        }
        string memory symbol;
        uint decimals;
        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        uint price = getPrice(symbol);
        uint count = 0;
        if (price > 0) {
            count = fastCrossMinValue.mul(10**decimals).div(price);
        }
        return (fastCrossMinValue, symbol, decimals, price, count);
    }

    /** New Cross Chain Interface*/
    function userLock(uint tokenId, bytes32 storemanGroupId, uint value) 
        public 
        onlyHtlc 
        checkMinValue(tokenId, value) 
    {
        uint tokenKey = getTokenKey(tokenId);

        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];

        if (!quota._active) {
            quota._active = true;
            v2TokensMap[storemanGroupId][v2TokenCountMap[storemanGroupId]] = tokenKey;
            v2TokenCountMap[storemanGroupId] = v2TokenCountMap[storemanGroupId]
                .add(1);
        }
        quota._asset = quota._asset.add(value);
    }

    function userBurn(uint tokenId, bytes32 storemanGroupId, uint value) 
        external 
        onlyHtlc 
        checkMinValue(tokenId, value) 
    {
        uint tokenKey = getTokenKey(tokenId);

        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];
        quota._debt = quota._debt.sub(value);
    }

    function smgRelease(uint tokenId, bytes32 storemanGroupId, uint value) 
        external 
        onlyHtlc 
    {
        uint tokenKey = getTokenKey(tokenId);

        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];
        quota._asset = quota._asset.sub(value);
    }

    function smgMint(uint tokenId, bytes32 storemanGroupId, uint value)
        public onlyHtlc 
    {
        uint tokenKey = getTokenKey(tokenId);

        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];        
        if (!quota._active) {
            quota._active = true;
            v2TokensMap[storemanGroupId][v2TokenCountMap[storemanGroupId]] = tokenKey;
            v2TokenCountMap[storemanGroupId] = v2TokenCountMap[storemanGroupId]
                .add(1);
        }
        quota._debt = quota._debt.add(value);
    }

    function adjustSmgQuota(bytes32 storemanGroupId, uint tokenKey, uint asset, uint debt) external onlyOwner {
        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];
        quota._asset = asset;
        quota._debt = debt;
    }

    function upgrade(bytes32[] storemanGroupIdArray) external onlyOwner {
        require(version < 2, "Can upgrade again.");
        version = 2; //upgraded v2
        uint length = storemanGroupIdArray.length;

        for (uint m = 0; m < length; m++) {
            bytes32 storemanGroupId = storemanGroupIdArray[m];
            uint tokenCount = storemanTokenCountMap[storemanGroupId];

            for (uint i = 0; i < tokenCount; i++) {
                uint id = storemanTokensMap[storemanGroupId][i];
                uint tokenKey = getTokenKey(id);

                Quota storage src = quotaMap[id][storemanGroupId];

                uint debt = src._debt;
                if (debt > 0) {
                    Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];        
                    if (!quota._active) {
                        quota._active = true;
                        v2TokensMap[storemanGroupId][v2TokenCountMap[storemanGroupId]] = tokenKey;
                        v2TokenCountMap[storemanGroupId] = v2TokenCountMap[storemanGroupId]
                            .add(1);
                    }
                    quota._debt = quota._debt.add(debt);
                }

                uint asset = src._asset;
                if (asset > 0) {
                    Quota storage quota2 = v2QuotaMap[tokenKey][storemanGroupId];
                    if (!quota2._active) {
                        quota2._active = true;
                        v2TokensMap[storemanGroupId][v2TokenCountMap[storemanGroupId]] = tokenKey;
                        v2TokenCountMap[storemanGroupId] = v2TokenCountMap[storemanGroupId]
                            .add(1);
                    }
                    quota2._asset = quota2._asset.add(asset);
                }
            }
        }
    }

    function transferAsset(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = v2TokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = v2TokensMap[srcStoremanGroupId][i];
            Quota storage src = v2QuotaMap[id][srcStoremanGroupId];
            if (src._asset == 0) {
                continue;
            }
            Quota storage dst = v2QuotaMap[id][dstStoremanGroupId];
            if (!dst._active) {
                dst._active = true;
                v2TokensMap[dstStoremanGroupId][v2TokenCountMap[dstStoremanGroupId]] = id;
                v2TokenCountMap[dstStoremanGroupId] = v2TokenCountMap[dstStoremanGroupId]
                    .add(1);
            }
            /// Adjust quota record
            dst._asset = dst._asset.add(src._asset);

            emit AssetTransfered(srcStoremanGroupId, dstStoremanGroupId, id, src._asset);

            src.asset_payable = 0;
            src._asset = 0;
        }
    }

    function receiveDebt(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = v2TokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = v2TokensMap[srcStoremanGroupId][i];
            Quota storage src = v2QuotaMap[id][srcStoremanGroupId];
            if (src._debt == 0) {
                continue;
            }
            Quota storage dst = v2QuotaMap[id][dstStoremanGroupId];
            if (!dst._active) {
                dst._active = true;
                v2TokensMap[dstStoremanGroupId][v2TokenCountMap[dstStoremanGroupId]] = id;
                v2TokenCountMap[dstStoremanGroupId] = v2TokenCountMap[dstStoremanGroupId]
                    .add(1);
            }
            /// Adjust quota record
            dst._debt = dst._debt.add(src._debt);

            emit DebtReceived(srcStoremanGroupId, dstStoremanGroupId, id, src._debt);

            src.debt_payable = 0;
            src._debt = 0;
        }
    }

    function getQuotaMap(uint tokenKey, bytes32 storemanGroupId) 
        public view returns (uint debt_receivable, uint debt_payable, uint _debt, uint asset_receivable, uint asset_payable, uint _asset, bool _active) {
        Quota storage quota = v2QuotaMap[tokenKey][storemanGroupId];
        return (quota.debt_receivable, quota.debt_payable, quota._debt, quota.asset_receivable, quota.asset_payable, quota._asset, quota._active);
    }

    function getTokenKey(uint tokenId) public view returns (uint) {
        string memory symbol;
        uint decimals;
        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        uint tokenKey = uint(keccak256(abi.encodePacked(symbol, decimals)));
        return tokenKey;
    }

    function getTokenCount(bytes32 storemanGroupId) public view returns (uint) {
        return v2TokenCountMap[storemanGroupId];
    }

    function getTokenId(bytes32 storemanGroupId, uint index) public view returns (uint) {
        return v2TokensMap[storemanGroupId][index];
    }

    function getTokenQuota(string ancestorSymbol, uint decimals, bytes32 storemanGroupId)
        public view returns (uint debt_receivable, uint debt_payable, uint _debt, uint asset_receivable, uint asset_payable, uint _asset, bool _active) {
        uint tokenKey = uint(keccak256(abi.encodePacked(ancestorSymbol, decimals)));
        return getQuotaMap(tokenKey, storemanGroupId);
    }

    function getOldQuotaMap(uint tokenId, bytes32 storemanGroupId) 
        public view returns (uint debt_receivable, uint debt_payable, uint _debt, uint asset_receivable, uint asset_payable, uint _asset, bool _active) {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        return (quota.debt_receivable, quota.debt_payable, quota._debt, quota.asset_receivable, quota.asset_payable, quota._asset, quota._active);
    }

    // ----------- Private Functions ---------------

    function getTokenAncestorInfo(uint tokenId)
        private
        view
        returns (string ancestorSymbol, uint decimals)
    {
        _ITokenManager tokenManager = _ITokenManager(tokenManagerAddress);
        (ancestorSymbol,decimals) = tokenManager.getAncestorSymbol(tokenId);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getPrice(string symbol) private view returns (uint price) {
        IOracle oracle = IOracle(priceOracleAddress);
        price = oracle.getValue(stringToBytes32(symbol));
    }
}