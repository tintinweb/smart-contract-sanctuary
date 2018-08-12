pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
//共识会 contract
//
//共识勋章：象征着你在共识会的地位和权利
//Anno Consensus Medal: Veni, Vidi, Vici
// 
// Symbol      : CPLD
// Name        : Anno Consensus
// Total supply: 1000000
// Decimals    : 0
// 
// 共识币：维护共识新纪元的基石
//Anno Consensus Coin: Caput, Anguli, Seclorum
// Symbol      : anno
// Name        : Anno Consensus Token
// Total supply: 1000000000
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

    address public adminAddress = 0xbd74Dec00Af1E745A21d5130928CD610BE963027;

    bool public paused = false;

    modifier onlyAdmin() {
        require(msg.sender == adminAddress);
        _;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0));
        AdminTransferred(adminAddress, _newAdmin);
        adminAddress = _newAdmin;
        
    }

    function withdrawBalance() external onlyAdmin {
        adminAddress.transfer(this.balance);
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
        Pause();
        return true;
    }

    function unpause() public onlyAdmin whenPaused returns(bool) {
        paused = false;
        Unpause();
        return true;
    }

    uint oneEth = 1 ether;
}

contract AnnoMedal is ERC20Interface, Administration, SafeMath {
    event MedalTransfer(address indexed from, address indexed to, uint tokens);
    
    string public medalSymbol;
    string public medalName;
    uint8 public medalDecimals;
    uint public _medalTotalSupply;

    mapping(address => uint) medalBalances;
    mapping(address => bool) medalFreezed;
    mapping(address => uint) medalFreezeAmount;
    mapping(address => uint) medalUnlockTime;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function AnnoMedal() public {
        medalSymbol = "CPLD";
        medalName = "Anno Medal";
        medalDecimals = 0;
        _medalTotalSupply = 1000000;
        medalBalances[adminAddress] = _medalTotalSupply;
        MedalTransfer(address(0), adminAddress, _medalTotalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function medalTotalSupply() public constant returns (uint) {
        return _medalTotalSupply  - medalBalances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function medalBalanceOf(address tokenOwner) public constant returns (uint balance) {
        return medalBalances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function medalTransfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        if(medalFreezed[msg.sender] == false){
            medalBalances[msg.sender] = safeSub(medalBalances[msg.sender], tokens);
            medalBalances[to] = safeAdd(medalBalances[to], tokens);
            MedalTransfer(msg.sender, to, tokens);
        } else {
            if(medalBalances[msg.sender] > medalFreezeAmount[msg.sender]) {
                require(tokens <= safeSub(medalBalances[msg.sender], medalFreezeAmount[msg.sender]));
                medalBalances[msg.sender] = safeSub(medalBalances[msg.sender], tokens);
                medalBalances[to] = safeAdd(medalBalances[to], tokens);
                MedalTransfer(msg.sender, to, tokens);
            }
        }
            
        return true;
    }

    // ------------------------------------------------------------------------
    // Mint Tokens
    // ------------------------------------------------------------------------
    function mintMedal(uint amount) public onlyAdmin {
        medalBalances[msg.sender] = safeAdd(medalBalances[msg.sender], amount);
        _medalTotalSupply = safeAdd(_medalTotalSupply, amount);
    }

    // ------------------------------------------------------------------------
    // Burn Tokens
    // ------------------------------------------------------------------------
    function burnMedal(uint amount) public onlyAdmin {
        medalBalances[msg.sender] = safeSub(medalBalances[msg.sender], amount);
        _medalTotalSupply = safeSub(_medalTotalSupply, amount);
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function medalFreeze(address user, uint amount, uint period) public onlyAdmin {
        require(medalBalances[user] >= amount);
        medalFreezed[user] = true;
        medalUnlockTime[user] = uint(now) + period;
        medalFreezeAmount[user] = amount;
    }
    
    function _medalFreeze(uint amount) internal {
        require(medalFreezed[msg.sender] == false);
        require(medalBalances[msg.sender] >= amount);
        medalFreezed[msg.sender] = true;
        medalUnlockTime[msg.sender] = uint(-1);
        medalFreezeAmount[msg.sender] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function medalUnFreeze() public whenNotPaused {
        require(medalFreezed[msg.sender] == true);
        require(medalUnlockTime[msg.sender] < uint(now));
        medalFreezed[msg.sender] = false;
        medalFreezeAmount[msg.sender] = 0;
    }
    
    function _medalUnFreeze(uint _amount) internal {
        require(medalFreezed[msg.sender] == true);
        medalUnlockTime[msg.sender] = 0;
        medalFreezed[msg.sender] = false;
        medalFreezeAmount[msg.sender] = safeSub(medalFreezeAmount[msg.sender], _amount);
    }
    
    function medalIfFreeze(address user) public view returns (
        bool check, 
        uint amount, 
        uint timeLeft
    ) {
        check = medalFreezed[user];
        amount = medalFreezeAmount[user];
        timeLeft = medalUnlockTime[user] - uint(now);
    }

}

contract AnnoToken is AnnoMedal {
    event PartnerCreated(uint indexed partnerId, address indexed partner, uint indexed amount, uint singleTrans, uint durance);
    event RewardDistribute(uint indexed postId, uint partnerId, address indexed user, uint indexed amount);
    
    event VipAgreementSign(uint indexed vipId, address indexed vip, uint durance, uint frequence, uint salar);
    event SalaryReceived(uint indexed vipId, address indexed vip, uint salary, uint indexed timestamp);
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public minePool;

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
    function AnnoToken() public {
        symbol = "anno";
        name = "Anno Token";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        minePool = 60000000000000000000000000000;
        balances[adminAddress] = _totalSupply - minePool;
        Transfer(address(0), adminAddress, _totalSupply);
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
            Transfer(msg.sender, to, tokens);
        } else {
            if(balances[msg.sender] > freezeAmount[msg.sender]) {
                require(tokens <= safeSub(balances[msg.sender], freezeAmount[msg.sender]));
                balances[msg.sender] = safeSub(balances[msg.sender], tokens);
                balances[to] = safeAdd(balances[to], tokens);
                Transfer(msg.sender, to, tokens);
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
        Approval(msg.sender, spender, tokens);
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
        Transfer(from, to, tokens);
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
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Mint Tokens
    // ------------------------------------------------------------------------
    function _mint(uint amount, address receiver) internal {
        require(minePool >= amount);
        minePool = safeSub(minePool, amount);
        balances[receiver] = safeAdd(balances[receiver], amount);
        Transfer(address(0), receiver, amount);
    }
    
    function mint(uint amount) public onlyAdmin {
        require(minePool >= amount);
        minePool = safeSub(minePool, amount);
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);
        _totalSupply = safeAdd(_totalSupply, amount);
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
    function unFreeze() public {
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
        PartnerCreated(newPartnerId, _partner, _amount, _singleTrans, _durance);
        
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
        _mint(_amount, _to);
        RewardDistribute(newPostId, _partnerId, _to, _amount);
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
        VipAgreementSign(newVipId, _vip, _durance, _frequence, _salary);
        
        return newVipId;
    }
    
    function mineSalary(uint _vipId) public onlyVip(_vipId) whenNotPaused returns (bool) {
        Vip storage _Vip = vips[_vipId];
        _mint(_Vip.salary, _Vip.vip);
        _Vip.timestamp = safeAdd(_Vip.timestamp, _Vip.frequence);
        
        SalaryReceived(_vipId, _Vip.vip, _Vip.salary, _Vip.timestamp);
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
        return ERC20Interface(tokenAddress).transfer(adminAddress, tokens);
    }
}

contract Anno is AnnoToken {
    event MembershipUpdate(address indexed member, uint indexed level);
    event MembershipCancel(address indexed member);
    event AnnoTradeCreated(uint indexed tradeId, bool indexed ifMedal, uint medal, uint token);
    event TradeCancel(uint indexed tradeId);
    event TradeComplete(uint indexed tradeId, address indexed buyer, address indexed seller, uint medal, uint token);
    event Mine(address indexed miner, uint indexed salary);
    
    mapping (address => uint) MemberToLevel;
    mapping (address => uint) MemberToMedal;
    mapping (address => uint) MemberToToken;
    mapping (address => uint) MemberToTime;
    
    uint public period = 14 days;
    
    uint[5] public boardMember =[
        0,
        500,
        2500,
        25000,
        50000
    ];
    
    uint[5] public salary = [
        0,
        1151000000000000000000,
        5753000000000000000000,
        57534000000000000000000,
        115068000000000000000000
    ];
    
    struct AnnoTrade {
        address seller;
        bool ifMedal;
        uint medal;
        uint token;
    }
    
    AnnoTrade[] annoTrades;
    
    function boardMemberApply(uint _level) public whenNotPaused {
        require(_level > 0 && _level <= 4);
        require(medalBalances[msg.sender] >= boardMember[_level]);
        _medalFreeze(boardMember[_level]);
        MemberToLevel[msg.sender] = _level;
        if(MemberToTime[msg.sender] == 0) {
            MemberToTime[msg.sender] = uint(now);
        }
        
        MembershipUpdate(msg.sender, _level);
    }
    
    function getBoardMember(address _member) public view returns (
        uint level,
        uint timeLeft
    ) {
        level = MemberToLevel[_member];
        if(MemberToTime[_member] > uint(now)) {
            timeLeft = safeSub(MemberToTime[_member], uint(now));
        } else {
            timeLeft = 0;
        }
    }
    
    function boardMemberCancel() public whenNotPaused {
        require(MemberToLevel[msg.sender] > 0);
        _medalUnFreeze(boardMember[MemberToLevel[msg.sender]]);
        
        MemberToLevel[msg.sender] = 0;
        MembershipCancel(msg.sender);
    }
    
    function createAnnoTrade(bool _ifMedal, uint _medal, uint _token) public whenNotPaused returns (uint) {
        if(_ifMedal) {
            require(medalBalances[msg.sender] >= _medal);
            medalBalances[msg.sender] = safeSub(medalBalances[msg.sender], _medal);
            MemberToMedal[msg.sender] = _medal;
            AnnoTrade memory anno = AnnoTrade({
               seller: msg.sender,
               ifMedal:_ifMedal,
               medal: _medal,
               token: _token
            });
            uint newMedalTradeId = annoTrades.push(anno) - 1;
            AnnoTradeCreated(newMedalTradeId, _ifMedal, _medal, _token);
            
            return newMedalTradeId;
        } else {
            require(balances[msg.sender] >= _token);
            balances[msg.sender] = safeSub(balances[msg.sender], _token);
            MemberToToken[msg.sender] = _token;
            AnnoTrade memory _anno = AnnoTrade({
               seller: msg.sender,
               ifMedal:_ifMedal,
               medal: _medal,
               token: _token
            });
            uint newTokenTradeId = annoTrades.push(_anno) - 1;
            AnnoTradeCreated(newTokenTradeId, _ifMedal, _medal, _token);
            
            return newTokenTradeId;
        }
    }
    
    function cancelTrade(uint _tradeId) public whenNotPaused {
        AnnoTrade memory anno = annoTrades[_tradeId];
        require(anno.seller == msg.sender);
        if(anno.ifMedal){
            medalBalances[msg.sender] = safeAdd(medalBalances[msg.sender], anno.medal);
            MemberToMedal[msg.sender] = 0;
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], anno.token);
            MemberToToken[msg.sender] = 0;
        }
        delete annoTrades[_tradeId];
        TradeCancel(_tradeId);
    }
    
    function trade(uint _tradeId) public whenNotPaused {
        AnnoTrade memory anno = annoTrades[_tradeId];
        if(anno.ifMedal){
            medalBalances[msg.sender] = safeAdd(medalBalances[msg.sender], anno.medal);
            MemberToMedal[anno.seller] = 0;
            transfer(anno.seller, anno.token);
            delete annoTrades[_tradeId];
            TradeComplete(_tradeId, msg.sender, anno.seller, anno.medal, anno.token);
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], anno.token);
            MemberToToken[anno.seller] = 0;
            medalTransfer(anno.seller, anno.medal);
            delete annoTrades[_tradeId];
            TradeComplete(_tradeId, msg.sender, anno.seller, anno.medal, anno.token);
        }
    }
    
    function mine() public whenNotPaused {
        uint level = MemberToLevel[msg.sender];
        require(MemberToTime[msg.sender] < uint(now)); 
        require(level > 0);
        _mint(salary[level], msg.sender);
        MemberToTime[msg.sender] = safeAdd(MemberToTime[msg.sender], period);
        Mine(msg.sender, salary[level]);
    }
    
    function setBoardMember(uint one, uint two, uint three, uint four) public onlyAdmin {
        boardMember[1] = one;
        boardMember[2] = two;
        boardMember[3] = three;
        boardMember[4] = four;
    }
    
    function setSalary(uint one, uint two, uint three, uint four) public onlyAdmin {
        salary[1] = one;
        salary[2] = two;
        salary[3] = three;
        salary[4] = four;
    }
    
    function setPeriod(uint time) public onlyAdmin {
        period = time;
    }
    
    function getTrade(uint _tradeId) public view returns (
        address seller,
        bool ifMedal,
        uint medal,
        uint token 
    ) {
        AnnoTrade memory _anno = annoTrades[_tradeId];
        seller = _anno.seller;
        ifMedal = _anno.ifMedal;
        medal = _anno.medal;
        token = _anno.token;
    }
    
    function WhoIsTheContractMaster() public pure returns (string) {
        return "Alexander The Exlosion";
    }
}