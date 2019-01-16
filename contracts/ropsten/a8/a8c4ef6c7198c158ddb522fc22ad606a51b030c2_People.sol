pragma solidity ^0.4.0;

contract People {
    address owner; 
    struct Person{
        address pAddress;
        string fName;
        string lName;
        string email;
        string age;
        string flightNo;
        string photoID;
        bool exists;
        bool accessed;
        bool onFlight;
        bool exited;
    }
    
    mapping (address => Person) addressPeople;
    address[] public peopleAddresses;
    
    mapping (string => Person) emailPeople;
    

    
    event savePerson(string fName, string lName, string email, string age, string flightNo, string photoID);
    
    modifier onlyOwner(){
        require(
            owner == msg.sender
        );
       _;
    }
    
    constructor() public{
        owner = msg.sender;
    }
    
    function addPerson(address _address, string _fName, string _lName, string _email, string _age,
                        string _flightNo, string _photoID) public {
        Person storage newPerson = addressPeople[_address];
        Person storage nP = emailPeople[_email];

        newPerson.fName = _fName;
        newPerson.lName = _lName;
        newPerson.email = _email;
        newPerson.age = _age;
        newPerson.flightNo = _flightNo;
        newPerson.photoID = _photoID;
        newPerson.exists = true;
        newPerson.accessed = true;
        newPerson.onFlight = false;
        newPerson.exited = false; 
        
        nP.fName = _fName;
        nP.lName = _lName;
        nP.email = _email;
        nP.age = _age;
        nP.flightNo = _flightNo;
        nP.photoID = _photoID;
        nP.exists = true;
        nP.accessed = true;
        nP.onFlight = false; 
        nP.exited = false;
        
        emit savePerson(_fName, _lName, _email, _age, _flightNo, _photoID);
        
        peopleAddresses.push(_address) -1;
    }
    
    function getPeople() view public returns (address[]) {
        return peopleAddresses;
    }
    
    function getPerson(address _address) view public 
                returns (address pAddress, string fName, string lName, string email, string age, string flightNo, string photoID) {
        return (_address, addressPeople[_address].fName, addressPeople[_address].lName, addressPeople[_address].email,
                addressPeople[_address].age, addressPeople[_address].flightNo, addressPeople[_address].photoID);
    }
    
    function getPersonByEmail(string _email) view public 
                returns(address pAddress, string fName, string lName, string age, 
                        string flightNo, string photoID){
        return (emailPeople[_email].pAddress, emailPeople[_email].fName, emailPeople[_email].lName,
                emailPeople[_email].age, emailPeople[_email].flightNo, emailPeople[_email].photoID);
    }
    
    function countPeople() view public returns (uint) {
        return peopleAddresses.length;
    }
    
    function personExists(string _email) view public returns (bool exists){
        return emailPeople[_email].exists;
    }
    
    function setPersonOnFlight(string _email) public{
        emailPeople[_email].onFlight = true;
    }
    
    function personOnFlight(string _email) view public returns(bool onFlight){
        return emailPeople[_email].onFlight;
    }
    
    function recognitionSuccess(string _email) public returns(address){
        emailPeople[_email].onFlight = false;
        emailPeople[_email].exists = false;
        emailPeople[_email].exited = true;
    }
    
    function personExited(string _email) view public returns(bool exited){
        return emailPeople[_email].exited;
    }
    
}