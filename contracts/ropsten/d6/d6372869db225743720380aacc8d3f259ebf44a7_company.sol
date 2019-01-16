pragma solidity ^0.4.17;
contract company{ 
    
    uint c_count=0;
    
    struct Company{
    string c_name;
    string c_id;
    uint p_count;
    
    mapping(uint=>product) prod1;
     
    }
    
    struct product{
        string p_name;
        string p_descr;
        uint p_id;
     
        
    }
    
    mapping(uint=>Company) comp;
    
     function set_comp(uint _c_id, string _c_name) public{
         comp[_c_id].c_name= _c_name;
         c_count=c_count+1;
         
     }
     function set_prod(uint _c_id, uint _p_id, string _p_name, string _p_descr) public{
          comp[_c_id].prod1[_p_id].p_name=_p_name;
          comp[_c_id].prod1[_p_id].p_descr=_p_descr;
          comp[_c_id].p_count= comp[_c_id].p_count+1;
}

function get_comp(uint _c_id, uint _p_id) view public returns (string,string,string){
    return (comp[_c_id].c_name, comp[_c_id].prod1[_p_id].p_name,comp[_c_id].prod1[_p_id].p_descr);
}

function p_count(uint _c_id) view public returns (uint){
    return (comp[_c_id].p_count);
}

function comp_count() view public returns (uint){
    return (c_count);
}
}