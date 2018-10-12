pragma solidity ^0.4.24;

contract DmDesignContract  {    

    string public constant name = "http://dm-designe.pl"; 
    string public constant facebook = "https://www.facebook.com/DmDesignPoland/"; 
    string public description = "companyDescription";
    
    address public owner_;
    mapping (address => ProductItem) public product;
    
    struct ProductItem {
        uint confirm;
        uint productNr;
        address owner;
        string description;
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

    function addProduct(address productOwner, uint productNr, string descriptionVal, string productCode) public onlyOwner returns (bool){
        product[productOwner].owner = productOwner;
        product[productOwner].confirm = 0;
        product[productOwner].productNr = productNr;
        product[productOwner].description = descriptionVal;
        product[productOwner].productCode = productCode;
    }

    function update(uint productNr, string descriptionVal) public returns (bool){
        require(product[msg.sender].productNr == productNr, "Increct product nr");

        product[msg.sender].description = descriptionVal;        
    }
}