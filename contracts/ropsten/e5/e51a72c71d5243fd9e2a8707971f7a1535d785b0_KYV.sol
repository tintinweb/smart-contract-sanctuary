pragma solidity ^0.4.4;

//<--- @Author http://fliptin.com/ ---->
//<--- Version 0.3 ---->

contract KYV {

    //saves the event logs
    event Log(
        string  eventMessage,
        string  status
    );

    // struct Organisation
    struct Organisation {
        string code;
        string regNumber;
        string dataHash;
        string status;
        string createdDate;
        string updatedDate;
        string adminId;
        bool isValue;
    }
    
    //struct Document
    struct Document {
        string docId;
        string docHash;
        string createdDate;
    }

    //creator of this smart contract
    string creatorName;
    address creatorAddress;
    
    //Each organisation mapped to vendor Id
    mapping(string => Organisation) orgs;
    
    //Organisation track with orgId
    mapping(string => Organisation[]) orgTrack;
    
    //Vendor Document hash
    mapping(string => Document[]) docs;
    
    //vendor document index
    mapping(string => mapping(string => Document)) documentIndex;
    
    //contructor which creates the owner
    constructor (string _creator) public {
      creatorName = _creator;
      creatorAddress = msg.sender;
      emit Log("Contract deployed successfully by ",_creator);
    }
    
    //function to check access rights of transaction request sender
    function isPartOfOrg(string _vendorId) private view returns(bool) {
         if(orgs[_vendorId].isValue) {
             return true;
         }
             return false;
    }
    
    //  function that adds an organisation to the network
    //  returns 0 if successfull
    //  returns 7 if no access rights to transaction request sender
    function addOrg(string _vendorId, string _code, string _regNumber, string _dataHash, string _date, string _status) public payable returns(uint) {
        if(!isPartOfOrg(_vendorId)) {
         Organisation storage org = orgs[_vendorId];
         org.code = _code;
         org.regNumber = _regNumber;
         org.dataHash = _dataHash;
         org.createdDate = _date;
         org.status = _status;
         org.isValue = true;
         orgTrack[_vendorId].push(org);
         emit Log("Successfully added organisation",_status);
        return 0; 
    } 
        return 7;
    }
    
     //funtion that approves or rejects the organisation
    //returns the status 0-> NEW, 1-> APPROVED, 2-> DECLINED, 7-> Invalid orgId
    function approveRejectOrg(string _adminId, string _vendorId, string _status, string _date, string _dataHash) public payable returns(uint) {
        if(isPartOfOrg(_vendorId)) { 
          Organisation storage org = orgs[_vendorId];
          org.status = _status;
          org.updatedDate = _date;
          org.adminId = _adminId;
          org.dataHash= _dataHash;
          orgTrack[_vendorId].push(org);
          emit Log("Approve or Reject organisation",_status);
          return 0; 
        } 
          return 7;
    }
    
    //Used to add the Document
    function addDoc(string _vendorId,string _docId, string _docHash, string _date) public payable returns (uint){
        Document storage doc = documentIndex[_vendorId][_docId];
        doc.docId = _docId;
        doc.docHash = _docHash;
        doc.createdDate = _date;
        docs[_vendorId].push(doc);
        return 0;
    }
    
    //funtion which returns organisation by accepting the organisation Id
    function getOrg(string _vendorId) public constant returns (string code, string regNumber,
                    string dataHash, string adminId, string createdDate, string status, string updatedDate){
        Organisation memory org = orgs[_vendorId];
        return (org.code, org.regNumber, org.dataHash, org.adminId, org.createdDate, org.status, org.updatedDate);
    }
    
    //function which returns document by accepting orgid and docId 
    function getDoc(string _vendorId, string _docId) public constant returns (string docId, string docHash, string _date){
        Document memory doc = documentIndex[_vendorId][_docId];
        return(doc.docId,doc.docHash,doc.createdDate);
    }
    
     //function which returns last index in documents
    function getDocsCount(string _vendorId) public constant returns (uint index){
        return docs[_vendorId].length;
    }
    
     //function which returns last index in documents
    function getDocByIndex(string _vendorId, uint _index) public constant returns (string docId, string docHash, string date){
         Document memory doc = docs[_vendorId][_index-1];
         return(doc.docId,doc.docHash,doc.createdDate);
    }
    
    //function returns the owner
    function getOwner() public constant returns (string, address) {
        return (creatorName,creatorAddress);
    }
    
     //function returns the organisation index
    function getOrgCount(string _vendorId) public constant returns (uint index) {
        return orgTrack[_vendorId].length;
    }
    
     //function returns the organisation by index
    function getOrgByIndex(string _vendorId,uint _index) public constant returns (string code, string regNumber,
                    string dataHash, string adminId, string createdDate, string status, string updatedDate) {
        Organisation memory org = orgTrack[_vendorId][_index-1];
        return (org.code, org.regNumber, org.dataHash, org.adminId, org.createdDate, org.status, org.updatedDate);
    }
    
}