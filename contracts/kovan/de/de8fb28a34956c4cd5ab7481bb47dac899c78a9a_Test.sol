/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity >=0.8.2;

contract Test {
    uint256 nonce = 0;
    
    function increment() external returns (uint256) {
        nonce = nonce + 1;
        
        return nonce;
    }
    
    function getNonceIncrementedBy(uint256 increment) view external returns(uint256) {
        return nonce + increment;
    }
}