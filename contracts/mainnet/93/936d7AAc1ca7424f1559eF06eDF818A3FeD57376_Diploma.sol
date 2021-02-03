/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity >=0.4.22 <0.7.0;

//SPDX-License-Identifier: UNLICENSED

//Casey Zduniak's Diploma checksum

contract Diploma {

    // valid md5 hash
    bytes16 ipft_hash = 0x845e9f56005bc7a0240113314ccf257a;

    function validate(bytes16 num) public view returns (bool){
        if (num == ipft_hash) {
            return true;
        }
        else {
            return false;
        }
    }

}