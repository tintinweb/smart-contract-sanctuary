pragma solidity ^0.4.18;


// ----------------------------------------------------------------------------

// Spendcoin Contract
//
// Symbol      : SPND
// Name        : Spendcoin
// Total supply: 2,000,000,000.000000000000000000
// Decimals    : 18
// Website     : https://spendcoin.org
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------

// Safe maths

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

// Owned contract

// ----------------------------------------------------------------------------

contract Owned {

    address public owner;

    function Owned() public {

        owner = msg.sender;

    }


    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }

}

contract Tokenlock is Owned {
    
    uint lockStartTime = 0;   //time from when token will be locked
    uint lockEndTime = 0;     //time from when token will be locked
    uint8 isLocked = 0;       //flag indicates if token is locked

    event Freezed(uint starttime, uint endtime);
    event UnFreezed();

    modifier validLock {
        require(isLocked == 0 || (now < lockStartTime || now > lockEndTime));
        _;
    }
    
    function freezeTime(uint _startTime, uint _endTime) public onlyOwner {
        isLocked = 1;
        lockStartTime = _startTime;
        lockEndTime = _endTime;
        
        emit Freezed(lockStartTime, lockEndTime);
    }
    
    function freeze() public onlyOwner {
        isLocked = 1;
        lockStartTime = 0;
        lockEndTime = 90000000000;
        
        emit Freezed(lockStartTime, lockEndTime);
    }

    function unfreeze() public onlyOwner {
        isLocked = 0;
        lockStartTime = 0;
        lockEndTime = 0;
        
        emit UnFreezed();
    }
}


// ----------------------------------------------------------------------------

// ERC20 Token, with the addition of symbol, name and decimals and an

// initial fixed supply

// ----------------------------------------------------------------------------

contract Spendcoin is ERC20Interface, Tokenlock {

    using SafeMath for uint;


    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;


    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;



    // ------------------------------------------------------------------------

    // Constructor

    // ------------------------------------------------------------------------

    function Spendcoin() public {

        symbol = "SPND";

        name = "Spendcoin";

        decimals = 18;

        _totalSupply = 2000000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;

        emit Transfer(address(0), owner, _totalSupply);

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

    // - Owner&#39;s account must have sufficient balance to transfer

    // - 0 value transfers are allowed

    // ------------------------------------------------------------------------

    function transfer(address to, uint tokens) public returns (bool success) {

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

    // Do accept ETH

    // ------------------------------------------------------------------------

    function () public payable {


    }


    // ------------------------------------------------------------------------
    // Owner can withdraw ether if token received.
    // ------------------------------------------------------------------------
    function withdraw() public onlyOwner returns (bool result) {
        address tokenaddress = this;
        return owner.send(tokenaddress.balance);
    }
    
    // ------------------------------------------------------------------------

    // Owner can transfer out any accidentally sent ERC20 tokens

    // ------------------------------------------------------------------------

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}