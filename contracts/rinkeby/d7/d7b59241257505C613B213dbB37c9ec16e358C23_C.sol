/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.7.0;



contract C {
    function g(uint a) public pure returns (uint ret) { 
        return a + 10 ;
    }
    
    function test1() public{
        g(1);
    }
    
    function test2() public{
        this.g(2);
    }
    
        function test3() public{
        g(1);
    }
    
        function test4() public{
        g(1);
    }
    
        function test5() public{
        g(1);
    }
    
        function test6() public{
        g(1);
    }

}

// contract D {
//     function test3() public {
//         C c = new C();
//         c.g(3);
//     }
// }