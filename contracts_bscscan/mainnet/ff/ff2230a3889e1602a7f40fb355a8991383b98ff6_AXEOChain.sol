/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity 0.5.16;
// ----------------------------------------------------------------------------
// AXEOChain is a decentralized one-stop platform on binance smartchain.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// SafeMath
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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }
}

// ----------------------------------------------------------------------------
// BEP20 Owned Standard contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

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
	
	function returnOwner() public view returns(address){
		return owner;
	}
}

// ----------------------------------------------------------------------------
// BEP20 Token Standard Interface without token mint function
// ----------------------------------------------------------------------------
contract BEP20Interface {
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
// BEP20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract AXEOChain is BEP20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol = "AXEO";
    string public  name = "AXEOChain";
    uint8 public decimals = 18;
    uint public _totalSupply = 300000000000000000000000; //300.000
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address _owner) public {
        owner = address(_owner);
        balances[address(owner)] =  _totalSupply;
        emit Transfer(address(0),address(owner), _totalSupply);
    }
    
    // ------------------------------------------------------------------------
    // Don't Accepts BNB / instead of deposit balances
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }
    
    /*===============================BEP20 functions=====================================*/
    
    function totalSupply() public view returns (uint){
       return _totalSupply;
    }
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // prevent transfer to 0x0, use burn instead
        require(to != address(0));
        require(balances[msg.sender] >= tokens );
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        require(balances[to] + tokens >= balances[to]);
        
        // Transfer the unburned tokens to "to" address
        balances[to] = balances[to].add(tokens);
        
        // emit Transfer event to "to" address
        emit Transfer(msg.sender,to,tokens);
        
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
        require(balances[from] >= tokens); // check if sufficient balance exist or not
        
        balances[from] = balances[from].sub(tokens);
        
        
        require(balances[to] + tokens >= balances[to]);
        // Transfer the unburned tokens to "to" address
        balances[to] = balances[to].add(tokens);
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        emit Transfer(from,to,tokens);
        
        return true;
    }
    
     //deleteTokens / instead of burn tokens
    function deleteTokens(uint256 tokens) public onlyOwner{
        require(tokens >= 0);
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success){
        require(allowed[msg.sender][spender] == 0 || tokens == 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
}