// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Test {
       
        address[3][] public tokenPath;
        uint256[2][] public tokenAmount;
        
       
         
    function multiArray(address[] memory arr, uint256[] memory amt) external returns (address[3][] memory path, uint256[2][] memory amount) {
        
       
        
        for(uint256 i = 0 ; i < (arr.length / 3) ; i++){
            for(uint256 j = 0 ; j < 3 ; j++){
        tokenPath[i][j] = arr[i * 3 + j];
      }
    }
        for(uint256 i = 0 ; i < (amt.length / 2) ; i++){
            for(uint256 j = 0 ; j < 2 ; j++){
        tokenAmount[i][j] = amt[i * 2 + j];
      }
    }
    
    return (tokenPath, tokenAmount);
    }
    
}