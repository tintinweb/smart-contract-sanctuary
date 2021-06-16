/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.4.22;

// 密封拍卖协议
contract BlindAuction {
    struct Bid {
        bytes32 blindedBid;
        uint deposit;
    }

    address public beneficiary; // 受益人
    uint public biddingEnd; // 出价结束时间
    uint public revealEnd; // 揭示价格结束时间
    bool public ended; // 拍卖是否结束

    mapping(address => Bid[]) public bids; // 地址到竞标之间的映射

    address public highestBidder; // 最高出价者
    uint public highestBid;  // 最高出价

    // 允许撤回没有成功的出价
    mapping(address => uint) pendingReturns;

    event AuctionEnded(address winner, uint highestBid);  // 拍卖结束的事件

    /// 修饰符主要用于验证输入的正确定
    /// onlyBefore和onlyAfter用于验证是否大于或者小于一个时间点
    /// 其中`_`是原始程序开始执行的地方
    modifier onlyBefore(uint _time) { require(now < _time); _; }
    modifier onlyAfter(uint _time) { require(now > _time); _; }

    // 构建函数：保存受益人、竞标结束时间、公示价格结束时间
    function BlindAuction(
        uint _biddingTime,
        uint _revealTime,
        address _beneficiary
    ) public {
        beneficiary = _beneficiary;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    /// 给出一个秘密出价 _blindedBid = keccak256(value, fake, secret)
    /// 给出的保证金只在出价正确时给予返回
    /// 有效的出价要求出价的ether至少到达value，并且fake不是true
    /// 设置fake为true，并且给出一个错误的出价可以隐藏真实的出价
    /// 一个地址能够多次出价
    /// QY：如果是我的话，我会限制必须一个人的出价都是有效的才有进一步的操作，从而增加造假的难度
    function bid(bytes32 _blindedBid)
        public
        payable
        onlyBefore(biddingEnd)
    {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }

    /// 公示你的出价，对于正确参与的出价，只要没有最终获胜，都会被归还
    function reveal(
        uint[] _values,
        bool[] _fake,
        bytes32[] _secret
    )
        public
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            var bid = bids[msg.sender][i];
            var (value, fake, secret) =
                    (_values[i], _fake[i], _secret[i]);
            if (bid.blindedBid != keccak256(value, fake, secret)) {
                // bid不正确，不会退回押金
                continue;
            }
            refund += bid.deposit;
            if (!fake && bid.deposit >= value) { // 处理bid超过value的情况
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            // 防止再次claim押金
            bid.blindedBid = bytes32(0);
        }
        msg.sender.transfer(refund); // 如果之前没有置0，会有fallback风险
    }

    // 这是个内部函数，只能被协约本身调用
    function placeBid(address bidder, uint value) internal
            returns (bool success)
    {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != 0) {
            // 返回押金给之前出价最高的人
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// 撤回过多的出价
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 一定要先置0，规避风险
            pendingReturns[msg.sender] = 0;

            msg.sender.transfer(amount);
        }
    }

    /// 结束拍卖，把代币发给受益人
    function auctionEnd()
        public
        onlyAfter(revealEnd)
    {
        require(!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
}