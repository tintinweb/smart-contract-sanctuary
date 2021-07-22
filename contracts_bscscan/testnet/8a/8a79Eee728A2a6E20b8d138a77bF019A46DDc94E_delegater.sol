/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity 0.8.0;

contract delegater {
    
    function addValuesWithDelegateCall(address _impl) public returns (uint256) {
        (bool success, bytes memory result) = _impl.delegatecall(abi.encodeWithSignature("execute()"));
        return abi.decode(result, (uint256));
    }
}