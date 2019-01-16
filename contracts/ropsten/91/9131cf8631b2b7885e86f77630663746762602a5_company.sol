pragma solidity ^0.4.18;
contract company
{
    uint count=0;
    struct comp
    {
        string comp_name;
        string comp_des;
        uint pro_count;
        mapping(uint=>product)pro;
    }
    uint[] comp_id;
    mapping(uint=>comp)comp_map;
    
    struct product
    {
        string pro_name;
        string pro_des;
        
    }
    uint[] pro_id;
    
    function setcompany(string _comp_name,uint c_id,string _comp_des)public 
    {
        comp_map[c_id].comp_name=_comp_name;
        comp_map[c_id].comp_des=_comp_des;
        comp_id.push(c_id)-1;
        count++;
        
    }
    function getcompany(uint c_id)public view returns(string,string)
    {
        return(comp_map[c_id].comp_name,comp_map[c_id].comp_des);
    }
    
    function setproduct(string _pro_name,string _pro_des,uint p_id,uint c_id)public
    {
        comp_map[c_id].pro[p_id].pro_name=_pro_name;
        comp_map[c_id].pro[p_id].pro_des=_pro_des;
        comp_map[c_id].pro_count++;
    }
    function getproduct(uint c_id,uint p_id)public view returns(string,string)
    {
        return(comp_map[c_id].pro[p_id].pro_name,comp_map[c_id].pro[p_id].pro_des);
        
    }
    function countpro(uint c_id)public view returns(uint)
    {
        return(comp_map[c_id].pro_count);
    }

    function countcomp()public view returns(uint)
    {
        return(count);
    }
    function cid()public view returns(uint[])
    {
        return(comp_id);
    }
    
}