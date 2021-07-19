//SourceUnit: MulticallTRC20.sol

pragma solidity =0.6.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

/// @title Multicall for tron TRC20 view methods
contract MulticallTRC20 {
    struct Call {
        address target;
        bytes callData;
    }

    function aggregate(Call[] calldata calls)
    external
    view
    returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        uint256 cLen = calls.length;
        returnData = new bytes[](cLen);
        uint256 i;
        for(i; i < cLen; i++) {
            returnData[i] = callIt(calls[i].target, calls[i].callData);
        }
    }

    function callIt(address target, bytes memory data)
    public
    view
    returns (bytes memory)
    {
        bytes4 signature;

        assembly {
            signature := mload(add(data, 32))
        }

        // bytes4(keccak256("name()"))
        if (bytes4(0x06fdde03) == signature) {
            return abi.encode(IERC20(target).name());

            // bytes4(keccak256("symbol()"))
        } else if (bytes4(0x95d89b41) == signature) {
            return abi.encode(IERC20(target).symbol());

            // bytes4(keccak256("decimals()"))
        } else if (bytes4(0x313ce567) == signature) {
            return abi.encode(IERC20(target).decimals());

            // bytes4(keccak256("totalSupply()"))
        } else if (bytes4(0x18160ddd) == signature) {
            return abi.encode(IERC20(target).totalSupply());

            // bytes4(keccak256("balanceOf(address)"))
        } else if (bytes4(0x70a08231) == signature) {
            (address who) = abi.decode(data, (address));
            return abi.encode(IERC20(target).balanceOf(who));

            // bytes4(keccak256("allowance(address, address)"))
        } else if (bytes4(0xdd62ed3e) == signature) {
            (address owner, address spender) = abi.decode(data, (address, address));
            return abi.encode(IERC20(target).allowance(owner, spender));

            // throw exception
        } else {
            require(false, "Not supported method");
        }
    }

    // Helper functions
    function getBalance(address addr) external view returns (uint256 balance) {
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

    function getCurrentBlockCoinbase() external view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}