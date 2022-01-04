/**
 *Submitted for verification at Etherscan.io on 2022-01-04
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

    function safeTransferFrom(address _from, address _to, string memory _tokenId) external;
}

contract Nft {

    uint256[] public mark;//角标
    mapping(uint256 => address) name;//出价人列表
    mapping(uint256 => uint256) prices;//出价人价格
    uint256  _initPrice;//起拍价
    uint256  _price;//起拍价
    address  _last;//最后出价人
    uint256 _rate;//加价幅度
    bool _status;//是否已结算
    uint256 _endTime; //nft结束时间
    address _settle; //nft结算方式
    uint256  _timeBuffer; //nft延时
    address public _addr; //nft合约地址

    struct Bid {
        uint8 index; // scaling variable for price
        address addr; // fixed term or fixed expiration
        uint256 price; // term in blocks (fixed-term)
    }

    //校验是否已经结束
    modifier isExpired(string memory nft) {
        require(block.timestamp < _endTime, "Auction expired");
        _;
    }

    constructor(uint256 initPrice, uint256 time, address settle, uint256 timeBuffer, uint256 rate, address addr){
        _initPrice = initPrice;
        _endTime = time;
        _settle = settle;
        _timeBuffer = timeBuffer;
        _rate = rate;
        _addr = addr;

    }

    function query(uint8 index) public view returns (Bid[] memory) {
        Bid[] memory bids;
        if (index >= mark.length) {
            return bids;
        }

        uint256 position = index;

        for (; index < mark.length; index++) {
            address addr = name[index];
            uint256 price = prices[index];
            bids[index - position] = Bid({
            index : index, // scaling variable for price
            addr : addr, // fixed term or fixed expiration
            price : price //
            });
        }
        return bids;
    }

    //参与竞拍
    function bid(string memory nft, uint256 amount) public payable isExpired(nft) {

        if (_settle == address(0)) {
            amount = msg.value;
        } else {
            require(
                msg.value == 0,
                "ERC20 auctions only accept ERC20_TOKEN, pls do not send ether"
            );
        }
        //nft时间是否已结束
        if (block.timestamp >= _endTime) {
            AuctionEnd(nft);
        }
        //第一次出价不得低于底价
        uint256 oldPrice = _price;
        require(amount >= _initPrice, "Must send at least reservePrice");
        require(
            amount >=
            oldPrice +
            ((oldPrice * _rate) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
        //退回上一个竞拍人的资产
        address bidder = _last;
        if (bidder != address(0)) {
            if (_settle == address(0)) {
                payable(bidder).transfer(oldPrice);
            } else {
                IERC20(_settle).transfer(bidder, oldPrice);
            }
        }
        if (_settle != address(0)) {
            IERC20(_settle).transferFrom(msg.sender, address(this), amount);
        }
        bool extended = _endTime- block.timestamp < _timeBuffer;
        if (extended) {
            _endTime = block.timestamp + _timeBuffer;
        }
        //刷新当前价格;
        _price = amount;
        //刷新出价人列表
        mark.push(mark.length + 1);
        name[mark.length] = msg.sender;
        prices[mark.length] = amount;
        //刷新最后出价人
        _last = msg.sender;
    }

    //拍卖结束
    function AuctionEnd(string memory nft) public {
        require(block.timestamp >= _endTime, "Auction is not expired");
        _status = true;
        if (_price != 0 && _last != address(0)) {
            //转账
            IERC721(_addr).safeTransferFrom(address(this), _last, nft);
        }
    }

    function withDraw(address contractAddr, address _to, uint256 amount) public payable {
        if (contractAddr == address(0)) {
            payable(_to).transfer(amount);
        } else {
            IERC20(contractAddr).transfer(_to, amount);
        }
    }

    function modify(uint256 endTime) public  returns (bool){
        _endTime = endTime;
        return true;
    }

    function queryEnd() public view returns(uint256) {
        return _endTime;
    }

    function queryAddr() public view returns(address) {
        return _addr;
    }


}

contract Auction {
    address private owner;
    mapping(string => Nft) public nfts;
    //nft当前锁定状态 TRUE 已锁定 FALSE 未锁定
    mapping(string => bool) public n_lock;
    //黑名单
    mapping(string => mapping(address => bool)) public blacks;

    constructor(){
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    //校验需要锁定/解锁的nft是否存在
    modifier isLock(string memory nft) {
        require(n_lock[nft] != true, "The auction is locked");
        _;
    }
    //校验是否已经结束
    modifier isExpired(string memory nft) {
        require(block.timestamp < nfts[nft].queryEnd(), "Auction expired");
        _;
    }
    //校验是否存在
    modifier isExist(string memory nft) {
        require(nfts[nft].queryAddr() != address(0), "nft not exist");
        _;
    }

    function push(string memory nft, uint256 initPrice, uint256 time, address settle, uint256 timeBuffer, uint256 percentage, address addr) public isOwner returns (bool){
        require(nfts[nft].queryAddr() != address(0), "ntf is exist");
        nfts[nft] = new Nft(initPrice, time, settle, timeBuffer, percentage, addr);
        return true;
    }

    function bid(string memory nft, uint256 amount) public payable isLock(nft) isExpired(nft) isExist(nft) {
        //地址是否在黑名单
        require(blacks[nft][msg.sender] != true, "Addr is forbidden");
        nfts[nft].bid(nft,amount);
    }

    //解锁/锁定NFT
    function lock(string memory nft, bool state) public isOwner isExpired(nft) isExist(nft) returns (bool){
        n_lock[nft] = state;
        return true;
    }

    //修改NFT截止时间
    function modify(string memory nft, uint256 time) public isOwner isLock(nft) isExpired(nft) isExist(nft) returns (bool) {
        require(blockTime() > time, " time error");
        nfts[nft].modify(time);
        return true;
    }

    //添加/移除黑名单
    function lockAddr(string memory nft, address addr, bool state) public isOwner isLock(nft) isExpired(nft) isExist(nft) returns (bool) {
        blacks[nft][addr] = state;
        return true;
    }

    function blockTime() public view returns (uint256){
        return block.timestamp;
    }
}