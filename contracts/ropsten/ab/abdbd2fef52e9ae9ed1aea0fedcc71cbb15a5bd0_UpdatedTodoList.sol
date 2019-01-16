pragma solidity ^0.4.25;

// File: contracts/MyValues.sol

contract MyValues {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    mapping(bytes32 => uint) private uintValues;

    function getUint(bytes32 record) public view returns(uint) {
        return uintValues[record];
    }

    function putUint(bytes32 record, uint value) public {
        uintValues[record] = value;
    }

    mapping(bytes32 => string) private stringValues;

    function getString(bytes32 record) public view returns(string) {
        return stringValues[record];
    }

    function putString(bytes32 record, string value) public {
        stringValues[record] = value;
    }
    
    mapping(bytes32 => bool) private boolValues;

    function getBool(bytes32 record) public view returns(bool) {
        return boolValues[record];
    }

    function putBool(bytes32 record, bool value) public {
        boolValues[record] = value;
    }
}

// File: contracts/TodoLibrary.sol

library TodoLibrary {
    string public constant TODO_COUNT = "TodoCount";
    string public constant UNFINISHED_TODO_COUNT = "UnfinishedTodoCount";
    string private constant TODO = "Todo";
    
    function getTodoCount(address storageContract) 
        public
        view
        returns(uint) 
    {
        return MyValues(storageContract).getUint(getKey(TODO_COUNT));
    }
    
    function getTodo(address storageContract, uint id) 
        public 
        view 
        returns(string name, bool done) 
    {
        MyValues values = MyValues(storageContract);
        name = values.getString(getKey(TODO, id));
        done = values.getBool(getKey(TODO, id));
    }
    
    function getUnfinishedTodoCount(address storageContract)
        public
        view
        returns(uint)
    {
        return MyValues(storageContract).getUint(getKey(UNFINISHED_TODO_COUNT));
    }
    
    function addTodo(address storageContract, string todo) public {
        MyValues values = MyValues(storageContract);
        uint id = getTodoCount(storageContract);
        uint unfinished = getUnfinishedTodoCount(storageContract) + 1;
        values.putString(getKey(TODO, id), todo);
        values.putBool(getKey(TODO, id), false);
        values.putUint(getKey(TODO_COUNT), id + 1);
        values.putUint(getKey(UNFINISHED_TODO_COUNT), unfinished);
    }
    
    function finishTodo(address storageContract, uint id) public {
        MyValues values = MyValues(storageContract);
        values.putBool(getKey(TODO, id), true);
        uint unfinished = getUnfinishedTodoCount(storageContract) - 1;
        values.putUint(getKey(UNFINISHED_TODO_COUNT), unfinished);
    }
    
    function getKey(string name) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(name));
    }
    
    function getKey(string name, uint id) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(name, id));
    }
}

// File: contracts/UpdatedTodoList.sol

contract UpdatedTodoList {
    using TodoLibrary for address;
  
    address public _myValues;

    constructor(address myValues) public {
        _myValues = myValues;
    }

    function addTodo(string todo) public {
        _myValues.addTodo(todo);
    }
    
    function getTodosCount() public view returns(uint) {
        return _myValues.getTodoCount();
    }
    
    function getUnfinishedTodoCount() public view returns(uint) {
        return _myValues.getUnfinishedTodoCount();
    }

    function getTodo(uint id) 
        public 
        view 
        returns(string, bool)
    {
        return (_myValues.getTodo(id));
    }

    function finishTodo(uint id) public {
        _myValues.finishTodo(id);
    }

    function kill(address updatedTodoList) public {
        selfdestruct(updatedTodoList);
    }
}