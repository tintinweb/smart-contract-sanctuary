/**
 *Submitted for verification at hecoinfo.com on 2022-06-11
*/

pragma solidity ^0.6.2;
// SPDX-License-Identifier: MIT

contract bbbb {
    function sub(uint256 a,uint256 b) external pure returns (uint256 c) {
        c = a-b;
    }
}

// interface fgl {
//     function sub(uint256 a,uint256 b) external pure returns (uint256 c);
// }

contract aa {
    event dddd(uint256 a,uint256 b);
    bbbb public balala;
    
    
    constructor () public {
        balala = new bbbb();
    }
    
    function k(uint256 a,uint256 b) external view returns (uint256) {
        try balala.sub(a,b) returns (uint256 m) {
            //emit dddd(a,b);
             return m;
        }catch {
            return 0;
        }
    }
}