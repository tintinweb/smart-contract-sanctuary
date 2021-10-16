/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity ^0.4.25;


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function adduser(address to, uint meseg) external;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
        
    } 
        function safeMul(uint a, uint b) public pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
            
    } 
        function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract CentiRef is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;
    
    struct User {
        address  dis1;
        address dis2;
        address  dis3;
        address  dis4;
        uint invest;
        uint stat;
       }
    
    mapping(address => User) public users;
    address public ownercont;
    address  crowdsale;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event crowdsaleTransferred(address indexed crowdsale, address indexed newcrowdsale);
   event ownershipTransferred(address indexed previousowner, address indexed newownercont);
    constructor() public {
        name = "CentinuumRef";
        symbol = "CTNR";
        decimals = 18;
        _totalSupply = 7890000000000000000000000000;
        ownercont = msg.sender;
        crowdsale = 0xE341F75c9d765c5983124Ef650332cF114202fA3;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        
        
        users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].dis1 = 0x583031D1113aD414F02576BD6afaBfb302140225;
      users[0x583031D1113aD414F02576BD6afaBfb302140225].dis1 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
      users[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB].dis1 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
      users[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB].dis1 = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;
      users[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C].dis1 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      users[0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688].dis1 = 0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75;
      users[0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75].dis1 = 0xe7f2ee3aA81F0Ec43d2fd25E0F7291e4c31f5be2;
      users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].stat = 1;
      
    }
    
    modifier onlyOwnercont() {
    require(msg.sender == ownercont);
    _;
  }
  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }
  
  function transferowner(address newowner) public onlyOwnercont {
    require(newowner != address(0));
    emit ownershipTransferred(ownercont, newowner);
    ownercont = newowner;
  } 
  
  
   function adduser(address to, uint meseg) external onlyCrowdsale {  
      uint invest = meseg;
      address sender = to;
      
      
   User memory newUser; 
     
       
       newUser.invest = invest;
       newUser.stat = 0;
       users[sender] = newUser;
   
   }
   
    function referadd(address senderes, address to) private  {
    
      
      require(users[to].stat >= 1);
      address   dis1 = to;
      address   dis2 = users[dis1].dis1;
      address   dis3 = users[dis2].dis1;
      address   dis4 = users[dis3].dis1;
      users[senderes].dis1 = to;
      users[senderes].dis2 = users[dis1].dis1;
      users[senderes].dis3 = users[dis2].dis1;
      users[senderes].dis4 = users[dis3].dis1;
      users[senderes].stat = 1;
      
      sales(senderes);
    }
    
    function sales(address  senderes)private {
      address   dis1 =  users[senderes].dis1;
      address   dis2 = users[senderes].dis2;
      address   dis3 = users[senderes].dis3;
      address   dis4 = users[senderes].dis4; 
      uint valuedis1 = users[senderes].invest *10/100;
      uint valuedis2 = users[senderes].invest *5/100;
      uint valuedis3 = users[senderes].invest *5/100;
      uint valuedis4 = users[senderes].invest *10/100;
      dis1.transfer(valuedis1);
      dis2.transfer(valuedis2);
      dis3.transfer(valuedis3);
      dis4.transfer(valuedis4);
      }
    function transfertoken1(address  newcrowdsale) public onlyOwnercont {
    
    emit crowdsaleTransferred(crowdsale, newcrowdsale);
    crowdsale = newcrowdsale;
  } 

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        
        
         balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        address senderes = msg.sender;
        return true;
        referadd(senderes, to);
    }
    
    
    
    function ()public payable {
        
    }
    
    

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    
}