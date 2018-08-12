pragma solidity ^0.4.17;
contract Certification {
    struct KhoaHoc{
        string Ten;
        uint ID;
        string NgayBatDau;
        string NgayKetThuc;
        string MoTa;
        string GiaoVien;
    }
    
    struct SinhVien{
        string DiaChi;
        string Email;
        string phone;
        string TenSinhVien;
        uint CourseID;
        bool Dat;
    }
    
    mapping (uint => KhoaHoc) public Courses;
    mapping (uint => SinhVien) public StudentRequests;
    mapping (uint => SinhVien) public SinhVienDat;
    
    address private educator ;
    uint private DemKhoaHoc = 0;
    uint private DemSinhVien = 0;
    uint private DemSinhVienDat = 0;
    uint private SoSinhVienDaKiemTra=0;
    
    
    constructor () public {
       educator = msg.sender;
    }
    
    
    function ThemKhoaHoc (string _Ten,
    uint _ID, 
    string _NgayBatDau, 
    string _NgayKetThuc, 
    string _MoTa, 
    string _GiaoVien) 
    public hasPermission {
        DemKhoaHoc++;
        Courses[DemKhoaHoc]= KhoaHoc(_Ten,_ID, _NgayBatDau, _NgayKetThuc , _MoTa,_GiaoVien);
        
    } 
    
    
    modifier hasPermission {
        require(msg.sender == educator);
        _;
    }
    
   
    
    function DemSoKhoaHoc() public view returns(uint _SoKhoaHoc){
    
        return DemKhoaHoc;
    }
    
    
    function ApplyForCertification (string _DiaChi, 
    string _Email, 
    string _phone, 
    string _TenSinhVien, 
    uint _CourseID) 
    public{
        DemSinhVien++;
        StudentRequests[DemSinhVien]=SinhVien(_DiaChi, _Email,_phone,_TenSinhVien,_CourseID,false);
         
    }
    
    function DemSinhVienRequests() public view returns(uint ){
        return DemSinhVien;
    }
    
    function DeleteAllRequests() public{
        uint i = 0;
        
        while (i <= DemSinhVien){
            
            delete StudentRequests[i];
            i++;
            
        }
        DemSinhVien=0;
        SoSinhVienDaKiemTra=0;
    }
    
    function approve() public hasPermission
    {
        SoSinhVienDaKiemTra++;
        if(SoSinhVienDaKiemTra<=DemSinhVien)
        {
            DemSinhVienDat++;
            SinhVienDat[DemSinhVienDat] = StudentRequests[SoSinhVienDaKiemTra];
            SinhVienDat[DemSinhVienDat].Dat=true;
            StudentRequests[SoSinhVienDaKiemTra].Dat=true;
        }
    }
    function Reject() public hasPermission
    {
        SoSinhVienDaKiemTra++;
        if(SoSinhVienDaKiemTra<=DemSinhVien)
        {
            StudentRequests[SoSinhVienDaKiemTra].Dat=false;
        }
    }
    
    function _DemSinhVienDat() public view returns(uint ){
        return DemSinhVienDat;
    }
    
  
    function KiemTra(uint _a) 
    public view returns  (string _Ten, 
    uint _ID,
    string _NgayBatDau,
    string _NgayKetThuc , 
    string _MoTa, 
    string _GiaoVien){
        
        uint i = DemKhoaHoc;
        while (i>0){
            
            if (SinhVienDat[_a].CourseID==Courses[i].ID){
                return (Courses[i].Ten, Courses[i].ID, Courses[i].NgayBatDau, Courses[i].NgayKetThuc, Courses[i].MoTa,
                Courses[i].GiaoVien);
            }
            else
                return ("",0,"","","","");
                
        i--;
        }
       
    }
    

}