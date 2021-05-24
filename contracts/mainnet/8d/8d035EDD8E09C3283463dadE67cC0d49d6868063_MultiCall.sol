/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


contract MultiCall {
    
    struct Call {
        address to;
        bytes data;
    }
    
   function multicall(Call[] memory calls) public returns (bytes[] memory results) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);
        }
    }
    
    
    // be careful with calls.length == 0
    function multicallWithGasLimitation(Call[] memory calls, uint256 gasBuffer) public returns (bytes[] memory results, uint256 lastSuccessIndex) {
        results = new bytes[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            (, results[i]) = calls[i].to.call(calls[i].data);
            if (gasleft() < gasBuffer) {
                return (results, i);
            }
        }
        return (results, calls.length - 1);
    }
    
   function multicallWithGas(Call[] memory calls) public returns (bytes[] memory results, uint256[] memory gasUsed) {
        results = new bytes[](calls.length);
        gasUsed = new uint256[](calls.length);
        for (uint i = 0; i < calls.length; i++) {
            uint256 initialGas = gasleft();
            (, results[i]) = calls[i].to.call(calls[i].data);
            gasUsed[i] = initialGas - gasleft();
        }
    }
    
    function gaslimit() external view returns (uint256) {
        return block.gaslimit;
    }
    
    function gasLeft() external view returns (uint256) {
        return gasleft();
    }
}