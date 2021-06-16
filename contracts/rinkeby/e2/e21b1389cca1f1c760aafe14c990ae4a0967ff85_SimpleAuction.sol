/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.4.22;

contract SimpleAuction {
    // 拍卖的参数
    address public beneficiary; // 拍卖的受益人
    uint public auctionEnd; // 拍卖的结束时间


    address public highestBidder; // 当前的最高出价者
    uint public highestBid; // 当前的最高出价

    mapping(address => uint) pendingReturns; // 用于取回之前的出价

    bool ended; // 拍卖是否结束

    // 发生变化时的事件
    event HighestBidIncreased(address bidder, uint amount); // 出现新的最高价
    event AuctionEnded(address winner, uint amount); // 拍卖结束

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// 创建一个拍卖，参数为拍卖时长和受益人
    function SimpleAuction(
        uint _biddingTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        auctionEnd = now + _biddingTime;
    }

    /// 使用代币来进行拍卖
    /// 当拍卖失败时，会退回代币
    function bid() public payable {
        // 不需要参数，因为都被自动处理了
        // 当一个函数要处理Ether时，需要包含payable的修饰符

        // 如果超过了截止期，交易撤回
        require(
            now <= auctionEnd,
            "Auction already ended."
        );

        // 如果出价不够，交易撤回
        require(
            msg.value > highestBid,
            "There already is a higher bid."
        );

        if (highestBid != 0) {
            // 调用highestBidder.send(highestBid)的方式是危险的
            // 因为会执行不知道的协议
            // 因此最好让用户自己取回自己的代币
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// 取回被超出的拍卖前的出资
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 需要提前设置为0，因为接收者可以在这个函数结束前再次调用它
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // 不需要throw，直接重制代币数量即可
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// 结束拍卖，将金额给予受益人
    function auctionEnd() public {
        // 与其他协议交互的最好遵循以下顺序的三个步骤：
        // 1. 检查状况
        // 2. 修改状态
        // 3. 合约交互
        // 如果这三个步骤混在一起，那么攻击者可能通过多次调用这个函数来进行攻击

        // 1. 检查状况
        require(now >= auctionEnd, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        // 2. 修改状态
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3. 合约交互
        beneficiary.transfer(highestBid);
    }
}