/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ITOKEN {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

struct item{
    uint256 balance;
    uint8 decimal;
    string name;
}

contract GetBalances {
 
    function balances(address[] calldata users,address[] calldata tokens) external view returns (bytes memory){
        item[] memory _items = new item[](tokens.length*users.length);
        uint count = 0;
        for(uint i = 0;i<users.length;i++){
            for(uint j = 0;j<tokens.length;j++){
                _items[count].balance = ITOKEN(tokens[j]).balanceOf(users[i]);
                _items[count].name = ITOKEN(tokens[j]).name();
                _items[count].decimal = ITOKEN(tokens[j]).decimals();
                count++;
            }
            
        }
        return abi.encode(_items);
    }

}