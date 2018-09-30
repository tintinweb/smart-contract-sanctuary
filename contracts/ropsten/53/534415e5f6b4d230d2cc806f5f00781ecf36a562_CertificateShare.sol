pragma solidity^0.4.25;
contract CertificateShare {
     //Saves the event logs
	    event Log(string  eventMessage);
	    
	      struct Certificate {
	         string id;
	         string certId;
	         address organisation;
	         address requester;
	         string action;
	         string createdDate;
	     }
	     
	      //Certificate shared id Index
	     mapping(string => Certificate) certificate;
	     
	   
	     //Organisation issued certificates
	     mapping(address => Certificate[]) orgSharedCerts;
	     
	      //Certificates List
	     Certificate[] certificates;
	     
	      //creator of this smart contract
	    string creatorName;
	    address creatorAddress;
	     
	     //contructor which creates the owner
	    constructor (string _creator) public {
	      creatorName = _creator;
	      creatorAddress = msg.sender;
	      emit Log("Contract deployed successfully");
	    }
	    
	    function shareCertificate(string _sharedId,string _certId, string _date,  address _org,
	          address _requester, string _action) public payable returns(bool) {
	       Certificate storage cert = certificate[_sharedId];   
	       cert.id = _sharedId;
	       cert.certId=_certId;
	       cert.createdDate = _date;
	       cert.organisation = _org;
	       cert.requester = _requester;
	       cert.action = _action;
	       //Certificates list
	       certificates.push(cert);
	       //Certificate map by certsharedId
	       certificate[_sharedId] = cert;
	       //Org certificates by orgaddress and certsharedId
	       orgSharedCerts[_org].push(cert);
	       return true;
	   }
	    
    
}