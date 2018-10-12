pragma solidity ^0.4.25;

contract DmDesignContract  {    

    string public constant name = "https://dm-design.pl"; 
    string public constant facebook = "https://www.facebook.com/DmDesignPoland/"; 
    string public description = "companyDescription";
    
    address public owner_;
    mapping (address => ProductItem) public product;
    
    struct ProductItem {
        uint confirm;
        uint productNr;
        uint addTime;
        address owner;
        string description;
        string signature;
        string productCode;
    }
    
    constructor() public {
        owner_ = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner_, "Not contract owner");
        _;
    }
    
    function updateDescription(string text) public onlyOwner returns (bool){
        description = text;
        return true;
    }
    
    function changeContractOwner(address newOwner) public onlyOwner returns (bool){
        owner_ = newOwner;
        return true;
    }

    function confirmProduct(uint confirmNr) public returns (bool){
        product[msg.sender].confirm = confirmNr;
    }

    function addProduct(address productOwner, uint productNr, string descriptionVal, string productCode, string signature) public onlyOwner returns (bool){
        require(product[productOwner].owner == 0x0, "product already has owner");

        product[productOwner].owner = productOwner;
        product[productOwner].confirm = 0;
        product[productOwner].productNr = productNr;
        product[productOwner].description = descriptionVal;
        product[productOwner].productCode = productCode;
        product[productOwner].signature = signature;
        product[productOwner].addTime = block.timestamp;
        
    }

    function update(uint productNr, string signatureOwner) public returns (bool){
        require(product[msg.sender].productNr == productNr, "Increct product nr");

        product[msg.sender].signature = signatureOwner;        
    }
}