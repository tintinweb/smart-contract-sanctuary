pragma solidity ^0.4.0;


contract TodoList
{
    struct Todo
    {
        string hash;
    }
    
    mapping (address => Todo) GetList;
    
    function addHash(string _s) public {
        GetList[msg.sender].hash = _s;
    }
    
    function addHash() public view returns(string){
        return GetList[msg.sender].hash;
    }

}