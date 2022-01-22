/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;
contract Registration{
  function RegisterForensic (uint[] memory _jids) public { }
  function approveUser(uint _id) public{}
  function RegisterRTO (string memory _jurstriction) public { }
  function RegisterServiceCenter (string memory _sname) public { }
  function RegisterLAW (string memory _jurstriction) public { } 
  function RegisterPolice (string memory _jurstriction) public {  }
  function RegisterVehicleAtRTO (uint _vid,uint _jid) public { }
  function RegisterRSU (uint _jid,address _rsuaddress) public { }
  function serviceVehicle (uint _vid,uint _sid,string memory _sdate,string memory _stype)  public {}
  function RegisterVehicleOwner (string memory _name,string memory _adr,string memory _phno) public { }
  function RegisterVehicleSeller (string memory _name) public {  }
  function SellVehicle (uint _vid,uint _oid) public { }
  function RegisterManufacturer (string memory _name) public { }
  function RegisterInsuranceProvider (string memory _name) public {  }
  function RegisterVehicle (string memory _chasis,string memory _engine, string memory _color, uint _model,uint _sid) public {  }   
  function RegisterPolicy (uint _policyno,string memory _provider,uint _vno,string memory _sdate,string memory _edate) public {  }
  function getRSUJID(address _caller) public view  returns (uint) {  }
  function getVehicleMapping(uint _vid) public view returns (uint){}
  function getJuristrictionPoliceID(uint _jid) public view returns (uint){}
  function getJuristrictionForensicID(uint _jid) public view returns (uint){}
  function getJuristrictionLawID(uint _jid) public view returns (uint){}
  function getOwnerAddress(uint _oid) public view returns (address){}
  function getForensicAddress(uint _fid) public view returns (address){}
   function getPoliceAddress(uint _pid) public view returns (address){}
   function getLawAddress(uint _lid) public view returns (address){}
    function getManufacturerAddress(uint _vid) public view returns (address){}
}
contract Vehicle{
  function getIncidentJid(uint _incidentid) public view returns (uint){}
   function getincidentToVids(uint _incidentid) public view returns (uint[] memory){}
}
contract Evidence { 
  Registration r;
  Vehicle v;
  constructor(address _registration,address _vehicle) public { 
      r = Registration(_registration);
      v=Vehicle(_vehicle);
  }
//Mobile Phone  Evidence
//Mobile Pone Evidence Starting

  struct MobilePhoneEvidence{
    uint incidentid;
    string typeofincident;
    string subcategory;
    string description;
    string ipfshash;
    string location;
    string date;
    string time;
  }
mapping (uint=>MobilePhoneEvidence[]) private mobilephoneevidences;//incident id to evidences

//Mobile Phone Evidence comparison data

  struct MobilePhoneEvidenceShortData{
    uint incidentid;  
    string evidencehash;
  }
  mapping (uint=>MobilePhoneEvidenceShortData[]) private mobilephoneevidenceshort;//incident id Evidences

function MobilePhoneEvidences (uint _incidentId ,string memory _typeofincident,string memory _subcategory,string memory _description,string memory _ipfshash,string memory _location,string memory _date,string memory _time ) public {

        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) 
      
        MobilePhoneEvidence memory _v=MobilePhoneEvidence(_incidentId,_typeofincident,_subcategory,_description,_ipfshash,_location,_date,_time);
        mobilephoneevidences[_incidentId].push(_v);
  }

  function shortMobilePhoneEvidencs (uint _incidentId ,string memory _evidencehash ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
        MobilePhoneEvidenceShortData memory _v=MobilePhoneEvidenceShortData(_incidentId,_evidencehash);           
        mobilephoneevidenceshort[_incidentId].push(_v);
  }
   function readMobileEvidences(uint _incidenid) public view returns (MobilePhoneEvidence[] memory){
    //ACCESS CONTROL       
    uint jid=v.getIncidentJid(_incidenid);
    //uint policeid=juristrictions[jid].policeid;
     uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (mobilephoneevidences[_incidenid]);
  }
function readMobileEvidencesShort(uint _incidenid) public view returns (MobilePhoneEvidenceShortData[] memory){
    //ACCESS CONTROL       
    uint jid=v.getIncidentJid(_incidenid);
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (mobilephoneevidenceshort[_incidenid]);
  }
