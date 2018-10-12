pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function transfer(address to, uint256 tokens) public returns (bool);
    function balanceOf(address tokenOwner) public view returns (uint256);
    function approve(address spender, uint256 tokens) public returns (bool);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool);
    function allowance(address tokenOwner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract StandardToken is ERC20Interface, SafeMath {

    uint256 public totalSupply;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    
    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }
    
    function transfer(address _to, uint256 _tokens) public returns (bool) {
        require(_tokens <= balances[msg.sender]);
        require(_to != 0x0);
        require(_tokens >= 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }
    
    function balanceOf(address _tokenOwner) public view returns (uint256) {
        return balances[_tokenOwner];
    }
    
    function approve(address _spender, uint256 _tokens) public returns (bool) {
        require(_tokens >= 0);
        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _tokens) public returns (bool) {
        require(_tokens >= 0);
        require(_tokens <= balances[_from]);
        require(_tokens <= allowed[_from][msg.sender]);
        require(_to != 0x0);
        
        balances[_from] = safeSub(balances[_from], _tokens);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _tokens);
        balances[_to] = safeAdd(balances[_to], _tokens);
        emit Transfer(_from, _to, _tokens);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
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

contract Pausable is Owned {
    event Pause();
    event Unpause();
    
    bool public paused = false;
    
    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract MtbitToken is StandardToken, Pausable {
    string public constant symbol = &#39;MTB&#39;;
    string public constant name = &#39;Mtbit Token&#39;;
    uint256 public constant decimals = 18;
    uint256 public constant initSupply = 100000000 * 10**decimals;        
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        balances[msg.sender] = initSupply;
        emit Transfer(0x0, msg.sender, initSupply);
        totalSupply = initSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public view returns (uint256) {
        return super.balanceOf(_tokenOwner);
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address _to, uint256 _tokens) public whenNotPaused returns (bool) {
        return super.transfer(_to, _tokens);
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // ------------------------------------------------------------------------
    function approve(address _spender, uint256 _tokens) public whenNotPaused returns (bool) {
        return super.approve(_spender, _tokens);
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // ------------------------------------------------------------------------
    function transferFrom(address _from, address _to, uint256 _tokens) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _tokens);
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return super.allowance(_owner, _spender);
    }
    
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);

    function burn(uint256 _tokens) public whenNotPaused returns (bool) {
        require(_tokens >= 0);
        require(balances[msg.sender] >= _tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        totalSupply = safeSub(totalSupply, _tokens);
        emit Burn(msg.sender, _tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Can accept ether
    // ------------------------------------------------------------------------
    function () public payable {
    }

    // transfer balance to owner
    function withdrawEther(uint256 amount) public onlyOwner returns (bool) {
        owner.transfer(amount);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) public onlyOwner returns (bool) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}