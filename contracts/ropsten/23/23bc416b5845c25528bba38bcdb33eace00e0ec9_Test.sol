/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Test {
    struct Win {
        uint256 s;
        uint256 b;
        address add;
    }
    
    Win[] public a;

    constructor() {
        a.push(Win(12,21, address(this)));
        a.push(Win(13,31,address(this)));
        a.push(Win(14,41,address(this)));
        a.push(Win(15,51,address(0)));
    }

    function getI(uint256 n) external view returns(Win[] memory) {
        n = n > a.length ? a.length : n;
        Win[] memory res = new Win[](n);
        
        for (uint256 i = 0; i< n; i++) {
            res[i] = a[i];
        }
        
        return res;
    }
    
    function getWinI() external view returns(Win[] memory) {
        uint256 n = a.length;
        Win[] memory res = new Win[](n);
        
        for (uint256 i = 0; i< n; i++) {
            res[i] = a[i];
        }
        
        return res;
    }
}