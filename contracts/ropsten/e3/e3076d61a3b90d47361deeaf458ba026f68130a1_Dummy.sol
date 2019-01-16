pragma solidity 0.4.25;

// ----------------------------------------------------------------------------
// &#39;Dummy&#39; token contract

// Symbol      : DUMMY
// Name        : Dummy
// Total supply: 1000000000
// Decimals    : 18
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
contract Dummy is ERC20Interface, Owned {
    using SafeMath for uint256;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint256) dividendBalanceOf;
    mapping(address => uint256) dividendCreditedTo;
    
    mapping(address => bool) addressCounted;
    
    uint256 public totalOwners;
    address[] public holders; 
    
    uint256 public dividendPerOwner;
    
    

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _owner) public {
        symbol = "DY";
        name = "Dummy";
        decimals = 18;
        _totalSupply = totalSupply();
        owner = _owner;
        totalOwners = 0;
        balances[owner] = _totalSupply;
        record(owner);
        emit Transfer(address(0),owner, _totalSupply);
    }
    
    function record(address account) internal {
        // this checks account is not recorded before but account is new and 
        // have balance greater than zero
        if((!addressCounted[account]) && (balances[account] > 0)){
                totalOwners++;
                addressCounted[account] = true;
                holders.push(account);
        } 
        // this checks account is recorded before but account is empty now and 
        // have balance equal to zero
        else if((addressCounted[account]) && (balances[account] == 0)){
            totalOwners--;
            addressCounted[account] = false;
            //update(account);
            uint256 amount = dividendBalanceOf[account];
            dividendBalanceOf[account] = 0;
            account.transfer(amount);
        }
    }
    
    function freeTokens(address receiver, uint tokenAmount) external onlyOwner {
        transfer(receiver, tokenAmount*10**uint(decimals));
    }
    
    // this will accept ether deposits
    function() public payable{
        // dividendPerOwner = dividendPerOwner.add((msg.value).div(totalOwners));
        dividendPerOwner = (msg.value).div(totalOwners); 
        for(uint i=0; i< totalOwners; i++){ 
            address account = holders[i];
            dividendBalanceOf[account] = dividendPerOwner;
        }
    }
    
        
    function withDraw() public returns(bool success){
        require(addressCounted[msg.sender]);
        // update(msg.sender);
        uint256 amount = dividendBalanceOf[msg.sender];
        dividendBalanceOf[msg.sender] = 0;
        msg.sender.transfer(amount);
        return true;
    }
    
    /*function update(address account) internal {
        uint256 owed = dividendPerOwner.sub(dividendCreditedTo[account]);
        dividendBalanceOf[account] = dividendBalanceOf[account].add(owed);
        dividendCreditedTo[account] = dividendPerOwner;
    }*/
    
    /** ERC20Interface function&#39;s implementation **/
    
    function totalSupply() public view returns (uint){
       return 1e28; // 10 billion 
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
        // prevent transfer to 0x0, use burn instead
        require(to != 0x0);
        require(balances[msg.sender] >= tokens );
        require(balances[to] + tokens >= balances[to]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        /*Call a record function */
        record(to);
        record(msg.sender);
        emit Transfer(msg.sender,to,tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
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
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens);
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        /*Call a record function */
        record(to);
        record(from);
        emit Transfer(from,to,tokens);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
}