//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

contract medicalRecords{


    mapping(uint => address) public patientDetail;
    mapping(address => address)  check;

    function getRegistered() public {
    require(msg.sender != check[msg.sender], "already a particiant");
    uint srNo;
    patientDetail[srNo] = msg.sender;
    check[msg.sender] = msg.sender;
    }

    mapping(string => uint) bicep;

    function getBicep(uint bicepsize) public {
        require(msg.sender == check[msg.sender], "Not a registered participant");
        bicep["bicep"] = bicepsize;
    }

    function getBicepsize() public view returns(uint) {
        return bicep["bicep"];
    }

}