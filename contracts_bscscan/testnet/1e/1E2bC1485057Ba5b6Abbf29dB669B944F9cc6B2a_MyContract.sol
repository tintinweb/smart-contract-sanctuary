/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

pragma solidity ^0.8;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MyContract {

    // this function can accept BNB
    // the accepted amount is in the `msg.value` global variable
    function foo() external payable {
        IERC20 tokenContract = IERC20(address(0x456));
        // sending 1 smallest unit of the token to the user executing the `foo()` function
        tokenContract.transfer(msg.sender, 1);
    }
}