/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity ^0.8.0;


contract Auction_me {
    address public owner;
    //NFT元数据 目前废弃
    mapping(string => mapping(string=>string)) public metadata;
    //NFT出价人列表
    mapping(string => mapping(address=>uint256)) public bidders;
    //NFT当前最高价买家
    mapping(string => address) public last_bidder;
    //NFT当前价
    mapping(string => uint256) public n_price;
    //nft当前状态 TRUE 进行中 FALSE 已结束
    mapping(string => bool) public n_status;
    //nft当前锁定状态 TRUE 已锁定 FALSE 未锁定
    mapping(string => bool) public n_lock;
    //nft开始时间
    mapping(string=>uint256) public startTime;
    //nft持续时间
    mapping(string=>uint256) public conTime;
    //黑名单
    mapping(string => mapping(address=>bool)) public blacks;
    //nft是否第一次出价
    mapping(string=>bool) public n_first;

    constructor() public payable {
        owner = msg.sender;
    }

    function push(string memory nft, uint256 lowestPrice, uint256 time) public {
        //校验nft标签是否已经存在
        //require(metadata[nft] != '',"nft is exist");
        require(owner == msg.sender , "You are not the owner of this contract");
        n_price[nft] = lowestPrice;
        n_status[nft] = false;
        n_lock[nft] = false;
        startTime[nft] = block.timestamp;
        conTime[nft] = time;
    }

    //解锁/锁定NFT
    function lock(string memory nft,uint8 lockType) public {
        //校验nft标签是否已经存在
        //require(metadata[nft] != '',"nft is exist");
        //校验需要锁定/解锁的nft是否存在
        require(owner == msg.sender , "You are not the owner of this contract");
        //校验是否已经结束
        require(n_status[nft]!=true,"The auction is over");
        if(lockType ==1)
        {
            n_lock[nft] = true;
        }
        if(lockType ==0)
        {
            n_lock[nft] = false;
        }
    }

    //修改NFT截止时间
    function modify(string memory nft,int256 time) public {
        //校验nft标签是否已经存在
        //require(metadata[nft] != '',"nft is exist");
        //校验需要修改的nft是否存在
        require(owner == msg.sender , "You are not the owner of this contract");
        //校验是否已经结束
        require(n_status[nft]!=true,"The auction is over");
        //校验是否已经锁定
        require(n_lock[nft]!=true,"The auction is locked");
        if (time < 0) {
            conTime[nft] = conTime[nft] - uint256(time);
        } else {
            conTime[nft] = conTime[nft] + uint256(time);
        }
        if(block.timestamp >= (startTime[nft]+conTime[nft]))
        {
            AuctionEnd(nft);
        } 
        
    }

    //添加/移除黑名单
    function lockAddr(string memory nft,address addr,uint8 processType) public {
        //校验nft标签是否已经存在
        //require(metadata[nft] != '',"nft is exist");
        //校验需要修改的nft是否存在
        //校验是否是拥有者
        require(owner == msg.sender , "You are not the owner of this contract");
        //校验是否已经结束
        require(n_status[nft]!=true,"The auction is over");
        //校验是否已经锁定
        require(n_lock[nft]!=true,"The auction is locked");
        if(processType ==1)
        {
            blacks[nft][addr] = true;
        }
        if(processType ==0)
        {
            blacks[nft][addr] = false;
        }
    }

    //参与竞拍
    function bid(string memory nft) public payable {
        //地址是否在黑名单
        bool is_lock = blacks[nft][msg.sender];
        require(is_lock!=true,"addr is forbidden");
        //nft时间是否已结束
        uint256 start = startTime[nft];
        uint256 con_time = conTime[nft];
        if(block.timestamp >= (start+con_time))
        {
            AuctionEnd(nft);
        }
        require(block.timestamp<=start+con_time,"Bidding time is over");
        //nft状态是否已结束
        bool isEnd = n_status[nft];
        require(isEnd != true,"The Auction is over");
        //nft是否已锁定
        require(n_lock[nft] != true,"The Auction is lock");
        //第一次出价不得低于底价
        uint256 oldPrice = n_price[nft];
        require(msg.value > oldPrice, "The lowestPrice is below the minimum lowestPrice");
        //退回上一个竞拍人的资产
        if(n_first[nft] != false)
        {
            address bidder = last_bidder[nft];
            payable(bidder).transfer(oldPrice);
            n_first[nft] = true;
        }
        //刷新当前价格;
        n_price[nft] = msg.value;
        //刷新出价人列表
        bidders[nft][msg.sender] = msg.value;
        //刷新最后出价人
        last_bidder[nft] = msg.sender;
        //刷新持续时间
        conTime[nft] = con_time + con_time;
        //结算
        if(block.timestamp >= (startTime[nft]+conTime[nft]))
        {
            AuctionEnd(nft);
        } 
    }

    //拍卖结束
    function AuctionEnd(string memory nft) public payable{
        n_status[nft] = true;
        if(n_price[nft] != 0)
        {
           //转账
          //payable(last_bidder[nft]).transfer(msg.value);
        }
    }

    function withDraw(string memory nft,address _to) public payable{
        require(_to != address(0));
        require(owner == msg.sender , "You are not the owner of this contract");
        require(n_status[nft] == true,"The auction is not over yet");
        payable(_to).transfer(msg.value);
    }
}