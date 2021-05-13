/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

contract Test {
using Math for uint256;
      mapping(uint256 => uint256[]) public userAmountsList;
    mapping(uint256 => address[]) public userAddressList;
    mapping(uint256 => uint256) public accountsListLength;
    address[] public t;
    
 
    function test(uint256 _pid,address[] memory _addressList) external 
    {  

        for (uint256 i = 0; i < _addressList.length; i++) {
            address userAddress = _addressList[i];
            userAddressList[_pid].push(userAddress);
            userAmountsList[_pid].push(i);
            t.push(userAddress);
        }
    }
    
    function getList(uint256 _pid) public view returns(address[] memory){
        return (userAddressList[_pid]);
    }
    
}