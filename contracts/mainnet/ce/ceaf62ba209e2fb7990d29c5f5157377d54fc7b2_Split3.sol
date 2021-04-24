/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

pragma solidity ^0.5.16;

contract ERC20Like {
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);    
}


contract Split3 {
    address constant ONE = address(0x8180a5CA4E3B94045e05A9313777955f7518D757);
    address constant TWO = address(0x143395428158A57d17Bcd8899770460656De98E4);
    address constant THREE = address(0xffF96a443aB8e8eFF4621c1Aa02Bbd90aD39DA57);
    
    // callable by anyone
    function drip(address source, ERC20Like token, uint qty) external {
        require(token.transferFrom(source, ONE, qty / 3), "ONE-failed");
        require(token.transferFrom(source, TWO, qty / 3), "TWO-failed");
        require(token.transferFrom(source, THREE, qty / 3), "THREE-failed");        
    }
    
}