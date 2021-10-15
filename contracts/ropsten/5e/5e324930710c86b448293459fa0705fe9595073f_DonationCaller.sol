/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

pragma solidity ^0.8.7;

contract DonationCaller {
    
    address callee = 0xDfE09AE31472AA9326F9A59Af6B0fb92ee1882d2;
    
    fallback() external payable { }
    
    function call(uint etherAmount) public {
        callee.call(abi.encodeWithSignature("donate(uint256)", etherAmount));
    }
    
    function kill() public {
        selfdestruct(payable(0xe7645fEd11A77A340C1161791bB984cE2E298273));
    }
}