pragma solidity ^0.4.0;

contract EthProfile{
    mapping(address=>string) public name;
    mapping(address=>string) public description;
    mapping(address=>string) public contact;
    mapping(address=>string) public imageAddress;

    constructor() public{
    }
    
    event Success(string status, address sender);

    function updateName(string newName) public{
        require(bytes(newName).length <256);
        name[msg.sender] = newName;
        emit Success(&#39;Name Updated&#39;,msg.sender);
    }
    
    function updateDescription(string newDescription) public{
        require(bytes(newDescription).length <256);
        description[msg.sender] = newDescription;
        emit Success(&#39;Description Updated&#39;,msg.sender);
    }
    
    function updateContact(string newContact) public{
        require(bytes(newContact).length < 256);
        contact[msg.sender] = newContact;
        emit Success(&#39;Contact Updated&#39;,msg.sender);
    }
    
    function updateImageAddress(string newImage) public{
        require(bytes(newImage).length <256);
        imageAddress[msg.sender] = newImage;
        emit Success(&#39;Image Updated&#39;,msg.sender);
    }
}