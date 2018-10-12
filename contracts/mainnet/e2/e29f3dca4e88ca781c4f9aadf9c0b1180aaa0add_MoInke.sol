pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
//MoInke直播 contract
//
//MoInke黄金
// Symbol      : MIG
// Name        : MoInke Gold
// Total supply: 180,000
// Decimals    : 0
// 
//MoInke币
// Symbol      : MoInke
// Name        : MoInke Token
// Total supply: 100,000,000,000
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Admin contract
// ----------------------------------------------------------------------------
contract Administration {
    event AdminTransferred(address indexed _from, address indexed _to);
    event Pause();
    event Unpause();

    address public CEOAddress = 0x8153b50F7e7b23460E1d2652243bF93d0d1b614E;
    address public CFOAddress = 0x0BCB75C80101b88e1AC692b7FA0ED2Dd0c03d1DB;

    bool public paused = false;
    bool public allowed = false;

    modifier onlyCEO() {
        require(msg.sender == CEOAddress);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == CEOAddress || msg.sender == CFOAddress);
        _;
    }

    function setCFO(address _newAdmin) public onlyCEO {
        require(_newAdmin != address(0));
        emit AdminTransferred(CFOAddress, _newAdmin);
        CFOAddress = _newAdmin;
        
    }

    function withdrawBalance() external onlyAdmin {
        CEOAddress.transfer(address(this).balance);
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }
    
    modifier whenAllowed() {
        require(allowed);
        _;
    }
    
    modifier ifGoldTrans() {
        require(allowed || msg.sender == CEOAddress || msg.sender == CFOAddress);
        _;
    }

    function pause() public onlyAdmin whenNotPaused returns(bool) {
        paused = true;
        emit Pause();
        return true;
    }

    function unpause() public onlyAdmin whenPaused returns(bool) {
        paused = false;
        emit Unpause();
        return true;
    }
    
    function allow() public onlyAdmin {
        if(allowed == false) {
            allowed = true;
        } else {
            allowed = false;
        }
    }

    uint oneEth = 1 ether;
}

