/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

// import "./ILoanTypeBase.sol";

contract LoanTypeBase {//is ILoanTypeBase {
    
    // function checkBorrowCode(uint256 code) override external pure {
    //     // require(true);
    //     // revert();
    //     assembly {
    //     //     switch code
    //     //     case 0 {
    //     //         return
    //     //     }
    //     //     case 1 {
            
    //     //     }
    //     //     default {
                
    //     //     }
    //         revert(0, code)

    //     }
    // }
    
    // function checkRepayCode(uint256 code) override external pure {
    // }
    
    uint256 public v = 0;
    
    function a() external {
        v++;
        revert();
    }
    
    function b() external {
        v++;
        revert("b");
    }
    
    function c() external {
        v++;
        assembly {
            revert(0, "b")
        }
    }
    
    function d() external {
        v++;
        assembly {
            revert(1, "b")
        }
    }
    
    function e(uint256 code) external {
        v++;
        assembly {
            revert(0, code)
        }
    }
    
    function f(uint256 ee, uint256 code) external {
        v++;
        assembly {
            revert(ee, code)
        }
    }
    
    
}