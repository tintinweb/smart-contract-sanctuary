pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// NRM token main contract
//
// Symbol       : NRM
// Name         : Neuromachine
// Total supply : 4.958.333.333,000000000000000000 (burnable)
// Decimals     : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe math
// ----------------------------------------------------------------------------
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// NRM ERC20 Token - Neuromachine token contract
// ----------------------------------------------------------------------------
contract NRM is ERC20Interface, Owned {
    using SafeMath for uint;

    bool public running = true;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    address public FreezeAddress;
    uint256 public FreezeTokens;
    uint256 public FreezeTokensReleaseTime;

    // ------------------------------------------------------------------------
    // Contract init. Set symbol, name, decimals and initial fixed supply
    // ------------------------------------------------------------------------
    function NRM() public {
        symbol = "NRM";
        name = "Neuromachine";
        decimals = 18;
        _totalSupply = 4958333333 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    // ------------------------------------------------------------------------
    // Team and develop tokens transfer to freeze account for 365 days
    // ------------------------------------------------------------------------
        FreezeAddress = 0x7777777777777777777777777777777777777777;
        FreezeTokens = _totalSupply.mul(30).div(100);

        balances[owner] = balances[owner].sub(FreezeTokens);
        balances[FreezeAddress] = balances[FreezeAddress].add(FreezeTokens);
        emit Transfer(owner, FreezeAddress, FreezeTokens);
        FreezeTokensReleaseTime = now + 365 days;
    }


    // ------------------------------------------------------------------------
    // Team and tokens unfreeze after 365 days from contract deploy
    // ------------------------------------------------------------------------

    function unfreezeTeamTokens(address unFreezeAddress) public onlyOwner returns (bool success) {
        require(balances[FreezeAddress] > 0);
        require(now >= FreezeTokensReleaseTime);
        balances[FreezeAddress] = balances[FreezeAddress].sub(FreezeTokens);
        balances[unFreezeAddress] = balances[unFreezeAddress].add(FreezeTokens);
        emit Transfer(FreezeAddress, unFreezeAddress, FreezeTokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Start-stop contract functions:
    // transfer, approve, transferFrom, approveAndCall
    // ------------------------------------------------------------------------

    modifier isRunnning {
        require(running);
        _;
    }


    function startStop () public onlyOwner returns (bool success) {
        if (running) { running = false; } else { running = true; }
        return true;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
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
    function approve(address spender, uint tokens) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(tokens != 0);
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
    function approveAndCall(address spender, uint tokens, bytes data) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Tokens burn
    // ------------------------------------------------------------------------

    function burnTokens(uint256 tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }    


    // ------------------------------------------------------------------------
    // Tokens multisend from owner only by owner
    // ------------------------------------------------------------------------
    function multisend(address[] to, uint256[] values) public onlyOwner returns (uint256) {
        for (uint256 i = 0; i < to.length; i++) {
            balances[owner] = balances[owner].sub(values[i]);
            balances[to[i]] = balances[to[i]].add(values[i]);
            emit Transfer(owner, to[i], values[i]);
        }
        return(i);
    }
}