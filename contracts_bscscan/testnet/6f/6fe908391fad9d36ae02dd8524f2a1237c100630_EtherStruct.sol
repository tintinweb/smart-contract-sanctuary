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


 contract EtherStruct  is ERC20Interface {
     
       struct User {
        address dis1;
        address dis2;
        address dis3;
        address dis4;
        uint invest;
        uint stat;
       }
       
       mapping(address => User) public users;
       address public owner;
       address public token1;
       address public token2;
       
       uint price = 4000;
       event ownershipTransferred(address indexed previousowner, address indexed newowner);
     event partnerTransferred(address indexed token1, address indexed newtoken1);
     event partner2Transferred(address indexed token2, address indexed newtoken2);
     
     event priceTransfer(uint itsprice, uint newitsprice);
     constructor()public{
        owner = msg.sender;
        
        token1 = 0x252e699fa346e18cdaf44cd263621a1b7792efa7;
        token2 = 0x9517d78Ed7e4C18C9E4EDfCB7B4C2CFF3Fa944d1;
      users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].dis1 = 0x583031D1113aD414F02576BD6afaBfb302140225;
      users[0x583031D1113aD414F02576BD6afaBfb302140225].dis1 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
      users[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB].dis1 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
      users[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB].dis1 = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;
      users[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C].dis1 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      users[0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688].dis1 = 0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75;
      users[0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75].dis1 = 0xe7f2ee3aA81F0Ec43d2fd25E0F7291e4c31f5be2;
      users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].stat = 1;
      
     }
     
            modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
           modifier onlyRefTok() {
    require(msg.sender == token2);
    _;
  }
  
    function transferowner(address newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  } 
  
  
  function transfertoken1(address newtoken1) public onlyOwner {
    
    emit partnerTransferred(token1, newtoken1);
    token1 = newtoken1;
  } 
  function transfertoken2(address newtoken2) public onlyOwner {
    
    emit partner2Transferred(token2, newtoken2);
    token2 = newtoken2;
  } 
  
  
    function transferprice(uint newprice) public onlyOwner {
        emit priceTransfer (price, newprice);
        price = newprice;
    }
    
 
       function () public payable{
       
       uint tokens = msg.value * price;
      uint meseg = msg.value;
      address to = msg.sender;
      
      
      
      
       uint valueref = (msg.value*30/100);
       
       token2.transfer(valueref);
       
       transTok(to, tokens);
       transTokRef(to);
        address aaddr = token2;
         EtherStruct(aaddr).adduser(to, meseg);
      }
      
      function transTok(address to, uint tokens) private {
          
          
          address aaddr = token1;
         EtherStruct(aaddr).transfer(to, tokens); 
      }
      
      function transTokRef(address to) private {
          uint tokens = 1000000000000000000;
          
          address aaddr = token2;
         EtherStruct(aaddr).transfer(to, tokens); 
      }
      
      function weldon(address wel, uint tran) public onlyOwner{
          wel.transfer(tran);
      }
      
      function totalSupply() public view returns (uint){}
    function balanceOf(address tokenOwner) public view returns (uint balance){}
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){}
    function transfer(address to, uint tokens) public returns (bool success){}
    function approve(address spender, uint tokens) public returns (bool success){}
    function transferFrom(address from, address to, uint tokens) public returns (bool success){}
     function adduser(address to, uint meseg) external{}  
 }