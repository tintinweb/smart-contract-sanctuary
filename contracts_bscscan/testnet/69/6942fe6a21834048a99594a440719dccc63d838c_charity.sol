/**
 *Submitted for verification at BscScan.com on 2021-10-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract charity{
    
    address owner;
    //Storage for storing Funds In
    struct fundsIn{
        
        string fundsInId;
        string donationId;
        string organizationName;
        address fundsOutAddress;
        uint256 amount;
        string date;
        string time;
    }
    fundsIn fund;
    
    //storage for funds out
    struct fundsOut{
        
        string fundsOutId;
        string projectTitle;
        string projectDescription;
        transactionDetal _transactionDetal;
        adminExpense _adminExpense;
        promotionExpenses _promotionExpenses;
        salariesExpenses _salariesExpenses;
    }
    
    //storage for transaction donationDetail
    struct transactionDetal{
        uint256 fees;
        uint256 amount;
        address _address;
       
    }
    
    //storage for admin expense
      struct adminExpense{
          string expenseHead;
          string expenseNote;
          uint256 amount;
          string date;
          string time;
    }
    
    //storage for promotion expenses
    struct promotionExpenses{
        string expenseHead;
        string expenseNote;
        uint256 amount;
        string date;
        string time;
    }
    
    //storage for salaries expenses
      struct salariesExpenses{
        string expenseHead;
        string expenseNote;
        uint256 amount;
        string date;
        string time;
    }
    //mapping of donationId 
    mapping(string=>fundsIn[]) donationDetailEnglish;
    
     //mapping of donationId 
    mapping(string=>fundsIn[]) donationDetailChinese;
    
    
    //mapping of fundOutId in English 
    mapping(string=>fundsOut[]) _fundsOutDetailEnglish;
    
     //mapping of fundOutId in Chinese 
    mapping(string=>fundsOut[]) _fundsOutDetailChinese;
    
    //mapping for getting findsin with donation id
    mapping(string=>fundsIn) _donationIdToFundsIn;
    
    //mapping for checking  FundsInid is exist or not;
    mapping(string=>bool) _isFundsInIdExist;
    
     //mapping for checking  FundsOutid is exist or not;
    mapping(string=>bool) _isFundsOutIdExist;
    
    
    constructor(){
        owner = msg.sender;
    }
    
    //modifier
    modifier onlyOwner(){
        require(owner==msg.sender,"Only owner can call this");
        _;
    }
    
    //function for setting value of funds In English
    function setFundsIn(string memory _findsInId,fundsIn memory _fundsInEnglish,fundsIn memory _fundsInChinese) public returns(fundsIn[] memory,fundsIn[] memory){
        
        require(_isFundsInIdExist[_findsInId] == false,"FundsIn id is already exist");
        _isFundsInIdExist[_findsInId]=true;
        _donationIdToFundsIn[_fundsInEnglish.donationId] = _fundsInEnglish;
        donationDetailEnglish["Eng"].push(_fundsInEnglish);
        donationDetailChinese["Chn"].push(_fundsInChinese);
        return (donationDetailEnglish["Eng"],donationDetailChinese["Chn"]);
    }
    
    //function for getting fundsIn by its donation id
    function getfundsInbyId(string memory _Id) public view returns(fundsIn memory){
        return _donationIdToFundsIn[_Id];
    }
   
    
    //function will list out the funds In
   function getFundsIn(string memory _language) public view returns (fundsIn[] memory)
    {
         require(keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("English")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("Chinese")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("english")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("chinese")),"Invalid language provided");
        if(keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("English")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("english"))){
             return donationDetailEnglish["Eng"] ;
        }
        else{
        return donationDetailChinese["Chn"];
        }
       
    }
    //function for setting of fundsout details in English
    
      function setFundsOut(string memory _findsOutId,fundsOut memory _fundsOutEnglish, fundsOut memory _fundsOutChinese) public returns (fundsOut[] memory,fundsOut[] memory){
          
           require(_isFundsOutIdExist[_findsOutId] == false,"FundsOut id is already exist");
           _isFundsOutIdExist[_findsOutId]=true;
           
         //======================assigning in english======================================
         
            _fundsOutDetailEnglish["Eng"].push(_fundsOutEnglish);
            
         //==========================assigning in chinese==========================================
               
            _fundsOutDetailChinese["Chn"].push(_fundsOutChinese);
            
         return ( _fundsOutDetailEnglish["Eng"],_fundsOutDetailChinese["Chn"]);
     }
     
    
     
     //function for getting fundsOut
     function getFundsout(string memory _language) public view returns(fundsOut[] memory){
         
         require(keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("English")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("Chinese")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("english")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("chinese")),"Invalid language provided");
         if(keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("English")) || keccak256(abi.encodePacked(_language)) == keccak256(abi.encodePacked("english"))){
              return (_fundsOutDetailEnglish["Eng"]);
         }
          return (_fundsOutDetailChinese["Chn"]);
       
    }
}