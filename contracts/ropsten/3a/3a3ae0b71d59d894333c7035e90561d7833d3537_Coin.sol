pragma solidity ^0.4.25;

contract Drugs {
    event RegisterDrug(uint256 _registroMS, string _product, string _description, uint256 _value, Tarjas _classification);
    enum Tarjas { Livre, Vermelha, Preta }
    
    struct DrugInfo {
        string product;
        string description;
        uint256 value;
        Tarjas classification;
    }
    
    mapping (uint256 => DrugInfo) drug;
    uint256[] private registroMS;
    
    function registerDrug(uint256 _registroMS, string _product, string _description, uint256 _value, Tarjas _classification) internal {
        require(drug[_registroMS].value == 0,"Med already existed");
        DrugInfo storage _drug = drug[_registroMS];
        
        _drug.product = _product;
        _drug.description = _description;
        _drug.value = _value;
        _drug.classification = _classification;
        
        registroMS.push(_registroMS) -1;
        emit RegisterDrug(_registroMS, _product, _description, _value, _classification);
    }
    
    function getDrugs() view public returns(uint256[]) {
        return registroMS;
    }
    
    function getDrugInfo(uint256 _registroMS) public constant returns  (string,string, uint256, string) {
        string memory _class;
        if (drug[_registroMS].classification == Tarjas.Livre){
            _class = "Venda Livre";
        }else if(drug[_registroMS].classification == Tarjas.Vermelha){
            _class = "Tarja Vermelha";
        }else if(drug[_registroMS].classification == Tarjas.Preta){
            _class = "Tarja Preta";
        }
        
        return (drug[_registroMS].product,drug[_registroMS].description, drug[_registroMS].value, _class);
    }
    
    function countDrugs() view public returns (uint256) {
        return registroMS.length;
    }
    
    function getDrugPrice(uint256 _registroMS) public view returns (uint256){
        return (drug[_registroMS].value);
    }
}

contract Coin is Drugs{

    event TransferLab(address indexed _from, address indexed _to, uint256 _value);
    event TransferMed(address indexed _from, address indexed _to, uint256 _value);
    event TransferFarm(address indexed _from, address indexed _to, uint256 _value);
    event RescueCoin(address indexed _from, address indexed _to, uint256 _value);
    
    function transferMed (address to, uint256 registroMS) public{
        uint256 value = getDrugPrice(registroMS);
        emit TransferMed(msg.sender,to,value);
    }
    
    function addDrug(uint256 _registroMS, string _product, string _description, uint256 _value, Tarjas _classification) public{
        registerDrug(_registroMS,_product,_description,_value,_classification);
    }
 
}