pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;United States Token Market 01&#39; token contract
//
// Deployed to : 0xBA77Afe8123b87476BA2E8Aaf2fdA78097971d99
// Symbol      : USTM01
// Name        : United States Token Market 01
// Total supply: 1,000,000,000
// Decimals    : 18
//
// 
//
// (c) Kingsbury, Texas, USA 2018.
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

    function Constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
library Div
{
   struct DivIteration
    {
        uint _divAmount;
        mapping(address => uint) _divSnapShot;
    
        //0-no transfer found 1-hastransfer
        mapping(address => uint) _divState; 
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract USTM01 is ERC20Interface, Owned, SafeMath {
    //Standard Members
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    //DIV Members
    uint _totalFloating;
    bool _isDividendAvailable = false;
    
    
 
    
    mapping(uint=>Div.DivIteration) _divdendSnapshots;
    uint _currentDivIteration;
    
    address _creator = 0xBA77Afe8123b87476BA2E8Aaf2fdA78097971d99;
    address _valutToken = 0xD4981e26722a1Ba2280A37b5B741622709AE3278;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function USTM01() public {
        symbol = "USTM01";
        name = "US Token Market";
        decimals = 18;
        _totalSupply = 1000000000 * 1 ether;
        _totalFloating = 0;
        balances[_creator] = _totalSupply;
        emit Transfer(address(0), _creator, _totalSupply);
        _currentDivIteration = 0;
        _divdendSnapshots[_currentDivIteration] = Div.DivIteration(0);
     
    }
    
    //For Display only
    function totalSupplyInt() public constant returns(uint)
    {
        return safeDiv(_totalSupply , 1 ether);
    }
    
     function balanceOfInt(address tokenOwner) public constant returns (uint bal) {
        return safeDiv(balances[tokenOwner],1 ether);
    }
    
    
    function totalSupply() public constant returns(uint)
    {
        _totalSupply;
    }
    
    function TotalFloatingInt() public constant returns (uint)
    {
        
        return safeDiv(_totalFloating, 1 ether);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint bal) {
        return balances[tokenOwner];
    }
    
    
    //TODO - Add Permission List
    function HasSigningPermission(address signer) public constant returns (bool haspermission)
    {
        return signer == _creator;
    }
    
    //TODO Add List to Indicate the address that are not considered floating
    function IsControledAddress(address targetAddress) public constant returns (bool canReceive)
    {
        return targetAddress != _creator;
    }
    
    // Stop Dividend Payment, TODO Add two step process
    function SignStopDividend() public
    {
        require(HasSigningPermission(msg.sender));
        _isDividendAvailable = false;
       
    }
    function SignDividend(uint amount) public 
    {
        require(_isDividendAvailable == false);
        require(HasSigningPermission(msg.sender));
     
       
        uint totalCoin = safeDiv(_totalFloating , 1 ether);
        require(totalCoin > 0);
        uint divLargeInt = safeMul(amount, 1 ether);
        uint divPerCoin = safeDiv(divLargeInt, totalCoin);
        
        require (divPerCoin > 0);
    
         _currentDivIteration ++;
        _divdendSnapshots[_currentDivIteration] = Div.DivIteration(0);
        _divdendSnapshots[_currentDivIteration]._divAmount = divPerCoin;
        _isDividendAvailable = true;
        
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        
        uint originalSender = balances[msg.sender];
        uint originalReceiver = balances[to];
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        
        LockDiv(msg.sender, originalSender);
        LockDiv(to,originalReceiver);
        CheckForFloating(msg.sender, tokens);
        return true;
    }
    
    function CheckForFloating(address sender, uint tokens) private
    {
        if (IsControledAddress(sender))
            _totalFloating += tokens;
    }
    
    function LookUpAvailableDivInt(address to) public constant returns(uint amountInt)
    {
        if(!_isDividendAvailable)
        return 0;
        
        uint snapshot = balances[to];
        if ( _divdendSnapshots[_currentDivIteration]._divState[to] == 1)
            snapshot =  _divdendSnapshots[_currentDivIteration]._divSnapShot[to];
            
            if (snapshot == 0)
            return 0;
            
        uint amountLargeInt = safeMul(snapshot , _divdendSnapshots[_currentDivIteration]._divAmount);
        amountInt = safeDiv(amountLargeInt,1 ether);
        
        return amountInt;
        
        
        
    }
    function LockDiv(address to, uint tokens) private
    {
        if (IsControledAddress(to))
            return;
        if ( _divdendSnapshots[_currentDivIteration]._divState[to] == 0)
             _divdendSnapshots[_currentDivIteration]._divSnapShot[to] = tokens;
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
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}