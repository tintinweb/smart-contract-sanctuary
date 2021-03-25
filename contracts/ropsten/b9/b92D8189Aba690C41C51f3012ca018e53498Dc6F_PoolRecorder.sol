// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./PoolFactory.sol";

contract PoolRecorder {
    struct Pool {
        string name;
        string description;
        address owner;
        address PoolAddress;
        bool visible;
    }

    address[] poolList;
    mapping(address => Pool) public poolRecorded;

    event PoolAdded(address poolAddress);

    function createPool(
        string memory _name,
        string memory _description,
        bool _visible,
        address _owner
    ) public returns (address) {
        PoolFactory newPoolBank = new PoolFactory(true, _owner);
        addPool(
            address(newPoolBank),
            msg.sender,
            _name,
            _description,
            _visible
        );
        return address(newPoolBank);
    }

    function addPool(
        address poolAddress,
        address _owner,
        string memory _name,
        string memory _description,
        bool _visible
    ) private {
        poolList.push(poolAddress);
        poolRecorded[poolAddress] = Pool(
            _name,
            _description,
            _owner,
            poolAddress,
            _visible
        );
        emit PoolAdded(poolAddress);
    }

    function removePool(address poolAddress) public {
        for (uint256 index = 0; index < poolList.length; index++) {
            if (poolList[index] == poolAddress) {
                poolList[index] = poolList[poolList.length - 1];
                delete poolList[poolList.length - 1];
                break;
            }
        }
    }

    function getListPools() public view returns (address[] memory) {
        return poolList;
    }

    function getPoolInfo(address poolAddress)
        public
        view
        returns (Pool memory)
    {
        return poolRecorded[poolAddress];
    }
}