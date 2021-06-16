/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.4.24;
contract SimpleAuction {
  // 定义参数：受益人、开始时间、拍卖持续时间
  address public beneficiary;
  uint public auctionStart;
  uint public biddingTime;
 
  // 最高出价者
  address public highestBidder;
  // 最高出价
  uint public highestBid;
 
  // 拍卖结束后，设置这个值为true，不允许被修改。
  bool ended;
 
  // 最高出价变动时调用事件
  event HighestBidIncreased(address bidder, uint amount);
  // 拍卖结束时调用事件
  event AuctionEnded(address winner, uint amount);
 
  // 创建一个拍卖对象，初始化参数值：受益人、开始时间、拍卖持续时间
  function SimpleAuction(uint _biddingTime, address _beneficiary) {
    beneficiary = _beneficiary;
    auctionStart = now;
    biddingTime = _biddingTime;
  }
 
  // 出价功能：包括交易参数。
  // 当出价不是最高，资金会被自动退回。
  function bid() payable  {
    // 从交易中获取时间，如果拍卖结束，拒绝出价
    if (now > auctionStart + biddingTime) {
      throw;
    }
    // 如果出价不是最高，资金退回
    if (msg.value <= highestBid) {
      throw;
    }
 
    // 如果出价最高，当前出价者作为最高出价人
    if (highestBidder != 0) {
      highestBidder.send(highestBid);
    }
    highestBidder = msg.sender;
    highestBid = msg.value;
    HighestBidIncreased(msg.sender, msg.value);
  }
 
  // 结束拍卖，并转账资金到受益人
  function auctionEnd() {
    if (now <= auctionStart + biddingTime)
      throw;
    if (ended)
      throw;
    AuctionEnded(highestBidder, highestBid);
 
    beneficiary.send(this.balance);
    ended = true;
  }
 
  // 当交易没有数据或者数据不对时，触发此函数，重置出价操作，确保出价者不会丢失资金
  function () {
    throw;
  }
}