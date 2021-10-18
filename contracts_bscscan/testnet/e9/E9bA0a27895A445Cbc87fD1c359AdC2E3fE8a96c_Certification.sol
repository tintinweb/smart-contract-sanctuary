/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

pragma solidity >=0.7.0 <0.9.0;

contract Certification {
    
    struct Certificate {
        string candidate_name;
        string org_name;
        string course_name;
        uint256 issue_date;
        uint256 expiration_date;
    }
    

    string public institution_name;
    
    mapping(bytes32 => Certificate) public certificates;
    mapping(address => bool) private isAdmin;

    event certificateGenerated(bytes32, Certificate);
    event adminChanged(address, bool);
    
    constructor() {
        institution_name = 'Blitz Broker';
        isAdmin[msg.sender] = true;
    }
    
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], 'You are not admin');
        _;
    }
    
    function setAdmin(address _a, bool _b) external onlyAdmin {
        isAdmin[_a] = _b;
        emit adminChanged(_a, _b);
    }
    
    function setInstitutionName(string memory _name) external onlyAdmin {
        institution_name = _name;
    }


    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
                result := mload(add(source, 32))
        }
    }

    function generateCertificate(
        string memory _id,
        string memory _candidate_name,
        string memory _org_name, 
        string memory _course_name, 
        uint256 _expiration_date) external onlyAdmin {
        bytes32 byte_id = stringToBytes32(_id);
        require(certificates[byte_id].issue_date == 0, "Certificate with given id already exists");
        certificates[byte_id] = Certificate(_candidate_name, _org_name, _course_name, block.timestamp, _expiration_date);
        emit certificateGenerated(byte_id, certificates[byte_id]);
    }

    function getCertificate(string memory _id) public view returns(Certificate memory) {
        bytes32 byte_id = stringToBytes32(_id);
        Certificate memory cert = certificates[byte_id];
        require(cert.issue_date != 0, "Invalid Certificate ID");
        return cert;
    }
}