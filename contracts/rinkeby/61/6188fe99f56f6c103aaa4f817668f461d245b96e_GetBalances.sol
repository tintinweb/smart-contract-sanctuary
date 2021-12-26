/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract GetBalances {
 
    function balances(address[] calldata users,address[] calldata tokens) external view returns (bytes memory){
        uint256[] memory _balances = new uint256[](tokens.length*users.length);
        uint count = 0;
        for(uint i = 0;i<users.length;i++){
            for(uint j = 0;j<tokens.length;j++){
                _balances[count] = IERC20(tokens[j]).balanceOf(users[i]);
                count++;
            }
            
        }
        return abi.encodePacked(_balances);
    }

}