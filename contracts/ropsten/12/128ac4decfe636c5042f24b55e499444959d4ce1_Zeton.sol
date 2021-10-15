/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity 0.8.7;

contract Zeton {
    
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    constructor() {
    
        _mint(msg.sender, 1e18);
        
    }
    
    
    function _mint(address to, uint256 amount) internal {
        balanceOf[to] = amount;
        totalSupply += amount;
    }
    
    function transfer(address recipient, uint256 amount) public {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
    }
    
}