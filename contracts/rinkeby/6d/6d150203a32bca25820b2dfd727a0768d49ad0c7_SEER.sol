/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.5.8;

// ----------------------------------------------------------------------------
//SEER 预言家 contract
//
//SEE黄金
// Symbol      : SEG
// Name        : SEER Gold
// Total supply: 10000
// Decimals    : 0
// 
//SEE币
// Symbol      : SEE
// Name        : SEER Token
// Total supply: 86000000
// Decimals    : 2
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
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
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
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


// ----------------------------------------------------------------------------
// Admin contract
// ----------------------------------------------------------------------------
contract Administration {
    event CFOTransferred(address indexed _from, address indexed _to);
    event Pause();
    event Unpause();

    address payable CEOAddress;
    address public CFOAddress;

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
        emit CFOTransferred(CFOAddress, _newAdmin);
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

contract SeerGold is ERC20Interface, Administration, SafeMath {
    event GoldTransfer(address indexed from, address indexed to, uint tokens);
    
    string public goldSymbol = "SEG";
    string public goldName = "SEER Gold";
    uint8 public goldDecimals = 0;
    uint public _goldTotalSupply = 10000;

    mapping(address => uint) goldBalances;
    mapping(address => bool) goldFreezed;
    mapping(address => uint) goldFreezeAmount;
    mapping(address => uint) goldUnlockTime;

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function goldTotalSupply() public view returns (uint) {
        return _goldTotalSupply  - goldBalances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function goldBalanceOf(address tokenOwner) public view returns (uint balance) {
        return goldBalances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
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

contract SeerToken is SeerGold {
    string public symbol = "SEE";
    string public  name = "Seer Token";
    uint8 public decimals = 2;
    uint public _totalSupply = 86000000*decimals;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) freezed;
    mapping(address => uint) freezeAmount;
    mapping(address => uint) unlockTime;
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
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
    // from the token owner's account
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
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        require(freezed[msg.sender] != true);
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        require(freezed[msg.sender] != true);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
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
    // Accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyAdmin returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(CEOAddress, tokens);
    }
}

contract SEER is SeerToken {
    event SEERTradeCreated(uint indexed tradeId, bool indexed ifGold, uint gold, uint token);
    event TradeCancel(uint indexed tradeId);
    event TradeComplete(uint indexed tradeId, address indexed buyer, address indexed seller, uint gold, uint token);

    mapping (address => uint) MemberToGold;
    mapping (address => uint) MemberToToken;

    
    struct SEERTrade {
        address seller;
        bool ifGold;
        uint gold;
        uint token;
    }
    
    SEERTrade[] SEERTrades;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _CFOAddress) public {
        CEOAddress = msg.sender;
        CFOAddress = _CFOAddress;
        
        balances[CEOAddress] = _totalSupply;
        goldBalances[CEOAddress] = _goldTotalSupply;
        emit GoldTransfer(address(0), CEOAddress, _goldTotalSupply);
        emit Transfer(address(0), CEOAddress, _totalSupply);
    }
    
    function createSEERTrade(bool _ifGold, uint _gold, uint _token) public whenNotPaused returns (uint) {
        if(_ifGold) {
            require(goldBalances[msg.sender] >= _gold);
            goldBalances[msg.sender] = safeSub(goldBalances[msg.sender], _gold);
            MemberToGold[msg.sender] = _gold;
            SEERTrade memory _trade = SEERTrade({
               seller: msg.sender,
               ifGold:_ifGold,
               gold: _gold,
               token: _token
            });
            uint newGoldTradeId = SEERTrades.push(_trade) - 1;
            emit SEERTradeCreated(newGoldTradeId, _ifGold, _gold, _token);
            
            return newGoldTradeId;
        } else {
            require(balances[msg.sender] >= _token);
            balances[msg.sender] = safeSub(balances[msg.sender], _token);
            MemberToToken[msg.sender] = _token;
            SEERTrade memory _trade = SEERTrade({
               seller: msg.sender,
               ifGold:_ifGold,
               gold: _gold,
               token: _token
            });
            uint newTokenTradeId = SEERTrades.push(_trade) - 1;
            emit SEERTradeCreated(newTokenTradeId, _ifGold, _gold, _token);
            
            return newTokenTradeId;
        }
    }
    
    function cancelTrade(uint _tradeId) public whenNotPaused {
        SEERTrade memory _trade = SEERTrades[_tradeId];
        require(_trade.seller == msg.sender);
        if(_trade.ifGold){
            goldBalances[msg.sender] = safeAdd(goldBalances[msg.sender], _trade.gold);
            MemberToGold[msg.sender] = 0;
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], _trade.token);
            MemberToToken[msg.sender] = 0;
        }
        delete SEERTrades[_tradeId];
        emit TradeCancel(_tradeId);
    }
    
    function trade(uint _tradeId) public whenNotPaused {
        SEERTrade memory _trade = SEERTrades[_tradeId];
        if(_trade.ifGold){
            goldBalances[msg.sender] = safeAdd(goldBalances[msg.sender], _trade.gold);
            MemberToGold[_trade.seller] = 0;
            transfer(_trade.seller, _trade.token);
            delete SEERTrades[_tradeId];
            emit TradeComplete(_tradeId, msg.sender, _trade.seller, _trade.gold, _trade.token);
        } else {
            balances[msg.sender] = safeAdd(balances[msg.sender], _trade.token);
            MemberToToken[_trade.seller] = 0;
            goldTransfer(_trade.seller, _trade.gold);
            delete SEERTrades[_tradeId];
            emit TradeComplete(_tradeId, msg.sender, _trade.seller, _trade.gold, _trade.token);
        }
    }
    
    function getTrade(uint _tradeId) public view returns (
        address seller,
        bool ifGold,
        uint gold,
        uint token 
    ) {
        SEERTrade memory _SEER = SEERTrades[_tradeId];
        seller = _SEER.seller;
        ifGold = _SEER.ifGold;
        gold = _SEER.gold;
        token = _SEER.token;
    }
    
    function WhoIsTheContractMaster() public pure returns (string memory) {
        return "Alexander The Exlosion";
    }
}