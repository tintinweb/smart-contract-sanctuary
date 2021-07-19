/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract EncodeTest {
    
    function encodeData(address _address, uint256 _chainId, uint256 _walletIndex) public pure returns (bytes memory){
        return abi.encodeWithSelector(0x8c016a00, _address, _chainId, _walletIndex); 
    }

    function encodeStringData(string memory _string) public pure returns (bytes memory){
        return abi.encode(_string); 
    }
}