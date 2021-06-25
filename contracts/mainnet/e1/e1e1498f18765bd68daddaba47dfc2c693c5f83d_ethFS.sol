/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
//+commit.4cb486ee;

struct File{
    uint256 timestamp;
    bool set;
    bool deleted;
    bool closed;
    uint256 size;
    bytes32[][] data;
}

struct FileTransfer{
    string name;
    address sender;
    uint256 transferTimestamp;
    uint256 timestamp;
    bool closed;
    uint256 size;
    bytes32[] data;
}

contract ethFS {
    // Events 
    // File modification events
    event FileSaved (
        address indexed user,
        string indexed name,
        uint256 timestamp,
        uint256 size,
        bool appended,
        bytes32 dataHash
    );
    event FileClosed (
        address indexed user,
        string indexed name
    );
    event FileDeleted (
        address indexed user,
        string indexed name
    );
    // File transfer events
    event InboxCleared (
        address indexed user
    );
    event InboxWhitelistStatusChange (
        address indexed user,
        bool enabled
    );
    event InboxWhitelistUserStatusChange (
        address indexed user,
        address indexed sender,
        bool enabled
    );
    
    event FileTransfered (
        address indexed user,
        address indexed receiver,
        string indexed name,
        uint256 transferTimestamp
    );
    
    event FileTransferAccepted (
        address indexed user,
        address indexed sender,
        string indexed name,
        uint256 transferTimestamp
    );
    
    // Ownership
    address owner;
    address nextOwner;
    address beneficiary;
    
    // Constraints
    uint256 minNameLenth = 1;
    uint256 maxNameLength = 1024;
    
    // Fees
    uint256 feePerFile = 0;
    uint256 feePerByte = 0;
    uint256 deletionFee = 0;
    uint256 closingFee = 0;
    uint256 transferSendFeePerFile = 0;
    uint256 transferSendFeePerByte = 0;
    uint256 transferAcceptFeePerFile = 0;
    uint256 transferAcceptFeePerByte = 0;
    
    // Active flags
    bool enabled = true;
    
    bool deletionAllowed = false;
    bool deletionEnabled = false;
    bool transferEnabled = true;
    
    // Statistics
    // Files
    uint256 totalSizeWritten = 0;
    uint256 totalSize = 0;
    uint256 totalSizeDeleted = 0;
    uint256 numberOfFiles = 0; // Increased when file is written that has not been set
    uint256 numberOfWrites = 0; // Increased whenever a file is written (created, overwritten, appended, transfers accepted)
    uint256 numberOfTrueAppends = 0; // Increased whenever a file is appended
    uint256 numberOfDeletedFiles = 0; // Number of times the delete bit has been set on a file
    // File transfers
    uint256 numberOfInboxClearings = 0;
    uint256 numberOfWhitelistedUsers = 0;
    uint256 numberOfUsersWithDisabledInboxWhitelist = 0;
    uint256 numberOfTransferRequests = 0;
    uint256 numberOfAcceptedFileTransfers = 0;
    
    
    // Operations
    uint256 defaultNumberOfNewestNames = 100;

    // Data store
    mapping(bytes32 => bytes) store;
    mapping(address => mapping(string => File)) nodes;
    mapping(address => string[]) index;
    
    // Inbox
    mapping(address => FileTransfer[][]) inbox;
    mapping(address => bool) inboxWhitelistDisabled;
    mapping(address => mapping(address => bool)) inboxWhitelist;
    
    // Ownership
    constructor() payable {
        owner = msg.sender;
        beneficiary = msg.sender;
    }
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Only owner can transfer ownership");
        nextOwner = newOwner;
    }
    function confirmOwnership() external {
        require(msg.sender == nextOwner, "Only next owner can confirm owner");
        owner = nextOwner;
    }
    function setBeneficiary(address b) external {
        require(msg.sender == owner, "Only owner can set the beneficiary");
        beneficiary = b;
    }
    function withdraw(uint256 amount) external {
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw");
        payable(msg.sender).transfer(amount);
    }
    
    // Activity flags
    function setEnabled(bool flag) external {
        require(msg.sender == owner, "Only owner can enable/disable");
        enabled = flag;
    }
    function setDeletionFlags(bool enabledFlag, bool allowedFlag) external {
        require(msg.sender == owner, "Only the owner can allow/disallow / enable/disable deletion");
        deletionAllowed = allowedFlag;
        deletionEnabled = enabledFlag;
    }
    function setTransferEnabled(bool flag) external {
        require(msg.sender == owner, "Only the owner can set the transfer enabled flag");
        transferEnabled = flag;
    }
    function setFilenameLimits(uint256 minLen, uint256 maxLen) external {
        require(msg.sender == owner, "Only the owner can set the max name length");
        require(minLen > 0, "Minimal filename length needs to be greater than 0");
        minNameLenth = minLen;
        maxNameLength = maxLen;
    }
    
    // Operations 
    function setOperationParameters(uint256 nNewest) external {
        require(msg.sender == owner, "Only the owner can set operation parameters");
        defaultNumberOfNewestNames = nNewest;
    }
    
    // Fees
    function setFileOperationFees(uint256 perFile, uint256 perByte, uint256 perDeletion, uint256 perClose) external {
        require(msg.sender == owner, "Only the owner can set the per file fee");
        feePerFile = perFile;
        feePerByte = perByte;
        deletionFee = perDeletion;
        closingFee = perClose;
    }
    function setTransferFees(uint256 sendPerFile, uint256 sendPerByte, uint256 acceptPerFile, uint256 acceptPerByte) external {
        require(msg.sender == owner, "Only the owner can set the transfer fees");
        transferSendFeePerFile = sendPerFile;
        transferSendFeePerByte = sendPerByte;
        transferAcceptFeePerFile = acceptPerFile;
        transferAcceptFeePerByte = acceptPerByte;
    }
    
    // Filesystem operations
    function calculateSaveFee(bytes memory data) view public returns (uint256) {
        return data.length * feePerByte + feePerFile;
    }
    function save(string memory name, bytes memory data) public payable {
        save(name, data, false);
    }
    function save(string memory name, bytes memory data, bool append) public payable {
        require(enabled == true, "ethFS disabled");
        require(bytes(name).length >= minNameLenth, "Name shorter than min filename length");
        require(bytes(name).length <= maxNameLength, "Name longer than max filename length");
        require(!containsNewline(name), "Filename should not contain newline");
        require(msg.value >= calculateSaveFee(data), "Not enough ether provided for saving fee");
        require(!append || !nodes[msg.sender][name].closed, "Trying to append but file is closed");
        require(!deletionEnabled || !append || !nodes[msg.sender][name].deleted, "Trying to append to deleted file");
        
        bool trueAppend = nodes[msg.sender][name].set && append;
        
        if(!nodes[msg.sender][name].set) {
            index[msg.sender].push(name);
            numberOfFiles++;
            assert(nodes[msg.sender][name].data.length == 0); // Data store for file that is not set should be empty
            nodes[msg.sender][name].data.push();
        } else {
            // If file is already set and operation is not append (=> overwrite)
            if(!append) {
                nodes[msg.sender][name].data.push();
                totalSize -= nodes[msg.sender][name].size;
                nodes[msg.sender][name].size = 0;
            }
            if(nodes[msg.sender][name].deleted){
                totalSizeDeleted -= nodes[msg.sender][name].size;
                numberOfDeletedFiles--;
            }
        }
        
        bytes32 dataHash = keccak256(data);
        store[dataHash] = data;
        nodes[msg.sender][name].set = true;
        nodes[msg.sender][name].deleted = false;
        nodes[msg.sender][name].closed = false;
        nodes[msg.sender][name].timestamp = block.timestamp;
        nodes[msg.sender][name].size += data.length;
        nodes[msg.sender][name].data[nodes[msg.sender][name].data.length - 1].push(dataHash);
        
        
        totalSizeWritten += data.length;
        totalSize += data.length;
        numberOfWrites++;
        if(trueAppend) {
            numberOfTrueAppends++;
        }
        emit FileSaved(msg.sender, name, block.timestamp, data.length, trueAppend, dataHash);
    }
    function close(string calldata name) external payable {
        require(enabled == true, "ethFS disabled");
        require(nodes[msg.sender][name].set = true, "Trying to close file that is not set");
        require(msg.value >= closingFee, "Not enough ether provided for closing fee");
        nodes[msg.sender][name].closed = true;
        
        emit FileClosed(msg.sender, name);
    }
    function remove(string calldata name) external payable {
        require(enabled == true, "ethFS disabled");
        require(deletionAllowed, "Deletion not allowed");
        require(deletionEnabled, "Deletion disabled");
        require(nodes[msg.sender][name].set, "File not found");
        require(msg.value >= deletionFee, "Not enough ether provided for deletion fee");
        
        bool trueDelete = !nodes[msg.sender][name].deleted;
        nodes[msg.sender][name].deleted = true;
        
        if(trueDelete){
            numberOfDeletedFiles++;
            totalSizeDeleted += nodes[msg.sender][name].size;
        }
        emit FileDeleted(msg.sender, name);
    }
    
    // Data chunk helpers
    function getFileData(bytes32[] memory data) private view returns (bytes memory) {
        bytes memory res;
        for(uint256 i=0; i<data.length; i++){
            res = abi.encodePacked(res, store[data[i]]);
        }
        return res;
    }
    
    // Transfer operations
    function clearInbox() external {
        inbox[msg.sender].push();
        
        numberOfInboxClearings++;
        emit InboxCleared(msg.sender);
    }
    function setInboxWhitelistEnabled(bool flag) external {
        bool previousState = !inboxWhitelistDisabled[msg.sender];
        inboxWhitelistDisabled[msg.sender] = !flag;
        
        if(previousState != flag){
            if(!flag){
                numberOfUsersWithDisabledInboxWhitelist++;
            } else {
                numberOfUsersWithDisabledInboxWhitelist--;
            }
        }
        emit InboxWhitelistStatusChange(msg.sender, flag);
    }
    function setInboxWhitelist(address sender, bool flag) external {
        bool previousState = inboxWhitelist[msg.sender][sender];
        inboxWhitelist[msg.sender][sender] = flag;
        
        if(previousState != flag) {
            if(flag){
                numberOfWhitelistedUsers++;
            } else {
                numberOfWhitelistedUsers--;
            }
        }
        emit InboxWhitelistUserStatusChange(msg.sender, sender, flag);
    }
    function calculateTransferSendingFee(string memory name) public view returns (uint256) {
        require(nodes[msg.sender][name].set, "File does not exist");
        require(!nodes[msg.sender][name].deleted || !deletionEnabled, "File has been deleted");
        return nodes[msg.sender][name].size * transferSendFeePerByte + transferSendFeePerFile;
    }
    function transfer(string calldata name, address receiver) external payable {
        require(enabled == true, "ethFS disabled");
        require(transferEnabled, "Transfer is not enabled");
        require(nodes[msg.sender][name].set, "File does not exist");
        require(!nodes[msg.sender][name].deleted || !deletionEnabled, "File has been deleted");
        require(inboxWhitelistDisabled[receiver] || inboxWhitelist[receiver][msg.sender], "Inbox whitelist enabled by receiver and sender not whitelisted");
        require(msg.value >= calculateTransferSendingFee(name), "Not enough ether provided for transfer fee");
        
        FileTransfer memory ft;
        ft.sender = msg.sender;
        ft.name = name;
        ft.transferTimestamp = block.timestamp;
        ft.timestamp = nodes[msg.sender][name].timestamp;
        ft.closed = nodes[msg.sender][name].closed;
        ft.size = nodes[msg.sender][name].size;
        ft.data = nodes[msg.sender][name].data[nodes[msg.sender][name].data.length - 1];
        if(inbox[receiver].length == 0){
            inbox[receiver].push();
        }
        inbox[receiver][inbox[receiver].length - 1].push(ft);
        
        numberOfTransferRequests++;
        emit FileTransfered(msg.sender, receiver, name, ft.transferTimestamp);
    }
    
    // returns (index of last FileTransfer, fee)
    function calculateLastFileTransferAcceptanceFee() public view returns (uint256, uint256) {
        require(inbox[msg.sender].length > 0, "Inbox not yet existing");
        require(inbox[msg.sender][inbox[msg.sender].length - 1].length > 0, "Inbox empty");
        
        uint256 i = inbox[msg.sender][inbox[msg.sender].length - 1].length - 1;
        return (i, inbox[msg.sender][inbox[msg.sender].length - 1][i].size * transferAcceptFeePerByte + transferAcceptFeePerFile);
    }
    function acceptLastFileTransfer(uint256 i) external payable {
        require(enabled == true, "ethFS disabled");
        require(transferEnabled, "Transfer is not enabled");
        require(inbox[msg.sender].length > 0, "Inbox not yet existing");
        require(inbox[msg.sender][inbox[msg.sender].length - 1].length > 0, "Inbox empty");
        require(i == inbox[msg.sender][inbox[msg.sender].length - 1].length - 1, "Requested transfer index not the last file in inbox (inbox)");
        (, uint256 fee) = calculateLastFileTransferAcceptanceFee();
        require(msg.value >= fee, "Not enough ether provided for transfer fee");
        
        FileTransfer storage ft = inbox[msg.sender][inbox[msg.sender].length - 1][i];
        inbox[msg.sender][inbox[msg.sender].length - 1].pop();
        
        if(!nodes[msg.sender][ft.name].set) {
            index[msg.sender].push(ft.name);
            numberOfFiles++;
            assert(nodes[msg.sender][ft.name].data.length == 0); // Data store for file that is not set should be empty
        } else {
            // If file is already set => overwrite
            totalSize -= nodes[msg.sender][ft.name].size;
            if(nodes[msg.sender][ft.name].deleted){
                totalSizeDeleted -= nodes[msg.sender][ft.name].size;
                numberOfDeletedFiles--;
            }
        }
        
        nodes[msg.sender][ft.name].set = true;
        nodes[msg.sender][ft.name].deleted = false;
        nodes[msg.sender][ft.name].timestamp = ft.timestamp;
        nodes[msg.sender][ft.name].closed = ft.closed;
        nodes[msg.sender][ft.name].size = ft.size;
        nodes[msg.sender][ft.name].data.push(ft.data);
        
        numberOfAcceptedFileTransfers++;
        totalSize += ft.size;
        numberOfWrites++;
        emit FileTransferAccepted(msg.sender, ft.sender, ft.name, ft.transferTimestamp);
    }
    
    // Getters
    
    // Filesystem 
    function count(address user, bool excludeDeleted) public view returns (uint256){
        uint256 c = 0;
        for(uint256 i=0; i<index[user].length; i++){
            c += (deletionEnabled && excludeDeleted && nodes[user][index[user][i]].deleted) ? 0 : 1;
        }
        return c;
    }    
    function count() public view returns (uint256){
        return count(msg.sender, true);
    }
    function getName(address user, uint256 i) public view returns (string memory) {
        return index[user][i];
    }
    function getName(uint256 i) public view returns (string memory) {
        return getName(msg.sender, i);
    }
    function getAllNames(address user, uint256 n, bool excludeDeleted) public view returns (string memory){
        string[] memory nameIndex = index[user];
        bytes memory res;
        uint256 nAdded = 0;
        for(uint256 i=0; i<nameIndex.length; i++){
            if(n == 0 || nAdded < n){
                uint256 current = nameIndex.length - i - 1;
                if(!deletionEnabled || !excludeDeleted || !nodes[user][nameIndex[current]].deleted) {
                    res = abi.encodePacked(res, nameIndex[current], '\n');
                    nAdded++;
                }
            }
        }
        return string(res);
    }
    function getAllNames(address user) public view returns (string memory){
        return getAllNames(user, 0, true);
    }
    function getAllNames() public view returns (string memory){
        return getAllNames(msg.sender, 0, true);
    }
    function getNewestNames(address user, uint256 n) public view returns (string memory){
        return getAllNames(user, n, true);
    }
    function getNewestNames(uint256 n) public view returns (string memory){
        return getAllNames(msg.sender, n, true);
    }
    function getNewestNames() public view returns (string memory){
        return getAllNames(msg.sender, defaultNumberOfNewestNames, true);
    }
    function exists(string memory name) public view returns (bool) {
        return exists(msg.sender, name);
    }
    function exists(address user, string memory name) public view returns (bool) {
        return nodes[user][name].set && (!nodes[msg.sender][name].deleted || !deletionEnabled);
    }

    function retrieve(address user, string memory name) public view returns (bytes memory){
        require(nodes[user][name].set, "File does not exist");
        require(!nodes[user][name].deleted || !deletionEnabled, "File has been deleted");
        return getFileData(nodes[user][name].data[nodes[msg.sender][name].data.length - 1]);
        
    }
    function retrieve(string memory name) public view returns (bytes memory){
        return retrieve(msg.sender, name);
    }

    function getTimestamp(address user, string memory name) public view returns (uint256){
        require(nodes[user][name].set, "File does not exist");
        require(!nodes[user][name].deleted || !deletionEnabled, "File has been deleted");
        return nodes[user][name].timestamp;
    }
    function getTimestamp(string calldata name) external view returns (uint256){
        return getTimestamp(msg.sender, name);
    }
    
    function getSize(address user, string memory name) public view returns (uint256){
        require(nodes[user][name].set, "File does not exist");
        require(!nodes[user][name].deleted || !deletionEnabled, "File has been deleted");
        return nodes[user][name].size;
    }
    function getSize(string calldata name) external view returns (uint256){
        return getSize(msg.sender, name);
    }
    
    // Inbox
    // returns index, name, sender, transferTimestamp, timestamp, dataHash
    function getLastFileFromInbox() external view returns (uint256, string memory, address, uint256, uint256, bytes memory) {
        require(inbox[msg.sender].length > 0, "Inbox not yet existing");
        require(inbox[msg.sender][inbox[msg.sender].length - 1].length > 0, "Inbox empty");
        uint256 i = inbox[msg.sender][inbox[msg.sender].length - 1].length - 1;
        (string memory name, address sender, uint256 transferTimestamp, uint256 timestamp, bytes memory data) = getFileFromInbox(i);
        return (i, name, sender, transferTimestamp, timestamp, data);
        
    }
    // returns name, sender, transferTimestamp, timestamp, dataHash
    function getFileFromInbox(uint256 i) public view returns (string memory, address, uint256, uint256, bytes memory) {
        require(inbox[msg.sender].length > 0, "Inbox not yet existing");
        require(i >= 0 && i < inbox[msg.sender][inbox[msg.sender].length - 1].length, "Index out of range");
        FileTransfer memory ft = inbox[msg.sender][inbox[msg.sender].length - 1][i];
        return (ft.name, ft.sender, ft.transferTimestamp, ft.timestamp, getFileData(ft.data));
    }
    
    // Helpers
    function containsNewline(string memory s) public pure returns (bool) {
        bytes memory stringBytes = bytes(s);
        for(uint256 i=0; i<stringBytes.length; i++){
            if (stringBytes[i] == '\n') {
                return true;
            }
        }
        return false;
    }
    
}