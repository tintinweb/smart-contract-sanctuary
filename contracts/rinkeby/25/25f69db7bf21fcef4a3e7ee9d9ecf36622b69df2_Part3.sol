/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

contract Part3 {
    
    string constant pt3 = "a5cbcb68d52074a691a041bac7855a5205e68b355bf487bab57ba4c295edf7085f8562c95660696055bc47a60dbd9cd4a1b49938237e101a64e93043de5c4343a4c4432ccbf391903e9d2cb98f4e30d5b2ed5d0fdd03675473d09a89b6e923a29a8dc0f35fa78caec9b2162a90eceaed0546dd9240e2d5a55379a1cbc8864078308";
    string public ptx = "x";
    
    function rrr() external pure returns(string memory) {
        bytes memory str = bytes(pt3);
        string memory tmp = new string(str.length);
        bytes memory _reverse = bytes(tmp);

        for(uint i = 0; i < str.length; i++) {
            _reverse[str.length - i - 1] = str[i];
        }
        return string(_reverse);
    }
    

}