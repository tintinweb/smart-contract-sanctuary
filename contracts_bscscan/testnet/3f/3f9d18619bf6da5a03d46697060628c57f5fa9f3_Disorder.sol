/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity ^0.4.25;



 contract Disorder {
     struct User {
        
       address distributor;
       address seconddistributor;
       address seconddistributor2;
       address seconddistributor3;
       
       }
         struct PasBal{
            uint deposit;
            uint dividends;
            uint rang;
            uint position;
            uint status;
        } 
        
        struct Out{
            uint status;
        }
       
       mapping(address => Out) public Outs;
       mapping(address => PasBal) public PassiveBalance;
       mapping(address => User) public users;
       uint public people = 0;
       address public owner;
       address public partner;
        
       event peoplestat(uint people, uint newpeople);
       event ownershipTransferred(address indexed previousowner, address indexed newowner);
       event partnerTransferred(address indexed partner, address indexed newpartner);
  
   constructor()public{
        owner = msg.sender;
        partner = 0xcaa72f6BF6f5bBA511b17c7F668a68A000f5E688;
      users[0x18661cd6403c046a8f210389f057dB2665689E45].distributor = 0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923;
      users[0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923].distributor = 0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2;
      users[0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2].distributor = 0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D;
      users[0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D].distributor = 0x488aDB5c8210a939051CFff266843A456c1B8C68;
        
        }
        
       
        modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
     
    
    function transferowner(address newowner) public onlyOwner {
    require(newowner != address(0));
    emit ownershipTransferred(owner, newowner);
    owner = newowner;
  }
   
   function transferpartner(address newpartner) public onlyOwner {
    require(newpartner != address(0));
    emit partnerTransferred(partner, newpartner);
    partner = newpartner;
  }
   
   
   
    
    function () public payable {
        
     if (msg.value >= 50 finney) {
         
       require(Outs[msg.sender].status == 0); 
       uint newpeople = people + 1;
       uint value1 = msg.value*10/100;
       uint value2 = msg.value*10/100; 
        emit peoplestat(people, newpeople);
    people = newpeople;
        
       
       PasBal memory newPasBal;
        User memory newUser; 
       
       newUser.distributor = 0x18661cd6403c046a8f210389f057dB2665689E45;
       newUser.seconddistributor = 0x54D7deDE96Ad761DB5ECF9c927C45F990cB7C923;
       newUser.seconddistributor2 = 0xa5E79608AD7C1f53c45f9778Dbc1debe247EEde2;
       newUser.seconddistributor3 = 0xF29D97312e7c45e97cBF1997a8609d0006DA9D5D;
        
       owner.transfer(value1);   
       partner.transfer(value2);
        
        addPassiveBalance(newPasBal);
        addpeoples(newUser);
     }
       if (msg.value <= 30 finney){
       require(people >= PassiveBalance[msg.sender].position + PassiveBalance[msg.sender].rang);  
       uint value7 = PassiveBalance[msg.sender].dividends;
       msg.sender.transfer(value7);
       stoppeoples(newPasBal);
       Out memory newOut;
       Outsbank(newOut);
     } 
        
    }
    
     
  function Registracion(address distributor) public payable {
      require(Outs[msg.sender].status == 0); 
      require(msg.sender != distributor);
       uint newpeople = people + 1;
       uint value1 = msg.value*10/100;
       uint value2 = msg.value*10/100; 
       uint value3 = msg.value*5/100;
       uint value4 = msg.value*4/100;
       uint value5 = msg.value*3/100;
       uint value6 = msg.value*18/100;
      address seconddistributor = users[distributor].distributor;
      address seconddistributor2 = users[seconddistributor].distributor;
      address seconddistributor3 = users[seconddistributor2].distributor;
      
       User memory newUser; 
     
       newUser.distributor = distributor;
       newUser.seconddistributor = seconddistributor;
       newUser.seconddistributor2 = seconddistributor2;
       newUser.seconddistributor3 = seconddistributor3;
       
       PasBal memory newPasBal;
       
       emit peoplestat(people, newpeople);
    people = newpeople;
       
       
       
        owner.transfer(value1);   
        partner.transfer(value2);
        distributor.transfer(value3);
        seconddistributor.transfer(value4);
        seconddistributor2.transfer(value5);
        seconddistributor3.transfer(value6);
       
       
       addpeoples(newUser);
       addPassiveBalance(newPasBal);
       
      
         
        }
       
     function addpeoples( User memory newUser) private {
         
         address sender = msg.sender;
         users[sender] = newUser;
         }
         
         function stoppeoples(PasBal memory newPasBal) private {
          address investor = msg.sender;
         newPasBal.deposit = 0;
         newPasBal.dividends = 0;
         newPasBal.status = 1;
         PassiveBalance[investor] = newPasBal;
         }
    
     
     function addPassiveBalance(PasBal memory newPasBal) private {
       address investor = msg.sender;
       if (people <= 10) {
       newPasBal.deposit = msg.value * 2;
       newPasBal.dividends = (msg.value + (msg.value*24/100)) * 2;
       }
       else if (people > 10) {
        newPasBal.deposit = msg.value;
       newPasBal.dividends = msg.value + (msg.value*24/100);
       }
       newPasBal.position = people;
       newPasBal.status;
       
       if (msg.value >= 50 finney) {
       newPasBal.rang = 600;
       }
        if (msg.value > 1 ether && msg.value <= 3 ether){
         newPasBal.rang = 300;  
       } 
       if (msg.value >= 3 ether) {
           newPasBal.rang = 150;
       }
       PassiveBalance[investor] = newPasBal;
       }
        
        
       function Outsbank( Out memory newOut) private {
           address Outer = msg.sender;
           newOut.status = 1;
           Outs[Outer] = newOut;
       }
     
    function budget(address bank, uint cash) public onlyOwner{
           uint cashvalue = cash;
           bank.transfer(cashvalue);
       }
 }