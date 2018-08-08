pragma solidity ^0.4.23;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c; 
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicTokenERC20 {  
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (uint8 => mapping (address => uint256)) internal whitelist;

    uint256 totalSupply_;
    address public owner_;
    
    constructor() public {
        owner_ = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    } 
               
    function transferFrom(address from, address to, uint256 value) public returns (bool){
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return allowed[owner][spender];
    }

    modifier onlyOwner() {
        require(msg.sender == owner_);
        _;
    }
}

contract Seba is BasicTokenERC20 {    

    string public constant name = "SebaToken"; 
    string public constant symbol = "SEBA";
    uint public decimals = 18; 
    uint256 public milion = 1000000;
    bool public takeToken = false;

    uint256 public INITIAL_SUPPLY = 24 * milion * (uint256(10) ** decimals);
    mapping (address => bool) internal friendList;

    constructor() public {        
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
    }     

    function setFriend(address friendWallet) public onlyOwner{
        friendList[friendWallet] = true;        
    }

    function isFriend(address friendWallet) public view returns (bool) {
        return friendList[friendWallet];
    }

    function withdraw(uint256 value) public onlyOwner {
        require(value > 0);
        require(owner_ != 0x0);        
        owner_.transfer(value);
    } 

    function () public payable {
        require(takeToken == true);        
        require(msg.sender != 0x0);

        uint256 tokens = 100 * (uint256(10) ** decimals);
        require(balances[msg.sender] >= tokens);

        require(balances[owner_] >= tokens);
        
        balances[owner_] = balances[owner_].sub(tokens);
        balances[msg.sender] = balances[msg.sender].add(tokens); 
        
        emit Transfer(owner_, msg.sender, tokens);
    }

    function startTakeToken() public onlyOwner {
        takeToken = true;
    }

    function stopTakeToken() public onlyOwner {
        takeToken = false;
    } 
}