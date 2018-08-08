pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;CRP&#39; token contract
//
// Deployed to : 0xd8BD8f9727551f9020B2FB5f31fd70695a580E10
// Symbol      : CRYPTX
// Name        : CRYPTX Token
// Total supply: 100000000
// Decimals    : 18
//
// Enjoy.
//
// (c) by Moritz Neto with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
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
contract Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}



// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Own {
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
contract CRYPTXToken is Interface, Own, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping (address => bool) public frozenAccount;
    mapping(address => uint) storedAmount;

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);
    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);
    //This notifies the client&#39;s activity in storedAmount
    event FixedDepositLog(address indexed from, uint256 amount, bytes32 action);
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "CRYPTX";
        name = "CRYPTX Token";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balanceOf[0xd8BD8f9727551f9020B2FB5f31fd70695a580E10] = _totalSupply;
        emit Transfer(address(0), 0xd8BD8f9727551f9020B2FB5f31fd70695a580E10, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balanceOf[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balanceOf[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowance
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(to != 0x0);
        require(tokens > 0);              //Check if the token is not negative
        require(!frozenAccount[msg.sender]);   // Check if sender is frozen
        require(!frozenAccount[to]);     // Check if recipient is frozen
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= tokens);
        // Check for overflows
        require(safeAdd(balanceOf[to], tokens) >= balanceOf[to]);

        uint256 previousBalances = safeAdd(balanceOf[msg.sender], balanceOf[to]);

        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        require(balanceOf[msg.sender] + balanceOf[to] == previousBalances);
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
    function approve(address spender, uint tokens) public returns (bool success) {
        require(tokens > 0);
        allowance[msg.sender][spender] = tokens;
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
    // - 0 value transfers are allowance
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        // Prevent transfer to 0x0 address. Use burn() instead
        require(to != 0x0);
        //Check if the token is not negative
        require(tokens > 0);
        // Check if the sender has enough
        require(balanceOf[msg.sender] >= tokens);
        // Check for overflows
        require(safeAdd(balanceOf[to], tokens) >= balanceOf[to]);

        balanceOf[from] = safeSub(balanceOf[from], tokens);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /**
     * Destroy tokens
     *
     * Remove `amount` tokens from the system irreversibly
     *
     * @param amount the amount of money to burn
     */
    function burn(uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount);   // Check if the sender has enough
        // Subtract from the sender
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], amount);
        // Updates totalSupply
        _totalSupply = safeSub(_totalSupply, amount);
        emit Burn(msg.sender, amount);
        return true;
    }

    // @Fixed Deposit stored tokens can&#39;t be trade without taking out from FD
    function fixedDeposit(uint256 amount) public returns(bool success) {

        require(amount>0);
        require(balanceOf[msg.sender] >= amount);
        //Store amount from user&#39;s balance
        storedAmount[msg.sender] = safeAdd(storedAmount[msg.sender], amount);
        //Update user&#39;s balance
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], amount);
        emit FixedDepositLog(msg.sender, amount, "Credit");
        return true;
    }

    //@Withdraw from Fixed Deposit
    function WithdrawDeposit(uint256 amount) public returns(bool success) {

        require(amount>0);
        require(storedAmount[msg.sender] >= amount);
        //Withdraw amount from user&#39;s fixed balance
        storedAmount[msg.sender] = safeSub(storedAmount[msg.sender], amount);
        //Update user&#39;s balance
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);
        emit FixedDepositLog(msg.sender, amount, "Debit");
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

}