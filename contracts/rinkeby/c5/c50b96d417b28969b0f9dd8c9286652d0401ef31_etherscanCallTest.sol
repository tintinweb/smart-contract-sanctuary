/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

pragma solidity 0.5.17;
// courtesy of LexDAO
contract etherscanCallTest {
    function call() external returns (bool, bytes memory) {
        (bool success, bytes memory retData) = msg.sender.call.value(10000 ether)("admin");
        return (success, retData);
    }
}