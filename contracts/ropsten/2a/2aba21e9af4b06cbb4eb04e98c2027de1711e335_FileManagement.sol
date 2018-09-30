pragma solidity ^0.4.25;

contract FileManagement {
    
    string[] public files;
    mapping(uint => bool) public isExist;

    function getFilesCount() public view returns(uint) {
        return files.length;
    }

    function create(string _name) public {
        uint id = files.length;
        files.push(_name);
        isExist[id] = true;
    }

    function remove(uint _id) public {
        require(isExist[_id]);
        isExist[_id] = false;
    }
}