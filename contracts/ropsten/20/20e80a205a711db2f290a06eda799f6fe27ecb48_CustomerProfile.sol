pragma solidity ^0.4.24;

contract CustomerProfile {
    
    
    string constant NoneString = ""; 
    bytes32 constant NoneBytes32 = bytes32(0);
    int64 constant NoneInt64 = int64(0);
    uint256 constant NoneUint256 = uint256(0);
    address constant NoneAddress = address(0x00);
    address owner;
    
    enum CustomerType { Phys, Jur, Foreing, Undefined }

    struct CustomerDescription {
        CustomerType customerType;
        string customerName;
        bytes32 customerNameHash;
        string customerIDString;
        bytes32 customerIDHash;
        int64 customerRating;
    }
    
    struct DataRecord {
        uint256 internalID;
        string reason;
        bytes32 reasonHash;
        string recordDataURI;
        bytes32 recordDataHash;
        int64 ratingChange;
        address publishedBy;
    }
    
            
    uint256 private recordCounter = 0;
    uint256 private historyRecordCounter = 0;
    
    enum RecordChangeType {AddRecord, ModifyRecord, RemoveRecord}
    
    struct HistoryRecord {
        uint256 internalID;
        RecordChangeType changeType;
        address modifiedBy;
        uint modificationTime;
        string reason;
        DataRecord oldRecord;
        DataRecord newRecord;
        // string reasonResourceURI;
        // bytes32 reasonDataHash;
        // bytes32 reasonHash;
    }
    
    CustomerDescription public customerDescription;
    mapping(uint256 => DataRecord) records;
    mapping(uint256 => HistoryRecord) history;
    
    
    constructor (CustomerType _customerType, string _name, string _idString) public {
        owner = msg.sender;
        customerDescription = CustomerDescription({customerType:_customerType, 
                                customerName: _name, 
                                customerNameHash: sha256(_name),
                                customerIDString: _idString,
                                customerIDHash: sha256(_idString),
                                customerRating: 0
        });
        recordCounter = 1;
        historyRecordCounter = 1;
    }
    
    function addRecord(string _reason, string _additionReason, string _recordDataURI, bytes32 _recordDataHash, int64 _ratingChange ) public returns (uint256 newRecordID, uint256 historyRecordID){
        DataRecord memory record = DataRecord({
                internalID: recordCounter,
                reason: _reason,
                reasonHash: sha256(_reason),
                recordDataURI: _recordDataURI,
                recordDataHash: _recordDataHash,
                ratingChange: _ratingChange,
                publishedBy: msg.sender
        });
        records[recordCounter] = record;
        recordCounter = recordCounter + 1;
    
        DataRecord memory noneRecord = DataRecord({
            internalID: NoneUint256,
            reason: NoneString, 
            reasonHash: NoneBytes32, 
            recordDataURI: NoneString, 
            recordDataHash: NoneBytes32, 
            ratingChange: NoneInt64, 
            publishedBy: NoneAddress});    
            
        HistoryRecord memory change = HistoryRecord({
            internalID: historyRecordCounter,
            oldRecord: noneRecord,
            newRecord: record,
            changeType: RecordChangeType.AddRecord,
            modifiedBy: msg.sender,
            modificationTime: now,
            reason: _additionReason
        });
        history[historyRecordCounter] = change;
        historyRecordCounter = historyRecordCounter + 1;
        
        int64 newRating = customerDescription.customerRating + _ratingChange;
        customerDescription.customerRating = newRating;
        newRecordID = record.internalID;
        historyRecordID = change.internalID;
    }


    function modifyRecord(uint256 _recordID, string _reason, string _modificationReason, string _recordDataURI, bytes32 _recordDataHash, int64 _ratingChange ) public returns (uint256 newRecordID, uint256 historyRecordID){
        
        DataRecord memory existingRecord = records[_recordID];
        if (existingRecord.internalID != _recordID) revert();
        
        DataRecord memory newRecord = DataRecord({
                internalID: _recordID,
                reason: _reason,
                reasonHash: sha256(_reason),
                recordDataURI: _recordDataURI,
                recordDataHash: _recordDataHash,
                ratingChange: _ratingChange,
                publishedBy: msg.sender
        });
        
        HistoryRecord memory change = HistoryRecord({
            internalID: historyRecordCounter,
            oldRecord: existingRecord,
            newRecord: newRecord,
            changeType: RecordChangeType.ModifyRecord,
            modifiedBy: msg.sender,
            modificationTime: now,
            reason: _modificationReason
        });
        
        int64 newRating = customerDescription.customerRating - existingRecord.ratingChange + _ratingChange;
        
        
        records[_recordID] = newRecord;
        history[historyRecordCounter] = change;
        historyRecordCounter = historyRecordCounter + 1;

        
        customerDescription.customerRating = newRating;
        newRecordID = newRecord.internalID;
        historyRecordID = change.internalID;
    }
    
    
    function deleteRecord(uint256 _recordID, string _deletionReason, string _recordDataURI, bytes32 _recordDataHash) public returns (uint256 historyRecordID){
        
        DataRecord memory existingRecord = records[_recordID];
        if (existingRecord.internalID != _recordID) revert();
        
        
        DataRecord memory newRecord = DataRecord({
                internalID: NoneUint256,
                reason: _deletionReason,
                reasonHash: sha256(_deletionReason),
                recordDataURI: _recordDataURI,
                recordDataHash: _recordDataHash,
                ratingChange: NoneInt64,
                publishedBy: msg.sender
        });
        
        HistoryRecord memory change = HistoryRecord({
            internalID: historyRecordCounter,
            oldRecord: existingRecord,
            newRecord: newRecord,
            changeType: RecordChangeType.RemoveRecord,
            modifiedBy: msg.sender,
            modificationTime: now,
            reason: _deletionReason
        });
        
        int64 newRating = customerDescription.customerRating - existingRecord.ratingChange;
        
        delete records[_recordID];
        
        history[historyRecordCounter] = change;
        historyRecordCounter = historyRecordCounter + 1;

        customerDescription.customerRating = newRating;
        historyRecordID = change.internalID;
    }
    

    function getRecord(uint256 recordID) public constant returns (        
        uint256 internalID,
        string reason,
        bytes32 reasonHash,
        string recordDataURI,
        bytes32 recordDataHash,
        int64 ratingChange,
        address publishedBy)
        {
            
            DataRecord rec = records[recordID];
            if (rec.internalID != recordID) revert();
            internalID = rec.internalID;
            reason = rec.reason;
            reasonHash = rec.reasonHash;
            recordDataURI = rec.recordDataURI;
            recordDataHash = rec.recordDataHash;
            ratingChange = rec.ratingChange;
            publishedBy = rec.publishedBy;
        }


    function getHistoryRecord(uint256 historyRecordID) public constant returns(
        uint256 internalID,
        RecordChangeType changeType,
        address modifiedBy,
        uint modificationTime,
        string reason)
        {
            HistoryRecord rec = history[historyRecordID];
            if (rec.internalID != historyRecordID) revert();
            internalID = rec.internalID;
            changeType = rec.changeType;
            modifiedBy = rec.modifiedBy;
            modificationTime = rec.modificationTime;
            reason = rec.reason;
        }
        
    function getOldRecordInHistoryRecord(uint256 historyRecordID) public constant returns(
        uint256 OLDinternalID,
        string OLDreason,
        bytes32 OLDreasonHash,
        string OLDrecordDataURI,
        bytes32 OLDrecordDataHash,
        int64 OLDratingChange,
        address OLDpublishedBy)
        {
            HistoryRecord rec = history[historyRecordID];
            if (rec.internalID != historyRecordID) revert();
            OLDinternalID = rec.oldRecord.internalID;
            OLDreason = rec.oldRecord.reason;
            OLDreasonHash = rec.oldRecord.reasonHash;
            OLDrecordDataURI = rec.oldRecord.recordDataURI;
            OLDrecordDataHash = rec.oldRecord.recordDataHash;
            OLDratingChange = rec.oldRecord.ratingChange;
            OLDpublishedBy = rec.oldRecord.publishedBy;
        }
        
    function getNewRecordInHistoryRecord(uint256 historyRecordID) public constant returns(
        uint256 NEWinternalID,
        string NEWreason,
        bytes32 NEWreasonHash,
        string NEWrecordDataURI,
        bytes32 NEWrecordDataHash,
        int64 NEWratingChange,
        address NEWpublishedBy){
            HistoryRecord rec = history[historyRecordID];
            if (rec.internalID != historyRecordID) revert();
            NEWinternalID = rec.newRecord.internalID;
            NEWreason = rec.newRecord.reason;
            NEWreasonHash = rec.newRecord.reasonHash;
            NEWrecordDataURI = rec.newRecord.recordDataURI;
            NEWrecordDataHash = rec.newRecord.recordDataHash;
            NEWratingChange = rec.newRecord.ratingChange;
            NEWpublishedBy = rec.newRecord.publishedBy;
        }        


    function currentRating() public constant returns (int64 rating){
        rating =  customerDescription.customerRating;
    }
    
    function maxRecordID() public constant returns(uint256 recordID){
        recordID = recordCounter - 1;
    }
    
    function maxHistoryRecordID() public constant returns(uint256 recordID){
        recordID = historyRecordCounter - 1;
    }
    

}