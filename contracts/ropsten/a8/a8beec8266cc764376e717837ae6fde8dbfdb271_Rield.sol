pragma solidity ^0.5.7; 



contract Rield  { 
    
    struct ValidationDocumentDetails {
        string propertyId;
        string propertyName;
        string previousHash;
        string currentHash;
    }
    
    struct PurchaseDetails {
        string propertyId;
        string purchaserName;
        string previousHash;
        string currentHash;
    }

    struct RentalDetails {
        string propertyId;
        string previousHash;
        string currentHash;
    }    
    
    struct PollingDetails {
        string propertyId;
        string pollingId;
        string hash;
    }    
    
    
    mapping(string => mapping(string => ValidationDocumentDetails)) validationDocumentDetailsMap;
    
    mapping(string => mapping(string => PurchaseDetails)) purchaseDetailsMap;
    
    mapping(string => mapping(string => RentalDetails)) rentalDetailsMap;
    
    mapping(string => mapping(string => PollingDetails)) pollingDetailsMap;
    
    string validationDocumentPrevHash = &#39;0&#39;;
    
    string purchaseDetailsPrevHash = &#39;0&#39;;
    
    string rentalDetailsPrevHash = &#39;0&#39;;
    
    function addValidationDocumentDetails(string memory propertyId,string memory propertyName,string memory currentHash) public{
        validationDocumentDetailsMap[propertyId][currentHash] = 
                ValidationDocumentDetails(propertyId,propertyName,validationDocumentPrevHash,currentHash);
        validationDocumentPrevHash = currentHash; 
    }
    
    function addPurchaseDetails(string memory propertyId,string memory purchaserName,string memory currentHash) public{
        purchaseDetailsMap[propertyId][currentHash] = 
                PurchaseDetails(propertyId,purchaserName,purchaseDetailsPrevHash,currentHash);
        purchaseDetailsPrevHash = currentHash; 
    }
    
    function addRentalDetails(string memory propertyId,string memory currentHash) public{
        rentalDetailsMap[propertyId][currentHash] = 
                RentalDetails(propertyId,rentalDetailsPrevHash,currentHash);
        rentalDetailsPrevHash = currentHash; 
    }
    
    function addPollingDetails(string memory propertyId,string memory pollingId,string memory hash) public{
        pollingDetailsMap[propertyId][pollingId] = PollingDetails(propertyId,pollingId,hash);
    }
    
    
    function getValidationDocumentDetails(string memory propertyId,string memory hash) view public 
        returns(string memory _propertyId,string memory _propertyName,string memory _previousHash,string memory _currentHash){
        
        ValidationDocumentDetails storage validationDocumentDetails = validationDocumentDetailsMap[propertyId][hash];
        return (validationDocumentDetails.propertyId,validationDocumentDetails.propertyName,
                validationDocumentDetails.previousHash,validationDocumentDetails.currentHash);
    }
    
    function getLatestValidationDocumentDetails(string memory propertyId) view public 
        returns(string memory _propertyId,string memory _propertyName,string memory _previousHash,string memory _currentHash){
        
        ValidationDocumentDetails storage validationDocumentDetails = validationDocumentDetailsMap[propertyId][validationDocumentPrevHash];
        return (validationDocumentDetails.propertyId,validationDocumentDetails.propertyName,
                validationDocumentDetails.previousHash,validationDocumentDetails.currentHash);
    }
    
    
    function getPurchaseDetails(string memory propertyId,string memory hash) view public 
        returns(string memory _propertyId,string memory _purchaserName,string memory _previousHash,string memory _currentHash){
        
        PurchaseDetails storage purchaseDetails = purchaseDetailsMap[propertyId][hash];
        return (purchaseDetails.propertyId,purchaseDetails.purchaserName,
                purchaseDetails.previousHash,purchaseDetails.currentHash);
    }
    
    function getLatestPurchaseDetails(string memory propertyId) view public 
        returns(string memory _propertyId,string memory _purchaserName,string memory _previousHash,string memory _currentHash){
        
         PurchaseDetails storage purchaseDetails = purchaseDetailsMap[propertyId][purchaseDetailsPrevHash];
        return (purchaseDetails.propertyId,purchaseDetails.purchaserName,
                purchaseDetails.previousHash,purchaseDetails.currentHash);
    }
    
    function getRentalDetails(string memory propertyId,string memory hash) view public 
        returns(string memory _propertyId,string memory _previousHash,string memory _currentHash){
        
        RentalDetails storage rentalDetails = rentalDetailsMap[propertyId][hash];
        return (rentalDetails.propertyId,rentalDetails.previousHash,rentalDetails.currentHash);
    }

    function getLatestRentalDetails(string memory propertyId) view public 
        returns(string memory _propertyId,string memory _previousHash,string memory _currentHash){
        
        RentalDetails storage rentalDetails = rentalDetailsMap[propertyId][rentalDetailsPrevHash];
        return (rentalDetails.propertyId,rentalDetails.previousHash,rentalDetails.currentHash);
    }    


    function getPollingDetails(string memory propertyId,string memory pollingId) view public 
        returns(string memory _propertyId,string memory _pollingId,string memory _hash){
        
        PollingDetails storage pollingDetails = pollingDetailsMap[propertyId][pollingId];
        return (pollingDetails.propertyId,pollingDetails.pollingId,pollingDetails.hash);
    }
   
}