pragma solidity ^0.4.24;
// import "./Console.sol";

// @doc http://solidity-cn.readthedocs.io/zh/develop/solidity-by-example.html#id5
// contract SimpleAuction is Console {
contract SimpleAuction  {  
  address public beneficiary;  //受益人
  // 时间是unix的绝对时间戳（自1970-01-01以来的秒数）
  // 或以秒为单位的时间段。
  uint public auctionEnd; //竞拍终止时间

  // 拍卖的当前状态
  address public highestBidder; //最高竞拍者
  uint public highestBid; //最高竞拍

  // Allowed withdrawals of previous bids
  mapping(address => uint) pendingReturns;  //待退回的竞拍（不是最高出价都退回）

  // Set to true at the end, disallows any change
  bool ended; //一旦设置不允许再投标

  // Events that will be fired on changes.
  event HighestBidIncreased(address bidder, uint amount); //最高出价变动时调用事件
  event AuctionEnded(address winner, uint amount); // 拍卖结束时调用事件

  // 以下是所谓的 natspec 注释，可以通过三个斜杠来识别。
  // 当用户被要求确认交易时将显示。

  /// 以受益者地址 `_beneficiary` 的名义，
  /// 创建一个简单的拍卖，拍卖时间为 `_biddingTime` 秒。
  /// 初始化拍卖对象：受益人地址、拍卖持续时间
  //zy:在remix，使用 ["0x796573","0xe4b88d"] 来调用创建，需要将字符串转换成16进制
  constructor(
    uint _biddingTime,
    address _beneficiary
  ) public {
    beneficiary = _beneficiary;
    auctionEnd = now + _biddingTime;
    // log("time now", now);
  }


  /// 对竞拍投标，payable代表该交易可以获取ether，只有没有竞拍成功的交易款才会退回
  /// 对拍卖进行出价，具体的出价随交易一起发送。
  /// 如果没有在拍卖中胜出，则返还出价。
  function bid() public payable {
    // 参数不是必要的。因为所有的信息已经包含在了交易中。
    // 对于能接收以太币的函数，关键字 payable 是必须的。
    // 如果拍卖已结束，撤销函数的调用。
    
    //输入检查，竞拍如果结束则终止
    require(now <= auctionEnd);

    // If the bid is not higher, send the
    // money back.
    //如果投标金额未超过当前最高金额，则终止
    require(msg.value > highestBid);

    if (highestBid != 0) {
      // 返还出价时，简单地直接调用 highestBidder.send(highestBid) 函数，
      // 是有安全风险的，因为它有可能执行一个非信任合约。
      // 更为安全的做法是让接收方自己提取金钱。
      pendingReturns[highestBidder] += highestBid; //原来的最高变次高出价，次高出价要退回
    }
    highestBidder = msg.sender; //新的最高出价者
    highestBid = msg.value; //新的最高出价
    emit HighestBidIncreased(msg.sender, msg.value); //触发最高出价增加事件
  }

  /// Withdraw a bid that was overbid.
  /// 取回被淘汰的竞拍
  function withdraw() public returns (bool) {
    uint amount = pendingReturns[msg.sender];
    if (amount > 0) {

      // 这里很重要，首先要设零值。
      // 因为，作为接收调用的一部分，
      // 接收者可以在 `send` 返回之前，重新调用该函数。
      pendingReturns[msg.sender] = 0; //在send方法被执行之前，将待退还的钱置为0 *这个很重要* 因为如果不置为0的话，可以重复发起withdraw交易，send需要时间，在交易没确认之前，重复发起可能就要退N倍的钱

      if (!msg.sender.send(amount)) { //用户自己取回退回的款项时，如果出错不用调用throw方法，而是将被置0的待退款金额恢复
        // No need to call throw here, just reset the amount owing
        pendingReturns[msg.sender] = amount;
        return false;
      }
    }
    return true;
  }
  
  /// 结束拍卖，并把最高的出价发送给受益人
  function auctionEnd() public returns (bool){
    // 对于可与其他合约交互的函数（意味着它会调用其他函数或发送以太币），
    // 一个好的指导方针是将其结构分为三个阶段：
    // 1. 检查条件
    // 2. 执行动作 (可能会改变条件)
    // 3. 与其他合约交互
    // 如果这些阶段相混合，其他的合约可能会回调当前合约并修改状态，
    // 或者导致某些效果（比如支付以太币）多次生效。
    // 如果合约内调用的函数包含了与外部合约的交互，
    // 则它也会被认为是与外部合约有交互的。

    // 1. 条件
    require(now >= auctionEnd, "Auction not yet ended.");
    require(!ended, "auctionEnd has already been called.");

    // 2. 生效
    ended = true;
    emit AuctionEnded(highestBidder, highestBid);

    // 3. 交互
    beneficiary.transfer(highestBid);
    return ended;
  }
  

  
  
}