pragma solidity ^0.4.16;
contract Refund {
    address owner = 0x0;
    function Refund() public payable {
        // 将部署合约的地址作为合约拥有者
        owner = msg.sender;
    }
    

}