//Mobile Phone  Evidence Ends

//CCTV starting

  struct CCTVData{
    uint incidentid;
    uint cctvid;
    string videohash;
  }
mapping (uint=>mapping(uint=>CCTVData)) private cctvdatas; //incident id to cctv id  to  data

function CCTVFootage (uint _incidentid ,uint _cctvid,string memory _videohash ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
            CCTVData memory _v=CCTVData(_incidentid,_cctvid,_videohash);           
            cctvdatas[_incidentid][_cctvid]=_v;          
  }

  function readCCTVFootage(uint _incidenid,uint _cctvid) public view returns (CCTVData memory){
    //ACCESS CONTROL  
    uint jid=v.getIncidentJid(_incidenid);
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (cctvdatas[_incidenid][_cctvid]);
  }

//CCTV ends

//Evidence By RSU starting

  struct RSUEvidence{
    uint incidentid;    
    string evidencehashvehicles;
  }
mapping (uint=>RSUEvidence) private rsuevidences; //incident id to EVIDENCE 

function RSUEvidencefromvehicles (uint _incidentid ,string memory _evidencehash ) public {  
        //require(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("9")))) ;//should be RSU
        RSUEvidence memory _v=RSUEvidence(_incidentid,_evidencehash);           
        rsuevidences[_incidentid]=_v;          
  }

  function readRSUEvidencefromvehicles(uint _incidenid) public view returns (RSUEvidence memory){
    //ACCESS CONTROL  
    uint jid=v.getIncidentJid(_incidenid);
    //uint policeid=juristrictions[jid].policeid;
    uint policeid=r.getJuristrictionPoliceID(jid);
    uint forensicid=r.getJuristrictionForensicID(jid);
     //Vehicle Owner can read or forensic or Police
    require((r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));
    return (rsuevidences[_incidenid]);
  }

//Evidence by RSU ends


//EDR Report starting
 struct EDRReoprt{
    uint incidentid;    
    uint vid;
    string date;
    uint roadsegmentid;    
    string edrdatahash;
  }
mapping (uint=>mapping(uint=>EDRReoprt)) private edrreports; //incident id to vid id  to  data
function writeEDRReoprt (uint _incidentid ,uint _vid,string memory _date, uint _roadsegmentid,string memory _edrdatahash ) public {  
          //uint jid=v.getIncidentJid(_incidentid);
          uint jid=v.getIncidentJid(_incidentid);
         // uint policeid=juristrictions[jid].policeid;
         uint policeid=r.getJuristrictionPoliceID(jid);
         uint forensicid=r.getJuristrictionForensicID(jid);
          // forensic or Police
          require((r.getForensicAddress(forensicid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender));

            EDRReoprt memory _v=EDRReoprt(_incidentid,_vid,_date,_roadsegmentid,_edrdatahash);           
            edrreports[_incidentid][_vid]=_v;          
  }

  function readEDRReoprt(uint _incidenid,uint _vid) public view returns (EDRReoprt memory){
    //ACCESS CONTROL  
     //uint _oid=vehiclemapping[_vid].oid;//Reading Owner Id of the Vehicle  
      uint _oid=r.getVehicleMapping(_vid);//Reading Owner Id of the Vehicle      
     //Vehicle Owner or Manufacturer can read
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getManufacturerAddress(_vid)==msg.sender));
    return (edrreports[_incidenid][_vid]);
  }

//EDR Report Ends

//Digital Investigation  Report starting
 struct DigitalFInvestigationReoprt{
    uint incidentid;    
    uint vid;
    string date;
    uint roadsegmentid;    
    string reporthash;
  }
