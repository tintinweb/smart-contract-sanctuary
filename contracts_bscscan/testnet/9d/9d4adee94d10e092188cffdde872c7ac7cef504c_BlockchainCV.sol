/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

pragma solidity ^0.4.16;

library Structures {
        /**
    @param First Name Last Name
    @param Headline
    @param Summary
    @param website URL
    @param contact Phone Number
    @param email address
    @param description or additional info
     */
    struct Basics {
        string _name;
        string _title;
        string _summary;
        string _website;
        string _phone;
        string _email;
        string _description;
    }

    struct Position {
        string _company;
        string _position;
        string _startDate;
        string _endDate;
        string _summary;
        string _highlights;
    }

    struct Education {
        string _institution;
        string _focusArea;
        int32 _startYear;
        int32 _finishYear;
    }

    struct Project {
        string name;
        string link;
        string description;
    }

    struct Publication {
        string name;
        string link;
        string language;
    }

    struct Skill {
        string name;
        int32 level;
    }
}

contract BlockchainCV {
    mapping (string => string) Basics;
    address owner;

    Structures.Project[] public projects;
    Structures.Education[] public educations;
    Structures.Skill[] public skills;
    Structures.Publication[] public publications;

    // =====================
    // ==== CONSTRUCTOR ====
    // =====================
    function BlockchainCV() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // =====================
    // ====== ADD NEW ======
    // =====================

    function setBasicData (string key, string value) onlyOwner() {
        Basics[key] = value;
    }

    function editBasicData (string key, string value) onlyOwner() {
        Basics[key] = value;
    }

    function editProject (
        bool operation,
        string name,
        string link,
        string description
    ) onlyOwner() {
        if (operation) {
            projects.push(Structures.Project(name, description, link));
        } else {
            delete projects[projects.length - 1];
        }
    }

    function editEducation (
        bool operation,
        string name,
        string speciality,
        int32 year_start,
        int32 year_finish
    ) onlyOwner() {
        if (operation) {
            educations.push(Structures.Education(name, speciality, year_start, year_finish));
        } else {
            delete educations[educations.length - 1];
        }
    }

    function editSkill(bool operation, string name, int32 level) onlyOwner() {
        if (operation) {
            skills.push(Structures.Skill(name, level));
        } else {
            delete skills[skills.length - 1];
        }
    }

    function editPublication (bool operation, string name, string link, string language) onlyOwner() {
        if (operation) {
            publications.push(Structures.Publication(name, link, language));
        } else {
            delete publications[publications.length - 1];
        }
    }

    // =====================
    // ======= USAGE =======
    // =====================
    function getBasicData (string arg) public constant returns (string) {
        return Basics[arg];
    }

    function getSize(string arg) constant returns (uint) {
        if (keccak256(arg) == keccak256("projects")) { return projects.length; }
        if (keccak256(arg) == keccak256("educations")) { return educations.length; }
        if (keccak256(arg) == keccak256("publications")) { return publications.length; }
        if (keccak256(arg) == keccak256("skills")) { return skills.length; }
        revert();
    }
}