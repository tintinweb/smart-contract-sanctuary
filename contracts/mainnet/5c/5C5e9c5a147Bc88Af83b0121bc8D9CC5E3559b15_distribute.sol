/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.5.17;

interface ERC721 {
    function ownerOf(uint256 tokenId) external returns(address);
}

interface ERC20{
   function balanceOf(address _add) external view returns(uint256);
   function transfer(address _to,uint256 _value) external returns (bool success);

}

contract distribute{
    
    address private owner;
    ERC721 LOOT;
    ERC20 LOOTMOON;
    uint256 public claimableAmount = 2000*10**18;
    
    constructor(address _add1, address _add2) public{
        LOOT = ERC721(_add1);
        LOOTMOON = ERC20(_add2);
        owner = msg.sender;
    }
    
    function claim(uint256 tokenId) public {
        address LOOTOwner = LOOT.ownerOf(tokenId);
        require(msg.sender == LOOTOwner);
        LOOTMOON.transfer(msg.sender,claimableAmount);
    }
    
    function withdraw(address _to) external{
        require(msg.sender == owner);
        uint256 withdrwaAmount = LOOTMOON.balanceOf(address(this));
        LOOTMOON.transfer(_to, withdrwaAmount);
    }
    
}