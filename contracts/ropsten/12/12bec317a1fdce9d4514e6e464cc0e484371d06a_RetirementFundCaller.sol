/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity ^0.8.7;

contract RetirementFundCaller {
    
    fallback() external payable { }
    
    function killit() public {
        selfdestruct(payable(address(0x596EdD9d32FC1997e0FEe5B6618A76F2a353b281)));
    }
}