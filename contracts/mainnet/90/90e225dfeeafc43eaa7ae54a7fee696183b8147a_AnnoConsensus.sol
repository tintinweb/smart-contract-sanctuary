pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
//共识会 contract
//
//共识勋章：象征着你在共识会的地位和权利
//Anno Consensus Medal: Veni, Vidi, Vici
// 
// Symbol      : GSU
// Name        : Anno Consensus
// Total supply: 1000000
// Decimals    : 0
// 
// 共识币：维护共识新纪元的基石
//Anno Consensus Coin: Caput, Anguli, Seclorum
// Symbol      : ANNO
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
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    
    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }
    
    // ------------------------------------------------------------------------
    // Accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract GSUMedal is ERC20Interface, Owned, SafeMath {
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
    function GSUMedal() public {
        medalSymbol = "GSU";
        medalName = "Anno Consensus";
        medalDecimals = 0;
        _medalTotalSupply = 1000000;
        medalBalances[msg.sender] = _medalTotalSupply;
        MedalTransfer(address(0), msg.sender, _medalTotalSupply);
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
    function mentalBalanceOf(address tokenOwner) public constant returns (uint balance) {
        return medalBalances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function medalTransfer(address to, uint tokens) public returns (bool success) {
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
    function mintMedal(uint amount) public onlyOwner {
        medalBalances[msg.sender] = safeAdd(medalBalances[msg.sender], amount);
        _medalTotalSupply = safeAdd(_medalTotalSupply, amount);
    }

    // ------------------------------------------------------------------------
    // Burn Tokens
    // ------------------------------------------------------------------------
    function burnMedal(uint amount) public onlyOwner {
        medalBalances[msg.sender] = safeSub(medalBalances[msg.sender], amount);
        _medalTotalSupply = safeSub(_medalTotalSupply, amount);
    }
    
    // ------------------------------------------------------------------------
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function medalFreeze(address user, uint amount, uint period) public onlyOwner {
        require(medalBalances[user] >= amount);
        medalFreezed[user] = true;
        medalUnlockTime[user] = uint(now) + period;
        medalFreezeAmount[user] = amount;
    }
    
    function _medalFreeze(uint amount) internal {
        require(medalBalances[msg.sender] >= amount);
        medalFreezed[msg.sender] = true;
        medalUnlockTime[msg.sender] = uint(-1);
        medalFreezeAmount[msg.sender] = amount;
    }

    // ------------------------------------------------------------------------
    // UnFreeze Tokens
    // ------------------------------------------------------------------------
    function medalUnFreeze() public {
        require(medalFreezed[msg.sender] == true);
        require(medalUnlockTime[msg.sender] < uint(now));
        medalFreezed[msg.sender] = false;
        medalFreezeAmount[msg.sender] = 0;
    }
    
    function _medalUnFreeze() internal {
        require(medalFreezed[msg.sender] == true);
        medalUnlockTime[msg.sender] = 0;
        medalFreezed[msg.sender] = false;
        medalFreezeAmount[msg.sender] = 0;
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

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract AnnoToken is GSUMedal {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public minePool;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) freezed;
    mapping(address => uint) freezeAmount;
    mapping(address => uint) unlockTime;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function AnnoToken() public {
        symbol = "ANNO";
        name = "Anno Consensus Token";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        minePool = 600000000000000000000000000;
        balances[msg.sender] = _totalSupply - minePool;
        Transfer(address(0), msg.sender, _totalSupply - minePool);
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
    // Freeze Tokens
    // ------------------------------------------------------------------------
    function freeze(address user, uint amount, uint period) public onlyOwner {
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
    
    function _mine(uint _amount) internal {
        balances[msg.sender] = safeAdd(balances[msg.sender], _amount);
        minePool = safeSub(minePool, _amount);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract AnnoConsensus is AnnoToken {
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
    
    function boardMemberApply(uint _level) public {
        require(medalBalances[msg.sender] >= boardMember[_level]);
        _medalFreeze(boardMember[_level]);
        MemberToLevel[msg.sender] = _level;
        
        MembershipUpdate(msg.sender, _level);
    }
    
    function getBoardMember(address _member) public view returns (uint) {
        return MemberToLevel[_member];
    }
    
    function boardMemberCancel() public {
        require(medalBalances[msg.sender] > 0);
        _medalUnFreeze();
        
        MemberToLevel[msg.sender] = 0;
        MembershipCancel(msg.sender);
    }
    
    function createAnnoTrade(bool _ifMedal, uint _medal, uint _token) public returns (uint) {
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
    
    function cancelTrade(uint _tradeId) public {
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
    
    function trade(uint _tradeId) public {
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
    
    function mine() public {
        uint level = MemberToLevel[msg.sender];
        require(MemberToTime[msg.sender] < uint(now)); 
        require(minePool >= salary[level]);
        require(level > 0);
        _mine(salary[level]);
        minePool = safeSub(minePool, salary[level]);
        MemberToTime[msg.sender] = safeAdd(MemberToTime[msg.sender], period);
        Mine(msg.sender, salary[level]);
    }
    
    function setSalary(uint one, uint two, uint three, uint four) public onlyOwner {
        salary[1] = one;
        salary[2] = two;
        salary[3] = three;
        salary[4] = four;
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
    
}