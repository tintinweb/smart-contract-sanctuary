pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;NeLunaCoin&#39; token contract
//
// Deployed to : 
// Symbol      : NLC
// Name        : NeLunaCoin
// Total supply: 1200000000
// Decimals    : 18
//
// (c) by KK
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

    //Events
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event SellToken(address indexed buyedFrom, uint tokens, uint eth);
    event BuyToken(address whoBuy, uint ethSpent);
    event Kill(string killConfirmed);
    
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

    constructor() public {
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
// Start-Stop contract
// ----------------------------------------------------------------------------
contract Start is Owned {
    bool public sale;

    event eSaleStart(bool saleStart);

    constructor() public {
        sale = true;
        emit eSaleStart(true);
    }

    modifier started {
        require(sale == true);
        _;
    }

    function startSale(bool starter) public onlyOwner {
        sale = starter;
        emit eSaleStart(starter);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract NeLunaCoin is ERC20Interface, Owned, Start, SafeMath {
    //Public vars of the token
    string public constant symbol = "NLC";
    string public constant name = "NeLunaCoin";
    uint256 public constant decimals = 18;
    
    //Token sellPrice 1 ETH = 1000 Tokens
    uint256 public sellPrice = 1000;
    uint256 public buyPrice = 1000;
    
    //Total supply and _devTokens
    uint public _totalSupply;
	uint public _devTokens;

    //Array with all balances    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    //Buyers
    address[] public buyersAddresses;
    mapping(address => uint) buyers;
    

    //
    //GETTER
    //
    function refundBuyer() onlyOwner public returns(bool){
        for(uint i = 0; i <= buyersAddresses.length; i++){
            uint amountToRefund = buyers[buyersAddresses[i]];
            require(amountToRefund <= address(this).balance);
            address(buyersAddresses[i]).transfer(amountToRefund);
        }
        //return balances;
    }
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
		_devTokens = 200000000 * 10**decimals;
        _totalSupply = 1200000000 * 10**decimals;
        
        balances[owner] = _devTokens;
        emit Transfer(address(this), owner, _devTokens);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
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
        balances[msg.sender] = safeSub(balances[msg.sender], tokens *10**decimals);
        balances[to] = safeAdd(balances[to], tokens*10**decimals);
        emit Transfer(msg.sender, to, tokens);
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
    // 1,000 NLC Tokens per 1 ETH
    // ------------------------------------------------------------------------
    function () public payable started{
        uint tokens;
        tokens = msg.value * buyPrice;
        require(tokens >= 1);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer(address(this), msg.sender, tokens);
        buyers[msg.sender] = msg.value;
        buyersAddresses.push(msg.sender) -1;
        emit BuyToken(msg.sender, msg.value);
        //owner.transfer(msg.value);
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    /*
    //Send the Tokens back, and get ETH
    function (uint tokens) public { 
        
    }
    */
    function getETH() onlyOwner public {
        owner.transfer(address(this).balance);
        emit Transfer(address(this), owner, address(this).balance);
    }


    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sellToken(uint256 amount) public {
        uint balance = address(this).balance;
        require(balance >= amount / sellPrice);      // checks if the contract has enough ether to buy
        transferFrom(msg.sender, this, amount);              // makes the transfers
        
        msg.sender.transfer(amount / sellPrice);          // sends ether to the seller. It&#39;s important to do this last to avoid recursion attacks
        emit SellToken(msg.sender, amount, amount / sellPrice);
    }
    
    // Kill contract and send funds to Owner
    function kill() onlyOwner public {
        selfdestruct(owner);
        emit Kill("Contract is dead");
    }
}