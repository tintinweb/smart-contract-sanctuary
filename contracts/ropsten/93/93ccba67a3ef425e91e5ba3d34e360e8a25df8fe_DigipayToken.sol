pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// &#39;Digipay&#39; CROWDSALE token contract
//
// Deployed to : 0x93ccba67a3ef425e91e5ba3d34e360e8a25df8fe
// Symbol      : DIP
// Name        : Digipay Token
// Total supply: 180000000
// Decimals    : 18
//
// 2018 (c) by Digipay
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// @title SafeMath
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
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
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract DigipayToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate;
    uint public bonusEnds50;
    uint public bonusEnds20;
    uint public bonusEnds15;
    uint public bonusEnds10;
    uint public bonusEnds5;
    uint public endDate;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function DigipayToken() public {
        symbol = "DIP";
        name = "Digipay Token";
        decimals = 18;
        _totalSupply = 180000000000000000000000000;
        balances[0x3b16c520a42b960E0278144C6701419558CBfaeB] = _totalSupply;
        Transfer(address(0), 0x3b16c520a42b960E0278144C6701419558CBfaeB, _totalSupply);
        bonusEnds50 = now + 4 weeks;
        bonusEnds20 = now + 7 weeks;
        bonusEnds15 = now + 8 weeks;
        bonusEnds10 = now + 9 weeks;
        bonusEnds5 = now + 10 weeks;
        endDate = now + 11 weeks;

    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address spender, uint256 tokens) public returns (bool success) {
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
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // 5,000 DIP Tokens per 1 ETH (No bonus)
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint256 tokens;
        if (now <= bonusEnds50) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 7500;
            } else {
            tokens = msg.value * 8250;
            }
        }
        if (now > bonusEnds50 && now <= bonusEnds20) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 6000;
            } else {
            tokens = msg.value * 6600;
            }
        }
        if (now > bonusEnds20 && now <= bonusEnds15) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 5750;
            } else {
            tokens = msg.value * 6325;
            }
        }
        if (now > bonusEnds15 && now <= bonusEnds10) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 5500;
            } else {
            tokens = msg.value * 6050;
            }
        }
        if (now > bonusEnds10 && now <= bonusEnds5) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 5250;
            } else {
            tokens = msg.value * 5775;
            }
        }
        if (bonusEnds5 < now) {
            if (msg.value < 10000000000000000000) {
            tokens = msg.value * 5000;
            } else {
            tokens = msg.value * 5500;
            }
        }
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        _totalSupply = safeSub(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }



    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}