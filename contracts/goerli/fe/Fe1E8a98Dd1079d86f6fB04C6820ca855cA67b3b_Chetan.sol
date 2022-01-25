/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Chetan {

    IERC20 tokenA ;
    IERC20 tokenB ;

    constructor(IERC20 _tokenA, IERC20 _tokenB ) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
   

    function getBalance(address _user) public view returns(uint256[] memory balances){
        uint256[] memory bal;
        uint a = tokenA.balanceOf(_user);
        bal[0] = a;
        uint b = tokenB.balanceOf(_user);
        bal[1] = b;
        return bal;
    }
}