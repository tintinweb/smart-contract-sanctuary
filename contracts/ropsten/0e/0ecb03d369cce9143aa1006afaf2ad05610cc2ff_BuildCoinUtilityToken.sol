// ----------------------------------------------------------------------------
// Brickchain Investments co Utility Token Smart Contract
// Further information on https://brickchaininvestments.io/ico/
// ----------------------------------------------------------------------------
pragma solidity ^0.4.25;


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

    function safePower(uint256 A, uint256 B) public returns (uint256){
        return A**B;
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
    event Burned(uint amount);
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract BuildCoinUtilityToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate = now;
    uint public endDate;

    // Tranches and their hard cap
    uint public tranche_1;
    uint public tranche_1_cap;
    uint public tranche_2;
    uint public tranche_2_cap;
    uint public tranche_3;
    uint public tranche_3_cap;
    uint public tranche_4;
    uint public tranche_4_cap;
    uint public tranche_5;
    uint public tranche_5_cap;
    uint public tranche_6;
    uint public tranche_6_cap;
    uint public _maxSupply;

    uint256 public _tokensForTeam;
    uint256 public tokensForTeam;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function BuildCoinUtilityToken() public {
        symbol = "BSC";
        name = "BuildCoin Utility token";

        decimals = 18;

        // Token Distribution
        // ------------------------------------------------------------------------
        tokensForTeam = 600000;
        _maxSupply = 3000000;
        // ------------------------------------------------------------------------


        _tokensForTeam = safeMul(tokensForTeam, safePower(10, decimals));
        balances[msg.sender] = safeAdd(balances[msg.sender], _tokensForTeam);
        _totalSupply = safeAdd(_totalSupply, _tokensForTeam);
        Transfer(address(0), msg.sender, _tokensForTeam);

        tranche_1_cap = 50000;
        tranche_2_cap = 150000;
        tranche_3_cap = 350000;
        tranche_4_cap = 550000;
        tranche_5_cap = 900000;
        tranche_6_cap = 1000000;
        tranche_1 = now + 24 hours;
        tranche_2 = tranche_1 + 48 hours;
        tranche_3 = tranche_2 + 48 hours;
        tranche_4 = tranche_3 + 48 hours;
        tranche_5 = tranche_4 + 72 hours;
        tranche_6 = tranche_5 + 72 hours;
        endDate = now + 13 days;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
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
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
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
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // BSC Tokens per 1 ETH per Tranche
    // ------------------------------------------------------------------------
    function () public payable {
        require (msg.value > 0);
        require(now >= startDate && now <= endDate);
        uint tokens;
        if ((now <= endDate) && ((_totalSupply - tokensForTeam) <= _maxSupply)) {
            if ((now <= tranche_1) && ((_totalSupply - tokensForTeam) <= tranche_1_cap)){
                tokens = msg.value * 266;
            } else if ((now <= tranche_2) && ((_totalSupply - tokensForTeam) <= safeAdd(tranche_1_cap, tranche_2_cap))) {
                tokens = msg.value * 250;
            } else if ((now <= tranche_3) && ((_totalSupply - tokensForTeam) <= safeAdd(safeAdd(tranche_1_cap, tranche_2_cap), tranche_3_cap))) {
                tokens = msg.value * 235;
            } else if ((now <= tranche_4) && ((_totalSupply - tokensForTeam) <= safeAdd(safeAdd(tranche_1_cap, tranche_2_cap), safeAdd(tranche_3_cap, tranche_4_cap)))) {
                tokens = msg.value * 222;
            } else if ((now <= tranche_5) && ((_totalSupply - tokensForTeam) <= safeAdd(safeAdd(safeAdd(tranche_1_cap, tranche_2_cap), safeAdd(tranche_3_cap, tranche_4_cap)), tranche_5_cap))) {
                tokens = msg.value * 210;
            } else if (now <= tranche_6) {
                tokens = msg.value * 167;
            } else {
                tokens = msg.value * 100;
            }
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            _totalSupply = safeAdd(_totalSupply, tokens);
            Transfer(address(0), msg.sender, tokens);
            owner.transfer(msg.value);
        }
    }



    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}