pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// ZAN token contract
//
// Symbol      : ZAN
// Name        : ZAN Coin
// Total supply: 17,148,385.000000000000000000
// Decimals    : 18
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        assert(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        assert(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        assert(b > 0);
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
    function receiveApproval(address from, uint tokens, address token, bytes data) public;
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract ZanCoin is ERC20Interface, Owned {
    using SafeMath for uint;
    
    // ------------------------------------------------------------------------
    // Metadata
    // ------------------------------------------------------------------------
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    // ------------------------------------------------------------------------
    // Crowdsale data
    // ------------------------------------------------------------------------
    bool public isInPreSaleState;
    bool public isInRoundOneState;
    bool public isInRoundTwoState;
    bool public isInFinalState;
    uint public stateStartDate;
    uint public stateEndDate;
    uint public saleCap;
    uint public exchangeRate;
    
    uint public burnedTokensCount;

    event SwitchCrowdSaleStage(string stage, uint exchangeRate);
    event BurnTokens(address indexed burner, uint amount);
    event PurchaseZanTokens(address indexed contributor, uint eth_sent, uint zan_received);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ZanCoin() public {
        symbol = "ZAN";
        name = "ZAN Coin";
        decimals = 18;
        _totalSupply = 17148385 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        
        isInPreSaleState = false;
        isInRoundOneState = false;
        isInRoundTwoState = false;
        isInFinalState = false;
        burnedTokensCount = 0;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
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
        emit Transfer(msg.sender, to, tokens);
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
        emit Approval(msg.sender, spender, tokens);
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
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Accepts ETH and transfers ZAN tokens based on exchage rate and state
    // ------------------------------------------------------------------------
    function () public payable {
        uint eth_sent = msg.value;
        uint tokens_amount = eth_sent.mul(exchangeRate);
        
        require(eth_sent > 0);
        require(exchangeRate > 0);
        require(stateStartDate < now && now < stateEndDate);
        require(balances[owner] >= tokens_amount);
        require(_totalSupply - (balances[owner] - tokens_amount) <= saleCap);
        
        // Don&#39;t accept ETH in the final state
        require(!isInFinalState);
        require(isInPreSaleState || isInRoundOneState || isInRoundTwoState);
        
        balances[owner] = balances[owner].sub(tokens_amount);
        balances[msg.sender] = balances[msg.sender].add(tokens_amount);
        emit PurchaseZanTokens(msg.sender, eth_sent, tokens_amount);
    }
    
    // ------------------------------------------------------------------------
    // Switches crowdsale stages: PreSale -> Round One -> Round Two
    // ------------------------------------------------------------------------
    function switchCrowdSaleStage() external onlyOwner {
        require(!isInFinalState && !isInRoundTwoState);
        
        if (!isInPreSaleState) {
            isInPreSaleState = true;
            exchangeRate = 1500;
            saleCap = (3 * 10**6) * (uint(10) ** decimals);
            emit SwitchCrowdSaleStage("PreSale", exchangeRate);
        }
        else if (!isInRoundOneState) {
            isInRoundOneState = true;
            exchangeRate = 1200;
            saleCap = saleCap + ((4 * 10**6) * (uint(10) ** decimals));
            emit SwitchCrowdSaleStage("RoundOne", exchangeRate);
        }
        else if (!isInRoundTwoState) {
            isInRoundTwoState = true;
            exchangeRate = 900;
            saleCap = saleCap + ((5 * 10**6) * (uint(10) ** decimals));
            emit SwitchCrowdSaleStage("RoundTwo", exchangeRate);
        }
        
        stateStartDate = now + 5 minutes;
        stateEndDate = stateStartDate + 7 days;
    }
    
    // ------------------------------------------------------------------------
    // Switches to Complete stage of the contract. Sends all funds collected
    // to the contract owner.
    // ------------------------------------------------------------------------
    function completeCrowdSale() external onlyOwner {
        require(!isInFinalState);
        require(isInPreSaleState && isInRoundOneState && isInRoundTwoState);
        
        owner.transfer(address(this).balance);
        exchangeRate = 0;
        isInFinalState = true;
        emit SwitchCrowdSaleStage("Complete", exchangeRate);
    }

    // ------------------------------------------------------------------------
    // Token holders are able to burn their tokens.
    // ------------------------------------------------------------------------
    function burn(uint amount) public {
        require(amount > 0);
        require(amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        burnedTokensCount = burnedTokensCount + amount;
        emit BurnTokens(msg.sender, amount);
    }

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}