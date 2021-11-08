/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT  

pragma solidity >=0.6.0 <0.9.0;

contract SimpleStorage {
    
    //These are examples of variables used in Solidity, for more info see the Course Github
    
    // If variables are not assigned a value, then they will have the NULL value of their type, (e.g. unint256 >> 0)
    uint256 number = 5;
    bool exampleBool = true;
    string exampleString = "These are example variables";
    int256 number2 = -5;
    address TestAccount = 0xCaCF7158b6ACc427aAB327A1e6901743826F8F99;
    bytes32 BytesObj = "Cat"; // This is something that is converted in a bytes object
    
    /*
    The public keyword is used to set the visibility of a variable or function,
    
    there are currently 4 types of visibility in Solidity:
        -External
        -Public
        -Internal
        -Private
        
    The default is internal
        
    See the Solidity documentation for more information
    */
    
    
    uint256 StoreNum;
    
    
    //Struct is a way to define a new type of object in Solidity, like a class in Python I guess...
    struct People{
        uint256 Number;
        string Name;
    }
    
    //Arrays are a way of storing a list or group of objects
    // Dynamic arrays can change is  size, fixed arrays cannot change in size
    
    //Fixed example: People[1] public people;, only 1 Object can be in this array
    //Dynamic
    People[] public people;
    
    //Mappings are a data structure that is used to map/search things?, it is like a dictionary
    mapping(string => uint256) public nameToNum;
    
    
    
    function addPerson(string memory _name, uint256 _num) public{
        
        // A string is actaully an array object of bytes which means that has to be stored if used as a function parameter
        
        /*
        Storing stuff:
        memory >> store it during the execution of the function
        storage >> data will persist even after function execution
        */
        
        //To add something to your array use [array name].push([Thing to add])
        people.push(People( _num, _name));
        nameToNum[_name] = _num;
        
    }
    
    
    function Store(uint256 _num) public{
        StoreNum = _num;
    }
    
    //view and pure are non-state changeing funtion calls, view just reads something
    //pure functions only do some type of math, ...
    function retrieve() public view returns(uint256){
        return StoreNum;
    }
    
    
}