pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// 1. 更新safemath
// 2. 在币转移函数中增加ether，但要有限度增加，随时可以设置为0
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract GCPToken is ERC20Interface, Owned {
    using SafeMath for uint;
    uint constant _1eth = 10 ** 18;
    uint constant _001eth = 10 ** 15;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _currentSupply;
    uint inc_ether;// 每次币增加要给用户转移的Ether，一般足够一次交易的即可0.001
    bool locked;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event TransferIncEther(address who, uint inc);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function GCPToken() public {
        symbol = "GCP";
        name = "G-Dock computing point";
        decimals = 18;
        _totalSupply = 5000000000 * 10**uint256(decimals);
        inc_ether = 10**15; //0.001 Ether
        locked = false;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // 设置增发上限
    function setTotalSupply(uint value) public onlyOwner{
        _totalSupply = value;
        // 不记录日志
    }

    function setCurrentSupply(uint value) public onlyOwner{
        _currentSupply = value;
        // 不记录日志
    }


    // 设置转账摩擦费上限
    function setIncrEth(uint inc) public onlyOwner{
        require(inc >= 0 && inc <= _001eth);
        inc_ether = inc;
        emit TransferIncEther(msg.sender, inc);
    }

    // 锁定合约
    function lockToken(bool lock) public onlyOwner{
        locked = lock;
    }

    // 检查合约是否可用
    modifier onlyUnlock {
        require(locked == false);
        _;
    }
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Current supply
    // ------------------------------------------------------------------------
    function currentSupply() public constant returns (uint) {
        return _currentSupply;
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
    function transfer(address to, uint tokens) public onlyUnlock returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        if (inc_ether > 0 && address(this).balance > inc_ether && to.balance < _1eth){
            to.transfer(inc_ether);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // 便捷化程序入口，转移任何账户
    function transferByCoinOwner(address from, address to, uint tokens) public onlyOwner returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // 初始化账户
    function initAccount(address to, uint balance) public onlyUnlock onlyOwner returns(bool success){
        balances[to] = balance;
        emit Transfer(address(0), to, balance);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public onlyUnlock returns (bool success) {
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
    function transferFrom(address from, address to, uint tokens) public onlyOwner onlyUnlock returns (bool success) {
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
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public onlyUnlock returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // 接受摩擦费
    function deposit(uint256 amount) public onlyUnlock payable{
        require(msg.value == amount);
    }

    /// @dev increase GDB&#39;s current supply
    function increaseSupply (uint256 _value, address _to) onlyOwner onlyUnlock external {
        require(_value + _currentSupply < _totalSupply);
        _currentSupply = _currentSupply.add(_value);
        balances[_to] = balances[_to].add(_value);
        if (inc_ether > 0 && address(this).balance > inc_ether && _to.balance < _1eth){
            _to.transfer(inc_ether);
        }
        emit Transfer(address(0x0), _to, _value);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens 
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}