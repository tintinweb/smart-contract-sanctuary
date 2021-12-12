// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "../interfaces/IOwnable.sol";

contract NFTbIDStorage {
    address public bridgeContract;
    mapping(uint256 => uint256) bscToRealIDERC721;
    mapping(uint256 => uint256) bscToRealIDERC1155;

    modifier onlyBridge() {
        require(msg.sender == bridgeContract, "can be called only by bridge contract");
        _;
    }

    modifier onlyBridgeOwner() {
        require(msg.sender == bridgeContract || msg.sender == IOwnable(bridgeContract).owner(),  "can be called only by bridge contract or bridge contract owner");
        _;
    }

    constructor(address _bridgeContract) {
        bridgeContract = _bridgeContract;
    }

    function recordIDERC721(uint256 bscID, uint256 realID)
    external
    onlyBridge
    {
        if (bscToRealIDERC721[bscID] == 0){
            bscToRealIDERC721[bscID] = realID;
        }
    }

    function recordIDERC1155(uint256 bscID, uint256 realID)
    external
    onlyBridge
    {
        if (bscToRealIDERC1155[bscID] == 0){
            bscToRealIDERC1155[bscID] = realID;
        }
    }

    function getRealIDERC721(uint256 bscID)
    external
    view
    returns (uint256)
    {
        if (bscToRealIDERC721[bscID] == 0){
            return bscID;
        }

        return bscToRealIDERC721[bscID];
    }

    function getRealIDERC1155(uint256 bscID)
    external
    view
    returns (uint256)
    {
        if (bscToRealIDERC1155[bscID] == 0){
            return bscID;
        }

        return bscToRealIDERC1155[bscID];
    }

    function setBridgeContract(address _bridgeContract)
    external
    onlyBridgeOwner {
        require(_bridgeContract != address(0));
        bridgeContract = _bridgeContract;
    }
}

pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);
}