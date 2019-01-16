//pragma experimental ABIEncoderV2; 
pragma solidity ^0.4.24;
contract Insurance_Company_Contract
{
    struct company
    {
        uint id;
        string comp_name;
        string location;
        uint[] emp_id;
        string[] emp_name;
        mapping(uint=>Employee)emp;
    }
    mapping(uint=>company)comp;
    struct Employee
    {
        uint comp_id;
        string e_name;
        uint age; 
    }

    function addCompany(uint _key,uint _id,string _name,string _loc) public
    {
        comp[_key].id=_id;
        comp[_key].comp_name=_name;
        comp[_key].location=_loc;
    }
    
    function showCompany(uint _key)public view returns(string,string)
    {
        return(comp[_key].comp_name,comp[_key].location);
    }
    
    function addEmployee(uint _key,uint _eid,string _ename,uint _age) public
    {
        comp[_key].emp[_eid].e_name=_ename;
        comp[_key].emp[_eid].age=_age;
        
        comp[_key].emp_id.push(_eid);
        comp[_key].emp_name.push(_ename);
    }
    function showEmployee(uint _key,uint _eid) public view returns(string,uint)
    {
        return(comp[_key].emp[_eid].e_name,comp[_key].emp[_eid].age);
    }
  /*  
    function showAll(uint _key) public view returns(string[],uint[])
    {
        return (comp[_key].emp_name,comp[_key].emp_id);
    }
    */
}