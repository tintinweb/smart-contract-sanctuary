pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
//喜马拉雅交易所 contract
//
//喜马拉雅荣耀
// Symbol      : XMH
// Name        : XiMaLaYa Honor
// Total supply: 1000
// Decimals    : 0
// 
//喜马拉雅币
// Symbol      : XMLY
// Name        : XiMaLaYa Token
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

    address public CEOAddress = 0x5B807E379170d42f3B099C01A5399a2e1e58963B;
    address public CFOAddress = 0x92cFfCD79E6Ab6B16C7AFb96fbC0a2373bE516A4;

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
        AdminTransferred(CFOAddress, _newAdmin);
        CFOAddress = _newAdmin;
        
    }

    function withdrawBalance() external onlyAdmin {
        CEOAddress.transfer(this.balance);
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

contract XMLYBadge is ERC20Interface, Administration, SafeMath {
    event BadgeTransfer(address indexed from, address indexed to, uint tokens);
    
    string public badgeSymbol;
    string public badgeName;
    uint8 public badgeDecimals;
    uint public _badgeTotalSupply;

    mapping(address => uint) badgeBalances;
    mapping(address => bool) badgeFreezed;
    mapping(address => uint) badgeFreezeAmount;
    mapping(address => uint) badgeUnlockTime;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function XMLYBadge() public {
        badgeSymbol = "XMH";
        badgeName = "XMLY Honor";
        badgeDecimals = 0;
        _badgeTotalSupply = 1000;
        badgeBalances[CFOAddress] = _badgeTotalSupply;
        BadgeTransfer(address(0), CFOAddress, _badgeTotalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function badgeTotalSupply() public constant returns (uint) {
        return _badgeTotalSupply  - badgeBalances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function badgeBalanceOf(address tokenOwner) public constant returns (uint balance) {
        return badgeBalances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function badgeTransfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        if(badgeFreezed[msg.sender] == false){
            badgeBalances[msg.sender] = safeSub(badgeBalances[msg.sender], tokens);
            badgeBalances[to] = safeAdd(badgeBalances[to], tokens);
            BadgeTransfer(msg.sender, to, tokens);
        } else {
            if(badgeBalances[msg.sender] > badgeFreezeAmount[msg.sender]) {
                require(tokens <= safeSub(badgeBalances[msg.sender], badgeFreezeAmount[msg.sender]));
                badgeBalances[msg.sender] = safeSub(badgeBalances[msg.sender], tokens);
                badgeBalances[to] = safeAdd(badgeBalances[to], tokens);
                BadgeTransfer(msg.sender, to, tokens);
            }
        }
            
        return true;
    }

    // ------------------------------------------------------------------------
    // Mint Tokens
    // ------------------------------------------------------------------------
    function mintBadge(uint amount) public onlyAdmin {
        badgeBalances[msg.sender] = safeAdd(badgeBalances[msg.sender], amount);
        _badgeTotalSupply = safeAdd(_badgeTotalSupply, amount);
    }

    // ------------------------------------------------------------------------
    // Burn Tokens
    // ------------------------------------------------------------------------
    function burnBadge(uint amount) public onlyAdmin {
        badgeBalances[msg.sender] = safeSub(badgeBalances[msg.sender], amount);
        _badgeTotalSupply = safeSub(_badgeTotalSupply, amount);
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function badgeFreeze(address user, uint amount, uint period) public onlyAdmin {
        require(badgeBalances[user] >= amount);
        badgeFreezed[user] = true;
        badgeUnlockTime[user] = uint(now) + period;
        badgeFreezeAmount[user] = amount;
    }
    
    function _badgeFreeze(uint amount) internal {
        require(badgeFreezed[msg.sender] == false);
        require(badgeBalances[msg.sender] >= amount);
        badgeFreezed[msg.sender] = true;
        badgeUnlockTime[msg.sender] = uint(-1);
        badgeFreezeAmount[msg.sender] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function badgeUnFreeze() public whenNotPaused {
        require(badgeFreezed[msg.sender] == true);
        require(badgeUnlockTime[msg.sender] < uint(now));
        badgeFreezed[msg.sender] = false;
        badgeFreezeAmount[msg.sender] = 0;
    }
    
    function _badgeUnFreeze(uint _amount) internal {
        require(badgeFreezed[msg.sender] == true);
        badgeUnlockTime[msg.sender] = 0;
        badgeFreezed[msg.sender] = false;
        badgeFreezeAmount[msg.sender] = safeSub(badgeFreezeAmount[msg.sender], _amount);
    }
    
    function badgeIfFreeze(address user) public view returns (
        bool check, 
        uint amount, 
        uint timeLeft
    ) {
        check = badgeFreezed[user];
        amount = badgeFreezeAmount[user];
        timeLeft = badgeUnlockTime[user] - uint(now);
    }

}

contract XMLYToken is XMLYBadge {
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
    function XMLYToken() public {
        symbol = "XMLY";
        name = "XMLY Token";
        decimals = 18;
        _totalSupply = 5000000000000000000000000000;
        minePool = 95000000000000000000000000000;
        balances[CFOAddress] = _totalSupply;
        Transfer(address(0), CFOAddress, _totalSupply);
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
        _totalSupply = safeAdd(_totalSupply, amount);
        balances[receiver] = safeAdd(balances[receiver], amount);
        Transfer(address(0), receiver, amount);
    }
    
    function mint(uint amount) public onlyAdmin {
        require(minePool >= amount);
        minePool = safeSub(minePool, amount);
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);
        _totalSupply = safeAdd(_totalSupply, amount);
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
        return ERC20Interface(tokenAddress).transfer(CEOAddress, tokens);
    }
}

contract XMLY is XMLYToken {
    event MembershipUpdate(address indexed member, uint indexed level);
    event MembershipCancel(address indexed member);
    event XMLYTradeCreated(uint indexed tradeId, bool indexed ifBadge, uint badge, uint token);
    event TradeCancel(uint indexed tradeId);
    event TradeComplete(uint indexed tradeId, address indexed buyer, address indexed seller, uint badge, uint token);
    event Mine(address indexed miner, uint indexed salary);
    
    mapping (address => uint) MemberToLevel;
    mapping (address => uint) MemberToBadge;
    mapping (address => uint) MemberToToken;
    mapping (address => uint) MemberToTime;
    
    uint public period = 30 days;
    
    uint[5] public boardMember =[
        0,
        1,
        10
    ];
    
    uint[5] public salary = [
        0,
        10000000000000000000000,
        100000000000000000000000
    ];
    
    struct XMLYTrade {
        address seller;
        bool ifBadge;
        uint badge;
        uint token;
    }
    
    XMLYTrade[] xmlyTrades;
    
    function boardMemberApply(uint _level) public whenNotPaused {
        require(_level > 0 && _level <= 4);
        require(badgeBalances[msg.sender] >= boardMember[_level]);
        _badgeFreeze(boardMember[_level]);
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
        _badgeUnFreeze(boardMember[MemberToLevel[msg.sender]]);
        
        MemberToLevel[msg.sender] = 0;
        MembershipCancel(msg.sender);
    }
    
    function createXMLYTrade(bool _ifBadge, uint _badge, uint _token) public whenNotPaused returns (uint) {
        if(_ifBadge) {
            require(badgeBalances[msg.sender] >= _badge);
            badgeBalances[msg.sender] = safeSub(badgeBalances[msg.sender], _badge);
            MemberToBadge[msg.sender] = _badge;
            XMLYTrade memory xmly = XMLYTrade({
               seller: msg.sender,
               ifBadge:_ifBadge,
               badge: _badge,
               token: _token
            });
            uint newBadgeTradeId = xmlyTrades.push(xmly) - 1;
            XMLYTradeCreated(newBadgeTradeId, _ifBadge, _badge, _token);
            
            return newBadgeTradeId;
        } else {
            require(balances[msg.sender] >= _token);
            balances[msg.sender] = safeSub(balances[msg.sender], _token);
            MemberToToken[msg.sender] = _token;
            XMLYTrade memory _xmly = XMLYTrade({
               seller: msg.sender,
               ifBadge:_ifBadge,
               badge: _badge,
               token: _token
            });
            uint newTokenTradeId = xmlyTrades.push(_xmly) - 1;
            XMLYTradeCreated(newTokenTradeId, _ifBadge, _badge, _token);
            
            return newTokenTradeId;
        }
    }
    
    function cancelTrade(uint _tradeId) public whenNotPaused {
        XMLYTrade memory xmly = xmlyTrades[_tradeId];
        require(xmly.seller == msg.sender);
        if(xmly.ifBadge){
            badgeBalances[msg.sender] = safeAdd(badgeBalances[msg.sender], xmly.badge);
            MemberToBadge[msg.sender] = 0;
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], xmly.token);
            MemberToToken[msg.sender] = 0;
        }
        delete xmlyTrades[_tradeId];
        TradeCancel(_tradeId);
    }
    
    function trade(uint _tradeId) public whenNotPaused {
        XMLYTrade memory xmly = xmlyTrades[_tradeId];
        if(xmly.ifBadge){
            badgeBalances[msg.sender] = safeAdd(badgeBalances[msg.sender], xmly.badge);
            MemberToBadge[xmly.seller] = 0;
            transfer(xmly.seller, xmly.token);
            delete xmlyTrades[_tradeId];
            TradeComplete(_tradeId, msg.sender, xmly.seller, xmly.badge, xmly.token);
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], xmly.token);
            MemberToToken[xmly.seller] = 0;
            badgeTransfer(xmly.seller, xmly.badge);
            delete xmlyTrades[_tradeId];
            TradeComplete(_tradeId, msg.sender, xmly.seller, xmly.badge, xmly.token);
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
    
    function setBoardMember(uint one, uint two) public onlyAdmin {
        boardMember[1] = one;
        boardMember[2] = two;
    }
    
    function setSalary(uint one, uint two) public onlyAdmin {
        salary[1] = one;
        salary[2] = two;
    }
    
    function setPeriod(uint time) public onlyAdmin {
        period = time;
    }
    
    function getTrade(uint _tradeId) public view returns (
        address seller,
        bool ifBadge,
        uint badge,
        uint token 
    ) {
        XMLYTrade memory _xmly = xmlyTrades[_tradeId];
        seller = _xmly.seller;
        ifBadge = _xmly.ifBadge;
        badge = _xmly.badge;
        token = _xmly.token;
    }
    
    function WhoIsTheContractMaster() public pure returns (string) {
        return "Alexander The Exlosion";
    }
}