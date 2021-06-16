/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.4.22;

contract SimpleAuction {
  // 定义参数：受益人、拍卖结束时间
    address public beneficiary;
    uint public auctionEnd;
    uint public biddingTime;
    uint public auctionStart;

    // 最高出价者
    address public highestBidder;

    // 最高出价
    uint public highestBid;

    mapping (address => uint) pendingReturns; // 用于取回之前的出价

    // 拍卖是否结束，不允许被修改
    bool ended;

    // 最高出价变动时调用事件
    event HighestBidIncreased(address _bidder, uint _amount);

    // 拍卖结束时调用事件
    event AuctionEnded(address _winner, uint _amount);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    // 构造函数
    // 创建一个拍卖对象，初始化参数值：受益人、拍卖持续时间
    constructor(uint _biddingTime, address _beneficiary) public {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingTime = _biddingTime;
        auctionEnd = now + _biddingTime; // now: current block's timestamp

    }

    // 使用代币进行拍卖，当拍卖失败时，会退回代币
    // 出价功能：包括交易参数
    // 当出价不是最高，资金会被自动退回
    function bid() public payable{
        // 不需要参数，因为都被自动处理了
        // 当一个函数要处理Ether时，需要包含payable的修饰符

        // 如果超过了截止期，交易撤回
        if(now > auctionStart + biddingTime){
            revert();
        }

        // 如果出价不够，交易撤回
        if (msg.value <= highestBid){
            revert();
        }

        // 如果出价最高，当前出价者作为最高出价人
        if (highestBidder != 0){
          //highestBidder.send(highestBid); // send ether(in wei)to the address
          // 调用highestBidder.send(highestBid)的方式是危险的
          // 因为会执行不知道的协议
          // 因此最好让用户自己取回自己的代币
          pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // 取回被超出的拍卖前的出资
    function withdraw() public returns (bool){
        uint amount = pendingReturns[msg.sender];
        if (amount > 0){
            // 需要提前设置为0，因为接收者可以在这个函数结束前再次调用它
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)){
                // 不需要throw，直接重置代币数量即可
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // 结束拍卖，将金额给予受益人
    function auctionEnd() public {
        // 与其他协议交互的最好遵循以下顺序的三个步骤：
        // 1.检查状况
        // 2.修改状态
        // 3.合约交互
        // 如果这三个步骤混在一起，那么攻击者可能通过多次调用这个函数来进行攻击

        // 1.检查状况
        if (now <= auctionEnd) {
          revert();
        }
        if(ended){
          revert();
        }
      //  require (now >= auctionEnd, "Auction not yet ended.");
      //  require (!ended, "auctionEnd has already called.");

        // 2.修改状态
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3.合约交互
        beneficiary.transfer(highestBid);
      }

      function () public{
        revert();
      }
}