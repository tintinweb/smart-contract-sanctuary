pragma solidity ^0.5.0;

contract test{
    string public item_name;
    string public company_name;
    address public owner;
    
    constructor()public{
        owner = msg.sender;
        item_name = "plz enter name";
        company_name = "";
    }
    
   function newname(string memory newitemname,string memory newcompany_name)public  returns(string memory){
       item_name = newitemname;
       company_name = newcompany_name;
       return item_name;
       return company_name;
   }
}