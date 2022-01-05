// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract Util {

    function getParam(
        address _uniFactory,
        address _poolAddress,
        address _config,
        address _nftManager,
        address _operator,
        address _swapPool,
        uint8 _performanceFee,
        uint24 _diffTick)
    external pure returns(bytes memory param){
        bytes4 methodId = bytes4(keccak256("initialize(address,address,address,address,address,address,uint8,uint24)"));
        param = abi.encodeWithSelector(methodId, _uniFactory, _poolAddress, _config, _nftManager, _operator, _swapPool, _performanceFee, _diffTick);
    }


    function getParam2(
        address _uniFactory,
        address _poolAddress,
        address _config,
        address _nftManager,
        address _operator,
        address _swapPool,
        uint8 _performanceFee,
        uint24 _diffTick)
    external pure returns(bytes memory param){
        param = abi.encodeWithSignature("initialize(address,address,address,address,address,address,uint8,uint24)", _uniFactory, _poolAddress, _config, _nftManager, _operator, _swapPool, _performanceFee, _diffTick);
    }

    function getUpgradeParam(address _vaultAddress) external pure returns(bytes memory param){
        bytes4 methodId = bytes4(keccak256("upgrade(address)"));
        param = abi.encodeWithSelector(methodId, _vaultAddress);
    }

    function getSenderAddress() external view returns(address){
        return msg.sender;
    }
}