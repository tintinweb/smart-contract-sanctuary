/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

contract StudentManager {

    uint ID;

    struct Student {
        uint MSSV;
        string student;
        string HocLuc;
        uint diemToan;
        uint diemLy;
        uint diemHoa;
        uint dtb;
        
    }

    event GetNewStudent (uint MSSV,string student, string HocLuc, uint diemToan, uint diemLy, uint diemHoa, uint dtb);
    event GetUpdateStudent (uint MSSV,string student,  string HocLuc, uint diemToan, uint diemLy, uint diemHoa, uint dtb);


    string[] private studentMSSV;
    uint[] private addressMSSV;

    mapping (uint => string) Class;

    mapping (string => Student) private Students;
    mapping (uint => Student) private Addresses;
    
    Student[] private lstStudent;

    function hocLucChecker(uint diemToan, uint diemLy, uint diemHoa) internal pure returns(string memory) {
        string memory HocLuc;
        uint dtb = (diemHoa+diemToan+diemLy)/3;
        if (dtb < 5){
            HocLuc = "Yeu";
        }
        else if (dtb < 6 && dtb >=5){
            HocLuc = "Trung binh";
        }
        else if (dtb < 7 && dtb >= 6){
            HocLuc = "Trung binh-kha";
        }
        else if (dtb < 8 && dtb >= 7){
            HocLuc = "Kha";
        }
        else if (dtb < 9 && dtb >= 8){
            HocLuc = "Gioi";
        }
        else{
            HocLuc = "Xuat sac";
        }
        return HocLuc;
    }

    function isStudent(string memory student)
    public
    view
    returns(bool isIndeed)
    {
        if(studentMSSV.length == 0) return false;

        return keccak256(bytes(student)) == keccak256(bytes(studentMSSV[Students[student].MSSV]));

    }

    function addStudent(
        string memory student,
        uint diemToan, 
        uint diemLy, 
        uint diemHoa
        )
    public
    returns(uint MSSV)
    {
        require(diemToan >= 0 && diemToan <= 10 && diemLy >= 0 && diemLy <= 10 &&diemHoa >= 0 && diemHoa <= 10 ,"Sai dinh dang diem");
        string memory HocLuc = hocLucChecker(diemToan, diemLy, diemHoa);
        uint dtb =  (diemLy+diemToan+diemHoa)/3;
        Addresses[ID].MSSV = addressMSSV.push(ID)-1;
        Students[student].HocLuc   = HocLuc;
        Students[student].MSSV = studentMSSV.push(student)-1;
        Students[student].diemToan = diemToan;
        Students[student].diemLy = diemLy;
        Students[student].diemHoa = diemHoa;
        Students[student].dtb = (diemLy+diemToan+diemHoa)/3;
        emit GetNewStudent (Students[student].MSSV,student, HocLuc, diemToan, diemLy, diemHoa, dtb);
        lstStudent.length++;
        lstStudent[lstStudent.length - 1].student = student;
        lstStudent[lstStudent.length-1].diemToan = diemToan;
        lstStudent[lstStudent.length-1].diemLy = diemLy;
        lstStudent[lstStudent.length-1].diemHoa = diemHoa;
        lstStudent[lstStudent.length-1].HocLuc = HocLuc;
        lstStudent[lstStudent.length-1].dtb = (diemLy+diemToan+diemHoa)/3;
        lstStudent[lstStudent.length-1].MSSV = Students[student].MSSV;
        return studentMSSV.length-1;
    }

    function getStudentInfo(string memory student)
    public
    view
    returns( uint MSSV, string memory HocLuc,uint diemToan,uint diemLy,uint diemHoa,uint dtb)
    {
      require(isStudent(student), "Sinh vien nay khong co trong lop");
        return(
        Students[student].MSSV,
        Students[student].HocLuc,
        Students[student].diemToan,
        Students[student].diemLy,
        Students[student].diemHoa,
        Students[student].dtb
        );
    }

    function updateStudent(string memory student,uint diemToan, uint diemLy, uint diemHoa)
    public 
    returns(bool success)
    {
        require(isStudent(student), "Sinh vien nay khong co trong lop");

        string memory HocLuc = hocLucChecker(diemToan,diemLy,diemHoa);
        uint dtb =  (diemLy+diemToan+diemHoa)/3;
        Students[student].diemToan;
        Students[student].diemLy;
        Students[student].diemHoa;
        Students[student].dtb = (diemLy+diemToan+diemHoa)/3;
        Students[student].HocLuc   = HocLuc;

        emit GetUpdateStudent (Students[student].MSSV,student,HocLuc, diemToan,diemLy,diemHoa,dtb);
        lstStudent[Students[student].MSSV].diemToan = diemToan;
        lstStudent[Students[student].MSSV].diemLy = diemLy;
        lstStudent[Students[student].MSSV].diemHoa = diemHoa;
        lstStudent[Students[student].MSSV].dtb = (diemLy+diemToan+diemHoa)/3;
        lstStudent[Students[student].MSSV].HocLuc = HocLuc;
        return true;

    }

    function getStudentCount()
    public
    view
    returns(uint count)
    {
        return studentMSSV.length;
    }

    function getStudentNameAtMSSV(uint MSSV)
    public
    view
    returns(string memory student)
    {
        require(MSSV < studentMSSV.length, "Ma so sinh vien sai");
        return studentMSSV[MSSV];
    }
    
    function get3HighestGPA() public view returns(Student[] memory res){
        res = new Student[](3);
        Student[] memory newSV = new Student[](lstStudent.length);
        uint x =0;
        for(uint i = 0; i < lstStudent.length ; i++){
            newSV[x] = lstStudent[i];
            x++;
        }
        for (uint i = 0; i < newSV.length; i++){
            for (uint j = i+1; j <newSV.length; j++){
                if((newSV[i].diemToan+newSV[i].diemLy+newSV[i].diemHoa) < (newSV[j].diemToan+newSV[j].diemLy+newSV[j].diemHoa)){
                    Student memory temp = newSV[i];
                    newSV[i] = newSV[j];
                    newSV[j]= temp;
                }
            }
        }
        for (uint i=0;i< (3<newSV.length?3:newSV.length) ;i++)
            res[i] = newSV[i];
    }
    
   function getStudentHocLai() public view returns(Student[] memory res){
      uint cnt = 0;
      for(uint i = 0; i < lstStudent.length; i++){
          if(lstStudent[i].diemToan < 5 ||lstStudent[i].diemLy < 5||lstStudent[i].diemHoa < 5){
              cnt++;
          }
      }
      require(cnt > 0, "Khong ai phai hoc lai");
        res = new Student[](cnt);
      uint x =0;
      for(uint i = 0; i < lstStudent.length; i++){
           if(lstStudent[i].diemToan < 5 ||lstStudent[i].diemLy < 5||lstStudent[i].diemHoa < 5){
                res[x] = lstStudent[i];
                x++;
      }
      }
    }
    
    function compStr(string memory a, string memory b) private view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
    
    function getStudentByHocLuc(string memory _HocLuc) public view returns (Student[] memory res){
        uint count = 0;
        for (uint i=0;i<lstStudent.length;i++)
            if (compStr(lstStudent[i].HocLuc, _HocLuc)){
                count++;
            }
            
        res = new Student[](count);
        uint j=0;
        for (uint i=0;i<lstStudent.length;i++)
            if (compStr(lstStudent[i].HocLuc, _HocLuc)){
                res[j]=lstStudent[i];
                j++;
            }
    }
    
    
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }
    
    

    function getClass() public view returns(string memory) {
        string memory rString;

        for(uint i = 0; i < studentMSSV.length; i++) {
            rString = strConcat(rString,studentMSSV[i]);
            rString = strConcat(rString,",");
        }
        return rString;
    }

}