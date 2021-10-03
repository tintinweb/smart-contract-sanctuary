/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;



contract testCompany {

    // Company Structure here   
    struct companyInfo {
        bytes32 name ;
        uint companyId;
        uint adminId;
        uint companyParentId;
        uint status;
        uint entity;
    }



    // Admin Structure here 
    struct adminInfo{
        bytes32 name;
        
        uint adminId;
        uint companyId;
        bytes32 companyName;
        uint companyParentId;
        uint status;
        uint entity;
        uint [] signRecords;
        uint [] changeStatusRecords;
        uint [] createRecords;
        uint [] requestRecords;
    }
 
    // ----------------mapping------------------

    
    mapping (uint => uint ) entity;
    mapping (uint => companyInfo) companyInfoMapping;
    mapping (uint => adminInfo) adminInfoMapping;
    mapping (address => uint) addresstoId;
    mapping (uint => address) IdtoAdress;

    // ----------------mapping--------------------
    // ----------------Event----------------------
    event companyCreated(bytes32 name, uint companyId, uint companyParentId);
    // ----------------Event----------------------


    constructor(address  _addres) {
        
 
        uint _adminId=1234567890;
        entity[_adminId]= 11;
        addresstoId[_addres] =  _adminId;
        IdtoAdress[_adminId] = _addres;
        adminInfoMapping[_adminId].companyId = 1000;
        adminInfoMapping[_adminId].status = 2;


        uint _companyId = 1000;
        entity[1000]= 10;
        companyInfoMapping[_companyId].status = 2;
        companyInfoMapping[_companyId].name = "0x62696d636861696e";
        companyInfoMapping[_companyId].adminId = 1234567890;
        

    }

    // --------------Random function-----------------------

    function random() private view returns(uint){
        uint rand= uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty)))%1000;
        return rand;
        }
    // --------------Random function-----------------------
    // --------------Company function----------------------

    function addCompanyInfo (bytes32 _name, uint _entity,  uint _adminId) public returns(uint companyId) {

        //require(entity[_companyId]==0, 'The company is exist'); 
        require(addresstoId[msg.sender]==_adminId , 'Wrong ID');
        require((entity[_adminId]==11 && _entity==20) || (entity[_adminId]==21 &&
         (_entity==30 || _entity==40 || _entity==50 || _entity==60)), 'You are not allowed');
        uint _companyId = random();
        companyInfoMapping[_companyId].name = _name;
        companyInfoMapping[_companyId].companyId = _companyId;
        companyInfoMapping[_companyId].entity = _entity;
        companyInfoMapping[_companyId].status = 1;
        companyInfoMapping[_companyId].entity = _entity;
        entity[_companyId]= _entity;
        uint _companyParentId = adminInfoMapping[_adminId].companyId;
        companyInfoMapping[_companyId].companyParentId = _companyParentId;
        adminInfoMapping[_adminId].createRecords.push(_companyId);
        emit companyCreated(_name, _companyId, _companyParentId);
        return _companyId;
        }
    
    function getCompanyInfo (uint _companyId) public view returns (bytes32 name, uint companyEntity, uint status){
        
    
        return(companyInfoMapping[_companyId].name, companyInfoMapping[_companyId].entity, companyInfoMapping[_companyId].status);
    }

    function changeCompanyStatus(uint _companyId, uint _adminID, uint _status) public{

        require(addresstoId[msg.sender]==_adminID, 'Wrong ID');
        require((companyInfoMapping[_companyId].adminId == _adminID || companyInfoMapping[_companyId].adminId == 1234567890) , 'You are not allowed');
        require(companyInfoMapping[_companyId].status != _status, 'The status now is this');
        companyInfoMapping[_companyId].status = _status;
        adminInfoMapping[_adminID].changeStatusRecords.push(_companyId);


    }

// --------------Company function----------------------
// --------------Admin function------------------------
    function addAdminInfo (bytes32 _name, uint _companyId, uint _companyParentId ,bytes32 _companyName, uint _adminEntity) public returns(uint newadminId){
        require(addresstoId[msg.sender]==0, 'You are already registered');
        uint _newadminId = random();
        adminInfoMapping[_newadminId].name = _name;
        adminInfoMapping[_newadminId].companyId = _companyId;
        adminInfoMapping[_newadminId].adminId = _newadminId;
        adminInfoMapping[_newadminId].companyName = _companyName;
        adminInfoMapping[_newadminId].status = 1;
        entity[_newadminId]= _adminEntity;
        adminInfoMapping[_newadminId].companyParentId = _companyParentId;
        addresstoId[msg.sender] = _newadminId;
        IdtoAdress[_newadminId] = msg.sender;
        adminInfoMapping[companyInfoMapping[_companyParentId].adminId].requestRecords.push(_newadminId);
        return (_newadminId);
        }
    function getAdminInfo (uint _adminId) public view returns (bytes32 name, uint adminId, uint status){
        require(addresstoId[msg.sender]==_adminId || addresstoId[msg.sender]==companyInfoMapping[adminInfoMapping[_adminId].companyParentId].adminId , 'You are not allowed'); 
        return (adminInfoMapping[_adminId].name, adminInfoMapping[_adminId].adminId, adminInfoMapping[_adminId].status);
    }
    function getAdminArray(uint _adminId) public view returns (uint [] memory requestRecords, uint [] memory changeStatusRecords, uint [] memory createRecords ){

        require(addresstoId[msg.sender]==_adminId || addresstoId[msg.sender]==companyInfoMapping[adminInfoMapping[_adminId].companyParentId].adminId , 'You are not allowed');
        return(adminInfoMapping[_adminId].requestRecords, adminInfoMapping[_adminId].changeStatusRecords, adminInfoMapping[_adminId].createRecords );


    }
    function changeAdminStatus(uint _adminId, uint _adminParentId, uint _status) public{
        require(addresstoId[msg.sender]==_adminParentId, 'You are not allowed');
        require(adminInfoMapping[_adminParentId].status == 2, 'You are disable');
        require(companyInfoMapping[adminInfoMapping[_adminId].companyParentId].adminId == _adminParentId, 'You are not allowed');
        require(adminInfoMapping[_adminId].status != _status, 'The status now is this');
        adminInfoMapping[_adminId].status = _status;
        adminInfoMapping[_adminParentId].changeStatusRecords.push(_adminId);

    }
  // --------------Admin function------------------------
  
}