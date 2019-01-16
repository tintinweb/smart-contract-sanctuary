pragma solidity ^0.4.25;

contract Optimizedproject {
    
    uint256 usersCount = 0;
    
    struct User{
        uint256 vehiclescount;
        string aadhar;
        bool loginstatus;
    }
    
    address[]users;
    mapping(address=>User)userdetails;
    
    struct Vehiclesinfo{
        uint256 number;
        string vehicletype;
        string model;
        string vin;
        string numberplate;
        string licensenumber;
    }
    mapping(address=>mapping(uint256=>Vehiclesinfo))uservehicles;
    
    function useregister(address _hash,string _aadhar)public returns(bool){
        require(_hash==msg.sender);
        require(hashNotFound(_hash)==true);
        usersCount = usersCount + 1;
        users.push(_hash);
        userdetails[_hash].aadhar = _aadhar;
        userdetails[_hash].loginstatus = false;
        return true;
    }
    
    function hashNotFound(address _hash)internal view returns(bool){
        uint256 i=0;
        for(i=0;i<usersCount;i++){
            if(users[i]==_hash){
                return false;
            }
        }
        return true;
    }
    
    function userlogin(address _hash)public returns(bool){
        require(_hash==msg.sender);
        userdetails[_hash].loginstatus = true;
        return true;
    }
    
    function userlogout(address _hash)public returns(bool){
        require(_hash==msg.sender);
        userdetails[_hash].loginstatus = false;
    }
    
    function displayuserdetails(address _hash)public view returns(uint256,address,string){
        require(_hash == msg.sender);
        require(userdetails[_hash].loginstatus==true);
        return(userdetails[_hash].vehiclescount,_hash,userdetails[_hash].aadhar);
    }
    
    uint256 reqvehregcount = 0;
    uint256 verifiedvehregcount = 0;
    
    struct Vehiclereq{
        string aadhar;
        string vin;
        string numberplate;
        string licensenumber;
        bool status;
    }
    
    mapping(uint256=>Vehiclereq)vehiclereq;
    
    function reqvehreg(string _aadhar,string _vin,string _numberplate, string _licensenumber)public{
        reqvehregcount = reqvehregcount +1;
        vehiclereq[reqvehregcount].aadhar = _aadhar;
        vehiclereq[reqvehregcount].vin = _vin;
        vehiclereq[reqvehregcount].numberplate = _numberplate;
        vehiclereq[reqvehregcount].licensenumber = _licensenumber;
    }
    
    function checkvehrespond(uint256 num, address hash)public view validmember(num,hash) returns(bool,uint256,string,string,string,string){
        require(equals(department[num].name,"D2"));
        if(verifiedvehregcount<reqvehregcount){
            return (false,verifiedvehregcount+1,vehiclereq[verifiedvehregcount+1].aadhar,vehiclereq[verifiedvehregcount+1].vin,vehiclereq[verifiedvehregcount+1].numberplate,vehiclereq[verifiedvehregcount+1].licensenumber);
        }else{
            return (true,reqvehregcount,"","","","");
        }
    }
    
    function vehrespond(uint256 num, uint256 _verifiedvehregcount,address hash,bool decision) public validmember(num,hash){
        require(_verifiedvehregcount<reqvehregcount);
        verifiedvehregcount = verifiedvehregcount +1;
        vehiclereq[verifiedvehregcount].status = decision;
    }
    
    function vehicleregistration(address _hash,string _type,string _model,string _vin,string _numberplate,string _licensenumber)public returns(bool){
        require(_hash == msg.sender);
        require(userdetails[_hash].loginstatus==true);
        require(vehicleExist(_hash,_vin)==false);
        require(numberPlateExist(_hash,_numberplate)==false);
        //require(approvedreg(userdetails[_hash].aadhar,_vin,_numberplate,_licensenumber));
        userdetails[_hash].vehiclescount=userdetails[_hash].vehiclescount+1;
        uint256 index = userdetails[_hash].vehiclescount;
        uservehicles[_hash][index].number = index;
        uservehicles[_hash][index].vehicletype = _type;
        uservehicles[_hash][index].model = _model;
        uservehicles[_hash][index].vin = _vin;
        uservehicles[_hash][index].numberplate = _numberplate;
        uservehicles[_hash][index].licensenumber = _licensenumber;
        return true;
    }
    
    function approvedreg(string _aadhar, string _vin, string _numberplate, string _licensenumber)internal view returns(bool){
        uint256 i;
        uint256 count = verifiedvehregcount;
        for(i=1;i<=count;i++){
            if((vehiclereq[i].status)&&(equals(vehiclereq[i].aadhar,_aadhar))&&(equals(vehiclereq[i].vin,_vin))&&(equals(vehiclereq[i].numberplate,_numberplate))&&(equals(vehiclereq[i].licensenumber,_licensenumber))){
                return true;
            }
        }
        return false;
    }
    
    function vehicleExist(address _hash,string _vin)internal view returns(bool){
        uint256 i;
        for(i=1;i<=userdetails[_hash].vehiclescount;i++){
            if(equals(uservehicles[_hash][i].vin,_vin)){
                return true;
            }
        }
        if(i==userdetails[_hash].vehiclescount+1){
            return false;
        }
    }
    
    function equals(string one, string two)internal pure returns(bool){
        bytes memory a = bytes(one);
        bytes memory b = bytes(two);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        if (a.length < b.length){
            return false;
        }else if (a.length > b.length){
            return false;
        }else{
            for (uint i = 0; i < minLength; i ++){
                if(a[i]!=b[i]){
                    return false;
                }
            }
            if(i==minLength) return true;
        }
    }
    
    function numberPlateExist(address _hash,string _numberPlate)internal view returns(bool){
        uint256 i;
        for(i=1;i<=userdetails[_hash].vehiclescount;i++){
            if(equals(uservehicles[_hash][i].numberplate,_numberPlate)){
                return true;
            }
        }
        if(i==userdetails[_hash].vehiclescount+1){
            return false;
        }
    }
    
    function displayvehicledetails(address _hash, uint256 _number)public view returns(uint256,string,string,string,string,string){
        require(_hash == msg.sender);
        require(userdetails[_hash].loginstatus==true);
        require(vehicleFound(_hash,_number));
        return(_number,uservehicles[_hash][_number].vehicletype,uservehicles[_hash][_number].model,uservehicles[_hash][_number].vin,uservehicles[_hash][_number].numberplate,uservehicles[_hash][_number].licensenumber);
    }
    
    function vehicleFound(address _hash, uint256 _repNo)internal view returns(bool){
        if((_repNo>0)&&(_repNo<=userdetails[_hash].vehiclescount)){
            return true;
        }else{
            return false;
        }
    }
    
    struct Decision{
        address hash;
        string remarks;
        string deptname;
        bool opinion;
        bool variety;
    }
    
    struct DepartmentMember{
        uint256 decisionscount;
        uint256 deptdecisionscount;
        address member;
        bool existence;
        mapping(uint256=>Decision)decision;
        mapping(uint256=>Decision)deptdecision;
    }
    
    struct Request{
        address member;
        bool variety;//true-add, false-remove
    }
    
    struct Department{
        uint256 memberscount;
        uint256 presentmemberscount;
        uint256 requestscount;
        string name;
        mapping(uint256=>Request)request;
        mapping(uint256=>DepartmentMember)departmentmember;
    }
    
    mapping(uint256=>Department)department;
    uint256 departmentscount = 0;
    
    constructor(string departmentname)public{
        departmentscount = departmentscount+1;
        department[1].name = departmentname;
        department[1].memberscount = 1;
        department[1].presentmemberscount = 1;
        department[1].requestscount = 0;
        department[1].departmentmember[1].member = msg.sender;
        department[1].departmentmember[1].existence = true;
    }
    
    modifier validmember(uint256 _departmentNo,address _hash){
        require((_hash==msg.sender)&&(userdetails[_hash].loginstatus==true)&&(exist(_departmentNo,_hash)));
        _;
    }
    
    function exist(uint256 number, address hash)internal view returns(bool){
        require((number>0)&&(number<=departmentscount));
        uint256 count = department[number].memberscount;
        uint256 i=1;
        for(i;i<=count;i++){
            if((department[number].departmentmember[i].existence==true)&&(department[number].departmentmember[i].member==hash)){
                return true;
            }
        }
        return false;
    }
    
    //variety: true-add, false-remove;
    function request(uint256 _departmentNo,address _from, address _to,string _remarks,bool _variety)public validmember(_departmentNo,_from) {
        require(donealready(_departmentNo,_to,_variety)==false);
        department[_departmentNo].requestscount = department[_departmentNo].requestscount +1;
        uint256 i = department[_departmentNo].requestscount;
        department[_departmentNo].request[i].member = _to;
        department[_departmentNo].request[i].variety = _variety;
        uint256 position = getmemberposition(_departmentNo,_from);
        department[_departmentNo].departmentmember[position].decisionscount = department[_departmentNo].departmentmember[position].decisionscount +1;
        uint256 index = department[_departmentNo].departmentmember[position].decisionscount;
        department[_departmentNo].departmentmember[position].decision[index].hash = _to;
        department[_departmentNo].departmentmember[position].decision[index].opinion = true;
        department[_departmentNo].departmentmember[position].decision[index].remarks = _remarks;
        department[_departmentNo].departmentmember[position].decision[index].variety = _variety;
        
        //if all the members in governing body are accepted, then add as governing member.
        if(checkapproval(_departmentNo,department[_departmentNo].request[i].member,_variety)){
            if(_variety){
                department[_departmentNo].memberscount = department[_departmentNo].memberscount + 1;
                department[_departmentNo].presentmemberscount = department[_departmentNo].presentmemberscount + 1;
                department[_departmentNo].departmentmember[department[_departmentNo].memberscount].member = _to;
                department[_departmentNo].departmentmember[department[_departmentNo].memberscount].existence = true;
                department[_departmentNo].departmentmember[department[_departmentNo].memberscount].decisionscount = department[_departmentNo].requestscount;
            }else{
                uint256 pos = getmemberposition(_departmentNo,_to);
                department[_departmentNo].presentmemberscount = department[_departmentNo].presentmemberscount - 1;
                department[_departmentNo].departmentmember[pos].existence = false;
            }
        }
    }
    
    //this function checks whether the respective action is already taken or not.
    function donealready(uint256 number, address hash, bool _variety)internal view returns(bool){
        uint256 a = department[number].memberscount;
        //uint256 b = department[number].departmentmember[].member
        uint256 i;
        bool flag=false;
        for(i=1;i<=a;i++){
            if(department[number].departmentmember[i].member==hash){
                if(department[number].departmentmember[i].existence==true){
                    if(_variety){
                        return true;
                    }else{
                        return false;
                    }
                }else{
                    if(_variety){
                        return false;
                    }else{
                        return true;
                    }
                }
                flag=true;
            }
        }
        if(flag==false){
            if(_variety){
                return false;
            }else{
                return true;
            }
        }
    }
    
    //this functions checks whether all members in body accepted the request to join or to remove
    //i is department no., j is requestcount
    function checkapproval(uint256 i, address addr, bool _variety)internal view returns(bool){
        address k = addr;
        uint256 count = department[i].memberscount;
        uint256 x=1;
        uint256 y=1;
        uint256 action= 0;
        for(x;x<=count;x++){
            if(department[i].departmentmember[x].existence){
                uint256 decount = department[i].departmentmember[x].decisionscount;
                bool flag = false;
                for(y;y<=decount;y++){
                    if((department[i].departmentmember[x].decision[y].hash==k)&&(department[i].departmentmember[x].decision[y].variety==_variety)){
                        if(department[i].departmentmember[x].decision[y].opinion){
                            action = action +1;
                        }else{
                            return false;
                        }
                        flag=true;
                    }    
                }
                if(flag==false){
                    return false;
                }
            }      
        }
        if(action==department[i].presentmemberscount)
            return true;
        else
            return false;
    }
    
    function getmemberposition(uint256 number,address hash)internal view returns(uint256){
        uint256 i=1;
        uint256 count = department[number].memberscount;
        for(i;i<=count;i++){
            if((department[number].departmentmember[i].existence==true)&&(department[number].departmentmember[i].member==hash)){
                return i;
            }
        }
    }
    
    //this function is used for department member to check if there are any pendings to take decisions
    function checkrespond(uint256 number,address hash)public validmember(number,msg.sender) view returns(uint256,uint256,address,bool){
        uint256 pos = getmemberposition(number,hash);
        uint256 i = department[number].departmentmember[pos].decisionscount;
        if(i<department[number].requestscount){
            return(department[number].departmentmember[pos].decisionscount,department[number].requestscount,department[number].request[i].member,department[number].request[i].variety);
        }else{
            return(0,0,0x0,false);
        }
        //
    }
    
    function respond(uint256 number, address _from, address _to, string _remarks,bool _variety,bool _decision)public validmember(number,_from) returns(bool){
        require(donealready(number,_to,_variety)==false);
        require(department[number].departmentmember[getmemberposition(number,_from)].decisionscount<department[number].requestscount);
        uint256 index = department[number].departmentmember[getmemberposition(number,_from)].decisionscount + 1;
        uint256 pos = getmemberposition(number,_from);
        department[number].departmentmember[pos].decisionscount = index;
        department[number].departmentmember[pos].decision[index].hash = _to;
        department[number].departmentmember[pos].decision[index].opinion = _decision;
        department[number].departmentmember[pos].decision[index].remarks = _remarks;
        department[number].departmentmember[pos].decision[index].variety = _variety;
        if(checkapproval(number,_to,_variety)){
            if(_variety){
                department[number].memberscount = department[number].memberscount + 1;
                department[number].presentmemberscount = department[number].presentmemberscount + 1;
                uint256 count = department[number].memberscount;
                department[number].departmentmember[count].member = _to;
                department[number].departmentmember[count].existence = true;
                department[number].departmentmember[count].decisionscount = department[number].requestscount;
            }else{
                pos = getmemberposition(number,_to);
                department[number].presentmemberscount = department[number].presentmemberscount - 1;
                department[number].departmentmember[pos].existence = false;
            }    
        }
        return true;
    }
    
    struct Reqdepartment{
        address member;
        string name;
    }
    
    uint256 depreqcount;
    mapping(uint256 => Reqdepartment)reqdepartment;
    
    function notexistdept(string _name)internal view returns(bool){
        uint256 count = departmentscount;
        uint256 i=1;
        for(i;i<=count;i++){
            if(equals(department[i].name,_name)){
                return false;
            }
        }
        return true;
    }
    
    function departmentrequest(address hash,string _name,string _remarks,bool _opinion)public validmember(1,hash){
        require(notexistdept(_name));
        depreqcount = depreqcount + 1;
        reqdepartment[depreqcount].member = hash;
        reqdepartment[depreqcount].name = _name;
        uint256 pos= getmemberposition(1,hash);
        uint256 index = department[1].departmentmember[pos].deptdecisionscount + 1;
        department[1].departmentmember[pos].deptdecisionscount = index;
        department[1].departmentmember[pos].deptdecision[index].deptname = _name;
        department[1].departmentmember[pos].deptdecision[index].opinion = _opinion;
        department[1].departmentmember[pos].deptdecision[index].remarks = _remarks;
        if(deptcheckapproval(_name)){
            departmentscount = departmentscount +1;
            department[departmentscount].name = _name;
            department[departmentscount].memberscount = 1;
            department[departmentscount].presentmemberscount = 1;
            department[departmentscount].requestscount = 0;
            department[departmentscount].departmentmember[1].member = hash;
            department[departmentscount].departmentmember[1].existence = true;
        }
    }
    
    function deptcheckapproval(string j)internal view returns(bool){
        uint256 count = department[1].memberscount;
        uint256 x;
        uint256 y;
        uint256 action = 0;
        for(x=1;x<=count;x++){
            if(department[1].departmentmember[x].existence){
                uint256 decount = department[1].departmentmember[x].deptdecisionscount;
                bool flag = false;
                for(y=1;y<=decount;y++){
                    if(equals(department[1].departmentmember[x].deptdecision[y].deptname,j)){
                        if(department[1].departmentmember[x].deptdecision[y].opinion){
                            action = action+1;
                        }else{
                            return false;
                        }
                        flag=true;
                    }
                }
                if(flag==false){
                    return false;
                }
            }  
        }
        if(action==department[1].presentmemberscount){
            return true;
        }else{
            return false;
        }
    }
    
    function deptcheckrespond(address hash)public validmember(1,hash) view returns(uint256,uint256,address,string){
        uint256 pos = getmemberposition(1,hash);
        uint256 i = department[1].departmentmember[pos].deptdecisionscount;
        if(i<depreqcount){
            return(i,depreqcount,reqdepartment[i].member,reqdepartment[i].name);
        }else{
            return(0,0,0x0,"");
        }
    }
    
    function deptrespond(address _from,address _to,string _name,string _remarks,bool _opinion)public validmember(1,_from)returns(bool){
        require(department[1].departmentmember[getmemberposition(1,_from)].deptdecisionscount<depreqcount);
        uint256 pos = getmemberposition(1,_from);
        uint256 index = department[1].departmentmember[pos].deptdecisionscount +1;
        department[1].departmentmember[pos].deptdecisionscount = index;
        department[1].departmentmember[pos].deptdecision[index].deptname = _name;
        department[1].departmentmember[pos].deptdecision[index].opinion = _opinion;
        department[1].departmentmember[pos].deptdecision[index].remarks = _remarks;
        if(deptcheckapproval(_name)){
            departmentscount = departmentscount +1;
            department[departmentscount].name = _name;
            department[departmentscount].memberscount = 1;
            department[departmentscount].presentmemberscount = 1;
            department[departmentscount].requestscount = 0;
            department[departmentscount].departmentmember[1].member = _to;
            department[departmentscount].departmentmember[1].existence = true;
        }
    }
    
    function getdeptcount(uint256 num,address hash)public validmember(num,hash) view returns(uint256){
        return departmentscount;
    }
    
    function getdeptinfo(uint256 num, address hash)public validmember(num,hash) view returns(string){
        return department[num].name;
    }
    
    function checkcitizendetails(uint256 dn, string uaadhar, string uvin, string unumberplate, string ulicensenumber)public validmember(dn,msg.sender) view returns(bool,string,string,string,string){
        if(approvedreg(uaadhar, uvin, unumberplate, ulicensenumber)){
            return (true,uaadhar, uvin, unumberplate, ulicensenumber);
        }else{
            return (false,uaadhar, uvin, unumberplate, ulicensenumber);
        }
    }
}