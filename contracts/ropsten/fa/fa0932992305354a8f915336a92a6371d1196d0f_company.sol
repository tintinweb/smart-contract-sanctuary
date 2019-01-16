pragma solidity ^0.4.0;
contract company
{    uint count=0;
    struct companydetail
    {   
        string cmpname;
        uint cmpid;
        string description;
        mapping (uint =>product)products;
    }
    struct product
    {uint pid;
     string prdname;
     uint count;
     string description1;
    }
    mapping (uint=>companydetail) cmpny;
    function setcompany(uint _cmpid,string _cmpname,string _description) public 
    {   
        cmpny[_cmpid].cmpname=_cmpname;
         cmpny[_cmpid].description=_description;
         count=count+1;
    }
    function getcompany(uint _cmpid) public view returns(string,string,string,uint)
    {
        return( cmpny[_cmpid].cmpname,cmpny[_cmpid].description,"total no. of company:",count);
    }
    function setproduct(uint _cmpid,uint _pid,string _prname,string _description1)public
    {  
        cmpny[_cmpid].products[_pid].prdname=_prname;
        cmpny[_cmpid].products[_pid].description1=_description1;
         cmpny[_cmpid].products[_pid].count=count+1;
        
    }
    function getalldeatil(uint _cmpid,uint _pid) public view returns(string,string,string,string,string,uint)
    {     
        return(cmpny[_cmpid].cmpname,cmpny[_cmpid].description,cmpny[_cmpid].products[_pid].prdname,cmpny[_cmpid].products[_pid].description1,"total no of products",count);
    }
}