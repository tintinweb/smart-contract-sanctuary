//SourceUnit: MulticallERC20.sol

pragma solidity =0.6.0;
pragma experimental ABIEncoderV2;

interface ICall {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}


contract MulticallERC20 {

    struct NameCall {
        address target;
    }

    function name(NameCall[] calldata calls) external view returns (uint256 blockNumber, string[] memory returnData) {
        blockNumber = block.number;
        uint256 cLen = calls.length;
        returnData = new string[](cLen);

        uint256 i;
        for(i; i < cLen; i++) {
            returnData[i] = ICall(calls[i].target).name();
        }
    }


    struct SymbolCall {
        address target;
    }

    function symbol(SymbolCall[] calldata calls) external view returns (uint256 blockNumber, string[] memory returnData) {
        blockNumber = block.number;
        uint256 cLen = calls.length;
        returnData = new string[](cLen);

        uint256 i;
        for(i; i < cLen; i++) {
            returnData[i] = ICall(calls[i].target).symbol();
        }
    }


    struct DecimalsCall {
        address target;
    }

    function decimals(DecimalsCall[] calldata calls) external view returns (uint256 blockNumber, uint8[] memory returnData) {
        blockNumber = block.number;
        uint256 cLen = calls.length;
        returnData = new uint8[](cLen);

        uint256 i;
        for(i; i < cLen; i++) {
            returnData[i] = ICall(calls[i].target).decimals();
        }
    }


    struct TotalSupplyCall {
        address target;
    }

    function totalSupply(TotalSupplyCall[] calldata calls) external view returns (uint256 blockNumber, uint256[] memory returnData) {
        blockNumber = block.number;
        uint256 cLen = calls.length;
        returnData = new uint256[](cLen);

        uint256 i;
        for(i; i < cLen; i++) {
            returnData[i] = ICall(calls[i].target).totalSupply();
        }
    }

    struct AllowanceCall {
        address target;
        address owner;
        address spender;
    }

    function allowance(AllowanceCall[] calldata calls) external view returns (uint256 blockNumber, uint256[] memory returnData) {
        blockNumber = block.number;
        uint256 cLen = calls.length;
        returnData = new uint256[](cLen);

        uint256 i;
        for(i; i < cLen; i++) {
            returnData[i] = ICall(calls[i].target).allowance(calls[i].owner, calls[i].spender);
        }
    }


    struct BalanceOfCall {
        address target;
        address owner;
    }

    function balanceOf(BalanceOfCall[] calldata calls) external view returns (uint256 blockNumber, uint256[] memory returnData) {
        blockNumber = block.number;
        uint256 cLen = calls.length;
        returnData = new uint256[](cLen);

        uint256 i;
        for(i; i < cLen; i++) {
            returnData[i] = ICall(calls[i].target).balanceOf(calls[i].owner);
        }
    }

    // Helper functions
    function getEthBalance(address addr) external view returns (uint256 balance) {
        balance = addr.balance;
    }
    function getBlockHash(uint256 blockNumber) external view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }
    function getLastBlockHash() external view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }
    function getCurrentBlockTimestamp() external view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }
    function getCurrentBlockDifficulty() external view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }
    function getCurrentBlockGasLimit() external view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }
    function getCurrentBlockCoinbase() external view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}