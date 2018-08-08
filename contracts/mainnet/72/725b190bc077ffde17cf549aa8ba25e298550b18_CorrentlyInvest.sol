pragma solidity ^0.4.18;

// Corrently CAPEX token
// Modified for https://corrently.de/token
//
// Leveraged by STROMDAO (https://stromdao.de/)
// Changes: 
//   - embedded SafeMath due to missing utilization in some functions
//    
// ----------------------------------------------------------------------------
// Based on FWD &#39;BitFwd&#39; token contract
//
// FWD tokens are mintable by the owner until the `disableMinting()` function
// is executed. Tokens can be burnt by sending them to address 0x0
//
// Deployed to : 0xe199C41103020a325Ee17Fd87934dfe7Ac747AD4
// Symbol      : FWD
// Name        : BitFwd
// Total supply: mintable
// Decimals    : 18
//
// http://www.bitfwd.xyz
// https://github.com/bokkypoobah/Tokens/blob/master/contracts/BitFwdToken.sol
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for BitFwd 2017. The MIT Licence.
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
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
contract CorrentlyInvest is ERC20Interface, Owned {
    

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    bool public mintable;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event MintingDisabled();


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "CORI";
        name = "Corrently Invest";
        decimals = 2;
        mintable = true;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Disable minting
    // ------------------------------------------------------------------------
    function disableMinting() public onlyOwner {
        require(mintable);
        mintable = false;
        emit MintingDisabled();
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] -= tokens;
        require( balances[to]+tokens >=  balances[to]);
        balances[to] += tokens;
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
        require(tokens <= balances[msg.sender]);
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        require( balances[to]+tokens >=  balances[to]);
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
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
    // Mint tokens
    // ------------------------------------------------------------------------
    function mint(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        require(mintable);
        require( balances[tokenOwner]+tokens >=  balances[tokenOwner]);
        balances[tokenOwner] += tokens;
        require(_totalSupply+tokens>=_totalSupply);
        _totalSupply += tokens;
        
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ethers
    // ------------------------------------------------------------------------
    function ()  external  {
         revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}