contract MoInkeGold is ERC20Interface, Administration, SafeMath {
    event GoldTransfer(address indexed from, address indexed to, uint tokens);
    
    string public goldSymbol;
    string public goldName;
    uint8 public goldDecimals;
    uint public _goldTotalSupply;

    mapping(address => uint) goldBalances;
    mapping(address => bool) goldFreezed;
    mapping(address => uint) goldFreezeAmount;
    mapping(address => uint) goldUnlockTime;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        goldSymbol = "MIG";
        goldName = "MoInke Gold";
        goldDecimals = 0;
        _goldTotalSupply = 180000;
        goldBalances[CEOAddress] = _goldTotalSupply;
        emit GoldTransfer(address(0), CEOAddress, _goldTotalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function goldTotalSupply() public constant returns (uint) {
        return _goldTotalSupply  - goldBalances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function goldBalanceOf(address tokenOwner) public constant returns (uint balance) {
        return goldBalances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function goldTransfer(address to, uint tokens) public ifGoldTrans returns (bool success) {
        if(goldFreezed[msg.sender] == false){
            goldBalances[msg.sender] = safeSub(goldBalances[msg.sender], tokens);
            goldBalances[to] = safeAdd(goldBalances[to], tokens);
            emit GoldTransfer(msg.sender, to, tokens);
        } else {
            if(goldBalances[msg.sender] > goldFreezeAmount[msg.sender]) {
                require(tokens <= safeSub(goldBalances[msg.sender], goldFreezeAmount[msg.sender]));
                goldBalances[msg.sender] = safeSub(goldBalances[msg.sender], tokens);
                goldBalances[to] = safeAdd(goldBalances[to], tokens);
                emit GoldTransfer(msg.sender, to, tokens);
            }
        }
            
        return true;
    }

    // ------------------------------------------------------------------------
    // Mint Tokens
    // ------------------------------------------------------------------------
    function mintGold(uint amount) public onlyCEO {
        goldBalances[msg.sender] = safeAdd(goldBalances[msg.sender], amount);
        _goldTotalSupply = safeAdd(_goldTotalSupply, amount);
    }

    // ------------------------------------------------------------------------
    // Burn Tokens
    // ------------------------------------------------------------------------
    function burnGold(uint amount) public onlyCEO {
        goldBalances[msg.sender] = safeSub(goldBalances[msg.sender], amount);
        _goldTotalSupply = safeSub(_goldTotalSupply, amount);
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function goldFreeze(address user, uint amount, uint period) public onlyAdmin {
        require(goldBalances[user] >= amount);
        goldFreezed[user] = true;
        goldUnlockTime[user] = uint(now) + period;
        goldFreezeAmount[user] = amount;
    }
    
    function _goldFreeze(uint amount) internal {
        require(goldFreezed[msg.sender] == false);
        require(goldBalances[msg.sender] >= amount);
        goldFreezed[msg.sender] = true;
        goldUnlockTime[msg.sender] = uint(-1);
        goldFreezeAmount[msg.sender] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function goldUnFreeze() public whenNotPaused {
        require(goldFreezed[msg.sender] == true);
        require(goldUnlockTime[msg.sender] < uint(now));
        goldFreezed[msg.sender] = false;
        goldFreezeAmount[msg.sender] = 0;
    }
    
    function _goldUnFreeze(uint _amount) internal {
        require(goldFreezed[msg.sender] == true);
        goldUnlockTime[msg.sender] = 0;
        goldFreezed[msg.sender] = false;
        goldFreezeAmount[msg.sender] = safeSub(goldFreezeAmount[msg.sender], _amount);
    }
    
    function goldIfFreeze(address user) public view returns (
        bool check, 
        uint amount, 
        uint timeLeft
    ) {
        check = goldFreezed[user];
        amount = goldFreezeAmount[user];
        timeLeft = goldUnlockTime[user] - uint(now);
    }

}

contract MoInkeToken is MoInkeGold {
    event PartnerCreated(uint indexed partnerId, address indexed partner, uint indexed amount, uint singleTrans, uint durance);
    event RewardDistribute(uint indexed postId, uint partnerId, address indexed user, uint indexed amount);
    
    event VipAgreementSign(uint indexed vipId, address indexed vip, uint durance, uint frequence, uint salar);
    event SalaryReceived(uint indexed vipId, address indexed vip, uint salary, uint indexed timestamp);
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public minePool; // 90%

    struct Partner {
        address admin;
        uint tokenPool;
        uint singleTrans;
        uint timestamp;
        uint durance;
    }
    
    struct Poster {
        address poster;
        bytes32 hashData;
        uint reward;
    }
    
    struct Vip {
        address vip;
        uint durance;
        uint frequence;
        uint salary;
        uint timestamp;
    }
    
    Partner[] partners;
    Vip[] vips;

    modifier onlyPartner(uint _partnerId) {
        require(partners[_partnerId].admin == msg.sender);
        require(partners[_partnerId].tokenPool > uint(0));
        uint deadline = safeAdd(partners[_partnerId].timestamp, partners[_partnerId].durance);
        require(deadline > now);
        _;
    }
    
    modifier onlyVip(uint _vipId) {
        require(vips[_vipId].vip == msg.sender);
        require(vips[_vipId].durance > now);
        require(vips[_vipId].timestamp < now);
        _;
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) freezed;
    mapping(address => uint) freezeAmount;
    mapping(address => uint) unlockTime;
    
    mapping(uint => Poster[]) PartnerIdToPosterList;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "MINK";
        name = "MoInke Token";
        decimals = 18;
        _totalSupply = 10000000000000000000000000000;
        minePool = 90000000000000000000000000000;
        
        balances[CEOAddress] = _totalSupply;
        emit Transfer(address(0), CEOAddress, _totalSupply);
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        if(freezed[msg.sender] == false){
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(msg.sender, to, tokens);
        } else {
            if(balances[msg.sender] > freezeAmount[msg.sender]) {
                require(tokens <= safeSub(balances[msg.sender], freezeAmount[msg.sender]));
                balances[msg.sender] = safeSub(balances[msg.sender], tokens);
                balances[to] = safeAdd(balances[to], tokens);
                emit Transfer(msg.sender, to, tokens);
            }
        }
            
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        require(freezed[msg.sender] != true);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        require(freezed[msg.sender] != true);
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        require(freezed[msg.sender] != true);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Mint Tokens
    // ------------------------------------------------------------------------
    function _mine(uint amount, address receiver) internal {
        require(minePool >= amount);
        minePool = safeSub(minePool, amount);
        _totalSupply = safeAdd(_totalSupply, amount);
        balances[receiver] = safeAdd(balances[receiver], amount);
        emit Transfer(address(0), receiver, amount);
    }
    
    function mint(uint amount) public onlyAdmin {
        _mine(amount, msg.sender);
    }
    
    function burn(uint amount) public onlyAdmin {
        require(_totalSupply >= amount);
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        _totalSupply = safeSub(_totalSupply, amount);
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function freeze(address user, uint amount, uint period) public onlyAdmin {
        require(balances[user] >= amount);
        freezed[user] = true;
        unlockTime[user] = uint(now) + period;
        freezeAmount[user] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function unFreeze() public whenNotPaused {
        require(freezed[msg.sender] == true);
        require(unlockTime[msg.sender] < uint(now));
        freezed[msg.sender] = false;
        freezeAmount[msg.sender] = 0;
    }
    
    function ifFreeze(address user) public view returns (
        bool check, 
        uint amount, 
        uint timeLeft
    ) {
        check = freezed[user];
        amount = freezeAmount[user];
        timeLeft = unlockTime[user] - uint(now);
    }
    
    // ------------------------------------------------------------------------
    // Partner Authorization
    // ------------------------------------------------------------------------
    function createPartner(address _partner, uint _amount, uint _singleTrans, uint _durance) public onlyAdmin returns (uint) {
        Partner memory _Partner = Partner({
            admin: _partner,
            tokenPool: _amount,
            singleTrans: _singleTrans,
            timestamp: uint(now),
            durance: _durance
        });
        uint newPartnerId = partners.push(_Partner) - 1;
        emit PartnerCreated(newPartnerId, _partner, _amount, _singleTrans, _durance);
        
        return newPartnerId;
    }
    
    function partnerTransfer(uint _partnerId, bytes32 _data, address _to, uint _amount) public onlyPartner(_partnerId) whenNotPaused returns (bool) {
        require(_amount <= partners[_partnerId].singleTrans);
        partners[_partnerId].tokenPool = safeSub(partners[_partnerId].tokenPool, _amount);
        Poster memory _Poster = Poster ({
           poster: _to,
           hashData: _data,
           reward: _amount
        });
        uint newPostId = PartnerIdToPosterList[_partnerId].push(_Poster) - 1;
        _mine(_amount, _to);
        emit RewardDistribute(newPostId, _partnerId, _to, _amount);
        return true;
    }
    
    function setPartnerPool(uint _partnerId, uint _amount) public onlyAdmin {
        partners[_partnerId].tokenPool = _amount;
    }
    
    function setPartnerDurance(uint _partnerId, uint _durance) public onlyAdmin {
        partners[_partnerId].durance = uint(now) + _durance;
    }
    
    function getPartnerInfo(uint _partnerId) public view returns (
        address admin,
        uint tokenPool,
        uint timeLeft
    ) {
        Partner memory _Partner = partners[_partnerId];
        admin = _Partner.admin;
        tokenPool = _Partner.tokenPool;
        if (_Partner.timestamp + _Partner.durance > uint(now)) {
            timeLeft = _Partner.timestamp + _Partner.durance - uint(now);
        } else {
            timeLeft = 0;
        }
        
    }

    function getPosterInfo(uint _partnerId, uint _posterId) public view returns (
        address poster,
        bytes32 hashData,
        uint reward
    ) {
        Poster memory _Poster = PartnerIdToPosterList[_partnerId][_posterId];
        poster = _Poster.poster;
        hashData = _Poster.hashData;
        reward = _Poster.reward;
    }

    // ------------------------------------------------------------------------
    // Vip Agreement
    // ------------------------------------------------------------------------
    function createVip(address _vip, uint _durance, uint _frequence, uint _salary) public onlyAdmin returns (uint) {
        Vip memory _Vip = Vip ({
           vip: _vip,
           durance: uint(now) + _durance,
           frequence: _frequence,
           salary: _salary,
           timestamp: now + _frequence
        });
        uint newVipId = vips.push(_Vip) - 1;
        emit VipAgreementSign(newVipId, _vip, _durance, _frequence, _salary);
        
        return newVipId;
    }
    
    function mineSalary(uint _vipId) public onlyVip(_vipId) whenNotPaused returns (bool) {
        Vip storage _Vip = vips[_vipId];
        _mine(_Vip.salary, _Vip.vip);
        _Vip.timestamp = safeAdd(_Vip.timestamp, _Vip.frequence);
        
        emit SalaryReceived(_vipId, _Vip.vip, _Vip.salary, _Vip.timestamp);
        return true;
    }
    
    function deleteVip(uint _vipId) public onlyAdmin {
        delete vips[_vipId];
    }
    
    function getVipInfo(uint _vipId) public view returns (
        address vip,
        uint durance,
        uint frequence,
        uint salary,
        uint nextSalary,
        string log
    ) {
        Vip memory _Vip = vips[_vipId];
        vip = _Vip.vip;
        durance = _Vip.durance;
        frequence = _Vip.frequence;
        salary = _Vip.salary;
        if(_Vip.timestamp >= uint(now)) {
            nextSalary = safeSub(_Vip.timestamp, uint(now));
            log = "Please Wait";
        } else {
            nextSalary = 0;
            log = "Pick Up Your Salary Now";
        }
    }

    // ------------------------------------------------------------------------
    // Accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyAdmin returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(CEOAddress, tokens);
    }
}

contract MoInke is MoInkeToken {
    event MembershipUpdate(address indexed member, uint indexed level);
    event MemberAllowance(address indexed member, uint indexed amount);
    event MembershipCancel(address indexed member);
    event InkeTradeCreated(uint indexed tradeId, bool indexed ifGold, uint gold, uint token);
    event TradeCancel(uint indexed tradeId);
    event TradeComplete(uint indexed tradeId, address indexed buyer, address indexed seller, uint gold, uint token);
    event Mine(address indexed miner, uint indexed salary);
    
    mapping (address => uint) MemberToLevel;
    mapping (address => uint) MemberToGold;
    mapping (address => uint) MemberToToken;
    mapping (address => uint) MemberToTime;
    mapping (address => uint) MemberToAllowance;
    
    uint public period = 15 days;
    
    uint public salary = 10000000000000000000000;
    
    struct InkeTrade {
        address seller;
        bool ifGold;
        uint gold;
        uint token;
    }
    
    function mine() public whenNotPaused {
        require(MemberToTime[msg.sender] < uint(now)); 
        uint amount = goldBalances[msg.sender];
        require(amount > 0);
        amount = salary*amount;
        _mine(amount, msg.sender);
        if (MemberToTime[msg.sender] == 0) {
            MemberToTime[msg.sender] = uint(now);
        }
        MemberToTime[msg.sender] = safeAdd(MemberToTime[msg.sender], period);
        emit Mine(msg.sender, amount);
    }
    
    InkeTrade[] inkeTrades;
    
    function createInkeTrade(bool _ifGold, uint _gold, uint _token) public whenAllowed returns (uint) {
        if(_ifGold) {
            require(goldBalances[msg.sender] >= _gold);
            goldBalances[msg.sender] = safeSub(goldBalances[msg.sender], _gold);
            MemberToGold[msg.sender] = _gold;
            InkeTrade memory Moinke = InkeTrade({
               seller: msg.sender,
               ifGold:_ifGold,
               gold: _gold,
               token: _token
            });
            uint newGoldTradeId = inkeTrades.push(Moinke) - 1;
            emit InkeTradeCreated(newGoldTradeId, _ifGold, _gold, _token);
            
            return newGoldTradeId;
        } else {
            require(balances[msg.sender] >= _token);
            balances[msg.sender] = safeSub(balances[msg.sender], _token);
            MemberToToken[msg.sender] = _token;
            InkeTrade memory _inke = InkeTrade({
               seller: msg.sender,
               ifGold:_ifGold,
               gold: _gold,
               token: _token
            });
            uint newTokenTradeId = inkeTrades.push(_inke) - 1;
            emit InkeTradeCreated(newTokenTradeId, _ifGold, _gold, _token);
            
            return newTokenTradeId;
        }
    }
    
    function cancelTrade(uint _tradeId) public whenAllowed {
        InkeTrade memory Moinke = inkeTrades[_tradeId];
        require(Moinke.seller == msg.sender);
        if(Moinke.ifGold){
            goldBalances[msg.sender] = safeAdd(goldBalances[msg.sender], Moinke.gold);
            MemberToGold[msg.sender] = 0;
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], Moinke.token);
            MemberToToken[msg.sender] = 0;
        }
        delete inkeTrades[_tradeId];
        emit TradeCancel(_tradeId);
    }
    
    function trade(uint _tradeId) public whenAllowed {
        InkeTrade memory Moinke = inkeTrades[_tradeId];
        if(Moinke.ifGold){
            goldBalances[msg.sender] = safeAdd(goldBalances[msg.sender], Moinke.gold);
            MemberToGold[Moinke.seller] = 0;
            transfer(Moinke.seller, Moinke.token);
            delete inkeTrades[_tradeId];
            emit TradeComplete(_tradeId, msg.sender, Moinke.seller, Moinke.gold, Moinke.token);
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], Moinke.token);
            MemberToToken[Moinke.seller] = 0;
            goldTransfer(Moinke.seller, Moinke.gold);
            delete inkeTrades[_tradeId];
            emit TradeComplete(_tradeId, msg.sender, Moinke.seller, Moinke.gold, Moinke.token);
        }
    }
    
    function setSalary(uint _salary) public onlyAdmin {
        salary = _salary;
    }
    
    function setPeriod(uint time) public onlyAdmin {
        period = time;
    }
    
    function getTrade(uint _tradeId) public view returns (
        address seller,
        bool ifGold,
        uint gold,
        uint token 
    ) {
        InkeTrade memory _inke = inkeTrades[_tradeId];
        seller = _inke.seller;
        ifGold = _inke.ifGold;
        gold = _inke.gold;
        token = _inke.token;
    }
    
    function WhoIsTheContractMaster() public pure returns (string) {
        return "Alexander The Exlosion";
    }
}