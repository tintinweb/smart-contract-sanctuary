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
    
    function c2(uint256 code) external {
        v++;
        assembly {
            revert(code, code)
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
    
    function g(uint256 code) external {
        v++;
        assembly {
            revert(1, code)
        }
    }
    
    function g1(uint256 code) external {
        revert(toBytesNickJohnson(code));
    }
    
    function g2(uint256 code) external {
        if (0 != code) {
            revert(toBytesNickJohnson(code));
        }
    }
    
    string public aaaa = "aaa";
    
    function toBytesNickJohnson(uint256 x) public returns (string memory) {
        bytes memory vvb = new bytes(32);
        assembly { mstore(add(vvb, 32), x) }
        aaaa = string(vvb);
        return aaaa;
    }
    
    function toBytes(uint256 x) public pure returns (bytes memory bbbb) {
        bbbb = new bytes(32);
        assembly { mstore(add(bbbb, 32), x) }
    }
    
    function toBytes22(uint256 x) public pure returns (string memory) {
        bytes memory bbbb = new bytes(32);
        assembly { mstore(add(bbbb, 32), x) }
        return string(bbbb);
    }
    
    function toBytes222(uint256 x) external {
        aaaa = string(toBytes(x));
    }
    
}