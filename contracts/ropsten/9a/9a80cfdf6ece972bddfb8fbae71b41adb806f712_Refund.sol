pragma solidity ^0.4.24;
contract Refund {
    
    address owner = 0x0;
    uint256 ticket = 1 ether;    // 一个eth
      
    // 合约构造函数
    // 第一次部署合约时，会调用该方法。
    // 之后执行合约不会调用。
    constructor() public payable {
        // 将部署合约的地址作为合约拥有者
        owner = msg.sender;
    }
  
    // 后备函数
    function () public payable {
          require(msg.value >= ticket);
          if (msg.value > ticket) {
              uint256 refundFee = msg.value - ticket;
              msg.sender.transfer(refundFee);
        }
    }
}