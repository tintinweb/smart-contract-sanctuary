/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

pragma solidity ^0.4.25;


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


contract CentinummRef is ERC20Interface, SafeMath {
    struct User{
        address dis1;
        address dis2;
        address dis3;
        address dis4;
        address dis5;
    }
    
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;
    mapping(address => User) public users;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    address public owner;
    address public partner;
    uint public price;
    address public aaddr;
    address public token2;
    address public thisaddr;
    address public referal;
     event ownershipTransferred(address indexed previousowner, address indexed newowner);
     event partnerTransferred(address indexed partner, address indexed newpartner);
     event thisaddrTransferred(address indexed thisaddr, address indexed newthisaddr);
     event token2Transferred(address indexed token2, address indexed newtoken2);
     event priceTransfer(uint itsprice, uint newitsprice);
    
    constructor() public {
        name = "CentinummRef";
        symbol = "CTNR";
        decimals = 18;
        _totalSupply = 800000000000000000000000000000;

        
        
        price = 4000;
        owner = msg.sender;
        partner = 0x4e977304F48645044BE1B39F09E7aDdA2e8A8cA9;
        
        aaddr = address(this);
        referal = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
       users[0x18661cd6403c046a8f210389f057dB2665689E45].dis1 = 0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923;
      users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].dis1 = 0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2;
      users[0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2].dis1 = 0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D;
      users[0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D].dis1 = 0x488aDB5c8210a939051CFff266843A456c1B8C68;
      users[0x488aDB5c8210a939051CFff266843A456c1B8C68].dis1 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      
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
        if(msg.sender == referal){
        
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        } else if(msg.sender == owner) {
             balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens); } else {
            
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        
        
        User memory newUser;
        address sender = to;
        address dis1 = msg.sender;
        address dis2 = users[dis1].dis1;
        address dis3 = users[dis2].dis1;
        address dis4 = users[dis3].dis1;
        address dis5 = users[dis4].dis1;
        
        
        newUser.dis1 = dis1;
        newUser.dis2 = dis2;
        newUser.dis3 = dis3;
        newUser.dis4 = dis4;
        newUser.dis5 = dis5;
        users[sender] = newUser;
        }
       
        return true;
        }
        
   
    
    
    
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferprice(uint newitsprice) public onlyOwner {
       emit priceTransfer(price, newitsprice);
    price = newitsprice;
   }
   function transferowner(address newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
  function transPart(address  newpartner) public onlyOwner {
    require(newpartner != address(0));
    emit partnerTransferred(partner, newpartner);
    partner = newpartner;
  }
  function transthisaddr(address  newthisaddr) public onlyOwner {
    require(newthisaddr != address(0));
    emit thisaddrTransferred(thisaddr, newthisaddr);
    thisaddr = newthisaddr;
  }
  
 
  
   function transftoken2(address  newtoken2) public onlyOwner {
    require(newtoken2 != address(0));
    emit token2Transferred(token2, newtoken2);
    token2 = newtoken2;
  }
    
    function () external payable  {
        
        uint start = msg.value * 10;
        
       
        
        balances[msg.sender] = start;
        emit Transfer(address(0), msg.sender, start);
     
       
         
    
       
        
 }
 
   function payer() private {
        uint value1 = msg.value * 245 / 1000;
        uint value3 = msg.value * 15/100;
        uint value4 = msg.value *5 / 100;
        uint value6 = msg.value *10 / 100;
         CentinummRef(aaddr).transfer(to, tokens);
        address to = msg.sender;
        uint tokens = msg.value * 20;
        address dis1 = users[msg.sender].dis1;
        address dis2 = users[msg.sender].dis2;
        address dis3 = users[msg.sender].dis3;
        address dis4 = users[msg.sender].dis4;
        address dis5 = users[msg.sender].dis5;
        owner.transfer(value1);
        partner.transfer(value1);
        dis1.transfer(value3);
        dis2.transfer(value4);
        dis3.transfer(value4);
        dis4.transfer(value6);
        dis5.transfer(value3);
       
   }
   
   function refertoken(address to) private {
       address from = address(this);
       uint tokens = msg.value * 10;
       transferFrom( from, to, tokens);
   }
    

    function outtok2(address to, uint how) public onlyOwner {
        uint tokens = how;
        
       CentinummRef(referal).transfer(to, tokens);
    }
    
    
}