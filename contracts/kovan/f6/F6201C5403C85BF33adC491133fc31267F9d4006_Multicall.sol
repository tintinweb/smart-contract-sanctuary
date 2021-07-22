/**
 *Submitted for verification at Etherscan.io on 2021-07-22
*/

/**
 *Submitted for verification at BscScan.com on 2020-09-10
*/

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Multicall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    address public owner;
    address public minter;
    address public burner;
    address[] public minters;
    address[] public burners;
    
    mapping(address => bool)public mintUsers;
    mapping(address => bool)public burnUsers;
    
    constructor (address _owner,address _minter,address _burner)public {
        owner = _owner;
        minter = _minter;
        burner = _burner;
    }
    
    function submitMintTransaction(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        require(msg.sender == owner || msg.sender == minter || mintUsers[msg.sender] == true,"no access");
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    function submitBurnTransaction(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        require(msg.sender == owner || msg.sender == burner || burnUsers[msg.sender] == true,"no access");
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);
            returnData[i] = ret;
        }
    }
    
    function updateAddress(address _owner,address _minter,address _burner)public{
        require(msg.sender == owner,"No access");
        owner = _owner;
        minter = _minter;
        burner = _burner;
    }
    
    
     function addMinter(address[] memory _minter)public {
        require(msg.sender == owner || msg.sender == minter ,"Owner and minter");
        for (uint i = 0; i<_minter.length;i++){
            minters.push(_minter[i]);
            mintUsers[_minter[i]] = true;
        }
    }
    
    function addBurner(address[] memory _burner)public {
        require(msg.sender == owner || msg.sender == burner ,"Owner and burner");
        for (uint i = 0; i<_burner.length;i++){
            burners.push(_burner[i]);
            burnUsers[_burner[i]] = true;
        }
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
}