pragma solidity ^0.4.18;
contract smartdoctor
{
    struct doctor
    {
        string doc_name;
        string doc_des;
        uint pat_count;
        mapping(uint=>patient)pr;
    }
    mapping(uint=>doctor)doc_map;
    uint[] doc_id;
    
    struct patient
    {
        string pat_name;
        string pat_dis;
    }
    uint[] pat_id;
    
    function setdoctor(string _doc_name,uint d_id,string _doc_des)public 
    {
        doc_map[d_id].doc_name=_doc_name;
        doc_map[d_id].doc_des=_doc_des;
        
    }
    function getdoctor(uint d_id)public view returns(string,string)
    {
        return(doc_map[d_id].doc_name,doc_map[d_id].doc_des);
    }
    
    function setpatient(string _pat_name,string _pat_dis,uint p_id,uint d_id)public
    {
        doc_map[d_id].pr[p_id].pat_name=_pat_name;
        doc_map[d_id].pr[p_id].pat_dis=_pat_dis;
        doc_map[d_id].pat_count++;
    }
    function getpatient(uint d_id,uint p_id)public view returns(string,string)
    {
        return(doc_map[d_id].pr[p_id].pat_name,doc_map[d_id].pr[p_id].pat_dis);
        
    }
    function countpat(uint d_id)public view returns(uint)
    {
        return(doc_map[d_id].pat_count);
    }

}