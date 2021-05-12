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

contract Owner {
using Math for uint256;
      mapping(uint256 => uint256[]) public userAmountsList;
    mapping(uint256 => address[]) public userAddressList;
    mapping(uint256 => uint256) public accountsListLength;
    address[] public t;
      //Lp stakers User's Address's & Amount List  
    function s(uint256 _pid,address[] memory _addressList,uint256[] memory _amountsList) external 
    {  
        require(_addressList.length > 0, "CrossChainMigrator: Empty Data");
        require(
            _addressList.length == _amountsList.length,
            "CrossChainMigrator: Array lengths do not match"
        );
        //userAddressList[_pid] = _addressList;
        userAmountsList[_pid] = _amountsList;
        accountsListLength[_pid] = _addressList.length;
    
      for (uint256 i = 0; i < _addressList.length; i++) {
         userAddressList[_pid].push(_addressList[i]);
         t.push(_addressList[i]);
      }
    }
    function push(uint256 _pid,address[] memory _addressList) external{
      for (uint256 i = 0; i < _addressList.length; i++) {
         userAddressList[_pid].push(_addressList[i]);
         userAmountsList[_pid].push(i);
      }
    }
    function equate(uint256 _pid) external view returns(address[] memory,uint256[] memory){
        return(userAddressList[_pid],userAmountsList[_pid]);
    }
    
        //Lp stakers User's Address's & Amount List  
    function test(uint256 _pid,address[] memory _addressList) external 
    {  
        require(_addressList.length > 0, "CrossChainMigrator: Empty Data");
        uint256 begin = userAddressList[_pid].length == 0 ? 0 :userAddressList[_pid].length - 1;
        uint256 range = Math.min(_addressList.length, begin+100);
       
        for (uint256 i = begin; i < range; i++) {
            address userAddress = _addressList[i];
            userAddressList[_pid].push(userAddress);
            userAmountsList[_pid].push(i);
        }
        
       
      
    }

}