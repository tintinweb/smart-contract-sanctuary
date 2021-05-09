/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

pragma solidity ^0.5.0;
contract DelegateCall {
    function batchApproveClaim(address _e, address[] calldata toAddresses,  uint256[] calldata amounts) external {
        require(toAddresses.length == amounts.length, "Addresses and amounts should have same length");
        for (uint i = 0; i < toAddresses.length; i++) {
            delegateTo(_e, abi.encodeWithSignature("approveClaim(address,uint256)",
                                                            toAddresses[i],
                                                            amounts[i]));
        }
    }
    function delegateTo(address callee, bytes memory data) internal {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
    }
    // function delegatecallApproveClaim(address _e, address toAddress, uint256 amount) internal {
    //     _e.delegatecall(abi.encode(bytes4(keccak256("approveClaim(address, uint256)")), toAddress, amount));
    // }
}