pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// PinMo contract
// 
// Symbol      : PMC
// Name        : PinMo Crown
// Total supply: 100,000
// Decimals    : 0
// 
// Symbol      : PMT
// Name        : PinMo Token
// Total supply: 273,000,000
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
    
    address public adminAddress = 0x9d3177a1363702682EA8913Cb4A8a0FBDa00Ba75;

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

contract PinMoCrown is ERC20Interface, Administration, SafeMath {
    event CrownTransfer(address indexed from, address indexed to, uint tokens);
    
    string public crownSymbol;
    string public crownName;
    uint8 public crownDecimals;
    uint public _crownTotalSupply;

    mapping(address => uint) crownBalances;
    mapping(address => bool) crownFreezed;
    mapping(address => uint) crownFreezeAmount;
    mapping(address => uint) crownUnlockTime;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function PinMoCrown() public {
        crownSymbol = "PMC";
        crownName = "PinMo Crown";
        crownDecimals = 0;
        _crownTotalSupply = 100000;
        crownBalances[adminAddress] = _crownTotalSupply;
        CrownTransfer(address(0), adminAddress, _crownTotalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function crownTotalSupply() public constant returns (uint) {
        return _crownTotalSupply  - crownBalances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function crownBalanceOf(address tokenOwner) public constant returns (uint balance) {
        return crownBalances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function crownTransfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        if(crownFreezed[msg.sender] == false){
            crownBalances[msg.sender] = safeSub(crownBalances[msg.sender], tokens);
            crownBalances[to] = safeAdd(crownBalances[to], tokens);
            CrownTransfer(msg.sender, to, tokens);
        } else {
            if(crownBalances[msg.sender] > crownFreezeAmount[msg.sender]) {
                require(tokens <= safeSub(crownBalances[msg.sender], crownFreezeAmount[msg.sender]));
                crownBalances[msg.sender] = safeSub(crownBalances[msg.sender], tokens);
                crownBalances[to] = safeAdd(crownBalances[to], tokens);
                CrownTransfer(msg.sender, to, tokens);
            }
        }
            
        return true;
    }

    // ------------------------------------------------------------------------
    // Mint Tokens
    // ------------------------------------------------------------------------
    function mintCrown(uint amount) public onlyAdmin {
        crownBalances[msg.sender] = safeAdd(crownBalances[msg.sender], amount);
        _crownTotalSupply = safeAdd(_crownTotalSupply, amount);
    }

    // ------------------------------------------------------------------------
    // Burn Tokens
    // ------------------------------------------------------------------------
    function burnCrown(uint amount) public onlyAdmin {
        crownBalances[msg.sender] = safeSub(crownBalances[msg.sender], amount);
        _crownTotalSupply = safeSub(_crownTotalSupply, amount);
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function crownFreeze(address user, uint amount, uint period) public onlyAdmin {
        require(crownBalances[user] >= amount);
        crownFreezed[user] = true;
        crownUnlockTime[user] = uint(now) + period;
        crownFreezeAmount[user] = amount;
    }
    
    function _crownFreeze(uint amount) internal {
        require(crownFreezed[msg.sender] == false);
        require(crownBalances[msg.sender] >= amount);
        crownFreezed[msg.sender] = true;
        crownUnlockTime[msg.sender] = uint(-1);
        crownFreezeAmount[msg.sender] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function crownUnFreeze() public whenNotPaused {
        require(crownFreezed[msg.sender] == true);
        require(crownUnlockTime[msg.sender] < uint(now));
        crownFreezed[msg.sender] = false;
        crownFreezeAmount[msg.sender] = 0;
    }
    
    function _crownUnFreeze(uint _amount) internal {
        require(crownFreezed[msg.sender] == true);
        crownUnlockTime[msg.sender] = 0;
        crownFreezed[msg.sender] = false;
        crownFreezeAmount[msg.sender] = safeSub(crownFreezeAmount[msg.sender], _amount);
    }
    
    function crownIfFreeze(address user) public view returns (
        bool check, 
        uint amount, 
        uint timeLeft
    ) {
        check = crownFreezed[user];
        amount = crownFreezeAmount[user];
        timeLeft = crownUnlockTime[user] - uint(now);
    }

}

//
contract PinMoToken is PinMoCrown {
    event PartnerCreated(uint indexed partnerId, address indexed partner, uint indexed amount, uint singleTrans, uint durance);
    event RewardDistribute(uint indexed postId, uint partnerId, address indexed user, uint indexed amount);
    
    event VipAgreementSign(uint indexed vipId, address indexed vip, uint durance, uint frequence, uint salar);
    event SalaryReceived(uint indexed vipId, address indexed vip, uint salary, uint indexed timestamp);
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public minePool;

//Advertising partner can construct their rewarding pool for each campaign
    struct Partner {
        address admin;
        uint tokenPool;
        uint singleTrans;
        uint timestamp;
        uint durance;
    }
//regular users
    struct Poster {
        address poster;
        bytes32 hashData;
        uint reward;
    }
//Influencers do have additional privileges such as salary
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
    function PinMoToken() public {
        symbol = "pinmo";
        name = "PinMo Token";
        decimals = 18;
        _totalSupply = 273000000000000000000000000;
        
    //rewarding pool
        minePool = 136500000000000000000000000;
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
        Transfer(address(0), msg.sender, amount);
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

contract PinMo is PinMoToken {
    event MembershipUpdate(address indexed member, uint indexed level);
    event MembershipCancel(address indexed member);
    event PinMoTradeCreated(uint indexed tradeId, bool indexed ifCrown, uint crown, uint token);
    event TradeCancel(uint indexed tradeId);
    event TradeComplete(uint indexed tradeId, address indexed buyer, address indexed seller, uint crown, uint token);
    event Mine(address indexed miner, uint indexed salary);
    
    mapping (address => uint) MemberToLevel;
    mapping (address => uint) MemberToCrown;
    mapping (address => uint) MemberToToken;
    mapping (address => uint) MemberToTime;
    
    uint public period = 30 days;
    
    uint[4] public boardMember =[
        0,
        5,
        25,
        100
    ];

    uint[4] public salary = [
        0,
        2000000000000000000000,
        6000000000000000000000,
        12000000000000000000000
    ];
    
    struct PinMoTrade {
        address seller;
        bool ifCrown;
        uint crown;
        uint token;
    }
    
    PinMoTrade[] pinMoTrades;
    
    function boardMemberApply(uint _level) public whenNotPaused {
        require(_level > 0 && _level <= 3);
        require(crownBalances[msg.sender] >= boardMember[_level]);
        _crownFreeze(boardMember[_level]);
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
        _crownUnFreeze(boardMember[MemberToLevel[msg.sender]]);
        
        MemberToLevel[msg.sender] = 0;
        MembershipCancel(msg.sender);
    }
    
    function createPinMoTrade(bool _ifCrown, uint _crown, uint _token) public whenNotPaused returns (uint) {
        if(_ifCrown) {
            require(crownBalances[msg.sender] >= _crown);
            crownBalances[msg.sender] = safeSub(crownBalances[msg.sender], _crown);
            MemberToCrown[msg.sender] = _crown;
            PinMoTrade memory pinMo = PinMoTrade({
               seller: msg.sender,
               ifCrown:_ifCrown,
               crown: _crown,
               token: _token
            });
            uint newCrownTradeId = pinMoTrades.push(pinMo) - 1;
            PinMoTradeCreated(newCrownTradeId, _ifCrown, _crown, _token);
            
            return newCrownTradeId;
        } else {
            require(balances[msg.sender] >= _token);
            balances[msg.sender] = safeSub(balances[msg.sender], _token);
            MemberToToken[msg.sender] = _token;
            PinMoTrade memory _pinMo = PinMoTrade({
               seller: msg.sender,
               ifCrown:_ifCrown,
               crown: _crown,
               token: _token
            });
            uint newTokenTradeId = pinMoTrades.push(_pinMo) - 1;
            PinMoTradeCreated(newTokenTradeId, _ifCrown, _crown, _token);
            
            return newTokenTradeId;
        }
    }
    
    function cancelTrade(uint _tradeId) public whenNotPaused {
        PinMoTrade memory pinMo = pinMoTrades[_tradeId];
        require(pinMo.seller == msg.sender);
        if(pinMo.ifCrown){
            crownBalances[msg.sender] = safeAdd(crownBalances[msg.sender], pinMo.crown);
            MemberToCrown[msg.sender] = 0;
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], pinMo.token);
            MemberToToken[msg.sender] = 0;
        }
        delete pinMoTrades[_tradeId];
        TradeCancel(_tradeId);
    }
    
    function trade(uint _tradeId) public whenNotPaused {
        PinMoTrade memory pinMo = pinMoTrades[_tradeId];
        if(pinMo.ifCrown){
            crownBalances[msg.sender] = safeAdd(crownBalances[msg.sender], pinMo.crown);
            MemberToCrown[pinMo.seller] = 0;
            transfer(pinMo.seller, pinMo.token);
            delete pinMoTrades[_tradeId];
            TradeComplete(_tradeId, msg.sender, pinMo.seller, pinMo.crown, pinMo.token);
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], pinMo.token);
            MemberToToken[pinMo.seller] = 0;
            crownTransfer(pinMo.seller, pinMo.crown);
            delete pinMoTrades[_tradeId];
            TradeComplete(_tradeId, msg.sender, pinMo.seller, pinMo.crown, pinMo.token);
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
        bool ifCrown,
        uint crown,
        uint token 
    ) {
        PinMoTrade memory _pinMo = pinMoTrades[_tradeId];
        seller = _pinMo.seller;
        ifCrown = _pinMo.ifCrown;
        crown = _pinMo.crown;
        token = _pinMo.token;
    }
    
    function WhoIsTheContractMaster() public pure returns (string) {
        return "Alexander The Exlosion";
    }
}