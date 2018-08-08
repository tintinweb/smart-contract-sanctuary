pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;ADE&#39; &#39;AdeCoin&#39; token contract
//
// Symbol      : ADE
// Name        : AdeCoin
// Total supply: Generated from contributions
// Decimals    : 8
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event TransferSell(address indexed from, uint tokens, uint eth);
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
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// Receives ETH and generates tokens
// ----------------------------------------------------------------------------
contract ADEToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    uint public sellRate;
    uint public buyRate;
    
    uint private lockRate = 30 days;
    
    struct lockPosition{
        uint time;
        uint count;
        uint releaseRate;
    }
    
    mapping(address => lockPosition) private lposition;
    
    // locked account dictionary that maps addresses to boolean
    mapping (address => bool) private lockedAccounts;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    modifier is_not_locked(address _address) {
        if (lockedAccounts[_address] == true) revert();
        _;
    }
    
    modifier validate_address(address _address) {
        if (_address == address(0)) revert();
        _;
    }
    
    modifier is_locked(address _address) {
        if (lockedAccounts[_address] != true) revert();
        _;
    }
    
    modifier validate_position(address _address,uint count) {
        if(balances[_address] < count * 10**uint(decimals)) revert();
        if(lposition[_address].count > 0 && (balances[_address] - (count * 10**uint(decimals))) < lposition[_address].count && now < lposition[_address].time) revert();
        checkPosition(_address,count);
        _;
    }
    function checkPosition(address _address,uint count) private view {
        if(lposition[_address].releaseRate < 100 && lposition[_address].count > 0){
            uint _rate = safeDiv(100,lposition[_address].releaseRate);
            uint _time = lposition[_address].time;
            uint _tmpRate = lposition[_address].releaseRate;
            uint _tmpRateAll = 0;
            uint _count = 0;
            for(uint _a=1;_a<=_rate;_a++){
                if(now >= _time){
                    _count = _a;
                    _tmpRateAll = safeAdd(_tmpRateAll,_tmpRate);
                    _time = safeAdd(_time,lockRate);
                }
            }
            if(_count < _rate && lposition[_address].count > 0 && (balances[_address] - count * 10**uint(decimals)) < (lposition[_address].count - safeDiv(lposition[_address].count*_tmpRateAll,100)) && now >= lposition[_address].time) revert();   
        }
    }
    
    event _lockAccount(address _add);
    event _unlockAccount(address _add);
    
    function () public payable{
        require(owner != msg.sender);
        require(buyRate > 0);
        
        require(msg.value >= 0.1 ether && msg.value <= 1000 ether);
        uint tokens;
        
        tokens = msg.value / (1 ether * 1 wei / buyRate);
        
        
        require(balances[owner] >= tokens * 10**uint(decimals));
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens * 10**uint(decimals));
        balances[owner] = safeSub(balances[owner], tokens * 10**uint(decimals));
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ADEToken(uint _sellRate,uint _buyRate) public payable {
        symbol = "ADE";
        name = "AdeCoin";
        decimals = 8;
        totalSupply = 2000000000 * 10**uint(decimals);
        balances[owner] = totalSupply;
        Transfer(address(0), owner, totalSupply);
        sellRate = _sellRate;
        buyRate = _buyRate;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public is_not_locked(msg.sender) is_not_locked(to) validate_position(msg.sender,tokens / (10**uint(decimals))) returns (bool success) {
        require(to != msg.sender);
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public is_not_locked(msg.sender) is_not_locked(spender) validate_position(msg.sender,tokens / (10**uint(decimals))) returns (bool success) {
        require(spender != msg.sender);
        require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public is_not_locked(msg.sender) is_not_locked(from) is_not_locked(to) validate_position(from,tokens / (10**uint(decimals))) returns (bool success) {
        require(transferFromCheck(from,to,tokens));
        return true;
    }
    
    function transferFromCheck(address from,address to,uint tokens) private returns (bool success) {
        require(tokens > 0);
        require(from != msg.sender && msg.sender != to && from != to);
        require(balances[from] >= tokens && allowed[from][msg.sender] >= tokens);
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
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    

    // ------------------------------------------------------------------------
    // Sall a token from a contract
    // ------------------------------------------------------------------------
    function sellCoin(address seller, uint amount) public onlyOwner is_not_locked(seller) validate_position(seller,amount){
        require(balances[seller] >= amount * 10**uint(decimals));
        require(sellRate > 0);
        require(seller != msg.sender);
        uint tmpAmount = amount * (1 ether * 1 wei / sellRate);
        
        balances[owner] += amount * 10**uint(decimals);
        balances[seller] -= amount * 10**uint(decimals);
        
        seller.transfer(tmpAmount);
        TransferSell(seller, amount * 10**uint(decimals), tmpAmount);
    }
    
    // set rate
    function setRate(uint _buyRate,uint _sellRate) public onlyOwner {
        require(_buyRate > 0);
        require(_sellRate > 0);
        require(_buyRate < _sellRate);
        buyRate = _buyRate;
        sellRate = _sellRate;
    }
    
    //set lock position
    function setLockPostion(address _add,uint _count,uint _time,uint _releaseRate) public is_not_locked(_add) onlyOwner {
        require(_time > now);
        require(_count > 0);
        require(_releaseRate > 0 && _releaseRate <= 100);
        require(_releaseRate == 2 || _releaseRate == 4 || _releaseRate == 5 || _releaseRate == 10 || _releaseRate == 20 || _releaseRate == 25 || _releaseRate == 50);
        require(balances[_add] >= _count * 10**uint(decimals));
        lposition[_add].time = _time;
        lposition[_add].count = _count * 10**uint(decimals);
        lposition[_add].releaseRate = _releaseRate;
    }
    
    // lockAccount
    function lockStatus(address _owner) public is_not_locked(_owner)  validate_address(_owner) onlyOwner {
        lockedAccounts[_owner] = true;
        _lockAccount(_owner);
    }

    /// @notice only the admin is allowed to unlock accounts.
    /// @param _owner the address of the account to be unlocked
    function unlockStatus(address _owner) public is_locked(_owner) validate_address(_owner) onlyOwner {
        lockedAccounts[_owner] = false;
        _unlockAccount(_owner);
    }
    
    //get lockedaccount
    function getLockStatus(address _owner) public view returns (bool _lockStatus) {
        return lockedAccounts[_owner];
    }
    
    //get lockPosition info
    function getLockPosition(address _add) public view returns(uint time,uint count,uint rate,uint scount) {
        
        return (lposition[_add].time,lposition[_add].count,lposition[_add].releaseRate,positionScount(_add));
    }
    
    function positionScount(address _add) private view returns (uint count){
        uint _rate = safeDiv(100,lposition[_add].releaseRate);
        uint _time = lposition[_add].time;
        uint _tmpRate = lposition[_add].releaseRate;
        uint _tmpRateAll = 0;
        for(uint _a=1;_a<=_rate;_a++){
            if(now >= _time){
                _tmpRateAll = safeAdd(_tmpRateAll,_tmpRate);
                _time = safeAdd(_time,lockRate);
            }
        }
        
        return (lposition[_add].count - safeDiv(lposition[_add].count*_tmpRateAll,100));
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}