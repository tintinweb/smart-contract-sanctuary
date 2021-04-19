pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;


import "./Ownable.sol";
import "./TechniciansWL.sol";
import "./ListClients.sol";


contract ContratsClient is Ownable {

    //Store the client addresses (if many account in the same company)
    mapping(address => bool) public client;
    //Client address added to client whitelist event
    event ClientAddressAdded(address addr);
    //Client address removed to client whitelist event
    event ClientAddressRemoved(address addr);
    
     //Allow to check technicians address from technicians whitelist contract
    address techniciansWLAddr = 0xbd854dE55A8Abf854f7d3e6aF7635C0Cc4c8627E;
    TechniciansWL techniciansWL = TechniciansWL(techniciansWLAddr);
  
   /**
   * @dev Throws if called by any account that's not a technician's.
   */
    modifier onlyTechnicians() {
        require(techniciansWL.isTechnician(msg.sender));
        _;
    }
    
    /**
   * @dev Change technicians whitelist address if this one was redeployed
   * @param addr new address of the technician whitelist
   */
    function updateTechniciansWLAddress(address addr) onlyOwner public {
        techniciansWL = TechniciansWL(addr);
    }
    
     /**
   * @dev Change client list address if this one was redeployed
   * @param addr new address of the technician whitelist
   */
    function updateClientListAddress(address addr) onlyOwner public {
        listOfClientAddr = addr;
    }
    
    
    /**
   * @dev Check if addr is in client "whitelist" 
   * @param addr wallet address
   */
   function isClient(address addr) public returns(bool){
      if(client[addr]){
          return true;
      }
      else {
          return false;
      }
    }
  
    string public nom;
    string public adressePostale;
    string public codePostal;
    string public ville;
    string public tel;
    string public mail;

    address public listOfClientAddr = 0x17ea2629839501B80ADE13CB5C36D665d6f82BF2;
    ListClients lc ;
    

    constructor(address _wallet, string memory _nom, string memory _adressePostale, string memory _codePostal, string memory _ville, string memory _tel, string memory _mail)public{
        nom = _nom;
        adressePostale = _adressePostale;
        codePostal = _codePostal;
        ville = _ville;
        tel = _tel;
        mail = _mail;
        lc = ListClients(listOfClientAddr);
        client[_wallet] = true;
    }
  
  /*
  function setClient(string memory _nom, string memory _adressePostale, string memory _codePostal, string memory _ville, string memory _tel, string memory _mail) onlyTechnicians public{
        nom = _nom;
        adressePostale = _adressePostale;
        codePostal = _codePostal;
        ville = _ville;
        tel = _tel;
        mail = _mail;
        ListClients lc = ListClients(listOfClientAddr);
      
      //lc.addClient(address(this),nom,adressePostale,codePostal,ville,tel,mail);
  }*/
  
  
  function updateClient(string memory _nom, string memory _adressePostale,string memory _codePostal, string memory _ville, string memory _tel, string memory _mail) onlyTechnicians public {
      nom = _nom;
      adressePostale = _adressePostale;
      codePostal = _codePostal;
      ville = _ville;
      tel = _tel;
      mail = _mail;
      ListClients lc = ListClients(listOfClientAddr);
      //lc.updateClient(address(this),_nom,_adressePostale,_codePostal,_ville,_tel,_mail);
  }
  
  
  
  /**
   * @dev add an address to the client whitelist
   * @param addr address
   * @return success true if the address was added to the client whitelist
   */
  function addAddressToWhitelist(address addr) onlyTechnicians public returns(bool success) {
        if (!client[addr]) {
            client[addr] = true;
            emit ClientAddressAdded(addr);
            success = true;
        }    
  }


  /**
   * @dev add addresses to the chosen whitelist
   * @param addrs addresses
   * @return success true if at least one address was added to the client whitelist,
   */
  function addAddressesToWhitelist(address[] memory addrs) onlyTechnicians public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }


  /**
   * @dev remove an address from the client whitelist
   * @param addr address
   * @return success true if the address was removed from the chosen whitelist,
   */
  function removeAddressFromWhitelist(address addr) onlyTechnicians public returns(bool success) {
        if(client[addr]) {
            client[addr] = false;
            emit ClientAddressRemoved(addr);
            success = true;
        }
  }


  /**
   * @dev remove addresses from the client whitelist
   * @param addrs addresses
   * @return success true if at least one address was removed from the client whitelist,
   */
  function removeAddressesFromWhitelist(address[] memory addrs) onlyTechnicians public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }
   
   
    //Get technicians whitelist to avoid defining them everytime
    struct appareil{
        string  categorie;
        string  a_type;
        string  brand;
        string  refer;
        string  serial_n;
        int  statut;
    }
    
    
    mapping(address => appareil) public contracts;   // mapping type of deployed contracts
    address[] public deployed;   // store deployed contracts
    


    function addContract(address _contract, string memory categorie, string memory a_type, string memory brand,string memory refer,string memory serial_n) public onlyTechnicians{
        updateContract(_contract,categorie,a_type,brand,refer,serial_n);
        contracts[_contract].statut= 1;
        deployed.push(_contract);
    }
    
    function updateContract(address _contract, string memory categorie, string memory a_type, string memory brand,string memory refer,string memory serial_n) public onlyTechnicians{
        contracts[_contract].categorie= categorie;
        contracts[_contract].a_type= a_type;
        contracts[_contract].brand= brand;
        contracts[_contract].refer= refer;
        contracts[_contract].serial_n= serial_n;
    }
    
    function updateContractStatus(address _contract, int statut) public onlyTechnicians{
        contracts[_contract].statut= statut;
    }
    
    
    
    function getContracts() view public returns(address[] memory) {
        return deployed;
    }

}