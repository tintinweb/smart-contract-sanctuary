/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC721 {
    function mint(address _to, uint256 _tokenId, string calldata _uri) external;

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

interface Staking {
    function stake(address _to, uint256 _amount, bool _claim) external returns (uint256);
}

contract Auction {
    address private owner;
    //NFT出价人列表
    mapping(string => mapping(address => uint256)) public bidders;
    //NFT当前最高价买家
    mapping(string => address) public last_bidder;
    //NFT当前价
    mapping(string => uint256) public n_price;
    //nft保留价格
    mapping(string => uint256) public reservePrice;
    //nft加价比例
    mapping(string => uint256) public minBidIncrementPercentage;
    //nft当前状态 TRUE 进行中 FALSE 已结束
    //nft是否已经结算 TRUE 是 FALSE 否
    mapping(string => bool) public n_status;
    //nft当前锁定状态 TRUE 已锁定 FALSE 未锁定
    mapping(string => bool) public n_lock;
    //nft结束时间
    mapping(string => uint256) public endTime;
    //黑名单
    mapping(string => mapping(address => bool)) public blacks;
    //nft结算方式
    mapping(string => address) public n_settle;
    //nft延时
    mapping(string => uint256) public n_timeBuffer;
    //nft合约地址
    mapping(string => address) public n_addr;
    //管理员
    mapping(address => bool) public _manager;
    //赠送币比例
    uint256 public _rate;
    //质押合约地址
    address public _stake;
    //代币小数位
    uint256 public _tokenDecimal;

    constructor(uint256 rate, address stake, uint8 decimal){
        owner = msg.sender;
        _rate = rate;
        _stake = stake;
        _tokenDecimal = decimal;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier isManager() {
        require(msg.sender == owner || _manager[msg.sender], "Caller is not manager");
        _;
    }
    //校验需要锁定/解锁的nft是否存在
    modifier isLock(string memory nft) {
        require(n_lock[nft] != true, "The auction is locked");
        _;
    }
    //校验是否已经结束
    modifier isExpired(string memory nft) {
        require(block.timestamp < endTime[nft], "Auction expired");
        _;
    }

    function push(string memory nft, uint256 lowestPrice, uint256 time, address settle, uint256 timeBuffer, uint256 percentage, address addr) public isManager {
        reservePrice[nft] = lowestPrice;
        minBidIncrementPercentage[nft] = percentage;
        n_status[nft] = false;
        n_lock[nft] = false;
        endTime[nft] = time;
        n_settle[nft] = settle;
        n_timeBuffer[nft] = timeBuffer;
        n_addr[nft] = addr;
    }

    //解锁/锁定NFT
    function lock(string memory nft, uint8 lockType) public isManager isExpired(nft) {
        if (lockType == 1) {
            n_lock[nft] = true;
        }
        if (lockType == 0) {
            n_lock[nft] = false;
        }
    }

    //修改NFT截止时间
    function modify(string memory nft, uint256 time) public isManager isLock(nft) isExpired(nft) {
        endTime[nft] = time;
    }

    //添加/移除黑名单
    function lockAddr(string memory nft, address addr, uint8 processType) public isManager isLock(nft) isExpired(nft) {
        if (processType == 1) {
            blacks[nft][addr] = true;
        }
        if (processType == 0) {
            blacks[nft][addr] = false;
        }
    }

    //参与竞拍
    function bid(string memory nft, uint256 amount) public payable isLock(nft) isExpired(nft) {

        //地址是否在黑名单
        require(blacks[nft][msg.sender] != true, "Addr is forbidden");

        if (n_settle[nft] == address(0)) {
            amount = msg.value;
        } else {
            require(
                msg.value == 0,
                "ERC20 auctions only accept ERC20_TOKEN, pls do not send ether"
            );
        }
        //nft时间是否已结束
        if (block.timestamp >= endTime[nft]) {
            AuctionEnd(nft);
        }
        //第一次出价不得低于底价
        uint256 oldPrice = n_price[nft];
        require(amount >= reservePrice[nft], "Must send at least reservePrice");
        require(
            amount >=
            oldPrice +
            ((oldPrice * minBidIncrementPercentage[nft]) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
        //退回上一个竞拍人的资产
        address bidder = last_bidder[nft];
        if (bidder != address(0)) {
            if (n_settle[nft] == address(0)) {
                payable(bidder).transfer(oldPrice);
            } else {
                IERC20(n_settle[nft]).transfer(bidder, oldPrice);
            }
        }
        if (n_settle[nft] != address(0)) {
            IERC20(n_settle[nft]).transferFrom(msg.sender, address(this), amount);
        }
        bool extended = endTime[nft] - block.timestamp < n_timeBuffer[nft];
        if (extended) {
            endTime[nft] = block.timestamp + n_timeBuffer[nft];
        }
        //刷新当前价格;
        n_price[nft] = amount;
        //刷新出价人列表
        bidders[nft][msg.sender] = amount;
        //刷新最后出价人
        last_bidder[nft] = msg.sender;
    }

    //拍卖结束
    function AuctionEnd(string memory nft) public isManager {
        require(block.timestamp >= endTime[nft], "Auction is not expired");
        n_status[nft] = true;
        if (n_price[nft] != 0 && last_bidder[nft] != address(0)) {
            //转账
            IERC721(n_addr[nft]).safeTransferFrom(address(this), last_bidder[nft], stringToUint(nft));
            if (n_settle[nft] == address(0)) {
                Staking(_stake).stake(last_bidder[nft], ((n_price[nft] / (10 ** 18)) * _rate * (10 ** _tokenDecimal)) / 1000, true);
            } else {
                Staking(_stake).stake(last_bidder[nft], (n_price[nft] * _rate) / 1000, true);
            }

        }
    }

    function withDraw(address contractAddr, address _to, uint256 amount) public payable isOwner {
        if (contractAddr == address(0)) {
            payable(_to).transfer(amount);
        } else {
            IERC20(contractAddr).transfer(_to, amount);
        }
    }

    function manager(address addr, bool state) public isOwner {
        _manager[addr] = state;
    }

    function modifyRate(uint256 rate) public isManager {
        _rate = rate;
    }

    function modifyStake(address stake) public isManager {
        _stake = stake;
    }

    function _decimal(uint8 decimal) public isManager {
        _tokenDecimal = decimal;
    }

    function _approve(address tokenAddr, uint256 amount) public isManager returns (bool) {
        return IERC20(tokenAddr).approve(_stake, amount);
    }

    function blockTime() public view returns (uint256){
        return block.timestamp;
    }

    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }
}