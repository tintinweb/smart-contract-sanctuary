pragma solidity 0.4.24;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
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
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract MetronomeToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function MetronomeToken() public {
        symbol = &quot;MET&quot;;
        name = &quot;Test Metronome Token&quot;;
        decimals = 18;
        _totalSupply = 10000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
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
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
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
    function approve(address spender, uint tokens) public returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
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
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        //revert();
    }
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}

contract MetronomeAuction {
    address owner;
    bool running=true;
    uint start_time=block.timestamp;
    uint tokens_sold;
    
    uint decimals=18;
    
    uint constant max_tokens=8000000*(10**18);
    uint lastPurchasePrice=0;
    uint lastAuctionEndPrice=1*(10**18);
    
    address tokenAddress;
    
    constructor() public {
        tokenAddress=new MetronomeToken();
    }
    
    
    
function whatWouldPurchaseDo(uint _wei, uint _timestamp) public constant returns (uint weiPerToken, uint tokens, uint refund) {
        weiPerToken=whichPrice(_timestamp);
        tokens=_wei/weiPerToken*10**decimals;
        refund=0;
        if(tokens>max_tokens-tokens_sold) {
            tokens=max_tokens-tokens_sold;
            refund=_wei-tokens*weiPerToken;
        }
}
    
function isRunning() public constant returns (bool) {
    return running;
}

function currentTick() public view returns(uint) {
    return whichTick(block.timestamp);
}

function currentAuction() public view returns(uint) {
    return 0;
}

function whichTick(uint t) public view returns(uint) {
    return (t-start_time)/60;
}

function whichAuction(uint t) public view returns(uint) {
    return 0;
}

function heartbeat() public view returns (bytes8 chain,address auctionAddr,address convertAddr,address tokenAddr,uint minting,uint totalMet,uint proceedsBal,uint currTick, uint currAuction,uint nextAuctionGMT,uint genesisGMT,uint currentAuctionPrice,uint dailyMintable,uint _lastPurchasePrice) {
    chain=0x1;
    auctionAddr=0;
    convertAddr=0;
    tokenAddr=tokenAddress;
    minting=max_tokens;
    totalMet=tokens_sold;
    proceedsBal=0;//unknown
    currTick=currentTick();
    currAuction=currentAuction();
    nextAuctionGMT=start_time+3600*24*7;
    genesisGMT=0;//unknown
    currentAuctionPrice=currentPrice();
    dailyMintable=max_tokens;//unknown
    _lastPurchasePrice=lastPurchasePrice;//unknown
}

function mintInitialSupply(uint[] _founders, address _token, address _proceeds, address _autonomousConverter) public onlyOwner returns (bool) {}

function initAuctions(uint _startTime, uint _minimumPrice, uint _startingPrice, uint _timeScale) public onlyOwner returns (bool) {}

function stopEverything() public onlyOwner {}

function isInitialAuctionEnded() public view returns (bool) {
    return false;
}

function globalMetSupply() public view returns (uint) {
    return max_tokens;
}

function globalDailySupply() public view returns (uint) {
    return max_tokens;
}

function whichPrice(uint t) public constant returns (uint weiPerToken) {
    uint price=lastAuctionEndPrice*2-whichTick(t)*198432056800000;
    if(price<3300000000000) {
        price=3300000000000;
    }
    return price;
}

function currentPrice() public constant returns (uint weiPerToken) {
    return whichPrice(block.timestamp);
}

function () public payable {
    lastPurchasePrice=currentPrice();
    (uint weiPerToken, uint tokens, uint refund)=whatWouldPurchaseDo(msg.value,block.timestamp);
    if(refund>0) {
        msg.sender.transfer(refund);
    }
    
    require(MetronomeToken(tokenAddress).transfer(msg.sender,tokens)==true);
    tokens_sold+=tokens;
    LogAuctionFundsIn(msg.value-refund);
}

function kill() public onlyOwner {
    selfdestruct(msg.sender);
}

event LogAuctionFundsIn(uint amount);
modifier onlyOwner {
    require(msg.sender == owner);
    _;
}

}