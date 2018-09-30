pragma solidity^0.4.25;
 
 contract CertificateAndClaims {
     
        //Saves the event logs
	    event Log(string  eventMessage);
	    
	    struct Organisation {
	       	string id;
	        string name;
	        string registrationDate;
	        bool exists;
	     }
	     
	     struct Certificate {
	         string id;
	         address issuer;
	         address requester;
	         string action;
	         string dataHash;
	         string createdDate;
	     }
	     
	      struct Claim {
	         string id;
	         address issuer;
	         address requester;
	         string action;
	         string dataHash;
	         string createdDate;
	     }
	     
	     //Organisation list
	     Organisation[] organisations;
	     
	     //Organisation index
	     mapping(address => Organisation) organisation;
	     
	     //Certificates List
	     Certificate[] certificates;
	     
	     //Certificate Index
	     mapping(string => Certificate) certificate;
	     
	     //Organisation issued certificates
	     mapping(address => Certificate[]) orgCerts;
	     
	     //Organisation endorsed claims
	     mapping(address => Claim[]) orgClaims;
	     
	     Claim[] claims;
	     
	     mapping(string => Claim) claim;
	    
	    //creator of this smart contract
	    string creatorName;
	    address creatorAddress;
	    
	    //contructor which creates the owner
	    constructor (string _creator) public {
	      creatorName = _creator;
	      creatorAddress = msg.sender;
	      emit Log("Contract deployed successfully");
	    }
	    
	     //Validate if application is exits or not
	    function isOrganisationExits(address _publicKey) private view returns(bool) {
	        if(organisation[_publicKey].exists){
	            return true;
	        }else{
	            return false;
	        }
	    }
	    
	    //Add organisation
	    function addOrganisation(address _publicKey,string _id,string _name, string _date) 
	            public payable returns(bool) {
	       if(!isOrganisationExits(_publicKey)){
	          Organisation storage org = organisation[_publicKey];
	          org.id = _id;
	          org.name = _name;
	          org.registrationDate = _date;
	          organisations.push(org);
	          organisation[_publicKey] = org;
	          return true;
	       }
	        return false;
	    }
	    
	    function issueCertificate(string _certId, string _dataHash, string _date,  address _issuer,
	          address _requester, string _action) public payable returns(bool) {
	       Certificate storage cert = certificate[_certId];   
	       cert.id = _certId;
	       cert.dataHash = _dataHash;
	       cert.createdDate = _date;
	       cert.issuer = _issuer;
	       cert.requester = _requester;
	       cert.action = _action;
	       //Certificates list
	       certificates.push(cert);
	       //Certificate map by certId
	       certificate[_certId] = cert;
	       //Org certificates by orgaddress and certId
	       orgCerts[_issuer].push(cert);
	       return true;
	   }
	   
	   function endorseClaim(string _claimId, string _dataHash, string _date,  address _issuer,
	          address _requester, string _action)public payable returns(bool) {
	       Claim storage _claims = claim[_claimId];
	       _claims.id = _claimId;
	       _claims.dataHash = _dataHash;
	       _claims.createdDate = _date;
	       _claims.issuer = _issuer;
	       _claims.requester = _requester;
	       _claims.action = _action;
	       //claims list
	       claims.push(_claims);
	       //Claims index by claimId
	       claim[_claimId] = _claims;
	       //Org claims by org adress and claimid
	       orgClaims[_issuer].push(_claims);
	       return true;
	   }
	    
	   
	   function getCertificateById(string _id) public constant returns (string dataHash, address issuer, address requester, string createdDate, string action) {
	       Certificate memory cert = certificate[_id];  
	       return (cert.dataHash,cert.issuer,cert.requester,cert.createdDate,cert.action);
	   }
	   
	   function getClaimById(string _id) public constant returns (string dataHash, address issuer, address requester, string createdDate, string action) {
	       Claim memory _claim = claim[_id];  
	       return (_claim.dataHash,_claim.issuer,_claim.requester,_claim.createdDate,_claim.action);
	   }
	   
	   function getOrganisationByAddress(address _publicKey) public constant returns (string id, string name, string date){
	       Organisation memory org = organisation[_publicKey];
	       return(org.id,org.name,org.registrationDate);
	   }
	    
	   function getOrganisationCount() public constant returns (uint256){
	       return organisations.length;
	   } 
	    
	   function getOrgClaimsCount(address _publicKey) public constant returns (uint256){
	       return orgClaims[_publicKey].length;
	   } 
	   
	   function getOrgCertificatesCount(address _publicKey) public constant returns (uint256){
	       return orgCerts[_publicKey].length;
	   }  
  
 }