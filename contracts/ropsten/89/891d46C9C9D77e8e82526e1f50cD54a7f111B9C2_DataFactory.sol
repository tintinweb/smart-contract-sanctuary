pragma solidity ^0.8.4;

contract DataFactory{
    struct Data{
        string name;
        uint value;
    }

    Data public data;

    function createData(string memory _name, uint _value) public{
        data = Data(_name, _value);
    }

}

