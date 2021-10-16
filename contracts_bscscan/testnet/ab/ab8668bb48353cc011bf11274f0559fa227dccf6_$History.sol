/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

// Telegram channel of the contract - t.me/tendollarshistory
// We are sure that a group of people can do more than a bureaucratic machine!
//the contract does not store money on its balance, funds are automatically sent to all participants of the grid.
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


 contract $History is ERC20Interface {
     struct User{
         address dis1;
         address dis2;
         address dis3;
         address dis4;
         address dis5;
         address dis6;
         address dis7;
         uint invest;
     }
     
     
     mapping(address => User) public users;
     address public token1;
     address public token2;
     address public owner;
     address public partner;
     uint public itsprice = 4000;
     
     
     event ownershipTransferred(address indexed previousowner, address indexed newowner);
     event partnerTransferred(address indexed partner, address indexed newpartner);
     event token1Transferred(address indexed token1, address indexed newtoken1);
     event token2Transferred(address indexed token2, address indexed newptoken2);
     event priceTransfer(uint itsprice, uint newitsprice);
     constructor()public{
        owner = msg.sender;
        partner = 0x4e977304F48645044BE1B39F09E7aDdA2e8A8cA9;
        token1 = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
        token2 = 0x252e699fA346e18CDAf44Cd263621a1b7792EFa7;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].dis1 = 0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923;
      users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].dis1 = 0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2;
      users[0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2].dis1 = 0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D;
      users[0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D].dis1 = 0x488aDB5c8210a939051CFff266843A456c1B8C68;
      users[0x488aDB5c8210a939051CFff266843A456c1B8C68].dis1 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      users[0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688].dis1 = 0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75;
      users[0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75].dis1 = 0xe7f2ee3aA81F0Ec43d2fd25E0F7291e4c31f5be2;
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
    function transPart(address newpartner) public onlyOwner {
    require(newpartner != address(0));
    emit partnerTransferred(partner, newpartner);
    partner = newpartner;
  }
  
    function transtoken1(address newtoken1) public onlyOwner {
    require(newtoken1 != address(0));
    emit token1Transferred(token1, newtoken1);
    token1 = newtoken1;
  }
  
   function transtoken2(address newtoken2) public onlyOwner {
    require(newtoken2 != address(0));
    emit token2Transferred(token2, newtoken2);
    token2 = newtoken2;
  }
  
   
   
   function () public payable{
       
      
      
      address sender = msg.sender;
      uint invest = msg.value;
      
       User memory newUser; 
       newUser.invest = invest;
       users[sender] = newUser;
       
       uint valueowner = msg.value/2;
       partner.transfer(valueowner);
       
       tokensale(sender, invest);
       tokensale2(sender);
   }
   
   function tokensale(address sender, uint invest) private{
       address to = sender;
       uint tokens = invest * itsprice;
      address addrr = token1;
      $History(addrr).transfer(to, tokens);
   }
   
   function tokensale2(address sender) private{
       address to = sender;
       uint tokens = 1000000000000000000;
      address addrr = token2;
      $History(addrr).transfer(to, tokens);
   }
   
   function Userpay(address to, address userr) external onlyToken2 {
      address dis1 = to;
      address dis2 = users[dis1].dis1;
      address dis3 = users[dis2].dis1;
      address dis4 = users[dis3].dis1;
      address dis5 = users[dis4].dis1;
      address dis6 = users[dis5].dis1;
      address dis7 = users[dis6].dis1;
       
       users[userr].dis1 = dis1;
       users[userr].dis2 = dis2;
       users[userr].dis3 = dis3;
       users[userr].dis4 = dis4;
       users[userr].dis5 = dis5;
       users[userr].dis6 = dis6;
       users[userr].dis7 = dis7;
       
    transferpay( dis1, dis2, dis3, dis4, dis5, dis6, dis7);
       
   }
   
    function transferpay(address dis1,address dis2,address dis3,address dis4,address dis5,address dis6,address dis7) private {
     uint value1 = msg.value / 10;         //10%
     uint value2 = msg.value * 34/1000;    //3.4%
     uint value3 = msg.value * 4 / 100;    //4%
     uint value4 = msg.value * 45 / 1000;  //4.5%
     uint value5 = msg.value * 52/ 1000;   //5.2%
     uint value6 = msg.value * 69 / 1000;  //6.9%
     uint value7 = msg.value * 16 / 100;   //16%
       dis1.transfer(value1);
       dis2.transfer(value2);
       dis3.transfer(value3);
       dis4.transfer(value4);
       dis5.transfer(value5);
       dis6.transfer(value6);
       dis7.transfer(value7); 
    }
    
    function outcrowdsale1(address to, uint tokens) public onlyOwner {
       address addrr = token1;
      $History(addrr).transfer(to, tokens); 
    }
    
    function outcrowdsale2(address to, uint tokens) public onlyOwner {
       address addrr = token2;
      $History(addrr).transfer(to, tokens); 
    }
    
    function totalSupply() public view returns (uint){}
    function balanceOf(address tokenOwner) public view returns (uint balance){}
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){}
    function transfer(address to, uint tokens) public returns (bool success){}
    function approve(address spender, uint tokens) public returns (bool success){}
    function transferFrom(address from, address to, uint tokens) public returns (bool success){}
 }