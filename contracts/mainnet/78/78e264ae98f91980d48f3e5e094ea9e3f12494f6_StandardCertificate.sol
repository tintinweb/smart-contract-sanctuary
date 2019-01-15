pragma solidity ^0.4.11;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract StandardCertificate is owned{
    
    string public name;
    string public description;
    string public language;
    string public place;
    uint public hoursCount;
    
    mapping (address => uint) certificates;
    
    function StandardCertificate (string _name, string _description, string _language, string _place, uint _hoursCount) {
        name = _name;
        description = _description;
        language = _language;
        place = _place;
        hoursCount = _hoursCount;
    }
    
    // выдача сертификата
    function issue (address student) onlyOwner {
        certificates[student] = now;
    }
    
    function issued (address student)  constant returns (uint) {
        return certificates[student];
    }
    
    function annul (address student) onlyOwner {
        certificates[student] = 0;
    }
    
}

contract EWCertificationCenter is owned {
    
    string public name;
    string public description;
    string public place;
    
    mapping (address => bool) public validCertificators;
    
    mapping (address => bool) public validCourses;
    
    modifier onlyValidCertificator {
        require(validCertificators[msg.sender]);
        _;
    }

    
    function EWCertificationCenter (string _name, string _description, string _place) {
    
        name = _name;
        description = _description;
        place = _place;
        validCertificators[msg.sender]=true;
        
    }
    
    // add and delete certificator 
    function addCertificator(address newCertificator) onlyOwner {
        validCertificators[newCertificator] = true;
    }
    
    function deleteCertificator(address certificator) onlyOwner {
        validCertificators[certificator] = false;
    }
    
    // add and delete cource certificate
    function addCourse(address courseAddess) onlyOwner {
        StandardCertificate s = StandardCertificate(courseAddess);
        validCourses[courseAddess] = true;
    }

    function deleteCourse(address courseAddess) onlyOwner {
        validCourses[courseAddess] = false;
    }
    
    function issueSertificate(address courseAddess, address student) onlyValidCertificator {
        require (student != 0x0);
        require (validCourses[courseAddess]);
        
        StandardCertificate s = StandardCertificate(courseAddess);
        s.issue(student);
    }
    
    function checkSertificate(address courseAddess, address student) constant returns (uint) {
        require (student != 0x0);
        require (validCourses[courseAddess]);
        
        StandardCertificate s = StandardCertificate(courseAddess);
        return s.issued(student);        
    }
    
    function annulCertificate(address courseAddess, address student) onlyValidCertificator {
        require (student != 0x0);
        require (validCourses[courseAddess]);

        StandardCertificate s = StandardCertificate(courseAddess);
        s.annul(student);
    }
    
    function changeOwnership(address certificateAddress, address newOwner) onlyOwner {
        StandardCertificate s = StandardCertificate(certificateAddress);
        s.transferOwnership(newOwner);
    }
    
}