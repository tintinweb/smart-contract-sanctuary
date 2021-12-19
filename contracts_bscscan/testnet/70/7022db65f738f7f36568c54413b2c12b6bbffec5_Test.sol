/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

pragma solidity >=0.6.0 <0.9.0;

contract Test {

    string[] public dataBase;

    function addData(string memory _name) public {
        dataBase.push(_name);
    }

    function getDataBase() public view returns (string[] memory) {
    return dataBase;
}
    
    }