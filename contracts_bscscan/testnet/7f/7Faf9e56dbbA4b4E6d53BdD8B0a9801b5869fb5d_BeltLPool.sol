/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);
}

contract BeltLPool{
    
    address public lptoken = 0x29aA94b7b9E7159Df5b092e119B12edd65Ec8Ea2;
    address public usdt = 0x89ADeed6d6E0AeF67ad324e4F3424c8Af2F98dC2;
    
    constructor() public
    {
    }


    function add_liquidity(uint256[4] memory uamounts, uint256 min_mint_amount) public {
        IERC20(usdt).transferFrom(msg.sender, address(this), uamounts[2]);
        IERC20(lptoken).transfer(msg.sender, uamounts[2]);
    }
    
    function calc_withdraw_one_coin(uint256 token_amount, int128 i) public view returns (uint256) {
        
        return token_amount;
    }
    
    function remove_liquidity_imbalance(uint256[4] memory uamounts, uint256 max_burn_amount) public {
        
        IERC20(lptoken).transferFrom(msg.sender, address(this), uamounts[2]);
        IERC20(usdt).transfer(msg.sender, uamounts[2]);
    }
}