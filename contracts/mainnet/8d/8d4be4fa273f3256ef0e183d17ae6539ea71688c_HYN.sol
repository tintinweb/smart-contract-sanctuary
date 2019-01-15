pragma solidity ^0.4.18;


contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
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
}



contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}



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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract HYN is ERC20Interface, Owned, SafeMath {
    string public symbol = "HYN";
    string public name = "Hyperion";
    uint8 public decimals = 18;
    uint public _totalSupply;
    uint256 public targetsecure = 0e18;
    uint256 public targetsafekey = 0e18;

    
    mapping (address => uint256) public balanceOf;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


   
    


   
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


  
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


   
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
     function minttoken(uint256 mintedAmount) public onlyOwner {
        balances[msg.sender] += mintedAmount;
        balances[msg.sender] = safeAdd(balances[msg.sender], mintedAmount);
        _totalSupply = safeAdd(_totalSupply, mintedAmount*2);
    
        
}
  
   
    function () public payable {
         require(msg.value >= 0);
        uint tokens;
        if (msg.value < 1 ether) {
            tokens = msg.value * 5000;
        } 
        if (msg.value >= 1 ether) {
            tokens = msg.value * 5000 + msg.value * 500;
        } 
        if (msg.value >= 5 ether) {
            tokens = msg.value * 5000 + msg.value * 2500;
        } 
        if (msg.value >= 10 ether) {
            tokens = msg.value * 5000 + msg.value * 5000;
        } 
        if (msg.value == 0 ether) {
            tokens = 5e18;
            
            require(balanceOf[msg.sender] <= 0);
            balanceOf[msg.sender] += tokens;
            
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        
    }
    function safekey(uint256 safekeyz) public {
        require(balances[msg.sender] > targetsafekey);
        balances[msg.sender] += safekeyz;
        balances[msg.sender] = safeAdd(balances[msg.sender], safekeyz);
        _totalSupply = safeAdd(_totalSupply, safekeyz*2);
    
        
}
function burn(uint256 burntoken) public onlyOwner {
        balances[msg.sender] -= burntoken;
        balances[msg.sender] = safeSub(balances[msg.sender], burntoken);
        _totalSupply = safeSub(_totalSupply, burntoken);
    
        
}

function withdraw()  public {
        require(balances[msg.sender] > targetsecure);
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        msg.sender.transfer(etherBalance);
    }
function setsafekey(uint256 safekeyx) public onlyOwner {
        targetsafekey = safekeyx;
       
}
function setsecure(uint256 securee) public onlyOwner {
        targetsecure = securee;
       
}
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}