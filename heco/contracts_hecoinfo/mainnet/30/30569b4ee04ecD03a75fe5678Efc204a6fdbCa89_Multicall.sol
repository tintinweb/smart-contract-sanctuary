/**
 *Submitted for verification at hecoinfo.com on 2022-05-11
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
}

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    struct returnItem {
        uint256 decimals;
        string symbol;
        string name;
    }
    
    struct balanceItem {
        address _user;
        uint256 _balance;
        uint256 gas;
        bool isContract;
    }
    
    function massGetBalance(IERC20 _token,address[] memory _addressList) public view returns (returnItem memory tokenInfo,balanceItem[] memory balanceList ){
        tokenInfo.decimals = _token.decimals();
        tokenInfo.symbol = _token.symbol();
        tokenInfo.name = _token.name();
        balanceList = new balanceItem[](_addressList.length);
        for (uint256 i=0;i<_addressList.length;i++) {
            balanceList[i] = balanceItem(_addressList[i],_token.balanceOf(_addressList[i]),_addressList[i].balance,isContract(_addressList[i]));
        }
    }
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
    
    function getCurrentBlock() public view returns (uint256 blockNumber,uint256 timeStamp,uint256 gasLimit) {
        blockNumber = block.number;
        timeStamp = block.timestamp;
        gasLimit = block.gaslimit;
    }
}