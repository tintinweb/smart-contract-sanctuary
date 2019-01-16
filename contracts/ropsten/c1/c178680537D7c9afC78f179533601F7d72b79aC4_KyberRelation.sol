pragma solidity 0.4.24;

contract KyberRelation {
    // Read/write candidate
    address public admin;

    mapping (address => address) public companyRelationUser;    

    event AddRelation(address indexed _slave, address indexed _master);

    // Constructor
    constructor () public {
        admin = msg.sender;
    }
    
    function addRelation(address _slave,address _master) public{
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        companyRelationUser[_slave] = _master;
        emit AddRelation(_slave, _master);
    }

    function getMaster(address _slave) constant public returns (address) {
        return companyRelationUser[_slave];
    }    

    function  transferAdmin(address _adminAddr) public {
        require(
            msg.sender == address(admin),
            "Only admin can call this."
        );
        admin = _adminAddr;
    }

}