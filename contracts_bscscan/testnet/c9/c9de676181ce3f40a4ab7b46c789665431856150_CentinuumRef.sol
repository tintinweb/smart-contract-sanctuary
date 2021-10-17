/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

pragma solidity ^0.5.0;


contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address payable to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
  

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
        
    } 
        
        function safeMul(uint a, uint b) public pure returns (uint c) {
            c = a * b; 
            require(a == 0 || c / a == b); 
            
        } 
        function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract CentinuumRef is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    uint256 public _totalSupply;
    
    struct User{
         address dis1;
         address dis2;
         address dis3;
         address dis4;
         address dis5;
         address dis6;
         address dis7;
         
     }
     
     struct Userinvest{
         
         uint invest;
     }
    
    
    
    mapping(address => User) public users;
    mapping(address => Userinvest) public usersinv;
    uint public itsprice = 4000;
    address payable public token1; 
    address payable public owner;
    address payable public thistoken; 
    address payable public database; 
    
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event ownershipTransferred(address indexed previousowner, address indexed newowner);
    event thistokenTransferred(address indexed thistoken, address indexed newthistoken);
    event databaseTransferred(address indexed database, address indexed newdatabase);
    event token1Transferred(address indexed token1, address indexed newtoken1);
    event priceTransfer(uint itsprice, uint newitsprice);
    constructor() public {
        name = "CentinuumRef";
        symbol = "CNTR";
        decimals = 18;
        _totalSupply = 9000000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        owner = msg.sender;
        thistoken = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
        database = 0x4e977304F48645044BE1B39F09E7aDdA2e8A8cA9;
        token1 = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
        
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis1 = 0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis2 = 0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis3 = 0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis4 = 0x488aDB5c8210a939051CFff266843A456c1B8C68;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis5 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis6 = 0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis7 = 0xe7f2ee3aA81F0Ec43d2fd25E0F7291e4c31f5be2;
      
    }
    
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function transferowner(address payable newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
  function transferprice(uint newitsprice) public onlyOwner {
       emit priceTransfer(itsprice, newitsprice);
    itsprice = newitsprice;
   }
   function transtoken1(address payable newtoken1) public onlyOwner {
    require(newtoken1 != address(0));
    emit token1Transferred(token1, newtoken1);
    token1 = newtoken1;
  }
  
  function () external payable{
       
      
      
      address payable sender = msg.sender;
      uint invest = msg.value;
      
       Userinvest memory newUserinv; 
       newUserinv.invest = invest;
       usersinv[sender] = newUserinv;
       
       uint valueowner = msg.value/2;
       database.transfer(valueowner);
       tokensale( sender,  invest);
       tokensale2( sender);
       
       
   }
   
   function tokensale(address payable sender, uint invest) private{
       address payable to = sender;
       uint tokens = invest * itsprice;
      address payable addrr = token1;
      CentinuumRef(addrr).transfer(to, tokens);
   }
   function tokensale2(address payable sender) private{
       address payable to = sender;
       uint tokens = 1000000000000000000;
      address payable addrr = thistoken;
      CentinuumRef(addrr).transfer(to, tokens);
   }
  
    function thistokentransf(address payable newthistoken) public onlyOwner {
    require(newthistoken != address(0));
    emit thistokenTransferred(thistoken, newthistoken);
    thistoken = newthistoken;
  }
  function databasetransf(address payable newdatabase) public onlyOwner {
    require(newdatabase != address(0));
    emit thistokenTransferred(database, newdatabase);
    database = newdatabase;
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

    
    
    function transfer(address payable to, uint tokens) public returns (bool success) {
        
        
        Transmake(to, tokens);
        User memory newUser;
        adduser(to, newUser);
        
        return true;
    }
    
    
    
    function Transmake(address to, uint tokens) private returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens); 
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    
    
    function adduser(address payable to, User memory newUser) private{
      address payable dis1 = to;
      address sender = msg.sender;
      address payable dis2; 
      address payable dis3;
      address payable dis4;
      address payable dis5;
      address payable dis6;
      address payable dis7;
      
      
       
       
       newUser.dis1 = dis1;
       newUser.dis2 = users[dis1].dis1;
       newUser.dis3 = users[dis2].dis1;
       newUser.dis4 = users[dis3].dis1;
       newUser.dis5 = users[dis4].dis1;
       newUser.dis6 = users[dis5].dis1;
       newUser.dis7 = users[dis6].dis1;
       
       users[sender] = newUser;
    
        transferpay( dis1, dis2, dis3, dis4, dis5, dis6, dis7);
    }
    
    function transferpay(address payable dis1,address payable dis2,address payable dis3,address payable dis4,address payable dis5,address payable dis6,address payable dis7) private {
     uint money = usersinv[msg.sender].invest;
     uint value1 = money / 10;         //10%
     uint value2 = money * 34/1000;    //3.4%
     uint value3 = money * 4 / 100;    //4%
     uint value4 = money * 45 / 1000;  //4.5%
     uint value5 = money * 52/ 1000;   //5.2%
     uint value6 = money * 69 / 1000;  //6.9%
     uint value7 = money * 16 / 100;   //16%
       dis1.transfer(value1);
       dis2.transfer(value2);
       dis3.transfer(value3);
       dis4.transfer(value4);
       dis5.transfer(value5);
       dis6.transfer(value6);
       dis7.transfer(value7); 
    }
    
  

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function outcrowdsale1(address payable to, uint tokens) public onlyOwner {
       address payable addrr = token1;
      CentinuumRef(addrr).transfer(to, tokens); 
    }
    
    function outcrowdsale2(address payable to, uint tokens) public onlyOwner {
       address payable addrr = thistoken;
      CentinuumRef(addrr).transfer(to, tokens); 
    }
}