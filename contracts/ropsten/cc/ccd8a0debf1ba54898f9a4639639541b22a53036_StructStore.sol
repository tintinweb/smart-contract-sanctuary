/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

pragma solidity 0.4.24;

contract StructStore {
    mapping(uint256 => User) users;

    struct User {
        uint256 id;
        //other attributes
        string[] data;
    }

    // Create a new user.
    function newUser(uint256 _id) public {
        // In a mapping, all elements are defined. They're just empty by default
        // So, just setting the id will create a new user;
        users[_id].id = _id;
    }

    // Pushed a piece of data to a user
    function addData(uint256 _id, string _data) public {
        users[_id].data.push(_data);
    }

    // Sets a piece of data by index
    function setData(uint256 _id, uint256 _index, string _newData) public {
        users[_id].data[_index] = _newData;
    }

    // Solidity can't return string arrays. So we'll have to provide the _dataIndex
    // Of the piece of data we want
    function getUserData(uint256 _id, uint256 _dataIndex) public view returns (string) {
        return users[_id].data[_dataIndex];
    }

    // Returns the amount of strings in a User's data array
    function getDataSize(uint256 _id) public view returns (uint256) {
        return users[_id].data.length;        
    }
}