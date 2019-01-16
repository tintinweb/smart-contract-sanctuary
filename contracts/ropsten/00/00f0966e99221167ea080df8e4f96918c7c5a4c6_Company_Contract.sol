pragma solidity ^0.4.24;
contract Company_Contract
{
    uint count_comp=0;
    struct Company
    {
        string c_name;
        string c_desc;
        uint countprod;
        mapping(uint=>Product) p_id;
    }
    mapping(uint=>Company)c_id;
    
    struct Product
    {
        string p_name;
        string p_desc;
    }
    
    function Add_Company(uint _cid,string _cname,string _cdesc)
    {
        c_id[_cid].c_name=_cname;
        c_id[_cid].c_desc=_cdesc;
        count_comp=count_comp+1;
    }
    function Add_Product(uint _cid,uint _pid,string _pname,string _pdesc)
    {
        c_id[_cid].p_id[_pid].p_name=_pname;
        c_id[_cid].p_id[_pid].p_desc=_pdesc;
        c_id[_cid].countprod=c_id[_cid].countprod+1;
    }
    function Show_Company(uint _cid) public view returns(string,string)
    {
        return(c_id[_cid].c_name,c_id[_cid].c_desc);
    }
    function Show_Product(uint _cid,uint _pid) public view returns(string,string)
    {
        return (c_id[_cid].p_id[_pid].p_name,c_id[_cid].p_id[_pid].p_desc);    
    }
    
    function Total_Products(uint _cid) public view returns(uint)
    {
        return c_id[_cid].countprod;
    }
    function Total_Companies() public view returns(uint)
    {
        return count_comp;
    }
}