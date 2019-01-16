pragma solidity ^0.4.0;
contract hospital
{    uint count=0;
    struct doctor
    {   
        string docname;
        uint docid;
        string specia;
        mapping (uint =>patient) patients;
    }
    struct patient
    {
        uint pid;
        string ptname;
        uint count;
        string disease;
    }
    mapping (uint=>doctor) doctors;
    function docdetail(uint _docid,string _docname,string _specia) public 
    {   
         doctors[_docid].docname=_docname;
         doctors[_docid].specia=_specia;
         count=count+1;
    }
    function getdoc(uint _docid) public view returns(string,string,string,uint)
    {
        return(doctors[_docid].docname,doctors[_docid].specia," no. of doctors :",count);
    }
    function setpatient(uint _docid,uint _pid,string name,string _disease)public
    {  
       doctors[_docid].patients[_pid].ptname=name;
        doctors[_docid].patients[_pid].disease=_disease;
          doctors[_docid].patients[_pid].count=count+1;
        
    }
    function getalldeatil(uint _docid,uint _pid) public view returns(string,string,string,string,string,uint)
    {     
        return(doctors[_docid].docname,doctors[_docid].specia,doctors[_docid].patients[_pid].ptname, doctors[_docid].patients[_pid].disease,"number of patients",count);
    }
}