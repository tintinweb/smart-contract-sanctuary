pragma solidity ^0.4.25;

contract DataStorage {
    
    string[] public datas;
    mapping(uint => bool) public isExist;

    function getCount() public view returns(uint) {
        return datas.length;
    }

    function create(string _property) public {
        uint id = datas.length;
        datas.push(_property);
        isExist[id] = true;
    }

    function remove(uint _id) public {
        require(isExist[_id]);
        isExist[_id] = false;
    }
}