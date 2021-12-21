// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyPool {
    mapping(uint256 => uint256) public pools;

    mapping(address => mapping(uint256 => uint256)) public stakes;

    // stake something into a pool
    function stake(uint256 _poolId) public payable returns (uint256) {
        pools[_poolId] += msg.value;
        stakes[msg.sender][_poolId] += msg.value;
        return msg.value;
    }

    // get a staked amount for a member in a pool
    function getBalance(address _owner, uint256 _poolId)
        public
        view
        returns (uint256)
    {
        return stakes[_owner][_poolId];
    }
}