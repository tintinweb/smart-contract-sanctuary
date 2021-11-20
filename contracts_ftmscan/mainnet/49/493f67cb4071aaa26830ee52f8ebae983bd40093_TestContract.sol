/**
 *Submitted for verification at FtmScan.com on 2021-11-17
*/

pragma solidity ^0.8.7;
contract TestContract {
    event Test(uint256 reference_code);
    
    function test(uint256 reference_code) public {
        emit Test(reference_code);
    }
}