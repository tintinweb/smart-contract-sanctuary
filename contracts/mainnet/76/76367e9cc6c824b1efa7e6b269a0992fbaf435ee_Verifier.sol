/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.0;

contract Verifier {
    function verifyWithdrawSignature(
        address _trader,
        bytes calldata _signature
    ) external returns (bool) {
        return true;
    }
}