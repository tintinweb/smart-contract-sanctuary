/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// File: localhost/mint/tripartitePlatform/publics/ILoanTypeBase.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

interface ILoanTypeBase {
    
    enum LoanType {
        NORMAL,
        MARGIN_SWAP_PROTOCOL,
        MINNING_SWAP_PROTOCOL
    }
    
    function checkBorrowCode(uint256 code) external pure;
    
    function checkRepayCode(uint256 code) external pure;

}
// File: localhost/mint/tripartitePlatform/publics/LoanTypeBase.sol

 

pragma solidity 0.7.4;


contract LoanTypeBase is ILoanTypeBase {
    
    function checkBorrowCode(uint256 code) override external pure {
        // require(true);
        // revert();
        assembly {
        //     switch code
        //     case 0 {
        //         return
        //     }
        //     case 1 {
            
        //     }
        //     default {
                
        //     }
            revert(0, code)

        }
    }
    
    function checkRepayCode(uint256 code) override external pure {
    }
    
    function a() external pure {
        revert();
    }
    
    function b() external pure {
        revert("b");
    }
    
    function c() external pure {
        assembly {
            revert(0, "b")
        }
    }
    
    function d() external pure {
        assembly {
            revert(1, "b")
        }
    }
    
    function e(uint256 code) external pure {
        assembly {
            revert(0, code)
        }
    }
    
    function f(uint256 ee, uint256 code) external pure {
        assembly {
            revert(ee, code)
        }
    }
    
}