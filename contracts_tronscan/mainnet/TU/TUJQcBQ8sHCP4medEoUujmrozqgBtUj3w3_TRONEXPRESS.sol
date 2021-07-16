//SourceUnit: TronExpress.sol

pragma solidity >=0.5.8 <0.6.0;

// ----------------------------------------------------------------------------
// 'TRON EXPRESS ' token contract
//
// Deployed to : TMwWbKBPX4QfGTz7C62PJbu5JVqEAGuaKQ
// Symbol      : TXE
// Name        : TRON EXPRESS
// Total supply: 1000000000
// Decimals    : 18
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
// TRC Token Standard #20 Interface
// https://tronprotocol.github.io/documentation-en/contracts/trc20/
// ----------------------------------------------------------------------------
contract TRC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event ChangeExchangeRate(uint newRate);
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
// Contract function to transfer and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract TransferAndCallFallBack { //ReceiveTokenPayment
    function receiveTransfer(address from, uint tokens, bytes memory data) public returns (bool success); //receiveTokenPayment
    //function receiveTransferTest(address from, uint tokens, bytes memory data) public returns (bool success); //receiveTokenPayment
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
        //owner = msg.sender;
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
// TRC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
    contract TRONEXPRESS is TRC20, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;
    address private issuer;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint private _exchangeRate = 100;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address ownerAddress) Owned (ownerAddress) public {
        symbol = "TXE";
        name = "TRON EXPRESS";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        issuer = ownerAddress;
        balances[issuer] = _totalSupply;
        emit Transfer(address(0),address(issuer), _totalSupply);
    }


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
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
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
        require (TransferAndCallFallBack(to).receiveTransfer(msg.sender, tokens, data)); //receiveTokenPayment  ReceiveTokenPayment
        
        emit Transfer(msg.sender, to, tokens);
        return true;    
    }
    

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent TRC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyTRC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return TRC20(tokenAddress).transfer(owner, tokens);
    }


    // ------------------------------------------------------------------------
    // Get current exchange rate
    // ------------------------------------------------------------------------
    function exchangeRate() public view returns (uint rate) {
        return _exchangeRate;
    }


    // ----------------------------------------------------------------------------
    // Owner can change exchange rate
    // ----------------------------------------------------------------------------
    function changeExchangeRate(uint newExchangeRate) public onlyOwner {
        require (newExchangeRate > 0, "Exchange rate should be greater than zero");
        _exchangeRate = newExchangeRate; 
        emit ChangeExchangeRate(newExchangeRate);
    }


    // ----------------------------------------------------------------------------
    // Buy TXE tokens for tron TRX by exchange rate
    // ----------------------------------------------------------------------------
    function buyTokens() public payable returns (bool success) {
        require (msg.value > 0, "Trx/sun amount should be greater than zero");
        
        uint tokenAmount = _exchangeRate * msg.value * 1000000000000; //compensate decimals difference in TRX and TXE
        balances[issuer] = safeSub(balances[issuer], tokenAmount);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokenAmount);
        emit Transfer(issuer, msg.sender, tokenAmount);
        return true;
    }


    // ----------------------------------------------------------------------------
    // Buy tokens and transfer to other address, additional data 
    // can be passed as parameter
    // ----------------------------------------------------------------------------
    function buyTokensAndTransfer(address to, bytes memory data) public payable returns (bool success) {
        require (buyTokens());
        uint tokenAmount = _exchangeRate * msg.value * 1000000000000; //compensate decimals difference in TRX and TXE
        require (transferAndCall (to, tokenAmount, data));
        return true;
    }

  
    // ----------------------------------------------------------------------------
    // Owner can transfer contract funds 
    // ----------------------------------------------------------------------------
    function transferFunds(address to, uint amount) public onlyOwner returns (bool success) {
        require (amount <= address(this).balance, "Not enough funds");
        address(uint160(to)).transfer(amount);
        return true;
    }
}