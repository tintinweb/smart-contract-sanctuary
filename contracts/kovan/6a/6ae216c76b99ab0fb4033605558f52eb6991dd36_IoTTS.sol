/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Internet of Things Trusted Storage

// this contract is mainly for storing string data.

contract IoTTS{
    
    // store production info
    // store logistics trace
    // store circulation trace
    
    struct StorageItem{
        string productionInfo; // production information of the product
        string logisticTrace;
        string circulationTrace;
        bool exists;
    }
    // map product hash ID to its storage.
    // product ID in address form
    mapping(address => StorageItem) public ts ;
    address[] itemIds;
    
    //  two level privileges
    address admin;
    mapping(address => bool) memberMarks;
    
    // uncomment if needed (may mess up the code)
    // address[] members;
    
    modifier isAdmin(){
        require(msg.sender == admin, "Caller is not admin");
        _;
    }
    modifier isMember(){
        require(memberMarks[msg.sender] == true, "Caller is not member of this storage.");
        _;
    }
    modifier itemExist(address itemId){
        require(ts[itemId].exists == true, "Requested item not exist!");
        _;
    }
    
    constructor(){
        admin = msg.sender;
        memberMarks[admin] = true;
    }
    
    function markMember(address addr) public isAdmin{
        memberMarks[addr] = true;
    }
    function unmarkMember(address addr) public isAdmin{
        require(addr != admin, "can't delete membership of admin!");
        delete memberMarks[addr];
    }
    function changeAdmin(address newAdmin) public isAdmin {
        admin = newAdmin;
    }
    
    function getProductionInfo(address itemId) public isMember  itemExist(itemId) view returns (string memory){
        StorageItem memory item = ts[itemId];
        return item.productionInfo;
    }
    function getLogisticTrace(address itemId) public  isMember itemExist(itemId) view returns (string memory){
        StorageItem memory item = ts[itemId];
        return item.logisticTrace;
    }
    function getCirculationTrace(address itemId) public isMember  itemExist(itemId) view returns (string memory){
        StorageItem memory item = ts[itemId];
        return item.circulationTrace;
    }
    function getItemIdList() public  isMember  view returns (address[] memory){
        return itemIds;
    }
    
    function make0Transaction(address itemId) internal {
        payable(itemId).transfer(0);
    }
    
    function setProductionInfo(address itemId, string calldata productionInfo) public isMember  {
        if(! ts[itemId].exists){
            itemIds.push(itemId);
        }
        StorageItem memory item = ts[itemId];
        item.productionInfo = productionInfo;
        item.exists = true;
        ts[itemId] = item;
        make0Transaction(itemId);
    }
    function setLogisticTrace(address itemId, string calldata logisticTrace) public isMember  {
        if(! ts[itemId].exists){
            itemIds.push(itemId);
        }
        StorageItem memory item = ts[itemId];
        item.productionInfo = logisticTrace;
        ts[itemId] = item;
        make0Transaction(itemId);
    }
    function setCirculationTrace(address itemId, string calldata circulationTrace) public  isMember {
        if(! ts[itemId].exists){
            itemIds.push(itemId);
        }
        StorageItem memory item = ts[itemId];
        item.productionInfo = circulationTrace;
        item.exists = true;
        ts[itemId] = item;
        make0Transaction(itemId);
    }
    function updateStorage(address itemId, string calldata productionInfo, string calldata logisticTrace,  string calldata circulationTrace) public isMember  {
        if(! ts[itemId].exists){
            itemIds.push(itemId);
        }
        StorageItem memory item;
        item.productionInfo = productionInfo;
        item.logisticTrace = logisticTrace;
        item.circulationTrace = circulationTrace;
        item.exists = true;
        ts[itemId] = item;
        make0Transaction(itemId);
    }
    function setStorageItem(address itemId,  StorageItem calldata itemData) public isMember  {
        if(! ts[itemId].exists){
            itemIds.push(itemId);
        }

        ts[itemId] = itemData;
        ts[itemId].exists = true;
        make0Transaction(itemId);
    }
}