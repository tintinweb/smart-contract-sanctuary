/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract TestImp1  {
    uint8       public      u8Test;
    uint256     public      u256Test;
    address     public      addrTest;

    function setU8(uint8 _u8Test) public {
        u8Test = _u8Test;
    }

     function setU256(uint256 _u256Test) public {
        u256Test = _u256Test;
    }
    
    function setAddress(address _addrTest) public {
        addrTest = _addrTest;
    }

    receive() external payable {
    }
   
    function destroy(address payable to) public {
        selfdestruct(to);
    }
}