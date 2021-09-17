/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

// File: contracts/external/utils/MultiCall.sol



pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title MultiCall - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>
contract MultiCall {

    struct Call {
        address target;
        bytes callData;
    }

    function _addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.call(calls[i].callData);
            if (!success) {
                if (result.length < 68) {
                    string memory targetString = _addressToString(calls[i].target);
                    revert(string(abi.encodePacked("Multicall::aggregate: revert at <", targetString, ">")));
                } else {
                    assembly {
                        result := add(result, 0x04)
                    }
                    string memory targetString = _addressToString(calls[i].target);
                    revert(string(abi.encodePacked("Multicall::aggregate: revert at <", targetString, "> with reason: ", abi.decode(result, (string)))));
                }
            }
            returnData[i] = result;
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