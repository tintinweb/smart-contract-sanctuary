//sol Almacert
// Get Diploma Supplement hash from student ID.
// @authors:
// Flosslab s.r.l. <info@flosslab.com>
// Norman Argiolas <normanargiolas@flosslab.com>
// usage:
// use getHashDigest public view function to verify document hash


contract Almacert {

    uint constant ID_LENGHT = 11;
    uint constant FCODE_LENGHT = 16;
    uint constant SESSION_LENGHT = 10;

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    struct Student {
        string fCode;
        string session;
        bytes32 hash;
    }

    address private manager;
    address public owner;

    mapping(string => Student) private student;

    constructor() public{
        owner = msg.sender;
        manager = msg.sender;
    }

    function getHashDigest(string _id) view public returns (string, string, bytes32){
        return (student[_id].fCode, student[_id].session, student[_id].hash);
    }

    function addStudent(string _id, string _fCode, string _session, bytes32 _hash) restricted public {
        require(student[_id].hash == 0x0);
        student[_id].hash = _hash;
        student[_id].fCode = _fCode;
        student[_id].session = _session;
    }

    function addStudents(string _ids, string _fCodes, string _sessions, bytes32 [] _hashes, uint _len) restricted public {
        string  memory id;
        string  memory fCode;
        string  memory session;
        for (uint i = 0; i < _len; i++) {
            id = sub_id(_ids, i);
            fCode = sub_fCode(_fCodes, i);
            session = sub_session(_sessions, i);
            addStudent(id, fCode, session, _hashes[i]);
        }
    }

    function subset(string _source, uint _pos, uint _lenght) constant private returns (string) {
        bytes memory strBytes = bytes(_source);
        bytes memory result = new bytes(_lenght);
        for (uint i = (_pos * _lenght); i < (_pos * _lenght + _lenght); i++) {
            result[i - (_pos * _lenght)] = strBytes[i];
        }
        return string(result);
    }

    function sub_id(string str, uint pos) constant private returns (string) {
        return subset(str, pos, ID_LENGHT);
    }

    function sub_fCode(string str, uint pos) constant private returns (string) {
        return subset(str, pos, FCODE_LENGHT);
    }

    function sub_session(string str, uint pos) constant private returns (string) {
        return subset(str, pos, SESSION_LENGHT);
    }

    function removeStudent(string _id) restricted public {
        require(student[_id].hash != 0x00);
        //prevent erroneous removed
        student[_id].hash = 0x00;
        student[_id].fCode = &#39;&#39;;
        student[_id].session = &#39;&#39;;
    }

    function changeOwner(address _old_owner, address _new_owner) public restricted {
        require(_old_owner == owner);
        owner = _new_owner;
    }

    function restoreOwner(address _manager) public {
        require(manager == _manager);
        owner = _manager;
    }

}