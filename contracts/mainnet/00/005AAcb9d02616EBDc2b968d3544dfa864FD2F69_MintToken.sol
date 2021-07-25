/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.11;

contract Ownable {
    address public owner;
    address public manager;
    uint private unlocked = 1;
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "1000");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == owner || (manager != address(0) && msg.sender == manager), "1000");
        _;
    }

    function setManager(address user) external onlyOwner {
        manager = user;
    }

    modifier lock() {
        require(unlocked == 1, '1001');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

contract ITGToken{
    uint public totalSupply;
    uint public limitSupply;
    mapping(address => uint) public balanceOf;
    function mint(address miner,uint256 tokens,uint256 additional) external returns(bool success);
    function redeem(address miner,uint256 tokens) external returns(bool success);
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, '1002');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, '1002');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, '1002');
    }
    
    function div(uint x,uint y) internal pure returns (uint z){
        if(x==0){
            return 0;
        }
        require(y == 0 || (z = x / y) > 0, '100');
    }
}

contract MintToken is IERC20, Ownable {
    using SafeMath for uint;

    ITGToken tg;
    address public tokenContract;
    uint limitSupply;//tgtoken的预发行总量
    uint minerPrice = 1 ether;//高配矿工价格 eth
    uint minerQuota = 100 ether * 10000;//高配矿工配额
    uint public minerid = 0;//矿工计数
    uint public auctionId = 0;//拍卖计数
    uint public lessThanId = 0;//不满足矿工要求的计数
    uint constant RATIO = 10000;//1eth质押铸币数量
    uint constant MINER_LIMIT = 10000;//矿工数量限制
    uint constant MINER_EXPIRES = 180 days;
    uint constant QUOTA_LIMIT = 5 ether * 10000; //5 ether * RATIO 默认配额的上限
    uint constant MINT_MIN_VALUE = 0.1 ether;//最小质押值
    uint constant MINT_MAX_VALUE = 1 ether;//首次最大质押值
    uint constant MIN_TOKENS = 1000 ether;//持续持有铸币的最小值

    uint public totalSupply;
    uint public constant decimals = 18;
    string public constant name = 'TGToken Mint Certificate';
    string public constant symbol = 'TMC';

    bool auctionStatus = false;//是否开启拍卖

    struct MinerStruct {
        uint id;
        uint quota;
        uint tokens;
    }
    struct AuctionStruct {
        uint id;
        uint quota;
        uint expires;
        uint price;
        uint count;
        uint highest;
        address bider;
    }
    struct LessThanStruct {
        uint id;
        uint time;
    }
    mapping (address => AuctionStruct) public auctions;
    mapping (address => MinerStruct) miners;
    mapping (uint => address) public auctionOf;
    mapping (address => mapping(address => uint)) public allowance;
    mapping (address => LessThanStruct) lessThanQuotaLimit;
    mapping (uint => address) lessThanOf;


    event Mint(address indexed from,uint id, uint value ,uint tokens);
    event Redeem(address indexed from, uint value, uint tokens);
    event Buy(address indexed from, address target, uint value);
    event Auction(address indexed from,uint id,uint quota, uint price,uint count,uint expires,address bider, uint highest);

    constructor () public {
        _miner_add(msg.sender, 0, 0, 0);
    }

    function initTokenContract(address _token) external onlyOwner{
        tokenContract = _token;
        tg = ITGToken(tokenContract);
        limitSupply = tg.limitSupply();
        miners[msg.sender].quota = limitSupply;
    }

    function balanceOf(address user) external view returns (uint){
        return miners[user].tokens;
    }

    function _transfer(address from, address to, uint value) private {
        require(miners[to].id > 0, '2030');
        miners[from].tokens = miners[from].tokens.sub(value);
        miners[to].tokens = miners[to].tokens.add(value);
        _update_lessthan(from);
        _update_lessthan(to);
        emit Transfer(from, to, value);
    }

    function transfer(address to, uint value) external lock returns (bool){
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint value) external returns (bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool){
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function mint() external payable {
        require(msg.value >= MINT_MIN_VALUE, '2001');
        uint tokens = msg.value.mul(RATIO);
        uint amount = tokens / 20;

        if(miners[msg.sender].id > 0){
            miners[msg.sender].tokens = miners[msg.sender].tokens.add(tokens);
            require(miners[msg.sender].tokens <= miners[msg.sender].quota,'2004');
        }else{
            require(msg.value <= MINT_MAX_VALUE,'2006');
            require(!_isContract(msg.sender), '2034');
            _miner_add(msg.sender, 0, tokens.mul(5), tokens);
        }
        _update_lessthan(msg.sender);
        totalSupply = totalSupply.add(miners[msg.sender].tokens);
        require(tg.mint(msg.sender,tokens,amount), '2007');
        emit Mint(msg.sender, miners[msg.sender].id, msg.value, tokens);
    }

    function redeem(uint _value) external lock{
        require(miners[msg.sender].id > 0,'2009');
        uint value = _value;
        uint tokens = value.mul(RATIO);
        if(tokens > miners[msg.sender].tokens){
            tokens = miners[msg.sender].tokens;
            value = tokens.div(RATIO);
        }
        miners[msg.sender].tokens = miners[msg.sender].tokens.sub(tokens);
        totalSupply = totalSupply.sub(tokens);
        _update_lessthan(msg.sender);
        require(tg.redeem(msg.sender,tokens),'2011');
        msg.sender.transfer(value);
        emit Redeem(msg.sender,value, tokens);
    }

    function _miner_add(address user, uint id, uint quota, uint tokens) private{
        if(id == 0){
            require(minerid < MINER_LIMIT,'2005');
            minerid += 1;
            miners[user] = MinerStruct(minerid,quota,tokens);
        }else{
            miners[user] = MinerStruct(id,quota,tokens);
        }
    }

    function _miner_clear(address user) private {
        delete miners[user];
    }

    function _update_lessthan(address user) private {
        if(miners[user].id == 0 || miners[user].quota > QUOTA_LIMIT || miners[user].tokens >= MIN_TOKENS){
            if(lessThanQuotaLimit[user].time > 0){
                delete lessThanOf[lessThanQuotaLimit[user].id];
                delete lessThanQuotaLimit[user];
            }
        }else if(lessThanQuotaLimit[user].time == 0){
            lessThanId += 1;
            lessThanQuotaLimit[user] = LessThanStruct(lessThanId,_now(0));
            lessThanOf[lessThanId] = user;
        }
    }

    function buy(address target) external lock payable{
        require(!_isContract(msg.sender), '2034');
        if(target == address(0)){
            require(minerPrice > 0 && msg.value == minerPrice, '2012');
            if(miners[msg.sender].id == 0){
                _miner_add(msg.sender,0, minerQuota, 0);
            }else{
                miners[msg.sender].quota = miners[msg.sender].quota.add(minerQuota);
                _update_lessthan(msg.sender);
                require(miners[msg.sender].quota <= QUOTA_LIMIT * 100, '2016');
            }
            address(uint160(owner)).transfer(msg.value);
            emit Buy(msg.sender,target,msg.value);
        }else{
            require(miners[msg.sender].id == 0,'2013');
            require(minerid >= MINER_LIMIT, '2005');
            require(msg.value >= 0.2 ether && msg.value <= 1 ether, '2014');
            MinerStruct memory miner = miners[target];
            require(_allowTransfer(target,miner),'2015');

            uint to_target_value = msg.value / 2;
            uint to_owner_value = msg.value - to_target_value;
            if(miner.tokens > 0){
                to_owner_value += miner.tokens.div(RATIO);
                totalSupply = totalSupply.sub(miner.tokens);
            }
            _miner_clear(target);
            _update_lessthan(target);
            _miner_add(msg.sender, miner.id, msg.value * RATIO * 5, 0);

            if(auctions[target].id>0){
                delete auctionOf[auctions[target].id];
                delete auctions[target];
            }

            address(uint160(target)).transfer(to_target_value);
            address(uint160(owner)).transfer(to_owner_value);

            emit Buy(msg.sender,target,msg.value);
        }
    }

    function auctionInitiate(uint price) external{
        require(auctionStatus &&
            minerid >= MINER_LIMIT &&
            miners[msg.sender].id > 1, '2017');
        require(auctions[msg.sender].id == 0, '2018');
        require(price > 0, '2019');
        uint expires = _now(7 days);
        auctionId += 1;
        auctions[msg.sender] = AuctionStruct(
            auctionId,
            miners[msg.sender].quota,
            expires,
            price,
            0,
            price,
            address(0)
        );
        auctionOf[auctionId] = msg.sender;
        emit Auction(msg.sender,auctionId,miners[msg.sender].quota, price, 0, expires, address(0), price);
    }

    function auctionCancel() external{
        uint id = auctions[msg.sender].id;
        require(id > 0, '2020');
        require(auctions[msg.sender].expires <= _now(0), '2021');
        require(auctions[msg.sender].bider == address(0), '2022');
        delete auctions[msg.sender];
        delete auctionOf[id];
        emit Auction(msg.sender,id,0, 0, 0, _now(0), address(0), 0);
    }

    function auctionBid(address target) external payable{
        require(miners[msg.sender].id == 0, '2013');
        AuctionStruct memory item = auctions[target];
        require(target != msg.sender, '2023');
        require(item.id > 0, '2024');
        require(item.expires > _now(0), '2027');
        require(msg.value > item.highest, '2025');
        require(!_isContract(msg.sender), '2034');

        address prev_bider = item.count == 0 ? address(0) : item.bider;
        uint prev_value = item.count == 0 ? 0 : item.highest;

        auctions[target].highest = msg.value;
        auctions[target].bider = msg.sender;
        auctions[target].count += 1;

        if(prev_value > 0){
            address(uint160(prev_bider)).transfer(prev_value);
        }
        emit Auction(target,item.id,item.quota,item.price, auctions[target].count, item.expires, msg.sender, msg.value);
    }

    function auctionFinish(address target) external lock{
        AuctionStruct memory item = auctions[target];
        require(item.id > 0, '2024');
        require(item.expires <= _now(0), '2028');
        require(item.count > 0 && item.bider == msg.sender, '2029');

        MinerStruct memory miner = miners[target];
        uint to_owner_value = item.highest / 10;
        uint to_target_value = item.highest - to_owner_value;
        if(miner.tokens > 0){
            to_owner_value += miner.tokens.div(RATIO);
            totalSupply = totalSupply.sub(miner.tokens);
        }
        _miner_clear(target);
        _update_lessthan(target);
        if(miners[msg.sender].id == 0){
            _miner_add(msg.sender, miner.id, miner.quota, 0);
        }else if(miners[msg.sender].quota <= miner.quota){
            miners[msg.sender].quota = miner.quota;
        }
        _update_lessthan(msg.sender);
        delete auctions[target];
        delete auctionOf[item.id];

        address(uint160(owner)).transfer(to_owner_value);
        address(uint160(target)).transfer(to_target_value);

        emit Auction(target,item.id,item.quota, item.price, item.count, _now(0), msg.sender, item.highest);
    }

    function setSellMiner(uint price,uint quota) external onlyOwner{
        require(quota > QUOTA_LIMIT, "quota must be greater than 50000tg");
        minerPrice = price;
        minerQuota = quota;
    }

    function setAuction(bool status) external onlyOwner{
        auctionStatus = status;
    }

    function viewSummary() external view returns (
        uint ratio,uint miner_count,uint miner_limit,uint miner_expires,
        uint miner_price,uint miner_quota,uint quota_limit,uint balance,bool auction_status,address token_contract
    ){
        return (
            RATIO,minerid,MINER_LIMIT,MINER_EXPIRES,minerPrice,minerQuota,
            QUOTA_LIMIT,address(this).balance,auctionStatus,tokenContract
        );
    }

    function viewMiner(address sender) external view returns (
        uint id,uint quota,uint tokens,uint value,uint status,uint expires
    ){
        return (
            miners[sender].id,
            miners[sender].quota,
            miners[sender].tokens,
            miners[sender].tokens.div(RATIO),
            auctions[sender].id > 0 ? 1 : 0,
            lessThanQuotaLimit[sender].time>0?lessThanQuotaLimit[sender].time.add(MINER_EXPIRES):0
        );
    }

    function viewTransferMiner() external view returns (address addr){
        if(minerid < MINER_LIMIT){
            return address(0);
        }
        for(uint i = 1; i <= lessThanId; i++){
            address _addr = lessThanOf[i];
            if(_addr != address(0)){
                MinerStruct memory miner = miners[_addr];
                if(_allowTransfer(_addr,miner)){
                    return _addr;
                }
            }
        }
        return address(0);
    }

    function _allowTransfer(address user,MinerStruct memory miner) private view returns (bool){
        return miner.id>1 && miner.quota<=QUOTA_LIMIT && miner.tokens < MIN_TOKENS &&
            lessThanQuotaLimit[user].time.add(MINER_EXPIRES) < _now(0) &&
            (auctions[user].id == 0 || (auctions[user].id>0 && auctions[user].count==0 && auctions[user].expires<_now(0)));
    }

    function _now(uint value) internal view returns (uint) {
        //solium-disable-next-line
        uint v = block.timestamp;
        if(value != 0){
            v = v.add(value);
        }
        return v;
    }
    function _isContract(address account) private view returns (bool) {
        uint256 size;
        //solium-disable-next-line
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}