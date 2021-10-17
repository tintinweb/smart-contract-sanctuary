/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

pragma solidity ^0.5.0;


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


contract Mercury is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => UserDividends) public UserDividend;
    mapping(address => Userinvest) public usersinv;
     mapping(address => User) public users;
     
     
     event ownershipTransferred(address indexed previousowner, address indexed newowner);
     event partnerTransferred(address indexed partner, address indexed newpartner);
     event token1Transferred(address indexed token1, address indexed newtoken1);
     event token2Transferred(address indexed token2, address indexed newptoken2);
     event priceTransfer(uint itsprice, uint newitsprice);
     event dividendsTransfer(uint dividends, uint newdividends);
     address payable public token1;
     address payable public token2;
     address public owner;
     address payable public partner;
     uint public itsprice = 4000;
     uint public newdividends = 0;
    constructor() public {
        name = "Mercury";
        symbol = "MRC";
        decimals = 18;
        _totalSupply = 250000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        
        owner = msg.sender;
        partner = 0x4e977304F48645044BE1B39F09E7aDdA2e8A8cA9;
        token1 = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
        token2 = 0x19957efd976B473266df2ce234440c3a6d013941;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis1 = 0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923;
      users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].dis1 = 0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2;
      users[0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2].dis1 = 0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D;
      users[0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D].dis1 = 0x488aDB5c8210a939051CFff266843A456c1B8C68;
      users[0x488aDB5c8210a939051CFff266843A456c1B8C68].dis1 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      users[0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688].dis1 = 0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75;
      users[0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75].dis1 = 0xe7f2ee3aA81F0Ec43d2fd25E0F7291e4c31f5be2;
     
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
        adduser(to);
        
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


 
     struct User{
         address id;
         address dis1;
         address dis2;
         address dis3;
         address dis4;
         
         
     }
     
     struct Userinvest{
         
         uint invest;
     }
     struct UserDividends{
         
         uint dividends;
     }
     
     
        
     
         modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
   modifier onlyToken2() {
    require(msg.sender == token2);
    _;
  }
  
   function transferprice(uint newitsprice) public onlyOwner {
       emit priceTransfer(itsprice, newitsprice);
    itsprice = newitsprice;
   }
  
  function transferowner(address newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
    function transPart(address payable newpartner) public onlyOwner {
    require(newpartner != address(0));
    emit partnerTransferred(partner, newpartner);
    partner = newpartner;
  }
  
    function transtoken1(address payable newtoken1) public onlyOwner {
    require(newtoken1 != address(0));
    emit token1Transferred(token1, newtoken1);
    token1 = newtoken1;
  }
  
   function transtoken2(address payable newtoken2) public onlyOwner {
    require(newtoken2 != address(0));
    emit token2Transferred(token2, newtoken2);
    token2 = newtoken2;
  }
  
   
   
   function () external payable{
       address sender = msg.sender;
       uint dividends = UserDividend[msg.sender].dividends;
       
       
       if(msg.value <= 100 finney){
       uint payback = UserDividend[msg.sender].dividends; 
       msg.sender.transfer(payback);
       emit dividendsTransfer(dividends, newdividends);
      dividends = newdividends;
       
       
       }
       UserDividend[sender].dividends = newdividends;
      
       if(msg.value >= 100 finney){
      uint invest = msg.value;
      Userinvest memory newUserinv; 
       newUserinv.invest = invest;
       usersinv[sender] = newUserinv;
       
       uint valueowner = msg.value/2;
       partner.transfer(valueowner);
       
       tokensale(sender, invest);
       tokensale2(sender);
   }
     
      
   }
   function tokensale(address sender, uint invest) private{
       address to = sender;
       uint tokens = invest * itsprice;
      address payable addrr = token1;
       Mercury(addrr).transfer(to, tokens);
   }
   
   function tokensale2(address sender) private{
       address to = sender;
       uint tokens = 1000000000000000000;
      address payable addrr = token2;
      Mercury(addrr).transfer(to, tokens);
   }
   
   function adduser(address to) private{
       
       address dis1 = to;
      
      address dis2 = users[dis1].dis1;
      address dis3 = users[dis2].dis1;
      address dis4 = users[dis3].dis1;
      
       address sender = msg.sender;
       User memory newUser;
       newUser.dis1 = to;
       newUser.dis2 = dis2;
       newUser.dis3 = dis3;
       newUser.dis4 = dis4;
       
       users[sender]=newUser;
       transferpay( dis1, dis2, dis3, dis4);
   }
   
    function transferpay(address dis1,address dis2,address dis3,address dis4) private {
    uint drob = usersinv[msg.sender].invest;
     
     uint value1 = drob / 10;         //10%
     uint value2 = drob * 5/100;    //5%
     uint value3 = drob * 5 / 100;    //5%
     uint value4 = drob * 30 / 1000;  //30%
     
     
     UserDividend[dis1].dividends = UserDividend[dis1].dividends + value1;
     UserDividend[dis2].dividends = UserDividend[dis2].dividends + value2;
      UserDividend[dis3].dividends = UserDividend[dis3].dividends + value3;
       UserDividend[dis4].dividends = UserDividend[dis4].dividends + value4;
        
          
    }
    
    function outcrowdsale1(address to, uint tokens) public onlyOwner {
       address payable addrr = token1;
       Mercury(addrr).transfer(to, tokens); 
    }
    
    function outcrowdsale2(address to, uint tokens) public onlyOwner {
       address payable addrr = token2;
       Mercury(addrr).transfer(to, tokens); 
    }
    
    
    
   
 }