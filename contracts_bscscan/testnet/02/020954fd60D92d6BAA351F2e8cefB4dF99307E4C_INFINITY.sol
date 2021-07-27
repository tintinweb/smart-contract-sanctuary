/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-01
*/

// SPDX-License-Identifier: None

pragma solidity ^0.6.12;



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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
abstract contract ERC20 {
    function totalSupply() virtual external view returns (uint);
    function balanceOf(address tokenOwner) virtual external view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual external view returns (uint remaining);
    function transfer(address to, uint tokens) virtual external returns (bool success);
    function approve(address spender, uint tokens) virtual external returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual external;
}

// ----------------------------------------------------------------------------
// Contract function to transfer and execute function in one call
// ----------------------------------------------------------------------------
abstract contract TransferAndCallFallBack {
    function receiveTransfer(address from, uint tokens, bytes memory data) virtual public returns (bool success); 
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner; 

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(address ownerAddress) public {
        owner = ownerAddress;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public virtual {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract INFINITY is ERC20, Owned, SafeMath {
    string constant public symbol = "IGL";
    string constant public name = "INNFINITY GLOBAL";
    uint8 constant public decimals = 18;
    uint constant private _totalSupply = 1000000000 * 1000 ** 18;
    uint private _exchangeRate;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event ChangeExchangeRate(uint newRate);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address ownerAddress) Owned (ownerAddress) public {
        balances[ownerAddress] = _totalSupply;
        _exchangeRate = 100;
        emit Transfer(address(0), ownerAddress, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() override external view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) override external view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) override external returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
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
    function approve(address spender, uint tokens) override external returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) override external returns (bool success) {
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
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Get current exchange rate
    // ------------------------------------------------------------------------
    function exchangeRate() external view returns (uint rate) {
        return _exchangeRate;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) external returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to a smart contract and receive approval
    // - Owner's account must have sufficient balance to transfer
    // - Smartcontract must accept the payment 
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferAndCall(address to, uint tokens, bytes memory data) public returns (bool success) {
        require (tokens <= balances[msg.sender] );
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        require (TransferAndCallFallBack(to).receiveTransfer(msg.sender, tokens, data));
        
        emit Transfer(msg.sender, to, tokens);
        return true;    
    }


    // ----------------------------------------------------------------------------
    // Buy EASY tokens for ETH by exchange rate
    // ----------------------------------------------------------------------------
    function buyTokens() public payable returns (bool success) {
        require (msg.value > 0, "ETH amount should be greater than zero");
        
        uint tokenAmount = _exchangeRate * msg.value; 
        balances[owner] = safeSub(balances[owner], tokenAmount);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokenAmount);
        emit Transfer(owner, msg.sender, tokenAmount);
        return true;
    }


    // ----------------------------------------------------------------------------
    // Buy tokens and transfer to other address, additional data 
    // can be passed as parameter
    // ----------------------------------------------------------------------------
    function buyTokensAndTransfer(address to, bytes memory data) external payable returns (bool success) {
        require (buyTokens());
        uint tokenAmount = _exchangeRate * msg.value ;
        require (transferAndCall (to, tokenAmount, data));
        return true;
    }
    

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }


    // ----------------------------------------------------------------------------
    // Owner can change exchange rate
    // ----------------------------------------------------------------------------
    function changeExchangeRate(uint newExchangeRate) external onlyOwner {
        require (newExchangeRate > 0, "Exchange rate should be greater than zero");
        _exchangeRate = newExchangeRate; 
        emit ChangeExchangeRate(newExchangeRate);
    }

  
    // ----------------------------------------------------------------------------
    // Owner can transfer contract funds 
    // ----------------------------------------------------------------------------
    function transferFunds(address to, uint amount) external onlyOwner returns (bool success) {
        require (amount <= address(this).balance, "Not enough funds");
        address(uint160(to)).transfer(amount);
        return true;
    }
    
    // ----------------------------------------------------------------------------
    // Accept ownership by new owner 
    // ----------------------------------------------------------------------------
    function acceptOwnership() public override {
        balances[newOwner] = balances[owner];
        balances[owner] = 0;
        emit Transfer(owner, newOwner, balances[newOwner]);
        super.acceptOwnership();
    }
}