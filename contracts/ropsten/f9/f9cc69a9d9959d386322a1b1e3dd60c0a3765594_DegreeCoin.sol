/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: GPL-3.0
/*
 * DegreeCoin       - A decentralized Degree equivalency tool.
 * Deployer Address - 0xced587906F10A90921235aBC2470b646ae464AaC
 * Deployed Network - Ropsten Test Network
 *
 * Limitation
 * - This application can handle:
 * -- Upto 2^64 different degrees for each Student.
 * -- Upto 2^64 Global equivalency Courses.
 * -- Upto 2^64 different courses for each university.
 * -- This limitation comes because of 25 Kilobytes contract size limit of Ethereum network.
 * --- For the same reason, Voting logic is also stripped.
 */
pragma solidity >=0.7.0 <0.9.0;

contract DegreeCoin {
    
    /*
     * Template of a course used for global standardization, each course of a university will map to one of these templates.
     * Universities can decide whether to trust a template or not (blacklist).
     * However, if they are mapping their degree to a template, then they are automatically trusting that template.
     * 
     * @prop name               - Name of the course.
     * @prop description        - Description of what this standardization is about and exact content this covers.
     * @prop duration           - Number of months it takes to complete.
     */
    struct CourseTemplate {
        string name;
        string description;
        uint8 duration;
    }

    /*
     * Course a university is offering. Considering different language and different education standards.
     * Each of these courses will map to one template which will be the equivalency of that course globally.
     * 
     * @prop name        - Name of the course.
     * @prop description - Information on what is offered in this course.
     * @prop duration    - Number of months it takes to complete the course.
     * @prop equivalency - Equivalen standardized courseTemplate to this course.
     */
    struct Course {
        string name;
        string description;
        uint8 duration;
        uint64 equivalency;
    }
    
    /*
     * Degree which is issued to a student by the university.
     * Each of these degrees are unique and thus can be considered as an NFT.
     * This will contain the information about performance of the student and related comments.
     * 
     * @prop issuer   - Address of the issuing university.
     * @prop cgpa     - CGPA of the student (from 00.00/0000 to 10.00/1000).
     * @prop grade    - Grade of student written in words. (For example, "First Class with Distinction").
     * @prop issuedAt - UNIX Timestamp (seconds) when the degree was issued.
     * @prop courseID - Reference to the ID of the course for which this degree is issued.
     * @prop comments - Additional comments that can be added while issuing the degree. (For example, "Exceptional Work").
     */
    struct Degree {
        address issuer;
        uint16 cgpa;
        string grade;
        uint64 issuedAt;
        uint64 courseID;
        string comments;
    }

    /*
     * Profile of each Student.
     * 
     * @prop degreeCount - Total number of degrees held by a student. [Additional Feature, for storing metadata].
     * @prop degrees     - List of refences to each of the individual degree issued to that student.
     */
    struct Student {
        uint64 degreeCount;
        Degree[] degrees;
    }

    /*
     * Profile of each University.
     * 
     * @prop name                       - Name of the university. (It is not mandatory to have, provided we can be pseudo-anonymous)
     * @prop invitedBy                  - The address of university which invited this university.
     * @prop establishedAt              - UNIX Timestamp (seconds) when the university was established. (Added to this application)
     * @prop blacklistedUniversities    - List of universities that are blacklisted.
     * @prop blacklistedCourseTemplates - List of courseTemplates whose equivalency is not considered valid.
     * @prop courses                    - List of courses offered.
     */
    struct University {
        string name;
        address invitedBy;
        uint64 establishedAt;
        address[] blacklistedUniversities; 
        uint64[] blacklistedCourseTemplates;
        Course[] courses;
    }

    /*
     * List of available students and universities on the application.
     * This is mapped with the address of the account holder.
     * Each array maps to a struct defining the data structure of that Student/University.
     */
    mapping (address => Student) private students;
    mapping (address => University) private universities;

    /*
     * List of available courseTemplates on the application.
     */
    CourseTemplate[] private courseTemplates;

    /*
     * Some statistics of the application. (Number of Degrees issued, Number of universities registered, Number of Students registered)
     * This data does not add any useful functionality but helps to get a broad picture of usage of this contract.
     * Even though these counters are public, they can only be read publicly. They cannot be overwritten by any public method.
     * They can only be overwritten from within this contract where it should update.
     */
    uint256 public issuedDegreeCount;
    uint256 public universityCount;
    uint256 public studentCount;

    uint8 public constant ACCOUNT_TYPE_UNIVERSITY = 101;
    uint8 public constant ACCOUNT_TYPE_STUDENT    = 102;

    //Address of the contract owner. This is initialized when the contract is deployed.
    address public owner;

    /*
     * Constructor of the Contract. This is executed only once.
     * The deployer of the contract is set as the ownser who is the first university in the network.
     * The owner also has a superpower to create courseTemplate.
     * This might create a trust requirement for the owner to be honest, but the owner can be a multi-sig wallet.
     * Using a multi-sig wallet will reduce the fear of the owner maliciously changing anything. As majority has to agree for a change.
     * Deployer address written in the top comment should match with the owner in order to verify that this is the genuine copy of contract.
     *
     * @param _name - Name of the contract owner
     */
    constructor(string memory _name) {
        owner = msg.sender;
        University storage university = universities[owner];
        university.name = _name;
        university.invitedBy = address(this);
        university.establishedAt = uint64(block.timestamp);
        incrementUniversityCount();
    }

    /*
     * Invite a university for registration on the application.
     * 
     * @param university - Address of the university to be invited.
     * @return address   - Address of the university which has been invited.
     * @validation 
     * - The inviter should be a valid university.
     * - The invited university should not be already Registered.
     */
    function inviteUniversity(address university) onlyUniversity() external returns(address) {
        require(universities[university].establishedAt == 0, "University already registered");
        universities[university].invitedBy = msg.sender;

        return university;

    }

    /*
     * Register a University on the application which already has an invitation.
     * 
     * @param _name    - Name of the University.
     * @return address - Address of the university which has been registered.
     * @validation 
     * - The university should not be already registered.
     * - The address should not belong to a student.
     * - The university needs to be invited by another valid university before attempting registration.
     */
    function registerUniversity(string calldata _name) external returns(address) {
        require(!isValidUniversity(), "The university is already registered");
        require(students[msg.sender].degreeCount == 0, "The Address is of a student, cannot register as a University");
        address invitedBy = universities[msg.sender].invitedBy;
        require(address(invitedBy) != address(0), "Only invited universities can be registered");
        require(isValidUniversity(invitedBy), "The invitation is invalid, please re-request invitation");

        universities[msg.sender].name = _name;
        universities[msg.sender].establishedAt = uint64(block.timestamp);

        incrementUniversityCount();
        return msg.sender;
    }

    /*
     * Update name of a university.
     * 
     * @param _name   - Name of the University.
     * @return string - Updated name of the University.
     * @validation
     * - Only registered universities can update their name.
     */
    function updateUniversityName(string calldata _name) onlyUniversity() external returns(string calldata) {
        universities[msg.sender].name = _name;
        return _name;
    }

    /*
     * Add a blacklisted university to the list.
     * 
     * @param blacklistedUniversity - Address of the University.
     * @return address[]            - Updated list of blacklisted Universities.
     * @validation
     * - The university needs to be registered.
     * - The number of blacklists added has to be less than 2^64.
     */
    function addBlacklistedUniversity(address blacklistedUniversity) onlyUniversity() external returns(address[] memory) {
        require(universities[msg.sender].blacklistedUniversities.length <= uint256(2**64), "Maximum number of blacklisted universities reached");
        if(!isBlacklistedUniversity(blacklistedUniversity)) {
            universities[msg.sender].blacklistedUniversities.push(blacklistedUniversity);
        }
        return universities[msg.sender].blacklistedUniversities;
    }

    /*
     * Remove a blacklisted university from the list.
     * 
     * @param blacklistedUniversity - Address of the University.
     * @return address[]            - Updated list of blacklisted Universities.
     * @validation
     * - The university needs to be registered.
     * - The university to be removed needs to be in the blacklist.
     */
    function removeBlacklistedUniversity(address blacklistedUniversity) onlyUniversity() external returns(address[] memory) {
        int blacklistedUniversityIndex = getBlacklistedUniversityIndex(blacklistedUniversity);
        require(blacklistedUniversityIndex >= 0, "University is not in Blacklist");

        //Oh Daamn! Naming like Java Classes, lol
        universities[msg.sender].blacklistedUniversities[uint256(blacklistedUniversityIndex)] = universities[msg.sender].blacklistedUniversities[universities[msg.sender].blacklistedUniversities.length - 1];
        universities[msg.sender].blacklistedUniversities.pop();

        return universities[msg.sender].blacklistedUniversities;
    }

    /*
     * Check whether the university is blacklisted or not.
     * 
     * @param university - Address of the University.
     * @return bool      - Whether the university is blacklisted or not.
     */
    function isBlacklistedUniversity(address university) public view returns(bool) {
        if(getBlacklistedUniversityIndex(university) >= 0) {
            return true;
        }
        return false;
    }

    /*
     * Get index of the blacklisted university.
     * This is a private method, that means it can only be called from within this Contract.
     * 
     * @param university - Address of the University.
     * @return int       - Index of the blacklisted university, -1 if not found.
     */
    function getBlacklistedUniversityIndex(address university) private view returns(int) {
        address[] memory blacklistedUniversities = universities[msg.sender].blacklistedUniversities;
        for (uint256 i=0; i<blacklistedUniversities.length; i++) {
            if(blacklistedUniversities[i] == university) {
                return int(i);
            }
        }
        return -1;
    }

    /*
     * Add a blacklisted courseTemplate  to the list.
     * 
     * @param courseTemplateID - ID of the courseTemplate.
     * @return uint64[]       - Updated list of blacklisted courseTemplates.
     * @validation
     * - The university needs to be registered.
     * - Upto 2^64 blacklisted courses can be added.
     */
    function addBlacklistedCourseTemplate(uint64 courseTemplateID) onlyUniversity() external returns(uint64[] memory) {
        require(universities[msg.sender].blacklistedCourseTemplates.length < uint256(2**64), "Upto 2^64 blacklisted courses can be added");
        if(!isBlacklistedCourseTemplate(courseTemplateID)) {
            universities[msg.sender].blacklistedCourseTemplates.push(courseTemplateID);
        }
        return universities[msg.sender].blacklistedCourseTemplates;
    }

    /*
     * Remove a blacklisted courseTemplate from the list.
     * 
     * @param courseTemplateID - ID of the courseTemplate.
     * @return uint64[]        - Updated list of blacklisted courseTemplates.
     * @validation
     * - The university needs to be registered.
     * - The courseTemplate to be removed needs to be in the blacklist.
     */
    function removeBlacklistedCourseTemplate(uint64 courseTemplateID) onlyUniversity() external returns(uint64[] memory) {
        int blacklistedCourseTemplateIndex = getBlacklistedCourseTemplateIndex(courseTemplateID);
        require(blacklistedCourseTemplateIndex >= 0, "Course Template is not blacklisted");

        //Another one.
        universities[msg.sender].blacklistedCourseTemplates[uint256(blacklistedCourseTemplateIndex)] = universities[msg.sender].blacklistedCourseTemplates[universities[msg.sender].blacklistedCourseTemplates.length - 1];
        universities[msg.sender].blacklistedCourseTemplates.pop();

        return universities[msg.sender].blacklistedCourseTemplates;
    }

    /*
     * Check whether the courseTemplate is blacklisted or not.
     * 
     * @param courseTemplateID - ID of the courseTemplate.
     * @return bool            - Whether the courseTemplate is blacklisted or not.
     */
    function isBlacklistedCourseTemplate(uint64 courseTemplateID) public view returns(bool) {
        if(getBlacklistedCourseTemplateIndex(courseTemplateID) >= 0) {
            return true;
        }
        return false;
    }

    /*
     * Get index of the blacklisted courseTemplate.
     * This is a private method, that means it can only be called from within this Contract.
     * 
     * @param courseTemplateID  - ID of the courseTemplate.
     * @return int              - Index of the blacklisted courseTemplate, -1 if not found.
     */
    function getBlacklistedCourseTemplateIndex(uint64 courseTemplateID) private view returns(int64) {
        uint64[] memory blacklistedCourseTemplates = universities[msg.sender].blacklistedCourseTemplates;
        for (uint64 i=0; i<blacklistedCourseTemplates.length; i++) {
            if(blacklistedCourseTemplates[i] == courseTemplateID) {
                return int64(i);
            }
        }
        return -1;
    }
    
    /*
     * Get list of blacklisted courseTemplates of a university.
     * This can only be called from inside this contract.
     * 
     * @return uint64[] - List of blacklisted courseTemplate indices (Global)
     */
    function getBlacklistedCourseTemplates() view private returns(uint64[] memory) {
        return universities[msg.sender].blacklistedCourseTemplates;
    }

    /*
     * Register course by a university. The course needs to be mapped to a valid non blacklisted equivalent courseTemplate.
     *
     * @param name        - Name of the course.
     * @param description - Description of the content offered in the course.
     * @param duration    - Duration of course in months.
     * @param equivalency - Global identifier of equivalent courseTemplate.
     * @return string     - Name of the course registered.
     * @validation
     * - Upto 2^64 courses can be registered by a university.
     * - Issuing university should be a valid university.
     * - Name of the course cannot be empty.
     * - Duration of the course cannot be 0.
     * - Equivalency needs to map to a valid courseTemplate.
     * - Equivalent courseTemplate should not be blacklisted.
     */
    function registerCourse(string calldata name, string calldata description, uint8 duration, uint64 equivalency) onlyUniversity() external returns(string calldata) {
        require(universities[msg.sender].courses.length < uint256(2**64), "Maximum number of registered courses reached");
        require(bytes(name).length > 0, "Course name cannot be empty");
        require(duration > 0, "Duration of course should be more than 0");
        require(equivalency < courseTemplates.length, "The equivalentCourseTemplate is not valid");
        require(!isBlacklistedCourseTemplate(equivalency), "The equivalent courseTemplate cannot be blacklisted");
        
        Course memory course = Course(name, description, duration, equivalency);
        universities[msg.sender].courses.push(course);
        return name;
    }

    /*
     * Issue degree to a Student.
     * 
     * @param studentAddr - Address of the Student whom to issue the degree.
     * @param courseID    - ID of the course for which the degree is being issued.
     * @param cgpa        - CGPA marks being awarded.
     * @param grade       - Grade being awarded.
     * @param comments    - Any additional comments if needed to be added to the degree.
     * @return bool       - True, only if the issuance was successful.
     * @validation
     * - University should be registered.
     * - Cannot issue degree to a university.
     * - CGPA can only be between 0000 and 1000 (both included).
     * - Grade is Required.
     * - Issuing degree should have an equivalency connected.
     */
    function issueDegree(address studentAddr, uint64 courseID, uint16 cgpa, string memory grade, string memory comments) onlyUniversity() external returns(bool) {
        require(bytes(grade).length > 0, "Grade text is mandatory");
        require(((cgpa >= 0) && (cgpa <= 1000)), "CGPA has to be between 0000 and 1000");
        require(address(universities[studentAddr].invitedBy) == address(0), "Cannot issue degree to a university");

        University memory university = universities[msg.sender];
        require(university.courses[courseID].duration != 0, "CourseID should be valid");
        require(courseTemplates[university.courses[courseID].equivalency].duration != 0, "The degree is not valid, it should have some equivalency");

        uint64 issuedAt = uint64(block.timestamp);
        Degree memory degree = Degree(msg.sender, cgpa, grade, issuedAt, courseID, comments);
        Student storage student = students[studentAddr];

        student.degrees.push(degree);      
        student.degreeCount++;

        incrementIssuedDegreeCount();
        if(student.degreeCount == 1) {
            incrementStudentCount();
        }

        return true;
    }

    /*
     * This will create a courseTemplate.
     * This can only be executed by owner of this contract.
     *
     * @param name        - Name of the courseTemplate standardized course.
     * @param description - Description of the Course.
     * @param duration    - Duration of the course in months
     * @validation
     * - Can be executed only by the contract owner.
     * - Name cannot be empty.
     * - Duration of the course cannot be zero.
     */
    function createCourseTemplate(string calldata _name, string calldata _description, uint8 _duration) onlyOwner() external returns(CourseTemplate memory _courseTemplate) {
        require(bytes(_name).length > 0, "CourseTemplate Name cannot be empty");
        require(_duration > 0, "Duration of course cannot be zero");

        _courseTemplate = CourseTemplate(_name, _description, _duration);
        courseTemplates.push(_courseTemplate);
    }

    /*
     * Increments the total number of degrees issued over time by 1.
     * Can only be called from within this contract.
     */
    function incrementIssuedDegreeCount() private {
        issuedDegreeCount++;
    }

    /*
     * Increments the total number of registered universities on the application by 1.
     * This can only be called from within this contract.
     */
    function incrementUniversityCount() private {
        universityCount++;
    }

    /*
     * Increments the total number of registered students on the application by 1.
     * This can only be called from within this contract.
     */
    function incrementStudentCount() private {
        studentCount++;
    }

    /*
     * Get the type of account currently connected to the application.
     * 
     * @return uint8 - 101 for University and 102 for Student.
     */
    function getAccountType() public view returns(uint8) {
        if(address(universities[msg.sender].invitedBy) != address(0)) {
            return ACCOUNT_TYPE_UNIVERSITY;
        }
        return ACCOUNT_TYPE_STUDENT;
    }

    /*
     * Return all information about the current Student Account.
     *
     * @return Student  - Object of the Student profile.     
     */
    function getDetailsStudent() external view returns(Student memory) {
        return getDetailsStudent(msg.sender);
    }

    /*
     * Return all information about the requested Student Account.
     *
     * @param student   - Address of the Student whose account needs to be fetched.
     * @return Student  - Object of the student Profile  
     */
    function getDetailsStudent(address student) public view returns(Student memory) {
        return students[student];
    }

    /*
     * Return all information about the current University Account.
     *
     * @return University - Object of the Requested university
     * @validations
     * - The current university needs to be registered.
     */
    function getDetailsUniversity() external view returns(University memory) {
        return getDetailsUniversity(msg.sender);
    }

    /*
     * Return all information about the requested University Account.
     *
     * @param university  - Address of the University whose account needs to be fetched.
     * @return University - Object of the University Profile.  
     */
    function getDetailsUniversity(address university) public view returns(University memory) {
        return universities[university];
    }

    /*
     * Check whether the sender of the message is a valid university or not.
     * This function can only be called from within this contract.
     * 
     * @return bool - Whether the current sender is a valid university or not.
     */
    function isValidUniversity() private view returns(bool) {
        return isValidUniversity(msg.sender);
    }

    /*
     * Check whether the university is valid or not.
     * This function can only be called from within this contract.
     * 
     * @param university - Address of the university to be checked.
     * @return bool      - Whether the university is valid or not.
     */
    function isValidUniversity(address university) private view returns(bool) {
        if(universities[university].establishedAt > 0) {
            return true;
        }
        return false;
    }

    /*
     * Check whether the universite is an invited university or not.
     *
     *  @return bool - Whether the university is invited or not.
     */
    function isInvitedUniversity() external view returns(bool) {
        if(address(universities[msg.sender].invitedBy) != address(0)) {
            return true;
        }
        return false;
    }

    /*
     * Get valid courseTemplates which a university can map to.
     * This is on a per university basis as this also considers blacklisted coursetemplates.
     * The returned list is all courseTemplate (minus) blacklistedCourseTemplates.
     *
     * @return CourseTemplate[] - List of valid courseTemplates which can be used by the university.
    */
    function getValidCourseTemplates() external view returns(CourseTemplate[] memory _courseTemplates) {
        _courseTemplates = courseTemplates;
        uint64[] memory _blacklistedCourseTemplateIDs = getBlacklistedCourseTemplates();

        for (uint64 i=1; i < _blacklistedCourseTemplateIDs.length; i++) {
            _courseTemplates[_blacklistedCourseTemplateIDs[i]] = CourseTemplate("", "", 0);
        }
    }

    /*
     * Get all Course Templates. This does not care about any blacklist.
     *
     * @return CourseTemplate[] - Array of all the CourseTemplates on the application.
     */
    function getCourseTemplates() external view returns(CourseTemplate[] memory _courseTemplates) {
        _courseTemplates = courseTemplates;
    }

    /*
     * Get a single Course Template.
     *
     * @param courseTemplateID - Index of the CourseTemplate
     * @return CourseTemplate  - Single Course Template
     * @validation
     * - The courseTemplate ID should be valid
     */
    function getCourseTemplate(uint64 courseTemplateID) external view returns(CourseTemplate memory _courseTemplate) {
        require(courseTemplateID < courseTemplates.length, "The courseTemplateID is invalid");
        _courseTemplate = courseTemplates[courseTemplateID];
    }


    /*
     * Access Modifier which can be used to keep the code simple and clean.
     * Helps remove repeated require checks for whether the user is a university or not.   
     */
    modifier onlyUniversity(){
        require(isValidUniversity(), "Unauthorized, not a registered University");
        _;
    }

    /*
     * Access Modifier which to check whether the user is owner or not.
     * This is checked before executing any transaction with owner superpower.
     */
    modifier onlyOwner(){
        require(msg.sender == owner, "Not owner, unauthorized");
        _;
    }

    /* END OF CONTRACT */
}