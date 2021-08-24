/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/*
INTERFACE PADRAO ERC20
*/
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event TransferFrom(address indexed from, address indexed to, uint256 value);
}


contract TokenSwap {
    IERC20 public token1;
    address public owner1;
    uint public amount1;
    IERC20 public token2;
    address public owner2;
    uint public amount2;

    constructor(
       
    ) {
        token1 = IERC20(0xcBBd1276C8da917599c3548d09BcEC7A66AB8F61); //SMART CONTRACT MST
        owner1 = 0x7DF9dC8FE80A40BE8caC77c56e76fEac25Fe8923; //ADDRESS BIG OWNER
       
        token2 = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174); //SMART CONTRACT USDT
    }

    function buyMST(uint256 amount_usdt) public {
        amount1 = 10000 * amount_usdt;
        amount2 = amount_usdt;
        
        // require(msg.sender == owner1 || msg.sender == owner2, "Not authorized");
        require(
            token1.allowance(owner1, address(this)) >= amount1,
            "Token 1 allowance too low"
        );
        require(
            token2.allowance(msg.sender, address(this)) >= amount2,
            "Token 2 allowance too low"
        );

        _safeTransferFrom(token1, owner1,  msg.sender, amount1);
        _safeTransferFrom(token2,  msg.sender, owner1, amount2);
    }
    
    

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }
}