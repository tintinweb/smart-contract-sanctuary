/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

pragma solidity ^0.4.25;



 contract APPRICE {
     struct User {
        
       address distributor;
       address seconddistributor;
       address seconddistributor2;
       address seconddistributor3;
       address seconddistributor4;
       address manager;
       uint Ordernumber;
       uint price;
       uint paid;
       }
       
       struct managers{
           uint active;
       }
       mapping(address => managers) public mrs;
       mapping(address => User) public users;
       uint prise = 20;
       uint prisem = 15;
       address public owner;
       event ownershipTransferred(address indexed previousowner, address indexed newowner);
       event prisetransferred(uint _prise, uint newprise);
       event prisemtransferred(uint _prisem, uint newprisem);
  
   constructor()public{
        owner = 0x6A4F62cbb93f35762a2d86e11284A90d5d69ca8B;
        }
        modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
     modifier onlymanager() {
    require(mrs[msg.sender].active == 1);
    _;
  }
    function transferowner(address newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
   function transferprise(uint newprise) public onlyOwner {
    require(newprise != uint(0));
    emit prisetransferred(prise, newprise);
    prise = newprise;
  }
     function transferprisem(uint newprisem) public onlyOwner {
    require(newprisem != uint(0));
    emit prisemtransferred(prisem, newprisem);
    prisem = newprisem;
  } 
    address partner = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
  
   function addmanagers(address manageradd, uint active) public onlyOwner{
       
       managers memory Newmanager;
       Newmanager.active = active;
       mrs[manageradd] = Newmanager;
   }
  
    function () public payable {
        require(msg.value >=users[msg.sender].price);
        
       
        
        uint value = msg.value*prise/100;
        uint partnervalue = msg.value*15/100;
        uint distributorvalue = msg.value*5/100;
        uint seconddistributorvalue = msg.value*5/100;
        uint seconddistributor2value = msg.value*5/100;
        uint seconddistributor3value = msg.value*5/100;
        uint seconddistributor4value = msg.value*15/100;
        uint managervalue = msg.value*prisem/100;
        
        partner.transfer(partnervalue);
        owner.transfer(value);
        users[msg.sender].distributor.transfer(distributorvalue);
        users[msg.sender].seconddistributor.transfer(seconddistributorvalue);
        users[msg.sender].seconddistributor2.transfer(seconddistributor2value);
        users[msg.sender].seconddistributor3.transfer(seconddistributor3value);
        users[msg.sender].seconddistributor4.transfer(seconddistributor4value);
        users[msg.sender].manager.transfer(managervalue);
        
        users[msg.sender].paid = users[msg.sender].paid + 1;
    }
    
     function paiforowner(address customer) public onlyOwner{
         users[customer].paid = users[customer].paid + 1;
     }
  
  function Registracion(address customer, address distributor, uint price, uint Ordernumber) public onlymanager {
      address manager = msg.sender;
      address sender = customer;
      address seconddistributor = users[distributor].distributor;
      address seconddistributor2 = users[seconddistributor].distributor;
      address seconddistributor3 = users[seconddistributor2].distributor;
      address seconddistributor4 = users[seconddistributor3].distributor;
      
      require (users[distributor].paid >= 1);
      
       
       User memory newUser; 
       newUser.distributor = distributor;
       newUser.seconddistributor = users[distributor].distributor;
       newUser.seconddistributor2 = users[seconddistributor].distributor;
       newUser.seconddistributor3 = users[seconddistributor2].distributor;
       newUser.seconddistributor4 = users[seconddistributor3].distributor;
       newUser.manager = manager;
       newUser.Ordernumber = Ordernumber;
       newUser.price = price;
       newUser.paid = 0;
       users[sender] = newUser;
       }
       function budget(address bank, uint cash) public onlyOwner{
           uint cashvalue = cash;
           bank.transfer(cashvalue);
       }
 }