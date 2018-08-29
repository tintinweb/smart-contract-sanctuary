pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
//Inke直播 contract
//
//Inke黄金
// Symbol      : IKG
// Name        : Inke Gold
// Total supply: 45000
// Decimals    : 0
// 
//Inke币
// Symbol      : Inke
// Name        : Inke Token
// Total supply: 100000000000
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

    address public CEOAddress = 0xDc08d076b65c3d876Bb2369b167Dc304De4b9677;
    address public CFOAddress = 0x4Ea72110C00f416963D34A7FECbF0FCDd306D15A;

    bool public paused = false;

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

    uint oneEth = 1 ether;
}

contract InkeGold is ERC20Interface, Administration, SafeMath {
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
        goldSymbol = "IKG";
        goldName = "Inke Gold";
        goldDecimals = 0;
        _goldTotalSupply = 45000;
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
    function goldTransfer(address to, uint tokens) public whenNotPaused returns (bool success) {
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

contract InkeToken is InkeGold {
    event PartnerCreated(uint indexed partnerId, address indexed partner, uint indexed amount, uint singleTrans, uint durance);
    event RewardDistribute(uint indexed postId, uint partnerId, address indexed user, uint indexed amount);
    
    event VipAgreementSign(uint indexed vipId, address indexed vip, uint durance, uint frequence, uint salar);
    event SalaryReceived(uint indexed vipId, address indexed vip, uint salary, uint indexed timestamp);
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public minePool; // 60%
    uint public fundPool; // 30%

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
        symbol = "Inke";
        name = "Inke Token";
        decimals = 18;
        _totalSupply = 10000000000000000000000000000;
        minePool = 60000000000000000000000000000;
        fundPool = 30000000000000000000000000000;
        
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
    
    function _fund(uint amount, address receiver) internal {
        require(fundPool >= amount);
        fundPool = safeSub(fundPool, amount);
        _totalSupply = safeAdd(_totalSupply, amount);
        balances[receiver] = safeAdd(balances[receiver], amount);
        emit Transfer(address(0), receiver, amount);
    }
    
    function mint(uint amount) public onlyAdmin {
        _fund(amount, msg.sender);
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
        _fund(_amount, _to);
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
        _fund(_Vip.salary, _Vip.vip);
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

contract Inke is InkeToken {
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
    mapping (address => address) MemberToBoss;
    mapping (address => uint) MemberToAllowance;
    
    uint public period = 30 days;
    uint leaseTimeI = uint(now) + 388 days;
    uint leaseTimeII = uint(now) + 99 days;
    
    uint[4] public boardSpot = [
        0,
        20000,
        1000,
        100
    ];
    
    uint[4] public boardMember =[
        0,
        1,
        10,
        100
    ];
    
    uint[4] public salary = [
        0,
        27397000000000000000000,
        273970000000000000000000,
        2739700000000000000000000
    ];
    
    struct InkeTrade {
        address seller;
        bool ifGold;
        uint gold;
        uint token;
    }
    
    InkeTrade[] inkeTrades;
    
    function boardMemberApply(uint _level) public whenNotPaused {
        require(_level > 0 && _level <= 3);
        require(boardSpot[_level] > 0);
        require(goldBalances[msg.sender] >= boardMember[_level]);
        _goldFreeze(boardMember[_level]);
        MemberToLevel[msg.sender] = _level;
        if(MemberToTime[msg.sender] == 0) {
            MemberToTime[msg.sender] = uint(now);
        }
        boardSpot[_level]--;
        emit MembershipUpdate(msg.sender, _level);
    }
    
    function giveMemberAllowance(address _member, uint _amount) public onlyAdmin {
        MemberToAllowance[_member] = safeAdd(MemberToAllowance[_member], _amount);
        emit MemberAllowance(_member, _amount);
    }
    
    function assignSubMember(address _subMember, uint _level) public whenNotPaused {
        require(_level > 0 && _level < 3);
        require(MemberToAllowance[msg.sender] >= boardMember[_level]);
        MemberToAllowance[msg.sender] = MemberToAllowance[msg.sender] - boardMember[_level];
        MemberToLevel[_subMember] = _level;
        if(MemberToTime[_subMember] == 0) {
            MemberToTime[_subMember] = uint(now);
        }
        MemberToBoss[_subMember] = msg.sender;
        boardSpot[_level]--;
        
        emit MembershipUpdate(_subMember, _level);
    }
    
    function getBoardMember(address _member) public view returns (
        uint level,
        uint allowance,
        uint timeLeft
    ) {
        level = MemberToLevel[_member];
        allowance = MemberToAllowance[_member];
        if(MemberToTime[_member] > uint(now)) {
            timeLeft = safeSub(MemberToTime[_member], uint(now));
        } else {
            timeLeft = 0;
        }
    }
    
    function getMemberBoss(address _member) public view returns (address) {
        return MemberToBoss[_member];
    }
    
    function boardMemberCancel() public whenNotPaused {
        uint level = MemberToLevel[msg.sender];
        require(level > 0);
        if(level == 1) {
            require(leaseTimeII < uint(now));
        } else {
            require(leaseTimeI < uint(now));
        }
        _goldUnFreeze(boardMember[MemberToLevel[msg.sender]]);
        
        boardSpot[level]++;
        MemberToLevel[msg.sender] = 0;
        emit MembershipCancel(msg.sender);
    }
    
    function createInkeTrade(bool _ifGold, uint _gold, uint _token) public whenNotPaused returns (uint) {
        if(_ifGold) {
            require(goldBalances[msg.sender] >= _gold);
            goldBalances[msg.sender] = safeSub(goldBalances[msg.sender], _gold);
            MemberToGold[msg.sender] = _gold;
            InkeTrade memory inke = InkeTrade({
               seller: msg.sender,
               ifGold:_ifGold,
               gold: _gold,
               token: _token
            });
            uint newGoldTradeId = inkeTrades.push(inke) - 1;
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
    
    function cancelTrade(uint _tradeId) public whenNotPaused {
        InkeTrade memory inke = inkeTrades[_tradeId];
        require(inke.seller == msg.sender);
        if(inke.ifGold){
            goldBalances[msg.sender] = safeAdd(goldBalances[msg.sender], inke.gold);
            MemberToGold[msg.sender] = 0;
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], inke.token);
            MemberToToken[msg.sender] = 0;
        }
        delete inkeTrades[_tradeId];
        emit TradeCancel(_tradeId);
    }
    
    function trade(uint _tradeId) public whenNotPaused {
        InkeTrade memory inke = inkeTrades[_tradeId];
        if(inke.ifGold){
            goldBalances[msg.sender] = safeAdd(goldBalances[msg.sender], inke.gold);
            MemberToGold[inke.seller] = 0;
            transfer(inke.seller, inke.token);
            delete inkeTrades[_tradeId];
            emit TradeComplete(_tradeId, msg.sender, inke.seller, inke.gold, inke.token);
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], inke.token);
            MemberToToken[inke.seller] = 0;
            goldTransfer(inke.seller, inke.gold);
            delete inkeTrades[_tradeId];
            emit TradeComplete(_tradeId, msg.sender, inke.seller, inke.gold, inke.token);
        }
    }
    
    function mine() public whenNotPaused {
        uint level = MemberToLevel[msg.sender];
        require(MemberToTime[msg.sender] < uint(now)); 
        require(level > 0);
        _mine(salary[level], msg.sender);
        MemberToTime[msg.sender] = safeAdd(MemberToTime[msg.sender], period);
        emit Mine(msg.sender, salary[level]);
    }
    
    function setBoardMember(uint one, uint two, uint three) public onlyAdmin {
        boardMember[1] = one;
        boardMember[2] = two;
        boardMember[3] = three;
    }
    
    function setSalary(uint one, uint two, uint three) public onlyAdmin {
        salary[1] = one;
        salary[2] = two;
        salary[3] = three;
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