/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity ^0.6.12;
pragma experimental 'ABIEncoderV2';

contract EternalStorage {

  struct CERTIFICATE {
    string student_id;
    uint256 created_at;
    uint256 admission_date;
    string admission_no; // registration number to a course
    string assign_subject_id; //link to get Course name
  }

  mapping(string => CERTIFICATE) internal studentCertificates;
  
}


contract StudentCertificate is EternalStorage {
  event StudentCertificateInserted(string student_id, string admission_no, string assign_subject_id);


  function insertStudentCertificate(
    string memory _student_id,
    uint256 _admission_date,
    string memory _admission_no,
    string memory _assign_subject_id) public {

    CERTIFICATE memory studentCertificate = CERTIFICATE(_student_id, now, _admission_date, _admission_no, _assign_subject_id);
    studentCertificates[_student_id] = studentCertificate;
    emit StudentCertificateInserted(_student_id, _admission_no, _assign_subject_id);

    }
    
    
  function getStudentCertificate(string memory _student_id) public view returns(CERTIFICATE memory studentCertificate)  {
        
    return  studentCertificates[_student_id];

    }    


}