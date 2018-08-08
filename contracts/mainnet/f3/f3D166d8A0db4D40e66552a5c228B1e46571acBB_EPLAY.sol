pragma solidity ^0.4.20;

contract owned {
    address public owner;
    
    event Log(string s);
    
    constructor() public payable{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
    function isOwner()public{
        if(msg.sender==owner)emit Log("Owner");
        else{
            emit Log("Not Owner");
        }
    }
}
contract ERC20 is owned{

    string public name;
    string public symbol;

    uint256 public totalSupply;
    uint8 public constant decimals = 4;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor(uint256 _totalSupply,string tokenName,string tokenSymbol) public {
        symbol = tokenSymbol;
        name = tokenName;
        totalSupply = _totalSupply;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function totalSupply() public view returns (uint){
        return totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender ]- tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] - (tokens);
        balances[to] = balances[to]+(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
}

contract EPLAY is ERC20 {
    
    uint256 activeUsers;

    mapping(address => bool) isRegistered;
    mapping(address => uint256) accountID;
    mapping(uint256 => address) accountFromID;
    mapping(address => bool) isTrusted;

    event Burn(address _from,uint256 _value);
    
    modifier isTrustedContract{
        require(isTrusted[msg.sender]);
        _;
    }
    
    modifier registered{
        require(isRegistered[msg.sender]);
        _;
    }
    
    constructor(
        string tokenName,
        string tokenSymbol) public payable
        ERC20(74145513585,tokenName,tokenSymbol)
    {
       
    }
    
    function distribute(address[] users,uint256[] balances) public onlyOwner {
         uint i;
        for(i = 0;i <users.length;i++){
            transferFrom(owner,users[i],balances[i]);
        }
    }

    function burnFrom(address _from, uint256 _value) internal returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }

    function contractBurn(address _for,uint256 value)external isTrustedContract{
        burnFrom(_for,value);
    }

    function burn(uint256 val)public{
        burnFrom(msg.sender,val);
    }

    function registerAccount(address user)internal{
        if(!isRegistered[user]){
            isRegistered[user] = true;
            activeUsers += 1;
            accountID[user] = activeUsers;
            accountFromID[activeUsers] = user;
        }
    }
    
    function registerExternal()external{
        registerAccount(msg.sender);
    }
    
    function register() public {
        registerAccount(msg.sender);
    }

    function testConnection() external {
        emit Log("CONNECTED");
    }
}