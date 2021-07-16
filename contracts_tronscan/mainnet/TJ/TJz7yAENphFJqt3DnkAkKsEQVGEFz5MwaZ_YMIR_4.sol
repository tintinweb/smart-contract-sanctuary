//SourceUnit: B001_all_in_one_v4.sol

pragma solidity ^0.5.8;


library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount);

        (bool success, ) = recipient.call.value(amount)("");
        require(success);
    }
}

contract Ownable {
    using Address for address;
    address payable public Owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        Owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(Owner, _newOwner);
        Owner = _newOwner.toPayable();
    }
}

interface ITRC20 {
    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function totalSupply() external view returns (uint);
    function balanceOf(address who) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint amount, address token, bytes calldata extraData) external;
}

contract TRC20 is ITRC20, Ownable {
    using SafeMath for uint;
    using Address for address;

    mapping (address => uint) internal _balances;

    mapping (address => mapping (address => uint)) internal _allowances;

    uint internal _totalSupply;
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "insufficient allowance!");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function burn(uint amount) public returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }
    
    function approveAndCall(address spender, uint amount, bytes memory extraData) public returns (bool) {
        require(approve(spender, amount));

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), extraData);

        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        require(_balances[sender] >= amount, "insufficient balance");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint amount) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint amount) internal {
        require(account != address(0));
        require(_balances[account] >= amount, "insufficient balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    // stake logic
    
    mapping (address => uint) internal _stakes;
    
    function _stake(uint amount) internal returns (bool) {
        require(_balances[msg.sender] >= amount, "insufficient balance");
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _stakes[msg.sender] = _stakes[msg.sender].add(amount);
        
        return true;
    }
    
    function _unstake(uint amount) internal returns (bool) {
        require(_stakes[msg.sender] >= amount, "insufficient stake amount");
                
        _stakes[msg.sender] = _stakes[msg.sender].sub(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        
        return true;
    }
    
    function stakeAmount(address addr) public view returns (uint) {
        return _stakes[addr];
    }
}

contract TRC20Detailed is ITRC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library Objects {
    struct User {
        address payable addr;
        uint amount;
        uint pieces;
        uint[8] cards;
        uint withdrawableAmount;
        uint withdrawedAmount;
        uint latestTime;
        uint lastWithdrawTime;
                
        InviteInfo inviteInfo;
    }
    
    struct InviteInfo {
        uint inviterID;
        uint[15] inviteeCnt;
        uint[15] inviteeAmount;
        uint[15] reward;
        uint inviteeStakeAmount;
    }
}

contract YMIR_4 is TRC20Detailed, TRC20 {
    using Address for address;
    using SafeMath for uint;
    
    uint public decimalVal = 1e6;

    constructor () public TRC20Detailed("YMIR", "YMIR", 6) {
        _mint(msg.sender, 12000000*decimalVal);
        newUser(msg.sender);
        dev_ = msg.sender;
    }
    
    // offer logic
    uint public BuyStartTime = 1608898680; // 12/25/2020 @ 12:18pm (UTC)
    uint timeUnit = 1 days;
    uint[5] public stageDuration = [0, 2, 4, 6, 7];
    uint[5] public stagePrice = [0, 80, 85, 90, 95];

    function setStartTime(uint val) public onlyOwner returns (bool) {
        BuyStartTime = val;
        return true;
    }
    
    function setTimeUnit(uint val) public onlyOwner returns (bool) {
        timeUnit = val;
        return true;
    }
    
    modifier checkStart {
        if (msg.sender != Owner && msg.sender != address(token)) {
            require(block.timestamp >= stageDuration[stageDuration.length] * timeUnit, "not start");
        }
        _;
    }
    
    function transfer(address recipient, uint amount) public checkStart returns (bool) {
        return super.transfer(recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint amount) public checkStart returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
    
    function getPrice() public view returns (uint, uint) {
        uint t = block.timestamp;
        if (t < BuyStartTime) {
            return (0, 0);
        }
        uint idx = 1;
        for(; idx < stageDuration.length; idx++) {
            if (t >= BuyStartTime + stageDuration[idx-1] * timeUnit && t < BuyStartTime + stageDuration[idx] * timeUnit) {
                return (stagePrice[idx], idx);
            }
        }
        return (0, idx);
    }

    mapping(address => uint) public addr2uid_;
    mapping(uint => Objects.User) uid2User_;
    uint userCnt_;
    uint BuyPiecesReward = 188;
    uint BuyMinPay = 50 * 1e6;
    uint BuyMaxAmount = 3000 * 1e6;
    uint SellAmount;
    uint UsdtAmount;
    uint buyCnt_;
    address dev_;
    
    ITRC20 usdtToken = ITRC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);
    
    function setUSDTToken(address addr) public onlyOwner returns (bool) {
        usdtToken = ITRC20(addr);
        return true;
    }
    
    function setDev(address addr) public onlyOwner returns (bool) {
        require(addr != address(0), "invalid address");
        dev_ = addr;
        return true;
    }
    
    function newUser(address payable addr) internal returns (uint) {
        uint uid = addr2uid_[addr];
        if (uid > 0) {
            return uid;
        }
        userCnt_ = userCnt_ + 1;
        uid = userCnt_;
        uid2User_[uid].addr = addr;
        addr2uid_[addr] = uid;
        return uid;
    }

    function getUID(address addr) public view returns (uint) {
        return addr2uid_[addr];
    }
    
    function getAddrByUid(uint uid) public view returns (address) {
        return uid2User_[uid].addr;
    }
    
    function getUserInfo(address addr) public view returns (uint userID, address userAddr, uint buyAmountUSDT, uint pieces, uint[8] memory cards, 
        uint lastWithdrawTime, uint withdrawableAmount, uint withdrawedAmount) {
        uint uid = getUID(addr);
        require(uid > 0, "invalid user");
        Objects.User storage user = uid2User_[uid];
        
        return (uid, user.addr, user.amount, user.pieces, user.cards, user.lastWithdrawTime, 
            user.withdrawableAmount + calcProfit(stakeAmount(user.addr), user.latestTime), 
            user.withdrawedAmount);
    }

    function getInviteInfo(address addr) public view returns (uint inviterID, uint [15] memory inviteeCnt, uint[15] memory inviteeAmount, 
        uint[15] memory inviteeReward, uint inviteeStakeAmount) {
        uint uid = addr2uid_[addr];
        require(uid>0, "invalid user");
        
        Objects.User storage user = uid2User_[uid];
        
        return (
            user.inviteInfo.inviterID,
            user.inviteInfo.inviteeCnt,
            user.inviteInfo.inviteeAmount,
            user.inviteInfo.reward,
            user.inviteInfo.inviteeStakeAmount
        );
    }

    ITRC20 token;
    function setToken(address addr) public onlyOwner returns (bool) {
        require(addr != address(0));
        token = ITRC20(addr);
        return true;
    }
    
    event Buy(address indexed user, uint usdtAmount, uint tokenAmount);
    
    function buy(uint inviterID, uint amount) public payable returns (bool) {
        require(address(token) != address(0), "set token address first");
        (uint price, ) = getPrice();
        require(price > 0, "can't buy");
        require(amount >= BuyMinPay, "invalid amount");
        
        uint uid = getUID(msg.sender);
        if (0 == uid) {
            uid = newUser(msg.sender);
        }
        require(uid > 0, "invalid user");
        if (inviterID == 0 || inviterID == uid || inviterID >= userCnt_) {
            inviterID = 1;
        }

        Objects.User storage user = uid2User_[uid];
        require(user.amount.add(amount) <= BuyMaxAmount, "exceed max amount");
        
        bool isNew = false;
        if (user.inviteInfo.inviterID == 0) {
            user.inviteInfo.inviterID = inviterID;
            isNew = true;
        }
        
        setInviteData(uid, user.inviteInfo.inviterID, amount, isNew, 0, false);
        
        if (user.amount == 0) {
            user.pieces = user.pieces.add(BuyPiecesReward);
        }
        
        UsdtAmount = UsdtAmount.add(amount);
        buyCnt_++;

        uint devAmount = amount.mul(50).div(100);
        usdtToken.transferFrom(msg.sender, dev_, devAmount);
        user.amount = user.amount.add(amount);
        
        uint tokenAmount = amount.mul(100).div(price);
        token.transferFrom(Owner, msg.sender, tokenAmount);
        SellAmount = SellAmount.add(tokenAmount);
        require(SellAmount <= 1200000 * 1e6, "sell out");
        
        emit Buy(msg.sender, amount, tokenAmount);
        
        return true;
    }
    
    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(address(this).balance >= amount);

        to.transfer(amount);
    }

    function rescue(address to, ITRC20 trc20Token, uint256 amount) external onlyOwner {
        require(to != address(0), "must not 0");
        require(amount > 0, "must gt 0");
        require(trc20Token.balanceOf(address(this)) >= amount);

        trc20Token.transfer(to, amount);
    }
    
    function buyTotal() public view returns (uint usdtTotal, uint tokenAmount, uint userCnt, uint buyCnt) {
        return (
            UsdtAmount,
            SellAmount,
            userCnt_,
            buyCnt_
            );
    }

    // game
    uint public SellCardTokenAmount;
    uint playCnt_;
    uint[] piecesSlot = [6,7,8,9,10,11,12,13,14,15];
    uint[8] public cardYMIRPrice =   [ 750000, 156250,  22500, 12800,  1750,  450,    0,    0];
    uint[8] public cardPiecesPrice = [1875000, 625000, 125000, 80000, 12500, 3750, 2500, 1880];
    
    uint CardGameYMIR;

    event GetPieces(address indexed user, uint ymirAmount, uint piecesAmount);
    function getPieces(uint amount, uint seed) public returns (bool) {
        require(amount >= decimalVal, "invalid amount");
        playCnt_++;
        uint uid = getUID(msg.sender);
        if (uid == 0) {
            uid = newUser(msg.sender);
        }
        require(balanceOf(msg.sender) >= amount, "insufficient balance!");
        uint price = piecesSlot[uint(keccak256(abi.encodePacked(seed + block.timestamp + userCnt_ + playCnt_ + totalSupply())))%piecesSlot.length];
        burn(amount);
        uint pieces = amount.mul(price).div(decimalVal);

        uid2User_[uid].pieces = uid2User_[uid].pieces.add(pieces);
        emit GetPieces(msg.sender, amount, pieces);
        return true;
    }
    
    event GetCard(address indexed user, uint cardID, uint cardCnt);
    function getCard(uint cardID, uint cardCnt) public returns (bool) {
        playCnt_++;
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        require(cardID < 8 && cardCnt > 0, "invalid parameter");
        require(uid2User_[uid].pieces >= cardPiecesPrice[cardID].mul(cardCnt), "insufficient pieces");
        
        Objects.User storage user = uid2User_[uid];
        
        user.pieces = user.pieces.sub(cardPiecesPrice[cardID].mul(cardCnt));
        user.cards[cardID] = user.cards[cardID].add(cardCnt);
        
        emit GetCard(msg.sender, cardID, cardCnt);
        return true;        
    }
    
    event UpgradeCard(address indexed user, uint cardID, uint cardCnt, uint piecesCost);
    function upgradeCard(uint cardID, uint cardCnt) public returns (bool) {
        playCnt_++;
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        require(cardID > 0 && cardID < 8 && cardCnt > 0 && uid2User_[uid].cards[cardID] >= cardCnt, "invalid parameter");
        uint piecesCost = cardPiecesPrice[cardID-1].sub(cardPiecesPrice[cardID]).mul(cardCnt);
        require(uid2User_[uid].pieces >= piecesCost, "insufficient pieces");
        
        Objects.User storage user = uid2User_[uid];
        
        user.pieces = user.pieces.sub(piecesCost);
        user.cards[cardID] = user.cards[cardID].sub(cardCnt);
        user.cards[cardID-1] = user.cards[cardID-1].add(cardCnt);
        
        emit UpgradeCard(msg.sender, cardID, cardCnt, piecesCost);
        return true;
    }
    
    event SellCard(address indexed user, uint cardID, uint cardCnt, uint ymirAmount);
    function sellCard(uint cardID, uint cardCnt) public returns (bool) {
        playCnt_++;
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        require(cardID < 6 && uid2User_[uid].cards[cardID] >= cardCnt, "invalid parameter");

        Objects.User storage user = uid2User_[uid];

        user.cards[cardID] = user.cards[cardID].sub(cardCnt);
        uint tokenAmount = cardPiecesPrice[cardID].div(10).mul(cardCnt).mul(decimalVal);
        token.transferFrom(Owner, msg.sender, tokenAmount);
        
        SellCardTokenAmount = SellCardTokenAmount.add(tokenAmount);
        require(SellCardTokenAmount <= 2400000 * 1e6, "YMIR sell out");
        
        emit SellCard(msg.sender, cardID, cardCnt, tokenAmount);
        return true;       
    }
    
    // stake logic

    uint[15] public InviteRewardRate = [30, 20, 10, 8, 5, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1];
    
    function setInviteData(uint inviteeID, uint inviterID, uint amount, bool isNew, uint stakeAmount, bool isInc) internal returns (bool) {

        for(uint idx = 0; idx < InviteRewardRate.length && inviterID > 0 && inviterID != inviteeID; idx++) {
            uid2User_[inviterID].inviteInfo.inviteeAmount[idx] = uid2User_[inviterID].inviteInfo.inviteeAmount[idx].add(amount);
            if (isNew) {
                uid2User_[inviterID].inviteInfo.inviteeCnt[idx] = uid2User_[inviterID].inviteInfo.inviteeCnt[idx].add(1);
            }
            if (stakeAmount > 0) {
                if (isInc) {
                    uid2User_[inviterID].inviteInfo.inviteeStakeAmount = uid2User_[inviterID].inviteInfo.inviteeStakeAmount.add(stakeAmount);
                } else {
                    uid2User_[inviterID].inviteInfo.inviteeStakeAmount = uid2User_[inviterID].inviteInfo.inviteeStakeAmount.sub(stakeAmount);
                }
            }
            inviterID = uid2User_[inviterID].inviteInfo.inviterID;
        }
        return true;
    }
    
    function setInviteRewardData(uint inviteeID, uint inviterID, uint amount) internal returns (bool) {
        for(uint idx = 0; idx < InviteRewardRate.length && inviterID > 0 && inviterID != inviteeID; idx++) {
            uint reward = amount.mul(InviteRewardRate[idx]).div(100);
            StakeProfitReward = StakeProfitReward.add(reward);
            uid2User_[inviterID].inviteInfo.reward[idx] = uid2User_[inviterID].inviteInfo.reward[idx].add(reward);
            uid2User_[inviterID].withdrawableAmount = uid2User_[inviterID].withdrawableAmount.add(reward);
            
            inviterID = uid2User_[inviterID].inviteInfo.inviterID;
        }
        return true;
    }
    
    uint public StakeAmount;
    uint public StakeProfit;
    uint public StakeProfitReward;
    function stake(uint inviterID, uint amount) public returns (bool) {
        require(amount >= 100 * decimalVal, "invalid stake amount");
        uint uid = getUID(msg.sender);
        if (uid == 0) {
            uid = newUser(msg.sender);
        }
        require(uid > 0, "invalid user");
        if (inviterID > userCnt_ || inviterID == 0 || inviterID == uid) {
            inviterID = 1;
        }
        
        Objects.User storage user = uid2User_[uid];
        
        bool isNew = false;
        if (user.inviteInfo.inviterID == 0) {
            user.inviteInfo.inviterID = inviterID;
            isNew = true;
        }

        setInviteData(uid, user.inviteInfo.inviterID, 0, isNew, amount, true);
        
        if (stakeAmount(user.addr) > 0) {
            user.withdrawableAmount = user.withdrawableAmount.add(calcProfit(stakeAmount(user.addr), user.latestTime));
        }
        user.latestTime = block.timestamp;
        
        super._stake(amount);
        StakeAmount = StakeAmount.add(amount);
        
        return true;
    }
    
    function unstake(uint amount) public returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        
        Objects.User storage user = uid2User_[uid];
        
        if (stakeAmount(user.addr) > 0) {
            user.withdrawableAmount = user.withdrawableAmount.add(calcProfit(stakeAmount(user.addr), user.latestTime));
        }
        user.latestTime = block.timestamp;
        
        setInviteData(uid, user.inviteInfo.inviterID, 0, false, amount, false);
  
        super._unstake(amount);
        StakeAmount = StakeAmount.sub(amount);
    }

    function getReward() public returns (bool) {
        uint uid = getUID(msg.sender);
        require(uid > 0, "invalid user");
        
        Objects.User storage user = uid2User_[uid];
        require(block.timestamp >= user.lastWithdrawTime.add(3 days), "invalid getReward time");
        
        if (stakeAmount(user.addr) > 0) {
            user.withdrawableAmount = user.withdrawableAmount.add(calcProfit(stakeAmount(user.addr), user.latestTime));
        }
        user.latestTime = block.timestamp;
        user.lastWithdrawTime = block.timestamp;
        token.transferFrom(Owner, msg.sender, user.withdrawableAmount);
        user.withdrawedAmount = user.withdrawedAmount.add(user.withdrawableAmount);
        
        StakeProfit = StakeProfit.add(user.withdrawableAmount);
        require(StakeProfit <= 4800000 * 1e6, "YMIR pool empty");
        
        setInviteRewardData(uid, user.inviteInfo.inviterID, user.withdrawableAmount);

        user.withdrawableAmount = 0;
        
        return true;
    }
    
    function getStakeProfitPrice() public view returns (uint) {
        if (StakeAmount < 200000 * decimalVal) {
            return 10;
        } else if (StakeAmount >= 200000 * decimalVal && StakeAmount < 300000 * decimalVal) {
            return 15;
        } else if (StakeAmount >= 300000 * decimalVal && StakeAmount < 500000 * decimalVal) {
            return 20;
        } else if (StakeAmount >= 500000 * decimalVal && StakeAmount < 800000 * decimalVal) {
            return 25;
        } else if (StakeAmount >= 800000 * decimalVal && StakeAmount < 1000000 * decimalVal) {
            return 31;
        } else if (StakeAmount >= 1000000 * decimalVal && StakeAmount < 1500000 * decimalVal) {
            return 40;
        } else if (StakeAmount >= 1500000 * decimalVal && StakeAmount < 3000000 * decimalVal) {
            return 50;
        } else if (StakeAmount >= 3000000 * decimalVal && StakeAmount < 4000000 * decimalVal) {
            return 70;
        } else if (StakeAmount >= 4000000 * decimalVal) {
            return 80;
        }
    }
    
    function calcProfit(uint amount, uint startTime) internal view returns (uint) {
        uint price = getStakeProfitPrice();
        uint duration = block.timestamp.sub(startTime);
        if (duration == 0) {
            return 0;
        }
        return amount.mul(price).mul(duration).div(1 days).div(1000);
    }
    
}