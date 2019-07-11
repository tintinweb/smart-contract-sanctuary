/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity >=0.4.22 <0.6.0;

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

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"Only the owner of the contract can use this function");
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
    bool internal _paused;
    
    function paused() public view returns (bool) {
        return _paused;
    }
    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
}

contract aaaaaa is ERC20Interface, Owned, Pausable {
        
    using SafeMath for uint;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint)blockedTime;
   
    uint _totalSupply;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public ownersRemaining;

    event Pause(address indexed sender);
    event Unpause(address indexed sender);
    event Burn(address indexed from,address indexed to, uint tokens, address indexed sender);
    event Mint(uint tokenIncrease, address indexed sender);
    
    constructor () public {
        symbol = "IZT";
        name = "iZiFinance Token";
        decimals = 0;
        _totalSupply = 10000000;
        balances[owner] = _totalSupply;
        ownersRemaining = 3;
        emit Transfer(address(0), owner, _totalSupply);
    }
    
    modifier notBlocked(){
        require(blockedTime[msg.sender] <= now,"Blocked: There still blocked time remaining");
        _;
    }
    
    //ERC20
    function totalSupply() public view returns (uint){
        return _totalSupply.sub(balances[address(0)]);
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){
        return allowed[tokenOwner][spender];        
    }
    
    function transfer(address to, uint tokens) public whenNotPaused notBlocked returns (bool success){
        require(balances[msg.sender] >= tokens,"Insufficient balance");
        require(tokens > 0,"Can&#39;t send a negative amount of tokens");
        require(to != address(0x0),"Can&#39;t send to a null address");
        executeTransfer(msg.sender,to, tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function approve(address spender, uint tokens) public whenNotPaused notBlocked returns (bool success){
        require(balances[msg.sender] >= tokens,"Insufficient amount of tokens");
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
        
    }
    
    function transferFrom(address from, address to, uint tokens) public whenNotPaused notBlocked returns (bool success){
        require(balances[from] >= tokens,"Insufficient balance");
        require(allowed[from][msg.sender] >= tokens,"Insufficient allowance");
        require(tokens > 0,"Can&#39;t send a negative amount of tokens");
        require(to != address(0x0),"Can&#39;t send to a null address");
        executeTransfer(from, to, tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    //iZiFinance Token
    function executeTransfer(address from,address to, uint tokens) private{
        uint previousBalances = balances[from] + balances[to];
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        require((balances[from] + balances[to] == previousBalances),"The balance overflowed");
    }
    
    //Pausable
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Pause(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpause(msg.sender);
    }
    
    //Mintable
    function mint(uint tokenIncrease) public whenNotPaused onlyOwner{
        require(tokenIncrease > 0,"Can&#39;t mint a negative number");
        uint oldTotalSupply = _totalSupply;
        _totalSupply = _totalSupply.add(tokenIncrease);
        balances[owner] = balances[owner].add(tokenIncrease);
        emit Mint(tokenIncrease, msg.sender);
        require(_totalSupply > oldTotalSupply,"Total supply overflowed");
    }
    
    //Burnable
    function burnTokens(address from, address to)public whenNotPaused onlyOwner{
        require(to != address(0x0),"Can&#39;t send to a null address");
        uint previousBalances = balances[from] + balances[to];
        uint oldbalance = balanceOf(from);
        balances[from] = balances[from].sub(oldbalance);
        balances[address(0x0)] = balances[address(0x0)].add(oldbalance);
        emit Transfer(from,address(0x0),oldbalance);
        mint(oldbalance);
        balances[owner] = balances[owner].sub(oldbalance);
        balances[to] = balances[to].add(oldbalance);
        emit Burn(from, to, oldbalance,msg.sender);
        require((balances[from] + balances[to] == previousBalances),"The balance overflowed");
    }
    
    //Initial Owner Transfer
    function sendToOwners(address to, uint value) public whenNotPaused onlyOwner{
        require(ownersRemaining > 0,"All initial owners were already set");
        uint oldUsers = ownersRemaining;
        executeTransfer(owner,to,value);
        blockedTime[to] = now + 1095 days;
        ownersRemaining = ownersRemaining - 1;
        emit Transfer(owner, to, value);
        assert(ownersRemaining < oldUsers);
    }
    
    function seeBlockedTime(address adressBlocked) public view returns (uint){
        return blockedTime[adressBlocked];
    }
    
    function seeNow() public view returns (uint){
        return now;
    }
    
    //Fallback
    function () external payable {
        revert();
    }

}