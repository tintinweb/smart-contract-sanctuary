/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

pragma solidity 0.8.6;

// ----------------------------------------------------------------------------
// RECEIVE contract 
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view;
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external;
    function approve(address spender, uint tokens) external;
    function transferFrom(address from, address to, uint tokens) external;
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// RECEIVE USDT  
// ----------------------------------------------------------------------------
contract RECEIVE is Owned {

    event transferIn(address indexed from, uint256 tokens);
    event transferOut(address indexed to, uint256 tokens);
    
    //address USDT_TOKEN_CONTRACT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // Ethereum Mainnet
    address USDT_TOKEN_CONTRACT = 0x516de3a7A567d81737e3a46ec4FF9cFD1fcb0136; // Ethereum Ropsten
    
    function input(uint256 amount) external returns (bool) {
        ERC20Interface(USDT_TOKEN_CONTRACT).transferFrom(msg.sender, address(this), amount);  
        emit transferIn(msg.sender, amount);
        return true;
    }
    
     function output(address payable to, uint256 amount) external onlyOwner returns(bool) {
        ERC20Interface(USDT_TOKEN_CONTRACT).transfer(to, amount);
        emit transferIn(to, amount);
        return true;
    }
}