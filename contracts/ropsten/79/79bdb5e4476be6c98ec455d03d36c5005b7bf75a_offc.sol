pragma solidity ^0.4.17;
contract offc{
    struct emp{
        string emp_name;
       uint id;
       mapping (uint=>product) product1;
         }
         
    struct company{
        string name;
        uint comp_id;
        mapping (uint=>emp) empl;
        
    }
    
    uint[] e_id;
    uint[]  p_id;

struct product{
    string prod_name;
    uint prod_id;
}
mapping (uint=>company) company1;
uint[] c_id;
function set_comp(uint _comp_id, string  _name )public {
    company1 [_comp_id].name=_name;
    c_id.push(_comp_id);
}
function set_emp(uint _comp_id, string _emp_name, uint _id) public {
    company1[_comp_id].empl[_id].emp_name=_emp_name;
}
function set_prod(uint _comp_id, uint _id, uint _prod_id, string _prod_name) public {
    company1[_comp_id].empl[_id].product1[_prod_id].prod_name=_prod_name;
}
function get_company (uint _comp_id, uint _prod_id, uint _id) view public returns (string,string,string)
{
    return (company1[_comp_id].name, company1[_comp_id].empl[_id].emp_name, company1[_comp_id].empl[_id].product1[_prod_id].prod_name);
}
}