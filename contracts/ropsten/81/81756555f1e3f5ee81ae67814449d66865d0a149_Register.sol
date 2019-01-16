pragma solidity ^0.4.25;

 contract Register{

 struct Details{
  string eName1;
  string eName2;

  }
 mapping (string => Details) DetailsTable;
   string proName;
   function setValue( string _product,string _eName1,string _eName2) public payable returns(bool success){
        proName=_product;
        DetailsTable[proName].eName1 = _eName1;
        DetailsTable[proName].eName2 = _eName2;
         return true;
      }
   function getAllNames(string _proName) public view returns(string,string){
         return(DetailsTable[_proName].eName1,DetailsTable[_proName].eName2);  
       }
 }