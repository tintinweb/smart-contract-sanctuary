// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
//import "./ERC20Token.sol";

contract DashToken is ERC1155{  //ERC20Token
    struct Property {
        uint256 propertyId;
        uint256 propertyPrice;
        uint256 investmentPortion;
        uint256 rentAmount;
        bool ispropertyKYC;
        uint256 balance;       //balanceOf a particular user can be found using the erc1155 function
    }
    
    // struct Owner {
    //     uint256 userId;
    //     uint256[] properties;
    //     uint256 balance;
    // }
    
    // Can assign minter and pauser roles and admin roles to the deployer
    
    struct User {
        uint256 userId;
        address user;
        bool issuerKYC;
        bool hasProperty;
        bool isOwner;                           //Check if it has samesignificance as hasProperty
        uint256[] properties;
        // uint256 balance;
    }

    struct Token {
        uint256 tokenId;
        uint256 totalTokens;
        bool isNFT;
    }
    
    mapping(uint256 => mapping(uint256 => Property)) propertywiseInvestment;    //userid => propertyid => balance
    mapping(uint256 => mapping(address => uint256)) balances;
    //mapping(uint256 => bool) _hasProperty;
    //mapping(uint256 => bool) _ispropertyKYC;
    //mapping(uint256 => bool) _issuerKYC;
    mapping(uint256 => User) userDetails;
    mapping(uint256 => Property) propertyDetails;
    mapping(uint256 => Token) tokenDetails;
    
    modifier hasProperty(uint256 userId) {
        require(userDetails[userId].hasProperty);
        _;
    }
    
    modifier issuerKYC(uint256 userId) {
        require(userDetails[userId].issuerKYC);
        _;
    }
    
    modifier ispropertyKYC(uint256 propertyId) {
        require(propertyDetails[propertyId].ispropertyKYC);
        _;
    }
    
    function addUser(uint256 _userId, address _user) public {
        userDetails[_userId].userId = _userId;
        userDetails[_userId].user = _user;
        userDetails[_userId].issuerKYC = true;
        userDetails[_userId].hasProperty = false;
    }
    
    
    function addProperty(uint256 _userId, uint256 _propertyId, uint256 _propertyPrice, 
                uint256 _investmentPortion, uint256 _rentAmount) public issuerKYC(_userId) {
        propertyDetails[_propertyId].propertyId = _propertyId;
        propertyDetails[_propertyId].propertyPrice = _propertyPrice;
        propertyDetails[_propertyId].investmentPortion = _investmentPortion;
        propertyDetails[_propertyId].rentAmount = _rentAmount;
        propertyDetails[_propertyId].ispropertyKYC = true;
        userDetails[_userId].isOwner = true;
        userDetails[_userId].hasProperty = true;
        userDetails[_userId].properties.push(_propertyId);
        uint256 _tokenId = _propertyId;
        tokenDetails[_tokenId].tokenId = _tokenId;
        tokenDetails[_tokenId].totalTokens = 1;
        tokenDetails[_tokenId].isNFT = true;
        _mint(userDetails[_userId].user, tokenDetails[_tokenId].tokenId, tokenDetails[_tokenId].totalTokens, "0x0");        //As of now the tokenId for the property is same as propertyId
        balances[_tokenId][userDetails[_userId].user] = 1; 
        
        // Use the mint function for ERC1155 
    }
    //generate id which is random so dont have to get it as an input in some of the functions
    //Check the uri function from the metadata if that can be helpful somewhere
    
    // function listProperty(uint256 _userId, uint256 _propertyId) public view returns(uint256, uint256, uint256, uint256, bool)
    //     hasProperty(_userId) ispropertyKYC(_propertyId){
    //         require()    //the function will be called only if the NFT has been issued

            //What else this function can be used for.?
            //Investment poriton to be added here

        
    // }
    function getUserDetails(uint256 _userId) public view returns(uint256 , address , bool, bool) {
        return(userDetails[_userId].userId, userDetails[_userId].user, userDetails[_userId].issuerKYC, userDetails[_userId].hasProperty);
    }
    
    function getPropertyDetails(uint256 _propertyId) public view returns(uint256, uint256, uint256, uint256, bool) {
        return(propertyDetails[_propertyId].propertyId, propertyDetails[_propertyId].propertyPrice, 
                    propertyDetails[_propertyId].investmentPortion, propertyDetails[_propertyId].rentAmount, propertyDetails[_propertyId].ispropertyKYC);
    }
    
    function invest(uint256 _owneruserId, uint256 _investoruserId, uint256 _tokenId, uint256 _propertyId, uint256 _amount) public issuerKYC(_owneruserId){
        propertywiseInvestment[_owneruserId][_propertyId].balance = _amount;
        safeTransferFrom(userDetails[_owneruserId].user, userDetails[_investoruserId].user, _tokenId, _amount, "0x0");
    }
}