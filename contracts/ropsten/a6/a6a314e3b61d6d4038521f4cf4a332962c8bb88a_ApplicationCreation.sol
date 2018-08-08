pragma solidity^0.4.17;

	//<--- @Author http://fliptin.com/ ---->
	//<--- Version 0.3 ---->

	contract ApplicationCreation {

	    //Saves the event logs
	    event Log(
	        string eventMessage
	    );

	    //Struct Application
	    struct Application {
	        string id;
	        string number;
	        string dataHash;
	        string createdDate;
	        bool exists;
	    }
	    
	     //Struct Vendor Application
	    struct VendorApplication {
	        string id;
	        string status;
	        string dataHash;
	        string createdDate;
	        string govtId;
	        string action;
	    }
	    
	    /* Struct status track
	     * Used to track the status 
	     */
	    struct StatusTrack {
	        string status;
	        string createdDate;
	        string dataHash;
	        string submitter;
	        string action;
	    }
	    
        /* Struct Scoring
	     * Used to track the scoring 
	     */
	    struct Scoring {
	        string submitter;
	        uint256 beeScore;
	        uint256 innovation;
	        uint256 bussinessModel;
	        uint256 scalability;
	        string createdDate;
	        string action;
	        string recommendedAmount;
	    }

	    //Defines the status
	    string vendorAppStatus;
	  
	    //creator of this smart contract
	    string creatorName;
	    address creatorAddress;
	    
	    //Govt applications
	    mapping(string => Application[]) applications;
	    
	    //Govt Application index
	    mapping(string => mapping(string => Application)) applicationIndex;
	    
	    //vendor applications
	    mapping(string => VendorApplication[]) vendorApplications;
	    
	    //vendor application index
	    mapping(string => VendorApplication) vendorApplicationIndex;
	    
	    //Vendor application status track by applicationVendorId
	    mapping(string => StatusTrack[]) vendorApplicationStatusTrack;
	    
	    //Vendor application Scoring by applicationVendorId
	    mapping(string => Scoring[]) vendorApplicationScoring;
	    
	    //contructor which creates the owner
	    constructor (string _creator) public {
	      creatorName = _creator;
	      creatorAddress = msg.sender;
	      emit Log("Contract deployed successfully");
	    }
	    
	    //function returns the owner
	    function getOwner() public constant returns (string, address) {
	        return (creatorName,creatorAddress);
	    }
	    
	    //Validate if application is exits or not
	    function isApplicationExits(string _govtId, string _applicationId) private view returns(bool) {
	        if(applicationIndex[_govtId][_applicationId].exists){
	            return true;
	        }else{
	            return false;
	        }
	    }
	    
    	/*
	     * Adds new application which is created by government 
	     * returns true if successfull
	     */
	    function addApplication(string _govtId, string _applicationId, string _createdDate, string _dataHash)
	                            public payable returns(bool) {
	        if (!isApplicationExits(_govtId,_applicationId)) {
	            Application storage app = applicationIndex[_govtId][_applicationId];
	            app.id = _applicationId;
	            app.dataHash = _dataHash;
	            app.createdDate = _createdDate;
	            app.exists = true;
	            applications[_govtId].push(app);
	            applicationIndex[_govtId][_applicationId] = app;
	            emit Log("New application added successfully");
	            return true;
	        }
	            return false;
	    }
	    
    	/*
	     * This function is used to submit the applications by vendors 
	     * returns true if successfull
	     */
	    function submitApplication(string _govtId, string _vendorId, string _applicationVendorId, string _dataHash, string _date, 
	                               string _status, string _submitter, string _action) public payable returns(bool) {
	        VendorApplication storage vApp = vendorApplicationIndex[_applicationVendorId];
	        vApp.status = _status;
	        vApp.id = _applicationVendorId;
	        vApp.dataHash = _dataHash;
	        vApp.createdDate = _date;
	        vApp.govtId = _govtId;
	        vApp.action = _action;
	        vendorApplications[_vendorId].push(vApp);
	        vendorApplicationStatusTrack[_applicationVendorId].push(StatusTrack({
	             status: _status,
	             createdDate: _date,
	             dataHash: _dataHash,
	             submitter: _submitter,
	             action: _action
	        }));
	        emit Log("Submitted application by vendor");
	        return true;
	    }
	    
	    /*
	     * which updated the status of vendor responded application returns true if
	     * successfull
	     */
	    function updateVendorApplicationStatus(string _applicationVendorId, string _status, string _date, string _dataHash,
	                                           string _submitter, string _action) public payable returns (bool) {
	        VendorApplication storage vApp = vendorApplicationIndex[_applicationVendorId];
	        vApp.status = _status;
	        vApp.action = _action;
	        vApp.dataHash = _dataHash;
	        vendorApplicationStatusTrack[_applicationVendorId].push(StatusTrack({
	             status: _status,
	             createdDate: _date,
	             dataHash: _dataHash,
	             submitter: _submitter,
	             action: _action
	        }));
	        emit Log("updated vendor application status");
	        return true;
	    }
	    
	    //Creates scoring for applicationVendor
	    function createScore(string _applicationVendorId, string _submitter,uint256 _beeScore,
	           uint256 _innovation, uint256 _bussinessModel,uint256 _scalability,string _date, string _recommendedAmount,
	           string _applicationVendorHash, string _action, string _status ) public payable returns (bool) {
	                         
	        VendorApplication storage vApp = vendorApplicationIndex[_applicationVendorId];
	        vApp.status = _status;
	        vApp.dataHash = _applicationVendorHash;
	        
	        vendorApplicationScoring[_applicationVendorId].push(Scoring({
	            submitter: _submitter,
	            beeScore: _beeScore,
	            innovation: _innovation,
	            bussinessModel: _bussinessModel,
	            scalability: _scalability,
	            createdDate: _date,
	            action: _action,
	            recommendedAmount: _recommendedAmount
	        }));
	        
	         vendorApplicationStatusTrack[_applicationVendorId].push(StatusTrack({
	             status: _status,
	             createdDate: _date,
	             dataHash: _applicationVendorHash,
	             submitter: _submitter,
	             action: _action
	        }));
	        
	        emit Log("Scoring created successfully");
	        return true;
	    }
	    
	    //---------------------> VendorApplication getters <----------------------------------//
	    
	     //returns vendor application by applicationVendorId
	     function getVendorApplication(string _applicationVendorId) public constant returns (string id, string status,
	                                        string dataHash, string date, string govtId, string action) {
	       VendorApplication memory vapp = vendorApplicationIndex[_applicationVendorId];
	        return (vapp.id, vapp.status,vapp.dataHash,vapp.createdDate,vapp.govtId,vapp.action);
	     }
	    
	    //returns status of vendor application
	    function getVendorApplicationStatus(string _applicationVendorId) public constant returns(string status) {
	         VendorApplication memory vApp = vendorApplicationIndex[_applicationVendorId];
	         return vApp.status;
	    }
	    
	      //returns total applications count of vendor
	    function getVendorApplicationsCount(string _vendorId) public constant returns (uint) {
	        return vendorApplications[_vendorId].length;    
	    }
	    
	     //---------------------> VendorApplication status  <----------------------------------//
	      
	     //returns status track index of vendor application
	    function getVendorApplicationStatusTrackCount(string _applicationVendorId) public constant returns(uint256 index) {
	         return vendorApplicationStatusTrack[_applicationVendorId].length;
	    }
	    
	    //returns status track of vendor application
	    function getVendorApplicationStatusTrack(string _applicationVendorId, uint _index) public constant 
	               returns(string status,string date, string hash,string submitter, string action) {
	                                             
	         StatusTrack memory st = vendorApplicationStatusTrack[_applicationVendorId][_index-1];
	         return (st.status,st.createdDate,st.dataHash,st.submitter,st.action);
	    }
	    
	     //---------------------> VendorApplication scoring  <----------------------------------//
	     
	    //returns scoring track index of vendor application
	    function getVendorApplicationScoringTrackCount(string _applicationVendorId) public constant 
	                                                    returns (uint256 index) {
	         return vendorApplicationScoring[_applicationVendorId].length;
	    }
	    
	    //returns status track of vendor application
	    function getVendorApplicationScoringTrack(string _applicationVendorId, uint _index) public constant 
	                                              returns(uint256 beeScore,uint256 innovation, uint256 bussinessModel, uint256 scalability,string date, string recommendedAmount,
	                                             string submitter, string action) {
	         Scoring memory st = vendorApplicationScoring[_applicationVendorId][_index-1];
	         return (st.beeScore,st.innovation,st.bussinessModel,st.scalability,st.createdDate,st.recommendedAmount,st.submitter,st.action);
	    }
	    
	    //---------------------> Govt Applications getters <----------------------------------//
	      
	    //returns total applications count of govt
	    function getGovtApplicationsCount(string _govtId) public constant returns (uint) {
	        return applications[_govtId].length;    
	    }
	    
	     //returns govt application by index
	    function getGovtApplicationByIndex(string _govtId, uint _index) public constant returns 
	                                        (string applicationId, string hash, string date) {
	       Application memory app = applications[_govtId][_index-1];  
	       return (app.id,app.dataHash,app.createdDate);
	    }
	    
	    //returns application of govt
	    function getGovtApplication(string _govtId, string _applicationId) public constant returns 
	                                (string applicationId, string hash, string date) {
	         Application memory app = applicationIndex[_govtId][_applicationId];
	         return (app.id,app.dataHash,app.createdDate);
	    }
	    
	}