/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

contract VentureManage {
    address public adminAddress;
    mapping(address => bool) public whitelistAddress;
    struct Project {
        string  projectName;
        address ventureAddress;
        address platformFeeAddress;
        uint    maxFunding;
        uint    currentFunding;
        uint    minPerFund;
        uint    maxPerFund;
    }
    Project[] public projectList;
    constructor() public {
        adminAddress = msg.sender;
    }
    function getOwnerAddress() public view returns(address) {
        return adminAddress;
    }
    function checkWhiteList() public checkAddressWhiteList view returns (bool){
        return true;
    }
    function addWhitelist(address investorAddress) checkAdminAddress public{
        whitelistAddress[investorAddress] = true;
    }
    function addProject(address ventureAddress, address platformFeeAddress,uint maxFunding,string memory projectName, uint minPerFund, uint maxPerFund ) checkAdminAddress public {
        Project memory project = Project({
            projectName: projectName,
            ventureAddress: ventureAddress,
            platformFeeAddress: platformFeeAddress,
            maxFunding: maxFunding,
            currentFunding: 0,
            minPerFund: minPerFund,
            maxPerFund: maxPerFund
        });
        projectList.push(project);
    }
    function getListProject() public checkAddressWhiteList view returns (Project[] memory){
        return projectList;
    }
    modifier checkAddressWhiteList() {
        require(whitelistAddress[msg.sender] || msg.sender == adminAddress);
        _;
    }
    modifier checkAdminAddress() {
        require(msg.sender == adminAddress);
        _;
    }
}