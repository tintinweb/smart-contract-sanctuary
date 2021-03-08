/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
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
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "safemath");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "safemath"); 
        c = a - b;
    } 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "safemath");
    } 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "safemath");
        c = a / b;
    }
}

contract BurningCoin is ERC20Interface, SafeMath {
    
    string private _name = "Burning Coin";
    string private _symbol = "BURN";
    uint8 private _decimals = 18;

    uint private _totalSupply = 100000000 * 10 ** uint(_decimals);
    uint private _totalBurn = 0;
    uint private _totalBounty = 0;
    uint private _transferCount = 0;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    mapping(uint => address) private holders;
    uint private holdersCount = 0;
    
    address private owner;
    address private zero = address(0);

    constructor() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
        emit Transfer(zero, owner, _totalSupply);
    }

    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    
    function totalSupply() public view returns (uint) { return _totalSupply; }
    function totalBurn() public view returns (uint) { return _totalBurn; }
    function totalBounty() public view returns (uint) { return _totalBounty; }

    function balanceOf(address tokenOwner) public view returns (uint balance) { return balances[tokenOwner]; }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) { return allowed[tokenOwner][spender]; }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) { 
        _transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint tokensSent = _transfer(from, to, tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokensSent);
        return true;
    }
    
    function _transfer(address from, address to, uint tokens) private returns (uint) {
        require(to != zero, "zero-address transfer");
        require(from != to, "equal-adress");
        require(from == msg.sender, "access denied");
        require(tokens > 0, "zero tokens sent");
        require(balances[from] >= tokens, "not enough tokens");
        
        if (!checkExist(from)) registerHolder(from);
        if (!checkExist(to)) registerHolder(to);
        
        uint burnAmount   = 0;
        uint feeAmount    = 0;
        uint bountyAmount = 0;
        uint tokensSent = tokens;
        
        if (from != owner) {
            burnAmount   = tokens *  50 / 10000; // 0.50 % burn
            feeAmount    = tokens *  25 / 10000; // 0.25 % fee
            bountyAmount = tokens * 100 / 10000; // 1.00 % bounty
            
            burn(from, burnAmount);
            fee(from, feeAmount);
            uint realBounty = bounty(from, bountyAmount);
            tokensSent -= burnAmount + feeAmount + realBounty;
        }

        pureTransfer(from, to, tokensSent);
        emit Transfer(from, to, tokensSent);
        return tokensSent;
    }
    
    function checkExist(address account) private view returns (bool) {
        if (owner == account) return true;
        for (uint i = 0; i < holdersCount; i++) {
            if (holders[i] == account)
                return true;
        }
        return false;
    }
    
    function registerHolder(address account) private {
        if (account != owner) {
            holders[holdersCount] = account;
            holdersCount++;
        }
    }

    function pureTransfer(address source, address target, uint tokens) private {
        balances[source] = safeSub(balances[source], tokens);
        balances[target] = safeAdd(balances[target], tokens);
    }

    function burn(address provider, uint amount) private {
        pureTransfer(provider, zero, amount);
        _totalSupply -= amount;
        _totalBurn += amount;
    }
    
    function fee(address provider, uint amount) private {
        pureTransfer(provider, owner, amount);
    }
    
    function bounty(address provider, uint amount) private returns (uint) {
        uint totalSum = 0;
        for (uint i = 0; i < holdersCount; i++) {
            address curAddress = holders[i];
            uint curBalance = balances[curAddress];
            if (curBalance == 0) continue;
            // if (curAddress == provider) continue;
            uint curBounty = amount * curBalance / _totalSupply;
            totalSum += curBounty;
            balances[curAddress] = safeAdd(balances[curAddress], curBounty);
        }
        if (totalSum > 0) {
            balances[provider] = safeSub(balances[provider], totalSum);
            _totalBounty += totalSum; 
        }
        return totalSum;
    }
}