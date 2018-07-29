pragma solidity ^0.4.24;

// Almacert v.1.0.8
// Universita&#39; degli Studi di Cagliari
// http://www.unica.it
// @authors:
// Flosslab s.r.l. <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d1b8bfb7be91b7bdbea2a2bdb0b3ffb2bebc">[email&#160;protected]</a>>

contract Almacert {

    uint constant ID_LENGTH = 11;
    uint constant FCODE_LENGTH = 16;
    uint constant SESSION_LENGTH = 10;

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    modifier restrictedToManager() {
        require(msg.sender == manager);
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

    function subset(string _source, uint _pos, uint _LENGTH) pure private returns (string) {
        bytes memory strBytes = bytes(_source);
        bytes memory result = new bytes(_LENGTH);
        for (uint i = (_pos * _LENGTH); i < (_pos * _LENGTH + _LENGTH); i++) {
            result[i - (_pos * _LENGTH)] = strBytes[i];
        }
        return string(result);
    }

    function sub_id(string str, uint pos) pure private returns (string) {
        return subset(str, pos, ID_LENGTH);
    }

    function sub_fCode(string str, uint pos) pure private returns (string) {
        return subset(str, pos, FCODE_LENGTH);
    }

    function sub_session(string str, uint pos) pure private returns (string) {
        return subset(str, pos, SESSION_LENGTH);
    }

    function removeStudent(string _id) restricted public {
        require(student[_id].hash != 0x00);
        student[_id].hash = 0x00;
        student[_id].fCode = &#39;&#39;;
        student[_id].session = &#39;&#39;;
    }

    function changeOwner(address _new_owner) restricted public{
        owner = _new_owner;
    }

    function restoreOwner() restrictedToManager public {
        owner = manager;
    }

}