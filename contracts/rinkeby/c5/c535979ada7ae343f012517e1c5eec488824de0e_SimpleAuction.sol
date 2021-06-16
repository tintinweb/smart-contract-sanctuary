/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

//简单的公开拍卖
pragma solidity ^0.4.11;
contract SimpleAuction {
    //定义拍卖的参数
    address public beneficiary;//拍卖的受益人
    uint public auctionStart;//拍卖开始时间
    uint public biddingTime;//出价时间
    
    //当前拍卖的状态
    address public HighestBidder;//最高出价者
    uint public HighestBid;//最高出价
    
    //判断拍卖结束标志，结束时用ture来拒绝任何改变
    bool ended;
    
    //声明事件，改变时会触发事件
    event HighestBidIncrease(address bidder,uint amount);
    event AcutionEnded(address winner,uint amount);
    
    //构造函数，初始化出价时间，竞拍开始时间和受益人
    function SimpleAuction(uint _biddingTime,address _beneficiary){
        biddingTime = _biddingTime;
        auctionStart = now;
        beneficiary = _beneficiary;
        
    }
    //竞拍出价
    function bid() payable public {
        //判断此刻时间是否在出价时间内
        if(now > auctionStart + biddingTime){
            revert();
        }
        //判断此账户出价是否高于最高出价
        if(msg.value <= HighestBid){
            revert();
        }
        //满足上述条件则进行如下
        //排除此时没有最高出价者的情况
        if(HighestBidder != 0){
            //退回此时最高出价者的保证金
            HighestBidder.transfer(HighestBid);
            //改变最高出价者地址为此时的出价者
            HighestBidder = msg.sender;
            //最高出价为此时出价者的保证金
            HighestBid = msg.value;
            HighestBidIncrease(msg.sender,msg.value);
        }
    }
    //拍卖结束后发送最高出价给受益人
    function acutionEnd(){
        //判断拍卖是否结束
        if(now <= auctionStart + biddingTime){
            revert();
        }
        //判断这个结束函数是否已经被调用，避免调用多次
        if(ended){
            revert();
        }
        //触发结束事件
        AcutionEnded(HighestBidder,HighestBid);
        //发送合约所有的钱给受益人
        beneficiary.transfer(this.balance);
        ended=true;
    }
    //当发送的交易事务包括无效的数据或者无数据时，
    //触发此函数来退出交易确保撤销所有交易
    function () {
        revert();
    }
}