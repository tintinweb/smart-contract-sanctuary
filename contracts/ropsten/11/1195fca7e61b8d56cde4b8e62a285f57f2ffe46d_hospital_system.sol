pragma solidity^0.4.17;
contract hospital_system{
    uint h_count=0;
    struct hospital{
        string hosp_name;
        uint total_staff;
        uint hosp_id;
        mapping(uint=>doctor) doc;
        mapping(uint=>patients) pat;
    }
    
    struct patients{
        string p_name;
        uint p_id;
        string p_disease;
    }
    
    struct doctor{
        string d_name;
        uint d_id;
        string d_explicit;
    }
    
    mapping (uint=>hospital) hosp1;
    uint [] hos;
    
    function set_hosp(uint _hosp_id, string _hosp_name) public {
        hosp1[_hosp_id].hosp_name=_hosp_name;
        h_count=h_count+1;
        hos.push(_hosp_id);
    }
    
    function set_doctor(uint _hosp_id, uint _d_id, string _d_name) public{
        hosp1[_hosp_id].doc[_d_id].d_name=_d_name;
    }
    
    function set_patient(uint _hosp_id,  uint _p_id, string _p_name, string _p_disease) public{
        hosp1[_hosp_id].pat[_p_id].p_name=_p_name;
       hosp1[_hosp_id].pat[_p_id].p_disease=_p_disease;
    }
     
     function get_hosp1(uint _hosp_id, uint _d_id, uint _p_id)  view public returns (string,string,string,string ){
         
        return (hosp1[_hosp_id].hosp_name,hosp1[_hosp_id].doc[_d_id].d_name, hosp1[_hosp_id].pat[_p_id].p_name,hosp1[_hosp_id].pat[_p_id].p_disease);
     }
     
     function hosp_count() view public returns (uint){
         return (h_count);
     }
     
    }