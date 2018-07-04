pragma solidity ^0.4.23;

contract CertificateManagement {





    struct CertificateMedata {
        bytes32 key;
        bytes32 value;
    }

    struct Certificate {

        bytes32 owner;
        bytes32 certificate_status;
        bytes32 certificate_type;
        bytes32 institute;
        bytes32 approved_by;
        bytes32 approved_year;
        bytes32 certificate_no;
        bool owner_approved;
        bytes32 owner_aadhar;
        bytes32 amount;
        string isDigital;
        CertificateMedata[] certificate_medata_list;
    }

    struct RootCertificate {

        bytes32 account;
        mapping(bytes32 => Certificate) certificate_records;
        bytes32[] listofcertificate_no;

    }

    struct Student {

        bytes32 account;
        mapping(bytes32 => RootCertificate) student_records;
        bytes32[] students_array;

    }


    struct Issuer {
        bytes32 account;
        bytes32[] issuer_array;
    }


    mapping(bytes32 => Issuer) student_issuer_map;


    mapping(bytes32 => Student) master_certificate_records;




    function addCertificate(bytes32 issuer, bytes32 owner, bytes32 owner_aadhar, bytes32 c_cert_no, bytes32 c_status, bytes32 c_cert_type, bytes32 c_institute, bytes32 c_approve, bytes32 c_approve_year, bytes32 amount,string isDigital,bytes32[] keys,bytes32[] values) public {

        require(isValidCertificate(issuer, owner, c_cert_no) != true);

        master_certificate_records[issuer].student_records[owner].account = owner;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].owner = owner;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].certificate_status = c_status;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].owner_aadhar = owner_aadhar;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].certificate_type = c_cert_type;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].institute = c_institute;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].owner_approved = false;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].approved_by = c_approve;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].approved_year = c_approve_year;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].certificate_no = c_cert_no;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].amount = amount;
        master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].isDigital = isDigital;
        master_certificate_records[issuer].student_records[owner].listofcertificate_no.push(c_cert_no);
        master_certificate_records[issuer].students_array.push(owner);
        student_issuer_map[owner].issuer_array.push(issuer);
        addMetaData(issuer,owner,c_cert_no,keys,values);

    }


    function addMetaData(bytes32 issuer, bytes32 owner, bytes32 cert_no, bytes32[] keys, bytes32[] values) internal {

        require(isValidCertificate(issuer, owner, cert_no) != false);

        for (uint i = 0; i < keys.length; i++) {
            master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_medata_list.push(CertificateMedata({key : keys[i], value : values[i]}));
        }
    }


    function getCertificate(bytes32 issuer, bytes32 owner, bytes32 cert_no) public constant returns (bytes32[] certificate,bool owner_approved,string isDigital,bytes32[] keys,bytes32[] values){


        require(isValidCertificate(issuer, owner, cert_no) != false);
        certificate[0] = (master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_status);
        certificate[1] = (master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_type);
        certificate[2] = (master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].owner_aadhar);
        certificate[3] = (master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].institute);
        certificate[4] = (master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].approved_by);
        certificate[5] = (master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].approved_year);
        certificate[6] = (master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].amount);
        owner_approved = master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].owner_approved;
        isDigital = master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].isDigital;
        uint256 count = getCertificateMetaDataCount(issuer,owner,cert_no);
	    for(uint i = 0; i < count; i++){
            keys[i] = 	 master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_medata_list[i].key;
            values[i] = 	 master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_medata_list[i].value;
	    }
    }

    function isValidCertificate(bytes32 issuer, bytes32 owner, bytes32 c_cert_no) public constant returns (bool){

        if (master_certificate_records[issuer].student_records[owner].certificate_records[c_cert_no].certificate_no == 0) return false;
        return true;
    }


    function getCertificateMetaDataCount(bytes32 issuer, bytes32 owner, bytes32 cert_no) internal constant returns (uint256){
        return master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_medata_list.length;
    }


    function getCertificateMetaData(bytes32 issuer, bytes32 owner, bytes32 cert_no, uint256 idx) internal constant returns (bytes32 key, bytes32 value){
        
        key = master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_medata_list[idx].key;
        value = master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_medata_list[idx].value;
    }

    function getCertificationList(bytes32 issuer, bytes32 owner) public constant returns (bytes32[]){
        return master_certificate_records[issuer].student_records[owner].listofcertificate_no;
    }

    function getStudentArray(bytes32 issuer) public constant returns (bytes32[] students){
        students = master_certificate_records[issuer].students_array;
    }

    function getIssuerArray(bytes32 owner) public constant returns (bytes32[] issuers){
        issuers = student_issuer_map[owner].issuer_array;
    }

    function updateMetaData(bytes32 issuer, bytes32 owner, bytes32 cert_no, uint256 idx, bytes32 key, bytes32 value) public {
        require(isValidCertificate(issuer, owner, cert_no) != false);
        var metedata = master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].certificate_medata_list[idx];
        metedata.key = key;
        metedata.value = value;
    }

    function approveCertificate(bytes32 issuer,bytes32 owner,bytes32 cert_no,bool approval) public {
        require(isValidCertificate(issuer,owner,cert_no) != false);
        master_certificate_records[issuer].student_records[owner].certificate_records[cert_no].owner_approved = approval;
    }
}