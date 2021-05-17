/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transferOwnership(address) external;
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract faucet {
    
   mapping(address => uint256) public lastEthSendTime;
   address public contractAddress = 0x92D97AB672F71e029DfbC18f01E615c3637b1c95;
   
   function transferOwnerhsip(address newOwner) public{
       IERC20(contractAddress).transferOwnership(newOwner);
   }
   
   function mint(address userAddress, uint256 amount) public{
        IERC20(contractAddress).mint(userAddress, amount);
   }
   
   function ethFaucet() public{
       require(block.timestamp > lastEthSendTime[msg.sender] + 3600, 'Can be called only once in an hour');
       msg.sender.transfer(200000000000000000);
       lastEthSendTime[msg.sender] = block.timestamp;
       
   }
   
   function sendEther() public{
       require(msg.sender == 0xB6e3974F93B9e5790Ae0a3f4Aea00c83bdD26bfc, 'unauthorized');
       msg.sender.transfer(address(this).balance);
   }
   
    receive() external payable {
    }
}