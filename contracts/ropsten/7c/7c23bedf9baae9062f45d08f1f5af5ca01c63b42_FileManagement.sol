pragma solidity ^0.4.25;

contract FileManagement {
    
    mapping(uint => string) public files;
    mapping(uint => bool) public isExist;
    uint[] public ids;

    function getFilesCount() public view returns(uint) {
        return ids.length;
    }

    function add(uint _id, string _name) public {
        files[_id] = _name;
        isExist[_id] = true;
        ids.push(_id);
    }

    function remove(uint _id) public {
        require(isExist[_id]);
        isExist[_id] = false;
    }
}