// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Ownable.sol';
import './IERC20.sol';
import './SyrupPool.sol';

contract SyrupPoolFactory is Ownable {
    address[] public Pools;

    event OnDeploySyrupPool(address indexed syrupPool);

    function deployPool(
        address stakedToken,
        address rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser,
        address admin) external onlyOwner {

        require(_startBlock < _bonusEndBlock, "startBlock must be lower than new endBlock");
        
        require(block.number < _startBlock, "startBlock must be higher than current block");

        IERC20 _stakedToken = IERC20(stakedToken);

        IERC20 _rewardToken = IERC20(rewardToken);

        bytes memory bytecode = type(SyrupPool).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _rewardToken, _startBlock));

        address syrupPoolAddress;

        assembly {
            syrupPoolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        SyrupPool(syrupPoolAddress).initialize(
            _stakedToken,

            _rewardToken,

            _rewardPerBlock,

            _startBlock,

            _bonusEndBlock,

            _poolLimitPerUser,

            admin
        );

        emit OnDeploySyrupPool(syrupPoolAddress);

        Pools.push(syrupPoolAddress);
    }
}