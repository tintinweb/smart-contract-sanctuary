pragma solidity ^0.4.24;

contract DataContract {
    
    struct Data {
        string name;
        string rxName;
        string bloodPressure;
    }
    
    Data[] public datas;
    mapping(uint => bool) public isExist;

    function getDatasCount() public view returns(uint) {
        return datas.length;
    }

    function createData(string _name, string _rxName, string _bloodPressure) public {
        uint id = datas.length;
        datas.push(Data(_name, _rxName, _bloodPressure));
        isExist[id] = true;
    }

    function deleteData(uint _id) public {
        require(isExist[_id]);
        isExist[_id] = false;
    }
}