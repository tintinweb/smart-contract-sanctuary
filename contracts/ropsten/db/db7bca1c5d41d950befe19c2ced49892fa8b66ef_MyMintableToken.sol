pragma solidity ^0.5.0;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "safeAdd integer overflow");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "safeSub integer underflow");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "safeMul integer overflow");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "safeDiv divide by zero");
        c = a / b;
    }
}

contract Owned {
    
    address public owner;
    address public newOwner;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    
    constructor() public {
        owner = msg.sender;
    }
    
    // only the owner can run a function
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can access this function");
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Only the new owner can access this function");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0); // set the next new owner to burn address
    }
    
}

contract ERC20Interface {
    
    // token supply
    function totalSupply() public view returns (uint256);
    
    // transfering tokens from sender
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    // allowing others to transfer tokens
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    
    // events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract MyMintableToken is ERC20Interface, Owned, SafeMath {
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public _totalSupply;
    
    bool private _mintLocked;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        
        // token parameters
        symbol = "XMINE";
        name = "My Mintable Token v3";
        decimals = 18;
        uint256 wholeTokens = 1e6;
        
        // set up supply
        _totalSupply = 0;
        _mintLocked = false;
        uint256 supply = wholeTokens * (uint256(10) ** decimals);
        
        // initial creation
        mint(owner, supply);
        
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        
        // current total supply is the supply - amount sent to burned address
        return safeSub(_totalSupply, balances[address(0)]);
        
    }
    
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        // remove from sender and add to recipient.
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        
        // send transfer event
        emit Transfer(msg.sender, _to, _value);
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
    function approve(address _spender, uint256 _value) public returns (bool success) {
        
        // set the value to be able to be spent from this account to _spender
        allowed[msg.sender][_spender] = _value;
        
        // send approval event
        emit Approval(msg.sender, _spender, _value);
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        
        // subtract from sender, add to recipient, and subtract from allowed sending amount
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        
        // send transfer event
        emit Transfer(_from, _to, _value);
        return true;
        
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        
        return allowed[_owner][_spender];
        
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address _spender, uint256 _value, bytes memory _data) public returns (bool success) {
        
        // set the allowed amount
        allowed[msg.sender][_spender] = _value;
        
        // send the approval event
        emit Approval(msg.sender, _spender, _value);
        ApproveAndCallFallBack(_spender).receiveApproval(msg.sender, _value, address(this), _data);
        return true;
        
    }
    
    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert("This contract doesn&#39;t accept ETH");
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // get if the mint has been locked
    function mintLocked() public view returns (bool) {
        return _mintLocked;
    }
    
    // can permininantly lock the supply and prevent the minting of new coins
    function lockMinting() public onlyOwner returns (bool success) {
        
        // can&#39;t lock what has already been locked
        require(!mintLocked(), "Minting has already been locked");
        
        // lock
        _mintLocked = true;
        
        emit LockedMinting(msg.sender);
        return true;
        
    }
    
    // a special burn function
    function burn(uint256 _value) public returns (bool success) {
        
        // make sure the burn can happen
        require(balances[msg.sender] <= _value, "Can&#39;t burn more than you own.");
        
        // remove burned coins from sender&#39;s account
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        // remove burned coins from total supply
        _totalSupply = safeSub(_totalSupply, _value);
        
        // send out burn event
        emit Burn(msg.sender, _value);
        return true;
        
    }
    
    // Owner can mint new coins to any address
    function mint(address _to, uint256 _value) public onlyOwner returns (bool success) {
        
        // make sure minting is allowed
        require(!mintLocked(), "Minting has been locked");
        
        // add the new tokens to the total supply
        _totalSupply = safeAdd(_totalSupply, _value);
        // add brand new coins to the address
        balances[_to] = safeAdd(balances[_to], _value);
        
        // send out mint event
        emit Mint(owner, _to, _value);
        return true;
        
    }
    
    event Burn(address indexed _owner, uint256 _value);
    event Mint(address indexed _owner, address indexed _to, uint256 _value);
    event LockedMinting(address indexed _owner);
    
}