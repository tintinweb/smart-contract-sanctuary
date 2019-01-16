pragma solidity ^0.4.25;

contract TestContract {

    string[] data;

    function pushData(string d) public {
        data.push(d);
    }
    
    function getData(uint i) public view returns (string) {
        return data[i];
    }

}