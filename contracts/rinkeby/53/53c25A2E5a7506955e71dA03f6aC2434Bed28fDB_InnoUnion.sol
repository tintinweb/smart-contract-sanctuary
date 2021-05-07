/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract InnoUnion {
    
    uint256 _total;    
    
    ERC20 erc20;
    
    constructor (address erc20Address) {
        erc20 = ERC20(erc20Address);
    }
    
    function balanceOf() public view returns(uint256) {
        return erc20.balanceOf(msg.sender);
    }
    
    function deposit(uint256 amount) public {
        erc20.transferFrom(msg.sender, address(this), amount);
        _total += amount;
    }
    
    function checkTotal() public view returns(uint256) {
        return _total;
    }
    
    function withdraw(address to) public {
        erc20.transferFrom(address(this), to, _total);
        _total = 0;
    }
}

abstract contract ERC20 {
    function balanceOf(address account) public virtual view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool);
}