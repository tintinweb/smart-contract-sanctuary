pragma solidity ^0.4.25;

 contract HospitalInfo{
     
     struct Doctor{
         string docName;
         mapping (uint =>uint)  DocPati;
     }
    
     struct Patient{
         string p_Name;
     }
     struct hospital{
         string H_Name;
         mapping (uint =>Doctor)  Doc_List;
         mapping (uint =>Patient)  pati_List;
         
     }
  
     mapping (uint => hospital)  hospitals_list;
  uint h_count=1;
  uint p_count=1;
   function addHospital(uint _h_Id,string _h_Name) public {
       h_count++;
       hospitals_list[_h_Id].H_Name=_h_Name;
     
      
   }
   function addDoctors(uint _d_Id, uint _h_Id,string _d_Name  ) public{
        hospitals_list[_h_Id].Doc_List[_d_Id].docName =_d_Name;   
   }
   function addpatient(uint _h_Id,uint _p_Id,string _p_Nmae) public {
       p_count++;
       hospitals_list[_h_Id].pati_List[_p_Id].p_Name=_p_Nmae;
       
   } 
   function assignPatient(uint _h_Id,uint _d_Id,uint _DocPati,uint _p_Id) public {
       hospitals_list[_h_Id].Doc_List[_d_Id].DocPati[_DocPati] =_p_Id;
   }
   function showhospital(uint _h_Id)public view returns(string){
       return hospitals_list[_h_Id].H_Name;
   }
   function totalhospital()public view returns(uint){
       return h_count;
   }
   function totalpatient() public view returns(uint)
   {
       return p_count;
   }
   function showEmployee(uint _h_Id,uint _d_Id,uint _p_Id) public view returns(string ,string,string){
     
       return (hospitals_list[_h_Id].H_Name,hospitals_list[_h_Id].Doc_List[_d_Id].docName ,hospitals_list[_h_Id].pati_List[_p_Id].p_Name);
   }
 }