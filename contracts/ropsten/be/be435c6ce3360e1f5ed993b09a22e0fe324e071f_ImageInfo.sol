pragma solidity ^0.4.24;
contract ImageInfo{
 struct companystatus{
     string comp_id;
     string private_key;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
 }
 mapping(string => companystatus)  company_status;
 mapping(string => uint) permission_status;
 function setPermissionStatus(string c_id_1,string c_id_2,uint _status) public{
     permission_status[concat(c_id_1,c_id_2)] = _status;
     
 }
 function getPermissionStatus(string c_id_1,string c_id_2) public view returns(uint){
     return permission_status[concat(c_id_1,c_id_2)];
 }
 function setcompanyPrivateKey(string c_id,string pvt_key) public{
        company_status[c_id].comp_id = c_id;
        company_status[c_id].private_key = pvt_key;
    }
    function getcompanyPrivateKey(string c_id) public view returns(string,string){
        return(company_status[c_id].comp_id,company_status[c_id].private_key);
    }
  function concat(string _str1,string _str2) pure internal returns(string){
       return string(abi.encodePacked(_str1,_str2,","));
    }
    

}