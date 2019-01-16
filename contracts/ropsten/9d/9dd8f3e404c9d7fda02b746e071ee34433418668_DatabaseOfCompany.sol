pragma solidity ^0.4.25;

 contract DatabaseOfCompany{
     
     struct Employee{
         string empName;
         mapping (uint =>uint)  empPro;
     }
    // uint [] empId;
    // uint [] proId;
     struct Product{
         string proName;
     }
     struct Company{
         string comName;
         mapping (uint =>Employee)  empList;
         mapping (uint =>Product)  proList;
         
     }
  //   uint [] cmpId;
     mapping (uint => Company)  Company_map;
  
   function addCompany(uint _cmpId,string _comName) public {
       Company_map[_cmpId].comName=_comName;
   }
   function addEmployee(uint _empId, uint _cmpId,string _empName  ) public{
        Company_map[_cmpId].empList[_empId].empName =_empName;   
   }
   function addProduct(uint _cmpId,uint _proId,string _proNmae) public {
       Company_map[_cmpId].proList[_proId].proName=_proNmae;
   } 
   function assignProduct(uint _cmpId,uint _empId,uint _empPro,uint _proId) public {
       Company_map[_cmpId].empList[_empId].empPro[_empPro] =_proId;
   }
   function showCompany(uint _cmpId)public view returns(string){
       return Company_map[_cmpId].comName;
   }
   function showEmployee(uint _cmpId,uint _empId,uint _proId) public view returns(string ,string,string){
       return (Company_map[_cmpId].comName, Company_map[_cmpId].empList[_empId].empName,Company_map[_cmpId].proList[_proId].proName);
   }
 }