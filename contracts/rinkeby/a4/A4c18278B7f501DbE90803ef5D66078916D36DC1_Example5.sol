/**
 *Submitted for verification at Etherscan.io on 2021-08-06
*/

//  - address
//  - boolean
//  - string
//  - bytes32
//  - bytes
//  - uint256
//  - enum
//  - struct
//  - mapping
//  - array

pragma solidity 0.8.4;

contract Example5 {
    
    address payable public receiverAddress = payable(0xb2361c55721DA1D13ce0F4955aB2a072162aA3B1);
    string public testMessage;
    bytes32 public hash;
    bytes1 public testBytes;
    
    enum TestEnum { TypeOne, TypeTwo }
    
    struct User {
        string name;
        uint256 age;
        string email;
    }
    
    mapping (address => User) public users;
    
    address[] public usersArray;
    
    function forwardEther() public payable {
        receiverAddress.send(msg.value);
        // receiverAddress.transfer(msg.value/3);
        // receiverAddress.call{value: msg.value/3}("");
    }
    
    function setTestMessage(string memory _testMessage) public {
        require(keccak256(abi.encodePacked((testMessage))) != keccak256(abi.encodePacked((_testMessage))), "Strings must not be equal");
        testMessage = _testMessage;
    }
    
    function setTestBytes32(bytes32 _hash) public {
        require(hash != _hash, "Bytes must not be equal");
        hash = _hash;
    }
    
    function setTestBytes(bytes1 _bytes) public {
        testBytes = _bytes;
    }
    
    function addUser(address _user, string memory _name, uint256 _age, string memory _email) public returns(User memory) {
        users[_user] = User(_name, _age, _email);
        usersArray.push(_user);
        // users[_user].name = _name;
        // users[_user].age = _age;
    }
    
}