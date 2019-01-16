pragma solidity ^0.4.18;
contract Manage_Contract5
{
    struct Employee
    {
        string e_name;                                                                                          
        mapping(uint=>uint) emp_pro;                                                                            //mapping assign_id to p_id
    }

    struct Product
    {
        string p_name;
    }

    struct Company
    {
        string c_name;
        mapping(uint=>Employee) e_id;                                                                           //mapping Emp_id_id to Employee struct
        mapping(uint=>Product) p_id;                                                                            //mapping Pro_id to Product struct
    }
    mapping(uint=>Company) comp_map;                                                                            //mapping Comp_id to Company struct

    // Adding data     
    function addCompany(uint _cid,string _cname) public                                                         //Adding Company
    {
        comp_map[_cid].c_name=_cname;
    }
    
    function addEmployee(uint _cid,uint _eid,string _ename) public                                              //Adding Employee
    {
        comp_map[_cid].e_id[_eid].e_name=_ename;
    }
    
    function addProduct(uint _cid,uint _pid,string _pname) public                                               //Adding product
    {
        comp_map[_cid].p_id[_pid].p_name=_pname;
    }
    
    function assignProduct(uint _cid,uint _eid,uint _epid,uint _pid) public                                     //Assigning product to Employee
    {
        comp_map[_cid].e_id[_eid].emp_pro[_epid]=_pid;
    }
    
    function showCompany(uint _cid)public view returns(string)                                                  //Showing Company
    {
        return comp_map[_cid].c_name;
    }
    
    function showEmployee(uint _cid,uint _eid,uint _assignid)public view returns(string,string,string)              //Showing Employee
    {
        return (comp_map[_cid].c_name,comp_map[_cid].e_id[_eid].e_name, comp_map[_cid].p_id[comp_map[_cid].e_id[_eid].emp_pro[_assignid]].p_name);
    }
    function showProduct(uint _cid,uint _pid)public view returns(string,string)                                 //Showing Product
    {
        return (comp_map[_cid].c_name,comp_map[_cid].p_id[_pid].p_name);
    }
}