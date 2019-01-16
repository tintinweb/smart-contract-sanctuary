pragma solidity ^0.4.25;
   contract dataBaseDoctor{
       
       
       struct Doctor{
           string D_Name;
           string  D_Domain;
           mapping (uint =>Patient)  PatientList;
       }
       Doctor [] Docters;
       mapping (uint => Doctor) DocterList;
       struct Patient{
           
           string p_Name;
           uint P_Age;
           string place;
           string P_type;
       }
        
       Patient [] patients;
       function setDoctor(uint d_id,string d_name,string d_domain ) public {
           DocterList[d_id].D_Name=d_name;
           DocterList[d_id].D_Domain=d_domain;
       }
       function setPatient(uint d_id,uint p_id,string p_name,string p_place,uint p_age,string p_type){
        DocterList[d_id].PatientList[p_id].p_Name=p_name;
        DocterList[d_id].PatientList[p_id].P_Age=p_age;
        DocterList[d_id].PatientList[p_id].place=p_place;
        DocterList[d_id].PatientList[p_id].P_type=p_type;
        
       }
       function showDetial(uint p_id,uint d_id)public view returns(string ,string,uint,string){
           return(DocterList[d_id].D_Name,DocterList[d_id].PatientList[p_id].p_Name,DocterList[d_id].PatientList[p_id].P_Age,DocterList[d_id].PatientList[p_id].P_type);
       }
   }