mapping (uint=>mapping(uint=>DigitalFInvestigationReoprt)) private investigationreports; //incident id to vid id  to  data
function writeEDRDigitalFInvestigationReoprt (uint _incidentid ,uint _vid,string memory _date, uint _roadsegmentid,string memory _reporthash ) public {  
          uint jid=v.getIncidentJid(_incidentid);         
          uint forensicid=r.getJuristrictionForensicID(jid);
          // should be forensic forensic 
          require((r.getForensicAddress(forensicid)==msg.sender));
            DigitalFInvestigationReoprt memory _v=DigitalFInvestigationReoprt(_incidentid,_vid,_date,_roadsegmentid,_reporthash);           
            investigationreports[_incidentid][_vid]=_v;          
  }

  function readDigitalFInvestigationReoprt(uint _incidenid,uint _vid) public view returns (DigitalFInvestigationReoprt memory){
    //ACCESS CONTROL owner police or law 
     //uint _oid=vehiclemapping[_vid].oid;//Reading Owner Id of the Vehicle
      uint _oid=r.getVehicleMapping(_vid);//Reading Owner Id of the Vehicle     
     uint jid=v.getIncidentJid(_incidenid);
      //uint policeid=juristrictions[jid].policeid; 
      uint policeid=r.getJuristrictionPoliceID(jid);
      //uint lawid=juristrictions[jid].lawid; 
       uint lawid=r.getJuristrictionLawID(jid);
     //Vehicle Owner or Manufacturer can read
    require((r.getOwnerAddress(_oid)==msg.sender)||(r.getPoliceAddress(policeid)==msg.sender)||(r.getLawAddress(lawid)==msg.sender));
    return (investigationreports[_incidenid][_vid]);
  }

//Digital Investigation  Report Ends

//FIR Report starting
 struct FIR{
    uint incidentid;    
    uint[] vids;
    string date;      
    string firhash;
  }
mapping (uint=>FIR) private firReports; //incident id to FIR Reports
function writeFIR (uint _incidentid,uint[] memory _vids,string memory _date,string memory _firhash ) public {  
          uint jid=v.getIncidentJid(_incidentid);         
          // uint policeid=juristrictions[jid].policeid; 
          uint policeid=r.getJuristrictionPoliceID(jid);
          // should be POLICE
          require((r.getPoliceAddress(policeid)==msg.sender));
          FIR memory _v=FIR(_incidentid,_vids,_date,_firhash);           
          firReports[_incidentid]=_v;          
  }

  function readFIR(uint _incidenid) public view returns (FIR memory){
    //ACCESS CONTROL owner OR law 
    uint flag=0;
    //uint[] memory _vids=incidentToVids[_incidenid];
    uint[] memory _vids=v.getincidentToVids(_incidenid);
    //Checking msg.sender is any of the owner
    for(uint i=0;i<_vids.length;i++){
         //uint _oid=vehiclemapping[_vids[i]].oid;
          uint _oid=r.getVehicleMapping(_vids[i]);//Reading Owner Id of the Vehicle   
         if(r.getOwnerAddress(_oid)==msg.sender){
           flag=1;break;
         }
    }
     uint jid=v.getIncidentJid(_incidenid);      
      uint lawid=r.getJuristrictionLawID(jid); 
     //Vehicle Owner or LAW
    require((flag==1)||(r.getLawAddress(lawid)==msg.sender));
    return (firReports[_incidenid]);
  }

//FIR Report Ends

//Read Service ServiceHistory Start

  //function readServiceHistory(uint _vid) public view returns (ServiceHistoryVehicle[] memory){
    //ACCESS CONTROL owner OR law 
   
   
     //Should be POLICE or Forensic or Insurance
     
     //require((keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("6"))))||(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("8"))))||(keccak256(abi.encodePacked((roles[msg.sender]))) == keccak256(abi.encodePacked(("2"))))) ;
       
    //return (servicehistoriesvehicle[_vid]);
  //}
//Read Service History Ends



//Write Verdict by Law starting
//LAW can read FIR report by calling ReadFIR()

mapping (uint=>mapping(uint=>string)) private verdicts; //incident id ,vid To verdict
  function closeIncident(uint _incidenid,uint _vid,string memory _verdictreport) public {
    //ACCESS CONTROL  law 
   
     uint jid=v.getIncidentJid(_incidenid);      
      uint lawid=r.getJuristrictionLawID(jid); 
     // LAW
    require(r.getLawAddress(lawid)==msg.sender);
    verdicts[_incidenid][_vid]=_verdictreport;
  }
//Write Verdict by Law ENDS

}