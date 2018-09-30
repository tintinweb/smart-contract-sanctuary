pragma solidity ^0.4.25;

contract FileManagement {
    
    string[] public files;
    mapping(uint => bool) public isExist;

    function getFilesCount() public view returns(uint) {
        return files.length;
    }

    function create(uint _id, string _name) public {
        files[_id] = _name;
        isExist[_id] = true;
    }

    function remove(uint _id) public {
        require(isExist[_id]);
        isExist[_id] = false;
    }
}