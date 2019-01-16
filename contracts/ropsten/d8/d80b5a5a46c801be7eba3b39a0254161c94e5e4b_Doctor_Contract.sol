pragma solidity ^0.4.24;
contract Doctor_Contract
{
    struct Doctor
    {
        string d_name;
        uint exp;
        string d_specs;
        string d_desc;
        uint Total_patient;
        mapping(uint=>Patient) p_id;
    }
    mapping(uint=>Doctor)d_id;
    
    struct Patient
    {
        string p_name;
        string p_treat;
        string p_desc;
    }
    
    function Add_Doctor(uint _did,uint _exp,string _dspecs,string _dname,string _ddesc)
    {
        d_id[_did].d_name=_dname;
        d_id[_did].exp=_exp;
        d_id[_did].d_specs=_dspecs;
        d_id[_did].d_desc=_ddesc;
    }
    function Add_Patient(uint _did,uint _pid,string _ptreat,string _pname,string _pdesc)
    {
        d_id[_did].p_id[_pid].p_name=_pname;
        d_id[_did].p_id[_pid].p_treat=_ptreat;
        d_id[_did].p_id[_pid].p_desc=_pdesc;
        d_id[_did].Total_patient=d_id[_did].Total_patient+1;
    }
    function Show_Doctor(uint _did) public view returns(string,uint,string,string)
    {
        return(d_id[_did].d_name,d_id[_did].exp,d_id[_did].d_specs,d_id[_did].d_desc);
    }
    function Show_Patient(uint _did,uint _pid) public view returns(string,string,string)
    {
        return (d_id[_did].p_id[_pid].p_name,d_id[_did].p_id[_pid].p_treat,d_id[_did].p_id[_pid].p_desc);    
    }
    function Total_Patient(uint _did) public view returns(uint)
    {
        return d_id[_did].Total_patient;
    }
}