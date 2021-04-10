/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity <=0.8.3;

contract Insurance{
   uint counter;
   struct Insured{
        uint uid;
        string name;
        bool gender;
        string bornDate;
        string id;
        string phone;
        string telephone;
        string company_telephone;
        string email;
    }
   struct Insured2{
        uint uid;
        string residence_zipcode;
        string residence_address;
        string mailing_zipcode;
        string mailing_address;
        string career;
        string company_name;
        string profession_title;
    }
   struct Insurer{
        uint uid;
        string name;
        bool gender;
        string bornDate;
        string id;
        string phone;
        string telephone;
    }
   struct Insurer2{
        uint uid;
        string company_telephone;
        string insured_Relation;
        string residence_zipcode;
        string residence_address;
        string mailing_zipcode;
        string mailing_address;
   }
   struct Payee{
       uint uid;
       string name;
       bool gender;
       string bornDate;
       string id;
       string phone;
       string telephone;
       string company_telephone;
       string insurer_Relation;
   }
   
   mapping(uint => Insured) insured;
   mapping(uint => Insured2) insured2;
   mapping(uint => Insurer) insurer;
   mapping(uint => Insurer2) insurer2;
   mapping(uint => Payee) payee;
   
   function addInsured1(string memory _name, bool _gender, string memory _bornDate, string memory _id, string memory _phone, string memory _telephone, string memory _company_telephone, string memory _email) public{
       insured[counter] = Insured(counter,_name,_gender,_bornDate,_id,_phone,_telephone,_company_telephone,_email);
   }
   
   function addInsured2(string memory _residence_zipcode, string memory _residence_address, string memory _mailing_zipcode, string memory _mailing_address, string memory _career, string memory _company_name, string memory _profession_title) public{
       insured2[counter] = Insured2(counter, _residence_zipcode, _residence_address, _mailing_zipcode, _mailing_address, _career, _company_name, _profession_title);
   }
   
   function addInsurer(string memory _name, bool _gender, string memory _bornDate, string memory _id, string memory _phone, string memory _telephone) public{
       insurer[counter] = Insurer(counter,_name,_gender,_bornDate,_id,_phone,_telephone);
   }
   
   function addInsurer2(string memory _company_telephone, string memory _insured_Relation, string memory _residence_zipcode,string memory _residence_address, string memory _mailing_zipcode, string memory _mailing_address) public{
       insurer2[counter] = Insurer2(counter,_company_telephone,_insured_Relation,_residence_zipcode,_residence_address,_mailing_zipcode,_mailing_address);
   }
   
   function addPayee(string memory _name, bool _gender, string memory _bornDate, string memory _id, string memory _phone, string memory _telephone, string memory _company_telephone, string memory _insurer_Relation) public{
       payee[counter] = Payee(counter, _name, _gender, _bornDate, _id, _phone, _telephone, _company_telephone, _insurer_Relation);
   }
   
   function searchInsured(uint uid) public view returns(Insured memory){
       require(uid <= counter);
       return insured[uid];
   }
   
   function searchInsured2(uint uid) public view returns(Insured2 memory){
       require(uid <= counter);
       return insured2[uid];
   }
   
   function searchInsurer(uint uid) public view returns(Insurer memory){
       require(uid <= counter);
       return insurer[uid];
   }
   
   function searchInsurer2(uint uid) public view returns(Insurer2 memory){
       require(uid <= counter);
       return insurer2[uid];
   }
   
   function searchPayee(uint uid) public view returns(Payee memory){
       require(uid <= counter);
       return payee[uid];
   }
   
   function addCount() public{
       counter++;
   }
   
   function memberCount() public view returns(uint){
       return counter;
   }
}