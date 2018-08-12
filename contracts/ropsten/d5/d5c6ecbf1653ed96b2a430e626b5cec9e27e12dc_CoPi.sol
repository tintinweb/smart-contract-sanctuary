pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;PiCoin&#39; token contract
//
// Deployed to : 0x7d715c835B6b7D1EAcE195C8B41383B2104c752d
// Symbol      : CoPi
// Name        : CoPi 
// Total supply: 1,000,000
// Decimals    : 18
//
// Based on a contract template 
// from https://github.com/bitfwdcommunity/Issue-your-own-ERC20-token
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract CoPi is ERC20Interface, Owned, SafeMath {
    string public symbol = "CoPi";
    string public name = "CoPi";

    // It must be 18, until decimals alignment is implemented in ()
    // DON&#39;T FORGET to update _totalSupply in the constructor
    uint8 public decimals = 18;  
    
    uint256 public totalSupply;
    uint256 public price = 0;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        // 1000000 and 18 decimals
        totalSupply = 1000000000000000000000000;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balances[_tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _tokens) public returns (bool success) {
        require(_to != address(0));
        // it&#39;s handled by safeSub
        // require(tokens <= balances[msg.sender]);

        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _tokens) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
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
    function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool success) {
        require(_to != address(0));
        // following is handled by safeSub
        // require(tokens <= balances[from]);
        // require(tokens <= allowed[from][msg.sender]);

        balances[_from] = safeSub(balances[_from], _tokens);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return allowed[_tokenOwner][_spender];
    }

    // ------------------------------------------------------------------------
    // Token owner can increase approval for spender to transferFrom(...) tokens
    // from the token owner&#39;s account.
    // From MonolithDAO Token.sol
    // ------------------------------------------------------------------------
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (
            safeAdd(allowed[msg.sender][_spender], _addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can reduce approval for spender to transferFrom(...) tokens
    // from the token owner&#39;s account.
    // From MonolithDAO Token.sol
    // ------------------------------------------------------------------------
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address _spender, uint256 _tokens, bytes _data) public returns (bool _success) {
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _tokens, this, _data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Accept ETH and transfer tokens to the sender
    // ------------------------------------------------------------------------
    function () public payable {
        // revert(); // don&#39;t accept ETH
        //TODO: align token decimals to ETH decimals (18)
        uint256 tokens = safeMul(price, msg.value); // price - number of token decimals in 1e-18 ETH
        // ERC20Interface(owner).transfer(msg.sender, tokens);
        balances[owner] = safeSub(balances[owner], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        emit Transfer(owner, msg.sender, tokens);
        // balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        // _totalSupply = safeAdd(_totalSupply, tokens);
        // Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value); // send ETH to the contract owner
    }

    // ------------------------------------------------------------------------
    // Allows any ERC20 tokens accidentially sent to this contract&#39;s address 
    // to be transferred to the owner address
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address _tokenAddress, uint256 _tokens) public onlyOwner returns (bool _success) {
        return ERC20Interface(_tokenAddress).transfer(owner, _tokens);
    }

    /**
    * Set price.
    *
    * @param _price new price
    */
    function setPrice (uint256 _price) public onlyOwner {
        require (_price > 0);
        price = _price;
        emit PriceChange (_price);
    }
    /**
    * Logged when fee parameters were changed.
    *
    * @param price new price
    */
    event PriceChange (uint256 price);
}