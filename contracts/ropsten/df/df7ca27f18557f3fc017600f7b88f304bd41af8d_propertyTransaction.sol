/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity >=0.4.22 <0.6.0;
contract propertyTransaction{
    
    struct propertyInfo
    {
        string propertyType;
        string description;
    }
    
    struct transferRecord
    {
        string sellerHash;
        string buyerHash;
        string propertyType;
        string description;
        string witnessHash;
    }
    

    
    
    struct personsProperties
    {
        propertyInfo[] propertiesInfo;
    }


    address admin;
    mapping(string=>personsProperties) citizensProperties;
    mapping(string=>transferRecord[]) transactions;
    mapping(string=>uint256) totalVat;
    mapping(string=>uint256) vatPercentage;
    
    constructor() public
    {
        admin = msg.sender;
    }
    
    modifier onlyAdmin()
    {
        require(msg.sender==admin);
        _;
    }
    
    function getAdmin() public view 
    returns (address) {
        return admin;
    }
    
    function setPropertiesInfo(string memory _ownerHash,
             string memory _propertyType,
             string memory _description) onlyAdmin public
    {
        propertyInfo memory pInfo;
        pInfo.propertyType = _propertyType;
        pInfo.description = _description;
        citizensProperties[_ownerHash].propertiesInfo.push(pInfo);
    }

    
    function getPropertiesInfo(string memory  _ownerHash,
             string memory _description,
             string memory _propertyType) onlyAdmin public
             view returns (bool)
    {
        uint length = citizensProperties[_ownerHash]
                      .propertiesInfo.length;

        for (uint i = 0; i<length; i++)
        {
            if(keccak256(abi.encodePacked(
               citizensProperties[_ownerHash].propertiesInfo[i]
               .propertyType)) ==
               keccak256(abi.encodePacked(_propertyType)) &&
               keccak256(abi.encodePacked(
               citizensProperties[_ownerHash].propertiesInfo[i]
               .description)) == 
               keccak256(abi.encodePacked(_description)))
            {
                return true;
            }
        }
        return false;
    }

    
    function deletePropertiesInfo(string memory _ownerHash,
             string memory _description,
             string memory _propertyType) onlyAdmin public
      {
             uint length = citizensProperties[_ownerHash]
                           .propertiesInfo.length;
        for (uint i = 0; i<length; i++)
        {
            if(keccak256(abi.encodePacked(
               citizensProperties[_ownerHash].propertiesInfo[i]
               .propertyType)) ==
                keccak256(abi.encodePacked(_propertyType)) &&
                keccak256(abi.encodePacked(
                citizensProperties[_ownerHash].propertiesInfo[i]
                .description)) ==
                keccak256(abi.encodePacked(_description)))
             {
               delete citizensProperties[_ownerHash].propertiesInfo[i];
             }
         }
      }
      
    function vatPayment(string memory _buyerHash,
             string memory propertyType,
             uint256 propertyValue) onlyAdmin public
         {
             totalVat[_buyerHash]+=
             (vatPercentage[propertyType]*propertyValue)/100;
         }
    
    function transferProperty(
        string memory _sellerHash,
        string memory _buyerHash,
        string memory _witnessHash,
        uint256  _propertyValues,
        string memory _propertyType, 
        string memory _description,
        string memory _combinedHash) onlyAdmin public{
        
        
        transferRecord memory curRecord;
        curRecord.sellerHash = _sellerHash ;
        curRecord.buyerHash = _buyerHash;
        curRecord.propertyType = _propertyType ;
        curRecord.description = _description;
        curRecord.witnessHash = _witnessHash;
        
        transactions[_combinedHash].push(curRecord);
        vatPayment(_buyerHash, _propertyType, _propertyValues); 
        
        setPropertiesInfo(_buyerHash, _propertyType,_description);
        deletePropertiesInfo(_sellerHash, _description, _propertyType);
        
        return;
    }
        
    function initializeVat(string memory propertyType,
             uint256 _vatPercentage)  onlyAdmin public
          {
             vatPercentage[propertyType] = _vatPercentage;
          }

    function isValidPropertyTransfer(
        string memory _combinedHash,
        string memory _sellerHash,
        string memory _buyerHash,
        string memory _propertyType,
        string memory _description,
        string memory _witnessHash )
        onlyAdmin public view returns (bool)
     {       
        uint length = transactions[_combinedHash].length;
        for (uint i = 0; i<length; i++)
        {
            if(keccak256(abi.encodePacked(transactions[_combinedHash][i]
               .sellerHash)) == keccak256(abi.encodePacked(_sellerHash))
                &&
                keccak256(abi.encodePacked(transactions[_combinedHash][i]
               .buyerHash)) == keccak256(abi.encodePacked(_buyerHash))
                &&
                keccak256(abi.encodePacked(transactions[_combinedHash][i]
               .propertyType)) == keccak256(abi.encodePacked(_propertyType))
                &&
                keccak256(abi.encodePacked(transactions[_combinedHash][i]
               .description)) == keccak256(abi.encodePacked(_description))
                &&
                keccak256(abi.encodePacked(transactions[_combinedHash][i]
               .witnessHash)) == keccak256(abi.encodePacked(_witnessHash)))
             {
                 return true;
             }
        }               
         return false;
     }
    
    function getVatAmount(string memory  hashWithkey) view public 
    returns (uint256)
    {
        return totalVat[hashWithkey];
    }
    
}