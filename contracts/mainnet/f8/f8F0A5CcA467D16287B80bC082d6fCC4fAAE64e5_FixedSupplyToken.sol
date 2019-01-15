pragma solidity ^0.4.24;

// ---------------------------------------------------------------------------- 
// Symbol      : UBTR
// Name        : OBETR.COM
// Total supply: 12,000,000,000
// Decimals    : 18 
// ----------------------------------------------------------------------------
//https://remix.ethereum.org/#optimize=true&version=soljson-v0.4.24+commit.e67f0147.js
//


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
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
//
// Borrowed from MiniMeToken
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
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply; 
    
    bool public crowdsaleEnabled;
    uint public ethPerToken;
    uint public bonusMinEth;
    uint public bonusPct; 

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    // ------------------------------------------------------------------------
    // Custom Events
    // ------------------------------------------------------------------------
    event Burn(address indexed from, uint256 value);
    event Bonus(address indexed from, uint256 value); 


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "UBTR";
        name = "UBETR";
        decimals = 18;
        _totalSupply = 12000000000000000000000000000;


        crowdsaleEnabled = false;
        ethPerToken = 20000;
        bonusMinEth = 0;
        bonusPct = 0; 

        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
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
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
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
    // Crowdsale 
    // ------------------------------------------------------------------------
    function () public payable {
        //crowd sale is open/allowed
        require(crowdsaleEnabled); 
        
        uint ethValue = msg.value;
        
        //get token equivalent
        uint tokens = ethValue.mul(ethPerToken);

        
        //append bonus if we have active bonus promo
        //and if ETH sent is more than then minimum required to avail bonus
        if(bonusPct > 0 && ethValue >= bonusMinEth){
            //compute bonus value based on percentage
            uint bonus = tokens.div(100).mul(bonusPct);
            
            //emit bonus event
            emit Bonus(msg.sender, bonus);
            
            //add bonus to final amount of token to be 
            //transferred to sender/purchaser
            tokens = tokens.add(bonus);
        }
        
        
        //validate token amount 
        //assert(tokens > 0);
        //assert(tokens <= balances[owner]);  
        

        //transfer from owner to sender/purchaser
        balances[owner] = balances[owner].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        
        //emit transfer event
        emit Transfer(owner, msg.sender, tokens);
    } 


    // ------------------------------------------------------------------------
    // Open the token for Crowdsale 
    // ------------------------------------------------------------------------
    function enableCrowdsale() public onlyOwner{
        crowdsaleEnabled = true; 
    }


    // ------------------------------------------------------------------------
    // Close the token for Crowdsale 
    // ------------------------------------------------------------------------
    function disableCrowdsale() public onlyOwner{
        crowdsaleEnabled = false; 
    }


    // ------------------------------------------------------------------------
    // Set the token price.  
    // ------------------------------------------------------------------------
    function setTokenPrice(uint _ethPerToken) public onlyOwner{ 
        ethPerToken = _ethPerToken;
    } 


    // ------------------------------------------------------------------------
    // Set crowdsale bonus percentage and its minimum
    // ------------------------------------------------------------------------
    function setBonus(uint _bonusPct, uint _minEth) public onlyOwner {
        bonusMinEth = _minEth;
        bonusPct = _bonusPct;
    }


    // ------------------------------------------------------------------------
    // Burn token
    // ------------------------------------------------------------------------
    function burn(uint256 _value) public onlyOwner {
        require(_value > 0);
        require(_value <= balances[msg.sender]); 

        address burner = msg.sender;
        
        //deduct from initiator&#39;s balance
        balances[burner] = balances[burner].sub(_value);
        
        //deduct from total supply
        _totalSupply = _totalSupply.sub(_value);
        
        emit Burn(burner, _value); 
    } 


    // ------------------------------------------------------------------------
    // Withdraw
    // ------------------------------------------------------------------------ 
    function withdraw(uint _amount) onlyOwner public {
        require(_amount > 0);
        
        // Amount withdraw should be less or equal to balance
        require(_amount <= address(this).balance);     
        
        owner.transfer(_amount);
    }


}