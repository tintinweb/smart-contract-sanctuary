/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity "0.5.1";

/* =========================================================================================================*/
// ----------------------------------------------------------------------------
// &#39;Deflationary&#39; token contract
//
// Symbol      : DTO
// Name        : Deflationary
// Total supply: 9800000
// Decimals    : 0
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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return div(mul(d,m),m);
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Deflationary is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint256 internal extras = 100;
    uint private count=1;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _owner) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = 98e5; //9800000
        owner = address(_owner);
        balances[address(owner)] =  _totalSupply * 10**uint(decimals);
        emit Transfer(address(0),address(owner), _totalSupply * 10**uint(decimals));
    }
    
    // ------------------------------------------------------------------------
    // Don&#39;t Accepts ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }
    
    function onePercent(uint256 _tokens) public view returns (uint256){
        uint roundValue = _tokens.ceil(extras);
        uint onePercentofTokens = roundValue.mul(extras).div(extras * 10**uint(2));
        return onePercentofTokens;
    }
    
    /*===============================ERC20 functions=====================================*/
    
    function totalSupply() public view returns (uint){
       return _totalSupply* 10**uint(decimals);
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
        require(to != address(0));
        require(balances[msg.sender] >= tokens );
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        uint256 tokenstoTransfer;
        
        if(count > 100){
            // calculate 1% of the tokens
            uint256 onePercenToBurn = onePercent(tokens);
            tokenstoTransfer = tokens.sub(onePercenToBurn);
            
            // burn one percent of tokens by transfering to zero address
            balances[address(0)] = onePercenToBurn;
        
            // remove burned tokens from _totalSupply
            _totalSupply = _totalSupply.sub(onePercenToBurn);
        
            // emit Transfer event to address(0)
            emit Transfer(msg.sender,address(0),onePercenToBurn);
        } 
        else {
            tokenstoTransfer = tokens;
            count++;
        }
        
        require(balances[to] + tokenstoTransfer >= balances[to]);
        
        // Transfer the unburned tokens to "to" address
        balances[to] = balances[to].add(tokenstoTransfer);
        
        // emit Transfer event to "to" address
        emit Transfer(msg.sender,to,tokenstoTransfer);
        
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
        require(from != address(0));
        require(to != address(0));
        require(tokens <= allowed[from][msg.sender]); //check allowance
        require(balances[from] >= tokens); // check if sufficient balance exist or not
        
        balances[from] = balances[from].sub(tokens);
        
        uint256 tokenstoTransfer;
        
        if(count > 100){
        // calculate 1% of the tokens
        uint256 onePercenToBurn = onePercent(tokens);
        tokenstoTransfer = tokens.sub(onePercenToBurn);
        
        // burn one percent of tokens by transfering to zero address
        balances[address(0)] = onePercenToBurn;
        
        // remove burned tokens from _totalSupply
        _totalSupply = _totalSupply.sub(onePercenToBurn);
        
        // emit Transfer event to address(0)
        emit Transfer(from,address(0),onePercenToBurn);
        } else {
            tokenstoTransfer = tokens;
            count++;
        }
        
        require(balances[to] + tokenstoTransfer >= balances[to]);
        // Transfer the unburned tokens to "to" address
        balances[to] = balances[to].add(tokenstoTransfer);
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        emit Transfer(from,to,tokenstoTransfer);
        
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success){
        require(spender != address(0));
        require(tokens <= balances[msg.sender]);
        require(tokens >= 0);
        require(allowed[msg.sender][spender] == 0 || tokens == 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
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