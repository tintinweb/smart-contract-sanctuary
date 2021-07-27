/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

//SPDX-License-Identifier: AFL-1.1
pragma solidity >= 0.5.0 < 0.9.0;
pragma experimental ABIEncoderV2;

contract MaximoSC {

    struct MainteinanceStatus {
        string changeBy;
        string changeDate;
        string status;
        uint256 woStatusID;
        
        string txhash;
    }

    struct MainteinanceWO {
        uint256 woNum;
        uint256 assetNum;
        string description;
        string href;
        string siteID;
        
        string txhash;
    }

    mapping(uint256 => MainteinanceWO) workOrders;                  //woNum => wo
    mapping(uint256 => MainteinanceStatus[]) statuses;              //woNum => status array
    mapping(uint256 => mapping(uint256 => uint256)) statusIndexes;  //woNum => status id => status index

    /*modifier WODoesNotAlreadyExist (uint256 woNum) {
        MainteinanceWO memory wo = workOrders[woNum];
        require(wo.woNum == woNum);
        _;
    }*/
    
    modifier doesWOExist(uint256 woNum, bool mustExist){
        MainteinanceWO memory wo = workOrders[woNum];
        bool exist = wo.woNum == woNum;
        require(exist == mustExist);
        _;
    }
    
    modifier WOTXNotSet(uint256 woNum){
        MainteinanceWO memory wo = workOrders[woNum];
        bytes32 realHash = keccak256(abi.encodePacked(wo.txhash));
        bytes32 voidHash = keccak256(abi.encodePacked(""));
        
        require(realHash == voidHash);
        _;
    }

    modifier WOStatusTXNotSet(uint256 woNum, uint256 statusID){
        uint256 index = statusIndexes[woNum][statusID];
        require(index != 0);
        _;
    }

    function getWorkOrder(uint256 woNum) public view returns (MainteinanceWO memory, MainteinanceStatus[] memory) {
        MainteinanceWO memory wo = workOrders[woNum];
        MainteinanceStatus[] memory st = statuses[woNum];
        return (wo, st);
    }

    
    function addWorkOrder(uint256 woNum, uint256 assetNum, string memory description, string memory href, string memory siteID)
    public doesWOExist(woNum, false) {
        
        MainteinanceWO memory wo;
        wo.woNum = woNum;
        wo.assetNum = assetNum;
        wo.description = description;
        wo.href = href;
        wo.siteID = siteID;
        
        workOrders[woNum] = wo;
    }
    
    function addWorkOrderStatus(uint256 woNum, string memory status, string memory changeBy, string memory changeDate, uint256 woStatusID)
    public doesWOExist(woNum, true) {
        
        MainteinanceStatus memory so;
        so.status = status;
        so.changeBy = changeBy;
        so.changeDate = changeDate;
        so.woStatusID = woStatusID;
        
        statuses[woNum].push(so);
        uint256 len = statuses[woNum].length;
        statusIndexes[woNum][woStatusID] = len;
    }

    function setWOTxHash(uint256 woNum, string memory txhash)
    public WOTXNotSet(woNum) {
        
        workOrders[woNum].txhash = txhash;
    }
    
    function setWOStatusTxHash(uint256 woNum, uint256 statusID, string memory txhash)
    public WOStatusTXNotSet(woNum, statusID) {
        
        /*uint256 last = statuses[woNum].length - 1;
        statuses[woNum][last].txhash = txhash;*/
        
        uint256 index = statusIndexes[woNum][statusID] - 1;
        statuses[woNum][index].txhash = txhash;
    }
}