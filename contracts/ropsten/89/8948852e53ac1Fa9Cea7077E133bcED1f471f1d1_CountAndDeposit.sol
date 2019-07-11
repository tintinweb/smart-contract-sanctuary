/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity >=0.4.25 <0.6.0;

contract CountAndDeposit {
    
    address contractOwner;
    address contractPartner;
    address contractAddress;
    mapping(address => uint256) machineBalance;
    mapping(address => uint256) machineCounter;
    uint counterLimit;
    uint confOwner;
    uint confPartner;
    
    
// HIER DEFINIEREN WIR DEN CONTRACT
     // hier wird der contractOwner definiert
     // geschieht bei der Erstellung der Contract-Instanz
     constructor() public {
         contractOwner = msg.sender;
     }
     
     // hier wird der contractPartner definiert
     // kann nur vom contractOwner definiert werden
     function setContractPartner(address input) public{
         require (msg.sender == contractOwner);
         contractPartner = input;
     }
     
     // legt das Limit f&#252;r Maschinenstunden fest
     // kann nur vom contractOwner definiert werden
     function setCounterLimit(uint input) public{
         require (msg.sender == contractOwner);
         counterLimit = input;
     }
     
// HIER SIND FUNKTIONEN, UM DEN CONTRACT ZU NUTZEN
// INPUT
    // erh&#246;ht Counter f&#252;r Maschinenstunden des owners
    // (also der Maschine, die den Contract angelegt hat)
    function increase(uint input) public payable{
        require (msg.sender == contractOwner);
        machineCounter[contractOwner] += input;
        machineBalance[contractOwner] +=msg.value;
    }
    
// HIER KANN MAN DEN STATUS DES CONTRACT PR&#220;FEN
// ALLE GET FUNKTIONEN
// OUTPUT
     // gibt counterLimit zur&#252;ck
     // kann von allen genutzt werden
     function getCounterLimit() public view returns (uint) {
         return counterLimit;
     }
    
    // gibt Adresse des contractPartner zur&#252;ck
    // kann nur vom contractOwner genutzt werden
    function getContractPartner() public view returns (address) {
        require (msg.sender == contractOwner);
        return contractPartner;
    }
    
     // gibt Adresse des contractPartner zur&#252;ck
     // kann nur vom contractOwner genutzt werden
    function getContractOwner() public view returns (address) {
        require (msg.sender == contractOwner);
        return contractOwner;
    }
    
    // gibt Adresse des Contracts zur&#252;ck
    // kann nur vom contractOwner genutzt werden
     function getContractAddress() public view returns (address) {
        require (msg.sender == contractOwner);
        return address(this);
    }
    
    // &#252;berpr&#252;ft und gibt die Balance des owners 
    // (also die Einzahlungen der Maschine) zur&#252;ck
    function getBalance() public view returns (uint) {
        return machineBalance[contractOwner];
    }
    
    // &#252;berpr&#252;ft und gibt den Counter des owners
    // (also die Maschinenstunden der Maschine) zur&#252;ck
    function getCount() public view returns (uint) {
           return machineCounter[contractOwner];
    }

    // &#252;berpr&#252;ft, ob das vertraglich festgelegte Limit 
    // der Maschinenstunden (MachineCounter) 
    // erreicht oder &#252;berschritten wurde und gibt 
    // true f&#252;r MachineCounter > Limit
    // false f&#252;r MachineCounter < Limit
    function checkCounterLimit() public view returns (bool) {
        if (machineCounter[contractOwner] >= counterLimit) return true;
        else return false;
    }
}