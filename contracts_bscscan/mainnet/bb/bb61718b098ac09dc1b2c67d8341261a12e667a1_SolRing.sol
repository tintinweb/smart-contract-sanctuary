/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
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
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}
// ----------------------------------------------------------------------------
// Dev Tax 
// ----------------------------------------------------------------------------

contract ReceiveETHERandSendPercentageToAnotherAddress{

    // if funds are received in this contract then 
    // Pay 1% to the target address
    address payable target = 0x3a5FDD1067767F78d4AACA11165070ee63Cec3B6;

    // Fallback function for incoming ether 
    function () payable external{
       
        //Send 1% to the target address configured above
        target.transfer(msg.value/500);

        //continue processing
    }
}

contract TransfertTokenAndPercentageToTargetAddress{

    // pay 1% of all transactions to target address
    address payable target = 0x004D1425680405e467ebC5642249d0DbD079b1e5;

    // state variables for your token to track balances and to test
    mapping (address => uint) public balanceOf;
    uint public totalSupply;

    // create a token and assign all the tokens to the creator to test
    constructor(uint _totalSupply) public {
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }

    // the token transfer function with the addition of a 1% share that
    // goes to the target address specified above
    function transfer(address _to, uint amount) public {

        // calculate the share of tokens for your target address
        uint shareForX = amount/500;

        // save the previous balance of the sender for later assertion
        // verify that all works as intended
        uint senderBalance = balanceOf[msg.sender];
        
        // check the sender actually has enough tokens to transfer with function 
        // modifier
        require(senderBalance >= amount, 'Not enough balance');
        
        // reduce senders balance first to prevent the sender from sending more 
        // than he owns by submitting multiple transactions
        balanceOf[msg.sender] -= amount;
        
        // store the previous balance of the receiver for later assertion
        // verify that all works as intended
        uint receiverBalance = balanceOf[_to];

        // add the amount of tokens to the receiver but deduct the share for the
        // target address
        balanceOf[_to] += amount-shareForX;
        
        // add the share to the target address
        balanceOf[target] += shareForX;

        // check that everything works as intended, specifically checking that
        // the sum of tokens in all accounts is the same before and after
        // the transaction. 
        assert(balanceOf[msg.sender] + balanceOf[_to] + shareForX ==
            senderBalance + receiverBalance);
    }
}


contract SolRing is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "SolRing";
        symbol = "Sol";
        decimals = 18;
        _totalSupply = 1000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}