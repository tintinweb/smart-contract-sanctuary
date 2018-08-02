pragma solidity ^0.4.22;

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
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event FrozenFunds(address target, uint tokens);
    event Buy(address indexed sender, uint eth, uint token);
}

// Owned contract
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

    //Transfer owner rights, can use only owner (the best practice of secure for the contracts)
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //Accept tranfer owner rights
    function acceptOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// Pausable Contract
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;

  //Modifier to make a function callable only when the contract is not paused.
  modifier whenNotPaused() {
    require(!paused);
    _;
  }


  //Modifier to make a function callable only when the contract is paused.
  modifier whenPaused() {
    require(paused);
    _;
  }

  //called by the owner to pause, triggers stopped state
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  //called by the owner to unpause, returns to normal state
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract VTest2 is ERC20Interface, Pausable {
    using SafeMath for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public icoEndTime;
    uint public waitPeriod;
    uint public unlockDate1;
    uint public unlockDate2;
    uint public unlockDate3;
    uint public Day = 24*60*60;

    uint private _totalSupply;
    mapping(address => uint) balances;
    mapping(address => uint) lockInfo;
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => bool) admins;
    
    modifier onlyAdmin {
        require(msg.sender == owner || admins[msg.sender]);
        _;
    }

    function setAdmin(address _admin, bool isAdmin) public onlyOwner {
        admins[_admin] = isAdmin;
    }

    constructor() public{
        symbol = &#39;VTest2&#39;;
        name = &#39;VTest2&#39;;
        decimals = 18;
        _totalSupply = 1000000000*10**uint(decimals);
        balances[owner] = _totalSupply;
        icoEndTime = 1533870000;
        waitPeriod = 15;
        unlockDate1 = icoEndTime + waitPeriod*Day;
        unlockDate2 = unlockDate1 + 3*30*Day; //add 3 months
        unlockDate3 = unlockDate2 + 3*30*Day; //add another 3 months
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);                                    // Prevent transfer to 0x0 address. Use burn() instead
        require(_value != 0);                                   // Prevent transfer 0
        require(balances[_from] >= _value);                     // Check if the sender has enough
        require(balances[_from] - _value >= lockInfo[_from]);   // Check after transaction, balance is still more than locked value
        balances[_from] = balances[_from].sub(_value);          // Substract value from sender
        balances[_to] = balances[_to].add(_value);              // Add value to recipient
        emit Transfer(_from, _to, _value);
    }

    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
         _transfer(msg.sender, to, tokens);
         return true;
    }

    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        require(allowed[from][msg.sender] >= tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public whenNotPaused constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    //Admin Tool
    function lockOf(address tokenOwner) public constant returns (uint lockedToken) {
        return lockInfo[tokenOwner];
    }

    //lock tokens or lock 0 to release all
    function lock(address target, uint lockedToken) public whenNotPaused onlyAdmin {
        lockInfo[target] = lockedToken;
        emit FrozenFunds(target, lockedToken);
    }

    //Batch lock or lock 0 to release all
    function batchLock(address[] accounts, uint lockedToken) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < accounts.length; i++) {
           lock(accounts[i], lockedToken);
        }
    }

    //Batch lock amount with array
    function batchLockArray(address[] accounts, uint[] lockedToken) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < accounts.length; i++) {
           lock(accounts[i], lockedToken[i]);
        }
    }

    //Airdrop Batch with lock 
    function batchAirdropWithLock(address[] receivers, uint tokens, bool freeze) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < receivers.length; i++) {
           sendTokensWithLock(receivers[i], tokens, freeze);
        }
    }

    //VIP Batch with lock
    function batchVipWtihLock(address[] receivers, uint[] tokens, bool freeze) public whenNotPaused onlyAdmin {
      for (uint i = 0; i < receivers.length; i++) {
           sendTokensWithLock(receivers[i], tokens[i], freeze);
        }
    }

    //Send token with lock 
    function sendTokensWithLock (address receiver, uint tokens, bool freeze) public whenNotPaused onlyAdmin {
        _transfer(msg.sender, receiver, tokens);
        if(freeze) {
            uint lockedAmount = lockInfo[receiver] + tokens;
            lock(receiver, lockedAmount);
        }
    }

    //Send initial tokens
    function sendInitialTokens (address user) public onlyOwner {
        _transfer(msg.sender, user, balanceOf(owner));
    }
}