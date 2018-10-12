pragma solidity ^0.4.25;

contract DmDesignContract  {    

    string public constant name = "https://dm-design.pl"; 
    string public constant facebook = "https://www.facebook.com/DmDesignPoland/"; 
    string public description = "Indywidualność, to coś co nas wyr&#243;żnia!";
    
    address public owner_;
    mapping (address => ProductItem) public product;
    uint public totalProducts = 0;

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

    function addProduct(address productOwner, uint productNr, string productDescripion, string productCode, string signature) public onlyOwner returns (bool){
        require(product[productOwner].owner == 0x0, "product already has owner");

        product[productOwner].owner = productOwner;
        product[productOwner].confirm = 0;
        product[productOwner].productNr = productNr;
        product[productOwner].description = productDescripion;
        product[productOwner].productCode = productCode;
        product[productOwner].signature = signature;
        product[productOwner].addTime = block.timestamp;
        totalProducts++;
    }

    function confirmProduct(uint confirmNr) public returns (bool){
        product[msg.sender].confirm = confirmNr;
    }

    function signProduct(string signatureOwner) public returns (bool){
        require(product[msg.sender].owner != 0x0, "No produt for this address");

        product[msg.sender].signature = signatureOwner;        
    }

    function resell(address buyer, string signature) public returns (bool){
        require(product[buyer].owner == 0x0, "buyer already has other product use other address");
        require(product[msg.sender].owner != 0x0, "seller has no product");

        product[buyer].owner = buyer;
        product[buyer].confirm = 0;
        product[buyer].productNr = product[msg.sender].productNr;
        product[buyer].description = product[msg.sender].description;
        product[buyer].productCode = product[msg.sender].productCode;
        product[buyer].addTime = product[msg.sender].addTime;
        product[buyer].signature = signature;
        
        product[msg.sender].owner = 0x0;        
        product[msg.sender].signature = "";     
        product[msg.sender].productNr = 0;   
        product[msg.sender].description = "";
        product[msg.sender].productCode = "";
        product[msg.sender].confirm = 0;
        product[msg.sender].addTime = 0;
    }
}