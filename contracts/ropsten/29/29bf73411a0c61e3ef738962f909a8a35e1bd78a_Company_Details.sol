pragma solidity ^0.5.1;
contract Company_Details
{
    struct Company
    {   
        string c_id;
        string c_name;
        string c_decs;
        string[] c_img;
        string Admin_names;
        string Employee_names;
        string LEmployee_names;
        string Product_names;
    }
    string company_names;
    mapping(string=>Company) Comp_map;
    
    struct Admin
    {
        string c_id;
        string a_id;
        string a_name;
        string a_type;
        string email;
        string pass;
        uint cell;
        bool status;
    }
    mapping(string=>Admin)Admncomp;
    
    struct Employee
    {
        string c_id;
        string a_id;
        string e_id;
        string e_name;
        uint cell;
        string email;
        string pass;
        string cpass;
        string e_role;
        bool status;
    }
    mapping(string=>Employee)CompEmp;
     
    struct Logistic_Employee
    {
        string c_id;
        string a_id;
        string le_id;
        string le_name;
        uint cell;
        string email;
        string pass;
        string cpass;
        bool status;        
    }
    mapping(string=>Logistic_Employee)CompLemp;
     
    struct Products
    {
        string c_id;
        string p_id;
        string p_desc;
        string[] p_img;
        string p_name;
        bool status;
    }
    mapping(string=>Products)CompPro;

    function Add_Company_Details(string memory _cid,string memory _cname,string memory _cdesc) public
    {
        Comp_map[_cid].c_id=_cid;
        Comp_map[_cid].c_name=_cname;
        Comp_map[_cid].c_decs=_cdesc;
        company_names=concate(_cid,company_names);
    }
    
    function Add_Company_Images(string memory _cid,string memory _img) public
    {
        Comp_map[_cid].c_img.push(_img);
    }
    
    function Add_Admin(string memory _cid,string memory _aid,string memory _aname,string memory _atype,string memory _email,string memory _pass,uint _cell,bool _status) public
    {
        Admncomp[_aid].a_id=_aid;
        Admncomp[_aid].c_id=_cid;
        Admncomp[_aid].a_name=_aname;
        Admncomp[_aid].a_type=_atype;
        Admncomp[_aid].email=_email;
        Admncomp[_aid].pass=_pass;
        Admncomp[_aid].cell=_cell;
        Admncomp[_aid].status=_status;
        Comp_map[_cid].Admin_names=concate(_aid,Comp_map[_cid].Admin_names);
    }
    
    function Add_Employee(string memory _cid,string memory _eid,string memory _ename,uint _cell,string memory _email,string memory _pass,string memory _cpass,string memory _erole,bool _status) public
    {
        CompEmp[_eid].e_id=_eid;
        CompEmp[_eid].c_id=_cid;
        CompEmp[_eid].e_name=_ename;
        CompEmp[_eid].cell=_cell;
        CompEmp[_eid].email=_email;
        CompEmp[_eid].pass=_pass;
        CompEmp[_eid].cpass=_cpass;
        CompEmp[_eid].e_role=_erole;
        CompEmp[_eid].status=_status;
        Comp_map[_cid].Employee_names=concate(_eid,Comp_map[_cid].Employee_names);
    }
    
    function Add_Logistic_Employee(string memory _cid,string memory _eid,string memory _ename,uint _cell,string memory _email,string memory _pass,string memory _cpass,bool _status) public
    {
        CompLemp[_eid].le_id=_eid;
        CompLemp[_eid].c_id=_cid;
        CompLemp[_eid].le_name=_ename;
        CompLemp[_eid].cell=_cell;
        CompLemp[_eid].email=_email;
        CompLemp[_eid].pass=_pass;
        CompLemp[_eid].cpass=_cpass;
        CompLemp[_eid].status=_status;
        Comp_map[_cid].LEmployee_names=concate(_eid,Comp_map[_cid].LEmployee_names);
    }
    
    function AddProducts(string memory _cid,string memory _pid,string memory _pname,string memory _desc,bool _status) public
    {
        CompPro[_pid].p_id=_pid;
        CompPro[_pid].c_id=_cid;
        CompPro[_pid].p_name=_pname;
        CompPro[_pid].p_desc=_desc;
        CompPro[_pid].status=_status;
        Comp_map[_cid].Product_names=concate(_pid,Comp_map[_cid].Product_names);
    }
    
    function Add_Products_Images(string memory _pid,string memory _img) public
    {
        CompPro[_pid].p_img.push(_img);
    }
    
    function Show_Company_Details(string memory _cid) public view returns(string memory,string memory)
    {
        return(
                Comp_map[_cid].c_name,
                Comp_map[_cid].c_decs
              );
    }
    
    function Show_Admin_Details(string memory _aid) public view returns(string memory,string memory,string memory,string memory,string memory,uint,bool)
    {
            return(
                    Admncomp[_aid].c_id,
                    Admncomp[_aid].a_name,
                    Admncomp[_aid].a_type,
                    Admncomp[_aid].email,
                    Admncomp[_aid].pass,
                    Admncomp[_aid].cell,
                    Admncomp[_aid].status
                  );
    }
    
    function Show_Employee_Details(string memory _eid) public view returns(string memory,string memory,uint,string memory,string memory,string memory,string memory)
    {
           return(
                    CompEmp[_eid].c_id,
                    CompEmp[_eid].e_name,
                    CompEmp[_eid].cell,
                    CompEmp[_eid].email,
                    CompEmp[_eid].pass,
                    CompEmp[_eid].cpass,
                    CompEmp[_eid].e_role
                  );
    }

    function Show_Logistic_Employee_Details(string memory _eid) public view returns(string memory,string memory,uint,string memory,string memory,string memory,bool)
    {
            return(
                    CompLemp[_eid].c_id,
                    CompLemp[_eid].le_name,
                    CompLemp[_eid].cell,
                    CompLemp[_eid].email,
                    CompLemp[_eid].pass,
                    CompLemp[_eid].cpass,
                    CompLemp[_eid].status
                  );
    }

    function Show_Product_Details(string memory _pid) public view returns(string memory,string memory,string memory,bool)
    {
            return(
                    CompPro[_pid].c_id,
                    CompPro[_pid].p_name,
                    CompPro[_pid].p_desc,
                    CompPro[_pid].status
                  );
    }

    function Show_All_Company() public view returns(string memory)
    {
        return company_names;
    }
    
    function Show_All_Admin(string memory _cid) public view returns(string memory)
    {
        return Comp_map[_cid].Admin_names;
    }
    
    function Show_All_Employees(string memory _cid) public view returns(string memory)
    {
        return Comp_map[_cid].Employee_names;
    }
    
    function Show_All_Logistic_Employees(string memory _cid) public view returns(string memory)
    {
        return Comp_map[_cid].LEmployee_names;
    }
    
    function Show_All_Products(string memory _cid) public view returns(string memory)
    {
        return Comp_map[_cid].Product_names;
    }
    
    function concate(string memory arr1,string memory arr2 ) internal pure returns(string memory)
    {
        arr2=string(abi.encodePacked(arr2," ",arr1));
        return arr2;
    }
}