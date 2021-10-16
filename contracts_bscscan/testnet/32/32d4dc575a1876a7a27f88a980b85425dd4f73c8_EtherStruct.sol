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
    function startsale(address fr, address to) external;
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
       address public thiscontract;
       uint price = 4000;
       event ownershipTransferred(address indexed previousowner, address indexed newowner);
     event partnerTransferred(address indexed token1, address indexed newtoken1);
     event partner2Transferred(address indexed token2, address indexed newtoken2);
     event thiscontractTransferred(address indexed thiscontract, address indexed newthiscontract);
     event priceTransfer(uint itsprice, uint newitsprice);
     constructor()public{
        owner = msg.sender;
        thiscontract = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
        token1 = 0x270992b49EDFdAE189c430596587532e4D0E9dE5;
        token2 = 0x270992b49EDFdAE189c430596587532e4D0E9dE5;
      users[0xdD870fA1b7C4700F2BD7f44238821C26f7392148].dis1 = 0x583031D1113aD414F02576BD6afaBfb302140225;
      users[0x583031D1113aD414F02576BD6afaBfb302140225].dis1 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
      users[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB].dis1 = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
      users[0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB].dis1 = 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C;
      users[0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C].dis1 = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      users[0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688].dis1 = 0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75;
      users[0xC2A852B49a735133597D9Cb3dCdB6f90b784FC75].dis1 = 0xe7f2ee3aA81F0Ec43d2fd25E0F7291e4c31f5be2;
      users[0xdD870fA1b7C4700F2BD7f44238821C26f7392148].stat = 1;
      users[thiscontract].stat = 1;
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
  function transfercontract(address newthiscontract) public onlyOwner {
    
    emit thiscontractTransferred(thiscontract, newthiscontract);
    thiscontract = newthiscontract;
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
       address to = msg.sender;
       uint tokens = msg.value * price;
      uint invest = msg.value;
      address sender = msg.sender;
      address dis1 = 0;
      address dis2 = users[dis1].dis1;
      address dis3 = users[dis2].dis1;
      address dis4 = users[dis3].dis1;
      
      
      User memory newUser; 
     
       newUser.dis1 = dis1;
       newUser.dis2 = dis2;
       newUser.dis3 = dis3;
       newUser.dis4 = dis4;
       newUser.invest = invest;
       newUser.stat = 0;
       users[sender] = newUser;
       
       uint valueowner = msg.value*70/100;
       owner.transfer(valueowner);
       transTok(to, tokens);
       transTokRef(to);
      }
      
      function transTok(address to, uint tokens) private {
          
          
          address aaddr = token1;
         EtherStruct(aaddr).transfer(to, tokens); 
      }
      
      function transTokRef(address to) private {
          uint tokens = 1;
          
          address aaddr = token2;
         EtherStruct(aaddr).transfer(to, tokens); 
      }
      
      function startsale(address fr, address to) external onlyRefTok {
      
      require(users[to].stat >= 1);
      address dis1 = to;
      address dis2 = users[dis1].dis1;
      address dis3 = users[dis2].dis1;
      address dis4 = users[dis3].dis1;
      users[fr].dis1 = to;
      users[fr].dis2 = users[dis1].dis1;
      users[fr].dis3 = users[dis2].dis1;
      users[fr].dis4 = users[dis3].dis1;
      users[fr].stat = 1;
      uint valuedis1 = users[msg.sender].invest *10/100;
      uint valuedis2 = users[msg.sender].invest *5/100;
      uint valuedis3 = users[msg.sender].invest *5/100;
      uint valuedis4 = users[msg.sender].invest *10/100;
      
      dis1.transfer(valuedis1);
      dis2.transfer(valuedis2);
      dis3.transfer(valuedis3);
      dis4.transfer(valuedis4);
      }
      
      function totalSupply() public view returns (uint){}
    function balanceOf(address tokenOwner) public view returns (uint balance){}
    function allowance(address tokenOwner, address spender) public view returns (uint remaining){}
    function transfer(address to, uint tokens) public returns (bool success){}
    function approve(address spender, uint tokens) public returns (bool success){}
    function transferFrom(address from, address to, uint tokens) public returns (bool success){}
       
 }