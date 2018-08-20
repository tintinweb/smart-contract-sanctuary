pragma solidity ^0.4.24;

contract PersonToken {
    
    struct Person {
        string name;
        string coursesTeached;
        uint totalHoursAsVolunteer;
        uint totalHoursAsTutor;
        uint averageReviewGrade;
    }
    
    Person[] public persons;
    mapping(uint => bool) public isExist;

    function getPersonsCount() public view returns(uint) {
        return persons.length;
    }

    function createPerson(
        string _name, 
        string _coursesTeached, 
        uint _totalHoursAsVolunteer,
        uint _totalHoursAsTutor,
        uint _averageReviewGrade) 
        public 
    {
        uint id = persons.length;
        persons.push(Person(_name, _coursesTeached, _totalHoursAsVolunteer, _totalHoursAsTutor, _averageReviewGrade));
        isExist[id] = true;
    }

    function deletePerson(uint _id) public {
        require(isExist[_id]);
        isExist[_id] = true;
    }
}