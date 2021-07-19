//SourceUnit: LpBalance.sol

// SPDX-License-Identifier: UNLICENSED
/*
https://everin.one/
*/
pragma solidity >=0.5.8 <=0.5.14;



interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LpBalance{
    ITRC20 public lpEverToken;
    constructor(
        address _lpEverToken
    ) public {
        lpEverToken = ITRC20(_lpEverToken);
    }

    function getBalance(address user) external view returns (uint256) {
        return lpEverToken.balanceOf(user);
    }

}