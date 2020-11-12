/*

 Copyright 2018-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

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

pragma solidity 0.6.6;

/// @title Pool Interface - Interface of pool standard functions.
/// @author Gabriele Rigo - <gab@rigoblock.com>
/// @notice only public view functions are used
interface IPool {
    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    function balanceOf(address _who) external view returns (uint256);
    function totalSupply() external view returns (uint256 totaSupply);
    function getEventful() external view returns (address);
    function getData() external view returns (string memory name, string memory symbol, uint256 sellPrice, uint256 buyPrice);
    function calcSharePrice() external view returns (uint256);
    function getAdminData() external view returns (address, address feeCollector, address dragodAO, uint256 ratio, uint256 transactionFee, uint32 minPeriod);
}

/// @title Drago Registry Interface - Allows external interaction with Drago Registry.
/// @author Gabriele Rigo - <gab@rigoblock.com>
// solhint-disable-next-line
interface IDragoRegistry {

    /*
     * CORE FUNCTIONS
     */
    function register(address _drago, string calldata _name, string calldata _symbol, uint256 _dragoId, address _owner) external payable returns (bool);
    function unregister(uint256 _id) external;
    function setMeta(uint256 _id, bytes32 _key, bytes32 _value) external;
    function addGroup(address _group) external;
    function setFee(uint256 _fee) external;
    function updateOwner(uint256 _id) external;
    function updateOwners(uint256[] calldata _id) external;
    function upgrade(address _newAddress) external payable; //payable as there is a transfer of value, otherwise opcode might throw an error
    function setUpgraded(uint256 _version) external;
    function drain() external;

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    function dragoCount() external view returns (uint256);
    function fromId(uint256 _id) external view returns (address drago, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromAddress(address _drago) external view returns (uint256 id, string memory name, string memory symbol, uint256 dragoId, address owner, address group);
    function fromName(string calldata _name) external view returns (uint256 id, address drago, string memory symbol, uint256 dragoId, address owner, address group);
    function getNameFromAddress(address _pool) external view returns (string memory);
    function getSymbolFromAddress(address _pool) external view returns (string memory);
    function meta(uint256 _id, bytes32 _key) external view returns (bytes32);
    function getGroups() external view returns (address[] memory);
    function getFee() external view returns (uint256);
}

/// @title Network - Returns data of active pools and network value.
/// @author Gabriele Rigo - <gab@rigoblock.com>
contract Network {

    address public DRAGOREGISTRYADDRESS;

    constructor(
        address dragoRegistryAddress)
        public
    {
        DRAGOREGISTRYADDRESS = dragoRegistryAddress;
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Returns two arrays of prices and total supply
    /// @return poolAddresses Array of addressed of the active pools
    /// @return poolPrices Array of the prices of the active pools
    /// @return totalTokens Array of the number of tokens of each pool
    function getPoolsPrices()
        external view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 length = IDragoRegistry(DRAGOREGISTRYADDRESS).dragoCount();
        address[] memory poolAddresses = new address[](length);
        uint256[] memory poolPrices = new uint256[](length);
        uint256[] memory totalTokens = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            bool active = isActive(i);
            if (!active) {
                continue;
            }
            (poolAddresses[i], ) = addressFromId(i);
            IPool poolInstance = IPool(poolAddresses[i]);
            poolPrices[i] = poolInstance.calcSharePrice();
            totalTokens[i] = poolInstance.totalSupply();
        }
        return (
            poolAddresses,
            poolPrices,
            totalTokens
        );
    }

    /// @dev Returns the value of the assets in the rigoblock network
    /// @return networkValue alue of the rigoblock network in wei
    /// @return numberOfPools Number of active funds
    function calcNetworkValue()
        external view
        returns (
            uint256 networkValue,
            uint256 numberOfPools
        )
    {
        numberOfPools = IDragoRegistry(DRAGOREGISTRYADDRESS).dragoCount();
        for (uint256 i = 0; i < numberOfPools; ++i) {
            bool active = isActive(i);
            if (!active) {
                continue;
            }
            (uint256 poolValue, ) = calcPoolValue(i);
            networkValue += poolValue;
        }
    }
    
    /// @dev Returns the value of the assets in the rigoblock network given a mock input
    /// @param mockInput Random number, must be 1 for querying data
    /// @return networkValue Value of the rigoblock network in wei
    /// @return numberOfPools Number of active funds
    function calcNetworkValueDuneAnalytics(uint256 mockInput)
        external view
        returns (
            uint256 networkValue,
            uint256 numberOfPools
        )
    {
        if(mockInput > uint256(1)) {
            return (uint256(0), uint256(0));
        }
        numberOfPools = IDragoRegistry(DRAGOREGISTRYADDRESS).dragoCount();
        for (uint256 i = 0; i < numberOfPools; ++i) {
            bool active = isActive(i);
            if (!active) {
                continue;
            }
            (uint256 poolValue, ) = calcPoolValue(i);
            networkValue += poolValue;
        }
    }


    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev Checks whether a pool is registered and active
    /// @param poolId Id of the pool
    /// @return Bool the pool is active
    function isActive(uint256 poolId)
        internal view
        returns (bool)
    {
        (address poolAddress, , , , , ) = IDragoRegistry(DRAGOREGISTRYADDRESS).fromId(poolId);
        if (poolAddress != address(0)) {
            return true;
        }
    }

    /// @dev Returns the address and the group of a pool from its id
    /// @param poolId Id of the pool
    /// @return poolAddress Address of the target pool
    /// @return groupAddress Address of the pool's group
    function addressFromId(uint256 poolId)
        internal view
        returns (
            address poolAddress,
            address groupAddress
        )
    {
        (poolAddress, , , , , groupAddress) = IDragoRegistry(DRAGOREGISTRYADDRESS).fromId(poolId);
    }

    /// @dev Returns the price a pool from its id
    /// @param poolId Id of the pool
    /// @return poolPrice Price of the pool in wei
    /// @return totalTokens Number of tokens of a pool (totalSupply)
    function getPoolPrice(uint256 poolId)
        internal view
        returns (
            uint256 poolPrice,
            uint256 totalTokens
        )
    {
        (address poolAddress, ) = addressFromId(poolId);
        IPool poolInstance = IPool(poolAddress);
        poolPrice = poolInstance.calcSharePrice();
        totalTokens = poolInstance.totalSupply();
    }

    /// @dev Returns the address and the group of a pool from its id
    /// @param poolId Id of the pool
    /// @return aum Address of the target pool
    /// @return success Address of the pool's group
    function calcPoolValue(uint256 poolId)
        internal view
        returns (
            uint256 aum,
            bool success
        )
    {
        (uint256 price, uint256 supply) = getPoolPrice(poolId);
        return (
            aum = (price * supply / 1000000), //1000000 is the base (6 decimals)
            success = true
        );
    }
}