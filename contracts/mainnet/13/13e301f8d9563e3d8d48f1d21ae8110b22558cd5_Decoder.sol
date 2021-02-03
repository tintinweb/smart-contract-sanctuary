/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Decoder {
    
    bytes32 public constant DEPOSIT = keccak256("DEPOSIT");
    bytes32 public constant MAP_TOKEN = keccak256("MAP_TOKEN");
    
    enum SyncType {Deposit, TokenMapping, Unsupported}
    
    function getSyncTypeAndData(bytes memory data) internal pure returns(bytes32, bytes memory) {
        (bytes32 syncType, bytes memory syncData) = abi.decode(data, (bytes32, bytes));
        
        return (syncType, syncData);
    }
    
    function decodeStateSyncData(bytes calldata data) external pure returns (SyncType, address, address, bytes memory){
        (bytes32 syncType, bytes memory syncData) = getSyncTypeAndData(data);
        
        if (syncType == MAP_TOKEN) {
            (address root, address child, ) = abi.decode(syncData, (address, address, bytes32));
            
            return (SyncType.TokenMapping, root, child, "");
        }
        
        if (syncType == DEPOSIT) {
            (address depositor, address root, bytes memory depositData) = abi.decode(syncData, (address, address, bytes));
            
            return (SyncType.Deposit, depositor, root, depositData);
        }
        
        return (SyncType.Unsupported, address(0), address(0), "");
    }
    
    function decodeERC20Deposit(bytes calldata depositData) external pure returns(uint256) {
        return abi.decode(depositData, (uint256));
    }
    
    function decodeERC721SingleDeposit(bytes calldata depositData) external pure returns(uint256) {
        return abi.decode(depositData, (uint256));
    }
    
    function decodeERC721BatchDeposit(bytes calldata depositData) external pure returns(uint256[] memory) {
        return abi.decode(depositData, (uint256[]));
    }
    
    function decodeERC1155BatchDeposit(bytes calldata depositData) external pure returns(uint256[] memory, uint256[] memory, bytes memory) {
        return abi.decode(depositData, (uint256[], uint256[], bytes));
    }
}