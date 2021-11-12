/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// File: contracts/tokenHolder.sol



pragma solidity ^0.8.0;

abstract contract ERC20 {
    function balanceOf(address tokenOwner) public virtual returns (uint256);
    function transfer(address to, uint256 tokens) public virtual returns (bool);
}

contract tokenHolder {
    address token_address = 0x4900b035E63EBeD9c2dc8aF29FD0Cff4644Fb057;
    address owner_address = 0xebfA3E2a81fDa622D8BE75D24f1944d154168C2d;
    uint256 stamp = 1636722025;
  
    function returnTokens() public {
        require(block.timestamp >= stamp, "...");
        uint256 amount = ERC20(token_address).balanceOf(address(this));
        ERC20(token_address).transfer(owner_address, amount);
    }
    function getStamp() public view returns(uint256) {
        return block.timestamp;
    }
    function changeStamp(uint256 st) public {
        stamp = st;
    }
}