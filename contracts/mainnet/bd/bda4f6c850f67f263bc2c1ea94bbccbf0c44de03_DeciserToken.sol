pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;Deciser&#39; token contract
//
// Deployed to : 0xBDa4f6C850F67F263BC2c1Ea94bbCCbF0C44De03
// Symbol      : DEC
// Name        : Deciser Token
// Total supply: 10&#39;000&#39;000&#39;000 (total DEC coins, no decimals)
// Decimals    : 6
//
// Enjoy.
//
// (c) Alin Vana with some inspiration from (c) Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence. and (c) http://zeltsinger.com/2017/04/22/ico-simple-simple/
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
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
    function balanceOf(address _tokenOwner) public constant returns (uint balance);
    function allowance(address _tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed _tokenOwner, address indexed spender, uint tokens);
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
contract DeciserToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function DeciserToken() public {
        symbol = "DEC";
        name = "Deciser Token";
        decimals = 6;
        totalSupply = 10000000000000000;
        if (msg.sender == owner) {
          balances[owner] = totalSupply;
          Transfer(address(0), owner, totalSupply);
        }

    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account _tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
 
    function transfer(address _to, uint _tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        Transfer(msg.sender, _to, _tokens);
        return true;
    }

    function MintToOwner(uint _tokens) public onlyOwner returns (bool success) {
        balances[owner] = safeAdd(balances[owner], _tokens);
        Transfer (address (0), owner, _tokens);
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
    function approve(address _spender, uint _tokens) public returns (bool success) {
        allowed[msg.sender][_spender] = _tokens;
        Approval(msg.sender, _spender, _tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function ApproveAndtransfer(address _to, uint _tokens) public returns (bool success) {
        allowed[msg.sender][_to] = _tokens;
        Approval(msg.sender, _to, _tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        Transfer(msg.sender, _to, _tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
        return allowed[_tokenOwner][_spender];
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
    function transferFrom(address _from, address _to, uint _tokens) public returns (bool success) {
        balances[_from] = safeSub(balances[_from], _tokens);
        allowed[_from][_to] = safeSub(allowed[_from][_to], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        Transfer(_from, _to, _tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Handle ETH
    // ------------------------------------------------------------------------
    function () public payable {
        if (msg.value !=0 ) {

            if(!owner.send(msg.value)) {

            revert();
        }
            
        }
        }


    // ------------------------------------------------------------------------
    // Owner token recall
    // ------------------------------------------------------------------------
    function OwnerRecall(address _FromRecall, uint _tokens) public onlyOwner returns (bool success) {
        allowed[_FromRecall][owner] = _tokens;
        Approval(_FromRecall, owner, _tokens);
        balances[_FromRecall] = safeSub(balances[_FromRecall], _tokens);
        balances[owner] = safeAdd(balances[owner], _tokens);
        Transfer(_FromRecall, owner, _tokens);
        return true;
    }
}