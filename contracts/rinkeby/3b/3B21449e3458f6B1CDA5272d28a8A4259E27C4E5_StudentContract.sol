/**
 *Submitted for verification at Etherscan.io on 2021-07-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract StudentContract  {
    

    
    uint256 internal Counter = 1;
    address public _adminAdress = 0xdbcFe4fE91383f80c37300D58541a08F937B992A;
    
    // Struct to store data of users. 
    struct formData {
        string Name;
        string SurName;
        string IdentityCard;
        string FathersName;
        string MothersName;
        string Domicile;
        string DateOfBirth;
        string MailingAddress;
        uint256 PhoneNumber;
        string County;
        string Country;
        string Nationality; 
    }

//Mapping and array declarations for the contracts. 
    formData[] internal formDataArray;
    string[] internal OtherArray;
    address payable public Owner;
    mapping (address => uint256) internal indexMapping;
    
    
   
//Constructor making msg sender as owner of the contract. 
    constructor () {
        
        Owner = payable(msg.sender);        

    }
    
    
    event SetData(string message);

// function which store the data into the struct array and make necessary configuration for future retrieval . 

    function setData(string memory _Name,string memory _SurName, string memory _identityCard, string memory _FathersName,string memory _MothersName,string memory _Domicile, string memory _DateOfBirth,string memory _MailingAddress, uint256 _PhoneNumber, string memory _County, string memory _Country, string memory _Nationality) public returns (uint256) {
        require(indexMapping[msg.sender] == 0, "Data already exist for this wallet");
        formData memory tx1 = formData(_Name,_SurName,_identityCard,_FathersName,_MothersName,_Domicile,_DateOfBirth,_MailingAddress,_PhoneNumber,_County,_Country,_Nationality);
        formDataArray.push(tx1);
        indexMapping[msg.sender] = Counter;
        Counter += 1;
        
        
        emit SetData("Congratulations you have set your data");
        
        return Counter;
        }

    


//modifer declaration for functions meant for owners onlyOwner
    modifier onlyOwner() {
        require(Owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    
// function for users to get their respect data in form of tupple. 
    function getData() public view returns(formData memory){
        formData memory tx1 = formDataArray[indexMapping[msg.sender]-1];
        return tx1;
    }
    
    
// function to owner / admin to get data of specific users by enterin their inded key 
    function getDataByAdmin(uint256 Index) public onlyOwner() view returns(formData memory){
        formData memory tx1 = formDataArray[Index-1];
        return tx1;
    }






}