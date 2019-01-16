pragma solidity 0.4.25;

contract HomburgerToken {
    string public constant name = "Homburger Token";
    string public constant symbol = "HBG";
    uint8 public constant decimals = 18;
    address public owner;
    uint256 public _totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    address public pauser = 0x33; // placeholder
    bool public paused;
    address public authority = 0x44; // placeholder
    mapping(address => bool) public isFrozen;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Paused(address account);
    event Unpaused(address account);
    event Confiscate(address indexed account, uint256 amount, address indexed receiver);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyPauser() {
        require(msg.sender == pauser);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }

    modifier onlyAuthority() {
        require(msg.sender == authority);
        _;
    }

    function checkIfFrozen(address _from, address _to) internal view {
        require(!isFrozen[_from], "from has been frozen");
        require(!isFrozen[_to], "to has been frozen");
    }

    function confiscate(address confiscatee, address receiver) 
        public 
        onlyAuthority
    {
        require(receiver != address(0));
        isFrozen[confiscatee] = true;
        uint256 balance = balanceOf(confiscatee);
        balances[confiscatee] -= balance;
        balances[receiver] += balance;
        emit Confiscate(confiscatee, balance, receiver);
    }


    function pause() public onlyPauser whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyPauser whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }
   
    function allowance(
        address tokenOwner, 
        address spender
    )
        public 
        view 
        returns (uint256) 
    {
        return allowed[tokenOwner][spender];
    }


    function transfer(
        address to, 
        uint256 value
    ) 
        public 
        whenNotPaused 
        returns (bool) 
    {
        require(balances[msg.sender] >= value);
        require(to != address(0));
        checkIfFrozen(msg.sender, to);
        
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

   function approve(
       address spender,
       uint256 value
    ) 
        public 
        whenNotPaused 
        returns (bool)
    {
        require(spender != address(0));
        
        allowed[msg.sender][spender] = value; 
        emit Approval(msg.sender, spender, value);
        return true;
    }

    
   function transferFrom(
        address from, 
        address to, 
        uint256 value
    ) 
        public 
        whenNotPaused
        returns (bool) 
    {
        require(allowed[from][msg.sender] >= value);
        require(balances[from] >= value);
        require(to != address(0));
        checkIfFrozen(msg.sender, to);
        
        allowed[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function mint(
        address to, 
        uint256 value
    ) 
        public 
        whenNotPaused 
        returns(bool)
    {
        require(msg.sender == owner);
        require(to != address(0));
        checkIfFrozen(msg.sender, to);
        
        _totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
        return true;
    }
}